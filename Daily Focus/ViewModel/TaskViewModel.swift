import Foundation
import Combine

class TaskViewModel {
    // MARK: - Published Properties
    @Published private(set) var tasks: [FocusTask] = []
    
    // MARK: - Constants
    private let maxTaskLimit = 3
    private let persistenceManager: PersistenceManagerProtocol
    private let shouldAddDefaultTask: Bool
    
    // MARK: - Initialization
    init(persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared, shouldAddDefaultTask: Bool = true) {
        self.persistenceManager = persistenceManager
        self.shouldAddDefaultTask = shouldAddDefaultTask
        loadTasks()
    }
    
    // MARK: - Public Methods
    
    /// Loads tasks from persistence
    func loadTasks() {
        tasks = persistenceManager.load()
        // No default task - show empty state instead
    }
    
    /// Adds a new task if under the limit
    /// - Parameters:
    ///   - title: The task title
    ///   - priority: The task priority (default: .medium)
    /// - Returns: Result indicating success or failure with reason
    func addTask(title: String, priority: TaskPriority = .medium) -> Result<Void, TaskError> {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.emptyTitle)
        }
        
        guard tasks.count < maxTaskLimit else {
            return .failure(.limitReached)
        }
        
        let newTask = FocusTask(title: title, isCompleted: false, priority: priority, isCarriedOver: false)
        tasks.append(newTask)
        saveTasks()
        
        return .success(())
    }
    
    /// Updates task priority
    /// - Parameters:
    ///   - index: The index of the task
    ///   - priority: The new priority
    func updateTaskPriority(at index: Int, priority: TaskPriority) {
        guard index < tasks.count else { return }
        tasks[index].priority = priority
        saveTasks()
    }
    
    /// Marks a task as carried over
    /// - Parameter index: The index of the task
    func markAsCarriedOver(at index: Int) {
        guard index < tasks.count else { return }
        tasks[index].isCarriedOver = true
        saveTasks()
    }
    
    /// Toggles the completion status of a task
    /// - Parameter index: The index of the task
    func toggleTaskCompletion(at index: Int) {
        guard index < tasks.count else { return }
        tasks[index].isCompleted.toggle()
        saveTasks()
    }
    
    /// Deletes a task at the given index
    /// - Parameter index: The index of the task
    func deleteTask(at index: Int) {
        guard index < tasks.count else { return }
        tasks.remove(at: index)
        saveTasks()
    }
    
    /// Gets the task at a specific index
    /// - Parameter index: The index of the task
    /// - Returns: The task if index is valid
    func task(at index: Int) -> FocusTask? {
        guard index < tasks.count else { return nil }
        return tasks[index]
    }
    
    /// Returns the number of tasks
    var taskCount: Int {
        return tasks.count
    }
    
    /// Checks if more tasks can be added
    var canAddMoreTasks: Bool {
        return tasks.count < maxTaskLimit
    }
    
    // MARK: - Private Methods
    
    private func saveTasks() {
        persistenceManager.save(tasks: tasks)
    }
}
