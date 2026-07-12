import SwiftUI

/// Sheet for manually adding a to-do to the Plan tab.
struct AddTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var defaultDate: Date = .now

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = true
    @State private var dueDate = Date.now
    @State private var priority: Priority = .medium

    init(defaultDate: Date = .now) {
        self.defaultDate = defaultDate
        _dueDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you need to do?", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section {
                    Toggle("Due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New to-do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let item = TodoItem(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority
        )
        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    AddTodoView()
        .modelContainer(SampleData.previewContainer)
}
