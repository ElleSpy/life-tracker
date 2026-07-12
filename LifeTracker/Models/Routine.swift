import Foundation
import SwiftData

/// A reusable routine — an ordered list of steps for a particular kind of day
/// (work from home, office, weekend, …). Routines can be duplicated and there
/// are built-in suggested templates (see `SuggestedRoutines`).
@Model
final class Routine {
    var name: String
    var kind: RoutineKind
    var notes: String
    /// True for the built-in suggestions the user can copy into their own list.
    var isSuggested: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineStep.routine)
    var steps: [RoutineStep]

    init(
        name: String,
        kind: RoutineKind = .custom,
        notes: String = "",
        isSuggested: Bool = false,
        createdAt: Date = .now,
        steps: [RoutineStep] = []
    ) {
        self.name = name
        self.kind = kind
        self.notes = notes
        self.isSuggested = isSuggested
        self.createdAt = createdAt
        self.steps = steps
    }

    var orderedSteps: [RoutineStep] {
        steps.sorted { $0.order < $1.order }
    }

    var totalMinutes: Int {
        steps.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Create a deep copy of this routine (and its steps) as an editable,
    /// non-suggested routine the user owns.
    func duplicate(named newName: String? = nil) -> Routine {
        let copy = Routine(
            name: newName ?? "\(name) copy",
            kind: kind,
            notes: notes,
            isSuggested: false
        )
        copy.steps = orderedSteps.map {
            RoutineStep(
                title: $0.title,
                detail: $0.detail,
                startTime: $0.startTime,
                durationMinutes: $0.durationMinutes,
                order: $0.order,
                routine: copy
            )
        }
        return copy
    }
}

/// One step within a routine.
@Model
final class RoutineStep {
    var title: String
    var detail: String
    /// Optional wall-clock start time. Only the hour/minute components matter.
    var startTime: Date?
    var durationMinutes: Int
    var order: Int
    var routine: Routine?

    init(
        title: String,
        detail: String = "",
        startTime: Date? = nil,
        durationMinutes: Int = 15,
        order: Int = 0,
        routine: Routine? = nil
    ) {
        self.title = title
        self.detail = detail
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.order = order
        self.routine = routine
    }

    var startTimeText: String? {
        guard let startTime else { return nil }
        return startTime.formatted(date: .omitted, time: .shortened)
    }
}
