import Foundation

/// Where a piece of data originated. Lets us distinguish things the user typed
/// from things pulled in by an integration (calendar, a to-do app, an import).
enum ItemSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case calendar
    case todoApp
    case emailImport
    case photoImport

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: return "Manual"
        case .calendar: return "Calendar"
        case .todoApp: return "To-do app"
        case .emailImport: return "Email"
        case .photoImport: return "Photo"
        }
    }

    var systemImage: String {
        switch self {
        case .manual: return "square.and.pencil"
        case .calendar: return "calendar"
        case .todoApp: return "checklist"
        case .emailImport: return "envelope"
        case .photoImport: return "camera"
        }
    }
}

enum Priority: Int, Codable, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var systemImage: String {
        switch self {
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon.stars"
        case .snack: return "carrot"
        }
    }

    /// Rough sort order across a day.
    var order: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }
}

/// A category for a routine, e.g. a work-from-home day vs an office day.
/// Users can also make their own via `.custom`.
enum RoutineKind: String, Codable, CaseIterable, Identifiable {
    case wfh
    case office
    case weekend
    case travel
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wfh: return "Work from home"
        case .office: return "Office day"
        case .weekend: return "Weekend"
        case .travel: return "Travel"
        case .custom: return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .wfh: return "house"
        case .office: return "building.2"
        case .weekend: return "beach.umbrella"
        case .travel: return "airplane"
        case .custom: return "slider.horizontal.3"
        }
    }
}

enum PantryCategory: String, Codable, CaseIterable, Identifiable {
    case produce
    case dairy
    case meat
    case pantry
    case frozen
    case bakery
    case drinks
    case other

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .produce: return "leaf"
        case .dairy: return "drop"
        case .meat: return "fish"
        case .pantry: return "cabinet"
        case .frozen: return "snowflake"
        case .bakery: return "birthday.cake"
        case .drinks: return "cup.and.saucer"
        case .other: return "shippingbox"
        }
    }
}
