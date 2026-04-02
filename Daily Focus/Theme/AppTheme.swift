import UIKit

/// Semantic colors that adapt to light and dark mode via `UITraitCollection`.
enum AppTheme {

    static let background = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
    }

    static let primaryText = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(white: 0.12, alpha: 1)
    }

    static let secondaryText = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.65, alpha: 1)
            : UIColor(white: 0.45, alpha: 1)
    }

    static let tertiaryText = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.5, alpha: 1)
            : UIColor(white: 0.55, alpha: 1)
    }

    static let accent = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.0, green: 0.55, blue: 1.0, alpha: 1)
            : UIColor(red: 0.0, green: 0.45, blue: 0.95, alpha: 1)
    }

    static let accentBright = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1)
            : UIColor(red: 0.1, green: 0.55, blue: 1.0, alpha: 1)
    }

    static let cardBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
            : UIColor.white
    }

    static let elevatedBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
            : UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1)
    }

    static let fieldBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.2, alpha: 1)
            : UIColor(white: 0.92, alpha: 1)
    }

    static let border = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.3, alpha: 1)
            : UIColor(white: 0.82, alpha: 1)
    }

    static let progressTrack = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.22, alpha: 1)
            : UIColor(white: 0.85, alpha: 1)
    }

    static let dimmedOverlay = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.5)
            : UIColor.black.withAlphaComponent(0.35)
    }

    static let chromeTint = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.6, alpha: 1)
            : UIColor(white: 0.4, alpha: 1)
    }

    static let blueDot = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1)

    // Priority chips (subtle in both modes)
    static let priorityHigh = UIColor(red: 0.75, green: 0.35, blue: 0.35, alpha: 1)
    static let priorityMedium = UIColor(red: 0.75, green: 0.65, blue: 0.25, alpha: 1)
    static let priorityLow = UIColor(red: 0.35, green: 0.6, blue: 0.4, alpha: 1)

    static let carriedOverOrange = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1)
}
