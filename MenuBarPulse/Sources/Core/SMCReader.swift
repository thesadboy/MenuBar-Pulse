import Foundation
import IOKit

public struct SMCVersion {
    public var major: CUnsignedChar = 0
    public var minor: CUnsignedChar = 0
    public var build: CUnsignedChar = 0
    public var reserved: CUnsignedChar = 0
    public var release: CUnsignedShort = 0
}

public struct SMCPLimitData {
    public var version: UInt16 = 0
    public var length: UInt16 = 0
    public var cpuPLimit: UInt32 = 0
    public var gpuPLimit: UInt32 = 0
    public var memPLimit: UInt32 = 0
}

public struct SMCKeyInfoData {
    public var dataSize: UInt32 = 0
    public var dataType: UInt32 = 0
    public var dataAttributes: UInt8 = 0
}

// 必须保证为 80 字节对齐，以支持 Apple Silicon 和 macOS 现代内核通信
public struct SMCKeyData {
    public var key: UInt32 = 0
    public var vers = SMCVersion()
    public var pLimitData = SMCPLimitData()
    public var keyInfo = SMCKeyInfoData()
    public var padding: UInt16 = 0
    public var result: UInt8 = 0
    public var status: UInt8 = 0
    public var data8: UInt8 = 0
    public var data32: UInt32 = 0
    public var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
                     (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

public final class SMCReader {
    public static let shared = SMCReader()
    
    private var connection: io_connect_t = 0
    private var isConnected: Bool = false
    
    private init() {
        openConnection()
    }
    
    deinit {
        closeConnection()
    }
    
    private func openConnection() {
        if isConnected { return }
        
        // 依次尝试 AppleSMCKeysEndpoint (Apple Silicon) 与 AppleSMC (Intel)
        let serviceNames = ["AppleSMCKeysEndpoint", "AppleSMC"]
        for name in serviceNames {
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(name))
            if service != 0 {
                let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
                IOObjectRelease(service)
                if result == KERN_SUCCESS {
                    isConnected = true
                    return
                }
            }
        }
    }
    
    private func closeConnection() {
        if isConnected {
            IOServiceClose(connection)
            connection = 0
            isConnected = false
        }
    }
    
    private func fourCharCode(_ string: String) -> UInt32 {
        var result: UInt32 = 0
        for char in string.utf8 {
            result = (result << 8) | UInt32(char)
        }
        return result
    }
    
    private func callSMC(input: inout SMCKeyData, output: inout SMCKeyData) -> kern_return_t {
        if !isConnected {
            openConnection()
            guard isConnected else { return KERN_FAILURE }
        }
        
        let inputSize = MemoryLayout<SMCKeyData>.stride
        var outputSize = MemoryLayout<SMCKeyData>.stride
        return IOConnectCallStructMethod(connection, 2, &input, inputSize, &output, &outputSize)
    }
    
    private var keyInfoCache: [String: SMCKeyInfoData?] = [:]
    
    public func readKeyInfo(_ keyStr: String) -> SMCKeyInfoData? {
        if let cached = keyInfoCache[keyStr] {
            return cached
        }
        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = fourCharCode(keyStr)
        input.data8 = 9 // SMC_CMD_READ_KEYINFO
        
        if callSMC(input: &input, output: &output) == KERN_SUCCESS {
            keyInfoCache[keyStr] = output.keyInfo
            return output.keyInfo
        }
        keyInfoCache[keyStr] = Optional<SMCKeyInfoData>.none
        return nil
    }
    
    public func readKey(_ keyStr: String) -> (dataType: String, bytes: [UInt8])? {
        guard let keyInfo = readKeyInfo(keyStr) else { return nil }
        
        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = fourCharCode(keyStr)
        input.keyInfo = keyInfo
        input.data8 = 5 // SMC_CMD_READ_BYTES
        
        if callSMC(input: &input, output: &output) == KERN_SUCCESS {
            let rawBytes = [
                output.bytes.0, output.bytes.1, output.bytes.2, output.bytes.3,
                output.bytes.4, output.bytes.5, output.bytes.6, output.bytes.7,
                output.bytes.8, output.bytes.9, output.bytes.10, output.bytes.11,
                output.bytes.12, output.bytes.13, output.bytes.14, output.bytes.15
            ]
            let typeChars = [
                UInt8((keyInfo.dataType >> 24) & 0xff),
                UInt8((keyInfo.dataType >> 16) & 0xff),
                UInt8((keyInfo.dataType >> 8) & 0xff),
                UInt8(keyInfo.dataType & 0xff)
            ]
            let typeString = String(bytes: typeChars, encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? ""
            return (typeString, Array(rawBytes.prefix(Int(keyInfo.dataSize))))
        }
        return nil
    }
    
    public func getFanCount() -> Int {
        if let data = readKey("FNum"), !data.bytes.isEmpty {
            return Int(data.bytes[0])
        }
        return 0
    }
    
    public func getFanSpeed(index: Int) -> (current: Double, min: Double, max: Double)? {
        let currentKey = "F\(index)Ac"
        let minKey = "F\(index)Mn"
        let maxKey = "F\(index)Mx"
        
        guard let currentVal = parseSpeedValue(key: currentKey) else { return nil }
        let minVal = parseSpeedValue(key: minKey) ?? 0
        let maxVal = parseSpeedValue(key: maxKey) ?? 6000
        return (currentVal, minVal, maxVal)
    }
    
    public func getCurrentFanSpeed(index: Int) -> Double? {
        return parseSpeedValue(key: "F\(index)Ac")
    }
    
    private func parseSpeedValue(key: String) -> Double? {
        guard let data = readKey(key) else { return nil }
        let bytes = data.bytes
        if data.dataType.hasPrefix("fpe2") && bytes.count >= 2 {
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw) / 4.0
        } else if data.dataType.hasPrefix("flt") && bytes.count >= 4 {
            let leU32 = (UInt32(bytes[3]) << 24) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[1]) << 8) | UInt32(bytes[0])
            var val = Double(Float(bitPattern: leU32))
            if val < 0.0 || val > 15000.0 {
                let beU32 = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
                let beVal = Double(Float(bitPattern: beU32))
                if beVal >= 0.0 && beVal <= 15000.0 { val = beVal }
            }
            return max(0.0, val)
        } else if bytes.count >= 2 {
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw)
        }
        return nil
    }
    
    public func readTemperatureValue(key: String) -> Double? {
        guard let data = readKey(key) else { return nil }
        let bytes = data.bytes
        if data.dataType.hasPrefix("flt") && bytes.count >= 4 {
            let leU32 = (UInt32(bytes[3]) << 24) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[1]) << 8) | UInt32(bytes[0])
            var val = Double(Float(bitPattern: leU32))
            if val < 0.0 || val > 150.0 {
                let beU32 = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
                let beVal = Double(Float(bitPattern: beU32))
                if beVal >= 0.0 && beVal <= 150.0 { val = beVal }
            }
            if val >= 5.0 && val <= 125.0 { return val }
        } else if data.dataType.hasPrefix("sp78") && bytes.count >= 2 {
            let raw = (Int(Int8(bitPattern: bytes[0])) << 8) | Int(bytes[1])
            let val = Double(raw) / 256.0
            if val >= 5.0 && val <= 125.0 { return val }
        } else if data.dataType.hasPrefix("fpe2") && bytes.count >= 2 {
            let raw = (Int(bytes[0]) << 8) | Int(bytes[1])
            let val = Double(raw) / 4.0
            if val >= 5.0 && val <= 125.0 { return val }
        }
        return nil
    }
}
