import SwiftUI

/// Review screen shown after an email/photo import. The user can tick off which
/// parsed items to actually add to the pantry before confirming.
struct PantryImportReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let items: [ImportedPantryItem]
    @State private var selected: Set<UUID>

    init(items: [ImportedPantryItem]) {
        self.items = items
        _selected = State(initialValue: Set(items.map(\.id)))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items) { item in
                        Button {
                            toggle(item.id)
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(item.id) ? Theme.Palette.accent : .secondary)
                                VStack(alignment: .leading) {
                                    Text(item.name).foregroundStyle(.primary)
                                    Text(item.category.label)
                                        .font(.caption)
                                        .foregroundStyle(Theme.Palette.subtleText)
                                }
                                Spacer()
                                Text(quantityText(item))
                                    .foregroundStyle(Theme.Palette.subtleText)
                            }
                        }
                    }
                } header: {
                    Text("Found \(items.count) items")
                } footer: {
                    Text("Review and untick anything you don't want. This is demo data — a real import would read your grocery receipt.")
                }
            }
            .navigationTitle("Import to pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selected.count)") { confirm() }
                        .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func quantityText(_ item: ImportedPantryItem) -> String {
        let qty = item.quantity.rounded() == item.quantity
            ? String(Int(item.quantity))
            : String(format: "%.1f", item.quantity)
        return item.unit.isEmpty ? qty : "\(qty) \(item.unit)"
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func confirm() {
        for item in items where selected.contains(item.id) {
            modelContext.insert(PantryItem(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                category: item.category,
                source: .emailImport
            ))
        }
        dismiss()
    }
}

#Preview {
    PantryImportReviewView(items: [
        ImportedPantryItem(name: "Milk", quantity: 2, unit: "L", category: .dairy),
        ImportedPantryItem(name: "Eggs", quantity: 12, unit: "", category: .dairy)
    ])
    .modelContainer(SampleData.previewContainer)
}
