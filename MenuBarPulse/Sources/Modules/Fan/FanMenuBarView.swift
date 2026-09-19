import SwiftUI

public struct FanItemView: View {
    @ObservedObject var fanState = AppState.shared.fanState
    @ObservedObject var prefs = PreferencesState.shared
    
    private var fan: FanSnapshot { fanState.snapshot }
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 3.5) {
            if prefs.fanShowModuleName {
                Text("FAN")
                    .font(.system(size: 8.5, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            if prefs.fanShowIcon {
                Image(systemName: "fan.fill")
                    .font(.system(size: 11.5))
                    .foregroundColor(prefs.fanColor.color)
            }
            
            if !fan.isFanless && !fan.fans.isEmpty {
                fanContentView
            } else {
                if prefs.fanTextMode != .none {
                    Text("静音")
                        .font(.system(size: 10.5, weight: .light))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(width: 26, alignment: prefs.fanTextAlign.alignment)
                }
            }
        }
        .padding(.horizontal, 2)
    }
    
    @ViewBuilder
    private var fanContentView: some View {
        let count = fan.fans.count
        if count == 1 {
            // MARK: 1. 单风扇硬件设备模式 (例如 MacBook Pro 13" / Mac mini)
            let f = fan.fans[0]
            if prefs.fanTextMode == .rpm {
                Text(String(format: "%.0f rpm", f.currentRPM))
                    .font(.system(size: 10.5, weight: .light).monospacedDigit())
                    .foregroundColor(.primary)
                    .frame(width: 52, alignment: prefs.fanTextAlign.alignment)
            } else if prefs.fanTextMode == .percentage {
                Text("\(Int(f.percentage))%")
                    .font(.system(size: 10.5, weight: .light).monospacedDigit())
                    .foregroundColor(.primary)
                    .frame(width: 34, alignment: prefs.fanTextAlign.alignment)
            }
        } else if count >= 2 {
            // MARK: 2. 左右双风扇硬件设备模式 (例如 MacBook Pro 14" / 16")
            let f1 = fan.fans[0]
            let f2 = fan.fans[1]
            
            switch prefs.fanTarget {
            case .bothSide:
                // 左右并列：例如 1850 / 1900 rpm
                if prefs.fanTextMode == .rpm {
                    Text(String(format: "%.0f / %.0f rpm", f1.currentRPM, f2.currentRPM))
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(minWidth: 84, alignment: prefs.fanTextAlign.alignment)
                } else if prefs.fanTextMode == .percentage {
                    Text("\(Int(f1.percentage))% / \(Int(f2.percentage))%")
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(minWidth: 64, alignment: prefs.fanTextAlign.alignment)
                }
                
            case .bothStack:
                // 上下双行堆叠：L 上，R 下 (与网络双行堆叠高度及字号完全对齐，紧凑行距)
                VStack(alignment: .leading, spacing: 0.0) {
                    HStack(spacing: 2.0) {
                        Text("L")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 7.0, alignment: .center)
                        if prefs.fanTextMode == .rpm {
                            Text(String(format: "%.0f rpm", f1.currentRPM))
                                .font(.system(size: 8.5, weight: .light).monospacedDigit())
                                .foregroundColor(.primary)
                                .frame(width: 48.0, height: 9.0, alignment: prefs.fanTextAlign.alignment)
                        } else if prefs.fanTextMode == .percentage {
                            Text("\(Int(f1.percentage))%")
                                .font(.system(size: 8.5, weight: .light).monospacedDigit())
                                .foregroundColor(.primary)
                                .frame(width: 30.0, height: 9.0, alignment: prefs.fanTextAlign.alignment)
                        }
                    }
                    HStack(spacing: 2.0) {
                        Text("R")
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 7.0, alignment: .center)
                        if prefs.fanTextMode == .rpm {
                            Text(String(format: "%.0f rpm", f2.currentRPM))
                                .font(.system(size: 8.5, weight: .light).monospacedDigit())
                                .foregroundColor(.primary)
                                .frame(width: 48.0, height: 9.0, alignment: prefs.fanTextAlign.alignment)
                        } else if prefs.fanTextMode == .percentage {
                            Text("\(Int(f2.percentage))%")
                                .font(.system(size: 8.5, weight: .light).monospacedDigit())
                                .foregroundColor(.primary)
                                .frame(width: 30.0, height: 9.0, alignment: prefs.fanTextAlign.alignment)
                        }
                    }
                }
                
            case .highest:
                let maxRPM = max(f1.currentRPM, f2.currentRPM)
                let maxPct = max(f1.percentage, f2.percentage)
                if prefs.fanTextMode == .rpm {
                    Text(String(format: "%.0f rpm", maxRPM))
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(width: 52, alignment: prefs.fanTextAlign.alignment)
                } else if prefs.fanTextMode == .percentage {
                    Text("\(Int(maxPct))%")
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(width: 34, alignment: prefs.fanTextAlign.alignment)
                }
                
            case .fan1:
                if prefs.fanTextMode == .rpm {
                    Text(String(format: "L %.0f rpm", f1.currentRPM))
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(width: 60, alignment: prefs.fanTextAlign.alignment)
                } else if prefs.fanTextMode == .percentage {
                    Text("\(Int(f1.percentage))%")
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(width: 34, alignment: prefs.fanTextAlign.alignment)
                }
                
            case .fan2:
                if prefs.fanTextMode == .rpm {
                    Text(String(format: "R %.0f rpm", f2.currentRPM))
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(width: 60, alignment: prefs.fanTextAlign.alignment)
                } else if prefs.fanTextMode == .percentage {
                    Text("\(Int(f2.percentage))%")
                        .font(.system(size: 10.5, weight: .light).monospacedDigit())
                        .foregroundColor(.primary)
                        .frame(width: 34, alignment: prefs.fanTextAlign.alignment)
                }
            }
        }
    }
}
