import SwiftUI
import AppKit

// MARK: - 剪贴板辅助单例
public final class ClipboardHelper: ObservableObject {
    public static let shared = ClipboardHelper()
    @Published public var copiedText: String? = nil
    
    private init() {}
    
    public func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        self.copiedText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.copiedText == text {
                self?.copiedText = nil
            }
        }
    }
}

// MARK: - 极简紧凑文本行组件 (CompactRow)
public struct CompactRow: View {
    public let label: String
    public let value: String
    public var labelColor: Color = .secondary
    public var valueColor: Color = .primary
    
    public init(label: String, value: String, labelColor: Color = .secondary, valueColor: Color = .primary) {
        self.label = label
        self.value = value
        self.labelColor = labelColor
        self.valueColor = valueColor
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(labelColor)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
        .frame(height: 16)
    }
}

// MARK: - 可复制文本行组件 (CopyableRow)
public struct CopyableRow: View {
    public let label: String
    public let value: String
    @ObservedObject public var clipboard: ClipboardHelper = ClipboardHelper.shared
    
    public init(label: String, value: String, clipboard: ClipboardHelper = .shared) {
        self.label = label
        self.value = value
        self.clipboard = clipboard
    }
    
    private var isCopied: Bool { clipboard.copiedText == value }
    
    public var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundColor(.primary)
                
                Button(action: {
                    clipboard.copy(value)
                }) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(isCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("复制地址")
            }
        }
    }
}
