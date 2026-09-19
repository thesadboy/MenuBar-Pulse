import SwiftUI

public struct FanCardView: View {
    @ObservedObject var fanState = AppState.shared.fanState
    
    private var fan: FanSnapshot { fanState.snapshot }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "fan.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("散热风扇")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
                if !fan.isFanless && !fan.fans.isEmpty {
                    if fan.fans.count == 1 {
                        Text(String(format: "%.0f rpm", fan.fans[0].currentRPM))
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundColor(.primary)
                    } else {
                        Text(String(format: "%.0f / %.0f rpm", fan.fans[0].currentRPM, fan.fans[1].currentRPM))
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("静音运转")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 2)
            
            VStack(spacing: 3) {
                if !fan.isFanless && !fan.fans.isEmpty {
                    ForEach(fan.fans) { f in
                        let pctStr = f.percentage > 0 ? String(format: "%.0f rpm (%.0f%%)", f.currentRPM, f.percentage) : String(format: "%.0f rpm", f.currentRPM)
                        CompactRow(label: f.name, value: pctStr)
                    }
                } else {
                    CompactRow(label: "散热架构", value: "静音被动散热 (Apple Silicon)")
                }
                
                CompactRow(label: "系统热压力", value: fan.thermalStateString)
            }
        }
        .padding(.vertical, 4)
    }
}
