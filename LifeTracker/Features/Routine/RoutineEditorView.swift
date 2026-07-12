import SwiftUI
import SwiftData

/// Create or edit a routine and its steps. Works for both a brand-new routine
/// and editing an existing owned one.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The routine being edited, or `nil` when creating a new one.
    var routine: Routine?

    @State private var name: String
    @State private var kind: RoutineKind
    @State private var notes: String
    @State private var steps: [DraftStep]

    init(routine: Routine? = nil) {
        self.routine = routine
        _name = State(initialValue: routine?.name ?? "")
        _kind = State(initialValue: routine?.kind ?? .custom)
        _notes = State(initialValue: routine?.notes ?? "")
        _steps = State(initialValue: (routine?.orderedSteps ?? []).map { DraftStep(from: $0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Routine name", text: $name)
                    Picker("Kind", selection: $kind) {
                        ForEach(RoutineKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Steps") {
                    ForEach($steps) { $step in
                        DraftStepEditor(step: $step)
                    }
                    .onDelete { steps.remove(atOffsets: $0) }
                    .onMove { steps.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        steps.append(DraftStep())
                    } label: {
                        Label("Add step", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(routine == nil ? "New routine" : "Edit routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
    }

    private func save() {
        let target: Routine
        if let routine {
            target = routine
            // Replace steps wholesale — simplest correct reconciliation.
            for existing in routine.steps { modelContext.delete(existing) }
            target.steps = []
        } else {
            target = Routine(name: "", isSuggested: false)
            modelContext.insert(target)
        }

        target.name = name.trimmingCharacters(in: .whitespaces)
        target.kind = kind
        target.notes = notes
        target.steps = steps.enumerated().map { index, draft in
            draft.makeStep(order: index, routine: target)
        }
        dismiss()
    }
}

/// Editable scratch model for a step.
struct DraftStep: Identifiable {
    let id = UUID()
    var title: String = ""
    var detail: String = ""
    var hasTime: Bool = false
    var time: Date = Date.now
    var duration: Int = 15

    init() {}

    init(from step: RoutineStep) {
        title = step.title
        detail = step.detail
        hasTime = step.startTime != nil
        time = step.startTime ?? .now
        duration = step.durationMinutes
    }

    func makeStep(order: Int, routine: Routine) -> RoutineStep {
        RoutineStep(
            title: title.trimmingCharacters(in: .whitespaces),
            detail: detail,
            startTime: hasTime ? time : nil,
            durationMinutes: duration,
            order: order,
            routine: routine
        )
    }
}

/// Inline editor for one draft step.
struct DraftStepEditor: View {
    @Binding var step: DraftStep

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            TextField("Step title", text: $step.title)
                .font(.body.weight(.medium))
            TextField("Detail (optional)", text: $step.detail)
                .font(.caption)
            HStack {
                Toggle("Time", isOn: $step.hasTime)
                    .labelsHidden()
                if step.hasTime {
                    DatePicker("", selection: $step.time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                Spacer()
                Stepper("\(step.duration)m", value: $step.duration, in: 5...240, step: 5)
                    .fixedSize()
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    RoutineEditorView()
        .modelContainer(SampleData.previewContainer)
}
