import Foundation
import SwiftData

/// An item on the shopping list. Can be added by hand or generated from the
/// weekly meal plan (recipe ingredients minus what's already in the pantry).
@Model
final class ShoppingItem {
    var name: String
    var quantity: Double
    var unit: String
    var category: PantryCategory
    var isChecked: Bool
    var source: ItemSource
    var addedAt: Date

    init(
        name: String,
        quantity: Double = 1,
        unit: String = "",
        category: PantryCategory = .other,
        isChecked: Bool = false,
        source: ItemSource = .manual,
        addedAt: Date = .now
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.source = source
        self.addedAt = addedAt
    }

    var quantityDescription: String {
        let qty = quantity.rounded() == quantity
            ? String(Int(quantity))
            : String(format: "%.1f", quantity)
        return unit.isEmpty ? qty : "\(qty) \(unit)"
    }

    /// Convert a checked-off shopping item into a pantry item (after shopping).
    func makePantryItem() -> PantryItem {
        PantryItem(name: name, quantity: quantity, unit: unit, category: category)
    }
}

/// Builds shopping-list suggestions from the meal plan and current pantry.
enum ShoppingListPlanner {
    /// Normalises a name for matching ("  Chicken Breast " -> "chicken breast").
    static func normalise(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Returns fresh `ShoppingItem`s for ingredients used by the given meal-plan
    /// entries that aren't already in the pantry or on the list. Quantities are
    /// summed across recipes; matching is by name (case-insensitive).
    static func suggestions(
        from entries: [MealPlanEntry],
        pantry: [PantryItem],
        existing: [ShoppingItem]
    ) -> [ShoppingItem] {
        // Aggregate needed ingredients across every planned recipe.
        var needed: [String: (name: String, qty: Double, unit: String, category: PantryCategory)] = [:]
        for entry in entries {
            guard let recipe = entry.recipe else { continue }
            for ingredient in recipe.ingredients {
                let key = normalise(ingredient.name)
                guard !key.isEmpty else { continue }
                if var current = needed[key] {
                    current.qty += ingredient.quantity
                    needed[key] = current
                } else {
                    needed[key] = (ingredient.name, ingredient.quantity, ingredient.unit, .other)
                }
            }
        }

        let pantryNames = Set(pantry.map { normalise($0.name) })
        let existingNames = Set(existing.map { normalise($0.name) })

        return needed.values
            .filter { !pantryNames.contains(normalise($0.name)) }
            .filter { !existingNames.contains(normalise($0.name)) }
            .sorted { $0.name < $1.name }
            .map {
                ShoppingItem(
                    name: $0.name,
                    quantity: $0.qty,
                    unit: $0.unit,
                    category: $0.category,
                    source: .manual
                )
            }
    }
}
