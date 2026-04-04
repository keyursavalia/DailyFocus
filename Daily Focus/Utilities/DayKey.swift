import Foundation

extension Notification.Name {
    static let dailyFocusSceneDidBecomeActive = Notification.Name("dailyFocusSceneDidBecomeActive")
}

/// Calendar-day identifier in the user's local timezone (`yyyy-MM-dd`).
enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        return formatter.string(from: start)
    }

    static func date(from dayKey: String, calendar: Calendar = .current) -> Date? {
        guard let d = formatter.date(from: dayKey) else { return nil }
        return calendar.startOfDay(for: d)
    }

    static func components(from dayKey: String, calendar: Calendar = .current) -> DateComponents? {
        guard let d = date(from: dayKey, calendar: calendar) else { return nil }
        return calendar.dateComponents([.year, .month, .day], from: d)
    }
}
