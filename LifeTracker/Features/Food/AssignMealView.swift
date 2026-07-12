import SwiftUI
import SwiftData

/// Sheet for filling a meal-plan slot with either a stored recipe or free text.
struct AssignMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    let day: Date
    let meal: MealType
    let existing: MealPlanEntry?

    @State private var freeText: String
    @State private var selectedRecipe: Recipe?

    init(day: Date, meal: MealType, existing: MealPlanEntry?) {
        self.day = day
        self.meal = meal
        self.existing = existing
        _freeText = State(initialValue: existing?.freeText ?? "")
        _selectedRecipe = State(initialValue: existing?.recipe)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick note") {
                    TextField("e.g. Leftovers, Eating out", text: $freeText)
                        .onChange(of: freeText) { _, newValue in
                            if !newValue.isEmpty { selectedRecipe = nil }
                        }
                }

                Section("Or pick a recipe") {
                    if recipes.isEmpty {
                        Text("No recipes yet. Add some in the Recipes tab.")
                            .foregroundStyle(Theme.Palette.subtleText)
                    } else {
                        ForEach(recipes) { recipe in
                            Button {
                                selectedRecipe = recipe
                                freeText = ""
                            } label: {
                                HStack {
                                    Text(recipe.name).foregroundStyle(.primary)
                                    Spacer()
                                    if selectedRecipe == recipe {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.Palette.accent)
                                    }
                                }
                            }
                        }
                    }
                }

                if existing != nil {
                    Section {
                        Button("Clear this meal", role: .destructive) { clear() }
                    }
                }
            }
            .navigationTitle(meal.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(freeText.isEmpty && selectedRecipe == nil)
                }
            }
        }
    }

    private func save() {
        if let existing {
            existing.freeText = freeText
            existing.recipe = selectedRecipe
        } else {
            modelContext.insert(MealPlanEntry(
                date: day, mealType: meal, freeText: freeText, recipe: selectedRecipe
            ))
        }
        dismiss()
    }

    private func clear() {
        if let existing { modelContext.delete(existing) }
        dismiss()
    }
}

#Preview {
    AssignMealView(day: .now, meal: .dinner, existing: nil)
        .modelContainer(SampleData.previewContainer)
}
