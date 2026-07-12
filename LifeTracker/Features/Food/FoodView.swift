import SwiftUI

/// The Food tab, split into the three sections from the spec:
/// what you have (pantry) · what you're making (weekly plan) · recipes.
struct FoodView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case have = "Have"
        case making = "Making"
        case recipes = "Recipes"
        case shop = "Shop"
        var id: String { rawValue }
    }

    @State private var segment: Segment = .have

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)

                switch segment {
                case .have:
                    PantryListView()
                case .making:
                    MealPlanView()
                case .recipes:
                    RecipeListView()
                case .shop:
                    ShoppingListView()
                }
            }
            .navigationTitle("Food")
        }
    }
}

#Preview {
    FoodView()
        .environment(Services.preview)
        .environment(AppSettings())
        .modelContainer(SampleData.previewContainer)
}
