# MenuBarPulse 开发上下文与全局规则 (AGENTS.md)

本项目为 macOS 菜单栏综合硬件与网络监控工具 **MenuBarPulse**（原生 Swift + SwiftUI + AppKit + IOKit + ServiceManagement 构建）。

---

## 1. 核心架构与技术规范

1. **编译环境与构建命令**：
   - 采用原生 `swiftc` 命令行编译，不依赖完整 Xcode 项目文件。
   - **快速编译构建并部署**：执行 `bash build.sh`，会自动编译、签名并同步安装至 `/Applications/MenuBarPulse.app`，自动平滑重启应用，并自动清理工作区内的临时 `.app`。
   - **打包发布镜像**：执行 `./package_dmg.sh`，生成交付安装镜像 `MenuBarPulse.dmg`，并自动调用 `clean.sh --all` 保持工作区 100% 纯净。
   - **一键清理**：执行 `./clean.sh` 或 `./clean.sh --all` 快速清理隐藏元数据与冗余副本。
   - 避免使用 Swift 5.9+ 的 `@State` 属性包装器或宏（如 `@Observable`），因为 CommandLineTools 缺失宏插件会导致编译报错；视图状态管理统一使用 `ObservableObject`、`@ObservedObject` 或单例响应类（如 `AppState`、`PreferencesState`、`DashboardLayoutState`）。

2. **UI 渲染与物理像素规则**：
   - **字体字重规范**：菜单栏状态栏所有文字统一使用 `.light` 细体字重（对标原生系统与 Stats，消除在副屏或非视网膜屏幕上的灰度字体膨胀问题）。
   - **绝对整数坐标**：所有几何尺寸、行高、间距、圆角必须为**绝对整数（Integer Points）**，严禁使用 `.5` 等小数半像素，防止 1x 屏幕（如 DELL 外接屏）产生亚像素抗锯齿色晕。
   - **禁止人工外置阴影**：严禁在菜单栏文字上添加 `.shadow`，防止非活动副屏透出灰色光晕。

3. **弹窗（Dashboard Popover）机制**：
   - 尺寸自适应贴合：Popup 高度由实际内容渲染高度驱动，紧密贴合内容底部（6pt 呼吸边距）。
   - 最高封顶：最高上限为当前屏幕有效高度的 2/3 (`screenH * 2/3`)。
   - **防滚动机制**：当内容未达到 2/3 屏高时，使用 `.scrollDisabled(!isScrollable)` 彻底锁死滚动并消除滚动条；仅当超高时才开放平滑滚动。

4. **工程目录与模块化规范**：
   - `Sources/Core/`：应用程序入口、主生命周期（`AppDelegate`）、全局数据状态（`AppState`）、SMC 底层交互（`SMCReader`）。
   - `Sources/Modules/`：各功能领域独立模块（`Network`、`Battery`、`Fan`、`Temperature`），每个模块内独立封装其监控引擎（`*Monitor`）、弹窗卡片（`*CardView`）与菜单栏视图（`*MenuBarView`）。
   - `Sources/UI/`：通用组件（`Common`）、弹窗装配（`Dashboard`）、状态栏装配（`MenuBar`）、偏好设置（`Preferences`）。
   - 动态编译：`build.sh` 自动递归检索 Swift 源文件，并将 `Sources/Core/main.swift` 放置在最后，保持库级入口顶级语法严格兼容。

5. **历史演进参考**：
   - 详细的历史 45 次优化记录请查阅同目录下的 [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md)。
