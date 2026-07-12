import SwiftUI
import SwiftData

/// The shopping list. Add items by hand, auto-generate from the weekly meal plan
/// (recipe ingredients you don't already have), tick things off as you shop, and
/// move the checked items into your pantry in one tap.
struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingItem.name) private var items: [ShoppingItem]
    @Query private var mealEntries: [MealPlanEntry]
    @Query private var pantry: [PantryItem]

    @State private var newItemName = ""
    @State private var showingGeneratedCount: Int?

    private var unchecked: [ShoppingItem] { items.filter { !$0.isChecked } }
    private var checked: [ShoppingItem] { items.filter(\.isChecked) }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add an item…", text: $newItemName)
                        .onSubmit(addManual)
                    Button(action: addManual) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Button {
                    generateFromPlan()
                } label: {
                    Label("Fill from this week's meal plan", systemImage: "sparkles")
                }
                if let count = showingGeneratedCount {
                    Text(count == 0
                         ? "You already have everything you need. Nice."
                         : "Added \(count) item\(count == 1 ? "" : "s") from your plan.")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }

            if items.isEmpty {
                Section {
                    Text("Your shopping list is empty.")
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }

            if !unchecked.isEmpty {
                Section("To buy") {
                    ForEach(unchecked) { item in
                        ShoppingRow(item: item)
                    }
                    .onDelete { delete($0, in: unchecked) }
                }
            }

            if !checked.isEmpty {
                Section {
                    ForEach(checked) { item in
                        ShoppingRow(item: item)
                    }
                    .onDelete { delete($0, in: checked) }
                } header: {
                    Text("In the basket")
                } footer: {
                    Button {
                        moveCheckedToPantry()
                    } label: {
                        Label("Move \(checked.count) to pantry & clear", systemImage: "arrow.down.to.line")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, Theme.Spacing.sm)
                }
            }
        }
        .animation(.default, value: showingGeneratedCount)
    }

    private func addManual() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(ShoppingItem(name: trimmed))
        newItemName = ""
        showingGeneratedCount = nil
    }

    private func generateFromPlan() {
        let suggestions = ShoppingListPlanner.suggestions(
            from: mealEntries, pantry: pantry, existing: items
        )
        suggestions.forEach(modelContext.insert)
        showingGeneratedCount = suggestions.count
    }

    private func moveCheckedToPantry() {
        for item in checked {
            modelContext.insert(item.makePantryItem())
            modelContext.delete(item)
        }
    }

    private func delete(_ offsets: IndexSet, in list: [ShoppingItem]) {
        for index in offsets { modelContext.delete(list[index]) }
    }
}

struct ShoppingRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        Button {
            item.isChecked.toggle()
        } label: {
            HStack {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? Theme.Palette.accent : .secondary)
                Text(item.name)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                Spacer()
                Text(item.quantityDescription)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ShoppingListView() }
        .modelContainer(SampleData.previewContainer)
}
