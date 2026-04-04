import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case high = "High Priority"
    case low = "Low Priority"
    case medium = "Medium Priority"
}

struct FocusTask: Codable {
    var title: String
    var isCompleted: Bool
    var priority: TaskPriority
    var isCarriedOver: Bool
    var createdAt: Date
    /// Which calendar day this task belongs to (`yyyy-MM-dd`, local timezone).
    var dayKey: String

    private enum CodingKeys: String, CodingKey {
        case title, isCompleted, priority, isCarriedOver, createdAt, dayKey
    }

    init(
        title: String,
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        isCarriedOver: Bool = false,
        createdAt: Date = Date(),
        dayKey: String? = nil
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.isCarriedOver = isCarriedOver
        self.createdAt = createdAt
        self.dayKey = dayKey ?? DayKey.string(for: Date())
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        priority = try c.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
        isCarriedOver = try c.decodeIfPresent(Bool.self, forKey: .isCarriedOver) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        dayKey = try c.decodeIfPresent(String.self, forKey: .dayKey) ?? DayKey.string(for: Date())
    }
}
