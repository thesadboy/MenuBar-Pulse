import SwiftUI

// MARK: - 合并模式主视图 (MenuBarItemView - Combined Mode)
public struct MenuBarItemView: View {
    @ObservedObject var prefs = PreferencesState.shared
    
    public init() {}
    
    public var body: some View {
        let hasAny = prefs.netShowInMenuBar || prefs.batShowInMenuBar || prefs.fanShowInMenuBar || prefs.tempShowInMenuBar
        HStack(spacing: 8) {
            if prefs.netShowInMenuBar {
                NetworkItemView()
            }
            if prefs.batShowInMenuBar {
                BatteryItemView()
            }
            if prefs.fanShowInMenuBar {
                FanItemView()
            }
            if prefs.tempShowInMenuBar {
                TemperatureItemView()
            }
            if !hasAny {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle.fill")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.primary)
                }
                .frame(width: 20)
            }
        }
        .padding(.horizontal, 4)
    }
}
