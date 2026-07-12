import SwiftUI

/// Sheet for manually adding a pantry item.
struct AddPantryItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = 1.0
    @State private var unit = ""
    @State private var category: PantryCategory = .other
    @State private var hasExpiry = false
    @State private var expiryDate = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $name)
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Qty", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        TextField("unit", text: $unit)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(PantryCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.systemImage).tag(cat)
                        }
                    }
                }

                Section {
                    Toggle("Expiry date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add to pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        modelContext.insert(PantryItem(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: quantity,
            unit: unit,
            category: category,
            expiryDate: hasExpiry ? expiryDate : nil
        ))
        dismiss()
    }
}

#Preview {
    AddPantryItemView()
        .modelContainer(SampleData.previewContainer)
}
