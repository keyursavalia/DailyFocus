import Foundation
import Combine

class TaskViewModel {
    @Published private(set) var tasks: [FocusTask] = []

    private let maxTaskLimit = 3
    private let persistenceManager: PersistenceManagerProtocol
    private var tasksByDay: [String: [FocusTask]] = [:]
    /// Calendar day for the main Focus list (always "today" in local time).
    private var displayedDayKey: String = DayKey.string(for: Date())

    init(persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared, shouldAddDefaultTask: Bool = true) {
        self.persistenceManager = persistenceManager
        _ = shouldAddDefaultTask
        loadTasks()
    }

    func loadTasks() {
        tasksByDay = persistenceManager.loadTasksByDay()
        displayedDayKey = DayKey.string(for: Date())
        tasks = tasksByDay[displayedDayKey] ?? []
    }

    /// Call when the app may have crossed midnight or when returning to the main screen.
    func refreshForCurrentCalendarDayIfNeeded() {
        let todayKey = DayKey.string(for: Date())
        tasksByDay = persistenceManager.loadTasksByDay()
        displayedDayKey = todayKey
        tasks = tasksByDay[displayedDayKey] ?? []
    }

    func addTask(title: String, priority: TaskPriority = .medium) -> Result<Void, TaskError> {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.emptyTitle)
        }

        guard tasks.count < maxTaskLimit else {
            return .failure(.limitReached)
        }

        let todayKey = DayKey.string(for: Date())
        displayedDayKey = todayKey

        let newTask = FocusTask(
            title: title,
            isCompleted: false,
            priority: priority,
            isCarriedOver: false,
            createdAt: Date(),
            dayKey: todayKey
        )
        tasks.append(newTask)
        saveTasks()
        return .success(())
    }

    func updateTaskPriority(at index: Int, priority: TaskPriority) {
        guard index < tasks.count else { return }
        tasks[index].priority = priority
        saveTasks()
    }

    func markAsCarriedOver(at index: Int) {
        guard index < tasks.count else { return }
        tasks[index].isCarriedOver = true
        saveTasks()
    }

    func toggleTaskCompletion(at index: Int) {
        guard index < tasks.count else { return }
        tasks[index].isCompleted.toggle()
        saveTasks()
    }

    func deleteTask(at index: Int) {
        guard index < tasks.count else { return }
        tasks.remove(at: index)
        saveTasks()
    }

    func task(at index: Int) -> FocusTask? {
        guard index < tasks.count else { return nil }
        return tasks[index]
    }

    var taskCount: Int { tasks.count }

    var canAddMoreTasks: Bool { tasks.count < maxTaskLimit }

    func resetAllTasks() {
        tasks.removeAll()
        saveTasks()
    }

    private func saveTasks() {
        tasksByDay[displayedDayKey] = tasks
        persistenceManager.saveTasksByDay(tasksByDay)
    }
}
