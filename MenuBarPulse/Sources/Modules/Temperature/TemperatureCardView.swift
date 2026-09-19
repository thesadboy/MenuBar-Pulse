import SwiftUI

// MARK: - 温度卡片交互与折叠展开状态 (单例模式保证 CLI 工具链无宏依赖，且记忆展开偏好)
public final class TemperatureViewState: ObservableObject {
    public static let shared = TemperatureViewState()
    @Published public var expandedGroupIDs: Set<String> = []
    
    private init() {}
    
    public func isExpanded(_ id: String) -> Bool {
        return expandedGroupIDs.contains(id)
    }
    
    public func toggle(_ id: String) {
        if expandedGroupIDs.contains(id) {
            expandedGroupIDs.remove(id)
        } else {
            expandedGroupIDs.insert(id)
        }
    }
    
    public func areAllExpanded(allIDs: Set<String>) -> Bool {
        return !allIDs.isEmpty && expandedGroupIDs.isSuperset(of: allIDs)
    }
    
    public func toggleAll(allIDs: Set<String>) {
        if areAllExpanded(allIDs: allIDs) {
            expandedGroupIDs.removeAll()
        } else {
            expandedGroupIDs = allIDs
        }
    }
}

public struct TemperatureCardView: View {
    @ObservedObject var tempState = AppState.shared.tempState
    @ObservedObject var prefs = PreferencesState.shared
    @ObservedObject var viewState = TemperatureViewState.shared
    
    private var temperature: TemperatureSnapshot { tempState.snapshot }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // MARK: - 标题栏、主目标温度与全局展开/收起按钮
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("硬件温度")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 主目标温度数值
                let targetVal = temperature.targetValue(for: prefs.tempTarget)
                let targetStr = targetVal > 0 ? temperature.displayValue(celsiusValue: targetVal, unit: prefs.tempUnit) : "--"
                Text(targetStr)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundColor(.primary)
                
                // 全部展开 / 全部收起快捷切换按钮
                if !temperature.groups.isEmpty {
                    let allIDs = Set(temperature.groups.map(\.id))
                    let allExpanded = viewState.areAllExpanded(allIDs: allIDs)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewState.toggleAll(allIDs: allIDs)
                        }
                    }) {
                        Image(systemName: allExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                            .padding(.leading, 3)
                    }
                    .buttonStyle(.plain)
                    .help(allExpanded ? "收起全部明细" : "展开全部明细")
                }
            }
            .padding(.bottom, 2)
            
            // MARK: - 硬件类型分组列表 (支持展开/折叠明细探针)
            VStack(spacing: 3) {
                if !temperature.groups.isEmpty {
                    ForEach(temperature.groups) { group in
                        let isExpanded = viewState.isExpanded(group.id)
                        
                        VStack(spacing: 2) {
                            // 分组概要汇总行 (点击展开/收起)
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 8)
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                
                                Image(systemName: group.icon)
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary)
                                    .frame(width: 12)
                                
                                Text(group.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text("(\(group.sensors.count))")
                                    .font(.system(size: 9.5).monospacedDigit())
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Spacer(minLength: 4)
                                
                                Text(group.formattedSummary(unit: prefs.tempUnit))
                                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewState.toggle(group.id)
                                }
                            }
                            
                            // 展开后的各具体传感器明细 (平滑淡入滑出并裁剪)
                            if isExpanded {
                                VStack(spacing: 2) {
                                    ForEach(group.sensors) { sensor in
                                        CompactRow(
                                            label: sensor.name,
                                            value: temperature.formatSensorValue(celsius: sensor.celsius, unit: prefs.tempUnit)
                                        )
                                        .padding(.leading, 18)
                                    }
                                }
                                .padding(.top, 1)
                                .padding(.bottom, 2)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .clipped()
                            }
                        }
                    }
                } else if temperature.hasData {
                    // 回退兼容：仅有概要均值时
                    if temperature.cpuTemperature > 0 {
                        CompactRow(label: "中央处理器 (CPU)", value: temperature.displayValue(celsiusValue: temperature.cpuTemperature, unit: prefs.tempUnit))
                    }
                    if temperature.ssdTemperature > 0 {
                        CompactRow(label: "固态硬盘 (SSD)", value: temperature.displayValue(celsiusValue: temperature.ssdTemperature, unit: prefs.tempUnit))
                    }
                    if temperature.batteryTemperature > 0 {
                        CompactRow(label: "电池电芯", value: temperature.displayValue(celsiusValue: temperature.batteryTemperature, unit: prefs.tempUnit))
                    }
                } else {
                    CompactRow(label: "传感器状态", value: "读取中...")
                }
            }
        }
        .padding(.vertical, 4)
    }
}
