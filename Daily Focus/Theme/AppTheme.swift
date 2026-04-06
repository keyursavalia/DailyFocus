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

    // Priority chips — darker/richer in light mode for readability; softer in dark mode
    static let priorityHigh = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.30, blue: 0.30, alpha: 1)
            : UIColor(red: 0.82, green: 0.16, blue: 0.16, alpha: 1)
    }
    static let priorityMedium = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.60, blue: 0.20, alpha: 1)
            : UIColor(red: 0.78, green: 0.52, blue: 0.02, alpha: 1)
    }
    static let priorityLow = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.58, blue: 0.38, alpha: 1)
            : UIColor(red: 0.12, green: 0.58, blue: 0.28, alpha: 1)
    }

    static let carriedOverOrange = UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1)

    // Calendar (dark-first; light mode uses similar structure)
    static let calendarGridBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black
            : UIColor(red: 0.91, green: 0.91, blue: 0.94, alpha: 1)
    }

    static let calendarPanelBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
            : UIColor.white
    }

    static let calendarDayDimmed = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(white: 0.55, alpha: 1)
    }

    /// Task stripes under dates (blue family)
    static let calendarStripeBlue = UIColor(red: 0.2, green: 0.55, blue: 1.0, alpha: 1)
    /// Task stripes under dates (green family)
    static let calendarStripeGreen = UIColor(red: 0.25, green: 0.78, blue: 0.45, alpha: 1)

    static let calendarFABBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.28, alpha: 1)
            : UIColor(white: 0.85, alpha: 1)
    }
}
