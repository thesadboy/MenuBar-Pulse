import SwiftUI

public struct TemperatureItemView: View {
    @ObservedObject var tempState = AppState.shared.tempState
    @ObservedObject var prefs = PreferencesState.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 3.5) {
            if prefs.tempShowModuleName {
                Text("TEMP")
                    .font(.system(size: 8.5, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            if prefs.tempShowIcon {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 11.5))
                    .foregroundColor(prefs.tempColor.color)
            }
            
            if prefs.tempDisplayMode != .none {
                let text = tempState.snapshot.formattedString(
                    target: prefs.tempTarget,
                    unit: prefs.tempUnit,
                    mode: prefs.tempDisplayMode
                )
                Text(text)
                    .font(.system(size: 10.5, weight: .light).monospacedDigit())
                    .foregroundColor(.primary)
                    .frame(minWidth: prefs.tempDisplayMode == .valueWithUnit ? 28 : 22, alignment: prefs.tempTextAlign.alignment)
            }
        }
    }
}
