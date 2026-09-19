import Foundation
import IOKit
import SwiftUI

// MARK: - IOHIDEventSystemClient 私有 C 符号声明 (Apple Silicon 原生读取)
typealias IOHIDEventSystemClientRef = CFTypeRef
typealias IOHIDServiceClientRef = CFTypeRef
typealias IOHIDEventRef = CFTypeRef

@_silgen_name("IOHIDEventSystemClientCreate")
private func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> IOHIDEventSystemClientRef?

@_silgen_name("IOHIDEventSystemClientSetMatching")
private func IOHIDEventSystemClientSetMatching(_ client: IOHIDEventSystemClientRef, _ match: CFDictionary) -> Int32

@_silgen_name("IOHIDEventSystemClientCopyServices")
private func IOHIDEventSystemClientCopyServices(_ client: IOHIDEventSystemClientRef) -> CFArray?

@_silgen_name("IOHIDServiceClientCopyEvent")
private func IOHIDServiceClientCopyEvent(_ service: IOHIDServiceClientRef, _ type: Int64, _ options: Int32, _ timeout: Int64) -> IOHIDEventRef?

@_silgen_name("IOHIDEventGetFloatValue")
private func IOHIDEventGetFloatValue(_ event: IOHIDEventRef, _ field: UInt32) -> Double

@_silgen_name("IOHIDServiceClientCopyProperty")
private func IOHIDServiceClientCopyProperty(_ service: IOHIDServiceClientRef, _ property: CFString) -> CFTypeRef?

private let IOHIDEventTypeTemperature: Int64 = 15
private let IOHIDEventFieldTemperatureLevel: UInt32 = (15 << 16)

// MARK: - 温度单位
public enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "摄氏度 (°C)"
    case fahrenheit = "华氏度 (°F)"
    
    public var id: String { self.rawValue }
    public var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

// MARK: - 监控目标
public enum TemperatureTarget: String, CaseIterable, Identifiable {
    case cpu = "CPU / SoC 均温"
    case highest = "最高硬件温度"
    case cpuMax = "CPU 峰值温度"
    case ssd = "固态硬盘 (SSD)"
    case battery = "电池温度"
    
    public var id: String { self.rawValue }
}

// MARK: - 文本显示模式
public enum TempDisplayMode: String, CaseIterable, Identifiable {
    case value = "仅数值 (如 43°)"
    case valueWithUnit = "数值与单位 (如 43°C)"
    case none = "仅图标"
    
    public var id: String { self.rawValue }
}

// MARK: - 文字对齐方式
public enum TempTextAlign: String, CaseIterable, Identifiable {
    case right = "右对齐 (推荐，最稳固)"
    case center = "居中对齐"
    case left = "左对齐"
    
    public var id: String { self.rawValue }
    
    public var alignment: SwiftUI.Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
    
    public var horizontalAlignment: SwiftUI.HorizontalAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

// MARK: - 单个硬件温度传感器明细项 (纯中文标签与类别排序)
public struct TemperatureSensorItem: Identifiable, Hashable {
    public var id: String { name }
    public let key: String
    public let name: String
    public let category: String
    public let order: Int
    public let celsius: Double
    
    public init(key: String, name: String, category: String, order: Int, celsius: Double) {
        self.key = key
        self.name = name
        self.category = category
        self.order = order
        self.celsius = celsius
    }
}

// MARK: - 硬件温度大类分组模型 (支持收起/展开与智能摘要)
public struct TemperatureGroup: Identifiable, Hashable {
    public var id: String { category }
    public let name: String           // 分组中文名称
    public let icon: String           // SF Symbol 图标
    public let category: String       // 唯一分类标识
    public let sensors: [TemperatureSensorItem]
    public let avgTemp: Double        // 组均温
    public let maxTemp: Double        // 组最高温
    public let summaryMode: SummaryMode
    
    public enum SummaryMode: Hashable {
        case avgWithMax // 均温 (峰值)
        case avg        // 均温
        case max        // 最高温
    }
    
    public func formattedSummary(unit: TemperatureUnit) -> String {
        let fmt: (Double) -> String = { val in
            let v = (unit == .fahrenheit) ? (val * 9.0 / 5.0 + 32.0) : val
            return String(format: "%.0f%@", round(v), unit.symbol)
        }
        switch summaryMode {
        case .avgWithMax:
            let avgStr = fmt(avgTemp)
            if maxTemp > avgTemp + 1.0 {
                return "\(avgStr) (峰值 \(fmt(maxTemp)))"
            }
            return avgStr
        case .avg:
            return fmt(avgTemp)
        case .max:
            return fmt(maxTemp)
        }
    }
}

public struct TemperatureSnapshot: Equatable {
    public var sensors: [TemperatureSensorItem] = [] // 所有已检测到的硬件探针明细列表
    public var groups: [TemperatureGroup] = []       // 结构化硬件大类分组列表
    public var cpuTemperature: Double = 0.0          // CPU / SoC 核心均温
    public var cpuMaxTemperature: Double = 0.0       // CPU 峰值温度
    public var gpuTemperature: Double = 0.0          // GPU 核心温度
    public var batteryTemperature: Double = 0.0      // 电池温度
    public var ssdTemperature: Double = 0.0          // 固态硬盘温度
    public var highestTemperature: Double = 0.0      // 全系统最高温度
    public var highestSensorName: String = ""        // 最高温传感器名称
    public var sensorCount: Int = 0                  // 联通的探针总数
    public var hasData: Bool = false
    
    public func targetValue(for target: TemperatureTarget) -> Double {
        switch target {
        case .cpu: return cpuTemperature > 0 ? cpuTemperature : highestTemperature
        case .highest: return highestTemperature
        case .cpuMax: return cpuMaxTemperature > 0 ? cpuMaxTemperature : highestTemperature
        case .ssd: return ssdTemperature > 0 ? ssdTemperature : (cpuTemperature > 0 ? cpuTemperature : highestTemperature)
        case .battery: return batteryTemperature > 0 ? batteryTemperature : (cpuTemperature > 0 ? cpuTemperature : highestTemperature)
        }
    }
    
    public func formattedString(target: TemperatureTarget, unit: TemperatureUnit, mode: TempDisplayMode) -> String {
        guard hasData else { return "--" }
        let cValue = targetValue(for: target)
        guard cValue > 0 else { return "--" }
        
        let displayVal = (unit == .fahrenheit) ? (cValue * 9.0 / 5.0 + 32.0) : cValue
        switch mode {
        case .value:
            return String(format: "%.0f°", round(displayVal))
        case .valueWithUnit:
            return String(format: "%.0f%@", round(displayVal), unit.symbol)
        case .none:
            return ""
        }
    }
    
    public func displayValue(celsiusValue: Double, unit: TemperatureUnit) -> String {
        guard celsiusValue > 0 else { return "--" }
        let v = (unit == .fahrenheit) ? (celsiusValue * 9.0 / 5.0 + 32.0) : celsiusValue
        return String(format: "%.0f%@", round(v), unit.symbol)
    }
    
    public func formatSensorValue(celsius: Double, unit: TemperatureUnit) -> String {
        guard celsius > 0 else { return "--" }
        let v = (unit == .fahrenheit) ? (celsius * 9.0 / 5.0 + 32.0) : celsius
        return String(format: "%.0f%@", round(v), unit.symbol)
    }
}

public final class TemperatureMonitor {
    public static let shared = TemperatureMonitor()
    
    private var hidClient: IOHIDEventSystemClientRef? = nil
    private var cachedServices: [IOHIDServiceClientRef] = []
    private var serviceNames: [String] = []
    private var isAppleSilicon: Bool = false
    
    // MARK: - 跨平台/跨机型 SMC 传感器权威中文映射字典 (涵盖 Apple Silicon M1-M4 及 Intel)
    private let knownSensorDefinitions: [(key: String, name: String, category: String, order: Int)] = [
        // CPU 性能核心 (P-Core)
        ("TfC0", "CPU 性能核心 1", "CPU", 10),
        ("TfC1", "CPU 性能核心 2", "CPU", 11),
        ("TfC2", "CPU 性能核心 3", "CPU", 12),
        ("TfC3", "CPU 性能核心 4", "CPU", 13),
        ("TfC4", "CPU 性能核心 5", "CPU", 14),
        ("TfC5", "CPU 性能核心 6", "CPU", 15),
        ("TfC6", "CPU 性能核心 7", "CPU", 16),
        ("TfC7", "CPU 性能核心 8", "CPU", 17),
        ("Tp01", "CPU 性能核心 1", "CPU", 10),
        ("Tp05", "CPU 性能核心 2", "CPU", 11),
        ("Tp09", "CPU 性能核心 3", "CPU", 12),
        ("Tp0D", "CPU 性能核心 4", "CPU", 13),
        ("Tp0H", "CPU 性能核心 5", "CPU", 14),
        ("Tp0L", "CPU 性能核心 6", "CPU", 15),
        ("Tp0P", "CPU 性能核心 7", "CPU", 16),
        ("Tp0X", "CPU 性能核心 8", "CPU", 17),
        ("Tf04", "CPU 性能核心 1", "CPU", 10),
        ("Tf09", "CPU 性能核心 2", "CPU", 11),
        
        // CPU 能效核心 (E-Core)
        ("Tp0T", "CPU 能效核心 1", "CPU", 18),
        ("Tp0e", "CPU 能效核心 2", "CPU", 19),
        ("Te05", "CPU 能效核心 1", "CPU", 18),
        ("Te0L", "CPU 能效核心 2", "CPU", 19),
        
        // CPU Die / Heatsink (Intel)
        ("TC0D", "CPU 芯片核心", "CPU", 20),
        ("TC0E", "CPU 二极管", "CPU", 21),
        ("TC0F", "CPU 滤波温区", "CPU", 22),
        ("TC0H", "CPU 散热鳍片", "CPU", 23),
        ("TC1C", "CPU 核心 1", "CPU", 24),
        ("TC2C", "CPU 核心 2", "CPU", 25),
        
        // GPU
        ("Tg08", "GPU 核心 1", "GPU", 30),
        ("Tg0C", "GPU 核心 2", "GPU", 31),
        ("Tg0O", "GPU 核心 3", "GPU", 32),
        ("Tg0R", "GPU 核心 4", "GPU", 33),
        ("Tg0U", "GPU 核心 5", "GPU", 34),
        ("Tg0X", "GPU 核心 6", "GPU", 35),
        ("Tg0a", "GPU 核心 7", "GPU", 36),
        ("Tg0d", "GPU 核心 8", "GPU", 37),
        ("Tg05", "GPU 核心 1", "GPU", 30),
        ("Tg0D", "GPU 核心 2", "GPU", 31),
        ("TG0D", "GPU 二极管", "GPU", 38),
        ("TG0P", "GPU 邻近温区", "GPU", 39),
        ("TG0H", "GPU 散热鳍片", "GPU", 40),
        
        // SoC
        ("Ts00", "SoC 芯片 1", "SOC", 50),
        ("Ts04", "SoC 芯片 2", "SOC", 51),
        ("Ts0C", "SoC 芯片 3", "SOC", 52),
        ("Ts08", "SoC 芯片 8", "SOC", 53),
        ("Ts0P", "SoC 邻近温区", "SOC", 54),
        ("TS0P", "SoC 邻近温区", "SOC", 54),
        
        // 内存 (Memory)
        ("Tm00", "内存颗粒 1", "Memory", 60),
        ("Tm02", "内存颗粒 2", "Memory", 61),
        ("Tm04", "内存颗粒 5", "Memory", 62),
        ("Tm06", "内存颗粒 6", "Memory", 63),
        ("Tm08", "内存颗粒 9", "Memory", 64),
        ("Tm0C", "内存颗粒 10", "Memory", 65),
        ("Tm12", "内存颗粒 12", "Memory", 66),
        ("Tm1E", "内存颗粒 12", "Memory", 66),
        ("Tm21", "内存颗粒 22", "Memory", 67),
        ("Tm22", "内存颗粒 22", "Memory", 67),
        ("Tm0P", "内存邻近温区", "Memory", 68),
        
        // 固态硬盘 (SSD / NAND)
        ("TH0x", "固态硬盘 (SSD 1)", "Storage", 70),
        ("TH0a", "固态闪存颗粒 1", "Storage", 71),
        ("TH0b", "固态闪存颗粒 2", "Storage", 72),
        ("TH0P", "固态硬盘温区", "Storage", 73),
        
        // 电池
        ("TB0T", "电池电芯 0", "Battery", 80),
        ("TB1T", "电池电芯 1", "Battery", 81),
        ("TB2T", "电池电芯 2", "Battery", 82),
        ("Tb00", "电池电芯 0", "Battery", 80),
        ("Tb01", "电池电芯 1", "Battery", 81),
        ("Tb02", "电池电芯 2", "Battery", 82),
        
        // 风道
        ("TaLP", "左侧散热风道", "Airflow", 90),
        ("TaRF", "右侧散热风道", "Airflow", 91),
        
        // 电源供电模块与充电器 (Power Supply)
        ("TCHP", "充电接口模块", "Power", 100),
        ("TC0P", "充电接口模块", "Power", 100),
        ("TPMP", "主电源供电模块", "Power", 101),
        ("TPSP", "辅助电源供电模块", "Power", 102),
        ("TP0P", "主电源供电模块", "Power", 101),
        
        // 机身掌托 (Palm Rest)
        ("Tp00", "左侧掌托表面", "Enclosure", 110),
        ("Tp04", "右侧掌托表面", "Enclosure", 111),
        ("Tp10", "左侧掌托表面", "Enclosure", 110),
        ("Tp11", "右侧掌托表面", "Enclosure", 111),
        
        // 无线网卡 / 蓝牙感温 (Wireless)
        ("TW0P", "无线网络模块", "Network", 120)
    ]
    
    private var activeSensorDefinitions: [(key: String, name: String, category: String, order: Int)]? = nil
    
    private init() {
        checkArchitecture()
        setupHIDClient()
    }
    
    private func checkArchitecture() {
        var size: Int = 0
        sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
        var arm64: Int32 = 0
        let ret = sysctlbyname("hw.optional.arm64", &arm64, &size, nil, 0)
        isAppleSilicon = (ret == 0 && arm64 == 1)
    }
    
    private func setupHIDClient() {
        guard let client = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else { return }
        self.hidClient = client
        
        let matchDict: [String: Any] = [
            "PrimaryUsagePage": 0xff00,
            "PrimaryUsage": 0x0005
        ]
        _ = IOHIDEventSystemClientSetMatching(client, matchDict as CFDictionary)
        if let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClientRef] {
            // 核心性能优化：在初始化阶段对数十个 HID 服务进行白名单过滤，仅保留真实相关的 SSD/电池硬件
            var filteredServices: [IOHIDServiceClientRef] = []
            var filteredNames: [String] = []
            for service in services {
                let name = (IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String) ?? ""
                let lower = name.lowercased()
                if lower.contains("nand") || lower.contains("ssd") || lower.contains("battery") {
                    filteredServices.append(service)
                    filteredNames.append(name)
                }
            }
            self.cachedServices = filteredServices
            self.serviceNames = filteredNames
        }
    }
    
    public func update(isDetailed: Bool = true) -> TemperatureSnapshot {
        var snapshot = TemperatureSnapshot()
        var scannedSensors: [String: TemperatureSensorItem] = [:]
        
        // 1. 优先扫描权威 SMC 温度传感器（首次发现后只针对当前机型真实存在的硬件探针读取）
        let defsToScan = activeSensorDefinitions ?? knownSensorDefinitions
        for item in defsToScan {
            if scannedSensors[item.name] != nil { continue }
            if let temp = SMCReader.shared.readTemperatureValue(key: item.key) {
                scannedSensors[item.name] = TemperatureSensorItem(
                    key: item.key,
                    name: item.name,
                    category: item.category,
                    order: item.order,
                    celsius: temp
                )
            }
        }
        if activeSensorDefinitions == nil && !scannedSensors.isEmpty {
            let activeKeys = Set(scannedSensors.values.map(\.key))
            self.activeSensorDefinitions = knownSensorDefinitions.filter { activeKeys.contains($0.key) }
        }
        
        // 2. 补充读取 Apple Silicon 原生 IOHID 探针 (仅当 SMC 未能读取 SSD 或电池时才读取精简后的 1~2 个服务)
        if scannedSensors["固态硬盘 (SSD 1)"] == nil || scannedSensors["电池电芯 0"] == nil {
            readFromHID(scannedSensors: &scannedSensors)
        }
        
        // 3. 电池温度兜底：从 AppleSmartBattery 读取
        if scannedSensors["电池电芯 0"] == nil && scannedSensors["电池"] == nil {
            if let batTemp = readSmartBatteryTemp() {
                scannedSensors["电池电芯 0"] = TemperatureSensorItem(
                    key: "BATT",
                    name: "电池电芯 0",
                    category: "Battery",
                    order: 80,
                    celsius: batTemp
                )
            }
        }
        
        // 4. 计算综合温度指标与分类汇总
        let allSensors = Array(scannedSensors.values)
        if !allSensors.isEmpty {
            snapshot.hasData = true
            snapshot.sensorCount = allSensors.count
            // 按照硬件大类优先级 + 序号自然排序
            snapshot.sensors = allSensors.sorted {
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            
            // 最高温热点
            if let maxItem = allSensors.max(by: { $0.celsius < $1.celsius }) {
                snapshot.highestTemperature = maxItem.celsius
                snapshot.highestSensorName = maxItem.name
            }
            
            // CPU / SoC 均温与峰值
            let cpuSensors = allSensors.filter { $0.category == "CPU" || $0.category == "SOC" || $0.name.contains("核心") }
            if !cpuSensors.isEmpty {
                snapshot.cpuTemperature = cpuSensors.map(\.celsius).reduce(0, +) / Double(cpuSensors.count)
                snapshot.cpuMaxTemperature = cpuSensors.map(\.celsius).max() ?? snapshot.cpuTemperature
            } else {
                snapshot.cpuTemperature = snapshot.highestTemperature
                snapshot.cpuMaxTemperature = snapshot.highestTemperature
            }
            
            // GPU
            let gpuSensors = allSensors.filter { $0.category == "GPU" }
            if !gpuSensors.isEmpty {
                snapshot.gpuTemperature = gpuSensors.map(\.celsius).reduce(0, +) / Double(gpuSensors.count)
            }
            
            // 电池
            let batSensors = allSensors.filter { $0.category == "Battery" }
            if !batSensors.isEmpty {
                snapshot.batteryTemperature = batSensors.map(\.celsius).reduce(0, +) / Double(batSensors.count)
            }
            
            // SSD
            let ssdSensors = allSensors.filter { $0.category == "Storage" }
            if let firstSSD = ssdSensors.first {
                snapshot.ssdTemperature = firstSSD.celsius
            }
            
            // 5. 仅在需要详细视图（弹窗打开）时构建有序的硬件大类分组与总结性数据
            if isDetailed {
                var grouped: [String: [TemperatureSensorItem]] = [:]
                for s in snapshot.sensors {
                    grouped[s.category, default: []].append(s)
                }
                
                let categoryConfigs: [(cat: String, name: String, icon: String, mode: TemperatureGroup.SummaryMode)] = [
                    ("CPU", "中央处理器", "cpu", .avgWithMax),
                    ("GPU", "图形处理器", "display", .avg),
                    ("SOC", "SoC 芯片", "cpu.fill", .avg),
                    ("Memory", "统一内存", "memorychip", .avg),
                    ("Storage", "固态硬盘", "internaldrive", .max),
                    ("Battery", "电池电芯", "battery.100", .avg),
                    ("Airflow", "散热风道", "wind", .avg),
                    ("Power", "供电模块", "bolt.fill", .max),
                    ("Enclosure", "机身掌托", "laptopcomputer", .max),
                    ("Network", "无线网络", "wifi", .max)
                ]
                
                var groupList: [TemperatureGroup] = []
                for cfg in categoryConfigs {
                    if let list = grouped[cfg.cat], !list.isEmpty {
                        let avg = list.map(\.celsius).reduce(0, +) / Double(list.count)
                        let maxVal = list.map(\.celsius).max() ?? avg
                        groupList.append(TemperatureGroup(
                            name: cfg.name,
                            icon: cfg.icon,
                            category: cfg.cat,
                            sensors: list,
                            avgTemp: avg,
                            maxTemp: maxVal,
                            summaryMode: cfg.mode
                        ))
                    }
                }
                snapshot.groups = groupList
            }
        }
        
        return snapshot
    }
    
    private func readFromHID(scannedSensors: inout [String: TemperatureSensorItem]) {
        if cachedServices.isEmpty {
            setupHIDClient()
        }
        guard !cachedServices.isEmpty else { return }
        
        for (i, service) in cachedServices.enumerated() {
            guard let event = IOHIDServiceClientCopyEvent(service, IOHIDEventTypeTemperature, 0, 0) else { continue }
            let temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldTemperatureLevel)
            guard temp >= 10.0 && temp <= 125.0 else { continue }
            
            let name = i < serviceNames.count ? serviceNames[i] : ""
            let lower = name.lowercased()
            
            if lower.contains("nand") || lower.contains("ssd") {
                if scannedSensors["固态硬盘 (SSD 1)"] == nil {
                    scannedSensors["固态硬盘 (SSD 1)"] = TemperatureSensorItem(key: "HID_SSD", name: "固态硬盘 (SSD 1)", category: "Storage", order: 70, celsius: temp)
                }
            } else if lower.contains("battery") {
                if scannedSensors["电池电芯 0"] == nil {
                    scannedSensors["电池电芯 0"] = TemperatureSensorItem(key: "HID_BAT", name: "电池电芯 0", category: "Battery", order: 80, celsius: temp)
                }
            }
        }
    }
    
    private func readSmartBatteryTemp() -> Double? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        
        var props: Unmanaged<CFMutableDictionary>?
        if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
           let dict = props?.takeRetainedValue() as? [String: Any],
           let rawT = dict["Temperature"] as? Double, rawT > 0 {
            return rawT / 100.0
        }
        return nil
    }
}
