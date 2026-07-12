import Foundation

/// The external to-do providers we intend to connect to.
enum TodoProvider: String, CaseIterable, Identifiable {
    case reminders = "Apple Reminders"
    case todoist = "Todoist"
    case ticktick = "TickTick"
    case things = "Things"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .reminders: return "list.bullet"
        case .todoist: return "checkmark.circle"
        case .ticktick: return "checkmark.square"
        case .things: return "star.circle"
        }
    }
}

/// A task fetched from an external provider, in a provider-neutral shape.
struct RemoteTodo: Identifiable {
    let id: String
    let title: String
    let notes: String
    let dueDate: Date?
    let priority: Priority
}

/// Two-way(ish) sync with an external to-do app.
///
/// This is intentionally stubbed for now: `MockTodoSyncService` returns sample
/// data so the Plan tab and connection UI are fully exercised. Real providers
/// (OAuth + their APIs) slot in behind this protocol without touching the UI.
protocol TodoSyncService: AnyObject {
    var connectedProvider: TodoProvider? { get }
    func connect(_ provider: TodoProvider) async -> Bool
    func disconnect()
    func fetchTodos() async -> [RemoteTodo]
}

final class MockTodoSyncService: TodoSyncService {
    private(set) var connectedProvider: TodoProvider?

    func connect(_ provider: TodoProvider) async -> Bool {
        // Simulate a short OAuth round-trip.
        try? await Task.sleep(nanoseconds: 400_000_000)
        connectedProvider = provider
        return true
    }

    func disconnect() {
        connectedProvider = nil
    }

    func fetchTodos() async -> [RemoteTodo] {
        guard connectedProvider != nil else { return [] }
        let cal = Calendar.current
        return [
            RemoteTodo(id: "r1", title: "Renew passport", notes: "Expires in October",
                       dueDate: cal.date(byAdding: .day, value: 5, to: .now), priority: .high),
            RemoteTodo(id: "r2", title: "Reply to landlord", notes: "",
                       dueDate: cal.date(byAdding: .day, value: 1, to: .now), priority: .medium),
            RemoteTodo(id: "r3", title: "Book dentist", notes: "6-month checkup",
                       dueDate: nil, priority: .low)
        ]
    }
}
