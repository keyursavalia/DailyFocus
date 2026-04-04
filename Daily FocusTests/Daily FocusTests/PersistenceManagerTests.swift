import XCTest
@testable import Daily_Focus

class PersistenceManagerTests: XCTestCase {
    var persistenceManager: PersistenceManager!

    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager.shared
        UserDefaults.standard.removeObject(forKey: "userTasksByDay")
        UserDefaults.standard.removeObject(forKey: "userTasks")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "userTasksByDay")
        UserDefaults.standard.removeObject(forKey: "userTasks")
        super.tearDown()
    }

    func testSaveAndLoadByDay() {
        let day = DayKey.string(for: Date())
        let tasks = [
            FocusTask(title: "Task 1", isCompleted: false, dayKey: day),
            FocusTask(title: "Task 2", isCompleted: true, dayKey: day)
        ]
        let payload = [day: tasks]

        persistenceManager.saveTasksByDay(payload)
        let loaded = persistenceManager.loadTasksByDay()

        XCTAssertEqual(loaded[day]?.count, 2)
        XCTAssertEqual(loaded[day]?[0].title, "Task 1")
        XCTAssertEqual(loaded[day]?[1].title, "Task 2")
        XCTAssertFalse(loaded[day]?[0].isCompleted ?? true)
        XCTAssertTrue(loaded[day]?[1].isCompleted ?? false)
    }

    func testLoadEmpty() {
        let tasks = persistenceManager.loadTasksByDay()
        XCTAssertTrue(tasks.isEmpty)
    }
}
