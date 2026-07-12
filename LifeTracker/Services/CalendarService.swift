import Foundation
import EventKit

/// A calendar event, decoupled from EventKit so views never import EventKit
/// directly and so we can swap in a mock for previews/tests.
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarColorHex: String?

    var timeText: String {
        if isAllDay { return "All day" }
        let start = start.formatted(date: .omitted, time: .shortened)
        let end = end.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }
}

enum CalendarAuthStatus {
    case notDetermined
    case authorized
    case denied
}

/// A calendar the user can choose to show or hide.
struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let colorHex: String?
}

/// Read access to the user's calendars. `EventKitCalendarService` is the real
/// implementation; `MockCalendarService` backs previews and simulator demos
/// where calendar access hasn't been granted.
protocol CalendarService: AnyObject {
    var authStatus: CalendarAuthStatus { get }
    func requestAccess() async -> Bool
    /// All calendars the user could choose to display.
    func availableCalendars() -> [CalendarInfo]
    /// Events on `day`, limited to `calendarIDs`. An empty set means all
    /// calendars.
    func events(on day: Date, calendarIDs: Set<String>) async -> [CalendarEvent]
}

/// Real EventKit-backed calendar access.
final class EventKitCalendarService: CalendarService {
    private let store = EKEventStore()

    var authStatus: CalendarAuthStatus {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return .notDetermined
        case .fullAccess, .authorized:
            return .authorized
        default:
            return .denied
        }
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func availableCalendars() -> [CalendarInfo] {
        guard authStatus == .authorized else { return [] }
        return store.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { CalendarInfo(id: $0.calendarIdentifier, title: $0.title,
                                colorHex: $0.cgColor.flatMap(Self.hex(from:))) }
    }

    func events(on day: Date, calendarIDs: Set<String>) async -> [CalendarEvent] {
        guard authStatus == .authorized else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        // Restrict to the chosen calendars (empty selection = all).
        let allCalendars = store.calendars(for: .event)
        let chosen = calendarIDs.isEmpty
            ? allCalendars
            : allCalendars.filter { calendarIDs.contains($0.calendarIdentifier) }
        guard !chosen.isEmpty else { return [] }

        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: chosen
        )
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEvent(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "(No title)",
                    start: event.startDate,
                    end: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarColorHex: event.calendar?.cgColor.flatMap(Self.hex(from:))
                )
            }
    }

    private static func hex(from color: CGColor) -> String? {
        guard let components = color.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

/// A no-network stand-in used for previews and demo mode.
final class MockCalendarService: CalendarService {
    var authStatus: CalendarAuthStatus = .authorized

    func requestAccess() async -> Bool { true }

    func availableCalendars() -> [CalendarInfo] {
        [
            CalendarInfo(id: "personal", title: "Personal", colorHex: "#5A66B0"),
            CalendarInfo(id: "work", title: "Work", colorHex: "#8C6BB0"),
            CalendarInfo(id: "birthdays", title: "Birthdays", colorHex: "#4CAF50")
        ]
    }

    func events(on day: Date, calendarIDs: Set<String>) async -> [CalendarEvent] {
        let cal = Calendar.current
        func at(_ hour: Int, _ minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }
        return [
            CalendarEvent(id: "m1", title: "Team standup", start: at(9), end: at(9, 30),
                          isAllDay: false, calendarColorHex: "#5A66B0"),
            CalendarEvent(id: "m2", title: "Lunch with Sam", start: at(12, 30), end: at(13, 30),
                          isAllDay: false, calendarColorHex: "#8C6BB0"),
            CalendarEvent(id: "m3", title: "Design review", start: at(15), end: at(16),
                          isAllDay: false, calendarColorHex: "#5A66B0")
        ]
    }
}
