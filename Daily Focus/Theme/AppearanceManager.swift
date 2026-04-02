import UIKit

enum AppearancePreference: Int {
    case system = 0
    case light = 1
    case dark = 2

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    var symbolName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .system: return "Appearance: match system. Tap to use light mode."
        case .light: return "Appearance: light. Tap to use dark mode."
        case .dark: return "Appearance: dark. Tap to match system."
        }
    }
}

final class AppearanceManager {
    static let shared = AppearanceManager()

    private let defaultsKey = "appearancePreference"

    private init() {}

    var preference: AppearancePreference {
        get {
            let raw = UserDefaults.standard.integer(forKey: defaultsKey)
            return AppearancePreference(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            applyToAllWindows()
            NotificationCenter.default.post(name: .appearancePreferenceDidChange, object: nil)
        }
    }

    func apply(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = preference.userInterfaceStyle
    }

    func cyclePreference() {
        switch preference {
        case .system: preference = .light
        case .light: preference = .dark
        case .dark: preference = .system
        }
    }

    private func applyToAllWindows() {
        let style = preference.userInterfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            windowScene.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}

extension Notification.Name {
    static let appearancePreferenceDidChange = Notification.Name("appearancePreferenceDidChange")
}
