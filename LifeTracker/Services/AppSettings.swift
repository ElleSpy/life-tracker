import Foundation
import Observation

/// Which day the week starts on in week-based views and date pickers.
enum WeekStart: String, CaseIterable, Identifiable {
    case system
    case monday
    case sunday

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Match phone"
        case .monday: return "Monday"
        case .sunday: return "Sunday"
        }
    }

    /// The Calendar `firstWeekday` value (1 = Sunday), or `nil` to defer to the
    /// device locale.
    var firstWeekday: Int? {
        switch self {
        case .system: return nil
        case .sunday: return 1
        case .monday: return 2
        }
    }
}

/// User-facing app preferences, persisted in `UserDefaults`. Observable so the
/// UI updates immediately when a setting changes.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var weekStart: WeekStart {
        didSet { defaults.set(weekStart.rawValue, forKey: Keys.weekStart) }
    }

    /// Identifiers of the calendars the user has chosen to show. Empty means
    /// "all calendars".
    var selectedCalendarIDs: Set<String> {
        didSet { defaults.set(Array(selectedCalendarIDs), forKey: Keys.selectedCalendars) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.weekStart = defaults.string(forKey: Keys.weekStart)
            .flatMap(WeekStart.init(rawValue:)) ?? .system
        self.selectedCalendarIDs = Set(defaults.stringArray(forKey: Keys.selectedCalendars) ?? [])
    }

    /// A `Calendar` reflecting the chosen week-start (falling back to the device
    /// locale). Inject this into the SwiftUI environment so date pickers and our
    /// week views agree.
    var calendar: Calendar {
        var cal = Calendar.current
        if let firstWeekday = weekStart.firstWeekday {
            cal.firstWeekday = firstWeekday
        }
        return cal
    }

    /// The seven days of the week containing `date`, aligned to `calendar`'s
    /// first weekday.
    func weekDays(containing date: Date = .now) -> [Date] {
        let cal = calendar
        let start = cal.dateInterval(of: .weekOfYear, for: date)?.start
            ?? cal.startOfDay(for: date)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private enum Keys {
        static let weekStart = "settings.weekStart"
        static let selectedCalendars = "settings.selectedCalendars"
    }
}
