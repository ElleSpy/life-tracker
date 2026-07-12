import SwiftUI
import SwiftData

/// Shows a routine's steps. Suggested routines are read-only with a "Use this"
/// action; owned routines can be edited or duplicated.
struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var routine: Routine

    @State private var showingEditor = false

    var body: some View {
        List {
            if !routine.notes.isEmpty {
                Section { Text(routine.notes) }
            }

            Section {
                ForEach(routine.orderedSteps) { step in
                    RoutineStepRow(step: step)
                }
            } header: {
                HStack {
                    Text("Steps")
                    Spacer()
                    Text("\(routine.totalMinutes) min total")
                }
            }

            if routine.isSuggested {
                Section {
                    Button {
                        useThis()
                    } label: {
                        Label("Use this routine", systemImage: "plus.square.on.square")
                    }
                } footer: {
                    Text("Creates an editable copy in your routines.")
                }
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !routine.isSuggested {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showingEditor = true }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            RoutineEditorView(routine: routine)
        }
    }

    private func useThis() {
        let copy = routine.duplicate(named: routine.name)
        modelContext.insert(copy)
        dismiss()
    }
}

struct RoutineStepRow: View {
    let step: RoutineStep

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack {
                Text(step.startTimeText ?? "—")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(step.startTimeText == nil ? Theme.Palette.subtleText : .primary)
            }
            .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(step.title)
                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }
            Spacer()
            Text("\(step.durationMinutes)m")
                .font(.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }
}

#Preview {
    NavigationStack {
        RoutineDetailView(routine: SuggestedRoutines.workFromHome())
    }
    .modelContainer(SampleData.previewContainer)
}
