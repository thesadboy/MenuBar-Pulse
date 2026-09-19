<p align="center">
  <img src="MenuBarPulse/AppIcon.icns" width="128" height="128" alt="MenuBarPulse Icon" />
</p>

<h1 align="center">MenuBar Pulse</h1>

<p align="center">
  <strong>专为 macOS 打造的原生系统级极简、超低功耗菜单栏硬件监控与诊断中心</strong>
</p>

<p align="center">
  <a href="https://github.com/thesadboy/MenuBar-Pulse/releases"><img src="https://img.shields.io/github/v/release/thesadboy/MenuBar-Pulse?style=flat-square&color=34C759" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue?style=flat-square&logo=apple" alt="macOS 13.0+" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-orange?style=flat-square" alt="Universal" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-FA7343?style=flat-square&logo=swift" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/CPU%20Usage-%3C%200.8%25-brightgreen?style=flat-square" alt="Low CPU" />
  <img src="https://img.shields.io/badge/License-MIT-purple?style=flat-square" alt="MIT License" />
</p>

<p align="center">
  <a href="https://thesadboy.github.io/MenuBar-Pulse/">🌐 访问官方介绍主页</a> • 
  <a href="https://github.com/thesadboy/MenuBar-Pulse/releases">📦 下载最新 DMG</a> • 
  <a href="#-快速开始">🚀 快速开始</a> • 
  <a href="#-核心特性">✨ 核心特性</a>
</p>

---

## 📖 简介

**MenuBar Pulse** 是一款使用原生 Swift 与 SwiftUI 精心打磨的 macOS 状态栏监控工具。它旨在以**最小的系统开销（常驻 CPU 仅 ~0.0% - 0.7%，闲置唤醒仅 3 次/秒）**，在状态栏和精美浮动卡片中实时提供精确的网络上下行流速、电池健康寿命、散热风扇转速以及 10 大硬件温控探针数据。

彻底摒弃臃肿的第三方框架与高开销轮询，专为追求极致性能、原生质感与长续航的 Mac 用户设计。

---

## ✨ 核心特性

### 1. 🌐 实时网络上下行流速监控 (Network Pulse)
- **极速精确采集**：基于 macOS 内核 64 位 `sysctl (NET_RT_IFLIST2)` 路由接口读取硬件字节计数器，从根源规避 4GB 溢出截断；
- **多样化排版布局**：
  - **上下双行微型堆叠 (Stack)**：精巧紧凑，左右对称网格，内置定宽对齐防抖；
  - **左右并排排版 (Opposed)**：饱满易读，适合宽屏菜单栏；
- **微型矢量指示器**：
  - 1:1 数学对称 180° 旋转微矢量箭头；
  - 内置**视网膜冷暖色光渗补偿算法**（对冲蓝冷色收缩感）；
  - 支持固定系统黑白文字、跟随指示器色彩、自定义专属文字色彩；
  - 智能隐藏极低流速（可选）。

### 2. 🔋 原生内嵌胶囊电池与深度健康分析 (Battery Care)
- **系统级一体化内嵌胶囊**：1:1 像素复刻 macOS 原生电池框体与端子，电量填充与边框无缝贴合，内部嵌入百分比数字与 `⚡` 充电闪电；
- **硬件级生命周期监测**：
  - 电池真实健康百分比（与原厂出厂容量精确核算）；
  - 循环放电计数与健康状态（正常 / 建议维修）；
  - 出厂制造日期与已使用年龄推算；
  - 充电器实际协商功率（Wattage）与充满预计剩余时长。

### 3. 🌪️ 智能单双风扇独立监控 (Smart Fans)
- **硬件自适应识别**：单风扇机型（如 MacBook Pro 13" / Mac mini）与双风扇机型（MacBook Pro 14" / 16"）无缝兼容；
- **灵活多策略展示**：
  - 左右双风扇独立实时转速（并列 `1850 / 1900 rpm` 或双行 `L / R` 堆叠）；
  - 最高转速追踪或单一风扇指定；
  - 无风扇静音机型（如 MacBook Air）自动识别并呈现静音状态。

### 4. 🌡️ 10 大硬件分类温度透视 (Thermal Telemetry)
- **多维度传感器支持**：整合 Apple Silicon SMC 与 IOHID 内核事件，细分为 **10 大硬件类别**：
  `中央处理器`、`图形处理器`、`SoC 芯片`、`统一内存`、`固态硬盘`、`电池电芯`、`散热风道`、`供电模块`、`机身掌托`、`无线网络`；
- **交互式展开折叠**：卡片支持单个硬件组点击平滑展开明细探针，并支持「一键展开全部 / 收起全部」。

### 5. 🎛️ 纯动态自适应浮动面板 (Dynamic Dashboard)
- **100% 真实内容驱动高度**：无任何硬编码定高，通过 SwiftUI PreferenceKey 单向回传排版真实高度，窗口以 0.25s 丝滑原生曲线平滑缩放，**彻底杜绝视窗抖动与死循环**；
- **多屏幕智能感知**：支持多外接显示器识别，设置面板自动跟随鼠标居中呈现在活动屏幕上；
- **窗口固定置顶**：提供一键 Pin 按钮，支持保持监控面板悬浮常驻。

---

## ⚡ 极致能效架构设计

MenuBar Pulse 采用了系统级降载与惰性响应架构，在活动监视器中表现极为惊艳：

```
进程名称: MenuBar Pulse   % CPU: 0.7%   线程: 5   闲置唤醒: 3 次/秒   % GPU: 0.0%
```

- **按需惰性采集（Demand-Driven Polling）**：
  若菜单栏仅开启网络模块且弹窗关闭，风扇、电池、温度等底层查询**完全静默挂起**，0 IOKit/SMC 调用。
- **响应式状态细粒度解耦（Reactive Decoupling）**：
  `netState`、`batState`、`fanState`、`tempState` 彻底独立，每秒网速变动仅刷新状态栏网速文字，绝不引发任何弹窗后台卡片的连锁重绘。
- **内核查询零内存堆分配（Zero-Allocation sysctl）**：
  `NetworkMonitor` 采用复用缓冲区与寄存器级字节匹配，消除每秒产生临时数组与字符串垃圾回收的开销。

---

## 🚀 快速开始

### 方式一：下载 DMG 安装包（推荐）

1. 前往 [Releases](https://github.com/thesadboy/MenuBar-Pulse/releases) 页面；
2. 下载最新版 `MenuBarPulse.dmg`；
3. 打开 DMG 镜像，将 `MenuBarPulse.app` 拖入 `Applications` 文件夹即可使用。

### 方式二：源码本地编译与打包

本项目采用原生 macOS 命令行工具链，无需安装任何第三方外部包管理器：

```bash
# 1. 克隆代码仓库
git clone https://github.com/thesadboy/MenuBar-Pulse.git
cd MenuBar-Pulse/MenuBarPulse

# 2. 编译并直接运行安装
bash build.sh

# 3. 或者一键构建生成分发 DMG
bash package_dmg.sh
```

---

## 🛠️ 系统要求与兼容性

- **系统要求**：macOS 13.0 (Ventura) 或更高版本（兼容 macOS 14 Sonoma 及 macOS 15 Sequoia）
- **架构支持**：
  - Apple Silicon（M1 / M2 / M3 / M4 全系列芯片，原生加速）
  - Intel 处理器机型

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 协议开源，欢迎自由使用、学习与二次开发。
