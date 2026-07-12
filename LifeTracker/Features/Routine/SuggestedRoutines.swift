import Foundation

/// Built-in routine templates the user can preview and copy into their own list.
/// These are surfaced as "Suggested routines" and are never edited in place —
/// tapping "Use this" duplicates them into an owned, editable routine.
enum SuggestedRoutines {
    static func all() -> [Routine] {
        [workFromHome(), officeDay(), weekend()]
    }

    private static func time(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    static func workFromHome() -> Routine {
        let routine = Routine(name: "Work from home", kind: .wfh, isSuggested: true)
        routine.steps = steps([
            ("Wake up & hydrate", "", time(7), 10),
            ("Morning walk", "Get outside before screens", time(7, 15), 25),
            ("Breakfast & coffee", "", time(7, 45), 25),
            ("Deep work block", "Phone in another room", time(9), 120),
            ("Lunch away from desk", "", time(12, 30), 45),
            ("Meetings & admin", "", time(14), 120),
            ("Shut the laptop", "Hard stop to protect evenings", time(17, 30), 5),
            ("Evening wind down", "", time(21, 30), 30)
        ], for: routine)
        return routine
    }

    static func officeDay() -> Routine {
        let routine = Routine(name: "Office day", kind: .office, isSuggested: true)
        routine.steps = steps([
            ("Wake up", "", time(6, 30), 10),
            ("Get ready & pack lunch", "", time(6, 40), 40),
            ("Commute", "Podcast or reading", time(7, 30), 45),
            ("Focus hour before standup", "", time(8, 30), 60),
            ("Lunch with a colleague", "", time(12, 30), 45),
            ("Commute home", "", time(17, 30), 45),
            ("Dinner", "", time(19), 45),
            ("Prep for tomorrow", "Lay out clothes, check calendar", time(21), 15)
        ], for: routine)
        return routine
    }

    static func weekend() -> Routine {
        let routine = Routine(name: "Weekend reset", kind: .weekend, isSuggested: true)
        routine.steps = steps([
            ("Slow morning", "No alarm", time(9), 60),
            ("Tidy & laundry", "", time(10), 60),
            ("Grocery shop", "Check the weekly food plan first", time(11), 60),
            ("Meal prep", "", time(15), 90),
            ("Something fun", "See friends / hobby / outdoors", time(17), 120),
            ("Plan the week ahead", "", time(20), 20)
        ], for: routine)
        return routine
    }

    private static func steps(_ raw: [(String, String, Date, Int)], for routine: Routine) -> [RoutineStep] {
        raw.enumerated().map { index, step in
            RoutineStep(
                title: step.0,
                detail: step.1,
                startTime: step.2,
                durationMinutes: step.3,
                order: index,
                routine: routine
            )
        }
    }
}
