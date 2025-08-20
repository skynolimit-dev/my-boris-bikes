import UIKit

// MARK: - Bundle Extension for App Info Access
extension Bundle {
    /// Returns the app icon as a UIImage
    var appIcon: UIImage? {
        // Try to get the icon from the CFBundleIcons dictionary
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        
        // Fallback: Try to get icon from CFBundleIconFile (older format)
        if let iconName = infoDictionary?["CFBundleIconFile"] as? String {
            return UIImage(named: iconName)
        }
        
        return nil
    }
    
    /// Returns the app version string from Info.plist
    var appVersionString: String {
        // Try to get the version (CFBundleShortVersionString)
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        
        // Optionally include build number (CFBundleVersion)
        if let build = infoDictionary?["CFBundleVersion"] as? String,
           version != build {
            return "\(version) (\(build))"
        }
        
        return version
    }
}