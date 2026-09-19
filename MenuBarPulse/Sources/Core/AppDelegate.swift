import Cocoa
import SwiftUI
import Combine

// 穿透鼠标点击事件，使点击直接触发 NSStatusBarButton 的动作
public class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?
    
    // 菜单栏状态项管理 (支持 Combined 模式与 Standalone 模式)
    private var combinedStatusItem: NSStatusItem?
    private var combinedHostingView: PassthroughHostingView<MenuBarItemView>?
    
    private var netStatusItem: NSStatusItem?
    private var netHostingView: PassthroughHostingView<NetworkItemView>?
    
    private var batStatusItem: NSStatusItem?
    private var batHostingView: PassthroughHostingView<BatteryItemView>?
    
    private var fanStatusItem: NSStatusItem?
    private var fanHostingView: PassthroughHostingView<FanItemView>?
    
    private var tempStatusItem: NSStatusItem?
    private var tempHostingView: PassthroughHostingView<TemperatureItemView>?
    
    private var popover: NSPopover!
    private var preferencesWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var cachedPopoverHeights: [DashboardFocusModule: CGFloat] = [:]
    
    public override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建浮动 Popover 监控面板 (265pt 紧凑视窗)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 265, height: 430)
        popover.animates = true
        popover.behavior = PreferencesState.shared.pinWindow ? .applicationDefined : .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: DashboardView())
        
        // 监听固定窗口 (Pin) 状态变更
        PreferencesState.shared.$pinWindow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPinned in
                self?.popover.behavior = isPinned ? .applicationDefined : .transient
            }
            .store(in: &cancellables)
            
        // 监听弹窗关闭事件，彻底停止后台详细计算
        NotificationCenter.default.addObserver(
            forName: NSPopover.didCloseNotification,
            object: popover,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                AppState.shared.isDashboardVisible = false
            }
        }
        
        // 重建与更新菜单栏
        rebuildStatusItems()
        
        // 监听布局模式变化
        PreferencesState.shared.$moduleDisplayMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildStatusItems()
            }
            .store(in: &cancellables)
            
        // 监听模块开关变化
        Publishers.Merge4(
            PreferencesState.shared.$netShowInMenuBar,
            PreferencesState.shared.$batShowInMenuBar,
            PreferencesState.shared.$fanShowInMenuBar,
            PreferencesState.shared.$tempShowInMenuBar
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.rebuildStatusItems()
        }
        .store(in: &cancellables)
        
        // 偏好设置发生变更时重新计算菜单栏项宽度（立即计算并在下一帧确认真实 fittingSize）
        PreferencesState.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateAllStatusItemWidths()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.updateAllStatusItemWidths()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.updateAllStatusItemWidths()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 构建/重建菜单栏项 (支持 Combined 与 Standalone)
    public func rebuildStatusItems() {
        tearDownStatusItems()
        let prefs = PreferencesState.shared
        
        if prefs.moduleDisplayMode == .combined {
            // MARK: Combined Mode (单个统一项)
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = item.button {
                button.title = ""
                button.target = self
                button.action = #selector(handleButtonClick(_:))
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                
                let host = PassthroughHostingView(rootView: MenuBarItemView())
                host.translatesAutoresizingMaskIntoConstraints = false
                button.addSubview(host)
                
                NSLayoutConstraint.activate([
                    host.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                    host.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                    host.topAnchor.constraint(equalTo: button.topAnchor),
                    host.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                ])
                self.combinedHostingView = host
            }
            self.combinedStatusItem = item
        } else {
            // MARK: Standalone Mode (各模块独立状态栏项)
            // 1. 网络
            if prefs.netShowInMenuBar {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = item.button {
                    button.title = ""
                    button.target = self
                    button.action = #selector(handleButtonClick(_:))
                    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                    
                    let host = PassthroughHostingView(rootView: NetworkItemView())
                    host.translatesAutoresizingMaskIntoConstraints = false
                    button.addSubview(host)
                    
                    NSLayoutConstraint.activate([
                        host.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
                        host.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
                        host.topAnchor.constraint(equalTo: button.topAnchor),
                        host.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                    ])
                    self.netHostingView = host
                }
                self.netStatusItem = item
            }
            
            // 2. 电池
            if prefs.batShowInMenuBar {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = item.button {
                    button.title = ""
                    button.target = self
                    button.action = #selector(handleButtonClick(_:))
                    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                    
                    let host = PassthroughHostingView(rootView: BatteryItemView())
                    host.translatesAutoresizingMaskIntoConstraints = false
                    button.addSubview(host)
                    
                    NSLayoutConstraint.activate([
                        host.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
                        host.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
                        host.topAnchor.constraint(equalTo: button.topAnchor),
                        host.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                    ])
                    self.batHostingView = host
                }
                self.batStatusItem = item
            }
            
            // 3. 风扇
            if prefs.fanShowInMenuBar {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = item.button {
                    button.title = ""
                    button.target = self
                    button.action = #selector(handleButtonClick(_:))
                    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                    
                    let host = PassthroughHostingView(rootView: FanItemView())
                    host.translatesAutoresizingMaskIntoConstraints = false
                    button.addSubview(host)
                    
                    NSLayoutConstraint.activate([
                        host.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
                        host.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
                        host.topAnchor.constraint(equalTo: button.topAnchor),
                        host.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                    ])
                    self.fanHostingView = host
                }
                self.fanStatusItem = item
            }
            
            // 4. 温度
            if prefs.tempShowInMenuBar {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = item.button {
                    button.title = ""
                    button.target = self
                    button.action = #selector(handleButtonClick(_:))
                    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                    
                    let host = PassthroughHostingView(rootView: TemperatureItemView())
                    host.translatesAutoresizingMaskIntoConstraints = false
                    button.addSubview(host)
                    
                    NSLayoutConstraint.activate([
                        host.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
                        host.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
                        host.topAnchor.constraint(equalTo: button.topAnchor),
                        host.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                    ])
                    self.tempHostingView = host
                }
                self.tempStatusItem = item
            }
            
            // 如果 Standalone 模式下用户关闭了全部菜单栏模块，保留备用项防止无法点击打开弹窗
            if !prefs.netShowInMenuBar && !prefs.batShowInMenuBar && !prefs.fanShowInMenuBar && !prefs.tempShowInMenuBar {
                let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = item.button {
                    button.title = ""
                    button.target = self
                    button.action = #selector(handleButtonClick(_:))
                    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
                    
                    let host = PassthroughHostingView(rootView: MenuBarItemView())
                    host.translatesAutoresizingMaskIntoConstraints = false
                    button.addSubview(host)
                    
                    NSLayoutConstraint.activate([
                        host.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                        host.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                        host.topAnchor.constraint(equalTo: button.topAnchor),
                        host.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                    ])
                    self.combinedHostingView = host
                }
                self.combinedStatusItem = item
            }
        }
        
        updateAllStatusItemWidths()
    }
    
    private func tearDownStatusItems() {
        if let it = combinedStatusItem {
            NSStatusBar.system.removeStatusItem(it)
            combinedStatusItem = nil
            combinedHostingView = nil
        }
        if let it = netStatusItem {
            NSStatusBar.system.removeStatusItem(it)
            netStatusItem = nil
            netHostingView = nil
        }
        if let it = batStatusItem {
            NSStatusBar.system.removeStatusItem(it)
            batStatusItem = nil
            batHostingView = nil
        }
        if let it = fanStatusItem {
            NSStatusBar.system.removeStatusItem(it)
            fanStatusItem = nil
            fanHostingView = nil
        }
        if let it = tempStatusItem {
            NSStatusBar.system.removeStatusItem(it)
            tempStatusItem = nil
            tempHostingView = nil
        }
    }
    
    // MARK: - 精确计算宽度 (无多余空白、无裁切)
    private func updateAllStatusItemWidths() {
        if let host = combinedHostingView, let item = combinedStatusItem {
            host.layoutSubtreeIfNeeded()
            let w = ceil(host.fittingSize.width)
            item.length = max(22.0, w + 4.0)
        }
        if let host = netHostingView, let item = netStatusItem {
            host.layoutSubtreeIfNeeded()
            let w = ceil(host.fittingSize.width)
            item.length = max(22.0, w + 4.0)
        }
        if let host = batHostingView, let item = batStatusItem {
            host.layoutSubtreeIfNeeded()
            let w = ceil(host.fittingSize.width)
            item.length = max(22.0, w + 4.0)
        }
        if let host = fanHostingView, let item = fanStatusItem {
            host.layoutSubtreeIfNeeded()
            let w = ceil(host.fittingSize.width)
            item.length = max(22.0, w + 4.0)
        }
        if let host = tempHostingView, let item = tempStatusItem {
            host.layoutSubtreeIfNeeded()
            let w = ceil(host.fittingSize.width)
            item.length = max(22.0, w + 4.0)
        }
    }
    
    @objc private func handleButtonClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) ?? false) {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }
    
    public func togglePopover(_ sender: NSStatusBarButton) {
        let prefs = PreferencesState.shared
        let targetModule: DashboardFocusModule = {
            if prefs.moduleDisplayMode == .combined {
                return .all
            }
            if sender == netStatusItem?.button {
                return .network
            } else if sender == batStatusItem?.button {
                return .battery
            } else if sender == fanStatusItem?.button {
                return .fan
            } else if sender == tempStatusItem?.button {
                return .temperature
            } else {
                return .all
            }
        }()
        
        let initialH = cachedPopoverHeights[targetModule] ?? 430.0
        let targetSize = NSSize(width: 265, height: initialH)
        popover.contentSize = targetSize
        popover.contentViewController?.preferredContentSize = targetSize
        
        if popover.isShown {
            if AppState.shared.dashboardFocusModule == targetModule {
                popover.performClose(sender)
                AppState.shared.isDashboardVisible = false
            } else {
                AppState.shared.dashboardFocusModule = targetModule
                AppState.shared.isDashboardVisible = true
                AppState.shared.refreshData()
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        } else {
            AppState.shared.dashboardFocusModule = targetModule
            AppState.shared.isDashboardVisible = true
            AppState.shared.refreshData()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    // MARK: - 动态贴合内容实际高度 (100% 由 SwiftUI 真实渲染内容驱动，零硬编码定高，系统级原生帧同步)
    public func updatePopoverHeight(to targetHeight: CGFloat, animated: Bool = true) {
        guard targetHeight > 50 else { return }
        let screenH = (popover.contentViewController?.view.window?.screen ?? NSScreen.main)?.visibleFrame.height ?? 900
        let maxAllowedH = screenH * (2.0 / 3.0)
        let finalH = ceil(min(targetHeight, maxAllowedH))
        let targetSize = NSSize(width: 265, height: finalH)
        
        cachedPopoverHeights[AppState.shared.dashboardFocusModule] = finalH
        
        guard popover.isShown, let win = popover.contentViewController?.view.window else {
            popover.contentSize = targetSize
            popover.contentViewController?.preferredContentSize = targetSize
            return
        }
        
        let oldFrame = win.frame
        let deltaH = finalH - popover.contentSize.height
        guard abs(deltaH) >= 1.0 else { return }
        
        // 顶部锚点绝对固定：新 y 坐标向下平移差值 deltaH (macOS 窗口原点在左下角)
        let newOriginY = oldFrame.maxY - (oldFrame.height + deltaH)
        let newFrame = NSRect(x: oldFrame.origin.x, y: newOriginY, width: oldFrame.width, height: oldFrame.height + deltaH)
        
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                ctx.allowsImplicitAnimation = true
                win.animator().setFrame(newFrame, display: true)
                popover.contentSize = targetSize
                popover.contentViewController?.preferredContentSize = targetSize
            }
        } else {
            win.setFrame(newFrame, display: true)
            popover.contentSize = targetSize
            popover.contentViewController?.preferredContentSize = targetSize
        }
    }
    
    public func openPreferencesWindow() {
        let winWidth: CGFloat = 580
        let winHeight: CGFloat = 630
        
        // 1. 获取用户当前鼠标/操作所在的显示器 (多屏幕支持)
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
            ?? NSApp.keyWindow?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
        
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: winWidth, height: winHeight),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MenuBar Pulse 偏好设置"
            window.contentViewController = NSHostingController(rootView: PreferencesView())
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 520, height: 500)
            preferencesWindow = window
        }
        
        // 2. 居中定位到当前点击所在的屏幕
        if let window = preferencesWindow, let screen = targetScreen {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.origin.x + (screenFrame.width - winWidth) / 2.0
            let y = screenFrame.origin.y + (screenFrame.height - winHeight) / 2.0
            window.setFrame(NSRect(x: x, y: y, width: winWidth, height: winHeight), display: true)
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "MenuBar Pulse 控制中心", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        let showPanel = NSMenuItem(title: "打开监控卡片面板", action: #selector(openPanelFromMenu(_:)), keyEquivalent: "o")
        showPanel.target = self
        showPanel.representedObject = sender
        menu.addItem(showPanel)
        
        let prefItem = NSMenuItem(title: "偏好设置...", action: #selector(openPrefsFromMenu), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(prefItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 快速模式切换
        let modeSubMenu = NSMenu()
        for mode in ModuleDisplayMode.allCases {
            let item = NSMenuItem(title: mode.rawValue, action: #selector(changeDisplayMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            item.state = (PreferencesState.shared.moduleDisplayMode == mode) ? .on : .off
            modeSubMenu.addItem(item)
        }
        let modeMenu = NSMenuItem(title: "菜单栏排版模式", action: nil, keyEquivalent: "")
        modeMenu.submenu = modeSubMenu
        menu.addItem(modeMenu)
        
        let refreshItem = NSMenuItem(title: "立即刷新数据", action: #selector(manualRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let quitItem = NSMenuItem(title: "退出 MenuBar Pulse", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // 弹出右键菜单
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }
    
    @objc private func openPanelFromMenu(_ sender: NSMenuItem) {
        if let btn = sender.representedObject as? NSStatusBarButton {
            togglePopover(btn)
        } else if let btn = combinedStatusItem?.button ?? netStatusItem?.button ?? batStatusItem?.button {
            togglePopover(btn)
        }
    }
    
    @objc private func openPrefsFromMenu() {
        openPreferencesWindow()
    }
    
    @objc private func changeDisplayMode(_ sender: NSMenuItem) {
        if let m = sender.representedObject as? ModuleDisplayMode {
            PreferencesState.shared.moduleDisplayMode = m
        }
    }
    
    @objc private func manualRefresh() {
        AppState.shared.refreshData()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSPopoverDelegate (精准控制 Popover 打开/关闭状态以停止后台 SwiftUI 无意义计算)
extension AppDelegate: NSPopoverDelegate {
    public func popoverWillShow(_ notification: Notification) {
        AppState.shared.isDashboardVisible = true
        AppState.shared.refreshData()
    }
    
    public func popoverDidClose(_ notification: Notification) {
        AppState.shared.isDashboardVisible = false
    }
}

