import Foundation
import SwiftData

/// A stored recipe. Lives in the "Recipes you want to make" section and can be
/// slotted into the weekly meal plan.
@Model
final class Recipe {
    var name: String
    var summary: String
    /// Free-text preparation steps, one entry per step.
    var steps: [String]
    var servings: Int
    var prepMinutes: Int
    var tags: [String]
    /// A shortlist flag: recipes the user wants to try soon.
    var wantToMake: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    init(
        name: String,
        summary: String = "",
        steps: [String] = [],
        servings: Int = 2,
        prepMinutes: Int = 30,
        tags: [String] = [],
        wantToMake: Bool = false,
        createdAt: Date = .now,
        ingredients: [RecipeIngredient] = []
    ) {
        self.name = name
        self.summary = summary
        self.steps = steps
        self.servings = servings
        self.prepMinutes = prepMinutes
        self.tags = tags
        self.wantToMake = wantToMake
        self.createdAt = createdAt
        self.ingredients = ingredients
    }
}

/// One ingredient line within a recipe.
@Model
final class RecipeIngredient {
    var name: String
    var quantity: Double
    var unit: String
    var recipe: Recipe?

    init(name: String, quantity: Double = 1, unit: String = "", recipe: Recipe? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.recipe = recipe
    }

    var displayLine: String {
        // A zero quantity with no unit means "unspecified" (e.g. imported
        // ingredient lines that already read like "2 cups flour").
        if quantity == 0 && unit.isEmpty { return name }
        let qty = quantity.rounded() == quantity
            ? String(Int(quantity))
            : String(format: "%.1f", quantity)
        let measure = unit.isEmpty ? qty : "\(qty) \(unit)"
        return "\(measure) \(name)".trimmingCharacters(in: .whitespaces)
    }
}
