import Foundation
import SwiftData

/// A single actionable item on the Plan tab. Can be typed by the user or
/// synced in from an external to-do app (tracked via `source` / `externalID`).
@Model
final class TodoItem {
    var title: String
    var notes: String
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var priority: Priority
    var source: ItemSource
    /// Identifier from the originating service, so a sync can update in place
    /// rather than creating duplicates. `nil` for manual items.
    var externalID: String?
    /// Stable identifier used when scheduling/cancelling a local reminder.
    var reminderIdentifier: String
    var createdAt: Date

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        priority: Priority = .medium,
        source: ItemSource = .manual,
        externalID: String? = nil,
        reminderIdentifier: String = UUID().uuidString,
        createdAt: Date = .now
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = isCompleted ? createdAt : nil
        self.priority = priority
        self.source = source
        self.externalID = externalID
        self.reminderIdentifier = reminderIdentifier
        self.createdAt = createdAt
    }

    /// Toggle completion and stamp/clear the completion time.
    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? .now : nil
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < .now
    }
}
