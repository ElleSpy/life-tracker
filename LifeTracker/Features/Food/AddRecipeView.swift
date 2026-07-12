import SwiftUI

/// Sheet for adding a recipe, with editable ingredient and step lists.
struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var summary = ""
    @State private var servings = 2
    @State private var prepMinutes = 30
    @State private var wantToMake = false

    @State private var ingredients: [DraftIngredient] = [DraftIngredient()]
    @State private var steps: [String] = [""]

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
            .navigationTitle("New recipe")
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
        let recipe = Recipe(
            name: name.trimmingCharacters(in: .whitespaces),
            summary: summary,
            steps: steps.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            servings: servings,
            prepMinutes: prepMinutes,
            wantToMake: wantToMake
        )
        recipe.ingredients = ingredients
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { RecipeIngredient(name: $0.name, quantity: $0.quantity, unit: $0.unit, recipe: recipe) }
        modelContext.insert(recipe)
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
