import Foundation
@testable import Daily_Focus

class MockPersistenceManager: PersistenceManagerProtocol {
    var tasksByDay: [String: [FocusTask]] = [:]
    var loadCalled = false

    func saveTasksByDay(_ tasksByDay: [String: [FocusTask]]) {
        self.tasksByDay = tasksByDay
    }

    func loadTasksByDay() -> [String: [FocusTask]] {
        loadCalled = true
        return tasksByDay
    }
}
