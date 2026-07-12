import SwiftUI
import SwiftData

/// "What you have" — the pantry. Grouped by category, with manual add plus the
/// (stubbed) import-from-email / import-from-photo flows.
struct PantryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Services.self) private var services
    @Query(sort: \PantryItem.name) private var items: [PantryItem]

    @State private var showingAdd = false
    @State private var importing: ImportReviewPayload?
    @State private var isImporting = false

    private var grouped: [(PantryCategory, [PantryItem])] {
        Dictionary(grouping: items, by: \.category)
            .sorted { $0.key.label < $1.key.label }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyStateView(
                    systemImage: "refrigerator",
                    title: "Your pantry is empty",
                    message: "Add items by hand, or import a shopping receipt from email or a photo.",
                    actionTitle: "Add an item",
                    action: { showingAdd = true }
                )
            } else {
                List {
                    ForEach(grouped, id: \.0) { category, categoryItems in
                        Section {
                            ForEach(categoryItems) { item in
                                PantryRow(item: item)
                            }
                            .onDelete { delete($0, in: categoryItems) }
                        } header: {
                            Label(category.label, systemImage: category.systemImage)
                        }
                    }
                }
            }
        }
        .overlay {
            if isImporting {
                ProgressView("Reading receipt…")
                    .padding(Theme.Spacing.xl)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add manually", systemImage: "square.and.pencil")
                    }
                    Button {
                        Task { await runImport(.email) }
                    } label: {
                        Label("Import from email", systemImage: "envelope")
                    }
                    Button {
                        Task { await runImport(.photo) }
                    } label: {
                        Label("Import from photo", systemImage: "camera")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddPantryItemView()
        }
        .sheet(item: $importing) { payload in
            PantryImportReviewView(items: payload.items)
        }
    }

    private func runImport(_ source: ImportSource) async {
        isImporting = true
        defer { isImporting = false }
        let results: [ImportedPantryItem]
        switch source {
        case .email: results = await services.pantryImport.importFromEmail()
        case .photo: results = await services.pantryImport.importFromPhoto()
        }
        if !results.isEmpty {
            importing = ImportReviewPayload(items: results)
        }
    }

    private func delete(_ offsets: IndexSet, in list: [PantryItem]) {
        for index in offsets { modelContext.delete(list[index]) }
    }
}

enum ImportSource { case email, photo }

/// Identifiable wrapper so `.sheet(item:)` can carry the imported items.
struct ImportReviewPayload: Identifiable {
    let id = UUID()
    let items: [ImportedPantryItem]
}

struct PantryRow: View {
    @Bindable var item: PantryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(item.name)
                if let expiry = item.expiryDate {
                    Label(expiry.formatted(.dateTime.month().day()), systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(item.expiresSoon ? .orange : Theme.Palette.subtleText)
                }
            }
            Spacer()
            Text(item.quantityDescription)
                .foregroundStyle(Theme.Palette.subtleText)
            if item.source != .manual {
                Image(systemName: item.source.systemImage)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }
}

#Preview {
    NavigationStack { PantryListView() }
        .environment(Services.preview)
        .modelContainer(SampleData.previewContainer)
}
