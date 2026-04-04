import Foundation

protocol PersistenceManagerProtocol {
    func saveTasksByDay(_ tasksByDay: [String: [FocusTask]])
    func loadTasksByDay() -> [String: [FocusTask]]
}
