import Foundation
import SwiftData

/// Seeds first-run demo content and provides an in-memory container for previews.
enum SampleData {
    /// Seeds sample data once, keyed off whether any routines exist yet.
    static func seedIfNeeded(in context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<Routine>())
        guard (existing?.isEmpty ?? true) else { return }
        populate(context)
        try? context.save()
    }

    /// Fills a context with a realistic starter dataset.
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current

        // Suggested routines (read-only templates the user can copy).
        for routine in SuggestedRoutines.all() {
            context.insert(routine)
        }

        // A couple of the user's own routines.
        let myWFH = SuggestedRoutines.workFromHome().duplicate(named: "My WFH day")
        context.insert(myWFH)

        // To-dos on the Plan tab.
        let todos = [
            TodoItem(title: "Water the plants", dueDate: .now, priority: .low),
            TodoItem(title: "Finish project proposal",
                     notes: "Send to the team before Friday",
                     dueDate: cal.date(byAdding: .day, value: 2, to: .now), priority: .high),
            TodoItem(title: "Call mum", dueDate: cal.date(byAdding: .day, value: 1, to: .now)),
            TodoItem(title: "Order new running shoes", priority: .low)
        ]
        todos.forEach(context.insert)

        // Pantry.
        let pantry = [
            PantryItem(name: "Eggs", quantity: 6, unit: "", category: .dairy,
                       expiryDate: cal.date(byAdding: .day, value: 5, to: .now)),
            PantryItem(name: "Milk", quantity: 1, unit: "L", category: .dairy,
                       expiryDate: cal.date(byAdding: .day, value: 2, to: .now)),
            PantryItem(name: "Chicken breast", quantity: 400, unit: "g", category: .meat),
            PantryItem(name: "Rice", quantity: 1, unit: "kg", category: .pantry),
            PantryItem(name: "Broccoli", quantity: 1, unit: "head", category: .produce),
            PantryItem(name: "Olive oil", quantity: 1, unit: "bottle", category: .pantry)
        ]
        pantry.forEach(context.insert)

        // Recipes.
        let stirFry = Recipe(
            name: "Chicken & broccoli stir fry",
            summary: "Quick weeknight dinner using up what's in the fridge.",
            steps: [
                "Cook rice according to the packet.",
                "Slice and fry the chicken until golden.",
                "Add broccoli and a splash of soy sauce; stir fry 4 minutes.",
                "Serve over rice."
            ],
            servings: 2, prepMinutes: 25, tags: ["quick", "high-protein"], wantToMake: false
        )
        stirFry.ingredients = [
            RecipeIngredient(name: "Chicken breast", quantity: 400, unit: "g", recipe: stirFry),
            RecipeIngredient(name: "Broccoli", quantity: 1, unit: "head", recipe: stirFry),
            RecipeIngredient(name: "Rice", quantity: 150, unit: "g", recipe: stirFry),
            RecipeIngredient(name: "Soy sauce", quantity: 2, unit: "tbsp", recipe: stirFry)
        ]
        context.insert(stirFry)

        let ramen = Recipe(
            name: "Weekend miso ramen",
            summary: "A cosy bowl for a slow weekend.",
            steps: ["Simmer stock with miso.", "Cook noodles.", "Top with egg and greens."],
            servings: 2, prepMinutes: 45, tags: ["comfort"], wantToMake: true
        )
        context.insert(ramen)

        // Weekly plan: a few slots for the next couple of days.
        let dinnerToday = MealPlanEntry(date: .now, mealType: .dinner, recipe: stirFry)
        let breakfastTomorrow = MealPlanEntry(
            date: cal.date(byAdding: .day, value: 1, to: .now) ?? .now,
            mealType: .breakfast, freeText: "Porridge & berries"
        )
        context.insert(dinnerToday)
        context.insert(breakfastTomorrow)
    }

    /// In-memory container preloaded with sample data, for SwiftUI previews.
    @MainActor
    static var previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: TodoItem.self, PantryItem.self, Recipe.self,
            RecipeIngredient.self, MealPlanEntry.self, Routine.self, RoutineStep.self,
            configurations: config
        )
        populate(container.mainContext)
        return container
    }()
}
