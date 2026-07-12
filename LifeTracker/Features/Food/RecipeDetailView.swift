import SwiftUI
import SwiftData

/// Full recipe view with ingredients and steps. Includes two kitchen shortcuts:
/// "I cooked this" (deducts ingredients from the pantry) and "add missing to
/// shopping list".
struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe
    @Query private var pantry: [PantryItem]
    @Query private var shopping: [ShoppingItem]

    @State private var toast: String?

    /// Ingredients not currently in the pantry (by name, case-insensitive).
    private var missingIngredients: [RecipeIngredient] {
        let have = Set(pantry.map { ShoppingListPlanner.normalise($0.name) })
        return recipe.ingredients.filter { !have.contains(ShoppingListPlanner.normalise($0.name)) }
    }

    var body: some View {
        List {
            Section {
                if !recipe.summary.isEmpty {
                    Text(recipe.summary)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
                HStack(spacing: Theme.Spacing.lg) {
                    Label("\(recipe.prepMinutes) min", systemImage: "clock")
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .font(.subheadline)
                Toggle("On my want-to-make list", isOn: $recipe.wantToMake)
                if !recipe.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(recipe.tags, id: \.self) { Pill(text: $0) }
                        }
                    }
                }
            }

            Section("Ingredients") {
                if recipe.ingredients.isEmpty {
                    Text("No ingredients listed.")
                        .foregroundStyle(Theme.Palette.subtleText)
                } else {
                    ForEach(recipe.ingredients) { ingredient in
                        Text(ingredient.displayLine)
                    }
                }
            }

            Section("Method") {
                if recipe.steps.isEmpty {
                    Text("No steps listed.")
                        .foregroundStyle(Theme.Palette.subtleText)
                } else {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: Theme.Spacing.md) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Theme.Palette.accent)
                                .clipShape(Circle())
                            Text(step)
                        }
                    }
                }
            }

            Section {
                Button {
                    cookThis()
                } label: {
                    Label("I cooked this", systemImage: "flame")
                }
                Button {
                    addMissingToShoppingList()
                } label: {
                    Label("Add \(missingIngredients.count) missing to shopping list",
                          systemImage: "cart.badge.plus")
                }
                .disabled(missingIngredients.isEmpty)
                if let toast {
                    Text(toast)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            } footer: {
                Text("\"I cooked this\" subtracts the ingredients from your pantry.")
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: toast)
    }

    /// Deduct each ingredient's quantity from a matching pantry item, removing
    /// pantry items that reach zero.
    private func cookThis() {
        var deducted = 0
        for ingredient in recipe.ingredients {
            let key = ShoppingListPlanner.normalise(ingredient.name)
            guard let match = pantry.first(where: { ShoppingListPlanner.normalise($0.name) == key })
            else { continue }
            match.quantity -= ingredient.quantity
            deducted += 1
            if match.quantity <= 0 {
                modelContext.delete(match)
            }
        }
        toast = deducted == 0
            ? "None of these were in your pantry."
            : "Updated \(deducted) pantry item\(deducted == 1 ? "" : "s")."
    }

    private func addMissingToShoppingList() {
        let onList = Set(shopping.map { ShoppingListPlanner.normalise($0.name) })
        var added = 0
        for ingredient in missingIngredients
        where !onList.contains(ShoppingListPlanner.normalise(ingredient.name)) {
            modelContext.insert(ShoppingItem(
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit
            ))
            added += 1
        }
        toast = "Added \(added) item\(added == 1 ? "" : "s") to your shopping list."
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(
            name: "Test recipe",
            summary: "A tasty test.",
            steps: ["Do the thing", "Do the next thing"],
            tags: ["quick"],
            ingredients: [RecipeIngredient(name: "Salt", quantity: 1, unit: "tsp")]
        ))
    }
    .modelContainer(SampleData.previewContainer)
}
