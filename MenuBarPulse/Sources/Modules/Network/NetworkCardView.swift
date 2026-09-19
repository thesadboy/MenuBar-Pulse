import SwiftUI

// MARK: - 网络卡片视图 (NetworkCardView)
public struct NetworkCardView: View {
    @ObservedObject var netState = AppState.shared.netState
    @ObservedObject var clipboard: ClipboardHelper = ClipboardHelper.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 模块标题行
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(netState.snapshot.interfaceType.isEmpty ? "Wi-Fi" : netState.snapshot.interfaceType)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 接口标识
                Text(netState.snapshot.activeInterface.isEmpty ? "en0" : netState.snapshot.activeInterface)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)
            
            // 数据列表：上传, 下载, 本机 IP, 活动接口
            VStack(spacing: 3) {
                CompactRow(
                    label: "上传速率",
                    value: "\(NetworkMonitor.formatSpeed(netState.snapshot.uploadBytesPerSec)) | \(NetworkMonitor.formatBytes(netState.snapshot.totalOutBytes))"
                )
                
                CompactRow(
                    label: "下载速率",
                    value: "\(NetworkMonitor.formatSpeed(netState.snapshot.downloadBytesPerSec)) | \(NetworkMonitor.formatBytes(netState.snapshot.totalInBytes))"
                )
                
                CopyableRow(
                    label: "本机 IP",
                    value: netState.snapshot.localIP.isEmpty ? "127.0.0.1" : netState.snapshot.localIP,
                    clipboard: clipboard
                )
                
                CompactRow(label: "网络接口", value: "\(netState.snapshot.interfaceType) (\(netState.snapshot.activeInterface))")
            }
        }
        .padding(.vertical, 4)
    }
}
