import UIKit

enum AppearancePreference: Int {
    case light = 1
    case dark = 2

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }

    var symbolName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .light: return "Light mode. Tap to switch to dark."
        case .dark: return "Dark mode. Tap to switch to light."
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
            return AppearancePreference(rawValue: raw) ?? .dark
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
        preference = preference == .dark ? .light : .dark
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
