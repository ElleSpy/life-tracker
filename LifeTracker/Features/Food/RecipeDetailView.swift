import SwiftUI

/// Full recipe view with ingredients and steps, plus a shortcut to add any
/// missing ingredients to the pantry (handy after cooking / before shopping).
struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

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
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
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
