import SwiftUI
import Combine
import ServiceManagement

// MARK: - 可配置通用颜色选项 (支持每个模块独立选择)
public enum ColorOption: String, CaseIterable, Identifiable {
    case green = "翡翠绿"
    case cyan = "科技青"
    case blue = "深邃蓝"
    case orange = "活力橙"
    case yellow = "日光黄"
    case purple = "极光紫"
    case pink = "霓虹粉"
    case monochrome = "系统单色 (黑白)"
    
    public var id: String { self.rawValue }
    
    public var color: Color {
        switch self {
        case .green: return Color(red: 0.2, green: 0.85, blue: 0.35)
        case .cyan: return Color(red: 0.2, green: 0.8, blue: 1.0)
        case .blue: return Color(red: 0.18, green: 0.62, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.55, blue: 0.15)
        case .yellow: return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .purple: return Color(red: 0.75, green: 0.35, blue: 1.0)
        case .pink: return Color(red: 1.0, green: 0.35, blue: 0.65)
        case .monochrome: return .primary
        }
    }
}

// MARK: - 网络指示器图标形态
public enum NetItemType: String, CaseIterable, Identifiable {
    case arrow = "经典箭头 (▲/▼)"
    case dot = "双圆点 (●)"
    case square = "双方块 (■)"
    case none = "无图标 (仅文字)"
    
    public var id: String { self.rawValue }
}

// MARK: - 网络指示器排版模式
public enum NetIndicatorStyle: String, CaseIterable, Identifiable {
    case stack = "上下双行微型堆叠"
    case opposed = "左右并排显示"
    
    public var id: String { self.rawValue }
}

// MARK: - 网络流速文字对齐方式
public enum NetTextAlign: String, CaseIterable, Identifiable {
    case right = "右对齐 (推荐，最稳固)"
    case center = "居中对齐"
    case left = "左对齐"
    
    public var id: String { self.rawValue }
    
    public var alignment: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
    
    public var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

// MARK: - 网络指示器色彩模式
public enum NetColorMode: String, CaseIterable, Identifiable {
    case achromatic = "系统黑白单色 (推荐)"
    case achromaticDynamic = "动态黑白单色"
    case colored = "经典固定彩色"
    case coloredDynamic = "动态流速彩色"
    
    public var id: String { self.rawValue }
}

// MARK: - 菜单栏模块显示模式
public enum ModuleDisplayMode: String, CaseIterable, Identifiable {
    case combined = "合并模式 (整合为一个菜单栏项)"
    case standalone = "独立模式 (各模块分离，可拖拽排序)"
    
    public var id: String { self.rawValue }
}

// MARK: - 菜单栏文字色彩模式
public enum TextColorMode: String, CaseIterable, Identifiable {
    case monochrome = "系统固定黑白 (防抖防跳，推荐)"
    case matchIndicator = "跟随指示器专属颜色"
    case custom = "固定自定义文字颜色"
    
    public var id: String { self.rawValue }
}

// MARK: - 网络流速单位换算
public enum NetTrafficUnit: String, CaseIterable, Identifiable {
    case kbs = "字节制 (B/s, KB/s, MB/s)"
    case bits = "比特制 (b/s, Kb/s, Mb/s)"
    case auto = "智能自适应"
    
    public var id: String { self.rawValue }
}

// MARK: - 电池颜色模式
public enum BatteryColorMode: String, CaseIterable, Identifiable {
    case dynamic = "智能动态变色 (绿/黄/红)"
    case achromatic = "系统黑白单色"
    case custom = "固定自定义颜色"
    
    public var id: String { self.rawValue }
}

// MARK: - 电池图标形态
public enum BatteryIconStyle: String, CaseIterable, Identifiable {
    case embedded = "一体化胶囊 (百分比+充电状态内嵌在图标中，推荐)"
    case regular = "经典水平胶囊 (图标与文字外部分离)"
    case vertical = "垂直立式电池"
    case circleGauge = "环形刻度表盘"
    
    public var id: String { self.rawValue }
}

// MARK: - 电池文字显示模式
public enum BatTextMode: String, CaseIterable, Identifiable {
    case percentage = "显示电量百分比 (如 95%)"
    case health = "显示健康寿命百分比 (如 82%)"
    case percentageAndHealth = "显示电量与健康寿命 (如 95% | 82%)"
    case cycle = "显示循环计数 (如 285次)"
    case timeRemaining = "显示剩余可用时间 (如 4:30)"
    case both = "同时显示百分比与时间 (如 95% 4:30)"
    case none = "不显示外部文字 (仅显示图标)"
    
    public var id: String { self.rawValue }
}

// MARK: - 风扇文字显示模式
public enum FanTextMode: String, CaseIterable, Identifiable {
    case rpm = "显示转速 (如 2100 rpm)"
    case percentage = "显示转速百分比 (如 42%)"
    case none = "不显示文字"
    
    public var id: String { self.rawValue }
}

// MARK: - 风扇目标与多风扇展示模式
public enum FanTargetSelect: String, CaseIterable, Identifiable {
    case bothSide = "左右双风扇并列 (如 1850 / 1900 rpm)"
    case bothStack = "左右双风扇上下堆叠 (双行 L/R)"
    case highest = "最高转速风扇 (单值)"
    case fan1 = "仅显示左侧风扇 (L)"
    case fan2 = "仅显示右侧风扇 (R)"
    
    public var id: String { self.rawValue }
}

// MARK: - 风扇文字对齐方式
public enum FanTextAlign: String, CaseIterable, Identifiable {
    case right = "右对齐 (推荐，最稳固)"
    case center = "居中对齐"
    case left = "左对齐"
    
    public var id: String { self.rawValue }
    
    public var alignment: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
    
    public var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

// MARK: - 面板全局强调主题色
public enum AccentTheme: String, CaseIterable, Identifiable {
    case cyan = "科技青 (Cyan)"
    case blue = "经典蓝 (Blue)"
    case green = "翡翠绿 (Green)"
    case orange = "日落橙 (Orange)"
    case purple = "极光紫 (Purple)"
    
    public var id: String { self.rawValue }
    
    public var color: Color {
        switch self {
        case .cyan: return .cyan
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        }
    }
}

@MainActor
public final class PreferencesState: ObservableObject {
    public static let shared = PreferencesState()
    
    // MARK: - 界面导航状态
    @Published public var selectedTab: Int = 0
    
    // MARK: - 通用设置 (General)
    @Published public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "mbs_launchAtLogin")
            updateLaunchAtLoginService()
        }
    }
    @Published public var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "mbs_refreshInterval") }
    }
    @Published public var pinWindow: Bool {
        didSet { UserDefaults.standard.set(pinWindow, forKey: "mbs_pinWindow") }
    }
    @Published public var moduleDisplayMode: ModuleDisplayMode {
        didSet { UserDefaults.standard.set(moduleDisplayMode.rawValue, forKey: "mbs_moduleDisplayMode") }
    }
    @Published public var accentTheme: AccentTheme {
        didSet { UserDefaults.standard.set(accentTheme.rawValue, forKey: "mbs_accentTheme") }
    }
    
    // MARK: - 卡片模块排序 (Card Module Order)
    @Published public var cardModuleOrder: [ModuleType] {
        didSet {
            let rawList = cardModuleOrder.map { $0.rawValue }
            UserDefaults.standard.set(rawList, forKey: "mbs_cardModuleOrder")
        }
    }
    @Published public var draggedCardModule: ModuleType? = nil

    
    // MARK: - 网络模块设置 (Network)
    @Published public var netShowInMenuBar: Bool {
        didSet { UserDefaults.standard.set(netShowInMenuBar, forKey: "mbs_netShowInMenuBar") }
    }
    @Published public var netShowInWindow: Bool {
        didSet { UserDefaults.standard.set(netShowInWindow, forKey: "mbs_netShowInWindow") }
    }
    @Published public var netShowThroughput: Bool {
        didSet { UserDefaults.standard.set(netShowThroughput, forKey: "mbs_netShowThroughput") }
    }
    @Published public var netShowModuleName: Bool {
        didSet { UserDefaults.standard.set(netShowModuleName, forKey: "mbs_netShowModuleName") }
    }
    @Published public var netItemType: NetItemType {
        didSet { UserDefaults.standard.set(netItemType.rawValue, forKey: "mbs_netItemType") }
    }
    @Published public var netIndicatorStyle: NetIndicatorStyle {
        didSet { UserDefaults.standard.set(netIndicatorStyle.rawValue, forKey: "mbs_netIndicatorStyle") }
    }
    @Published public var netTextAlign: NetTextAlign {
        didSet { UserDefaults.standard.set(netTextAlign.rawValue, forKey: "mbs_netTextAlign") }
    }
    @Published public var netColorMode: NetColorMode {
        didSet { UserDefaults.standard.set(netColorMode.rawValue, forKey: "mbs_netColorMode") }
    }
    @Published public var netUploadColor: ColorOption {
        didSet { UserDefaults.standard.set(netUploadColor.rawValue, forKey: "mbs_netUploadColor") }
    }
    @Published public var netDownloadColor: ColorOption {
        didSet { UserDefaults.standard.set(netDownloadColor.rawValue, forKey: "mbs_netDownloadColor") }
    }
    @Published public var netTextColorMode: TextColorMode {
        didSet { UserDefaults.standard.set(netTextColorMode.rawValue, forKey: "mbs_netTextColorMode") }
    }
    @Published public var netCustomTextColor: ColorOption {
        didSet { UserDefaults.standard.set(netCustomTextColor.rawValue, forKey: "mbs_netCustomTextColor") }
    }
    @Published public var netTrafficUnit: NetTrafficUnit {
        didSet { UserDefaults.standard.set(netTrafficUnit.rawValue, forKey: "mbs_netTrafficUnit") }
    }
    @Published public var netShowUnitSuffix: Bool {
        didSet { UserDefaults.standard.set(netShowUnitSuffix, forKey: "mbs_netShowUnitSuffix") }
    }
    @Published public var netNotShowLowTraffic: Bool {
        didSet { UserDefaults.standard.set(netNotShowLowTraffic, forKey: "mbs_netNotShowLowTraffic") }
    }
    
    // MARK: - 电池模块设置 (Battery)
    @Published public var batShowInMenuBar: Bool {
        didSet { UserDefaults.standard.set(batShowInMenuBar, forKey: "mbs_batShowInMenuBar") }
    }
    @Published public var batShowInWindow: Bool {
        didSet { UserDefaults.standard.set(batShowInWindow, forKey: "mbs_batShowInWindow") }
    }
    @Published public var batShowModuleName: Bool {
        didSet { UserDefaults.standard.set(batShowModuleName, forKey: "mbs_batShowModuleName") }
    }
    @Published public var batShowIcon: Bool {
        didSet { UserDefaults.standard.set(batShowIcon, forKey: "mbs_batShowIcon") }
    }
    @Published public var batteryIconStyle: BatteryIconStyle {
        didSet { UserDefaults.standard.set(batteryIconStyle.rawValue, forKey: "mbs_batteryIconStyle") }
    }
    @Published public var batTextMode: BatTextMode {
        didSet { UserDefaults.standard.set(batTextMode.rawValue, forKey: "mbs_batTextMode") }
    }
    @Published public var batColorMode: BatteryColorMode {
        didSet { UserDefaults.standard.set(batColorMode.rawValue, forKey: "mbs_batColorMode") }
    }
    @Published public var batCustomColor: ColorOption {
        didSet { UserDefaults.standard.set(batCustomColor.rawValue, forKey: "mbs_batCustomColor") }
    }
    
    // MARK: - 风扇模块设置 (Fans)
    @Published public var fanShowInMenuBar: Bool {
        didSet { UserDefaults.standard.set(fanShowInMenuBar, forKey: "mbs_fanShowInMenuBar") }
    }
    @Published public var fanShowInWindow: Bool {
        didSet { UserDefaults.standard.set(fanShowInWindow, forKey: "mbs_fanShowInWindow") }
    }
    @Published public var fanShowIcon: Bool {
        didSet { UserDefaults.standard.set(fanShowIcon, forKey: "mbs_fanShowIcon") }
    }
    @Published public var fanShowModuleName: Bool {
        didSet { UserDefaults.standard.set(fanShowModuleName, forKey: "mbs_fanShowModuleName") }
    }
    @Published public var fanTextMode: FanTextMode {
        didSet { UserDefaults.standard.set(fanTextMode.rawValue, forKey: "mbs_fanTextMode") }
    }
    @Published public var fanTextAlign: FanTextAlign {
        didSet { UserDefaults.standard.set(fanTextAlign.rawValue, forKey: "mbs_fanTextAlign") }
    }
    @Published public var fanTarget: FanTargetSelect {
        didSet { UserDefaults.standard.set(fanTarget.rawValue, forKey: "mbs_fanTarget") }
    }
    @Published public var fanColor: ColorOption {
        didSet { UserDefaults.standard.set(fanColor.rawValue, forKey: "mbs_fanColor") }
    }
    
    // MARK: - 温度模块设置 (Temperature)
    @Published public var tempShowInMenuBar: Bool {
        didSet { UserDefaults.standard.set(tempShowInMenuBar, forKey: "mbs_tempShowInMenuBar") }
    }
    @Published public var tempShowInWindow: Bool {
        didSet { UserDefaults.standard.set(tempShowInWindow, forKey: "mbs_tempShowInWindow") }
    }
    @Published public var tempShowIcon: Bool {
        didSet { UserDefaults.standard.set(tempShowIcon, forKey: "mbs_tempShowIcon") }
    }
    @Published public var tempShowModuleName: Bool {
        didSet { UserDefaults.standard.set(tempShowModuleName, forKey: "mbs_tempShowModuleName") }
    }
    @Published public var tempDisplayMode: TempDisplayMode {
        didSet { UserDefaults.standard.set(tempDisplayMode.rawValue, forKey: "mbs_tempDisplayMode") }
    }
    @Published public var tempTarget: TemperatureTarget {
        didSet { UserDefaults.standard.set(tempTarget.rawValue, forKey: "mbs_tempTarget") }
    }
    @Published public var tempUnit: TemperatureUnit {
        didSet { UserDefaults.standard.set(tempUnit.rawValue, forKey: "mbs_tempUnit") }
    }
    @Published public var tempTextAlign: TempTextAlign {
        didSet { UserDefaults.standard.set(tempTextAlign.rawValue, forKey: "mbs_tempTextAlign") }
    }
    @Published public var tempColor: ColorOption {
        didSet { UserDefaults.standard.set(tempColor.rawValue, forKey: "mbs_tempColor") }
    }
    
    private init() {
        let savedInterval = UserDefaults.standard.double(forKey: "mbs_refreshInterval")
        self.refreshInterval = savedInterval >= 0.5 ? savedInterval : 1.0
        if #available(macOS 13.0, *) {
            let isEnabled = (SMAppService.mainApp.status == .enabled)
            let saved = UserDefaults.standard.object(forKey: "mbs_launchAtLogin") as? Bool ?? false
            let isLaunch = isEnabled || saved
            self.launchAtLogin = isLaunch
            if isLaunch && !isEnabled {
                try? SMAppService.mainApp.register()
            }
        } else {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "mbs_launchAtLogin")
        }
        self.pinWindow = UserDefaults.standard.bool(forKey: "mbs_pinWindow")
        
        if let modeStr = UserDefaults.standard.string(forKey: "mbs_moduleDisplayMode"),
           let mode = ModuleDisplayMode.allCases.first(where: { $0.rawValue == modeStr }) {
            self.moduleDisplayMode = mode
        } else {
            self.moduleDisplayMode = .combined
        }
        
        if let themeStr = UserDefaults.standard.string(forKey: "mbs_accentTheme"),
           let t = AccentTheme.allCases.first(where: { $0.rawValue == themeStr }) {
            self.accentTheme = t
        } else {
            self.accentTheme = .cyan
        }
        
        // CARD MODULE ORDER
        if let savedOrder = UserDefaults.standard.stringArray(forKey: "mbs_cardModuleOrder") {
            let mapped = savedOrder.compactMap { ModuleType(rawValue: $0) }
            var fullList = mapped
            for mod in ModuleType.defaultOrder {
                if !fullList.contains(mod) {
                    fullList.append(mod)
                }
            }
            self.cardModuleOrder = fullList
        } else {
            self.cardModuleOrder = ModuleType.defaultOrder
        }
        
        // NET
        self.netShowInMenuBar = UserDefaults.standard.object(forKey: "mbs_netShowInMenuBar") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_netShowInMenuBar")
        self.netShowInWindow = UserDefaults.standard.object(forKey: "mbs_netShowInWindow") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_netShowInWindow")
        self.netShowThroughput = UserDefaults.standard.object(forKey: "mbs_netShowThroughput") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_netShowThroughput")
        self.netShowModuleName = UserDefaults.standard.bool(forKey: "mbs_netShowModuleName")
        
        if let itStr = UserDefaults.standard.string(forKey: "mbs_netItemType"),
           let it = NetItemType.allCases.first(where: { $0.rawValue == itStr }) {
            self.netItemType = it
        } else {
            self.netItemType = .arrow
        }
        
        if let s = UserDefaults.standard.string(forKey: "mbs_netIndicatorStyle"),
           let style = NetIndicatorStyle.allCases.first(where: { $0.rawValue == s }) {
            self.netIndicatorStyle = style
        } else {
            self.netIndicatorStyle = .stack // 默认上下两行堆叠
        }
        
        if let taStr = UserDefaults.standard.string(forKey: "mbs_netTextAlign") {
            if let ta = NetTextAlign.allCases.first(where: { $0.rawValue == taStr }) {
                self.netTextAlign = ta
            } else if taStr.contains("中") || taStr == "center" {
                self.netTextAlign = .center
            } else if taStr.contains("左") || taStr == "left" {
                self.netTextAlign = .left
            } else {
                self.netTextAlign = .right
            }
        } else {
            self.netTextAlign = .right
        }
        
        if let cmStr = UserDefaults.standard.string(forKey: "mbs_netColorMode"),
           let cm = NetColorMode.allCases.first(where: { $0.rawValue == cmStr }) {
            self.netColorMode = cm
        } else {
            self.netColorMode = .colored
        }
        
        if let u = UserDefaults.standard.string(forKey: "mbs_netTrafficUnit"),
           let unit = NetTrafficUnit.allCases.first(where: { $0.rawValue == u }) {
            self.netTrafficUnit = unit
        } else {
            self.netTrafficUnit = .kbs // 默认 KB/s
        }
        
        self.netShowUnitSuffix = UserDefaults.standard.object(forKey: "mbs_netShowUnitSuffix") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_netShowUnitSuffix")
        self.netNotShowLowTraffic = UserDefaults.standard.object(forKey: "mbs_netNotShowLowTraffic") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_netNotShowLowTraffic")
        
        if let upStr = UserDefaults.standard.string(forKey: "mbs_netUploadColor"),
           let up = ColorOption.allCases.first(where: { $0.rawValue == upStr }) {
            self.netUploadColor = up
        } else {
            self.netUploadColor = .green
        }
        
        if let downStr = UserDefaults.standard.string(forKey: "mbs_netDownloadColor"),
           let down = ColorOption.allCases.first(where: { $0.rawValue == downStr }) {
            self.netDownloadColor = down
        } else {
            self.netDownloadColor = .cyan
        }
        
        if let tcmStr = UserDefaults.standard.string(forKey: "mbs_netTextColorMode"),
           let tcm = TextColorMode.allCases.first(where: { $0.rawValue == tcmStr }) {
            self.netTextColorMode = tcm
        } else {
            self.netTextColorMode = .monochrome // 默认为系统固定黑白
        }
        
        if let ctcStr = UserDefaults.standard.string(forKey: "mbs_netCustomTextColor"),
           let ctc = ColorOption.allCases.first(where: { $0.rawValue == ctcStr }) {
            self.netCustomTextColor = ctc
        } else {
            self.netCustomTextColor = .monochrome
        }
        
        // BATTERY
        self.batShowInMenuBar = UserDefaults.standard.object(forKey: "mbs_batShowInMenuBar") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_batShowInMenuBar")
        self.batShowInWindow = UserDefaults.standard.object(forKey: "mbs_batShowInWindow") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_batShowInWindow")
        self.batShowModuleName = UserDefaults.standard.bool(forKey: "mbs_batShowModuleName")
        self.batShowIcon = UserDefaults.standard.object(forKey: "mbs_batShowIcon") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_batShowIcon")
        
        if let bis = UserDefaults.standard.string(forKey: "mbs_batteryIconStyle") {
            if let style = BatteryIconStyle.allCases.first(where: { $0.rawValue == bis }) {
                self.batteryIconStyle = style
            } else if bis.contains("一体化") || bis.contains("内嵌") || bis == "embedded" {
                self.batteryIconStyle = .embedded
            } else if bis.contains("垂直") || bis == "vertical" {
                self.batteryIconStyle = .vertical
            } else if bis.contains("环形") || bis == "circleGauge" {
                self.batteryIconStyle = .circleGauge
            } else if bis.contains("分离") || bis == "regular" {
                self.batteryIconStyle = .regular
            } else {
                self.batteryIconStyle = .embedded
            }
        } else {
            self.batteryIconStyle = .embedded // 默认一体化胶囊内嵌
        }
        
        if let b = UserDefaults.standard.string(forKey: "mbs_batTextMode") {
            if let mode = BatTextMode.allCases.first(where: { $0.rawValue == b }) {
                self.batTextMode = mode
            } else if b.contains("健康") && b.contains("电量") {
                self.batTextMode = .percentageAndHealth
            } else if b.contains("健康") {
                self.batTextMode = .health
            } else if b.contains("循环") {
                self.batTextMode = .cycle
            } else if b.contains("时间") && b.contains("百分比") {
                self.batTextMode = .both
            } else if b.contains("时间") || b == "timeRemaining" {
                self.batTextMode = .timeRemaining
            } else if b.contains("不显示") || b == "none" {
                self.batTextMode = .none
            } else {
                self.batTextMode = .percentage
            }
        } else {
            self.batTextMode = .percentage
        }
        
        if let bcm = UserDefaults.standard.string(forKey: "mbs_batColorMode"),
           let cm = BatteryColorMode.allCases.first(where: { $0.rawValue == bcm }) {
            self.batColorMode = cm
        } else {
            self.batColorMode = .dynamic
        }
        
        if let bcc = UserDefaults.standard.string(forKey: "mbs_batCustomColor"),
           let cc = ColorOption.allCases.first(where: { $0.rawValue == bcc }) {
            self.batCustomColor = cc
        } else {
            self.batCustomColor = .green
        }
        
        // FANS
        self.fanShowInMenuBar = UserDefaults.standard.bool(forKey: "mbs_fanShowInMenuBar")
        self.fanShowInWindow = UserDefaults.standard.object(forKey: "mbs_fanShowInWindow") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_fanShowInWindow")
        self.fanShowIcon = UserDefaults.standard.object(forKey: "mbs_fanShowIcon") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_fanShowIcon")
        self.fanShowModuleName = UserDefaults.standard.bool(forKey: "mbs_fanShowModuleName")
        
        if let f = UserDefaults.standard.string(forKey: "mbs_fanTextMode") {
            if let mode = FanTextMode.allCases.first(where: { $0.rawValue == f }) {
                self.fanTextMode = mode
            } else if f.contains("百分比") || f.contains("%") || f == "percentage" {
                self.fanTextMode = .percentage
            } else if f.contains("不显示") || f == "none" {
                self.fanTextMode = .none
            } else {
                self.fanTextMode = .rpm
            }
        } else {
            self.fanTextMode = .rpm
        }
        
        if let ftaStr = UserDefaults.standard.string(forKey: "mbs_fanTextAlign") {
            if let fta = FanTextAlign.allCases.first(where: { $0.rawValue == ftaStr }) {
                self.fanTextAlign = fta
            } else if ftaStr.contains("中") || ftaStr == "center" {
                self.fanTextAlign = .center
            } else if ftaStr.contains("左") || ftaStr == "left" {
                self.fanTextAlign = .left
            } else {
                self.fanTextAlign = .right
            }
        } else {
            self.fanTextAlign = .right
        }
        
        if let ft = UserDefaults.standard.string(forKey: "mbs_fanTarget") {
            if let target = FanTargetSelect.allCases.first(where: { $0.rawValue == ft }) {
                self.fanTarget = target
            } else if ft.contains("堆叠") || ft.contains("Stack") || ft == "bothStack" {
                self.fanTarget = .bothStack
            } else if ft.contains("并列") || ft.contains("并") || ft == "bothSide" {
                self.fanTarget = .bothSide
            } else if ft.contains("最高") || ft.contains("highest") {
                self.fanTarget = .highest
            } else if ft.contains("左") || ft.contains("1") || ft == "fan1" {
                self.fanTarget = .fan1
            } else if ft.contains("右") || ft.contains("2") || ft == "fan2" {
                self.fanTarget = .fan2
            } else {
                self.fanTarget = .bothSide
            }
        } else {
            self.fanTarget = .bothSide
        }
        
        if let fc = UserDefaults.standard.string(forKey: "mbs_fanColor"),
           let fColor = ColorOption.allCases.first(where: { $0.rawValue == fc }) {
            self.fanColor = fColor
        } else {
            self.fanColor = .cyan
        }
        
        // 温度模块加载
        self.tempShowInMenuBar = UserDefaults.standard.object(forKey: "mbs_tempShowInMenuBar") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_tempShowInMenuBar")
        self.tempShowInWindow = UserDefaults.standard.object(forKey: "mbs_tempShowInWindow") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_tempShowInWindow")
        self.tempShowIcon = UserDefaults.standard.object(forKey: "mbs_tempShowIcon") == nil ? true : UserDefaults.standard.bool(forKey: "mbs_tempShowIcon")
        self.tempShowModuleName = UserDefaults.standard.bool(forKey: "mbs_tempShowModuleName")
        
        if let dmStr = UserDefaults.standard.string(forKey: "mbs_tempDisplayMode"),
           let dm = TempDisplayMode.allCases.first(where: { $0.rawValue == dmStr }) {
            self.tempDisplayMode = dm
        } else {
            self.tempDisplayMode = .valueWithUnit
        }
        if let ttStr = UserDefaults.standard.string(forKey: "mbs_tempTarget"),
           let tt = TemperatureTarget.allCases.first(where: { $0.rawValue == ttStr }) {
            self.tempTarget = tt
        } else {
            self.tempTarget = .cpu
        }
        if let tuStr = UserDefaults.standard.string(forKey: "mbs_tempUnit"),
           let tu = TemperatureUnit.allCases.first(where: { $0.rawValue == tuStr }) {
            self.tempUnit = tu
        } else {
            self.tempUnit = .celsius
        }
        if let taStr = UserDefaults.standard.string(forKey: "mbs_tempTextAlign"),
           let ta = TempTextAlign.allCases.first(where: { $0.rawValue == taStr }) {
            self.tempTextAlign = ta
        } else {
            self.tempTextAlign = .right
        }
        if let tcStr = UserDefaults.standard.string(forKey: "mbs_tempColor"),
           let tc = ColorOption.allCases.first(where: { $0.rawValue == tcStr }) {
            self.tempColor = tc
        } else {
            self.tempColor = .orange
        }
    }
    
    // MARK: - 卡片模块顺序调整 API
    public func moveCardModuleUp(_ module: ModuleType) {
        guard let idx = cardModuleOrder.firstIndex(of: module), idx > 0 else { return }
        cardModuleOrder.swapAt(idx, idx - 1)
    }
    
    public func moveCardModuleDown(_ module: ModuleType) {
        guard let idx = cardModuleOrder.firstIndex(of: module), idx < cardModuleOrder.count - 1 else { return }
        cardModuleOrder.swapAt(idx, idx + 1)
    }
    
    public func isCardModuleVisible(_ module: ModuleType) -> Bool {
        switch module {
        case .network: return netShowInWindow
        case .battery: return batShowInWindow
        case .fan: return fanShowInWindow
        case .temperature: return tempShowInWindow
        }
    }
    
    public func setCardModuleVisible(_ module: ModuleType, visible: Bool) {
        switch module {
        case .network: netShowInWindow = visible
        case .battery: batShowInWindow = visible
        case .fan: fanShowInWindow = visible
        case .temperature: tempShowInWindow = visible
        }
    }
    
    // MARK: - 注册 / 注销系统登录自启动 (基于 macOS 13+ SMAppService 现代化系统服务)
    public func updateLaunchAtLoginService() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("MenuBarPulse: SMAppService error: \(error.localizedDescription)")
            }
        }
    }
}
