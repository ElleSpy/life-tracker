import SwiftUI
import SwiftData

/// "Recipes you want to make" — the recipe box. Filterable to the want-to-make
/// shortlist, with a manual add.
struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Services.self) private var services
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var showingAdd = false
    @State private var shortlistOnly = false

    @State private var showingImportPrompt = false
    @State private var importURL = ""
    @State private var isImporting = false
    @State private var importError: String?
    @State private var importPayload: ImportedRecipePayload?

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
        .overlay {
            if isImporting {
                ProgressView("Reading recipe…")
                    .padding(Theme.Spacing.xl)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("New recipe", systemImage: "square.and.pencil")
                    }
                    Button {
                        importURL = ""
                        showingImportPrompt = true
                    } label: {
                        Label("Import from URL", systemImage: "link")
                    }
                } label: {
                    Label("Add recipe", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddRecipeView()
        }
        .sheet(item: $importPayload) { payload in
            AddRecipeView(prefill: payload.recipe)
        }
        .alert("Import from a link", isPresented: $showingImportPrompt) {
            TextField("https://…", text: $importURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            Button("Import") { Task { await runImport() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Paste a link to a recipe page and we'll pull in the ingredients and steps for you to review.")
        }
        .alert("Couldn't import", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private func runImport() async {
        isImporting = true
        defer { isImporting = false }
        do {
            let parsed = try await services.recipeImport.importRecipe(from: importURL)
            importPayload = ImportedRecipePayload(recipe: parsed)
        } catch {
            importError = error.localizedDescription
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { modelContext.delete(shown[index]) }
    }
}

/// Identifiable wrapper so `.sheet(item:)` can carry a parsed recipe.
struct ImportedRecipePayload: Identifiable {
    let id = UUID()
    let recipe: ParsedRecipe
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
        .environment(Services.preview)
        .modelContainer(SampleData.previewContainer)
}
