import SwiftUI
import Combine

public enum DashboardFocusModule: String, Equatable {
    case all
    case network
    case battery
    case fan
    case temperature
}

public final class NetworkModuleState: ObservableObject {
    @Published public var snapshot = NetworkSnapshot()
}

public final class BatteryModuleState: ObservableObject {
    @Published public var snapshot = BatterySnapshot()
}

public final class FanModuleState: ObservableObject {
    @Published public var snapshot = FanSnapshot()
}

public final class TemperatureModuleState: ObservableObject {
    @Published public var snapshot = TemperatureSnapshot()
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // 独立模块状态：各自管理自身的发布通知，杜绝网络更新触发风扇/电池/温度/弹窗卡片的联动重绘
    public let netState = NetworkModuleState()
    public let batState = BatteryModuleState()
    public let fanState = FanModuleState()
    public let tempState = TemperatureModuleState()
    
    // 向后兼容访问器
    public var network: NetworkSnapshot {
        get { netState.snapshot }
        set { netState.snapshot = newValue }
    }
    public var battery: BatterySnapshot {
        get { batState.snapshot }
        set { batState.snapshot = newValue }
    }
    public var fan: FanSnapshot {
        get { fanState.snapshot }
        set { fanState.snapshot = newValue }
    }
    public var temperature: TemperatureSnapshot {
        get { tempState.snapshot }
        set { tempState.snapshot = newValue }
    }
    
    @Published public var dashboardFocusModule: DashboardFocusModule = .all
    @Published public var isDashboardVisible: Bool = false
    
    public let preferences = PreferencesState.shared
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        refreshData()
        restartTimer()
        
        // 监听偏好设置变更并即时生效
        preferences.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.restartTimer()
                    self?.refreshData()
                }
            }
            .store(in: &cancellables)
    }
    
    public func restartTimer() {
        timer?.invalidate()
        let interval = preferences.refreshInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshData()
            }
        }
    }
    
    /// 判断指定硬件模块当前是否需要进行数据采集（菜单栏展示 或 弹窗展开且该卡片可见）
    public func isModuleActive(_ module: ModuleType) -> Bool {
        // 1. 检查菜单栏是否正在展示该模块
        let inMenuBar: Bool
        switch module {
        case .network: inMenuBar = preferences.netShowInMenuBar
        case .battery: inMenuBar = preferences.batShowInMenuBar
        case .fan: inMenuBar = preferences.fanShowInMenuBar
        case .temperature: inMenuBar = preferences.tempShowInMenuBar
        }
        if inMenuBar { return true }
        
        // 2. 检查弹窗展开且当前窗口展示该模块
        if isDashboardVisible {
            switch dashboardFocusModule {
            case .all:
                return preferences.isCardModuleVisible(module)
            case .network:
                return module == .network
            case .battery:
                return module == .battery
            case .fan:
                return module == .fan
            case .temperature:
                return module == .temperature
            }
        }
        
        return false
    }
    
    public func refreshData() {
        let isDetailed = isDashboardVisible
        
        // 1. 网络：按需采集，仅在快照实质变更时触发独立 netState 广播
        if isModuleActive(.network) {
            let newNet = NetworkMonitor.shared.update(isDetailed: isDetailed)
            if newNet != netState.snapshot {
                netState.snapshot = newNet
            }
        }
        
        // 2. 电池：按需采集，仅在快照实质变更时触发独立 batState 广播
        if isModuleActive(.battery) {
            let newBat = BatteryMonitor.shared.update(force: isDetailed)
            if newBat != batState.snapshot {
                batState.snapshot = newBat
            }
        }
        
        // 3. 风扇：按需采集，仅在快照实质变更时触发独立 fanState 广播
        if isModuleActive(.fan) {
            let newFan = FanMonitor.shared.update()
            if newFan != fanState.snapshot {
                fanState.snapshot = newFan
            }
        }
        
        // 4. 温度：按需采集，仅在快照实质变更时触发独立 tempState 广播
        if isModuleActive(.temperature) {
            let newTemp = TemperatureMonitor.shared.update(isDetailed: isDetailed)
            if newTemp != tempState.snapshot {
                tempState.snapshot = newTemp
            }
        }
    }
}
