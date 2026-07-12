import SwiftUI
import SwiftData
import Observation

/// Create or edit a routine and its steps. Works for both a brand-new routine
/// and editing an existing owned one.
///
/// The draft is held in `@Observable` objects so editing one field (e.g. the
/// name) only re-renders that field — not every step row. This keeps typing
/// smooth even on long routines.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The routine being edited, or `nil` when creating a new one.
    var routine: Routine?

    @State private var draft: RoutineDraft
    @FocusState private var nameFocused: Bool

    init(routine: Routine? = nil) {
        self.routine = routine
        _draft = State(initialValue: RoutineDraft(from: routine))
    }

    var body: some View {
        @Bindable var draft = draft
        return NavigationStack {
            Form {
                Section {
                    TextField("Routine name", text: $draft.name)
                        .focused($nameFocused)
                    Picker("Kind", selection: $draft.kind) {
                        ForEach(RoutineKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    ForEach(draft.steps) { step in
                        DraftStepEditor(step: step)
                    }
                    .onDelete { draft.steps.remove(atOffsets: $0) }
                    .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        draft.steps.append(RoutineStepDraft())
                    } label: {
                        Label("Add step", systemImage: "plus")
                    }
                } header: {
                    HStack {
                        Text("Steps")
                        Spacer()
                        if draft.steps.count > 1 { EditButton().textCase(nil) }
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
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if routine == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        nameFocused = true
                    }
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

        target.name = draft.name.trimmingCharacters(in: .whitespaces)
        target.kind = draft.kind
        target.notes = draft.notes
        target.steps = draft.steps.enumerated().map { index, step in
            step.makeStep(order: index, routine: target)
        }
        dismiss()
    }
}

/// Observable draft of a whole routine.
@Observable
final class RoutineDraft {
    var name: String
    var kind: RoutineKind
    var notes: String
    var steps: [RoutineStepDraft]

    init(from routine: Routine?) {
        name = routine?.name ?? ""
        kind = routine?.kind ?? .custom
        notes = routine?.notes ?? ""
        steps = (routine?.orderedSteps ?? []).map(RoutineStepDraft.init(from:))
    }
}

/// Observable draft of a single step. Each row observes only its own object, so
/// editing the routine name or another step never re-renders this one.
@Observable
final class RoutineStepDraft: Identifiable {
    let id = UUID()
    var title: String
    var detail: String
    var hasTime: Bool
    var time: Date
    var duration: Int

    init(title: String = "", detail: String = "", hasTime: Bool = false,
         time: Date = .now, duration: Int = 15) {
        self.title = title
        self.detail = detail
        self.hasTime = hasTime
        self.time = time
        self.duration = duration
    }

    convenience init(from step: RoutineStep) {
        self.init(
            title: step.title,
            detail: step.detail,
            hasTime: step.startTime != nil,
            time: step.startTime ?? .now,
            duration: step.durationMinutes
        )
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

/// Inline editor for one draft step. Each control sits on its own generous row
/// so taps land reliably.
struct DraftStepEditor: View {
    @Bindable var step: RoutineStepDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            TextField("Step title", text: $step.title)
                .font(.body.weight(.medium))
            TextField("Detail (optional)", text: $step.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.subtleText)

            Toggle("Set a start time", isOn: $step.hasTime)
                .font(.subheadline)
            if step.hasTime {
                DatePicker("Starts at", selection: $step.time, displayedComponents: .hourAndMinute)
                    .font(.subheadline)
            }

            Stepper("Duration: \(step.duration) min", value: $step.duration, in: 5...240, step: 5)
                .font(.subheadline)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    RoutineEditorView()
        .modelContainer(SampleData.previewContainer)
}
