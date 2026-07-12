import SwiftUI
import SwiftData

/// The Plan tab: a to-do list combined with the day's calendar events, plus
/// manual additions and (stubbed) sync from an external to-do app.
struct PlanView: View {
    @Environment(Services.self) private var services
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var todos: [TodoItem]
    @Query private var mealEntries: [MealPlanEntry]

    @State private var selectedDay: Date = .now
    @State private var events: [CalendarEvent] = []
    @State private var isLoadingEvents = false
    @State private var calendarDenied = false
    @State private var showingAddTodo = false
    @State private var isSyncing = false

    private var openTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var doneTodos: [TodoItem] {
        todos.filter(\.isCompleted)
    }

    /// Open tasks due on the selected day.
    private var tasksDueSelectedDay: [TodoItem] {
        openTodos.filter { todo in
            guard let due = todo.dueDate else { return false }
            return Calendar.current.isDate(due, inSameDayAs: selectedDay)
        }
    }

    /// The dinner planned for the selected day, if any.
    private var dinnerSelectedDay: MealPlanEntry? {
        mealEntries.first {
            $0.mealType == .dinner
                && Calendar.current.isDate($0.date, inSameDayAs: selectedDay)
                && !$0.isEmpty
        }
    }

    private var nextEvent: CalendarEvent? {
        events.first { $0.end > .now } ?? events.first
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDay) }

    var body: some View {
        NavigationStack {
            List {
                WeekStripView(selectedDay: $selectedDay)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                summarySection

                calendarSection

                Section("To-do") {
                    if openTodos.isEmpty {
                        Text("Nothing on your list. Nice.")
                            .foregroundStyle(Theme.Palette.subtleText)
                    } else {
                        ForEach(openTodos) { todo in
                            TodoRowView(todo: todo)
                        }
                        .onDelete { delete($0, from: openTodos) }
                    }
                }

                if !doneTodos.isEmpty {
                    Section("Completed") {
                        ForEach(doneTodos) { todo in
                            TodoRowView(todo: todo)
                        }
                        .onDelete { delete($0, from: doneTodos) }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await syncTodos() }
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isSyncing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTodo = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoView(defaultDate: selectedDay)
            }
            .task(id: selectedDay) { await loadEvents() }
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        Section(isToday ? "Today at a glance" : "At a glance") {
            SummaryRow(
                systemImage: "checklist",
                title: "\(tasksDueSelectedDay.count) task\(tasksDueSelectedDay.count == 1 ? "" : "s") due",
                detail: tasksDueSelectedDay.first?.title
            )
            SummaryRow(
                systemImage: "calendar",
                title: nextEvent.map { isToday ? "Next: \($0.title)" : $0.title } ?? "No events",
                detail: nextEvent?.timeText
            )
            SummaryRow(
                systemImage: "fork.knife",
                title: dinnerSelectedDay.map { "Dinner: \($0.displayTitle)" } ?? "No dinner planned",
                detail: dinnerSelectedDay == nil ? "Plan one in Food › Making" : nil
            )
        }
    }

    @ViewBuilder
    private var calendarSection: some View {
        Section("Calendar") {
            if calendarDenied {
                Label("Calendar access is off. Turn it on in Settings to see your events here.",
                      systemImage: "calendar.badge.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.subtleText)
            } else if isLoadingEvents {
                HStack { ProgressView(); Text("Loading events…") }
                    .foregroundStyle(Theme.Palette.subtleText)
            } else if events.isEmpty {
                Text("No events \(selectedDay.formatted(.dateTime.weekday(.wide))).")
                    .foregroundStyle(Theme.Palette.subtleText)
            } else {
                ForEach(events) { event in
                    CalendarEventRow(event: event)
                }
            }
        }
    }

    private func loadEvents() async {
        isLoadingEvents = true
        defer { isLoadingEvents = false }

        if services.calendar.authStatus == .notDetermined {
            _ = await services.calendar.requestAccess()
        }
        calendarDenied = services.calendar.authStatus == .denied
        events = await services.calendar.events(on: selectedDay)
    }

    private func syncTodos() async {
        isSyncing = true
        defer { isSyncing = false }
        let remote = await services.todoSync.fetchTodos()
        let existingIDs = Set(todos.compactMap(\.externalID))
        for item in remote where !existingIDs.contains(item.id) {
            modelContext.insert(TodoItem(
                title: item.title,
                notes: item.notes,
                dueDate: item.dueDate,
                priority: item.priority,
                source: .todoApp,
                externalID: item.id
            ))
        }
    }

    private func delete(_ offsets: IndexSet, from list: [TodoItem]) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }
}

#Preview {
    PlanView()
        .environment(Services.preview)
        .modelContainer(SampleData.previewContainer)
}
