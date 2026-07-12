import SwiftUI
import SwiftData

/// The Routine tab: the user's own routines plus suggested templates. Routines
/// can be created, duplicated and deleted.
struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt) private var routines: [Routine]

    @State private var showingEditor = false

    private var mine: [Routine] { routines.filter { !$0.isSuggested } }
    private var suggested: [Routine] { routines.filter(\.isSuggested) }

    var body: some View {
        NavigationStack {
            List {
                Section("Your routines") {
                    if mine.isEmpty {
                        Text("No routines yet. Create one, or copy a suggestion below.")
                            .foregroundStyle(Theme.Palette.subtleText)
                    } else {
                        ForEach(mine) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine)
                            } label: {
                                RoutineRow(routine: routine)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(routine)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    duplicate(routine)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                .tint(Theme.Palette.accent)
                            }
                        }
                    }
                }

                if !suggested.isEmpty {
                    Section {
                        ForEach(suggested) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine)
                            } label: {
                                RoutineRow(routine: routine)
                            }
                        }
                    } header: {
                        Text("Suggested")
                    } footer: {
                        Text("Tap a suggestion to preview it, then use it to create your own editable copy.")
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("New routine", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                RoutineEditorView()
            }
        }
    }

    private func duplicate(_ routine: Routine) {
        let copy = routine.duplicate()
        modelContext.insert(copy)
    }
}

struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: routine.kind.systemImage)
                .font(.title3)
                .foregroundStyle(Theme.Palette.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(routine.name)
                Text("\(routine.steps.count) steps · \(routine.totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }
}

#Preview {
    RoutineListView()
        .modelContainer(SampleData.previewContainer)
}
