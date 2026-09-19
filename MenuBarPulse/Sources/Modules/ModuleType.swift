import SwiftUI

// MARK: - 统一功能模块枚举定义 (ModuleType)
public enum ModuleType: String, CaseIterable, Identifiable, Codable {
    case network = "network"
    case battery = "battery"
    case fan = "fan"
    case temperature = "temperature"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .network: return "网络 (Network)"
        case .battery: return "电池 (Battery)"
        case .fan: return "风扇 (Fans)"
        case .temperature: return "温度 (Temperature)"
        }
    }
    
    public var shortName: String {
        switch self {
        case .network: return "网络"
        case .battery: return "电池"
        case .fan: return "风扇"
        case .temperature: return "温度"
        }
    }
    
    public var iconName: String {
        switch self {
        case .network: return "wifi"
        case .battery: return "battery.100.bolt"
        case .fan: return "fan.fill"
        case .temperature: return "thermometer.medium"
        }
    }
    
    public var defaultColor: Color {
        switch self {
        case .network: return .blue
        case .battery: return .green
        case .fan: return .cyan
        case .temperature: return .orange
        }
    }
    
    public static var defaultOrder: [ModuleType] {
        return [.network, .battery, .fan, .temperature]
    }
}
