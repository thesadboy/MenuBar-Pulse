import SwiftUI

// MARK: - 原生系统级电池矢量轮廓 (1:1 像素级复刻 macOS 系统原生电池，一体化端子，零浮空感)
public struct SystemBatteryShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let totalW = rect.width
        let h = rect.height
        let termW: CGFloat = 2.0
        let w = totalW - termW
        let r: CGFloat = 3.0
        let termH: CGFloat = 4.0
        let termR: CGFloat = 1.0
        let termY = ((h - termH) / 2.0).rounded()
        let termBottomY = termY + termH
        
        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: w, y: termY))
        p.addLine(to: CGPoint(x: w + termW - termR, y: termY))
        p.addArc(center: CGPoint(x: w + termW - termR, y: termY + termR), radius: termR, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: w + termW, y: termBottomY - termR))
        p.addArc(center: CGPoint(x: w + termW - termR, y: termBottomY - termR), radius: termR, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: w, y: termBottomY))
        p.addLine(to: CGPoint(x: w, y: h - r))
        p.addArc(center: CGPoint(x: w - r, y: h - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r, y: h))
        p.addArc(center: CGPoint(x: r, y: h - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: 0, y: r))
        p.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - 电池模块独立视图 (BatteryItemView - 1:1 系统级原生质感)
public struct BatteryItemView: View {
    @ObservedObject var batState = AppState.shared.batState
    @ObservedObject var prefs = PreferencesState.shared
    
    private var battery: BatterySnapshot { batState.snapshot }
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 4) {
            if prefs.batShowModuleName {
                Text("BAT")
                    .font(.system(size: 8.5, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            if prefs.batteryIconStyle == .embedded {
                embeddedBatteryCapsule
                if prefs.batTextMode != .none {
                    Text(batteryTextString)
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundColor(.primary)
                        .frame(minWidth: batteryTextWidth, alignment: .trailing)
                }
            } else {
                if prefs.batShowIcon {
                    switch prefs.batteryIconStyle {
                    case .regular:
                        regularBatteryCapsule
                    case .vertical:
                        verticalBatteryCapsule
                    case .circleGauge:
                        circleBatteryGauge
                    case .embedded:
                        EmptyView()
                    }
                }
                
                if prefs.batTextMode != .none {
                    Text(batteryTextString)
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundColor(.primary)
                        .frame(minWidth: batteryTextWidth, alignment: .trailing)
                }
            }
        }
        .help(batteryTooltipString)
    }
    
    // 0. 一体化内嵌胶囊电池 (1:1 像素级复刻 macOS 系统原生电池，一体化端子，内嵌百分比与电源接通状态)
    private var embeddedBatteryCapsule: some View {
        let totalW: CGFloat = 24.0
        let h: CGFloat = 12.0
        let termW: CGFloat = 2.0
        let bodyW = totalW - termW // 22.0
        let fillRatio = CGFloat(max(0, min(100, battery.percentage))) / 100.0
        let fillWidth = max(2.0, ((bodyW - 2.0) * fillRatio).rounded())
        let onFillColor = isBatteryFillLight ? Color.black : Color.white
        
        return ZStack(alignment: .leading) {
            // 1. 系统级半透明底色 (一体化框体填充)
            SystemBatteryShape()
                .fill(Color.primary.opacity(0.08))
                .frame(width: totalW, height: h)
            
            // 2. 内部动态电量填充进度条 (贴合主体内圆角，高品质系统内嵌)
            RoundedRectangle(cornerRadius: 2.0)
                .fill(batteryColor)
                .frame(width: fillWidth, height: h - 2.0)
                .padding(.leading, 1.0)
            
            // 3. 原生系统级外轮廓描边 (含一体化正极端子，柔和透明度)
            SystemBatteryShape()
                .stroke(Color.primary.opacity(0.40), lineWidth: 1.0)
                .frame(width: totalW, height: h)
            
            // 4. 未填充区域文字 (纯白色，只在电量未铺满且文字跨越未填充区域时展现，绝不侵入填充区)
            if fillWidth < bodyW - 3.0 {
                batteryInnerContent
                    .foregroundColor(.white)
                    .frame(width: bodyW, height: h, alignment: .center)
                    .mask(
                        HStack(spacing: 0) {
                            Spacer()
                                .frame(width: fillWidth + 1.0)
                            Rectangle()
                                .frame(width: max(0, totalW - fillWidth - 1.0), height: h)
                        }
                        .frame(width: totalW, height: h)
                    )
            }
            
            // 5. 填充区域文字 (浅色填充呈现纯黑高对比度质感，无任何底层白色干扰)
            batteryInnerContent
                .foregroundColor(onFillColor)
                .frame(width: bodyW, height: h, alignment: .center)
                .mask(
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2.0)
                            .frame(width: fillWidth, height: h - 2.0)
                            .padding(.leading, 1.0)
                        Spacer(minLength: 0)
                    }
                    .frame(width: totalW, height: h)
                )
        }
        .frame(width: totalW, height: h)
    }
    
    private var batteryInnerContent: some View {
        HStack(spacing: 1.0) {
            if battery.isCharging || battery.isACConnected {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 7.0, weight: .medium))
            }
            Text("\(battery.percentage)")
                .font(.system(size: 8.0, weight: .medium).monospacedDigit())
        }
    }
    
    // 1. 常规横向胶囊电池 (1:1 原生系统电池造型，外部文字模式)
    private var regularBatteryCapsule: some View {
        let totalW: CGFloat = 21.0
        let h: CGFloat = 10.5
        let termW: CGFloat = 1.4
        let bodyW = totalW - termW // 19.6
        let fillRatio = CGFloat(max(0, min(100, battery.percentage))) / 100.0
        let fillWidth = max(1.5, (bodyW - 1.6) * fillRatio)
        let onFillColor = isBatteryFillLight ? Color.black : Color.white
        
        return ZStack(alignment: .leading) {
            // 背景底色
            SystemBatteryShape()
                .fill(Color.primary.opacity(0.08))
                .frame(width: totalW, height: h)
            
            // 内部电量填充
            RoundedRectangle(cornerRadius: 2.0)
                .fill(batteryColor)
                .frame(width: fillWidth, height: h - 1.6)
                .padding(.leading, 0.8)
            
            // 充电闪电 (未填充区域白色)
            if battery.isCharging || battery.isACConnected {
                if fillWidth < bodyW - 3.0 {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 6.0, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: bodyW, height: h, alignment: .center)
                        .mask(
                            HStack(spacing: 0) {
                                Spacer().frame(width: fillWidth + 0.8)
                                Rectangle().frame(width: max(0, totalW - fillWidth - 0.8), height: h)
                            }
                            .frame(width: totalW, height: h)
                        )
                }
                
                // 充电闪电 (填充浅色区域呈现纯黑高对比度质感)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 6.0, weight: .bold))
                    .foregroundColor(onFillColor)
                    .frame(width: bodyW, height: h, alignment: .center)
                    .mask(
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2.0)
                                .frame(width: fillWidth, height: h - 1.6)
                                .padding(.leading, 0.8)
                            Spacer(minLength: 0)
                        }
                        .frame(width: totalW, height: h)
                    )
            }
            
            // 外框
            SystemBatteryShape()
                .stroke(Color.primary.opacity(0.40), lineWidth: 1.0)
                .frame(width: totalW, height: h)
        }
        .frame(width: totalW, height: h)
    }
    
    // 2. 垂直立式电池 (系统级质感)
    private var verticalBatteryCapsule: some View {
        VStack(spacing: 0.6) {
            RoundedRectangle(cornerRadius: 0.6)
                .fill(Color.primary.opacity(0.40))
                .frame(width: 3.5, height: 1.0)
            ZStack(alignment: .bottom) {
                let fillRatio = CGFloat(max(0, min(100, battery.percentage))) / 100.0
                let fillHeight = max(1.5, 12.0 * fillRatio)
                
                RoundedRectangle(cornerRadius: 2.0)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 9.0, height: 13.5)
                
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(batteryColor)
                    .frame(width: 7.4, height: fillHeight)
                    .padding(.bottom, 0.8)
                
                RoundedRectangle(cornerRadius: 2.0)
                    .stroke(Color.primary.opacity(0.40), lineWidth: 1.0)
                    .frame(width: 9.0, height: 13.5)
            }
        }
    }
    
    // 3. 环形电量刻度 (Circle Gauge)
    private var circleBatteryGauge: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.2), lineWidth: 1.8)
                .frame(width: 12, height: 12)
            Circle()
                .trim(from: 0, to: CGFloat(battery.percentage) / 100.0)
                .stroke(batteryColor, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 12, height: 12)
                .rotationEffect(.degrees(-90))
        }
    }
    
    private var batteryColor: Color {
        switch prefs.batColorMode {
        case .dynamic:
            if battery.percentage <= 10 {
                return Color(red: 1.0, green: 0.27, blue: 0.23) // Apple System Red
            } else if battery.percentage <= 20 {
                return Color(red: 1.0, green: 0.62, blue: 0.04) // Apple System Orange
            } else {
                return Color(red: 0.20, green: 0.78, blue: 0.35) // Apple System Green
            }
        case .achromatic:
            return .primary.opacity(0.85)
        case .custom:
            return prefs.batCustomColor.color
        }
    }
    
    private var isBatteryFillLight: Bool {
        switch prefs.batColorMode {
        case .dynamic:
            // 绿色 (>20%) 与 橙黄 (11-20%) 属于浅色高亮色彩，镂空/黑色文字对比度最高；红色 (<=10%) 属于深色，白色文字清晰
            return battery.percentage > 10
        case .achromatic:
            return true
        case .custom:
            switch prefs.batCustomColor {
            case .green, .cyan, .orange, .yellow, .monochrome:
                return true
            case .blue, .purple, .pink:
                return false
            }
        }
    }
    
    private var batteryTextString: String {
        switch prefs.batTextMode {
        case .percentage:
            return "\(battery.percentage)%"
        case .health:
            return String(format: "%.0f%%", battery.healthPercentage)
        case .percentageAndHealth:
            return "\(battery.percentage)% | " + String(format: "%.0f%%", battery.healthPercentage)
        case .cycle:
            return "\(battery.cycleCount)次"
        case .timeRemaining:
            return formatTime(battery.timeRemainingMinutes, isAC: battery.isACConnected)
        case .both:
            let t = formatTime(battery.timeRemainingMinutes, isAC: battery.isACConnected)
            return "\(battery.percentage)% (\(t))"
        case .none:
            return ""
        }
    }
    
    private var batteryTextWidth: CGFloat {
        switch prefs.batTextMode {
        case .percentage, .health:
            return 34
        case .percentageAndHealth:
            return 74
        case .cycle:
            return 42
        case .timeRemaining:
            return 36
        case .both:
            return 78
        case .none:
            return 0
        }
    }
    
    private var batteryTooltipString: String {
        guard battery.hasBattery else {
            return "台式 Mac (外接电源)"
        }
        var lines: [String] = []
        lines.append("当前电量: \(battery.percentage)% (\(battery.statusDescription))")
        lines.append(String(format: "电池健康寿命: %.1f%% (%@)", battery.healthPercentage, battery.condition))
        if !battery.ageString.isEmpty {
            let mfgStr = battery.manufactureDateString.isEmpty ? "" : " (出厂日期: \(battery.manufactureDateString))"
            lines.append("已使用时长: \(battery.ageString)\(mfgStr)")
        }
        lines.append("电池循环计数: \(battery.cycleCount) 次")
        if battery.fullChargeCapacity > 0 && battery.designCapacity > 0 {
            lines.append("满充容量: \(battery.fullChargeCapacity) mAh / 设计容量: \(battery.designCapacity) mAh")
        }
        return lines.joined(separator: "\n")
    }
    
    private func formatTime(_ mins: Int, isAC: Bool) -> String {
        if mins <= 0 {
            return isAC ? "已充满" : "计算中"
        }
        let h = mins / 60
        let m = mins % 60
        return String(format: "%d:%02d", h, m)
    }
}
