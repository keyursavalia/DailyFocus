import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case high = "High Priority"
    case low = "Low Priority"
    case medium = "Medium Priority"
}

struct FocusTask: Codable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var priority: TaskPriority
    var isCarriedOver: Bool
    var createdAt: Date
    /// Which calendar day this task belongs to (`yyyy-MM-dd`, local timezone).
    var dayKey: String
    /// When false, `startDate`/`endDate` are the scheduled interval; when true, the task spans the full `dayKey` day.
    var isAllDay: Bool
    /// Event start (used for list, calendar, and sheets).
    var startDate: Date
    /// Event end (must be after `startDate` when not all-day).
    var endDate: Date

    private enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, priority, isCarriedOver, createdAt, dayKey
        case isAllDay, startDate, endDate
    }

    init(
        title: String,
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        isCarriedOver: Bool = false,
        createdAt: Date = Date(),
        dayKey: String? = nil,
        id: UUID = UUID(),
        isAllDay: Bool = false,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.isCarriedOver = isCarriedOver
        self.createdAt = createdAt
        let day = dayKey ?? DayKey.string(for: Date())
        self.dayKey = day
        self.isAllDay = isAllDay
        let cal = Calendar.current
        if isAllDay, let d = DayKey.date(from: day) {
            let sod = cal.startOfDay(for: d)
            self.startDate = sod
            self.endDate = cal.date(byAdding: DateComponents(day: 1, second: -1), to: sod) ?? sod
        } else {
            let start = startDate ?? createdAt
            self.startDate = start
            self.endDate = endDate ?? cal.date(byAdding: .hour, value: 1, to: start) ?? start
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        priority = try c.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
        isCarriedOver = try c.decodeIfPresent(Bool.self, forKey: .isCarriedOver) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        dayKey = try c.decodeIfPresent(String.self, forKey: .dayKey) ?? DayKey.string(for: Date())
        isAllDay = try c.decodeIfPresent(Bool.self, forKey: .isAllDay) ?? false
        let decodedStart = try c.decodeIfPresent(Date.self, forKey: .startDate)
        let decodedEnd = try c.decodeIfPresent(Date.self, forKey: .endDate)
        if let s = decodedStart {
            startDate = s
        } else {
            startDate = createdAt
        }
        if let e = decodedEnd {
            endDate = e
        } else {
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        }
    }
}

struct TaskFormPayload {
    var title: String
    var priority: TaskPriority
    var isAllDay: Bool
    var startDate: Date
    var endDate: Date
}
