import SwiftUI
import SwiftData

/// "Recipes you want to make" — the recipe box. Filterable to the want-to-make
/// shortlist, with a manual add.
struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var showingAdd = false
    @State private var shortlistOnly = false

    private var shown: [Recipe] {
        shortlistOnly ? recipes.filter(\.wantToMake) : recipes
    }

    var body: some View {
        Group {
            if recipes.isEmpty {
                EmptyStateView(
                    systemImage: "book.closed",
                    title: "No recipes yet",
                    message: "Save recipes you love or want to try, then slot them into your weekly plan.",
                    actionTitle: "Add a recipe",
                    action: { showingAdd = true }
                )
            } else {
                List {
                    Section {
                        Toggle("Want-to-make only", isOn: $shortlistOnly)
                    }
                    ForEach(shown) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeRow(recipe: recipe)
                        }
                    }
                    .onDelete { delete($0) }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Label("Add recipe", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddRecipeView()
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { modelContext.delete(shown[index]) }
    }
}

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title)
                .foregroundStyle(Theme.Palette.accent)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(recipe.name)
                HStack(spacing: Theme.Spacing.sm) {
                    Label("\(recipe.prepMinutes) min", systemImage: "clock")
                    Label("\(recipe.servings)", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundStyle(Theme.Palette.subtleText)
            }
            Spacer()
            if recipe.wantToMake {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
            }
        }
    }
}

#Preview {
    NavigationStack { RecipeListView() }
        .modelContainer(SampleData.previewContainer)
}
