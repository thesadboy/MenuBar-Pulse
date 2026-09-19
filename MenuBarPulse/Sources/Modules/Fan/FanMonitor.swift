import Foundation

public struct FanInfo: Identifiable, Equatable {
    public var id: Int
    public var name: String
    public var currentRPM: Double
    public var minRPM: Double
    public var maxRPM: Double
    
    public var percentage: Double {
        let span = maxRPM - minRPM
        guard span > 0 else { return 0 }
        let currentSpan = currentRPM - minRPM
        return max(0.0, min(100.0, (currentSpan / span) * 100.0))
    }
}

public struct FanSnapshot: Equatable {
    public var isFanless: Bool = true
    public var fanCount: Int = 0
    public var fans: [FanInfo] = []
    public var thermalStateString: String = "正常"
}

public final class FanMonitor {
    public static let shared = FanMonitor()
    
    private var cachedFanCount: Int? = nil
    private var cachedFanLimits: [Int: (min: Double, max: Double)] = [:]
    
    private init() {}
    
    public func update() -> FanSnapshot {
        var snapshot = FanSnapshot()
        
        let count: Int
        if let c = cachedFanCount {
            count = c
        } else {
            count = SMCReader.shared.getFanCount()
            cachedFanCount = count
        }
        snapshot.fanCount = count
        
        if count > 0 {
            snapshot.isFanless = false
            var fanList: [FanInfo] = []
            for i in 0..<count {
                let limits: (min: Double, max: Double)
                if let lim = cachedFanLimits[i] {
                    limits = lim
                } else if let speed = SMCReader.shared.getFanSpeed(index: i) {
                    limits = (speed.min, speed.max)
                    cachedFanLimits[i] = limits
                } else {
                    limits = (0, 6000)
                }
                
                let current = SMCReader.shared.getCurrentFanSpeed(index: i) ?? limits.min
                let fan = FanInfo(
                    id: i,
                    name: count == 1 ? "系统主风扇" : (i == 0 ? "左侧风扇" : "右侧风扇"),
                    currentRPM: current,
                    minRPM: limits.min,
                    maxRPM: limits.max
                )
                fanList.append(fan)
            }
            snapshot.fans = fanList
        } else {
            // 无物理风扇设备（如 MacBook Air M1/M2/M3 被动散热）
            snapshot.isFanless = true
            snapshot.fans = []
        }
        
        // 读取系统热压力等级
        let thermal = ProcessInfo.processInfo.thermalState
        switch thermal {
        case .nominal:
            snapshot.thermalStateString = "优良 (温度正常)"
        case .fair:
            snapshot.thermalStateString = "正常 (温热运行)"
        case .serious:
            snapshot.thermalStateString = "高负载 (发热升高)"
        case .critical:
            snapshot.thermalStateString = "警告 (过热保护降频)"
        @unknown default:
            snapshot.thermalStateString = "正常"
        }
        
        return snapshot
    }
}
