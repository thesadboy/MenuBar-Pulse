import Foundation
import Combine
import AppKit

public class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    
    @Published public var isChecking = false
    @Published public var updateStatus: String? = nil
    @Published public var newVersionURL: URL? = nil
    @Published public var newVersionString: String? = nil
    
    private let repoURL = "https://api.github.com/repos/thesadboy/MenuBar-Pulse/releases/latest"
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    private init() {}
    
    public func checkForUpdates() {
        guard !isChecking else { return }
        
        DispatchQueue.main.async {
            self.isChecking = true
            self.updateStatus = "正在检查更新..."
            self.newVersionURL = nil
            self.newVersionString = nil
        }
        
        guard let url = URL(string: repoURL) else {
            self.setFailed(message: "检查失败：无效的 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        // 防止被 GitHub API 速率限制或缓存
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.setFailed(message: "网络错误: \(error.localizedDescription)")
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURLStr = json["html_url"] as? String else {
                self.setFailed(message: "获取更新信息失败")
                return
            }
            
            let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
            
            DispatchQueue.main.async {
                self.isChecking = false
                if self.compareVersions(latest: latestVersion, current: self.currentVersion) {
                    self.updateStatus = "发现新版本：v\(latestVersion)"
                    self.newVersionString = latestVersion
                    self.newVersionURL = URL(string: htmlURLStr)
                } else {
                    self.updateStatus = "已是最新版本"
                }
            }
        }.resume()
    }
    
    private func setFailed(message: String) {
        DispatchQueue.main.async {
            self.isChecking = false
            self.updateStatus = message
        }
    }
    
    // Returns true if latest > current
    private func compareVersions(latest: String, current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        
        let count = max(latestParts.count, currentParts.count)
        
        for i in 0..<count {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}
