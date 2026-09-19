import SwiftUI
import AppKit

// MARK: - 动态内容高度测量 PreferenceKey
struct DashboardContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let n = nextValue()
        if n > 0 { value = n }
    }
}

// MARK: - 原生紧凑监控面板视窗 (Dashboard View - 模块化装配与动态排序)
public struct DashboardView: View {
    @ObservedObject var appState: AppState = AppState.shared
    @ObservedObject var prefs: PreferencesState = PreferencesState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - 原版 FLEWindowTitleBar (标题栏)
            VStack(spacing: 0) {
                windowTitleBar
                Divider()
            }
            
            // MARK: - 紧凑模块流 (根据 prefs.cardModuleOrder 动态排序与展示)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 1) {
                    let modules = displayedModules
                    if !modules.isEmpty {
                        ForEach(modules, id: \.self) { mod in
                            if mod != modules.first {
                                Divider().padding(.vertical, 2)
                            }
                            cardView(for: mod)
                        }
                    } else {
                        emptyPlaceholderView
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: DashboardContentHeightKey.self, value: geo.size.height)
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 265, alignment: .top)
        .background(VisualEffectBackground().ignoresSafeArea())
        .onPreferenceChange(DashboardContentHeightKey.self) { contentHeight in
            guard appState.isDashboardVisible else { return }
            guard contentHeight > 10 else { return }
            let total = 28.0 + contentHeight // 28pt 为标题栏及分割线固定高度
            AppDelegate.shared?.updatePopoverHeight(to: total, animated: true)
        }
    }
    
    private var displayedModules: [ModuleType] {
        switch appState.dashboardFocusModule {
        case .all:
            return prefs.cardModuleOrder.filter { prefs.isCardModuleVisible($0) }
        case .network:
            return [.network]
        case .battery:
            return [.battery]
        case .fan:
            return [.fan]
        case .temperature:
            return [.temperature]
        }
    }
    
    @ViewBuilder
    private func cardView(for mod: ModuleType) -> some View {
        switch mod {
        case .network:
            NetworkCardView()
        case .battery:
            BatteryCardView()
        case .fan:
            FanCardView()
        case .temperature:
            TemperatureCardView()
        }
    }
    
    private var emptyPlaceholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text("未在窗口中启用任何模块")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text("请在右上角设置中开启模块窗口显示")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 标题栏
    private var windowTitleBar: some View {
        HStack(spacing: 6) {
            switch appState.dashboardFocusModule {
            case .network:
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text("网络监控")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            case .battery:
                Image(systemName: "battery.100.bolt")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text("电池监控")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            case .fan:
                Image(systemName: "fan.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text("散热风扇")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            case .temperature:
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text("硬件温度")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            case .all:
                Image(systemName: "gauge.with.needle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text("综合监控面板")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Anchor 按钮 (固定窗口置顶)
            Button(action: {
                prefs.pinWindow.toggle()
            }) {
                Image(systemName: prefs.pinWindow ? "pin.fill" : "pin")
                    .font(.system(size: 10))
                    .foregroundColor(prefs.pinWindow ? prefs.accentTheme.color : .secondary)
                    .padding(3)
            }
            .buttonStyle(.plain)
            .help(prefs.pinWindow ? "已固定置顶" : "固定置顶")
            
            // Prefs 齿轮按钮
            Button(action: {
                AppDelegate.shared?.openPreferencesWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(3)
            }
            .buttonStyle(.plain)
            .help("偏好设置...")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}

// MARK: - 原生玻璃特效背景
public struct VisualEffectBackground: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
