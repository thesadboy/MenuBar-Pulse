import SwiftUI

// MARK: - 电池卡片视图 (BatteryCardView)
public struct BatteryCardView: View {
    @ObservedObject var batState = AppState.shared.batState
    private var battery: BatterySnapshot { batState.snapshot }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 模块标题行
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "battery.100.bolt")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("内建电池")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("\(battery.percentage)%")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 2)
            
            // 参数列表：健康度, 循环次数, 供电状态, 剩余时间, 上次充电, 适配器功率, 满充容量, 设计容量
            VStack(spacing: 3) {
                if !battery.ageString.isEmpty {
                    let mfgStr = battery.manufactureDateString.isEmpty ? "" : " (出厂: \(battery.manufactureDateString))"
                    CompactRow(label: "电池年龄", value: "\(battery.ageString)\(mfgStr)")
                }
                
                let healthStr = battery.healthPercentage.truncatingRemainder(dividingBy: 1) == 0 ?
                    String(format: "%.0f%%", battery.healthPercentage) :
                    String(format: "%.1f%%", battery.healthPercentage)
                CompactRow(label: "电池健康寿命", value: "\(healthStr) (\(battery.condition))")
                
                CompactRow(label: "循环计数", value: "\(battery.cycleCount) 次")
                
                let powerStr = battery.isACConnected ? "已连接电源 (\(battery.isCharging ? "充电中" : "已充满"))" : "电池供电"
                CompactRow(label: "供电状态", value: powerStr)
                
                if !battery.isACConnected || battery.isCharging {
                    let timeLabel = battery.isCharging ? "充满还需" : "剩余可用"
                    CompactRow(label: timeLabel, value: battery.timeRemainingFormatted)
                }
                
                if !battery.lastChargeFormatted.isEmpty {
                    CompactRow(label: "上次充电", value: battery.lastChargeFormatted)
                }
                
                if battery.adapterWatts > 0 {
                    CompactRow(label: "适配器功率", value: "\(battery.adapterWatts)W")
                }
                
                let cap = battery.fullChargeCapacity > 0 ? battery.fullChargeCapacity : battery.nominalCapacity
                if cap > 0 {
                    CompactRow(label: "满充容量", value: "\(cap) mAh")
                }
                
                if battery.designCapacity > 0 {
                    CompactRow(label: "设计容量", value: "\(battery.designCapacity) mAh")
                }
            }
        }
        .padding(.vertical, 4)
    }
}
