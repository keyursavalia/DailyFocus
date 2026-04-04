import Foundation

class PersistenceManager: PersistenceManagerProtocol {
    static let shared = PersistenceManager()

    private let tasksByDayKey = "userTasksByDay"
    private let legacyTasksKey = "userTasks"

    private init() {}

    func saveTasksByDay(_ tasksByDay: [String: [FocusTask]]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tasksByDay)
            UserDefaults.standard.set(data, forKey: tasksByDayKey)
        } catch {
            print("Unable to encode tasks by day: \(error)")
        }
    }

    func loadTasksByDay() -> [String: [FocusTask]] {
        if let data = UserDefaults.standard.data(forKey: tasksByDayKey) {
            do {
                return try JSONDecoder().decode([String: [FocusTask]].self, from: data)
            } catch {
                print("Unable to decode tasks by day: \(error)")
            }
        }

        if let legacy = loadLegacyFlatTasks() {
            let today = DayKey.string(for: Date())
            let migrated = legacy.map { task in
                var t = task
                if t.dayKey.isEmpty { t.dayKey = today }
                return t
            }
            let grouped = Dictionary(grouping: migrated, by: \.dayKey)
                .mapValues { $0 }
            saveTasksByDay(grouped)
            UserDefaults.standard.removeObject(forKey: legacyTasksKey)
            return grouped
        }

        return [:]
    }

    private func loadLegacyFlatTasks() -> [FocusTask]? {
        guard let data = UserDefaults.standard.data(forKey: legacyTasksKey) else { return nil }

        if let tasks = try? JSONDecoder().decode([FocusTask].self, from: data) {
            return tasks
        }

        return migrateOldFormat(data: data)
    }

    private func migrateOldFormat(data: Data) -> [FocusTask]? {
        struct OldFocusTask: Codable {
            var title: String
            var isCompleted: Bool
        }

        do {
            let oldTasks = try JSONDecoder().decode([OldFocusTask].self, from: data)
            let today = DayKey.string(for: Date())
            let migrated = oldTasks.map { old in
                FocusTask(
                    title: old.title,
                    isCompleted: old.isCompleted,
                    priority: .medium,
                    isCarriedOver: false,
                    createdAt: Date(),
                    dayKey: today
                )
            }
            return migrated
        } catch {
            print("Legacy migration failed: \(error)")
            UserDefaults.standard.removeObject(forKey: legacyTasksKey)
            return nil
        }
    }

    func clearAllTasks() {
        UserDefaults.standard.removeObject(forKey: tasksByDayKey)
        UserDefaults.standard.removeObject(forKey: legacyTasksKey)
    }
}
