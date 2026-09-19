import Foundation
import IOKit
import IOKit.ps

public struct BatterySnapshot: Equatable {
    public var hasBattery: Bool = true
    public var percentage: Int = 100
    public var isCharging: Bool = false
    public var isACConnected: Bool = false
    public var isCharged: Bool = false
    public var cycleCount: Int = 0
    public var healthPercentage: Double = 100.0
    public var condition: String = "正常" // "正常" / "建议检修"
    public var manufactureDateString: String = "" // 出厂日期 (如 2021-06-04)
    public var ageString: String = "" // 详细使用时间 (如 5年3个月)
    public var designCapacity: Int = 0
    public var nominalCapacity: Int = 0
    public var fullChargeCapacity: Int = 0
    public var adapterWatts: Int = 0
    public var timeRemainingMinutes: Int = -1 // -1 表示计算中或不可用
    public var statusDescription: String = "正在使用电池"
    
    // 上次充电时间与状态
    public var lastChargeDate: Date? = nil
    public var lastChargeLevel: Int? = nil
    public var lastChargeFormatted: String = ""
    
    // 格式化后的剩余可用或充满所需时间
    public var timeRemainingFormatted: String {
        if isACConnected {
            if isCharged {
                return "已充满"
            } else if isCharging {
                if timeRemainingMinutes > 0 {
                    let h = timeRemainingMinutes / 60
                    let m = timeRemainingMinutes % 60
                    return h > 0 ? "\(h)小时\(m)分" : "\(m)分钟"
                } else {
                    return "正在计算..."
                }
            } else {
                return "未充电"
            }
        } else {
            if timeRemainingMinutes > 0 {
                let h = timeRemainingMinutes / 60
                let m = timeRemainingMinutes % 60
                return h > 0 ? "\(h)小时\(m)分" : "\(m)分钟"
            } else {
                return "正在计算..."
            }
        }
    }
}

public final class BatteryMonitor {
    public static let shared = BatteryMonitor()
    
    private var cachedSystemMaxCapacity: Double? = nil
    private var lastSystemProfileFetchTime: Date = .distantPast
    
    // 静态电池元数据缓存（出厂日期、寿命、设计容量永久不变，仅需解析一次）
    private var cachedMfgDateString: String? = nil
    private var cachedAgeString: String? = nil
    private var cachedDesignCapacity: Int? = nil
    private var lastAgeUpdateDate: Date = .distantPast
    
    // 节流快照缓存
    private var cachedSnapshot = BatterySnapshot()
    private var lastUpdateTime: Date = .distantPast
    
    // 上次充电跟踪
    private var cachedLastChargeDate: Date? = nil
    private var cachedLastChargeLevel: Int? = nil
    private var prevIsACConnected: Bool? = nil
    private var isFetchingPmsetLog: Bool = false
    
    private let queue = DispatchQueue(label: "com.menubarpulse.battery", qos: .utility)
    
    private init() {
        // 从本地持久化存储加载上次充电记录
        let savedTs = UserDefaults.standard.double(forKey: "mbs_lastChargeTimestamp")
        if savedTs > 0 {
            self.cachedLastChargeDate = Date(timeIntervalSince1970: savedTs)
            let lvl = UserDefaults.standard.integer(forKey: "mbs_lastChargeLevel")
            if lvl > 0 {
                self.cachedLastChargeLevel = lvl
            }
        }
        
        refreshSystemMaxCapacity()
        fetchLastChargeFromPmset()
    }
    
    public func update(force: Bool = false) -> BatterySnapshot {
        let now = Date()
        // 性能节流：非强制且距上次读取未超 4 秒，直接复用已缓存快照（电池电量与状态极其稳定，无需每秒唤醒 IOKit）
        if !force && now.timeIntervalSince(lastUpdateTime) < 4.0 && cachedSnapshot.hasBattery {
            return cachedSnapshot
        }
        lastUpdateTime = now
        
        var snapshot = BatterySnapshot()
        
        // 定期静默刷新系统官方健康度（每 5 分钟）
        if now.timeIntervalSince(lastSystemProfileFetchTime) > 300 {
            lastSystemProfileFetchTime = now
            refreshSystemMaxCapacity()
        }
        
        // 1. 从 IOPowerSources 获取通用状态
        if let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
           !list.isEmpty {
            for source in list {
                if let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] {
                    snapshot.hasBattery = true
                    snapshot.percentage = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
                    snapshot.isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
                    let state = desc[kIOPSPowerSourceStateKey] as? String ?? ""
                    snapshot.isACConnected = (state == kIOPSACPowerValue)
                    snapshot.isCharged = (desc[kIOPSIsChargedKey] as? Bool) ?? (snapshot.percentage >= 100 && snapshot.isACConnected)
                    
                    if snapshot.isCharging {
                        snapshot.timeRemainingMinutes = desc[kIOPSTimeToFullChargeKey] as? Int ?? -1
                    } else if !snapshot.isACConnected {
                        snapshot.timeRemainingMinutes = desc[kIOPSTimeToEmptyKey] as? Int ?? -1
                    } else {
                        snapshot.timeRemainingMinutes = -1
                    }
                }
            }
        } else {
            // 没有电池（如 Mac mini, Mac Studio, Mac Pro）
            snapshot.hasBattery = false
            snapshot.isACConnected = true
            snapshot.statusDescription = "接通电源 (台式 Mac)"
            return snapshot
        }
        
        // 2. 从 AppleSmartBattery 读取硬件底层健康度与功率数据
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                
                snapshot.cycleCount = (dict["CycleCount"] as? Int) ?? (dict["BatteryData"] as? [String: Any])?["CycleCount"] as? Int ?? 0
                let bData = dict["BatteryData"] as? [String: Any] ?? [:]
                let serial = (dict["Serial"] as? String) ?? (bData["Serial"] as? String) ?? ""
                
                snapshot.designCapacity = (dict["DesignCapacity"] as? Int) ?? (bData["DesignCapacity"] as? Int) ?? 0
                snapshot.nominalCapacity = (dict["NominalChargeCapacity"] as? Int) ?? (bData["NominalChargeCapacity"] as? Int) ?? 0
                snapshot.fullChargeCapacity = (dict["FullChargeCapacity"] as? Int) ?? (dict["NominalChargeCapacity"] as? Int) ?? (bData["FullChargeCapacity"] as? Int) ?? (dict["AppleRawMaxCapacity"] as? Int) ?? 0
                
                // 优先采用系统设置官方最大容量（如 97%），若未就绪则采用物理容量比例
                let capForHealth = snapshot.nominalCapacity > 0 ? snapshot.nominalCapacity : snapshot.fullChargeCapacity
                if let sysMax = cachedSystemMaxCapacity {
                    snapshot.healthPercentage = sysMax
                } else if snapshot.designCapacity > 0 && capForHealth > 0 {
                    snapshot.healthPercentage = (Double(capForHealth) / Double(snapshot.designCapacity)) * 100.0
                }
                
                if snapshot.healthPercentage < 80.0 {
                    snapshot.condition = "建议检修"
                } else {
                    snapshot.condition = "正常"
                }
                
                // 3. 计算从出厂开始的使用时长 (从底层序列号或 SBS 规范解析出厂日期)
                var mfgDate: Date? = nil
                
                // 方案 A：标准智能电池规范 (SBS)
                if let mfgInt = bData["ManufactureDate"] as? Int, mfgInt > 0 && mfgInt < 65536 {
                    let day = mfgInt & 0x1F
                    let month = (mfgInt >> 5) & 0x0F
                    let year = 1980 + (mfgInt >> 9)
                    if year >= 2000 && month >= 1 && month <= 12 && day >= 1 && day <= 31 {
                        var comp = DateComponents()
                        comp.year = year
                        comp.month = month
                        comp.day = day
                        mfgDate = Calendar.current.date(from: comp)
                    }
                }
                
                // 方案 B：Apple 电池序列号解码 (如 D861225AKK4PJYRA1)
                // 字符 0-2 为厂商代号，字符 3 为出厂年份个位，字符 4-5 为周数(01-52)，字符 6 为周几(1-7)
                if mfgDate == nil && serial.count >= 7 {
                    let chars = Array(serial)
                    if let yearDigit = Int(String(chars[3])),
                       let week = Int(String(chars[4...5])),
                       let day = Int(String(chars[6])),
                       week >= 1 && week <= 53 {
                        
                        let currentYear = Calendar.current.component(.year, from: Date())
                        var year = 2020 + yearDigit
                        if year > currentYear {
                            year -= 10
                        } else if year < currentYear - 10 {
                            year += 10
                        }
                        
                        var comp = DateComponents()
                        comp.yearForWeekOfYear = year
                        comp.weekOfYear = week
                        comp.weekday = (day % 7) + 1
                        mfgDate = Calendar.current.date(from: comp)
                    }
                }
                
                // 3. 静态电池元数据仅解析一次并永久缓存
                if let mfg = self.cachedMfgDateString, let age = self.cachedAgeString {
                    snapshot.manufactureDateString = mfg
                    snapshot.ageString = age
                } else {
                    var mfgDate: Date? = nil
                    
                    // 方案 A：标准智能电池规范 (SBS)
                    if let mfgInt = bData["ManufactureDate"] as? Int, mfgInt > 0 && mfgInt < 65536 {
                        let day = mfgInt & 0x1F
                        let month = (mfgInt >> 5) & 0x0F
                        let year = 1980 + (mfgInt >> 9)
                        if year >= 2000 && month >= 1 && month <= 12 && day >= 1 && day <= 31 {
                            var comp = DateComponents()
                            comp.year = year
                            comp.month = month
                            comp.day = day
                            mfgDate = Calendar.current.date(from: comp)
                        }
                    }
                    
                    // 方案 B：Apple 电池序列号解码
                    if mfgDate == nil && serial.count >= 7 {
                        let chars = Array(serial)
                        if let yearDigit = Int(String(chars[3])),
                           let week = Int(String(chars[4...5])),
                           let day = Int(String(chars[6])),
                           week >= 1 && week <= 53 {
                            let currentYear = Calendar.current.component(.year, from: Date())
                            var year = 2020 + yearDigit
                            if year > currentYear {
                                year -= 10
                            } else if year < currentYear - 10 {
                                year += 10
                            }
                            var comp = DateComponents()
                            comp.yearForWeekOfYear = year
                            comp.weekOfYear = week
                            comp.weekday = (day % 7) + 1
                            mfgDate = Calendar.current.date(from: comp)
                        }
                    }
                    
                    if let date = mfgDate {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"
                        snapshot.manufactureDateString = df.string(from: date)
                        
                        let diff = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
                        let years = diff.year ?? 0
                        let months = diff.month ?? 0
                        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                        
                        if years > 0 {
                            snapshot.ageString = months > 0 ? "\(years)年\(months)个月" : "\(years)年"
                        } else if months > 0 {
                            snapshot.ageString = "\(months)个月"
                        } else if days > 0 {
                            snapshot.ageString = "\(days)天"
                        }
                    } else if let lifetime = bData["LifetimeData"] as? [String: Any],
                              let totalOpHours = lifetime["TotalOperatingTime"] as? Int, totalOpHours > 0 {
                        let days = totalOpHours / 24
                        let years = days / 365
                        let months = (days % 365) / 30
                        if years > 0 {
                            snapshot.ageString = months > 0 ? "\(years)年\(months)个月" : "\(years)年"
                        } else if months > 0 {
                            snapshot.ageString = "\(months)个月"
                        }
                    }
                    
                    self.cachedMfgDateString = snapshot.manufactureDateString
                    self.cachedAgeString = snapshot.ageString
                }
                
                if let adapter = dict["AdapterDetails"] as? [String: Any] {
                    snapshot.adapterWatts = adapter["Watts"] as? Int ?? 0
                }
            }
            IOObjectRelease(service)
        }
        
        // 3. 计算用户友好的状态文案
        if !snapshot.hasBattery {
            snapshot.statusDescription = "外接电源运行"
        } else if snapshot.isCharging {
            if snapshot.timeRemainingMinutes > 0 {
                let h = snapshot.timeRemainingMinutes / 60
                let m = snapshot.timeRemainingMinutes % 60
                snapshot.statusDescription = h > 0 ? "充电中 (还需 \(h)小时\(m)分充满)" : "充电中 (还需 \(m)分钟充满)"
            } else {
                snapshot.statusDescription = "正在充电"
            }
        } else if snapshot.isACConnected {
            snapshot.statusDescription = snapshot.isCharged ? "已充满 (外接电源)" : "已连接电源 (未充电)"
        } else {
            if snapshot.timeRemainingMinutes > 0 {
                let h = snapshot.timeRemainingMinutes / 60
                let m = snapshot.timeRemainingMinutes % 60
                snapshot.statusDescription = h > 0 ? "使用电池 (预计剩余 \(h)小时\(m)分)" : "使用电池 (预计剩余 \(m)分钟)"
            } else {
                snapshot.statusDescription = "正在使用电池"
            }
        }
        
        // 4. 上次充电事件监测与文案生成
        if let prevAC = self.prevIsACConnected {
            if prevAC && !snapshot.isACConnected {
                // 由连接电源切换为电池供电 (刚刚拔出充电器)
                let now = Date()
                self.cachedLastChargeDate = now
                self.cachedLastChargeLevel = snapshot.percentage
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "mbs_lastChargeTimestamp")
                UserDefaults.standard.set(snapshot.percentage, forKey: "mbs_lastChargeLevel")
            } else if snapshot.isACConnected && snapshot.isCharging {
                // 正在充电时持续保持时间与电量最新
                let now = Date()
                self.cachedLastChargeDate = now
                self.cachedLastChargeLevel = snapshot.percentage
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "mbs_lastChargeTimestamp")
                UserDefaults.standard.set(snapshot.percentage, forKey: "mbs_lastChargeLevel")
            }
        }
        self.prevIsACConnected = snapshot.isACConnected
        
        snapshot.lastChargeDate = self.cachedLastChargeDate
        snapshot.lastChargeLevel = self.cachedLastChargeLevel
        
        if snapshot.isACConnected {
            if snapshot.isCharging {
                snapshot.lastChargeFormatted = "正在充电 (\(snapshot.percentage)%)"
            } else if snapshot.isCharged {
                snapshot.lastChargeFormatted = "已充满 (连接电源)"
            } else {
                snapshot.lastChargeFormatted = "已连接电源 (未充电)"
            }
        } else if let date = self.cachedLastChargeDate {
            let elapsed = max(0, Int(Date().timeIntervalSince(date)))
            let timeAgo: String
            if elapsed < 60 {
                timeAgo = "刚刚"
            } else if elapsed < 3600 {
                let m = elapsed / 60
                timeAgo = "\(m)分钟前"
            } else if elapsed < 86400 {
                let h = elapsed / 3600
                let m = (elapsed % 3600) / 60
                if m > 0 {
                    timeAgo = "\(h)小时\(m)分钟前"
                } else {
                    timeAgo = "\(h)小时前"
                }
            } else {
                let d = elapsed / 86400
                let h = (elapsed % 86400) / 3600
                if h > 0 {
                    timeAgo = "\(d)天\(h)小时前"
                } else {
                    timeAgo = "\(d)天前"
                }
            }
            
            if let lvl = self.cachedLastChargeLevel, lvl > 0 {
                snapshot.lastChargeFormatted = "\(timeAgo) (充至 \(lvl)%)"
            } else {
                snapshot.lastChargeFormatted = timeAgo
            }
        } else {
            snapshot.lastChargeFormatted = "获取中..."
        }
        
        self.cachedSnapshot = snapshot
        return snapshot
    }
    
    /// 异步通过 pmset -g log 检索系统底层上次拔出充电器或上次充电记录
    public func fetchLastChargeFromPmset() {
        guard !isFetchingPmsetLog else { return }
        isFetchingPmsetLog = true
        queue.async { [weak self] in
            defer { self?.isFetchingPmsetLog = false }
            let pipe = Pipe()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            proc.arguments = ["-g", "log"]
            proc.standardOutput = pipe
            do {
                try proc.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                proc.waitUntilExit()
                
                guard let output = String(data: data, encoding: .utf8) else { return }
                
                struct PowerEvent {
                    let date: Date
                    let isAC: Bool
                    let charge: Int?
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                
                var events: [PowerEvent] = []
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    let isAC = line.contains("Using AC")
                    let isBatt = line.contains("Using Batt") || line.contains("Using BATT")
                    guard isAC || isBatt else { continue }
                    guard line.count >= 25 else { continue }
                    
                    let dateSubstring = String(line.prefix(25))
                    guard let date = dateFormatter.date(from: dateSubstring) else { continue }
                    
                    var charge: Int? = nil
                    if let range = line.range(of: "Charge:") {
                        let after = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                        let numStr = after.prefix(while: { $0.isNumber })
                        if let val = Int(numStr) {
                            charge = val
                        }
                    }
                    events.append(PowerEvent(date: date, isAC: isAC, charge: charge))
                }
                
                // 从后向前寻找最近一次由 AC 切换为电池供电的时刻 (拔出充电器时刻)
                var lastUnplug: PowerEvent? = nil
                if events.count >= 2 {
                    for i in stride(from: events.count - 1, through: 1, by: -1) {
                        let curr = events[i]
                        let prev = events[i - 1]
                        if !curr.isAC && prev.isAC {
                            lastUnplug = PowerEvent(date: curr.date, isAC: false, charge: prev.charge ?? curr.charge)
                            break
                        }
                    }
                }
                
                // 若未抓到状态切换，则尝试抓取最后一次 Using AC 记录
                if lastUnplug == nil {
                    for i in stride(from: events.count - 1, through: 0, by: -1) {
                        if events[i].isAC {
                            lastUnplug = events[i]
                            break
                        }
                    }
                }
                
                if let unplug = lastUnplug {
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if self.cachedLastChargeDate == nil || unplug.date >= self.cachedLastChargeDate! {
                            self.cachedLastChargeDate = unplug.date
                            if let ch = unplug.charge, ch > 0 {
                                self.cachedLastChargeLevel = ch
                                UserDefaults.standard.set(ch, forKey: "mbs_lastChargeLevel")
                            }
                            UserDefaults.standard.set(unplug.date.timeIntervalSince1970, forKey: "mbs_lastChargeTimestamp")
                        }
                    }
                }
            } catch {
                // 读取失败静默忽略
            }
        }
    }
    
    /// 异步获取 macOS 系统官方认定的电池最大容量百分比
    public func refreshSystemMaxCapacity() {
        queue.async { [weak self] in
            let pipe = Pipe()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            proc.arguments = ["SPPowerDataType", "-detailLevel", "basic"]
            proc.standardOutput = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                let outData = pipe.fileHandleForReading.readDataToEndOfFile()
                if let str = String(data: outData, encoding: .utf8) {
                    for line in str.components(separatedBy: "\n") {
                        if line.contains("Maximum Capacity:") {
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            let numStr = trimmed.replacingOccurrences(of: "Maximum Capacity:", with: "")
                                                .replacingOccurrences(of: "%", with: "")
                                                .trimmingCharacters(in: .whitespaces)
                            if let val = Double(numStr) {
                                DispatchQueue.main.async {
                                    self?.cachedSystemMaxCapacity = val
                                }
                                break
                            }
                        }
                    }
                }
            } catch {
                // 异常时回退到 IOKit 物理容量比值计算
            }
        }
    }
}
