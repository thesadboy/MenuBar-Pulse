import SwiftUI

// MARK: - 经典微型箭头矢量 Path (1:1 原版微矢量，严格 180° 中心对称旋转)
public struct StemArrowShape: Shape {
    public let isUp: Bool
    
    public init(isUp: Bool) {
        self.isUp = isUp
    }
    
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let midX = (w / 2.0).rounded()
        let midY = (h / 2.0).rounded()
        
        let stemHalfWidth: CGFloat = 1.0
        let stemLeft = midX - stemHalfWidth
        let stemRight = midX + stemHalfWidth
        let headBaseY: CGFloat = (h * 0.45).rounded()
        
        p.move(to: CGPoint(x: stemLeft, y: h))
        p.addLine(to: CGPoint(x: stemRight, y: h))
        p.addLine(to: CGPoint(x: stemRight, y: headBaseY))
        p.addLine(to: CGPoint(x: w, y: headBaseY))
        p.addLine(to: CGPoint(x: midX, y: 0.0))
        p.addLine(to: CGPoint(x: 0.0, y: headBaseY))
        p.addLine(to: CGPoint(x: stemLeft, y: headBaseY))
        p.closeSubpath()
        
        if !isUp {
            let transform = CGAffineTransform(translationX: midX, y: midY)
                .rotated(by: .pi)
                .translatedBy(x: -midX, y: -midY)
            return p.applying(transform)
        }
        
        return p
    }
}

// MARK: - 网络模块独立视图 (NetworkItemView)
public struct NetworkItemView: View {
    @ObservedObject var netState = AppState.shared.netState
    @ObservedObject var prefs = PreferencesState.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 3) {
            if prefs.netShowModuleName {
                Text("NET")
                    .font(.system(size: 8.5, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            let upBytes = (prefs.netNotShowLowTraffic && netState.snapshot.uploadBytesPerSec < 1024) ? 0.0 : netState.snapshot.uploadBytesPerSec
            let downBytes = (prefs.netNotShowLowTraffic && netState.snapshot.downloadBytesPerSec < 1024) ? 0.0 : netState.snapshot.downloadBytesPerSec
            let upStr = formatSpeed(upBytes)
            let downStr = formatSpeed(downBytes)
            
            let upColor = getArrowColor(isUp: true)
            let downColor = getArrowColor(isUp: false)
            let upAlpha = getArrowAlpha(bytes: netState.snapshot.uploadBytesPerSec)
            let downAlpha = getArrowAlpha(bytes: netState.snapshot.downloadBytesPerSec)
            
            let upTextColor: Color = {
                switch prefs.netTextColorMode {
                case .monochrome:
                    return .primary
                case .custom:
                    return prefs.netCustomTextColor.color
                case .matchIndicator:
                    return (prefs.netColorMode == .achromatic || prefs.netColorMode == .achromaticDynamic) ? .primary : prefs.netUploadColor.color
                }
            }()
            
            let downTextColor: Color = {
                switch prefs.netTextColorMode {
                case .monochrome:
                    return .primary
                case .custom:
                    return prefs.netCustomTextColor.color
                case .matchIndicator:
                    return (prefs.netColorMode == .achromatic || prefs.netColorMode == .achromaticDynamic) ? .primary : prefs.netDownloadColor.color
                }
            }()
            
            if prefs.netShowThroughput {
                if prefs.netIndicatorStyle == .stack {
                    // 上下微型双行堆叠（紧凑贴合，缩小行间距，预留 52pt 彻底避免 ... 省略号）
                    VStack(alignment: .leading, spacing: 0.0) {
                        HStack(spacing: 3.0) {
                            if prefs.netItemType != .none {
                                indicatorShapeView(type: prefs.netItemType, isUp: true, color: upColor, alpha: upAlpha)
                                    .frame(width: 7.0, height: 7.0)
                            }
                            Text(upStr)
                                .font(.system(size: 9.0, weight: .light).monospacedDigit())
                                .lineLimit(1)
                                .foregroundColor(upTextColor)
                                .frame(width: 52.0, height: 9.0, alignment: prefs.netTextAlign.alignment)
                        }
                        HStack(spacing: 3.0) {
                            if prefs.netItemType != .none {
                                indicatorShapeView(type: prefs.netItemType, isUp: false, color: downColor, alpha: downAlpha)
                                    .frame(width: 7.0, height: 7.0)
                            }
                            Text(downStr)
                                .font(.system(size: 9.0, weight: .light).monospacedDigit())
                                .lineLimit(1)
                                .foregroundColor(downTextColor)
                                .frame(width: 52.0, height: 9.0, alignment: prefs.netTextAlign.alignment)
                        }
                    }
                } else {
                    // 左右并排排版 (Opposed，预留 56pt 彻底避免 ... 省略号)
                    HStack(spacing: 6.0) {
                        HStack(spacing: 3.0) {
                            if prefs.netItemType != .none {
                                indicatorShapeView(type: prefs.netItemType, isUp: true, color: upColor, alpha: upAlpha)
                                    .frame(width: 7.0, height: 7.0)
                            }
                            Text(upStr)
                                .font(.system(size: 10.0, weight: .light).monospacedDigit())
                                .lineLimit(1)
                                .foregroundColor(upTextColor)
                                .frame(width: 56.0, alignment: prefs.netTextAlign.alignment)
                        }
                        
                        HStack(spacing: 3.0) {
                            if prefs.netItemType != .none {
                                indicatorShapeView(type: prefs.netItemType, isUp: false, color: downColor, alpha: downAlpha)
                                    .frame(width: 7.0, height: 7.0)
                            }
                            Text(downStr)
                                .font(.system(size: 10.0, weight: .light).monospacedDigit())
                                .lineLimit(1)
                                .foregroundColor(downTextColor)
                                .frame(width: 56.0, alignment: prefs.netTextAlign.alignment)
                        }
                    }
                }
            } else {
                // 仅图标模式
                HStack(spacing: 3.0) {
                    indicatorShapeView(type: prefs.netItemType == .none ? .arrow : prefs.netItemType, isUp: true, color: upColor, alpha: upAlpha)
                        .frame(width: 7.0, height: 7.0)
                    indicatorShapeView(type: prefs.netItemType == .none ? .arrow : prefs.netItemType, isUp: false, color: downColor, alpha: downAlpha)
                        .frame(width: 7.0, height: 7.0)
                }
            }
        }
    }
    
    @ViewBuilder
    private func indicatorShapeView(type: NetItemType, isUp: Bool, color: Color, alpha: Double) -> some View {
        switch type {
        case .arrow:
            StemArrowShape(isUp: isUp)
                .fill(color.opacity(alpha))
                .frame(width: 7.0, height: 7.0)
        case .dot:
            Circle()
                .fill(color.opacity(alpha))
                .frame(width: 5.0, height: 5.0)
        case .square:
            RoundedRectangle(cornerRadius: 1.0)
                .fill(color.opacity(alpha))
                .frame(width: 5.0, height: 5.0)
        case .none:
            EmptyView()
        }
    }
    
    private func getArrowColor(isUp: Bool) -> Color {
        switch prefs.netColorMode {
        case .achromatic, .achromaticDynamic:
            return .primary
        case .colored, .coloredDynamic:
            return isUp ? prefs.netUploadColor.color : prefs.netDownloadColor.color
        }
    }
    
    private func getArrowAlpha(bytes: Double) -> Double {
        switch prefs.netColorMode {
        case .achromatic, .colored:
            return 1.0
        case .achromaticDynamic, .coloredDynamic:
            if bytes < 1024 {
                return 0.55
            } else if bytes < 100 * 1024 {
                return 0.80
            } else {
                return 1.0
            }
        }
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        let suffix = prefs.netShowUnitSuffix ? "/s" : ""
        switch prefs.netTrafficUnit {
        case .kbs, .auto:
            if bytes < 1024 {
                return String(format: "0 B%@", suffix)
            } else if bytes < 1024 * 1024 {
                let kb = bytes / 1024.0
                if kb < 10 {
                    return String(format: "%.1f KB%@", kb, suffix)
                } else {
                    return String(format: "%.0f KB%@", kb, suffix)
                }
            } else if bytes < 1024 * 1024 * 1024 {
                return String(format: "%.1f MB%@", bytes / (1024.0 * 1024.0), suffix)
            } else {
                return String(format: "%.1f GB%@", bytes / (1024.0 * 1024.0 * 1024.0), suffix)
            }
        case .bits:
            let bits = bytes * 8.0
            if bits < 1000 {
                return String(format: "0 b%@", suffix)
            } else if bits < 1000 * 1000 {
                return String(format: "%.0f Kb%@", bits / 1000.0, suffix)
            } else {
                return String(format: "%.1f Mb%@", bits / 1000000.0, suffix)
            }
        }
    }
}
