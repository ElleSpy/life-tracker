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

/// Read access to the user's calendars. `EventKitCalendarService` is the real
/// implementation; `MockCalendarService` backs previews and simulator demos
/// where calendar access hasn't been granted.
protocol CalendarService: AnyObject {
    var authStatus: CalendarAuthStatus { get }
    func requestAccess() async -> Bool
    func events(on day: Date) async -> [CalendarEvent]
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

    func events(on day: Date) async -> [CalendarEvent] {
        guard authStatus == .authorized else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
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

    func events(on day: Date) async -> [CalendarEvent] {
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
