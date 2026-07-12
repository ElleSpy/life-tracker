import Foundation
import SwiftData

/// A single slot in the weekly food plan: one meal on one day. It either points
/// at a stored `Recipe` or holds free text (e.g. "Leftovers", "Eating out").
@Model
final class MealPlanEntry {
    /// Normalised to the start of the day so entries group cleanly by date.
    var date: Date
    var mealType: MealType
    var freeText: String
    var recipe: Recipe?

    init(date: Date, mealType: MealType, freeText: String = "", recipe: Recipe? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.mealType = mealType
        self.freeText = freeText
        self.recipe = recipe
    }

    /// What to show in the plan grid.
    var displayTitle: String {
        if let recipe { return recipe.name }
        return freeText
    }

    var isEmpty: Bool {
        recipe == nil && freeText.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
