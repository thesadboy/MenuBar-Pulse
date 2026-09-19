import SwiftUI
import UniformTypeIdentifiers

public struct PreferencesView: View {
    @ObservedObject var prefs = PreferencesState.shared
    @ObservedObject var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Tab 顶部导航栏 (纯中文，经典 macOS 工具栏风格)
            HStack(spacing: 12) {
                TabButton(title: "通用", icon: "gearshape.fill", index: 0, currentTab: $prefs.selectedTab)
                TabButton(title: "网络", icon: "network", index: 1, currentTab: $prefs.selectedTab)
                TabButton(title: "电池", icon: "battery.100.bolt", index: 2, currentTab: $prefs.selectedTab)
                TabButton(title: "风扇", icon: "fan.fill", index: 3, currentTab: $prefs.selectedTab)
                TabButton(title: "温度", icon: "thermometer.medium", index: 4, currentTab: $prefs.selectedTab)
                TabButton(title: "关于", icon: "info.circle.fill", index: 5, currentTab: $prefs.selectedTab)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
            
            // MARK: - Tab 内容页 (自适应高度，带滚动条，底部预留充分间距防止遮挡)
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    switch prefs.selectedTab {
                    case 0:
                        generalTab
                    case 1:
                        networkTab
                    case 2:
                        batteryTab
                    case 3:
                        fanTab
                    case 4:
                        temperatureTab
                    case 5:
                        aboutTab
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // MARK: - 底部状态栏 (固定在最底部)
            HStack {
                Text("所有设置即时保存并应用，菜单栏实时无缝重绘")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button("完成") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 600, idealWidth: 600, minHeight: 630, idealHeight: 630)
        .background(PrefVisualEffectBackground())
    }
    
    // MARK: - 1. 通用设置 (General)
    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingSection(title: "菜单栏布局模式") {
                HStack {
                    Text("展示形式：")
                        .font(.system(size: 12))
                    Spacer()
                    Picker("", selection: $prefs.moduleDisplayMode) {
                        ForEach(ModuleDisplayMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .frame(width: 280)
                }
                Text("• 合并模式：所有监控模块整合成单个紧凑菜单栏项。\n• 独立模式：各模块分离为独立菜单项，按住 ⌘ Command 键可任意拖拽重排位置。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            SettingSection(title: "模块显示与卡片排序设置") {
                VStack(spacing: 8) {
                    HStack {
                        Text("功能模块")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 140, alignment: .leading)
                        Spacer()
                        Text("顶部菜单栏")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 80, alignment: .center)
                        Text("卡片中显示")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 80, alignment: .center)
                        Text("卡片排序")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 70, alignment: .center)
                    }
                    .padding(.bottom, 2)
                    Divider()
                    
                    ForEach(Array(prefs.cardModuleOrder.enumerated()), id: \.element) { index, mod in
                        HStack {
                            // 拖拽手柄 + 模块图标与名称
                            HStack(spacing: 7) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .frame(width: 14)
                                    .help("按住拖拽以调整顺序")
                                
                                Image(systemName: mod.iconName)
                                    .foregroundColor(moduleColor(for: mod))
                                    .frame(width: 16)
                                Text(mod.displayName)
                                    .font(.system(size: 12))
                            }
                            .frame(width: 150, alignment: .leading)
                            
                            Spacer()
                            
                            // 顶部菜单栏开关
                            menuBarToggle(for: mod)
                                .frame(width: 80, alignment: .center)
                            
                            // 下拉卡片开关
                            cardToggle(for: mod)
                                .frame(width: 80, alignment: .center)
                            
                            // 上下步进排序按钮 (辅助无鼠标拖拽操作)
                            HStack(spacing: 6) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        prefs.moveCardModuleUp(mod)
                                    }
                                }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .buttonStyle(.borderless)
                                .disabled(index == 0)
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        prefs.moveCardModuleDown(mod)
                                    }
                                }) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .buttonStyle(.borderless)
                                .disabled(index == prefs.cardModuleOrder.count - 1)
                            }
                            .frame(width: 70, alignment: .center)
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(prefs.draggedCardModule == mod ? prefs.accentTheme.color.opacity(0.15) : Color.clear)
                        )
                        .onDrag {
                            prefs.draggedCardModule = mod
                            return NSItemProvider(object: mod.rawValue as NSString)
                        }
                        .onDrop(of: [UTType.plainText], delegate: CardModuleDropDelegate(
                            targetItem: mod,
                            prefs: prefs
                        ))
                    }
                }
                .padding(.vertical, 2)
                
                Text("提示：卡片模块顺序支持通过鼠标「按住拖拽 ≡」或点击「↑ / ↓」按钮自由调整；各模块在菜单栏与下拉卡片中的显示彼此独立。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            SettingSection(title: "系统选项") {
                Toggle("系统登录时自动启动 MenuBar Pulse", isOn: $prefs.launchAtLogin)
                    .font(.system(size: 12))
                
                Toggle("点击弹出的监控面板保持置顶 (固定不自动关闭)", isOn: $prefs.pinWindow)
                    .font(.system(size: 12))
            }
            
            SettingSection(title: "采样刷新与主题配色") {
                HStack {
                    Text("数据采样刷新频率：")
                        .font(.system(size: 12))
                    Spacer()
                    Picker("", selection: $prefs.refreshInterval) {
                        Text("0.5 秒 (高灵敏)").tag(0.5)
                        Text("1.0 秒 (推荐)").tag(1.0)
                        Text("2.0 秒 (均衡)").tag(2.0)
                        Text("3.0 秒 (省电)").tag(3.0)
                    }
                    .frame(width: 180)
                }
                
                HStack {
                    Text("面板强调高亮主题色：")
                        .font(.system(size: 12))
                    Spacer()
                    Picker("", selection: $prefs.accentTheme) {
                        ForEach(AccentTheme.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .frame(width: 180)
                }
            }
        }
    }
    
    private func moduleColor(for mod: ModuleType) -> Color {
        switch mod {
        case .network: return .blue
        case .battery: return .green
        case .fan: return .cyan
        case .temperature: return .orange
        }
    }
    
    @ViewBuilder
    private func menuBarToggle(for mod: ModuleType) -> some View {
        switch mod {
        case .network:
            Toggle("", isOn: $prefs.netShowInMenuBar).labelsHidden()
        case .battery:
            Toggle("", isOn: $prefs.batShowInMenuBar).labelsHidden()
        case .fan:
            Toggle("", isOn: $prefs.fanShowInMenuBar).labelsHidden()
        case .temperature:
            Toggle("", isOn: $prefs.tempShowInMenuBar).labelsHidden()
        }
    }
    
    @ViewBuilder
    private func cardToggle(for mod: ModuleType) -> some View {
        switch mod {
        case .network:
            Toggle("", isOn: $prefs.netShowInWindow).labelsHidden()
        case .battery:
            Toggle("", isOn: $prefs.batShowInWindow).labelsHidden()
        case .fan:
            Toggle("", isOn: $prefs.fanShowInWindow).labelsHidden()
        case .temperature:
            Toggle("", isOn: $prefs.tempShowInWindow).labelsHidden()
        }
    }
    
    // MARK: - 2. 网络模块设置 (Network)
    private var networkTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingSection(title: "模块显示与独立开关") {
                Toggle("在顶部菜单栏中显示网络模块", isOn: $prefs.netShowInMenuBar)
                    .font(.system(size: 12, weight: .semibold))
                
                Toggle("在点击下拉窗口中显示网络模块", isOn: $prefs.netShowInWindow)
                    .font(.system(size: 12, weight: .semibold))
                
                if prefs.netShowInMenuBar {
                    Toggle("在菜单栏显示 NET 标签文本", isOn: $prefs.netShowModuleName)
                        .font(.system(size: 12))
                        .padding(.leading, 16)
                }
            }
            
            if prefs.netShowInMenuBar {
                SettingSection(title: "菜单栏文字显示") {
                    Picker("", selection: $prefs.netShowThroughput) {
                        Text("显示网络速率实时数值").tag(true)
                        Text("仅显示指示图标，隐藏数值").tag(false)
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                }
                
                SettingSection(title: "流速排版样式") {
                    HStack {
                        Text("排版样式：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.netIndicatorStyle) {
                            ForEach(NetIndicatorStyle.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .frame(width: 250)
                    }
                }
                
                SettingSection(title: "文字对齐方式") {
                    Picker("", selection: $prefs.netTextAlign) {
                        ForEach(NetTextAlign.allCases) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                }
                
                SettingSection(title: "指示器色彩模式") {
                    Picker("", selection: $prefs.netColorMode) {
                        ForEach(NetColorMode.allCases) { cm in
                            Text(cm.rawValue).tag(cm)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                    
                    if prefs.netColorMode == .colored || prefs.netColorMode == .coloredDynamic {
                        Divider().padding(.vertical, 2)
                        
                        HStack {
                            Text("上传指示色：")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $prefs.netUploadColor) {
                                ForEach(ColorOption.allCases) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .frame(width: 160)
                        }
                        
                        HStack {
                            Text("下载指示色：")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $prefs.netDownloadColor) {
                                ForEach(ColorOption.allCases) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .frame(width: 160)
                        }
                    }
                }
                
                SettingSection(title: "文字色彩与防抖模式") {
                    Picker("", selection: $prefs.netTextColorMode) {
                        ForEach(TextColorMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                    
                    if prefs.netTextColorMode == .custom {
                        Divider().padding(.vertical, 2)
                        HStack {
                            Text("固定自定义文字颜色：")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $prefs.netCustomTextColor) {
                                ForEach(ColorOption.allCases) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .frame(width: 160)
                        }
                    }
                }
                
                SettingSection(title: "指示器图标形态") {
                    HStack {
                        Text("指示器形态：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.netItemType) {
                            ForEach(NetItemType.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .frame(width: 250)
                    }
                    
                    Toggle("低于 1 KB/s 视为静止 (显示为 0，防止微流量干扰)", isOn: $prefs.netNotShowLowTraffic)
                        .font(.system(size: 12))
                }
                
                SettingSection(title: "流速单位与换算") {
                    HStack {
                        Text("单位体系：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.netTrafficUnit) {
                            ForEach(NetTrafficUnit.allCases) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .frame(width: 250)
                    }
                    
                    Toggle("显示 \"/s\" 单位后缀 (如 KB/s、MB/s，取消勾选简写为 KB、MB)", isOn: $prefs.netShowUnitSuffix)
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
    }
    
    // MARK: - 3. 电池模块设置 (Battery)
    private var batteryTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingSection(title: "模块显示与独立开关") {
                Toggle("在顶部菜单栏中显示电池模块", isOn: $prefs.batShowInMenuBar)
                    .font(.system(size: 12, weight: .semibold))
                
                Toggle("在点击下拉窗口中显示电池模块", isOn: $prefs.batShowInWindow)
                    .font(.system(size: 12, weight: .semibold))
                
                if prefs.batShowInMenuBar {
                    Toggle("在菜单栏显示 BAT 标签文本", isOn: $prefs.batShowModuleName)
                        .font(.system(size: 12))
                        .padding(.leading, 16)
                }
            }
            
            if prefs.batShowInMenuBar {
                SettingSection(title: "电池图标形态与内嵌显示") {
                    HStack {
                        Text("图标展示样式：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.batteryIconStyle) {
                            ForEach(BatteryIconStyle.allCases) { b in
                                Text(b.rawValue).tag(b)
                            }
                        }
                        .frame(width: 280)
                    }
                    
                    if prefs.batteryIconStyle == .embedded {
                        Text("一体化内嵌模式：电量与电源接通⚡状态内嵌于电池胶囊内。若在下方选择附加文字，亦可在胶囊旁并列展示寿命或循环等详细信息。")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                    } else {
                        Toggle("在菜单栏显示电池图标", isOn: $prefs.batShowIcon)
                            .font(.system(size: 12))
                    }
                }
                
                SettingSection(title: "文字与健康寿命显示模式") {
                    Picker("", selection: $prefs.batTextMode) {
                        ForEach(BatTextMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                    
                    if !appState.battery.ageString.isEmpty {
                        let mfg = appState.battery.manufactureDateString.isEmpty ? "" : "（出厂日期：\(appState.battery.manufactureDateString)）"
                        Text("💡 本机电池出厂至今已使用约 \(appState.battery.ageString)\(mfg)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                SettingSection(title: "电池颜色配置") {
                    Picker("", selection: $prefs.batColorMode) {
                        ForEach(BatteryColorMode.allCases) { cm in
                            Text(cm.rawValue).tag(cm)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                    
                    if prefs.batColorMode == .custom {
                        Divider().padding(.vertical, 2)
                        HStack {
                            Text("自定义固定电池颜色：")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $prefs.batCustomColor) {
                                ForEach(ColorOption.allCases) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .frame(width: 160)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 4. 风扇模块设置 (Fans)
    private var fanTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingSection(title: "模块显示与独立开关") {
                Toggle("在顶部菜单栏中显示风扇模块", isOn: $prefs.fanShowInMenuBar)
                    .font(.system(size: 12, weight: .semibold))
                
                Toggle("在点击下拉窗口中显示风扇模块", isOn: $prefs.fanShowInWindow)
                    .font(.system(size: 12, weight: .semibold))
                
                if prefs.fanShowInMenuBar {
                    Toggle("在菜单栏显示 FAN 标签文本", isOn: $prefs.fanShowModuleName)
                        .font(.system(size: 12))
                        .padding(.leading, 16)
                }
            }
            
            if prefs.fanShowInMenuBar {
                SettingSection(title: "风扇图标") {
                    Toggle("在菜单栏显示风扇矢量图标", isOn: $prefs.fanShowIcon)
                        .font(.system(size: 12))
                }
                
                SettingSection(title: "风扇文字显示模式") {
                    Picker("", selection: $prefs.fanTextMode) {
                        ForEach(FanTextMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                }
                
                if prefs.fanTextMode != .none {
                    SettingSection(title: "文字对齐方式") {
                        Picker("", selection: $prefs.fanTextAlign) {
                            ForEach(FanTextAlign.allCases) { a in
                                Text(a.rawValue).tag(a)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .font(.system(size: 12))
                    }
                }
                
                SettingSection(title: "多风扇展示策略") {
                    if appState.fan.fans.count >= 2 {
                        HStack {
                            Text("双风扇排版：")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $prefs.fanTarget) {
                                ForEach(FanTargetSelect.allCases) { ft in
                                    Text(ft.rawValue).tag(ft)
                                }
                            }
                            .frame(width: 270)
                        }
                    } else if appState.fan.fans.count == 1 {
                        Text("当前硬件检测到 1 个物理风扇，已自动匹配单风扇标准呈现。")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("当前硬件为无风扇静音被动散热架构 (如 MacBook Air)。")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingSection(title: "风扇指示颜色") {
                    HStack {
                        Text("风扇图标颜色：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.fanColor) {
                            ForEach(ColorOption.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .frame(width: 160)
                    }
                }
            }
        }
    }
    
    // MARK: - 5. 温度设置 (Temperature)
    private var temperatureTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingSection(title: "模块启用与显示位置") {
                Toggle("在菜单栏显示温度模块", isOn: $prefs.tempShowInMenuBar)
                    .font(.system(size: 12, weight: .semibold))
                
                Toggle("在点击下拉窗口中显示温度模块", isOn: $prefs.tempShowInWindow)
                    .font(.system(size: 12, weight: .semibold))
                
                if prefs.tempShowInMenuBar {
                    Toggle("在菜单栏显示 TEMP 标签文本", isOn: $prefs.tempShowModuleName)
                        .font(.system(size: 12))
                        .padding(.leading, 16)
                }
            }
            
            if prefs.tempShowInMenuBar {
                SettingSection(title: "温度图标") {
                    Toggle("在菜单栏显示温度计矢量图标", isOn: $prefs.tempShowIcon)
                        .font(.system(size: 12))
                }
                
                SettingSection(title: "监控目标硬件") {
                    HStack {
                        Text("目标选择：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.tempTarget) {
                            ForEach(TemperatureTarget.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .frame(width: 250)
                    }
                }
                
                SettingSection(title: "温标单位") {
                    Picker("", selection: $prefs.tempUnit) {
                        ForEach(TemperatureUnit.allCases) { u in
                            Text(u.rawValue).tag(u)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                }
                
                SettingSection(title: "文字显示模式") {
                    Picker("", selection: $prefs.tempDisplayMode) {
                        ForEach(TempDisplayMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .font(.system(size: 12))
                }
                
                if prefs.tempDisplayMode != .none {
                    SettingSection(title: "文字对齐方式") {
                        Picker("", selection: $prefs.tempTextAlign) {
                            ForEach(TempTextAlign.allCases) { a in
                                Text(a.rawValue).tag(a)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .font(.system(size: 12))
                    }
                }
                
                SettingSection(title: "温度指示颜色") {
                    HStack {
                        Text("颜色主题：")
                            .font(.system(size: 12))
                        Spacer()
                        Picker("", selection: $prefs.tempColor) {
                            ForEach(ColorOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .frame(width: 160)
                    }
                }
            }
        }
    }
    
    // MARK: - 6. 关于 (About)
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 10)
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .foregroundColor(.accentColor)
            
            Text("MenuBar Pulse")
                .font(.system(size: 20, weight: .bold))
            
            Text("版本 1.0.0 (Build 20260918)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Divider().padding(.horizontal, 40)
            
            VStack(spacing: 6) {
                Text("专为 macOS 原生深度定制的高性能系统监控套件")
                    .font(.system(size: 12, weight: .medium))
                Text("遵循原生 macOS 规范与高性能极简架构")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                Text("专注于 网络流速、电池健康 与 芯片级风扇转速 监控")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            
            Divider().padding(.horizontal, 40)
            
            // MARK: 开发者信息
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text("开发者")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("NickZhang")
                        .font(.system(size: 12, weight: .medium))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text("源代码")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://github.com/thesadboy/MenuBar-Pulse")!)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                            Text("thesadboy/MenuBar-Pulse")
                                .font(.system(size: 11.5))
                                .underline()
                        }
                    }
                    .buttonStyle(.link)
                    .foregroundColor(.accentColor)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text("官方主页")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://thesadboy.github.io/MenuBar-Pulse/")!)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                            Text("thesadboy.github.io/MenuBar-Pulse")
                                .font(.system(size: 11.5))
                                .underline()
                        }
                    }
                    .buttonStyle(.link)
                    .foregroundColor(.accentColor)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 12))
                    Text("开源协议")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("MIT License")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.45))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            
            Text("© 2026 NickZhang · 以 MIT 协议开源发布")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 辅助组件
private struct TabButton: View {
    let title: String
    let icon: String
    let index: Int
    @Binding var currentTab: Int
    
    var isSelected: Bool { currentTab == index }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                currentTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: isSelected ? .medium : .regular))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            }
            .frame(width: 62, height: 48)
            .foregroundColor(isSelected ? .primary : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle(isSelected: isSelected))
    }
}

private struct TabButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.primary.opacity(0.12) : (configuration.isPressed ? Color.primary.opacity(0.08) : Color.clear))
            )
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

private struct SettingSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.45))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct CardModuleDropDelegate: DropDelegate {
    let targetItem: ModuleType
    let prefs: PreferencesState
    
    func dropEntered(info: DropInfo) {
        guard let dragged = prefs.draggedCardModule, dragged != targetItem else { return }
        guard let fromIndex = prefs.cardModuleOrder.firstIndex(of: dragged),
              let toIndex = prefs.cardModuleOrder.firstIndex(of: targetItem) else { return }
        if fromIndex != toIndex {
            withAnimation(.easeInOut(duration: 0.2)) {
                prefs.cardModuleOrder.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        prefs.draggedCardModule = nil
        return true
    }
}

private struct PrefVisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .windowBackground
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
