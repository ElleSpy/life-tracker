import Foundation

/// A parsed item coming out of a receipt email or a photo, before it is turned
/// into a `PantryItem` the user can review and confirm.
struct ImportedPantryItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var category: PantryCategory
}

/// Bulk-adding to the pantry by parsing grocery receipts from email or photos.
///
/// Stubbed for now: `MockPantryImportService` returns a plausible shopping list
/// so the review-and-confirm flow is fully wired. A real implementation would
/// use the Gmail API (email) and Vision/OCR + a parser (photo).
protocol PantryImportService: AnyObject {
    func importFromEmail() async -> [ImportedPantryItem]
    func importFromPhoto() async -> [ImportedPantryItem]
}

final class MockPantryImportService: PantryImportService {
    func importFromEmail() async -> [ImportedPantryItem] {
        try? await Task.sleep(nanoseconds: 600_000_000)
        return Self.sampleReceipt
    }

    func importFromPhoto() async -> [ImportedPantryItem] {
        try? await Task.sleep(nanoseconds: 600_000_000)
        return Self.sampleReceipt
    }

    private static let sampleReceipt: [ImportedPantryItem] = [
        ImportedPantryItem(name: "Milk", quantity: 2, unit: "L", category: .dairy),
        ImportedPantryItem(name: "Eggs", quantity: 12, unit: "", category: .dairy),
        ImportedPantryItem(name: "Chicken breast", quantity: 500, unit: "g", category: .meat),
        ImportedPantryItem(name: "Spinach", quantity: 1, unit: "bag", category: .produce),
        ImportedPantryItem(name: "Pasta", quantity: 500, unit: "g", category: .pantry),
        ImportedPantryItem(name: "Tomatoes", quantity: 6, unit: "", category: .produce)
    ]
}
