import SwiftUI

/// Sheet for adding *or editing* a recipe, with editable ingredient and step
/// lists. Pass `editing:` to edit an existing recipe in place.
struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The recipe being edited, or `nil` when creating a new one.
    var editing: Recipe?

    @State private var name: String
    @State private var summary: String
    @State private var servings: Int
    @State private var prepMinutes: Int
    @State private var wantToMake: Bool

    @State private var ingredients: [DraftIngredient]
    @State private var steps: [String]

    init(editing: Recipe? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _summary = State(initialValue: editing?.summary ?? "")
        _servings = State(initialValue: editing?.servings ?? 2)
        _prepMinutes = State(initialValue: editing?.prepMinutes ?? 30)
        _wantToMake = State(initialValue: editing?.wantToMake ?? false)
        _ingredients = State(initialValue: {
            let existing = editing?.ingredients ?? []
            return existing.isEmpty
                ? [DraftIngredient()]
                : existing.map { DraftIngredient(name: $0.name, quantity: $0.quantity, unit: $0.unit) }
        }())
        _steps = State(initialValue: {
            let existing = editing?.steps ?? []
            return existing.isEmpty ? [""] : existing
        }())
    }

    /// Seed the editor from a recipe parsed off the web, for review before
    /// saving. Ingredient lines keep a 0 quantity so they display verbatim.
    init(prefill: ParsedRecipe) {
        self.editing = nil
        _name = State(initialValue: prefill.name)
        _summary = State(initialValue: prefill.summary)
        _servings = State(initialValue: prefill.servings)
        _prepMinutes = State(initialValue: 30)
        _wantToMake = State(initialValue: false)
        _ingredients = State(initialValue: prefill.ingredients.isEmpty
            ? [DraftIngredient()]
            : prefill.ingredients.map { DraftIngredient(name: $0, quantity: 0, unit: "") })
        _steps = State(initialValue: prefill.steps.isEmpty ? [""] : prefill.steps)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Recipe name", text: $name)
                    TextField("Short description (optional)", text: $summary, axis: .vertical)
                        .lineLimit(1...3)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    Stepper("Prep: \(prepMinutes) min", value: $prepMinutes, in: 5...240, step: 5)
                    Toggle("Add to want-to-make list", isOn: $wantToMake)
                }

                Section("Ingredients") {
                    ForEach($ingredients) { $ingredient in
                        HStack {
                            TextField("Name", text: $ingredient.name)
                            TextField("Qty", value: $ingredient.quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                            TextField("unit", text: $ingredient.unit)
                                .frame(width: 60)
                        }
                    }
                    .onDelete { ingredients.remove(atOffsets: $0) }
                    Button {
                        ingredients.append(DraftIngredient())
                    } label: {
                        Label("Add ingredient", systemImage: "plus")
                    }
                }

                Section("Method") {
                    ForEach(steps.indices, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $steps[index], axis: .vertical)
                            .lineLimit(1...4)
                    }
                    .onDelete { steps.remove(atOffsets: $0) }
                    Button {
                        steps.append("")
                    } label: {
                        Label("Add step", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(editing == nil ? "New recipe" : "Edit recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let recipe: Recipe
        if let editing {
            recipe = editing
            // Replace ingredients wholesale — simplest correct reconciliation.
            for ingredient in editing.ingredients { modelContext.delete(ingredient) }
            recipe.ingredients = []
        } else {
            recipe = Recipe(name: "")
            modelContext.insert(recipe)
        }

        recipe.name = name.trimmingCharacters(in: .whitespaces)
        recipe.summary = summary
        recipe.steps = steps.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        recipe.servings = servings
        recipe.prepMinutes = prepMinutes
        recipe.wantToMake = wantToMake
        recipe.ingredients = ingredients
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { RecipeIngredient(name: $0.name, quantity: $0.quantity, unit: $0.unit, recipe: recipe) }
        dismiss()
    }
}

/// Mutable, identifiable scratch model for the ingredient editor rows.
struct DraftIngredient: Identifiable {
    let id = UUID()
    var name: String = ""
    var quantity: Double = 1
    var unit: String = ""
}

#Preview {
    AddRecipeView()
        .modelContainer(SampleData.previewContainer)
}
