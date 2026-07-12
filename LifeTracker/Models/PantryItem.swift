import Foundation
import SwiftData

/// Something you have in the kitchen. The "What you have" section of Food.
/// Items can be added manually or imported from an email receipt / photo.
@Model
final class PantryItem {
    var name: String
    var quantity: Double
    var unit: String
    var category: PantryCategory
    var expiryDate: Date?
    var source: ItemSource
    var addedAt: Date

    init(
        name: String,
        quantity: Double = 1,
        unit: String = "",
        category: PantryCategory = .other,
        expiryDate: Date? = nil,
        source: ItemSource = .manual,
        addedAt: Date = .now
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.expiryDate = expiryDate
        self.source = source
        self.addedAt = addedAt
    }

    /// A short "2 kg" style string, trimming a trailing ".0" for whole numbers.
    var quantityDescription: String {
        let qty = quantity.rounded() == quantity
            ? String(Int(quantity))
            : String(format: "%.1f", quantity)
        return unit.isEmpty ? qty : "\(qty) \(unit)"
    }

    var expiresSoon: Bool {
        guard let expiryDate else { return false }
        return expiryDate < Calendar.current.date(byAdding: .day, value: 3, to: .now)!
    }
}
