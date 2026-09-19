import Foundation
import Darwin

public struct NetworkSnapshot: Equatable {
    public var uploadBytesPerSec: Double = 0
    public var downloadBytesPerSec: Double = 0
    public var totalInBytes: UInt64 = 0
    public var totalOutBytes: UInt64 = 0
    public var activeInterface: String = "en0"
    public var localIP: String = "127.0.0.1"
    public var interfaceType: String = "Wi-Fi"
}

public final class NetworkMonitor {
    public static let shared = NetworkMonitor()
    
    private var lastInBytes: UInt64 = 0
    private var lastOutBytes: UInt64 = 0
    private var lastCheckTime: Date?
    private var lastInterface: String = ""
    private var cachedInterfaceInfo: (name: String, ip: String, type: String)? = nil
    private var lastInterfaceCheckTime: Date = .distantPast
    
    private init() {
        let (iface, _, _) = getActiveInterfaceInfo()
        let (inB, outB) = getRawBytes(forInterface: iface)
        self.lastInterface = iface
        self.lastInBytes = inB
        self.lastOutBytes = outB
        self.lastCheckTime = Date()
    }
    
    private var rawBuffer: UnsafeMutableRawPointer?
    private var rawBufferCapacity: Int = 0
    
    deinit {
        if let buf = rawBuffer {
            free(buf)
        }
    }
    
    public func update(isDetailed: Bool = false) -> NetworkSnapshot {
        let (iface, ip, type) = getActiveInterfaceInfo()
        let (currentIn, currentOut) = getRawBytes(forInterface: iface)
        let now = Date()
        
        var downSpeed: Double = 0
        var upSpeed: Double = 0
        
        // 监测网卡切换保护：当切换 Wi-Fi/以太网时，重新校准基线，防止瞬间计算出虚假脉冲尖刺
        if iface != lastInterface {
            self.lastInterface = iface
            self.lastInBytes = currentIn
            self.lastOutBytes = currentOut
            self.lastCheckTime = now
        } else if let lastTime = lastCheckTime {
            let interval = now.timeIntervalSince(lastTime)
            if interval > 0.05 {
                if currentIn >= lastInBytes {
                    downSpeed = Double(currentIn - lastInBytes) / interval
                }
                if currentOut >= lastOutBytes {
                    upSpeed = Double(currentOut - lastOutBytes) / interval
                }
            }
            self.lastInBytes = currentIn
            self.lastOutBytes = currentOut
            self.lastCheckTime = now
        } else {
            self.lastInBytes = currentIn
            self.lastOutBytes = currentOut
            self.lastCheckTime = now
        }
        
        // 当弹窗未打开时，微小的网络抖动（< 10 B/s）归零，保留 1 位小数，避免浮点微差破坏 Equatable
        if !isDetailed {
            if downSpeed < 10.0 { downSpeed = 0 }
            if upSpeed < 10.0 { upSpeed = 0 }
            downSpeed = (downSpeed * 10).rounded() / 10.0
            upSpeed = (upSpeed * 10).rounded() / 10.0
        }
        
        return NetworkSnapshot(
            uploadBytesPerSec: upSpeed,
            downloadBytesPerSec: downSpeed,
            totalInBytes: isDetailed ? currentIn : 0,
            totalOutBytes: isDetailed ? currentOut : 0,
            activeInterface: iface,
            localIP: ip,
            interfaceType: type
        )
    }
    
    /// 使用 64 位内核路由接口 sysctl (NET_RT_IFLIST2) 读取绝对精确的 u_int64_t 计数器
    /// 采用复用缓冲区与寄存器级字节匹配，实现零内存堆分配（Zero-Allocation）、零字符串转换开销
    private func getRawBytes(forInterface targetInterface: String? = nil) -> (UInt64, UInt64) {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: Int = 0
        guard sysctl(&mib, 6, nil, &len, nil, 0) == 0, len > 0 else { return (0, 0) }
        
        if len > rawBufferCapacity || rawBuffer == nil {
            rawBuffer = realloc(rawBuffer, len)
            rawBufferCapacity = len
        }
        guard let buf = rawBuffer else { return (0, 0) }
        guard sysctl(&mib, 6, buf, &len, nil, 0) == 0 else { return (0, 0) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        var offset = 0
        let targetBytes: [UInt8] = targetInterface != nil && !targetInterface!.isEmpty ? Array(targetInterface!.utf8) : []
        let hasTarget = !targetBytes.isEmpty
        
        while offset < len {
            let ptr = buf.advanced(by: offset)
            let ifm = ptr.bindMemory(to: if_msghdr2.self, capacity: 1).pointee
            if ifm.ifm_type == RTM_IFINFO2 {
                let sdlPtr = ptr.advanced(by: MemoryLayout<if_msghdr2>.stride)
                let sdl = sdlPtr.bindMemory(to: sockaddr_dl.self, capacity: 1).pointee
                let nlen = Int(sdl.sdl_nlen)
                
                if nlen > 0 {
                    let isIgnored = withUnsafePointer(to: sdl.sdl_data) { dataPtr -> Bool in
                        let p = UnsafeRawPointer(dataPtr).assumingMemoryBound(to: UInt8.self)
                        let c0 = p[0]
                        let c1 = nlen > 1 ? p[1] : 0
                        // 快速过滤: lo, bridge(br), awdl(aw), llw(ll), utun(ut), gif(gi), stf(st), anpi(an)
                        if c0 == 108 && c1 == 111 { return true } // lo
                        if c0 == 98 && c1 == 114 { return true }  // br
                        if c0 == 97 && c1 == 119 { return true }  // aw
                        if c0 == 108 && c1 == 108 { return true } // ll
                        if c0 == 117 && c1 == 116 { return true } // ut
                        if c0 == 103 && c1 == 105 { return true } // gi
                        if c0 == 115 && c1 == 116 { return true } // st
                        if c0 == 97 && c1 == 110 { return true }  // an
                        return false
                    }
                    
                    if !isIgnored {
                        var isMatch = true
                        if hasTarget {
                            if nlen != targetBytes.count {
                                isMatch = false
                            } else {
                                isMatch = withUnsafePointer(to: sdl.sdl_data) { dataPtr in
                                    let p = UnsafeRawPointer(dataPtr).assumingMemoryBound(to: UInt8.self)
                                    for i in 0..<nlen {
                                        if p[i] != targetBytes[i] { return false }
                                    }
                                    return true
                                }
                            }
                        }
                        
                        if isMatch {
                            totalIn += ifm.ifm_data.ifi_ibytes
                            totalOut += ifm.ifm_data.ifi_obytes
                        }
                    }
                }
            }
            offset += Int(ifm.ifm_msglen)
        }
        
        // 保底策略：若指定的目标网卡未捕获到数据，则回退为所有有效物理网卡之和
        if totalIn == 0 && totalOut == 0 && hasTarget {
            return getRawBytes(forInterface: nil)
        }
        
        return (totalIn, totalOut)
    }
    
    private func getActiveInterfaceInfo() -> (name: String, ip: String, type: String) {
        let now = Date()
        if let cached = cachedInterfaceInfo, now.timeIntervalSince(lastInterfaceCheckTime) < 10.0 {
            return cached
        }
        lastInterfaceCheckTime = now
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return cachedInterfaceInfo ?? ("en0", "127.0.0.1", "Wi-Fi")
        }
        defer { freeifaddrs(ifaddr) }
        
        var detectedName = "en0"
        var detectedIP = "127.0.0.1"
        var detectedType = "Wi-Fi"
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            
            if isUp && isRunning && !isLoopback {
                let name = String(cString: current.pointee.ifa_name)
                if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        detectedName = name
                        detectedIP = String(cString: hostname)
                        detectedType = name.hasPrefix("en0") ? "Wi-Fi" : "以太网"
                        break
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }
        let result = (detectedName, detectedIP, detectedType)
        self.cachedInterfaceInfo = result
        return result
    }
    
    public static func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return String(format: "%.0f B/s", bytesPerSec)
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024.0)
        } else if bytesPerSec < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB/s", bytesPerSec / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB/s", bytesPerSec / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    public static func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b < 1024 * 1024 {
            return String(format: "%.1f KB", b / 1024.0)
        } else if b < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", b / (1024.0 * 1024.0))
        } else if b < 1024 * 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", b / (1024.0 * 1024.0 * 1024.0))
        } else {
            return String(format: "%.2f TB", b / (1024.0 * 1024.0 * 1024.0 * 1024.0))
        }
    }
}
