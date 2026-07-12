import Foundation
import EventKit

/// The external to-do providers we intend to connect to. Apple Reminders is a
/// real, working integration (via EventKit); the cloud providers are stubs
/// until their APIs are wired.
enum TodoProvider: String, CaseIterable, Identifiable {
    case reminders = "Apple Reminders"
    case todoist = "Todoist"
    case ticktick = "TickTick"
    case things = "Things"

    var id: String { rawValue }

    /// Whether this provider is a real integration today.
    var isLive: Bool { self == .reminders }

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

/// The app's default to-do sync. Apple Reminders is fully wired via EventKit;
/// the cloud providers fall back to sample data until their APIs are added.
final class DefaultTodoSyncService: TodoSyncService {
    private(set) var connectedProvider: TodoProvider?
    private let store = EKEventStore()

    func connect(_ provider: TodoProvider) async -> Bool {
        if provider == .reminders {
            let granted = (try? await store.requestFullAccessToReminders()) ?? false
            if granted { connectedProvider = .reminders }
            return granted
        }
        // Cloud providers: simulate a short OAuth round-trip for now.
        try? await Task.sleep(nanoseconds: 400_000_000)
        connectedProvider = provider
        return true
    }

    func disconnect() {
        connectedProvider = nil
    }

    func fetchTodos() async -> [RemoteTodo] {
        switch connectedProvider {
        case .reminders:
            return await fetchReminders()
        case .some:
            return Self.sampleTodos
        case .none:
            return []
        }
    }

    /// Read incomplete reminders from Apple Reminders.
    private func fetchReminders() async -> [RemoteTodo] {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: nil
        )
        let reminders: [EKReminder] = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { found in
                continuation.resume(returning: found ?? [])
            }
        }
        return reminders.map { reminder in
            RemoteTodo(
                id: reminder.calendarItemIdentifier,
                title: reminder.title ?? "Reminder",
                notes: reminder.notes ?? "",
                dueDate: reminder.dueDateComponents?.date,
                priority: Self.priority(from: reminder.priority)
            )
        }
    }

    /// Map EventKit's 0–9 priority scale to our three levels.
    private static func priority(from ekPriority: Int) -> Priority {
        switch ekPriority {
        case 1...4: return .high
        case 5: return .medium
        case 6...9: return .low
        default: return .medium
        }
    }

    private static let sampleTodos: [RemoteTodo] = {
        let cal = Calendar.current
        return [
            RemoteTodo(id: "r1", title: "Renew passport", notes: "Expires in October",
                       dueDate: cal.date(byAdding: .day, value: 5, to: .now), priority: .high),
            RemoteTodo(id: "r2", title: "Reply to landlord", notes: "",
                       dueDate: cal.date(byAdding: .day, value: 1, to: .now), priority: .medium),
            RemoteTodo(id: "r3", title: "Book dentist", notes: "6-month checkup",
                       dueDate: nil, priority: .low)
        ]
    }()
}

/// All-mock to-do sync for previews and demo mode.
final class MockTodoSyncService: TodoSyncService {
    private(set) var connectedProvider: TodoProvider?

    func connect(_ provider: TodoProvider) async -> Bool {
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
                       dueDate: cal.date(byAdding: .day, value: 1, to: .now), priority: .medium)
        ]
    }
}
