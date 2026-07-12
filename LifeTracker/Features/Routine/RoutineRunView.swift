import SwiftUI

/// A live "run" of a routine: step through the day's routine, checking off each
/// step as you go, with a progress bar. Progress is per-session (not persisted)
/// so every run starts fresh.
struct RoutineRunView: View {
    @Environment(\.dismiss) private var dismiss
    let routine: Routine

    @State private var completed: Set<ObjectIdentifier> = []

    private var steps: [RoutineStep] { routine.orderedSteps }
    private var doneCount: Int { steps.filter { completed.contains(ObjectIdentifier($0)) }.count }
    private var progress: Double { steps.isEmpty ? 0 : Double(doneCount) / Double(steps.count) }
    private var isFinished: Bool { !steps.isEmpty && doneCount == steps.count }

    /// The first not-yet-completed step, highlighted as "up next".
    private var currentStep: RoutineStep? {
        steps.first { !completed.contains(ObjectIdentifier($0)) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                List {
                    ForEach(steps) { step in
                        RunStepRow(
                            step: step,
                            isDone: completed.contains(ObjectIdentifier(step)),
                            isCurrent: step === currentStep,
                            toggle: { toggle(step) }
                        )
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(routine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if isFinished {
                Label("Routine complete — nice work!", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.accent)
            } else if let currentStep {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Up next")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                    Text(currentStep.title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
            }
            ProgressView(value: progress)
                .tint(Theme.Palette.accent)
            Text("\(doneCount) of \(steps.count) done")
                .font(.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.cardBackground)
    }

    private func toggle(_ step: RoutineStep) {
        let id = ObjectIdentifier(step)
        if completed.contains(id) {
            completed.remove(id)
        } else {
            completed.insert(id)
        }
    }
}

private struct RunStepRow: View {
    let step: RoutineStep
    let isDone: Bool
    let isCurrent: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isDone ? Theme.Palette.accent : .secondary)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(step.title)
                        .strikethrough(isDone)
                        .foregroundStyle(isDone ? .secondary : .primary)
                    if let time = step.startTimeText {
                        Text("\(time) · \(step.durationMinutes) min")
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.subtleText)
                    } else {
                        Text("\(step.durationMinutes) min")
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.subtleText)
                    }
                }
                Spacer()
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(.plain)
        .listRowBackground(isCurrent ? Theme.Palette.accent.opacity(0.10) : nil)
    }
}

#Preview {
    RoutineRunView(routine: SuggestedRoutines.workFromHome())
        .modelContainer(SampleData.previewContainer)
}
