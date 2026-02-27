import Foundation

enum TaskError: LocalizedError, Equatable {
    case limitReached
    case emptyTitle
    
    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "You can only focus on 3 things at once. Finish something first!"
        case .emptyTitle:
            return "Please enter a task name before adding."
        }
    }
    
    var alertTitle: String {
        switch self {
        case .limitReached:
            return "Limit Reached"
        case .emptyTitle:
            return "Missing Title"
        }
    }
}
