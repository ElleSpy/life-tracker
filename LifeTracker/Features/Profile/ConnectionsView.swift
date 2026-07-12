import SwiftUI

/// Manages the app's external connections: calendar, to-do apps, reminders and
/// pantry import.
struct ConnectionsView: View {
    @Environment(Services.self) private var services
    @Environment(AppSettings.self) private var settings

    @State private var calendarStatus: CalendarAuthStatus = .notDetermined
    @State private var calendars: [CalendarInfo] = []
    @State private var connectedTodo: TodoProvider?
    @State private var isConnectingTodo = false
    @State private var connectError: String?
    @State private var notificationsOn = false

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Calendar", systemImage: "calendar")
                    Spacer()
                    calendarStatusView
                }
                if calendarStatus == .notDetermined {
                    Button("Connect calendar") {
                        Task {
                            _ = await services.calendar.requestAccess()
                            calendarStatus = services.calendar.authStatus
                            calendars = services.calendar.availableCalendars()
                        }
                    }
                } else if calendarStatus == .denied {
                    Text("Enable calendar access in Settings › LifeTracker.")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            } header: {
                Text("Calendar")
            } footer: {
                Text("Your events appear on the Plan tab.")
            }

            if calendarStatus == .authorized && !calendars.isEmpty {
                Section {
                    ForEach(calendars) { cal in
                        Toggle(isOn: Binding(
                            get: { isShown(cal) },
                            set: { setShown(cal, $0) }
                        )) {
                            Label {
                                Text(cal.title)
                            } icon: {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(Color(hex: cal.colorHex))
                            }
                        }
                    }
                } header: {
                    Text("Calendars to show")
                } footer: {
                    Text("Only the calendars you switch on appear on the Plan tab.")
                }
            }

            Section {
                if let connectedTodo {
                    HStack {
                        Label(connectedTodo.rawValue, systemImage: connectedTodo.systemImage)
                        Spacer()
                        Text("Connected").foregroundStyle(.green)
                    }
                    Button("Disconnect", role: .destructive) {
                        services.todoSync.disconnect()
                        self.connectedTodo = nil
                    }
                } else {
                    Menu {
                        ForEach(TodoProvider.allCases) { provider in
                            Button {
                                Task { await connectTodo(provider) }
                            } label: {
                                Label(provider.isLive ? provider.rawValue : "\(provider.rawValue) (soon)",
                                      systemImage: provider.systemImage)
                            }
                        }
                    } label: {
                        HStack {
                            Label("Connect a to-do app", systemImage: "checklist")
                            Spacer()
                            if isConnectingTodo { ProgressView() }
                        }
                    }
                    .disabled(isConnectingTodo)
                }
            } header: {
                Text("To-do apps")
            } footer: {
                Text("Connect an app, then use the Sync button on the Plan tab to pull tasks in. Apple Reminders works out of the box; TickTick needs a one-time setup (see TICKTICK_SETUP.md). Others are coming soon.")
            }

            Section {
                Toggle("Task reminders", isOn: Binding(
                    get: { notificationsOn },
                    set: { wantOn in
                        if wantOn {
                            Task {
                                notificationsOn = await services.notifications.requestAuthorization()
                            }
                        } else {
                            notificationsOn = false
                        }
                    }
                ))
            } header: {
                Text("Reminders")
            } footer: {
                Text("Get a local notification when a to-do with a due date and time comes up.")
            }

            Section {
                Label("Import from email", systemImage: "envelope")
                Label("Import from photo", systemImage: "camera")
            } header: {
                Text("Pantry import")
            } footer: {
                Text("Add groceries to your pantry from a receipt. Available from the Food › Have tab. Parsing is stubbed for now.")
            }
        }
        .navigationTitle("Connections")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't connect", isPresented: Binding(
            get: { connectError != nil },
            set: { if !$0 { connectError = nil } }
        )) {
            Button("OK", role: .cancel) { connectError = nil }
        } message: {
            Text(connectError ?? "")
        }
        .task {
            calendarStatus = services.calendar.authStatus
            calendars = services.calendar.availableCalendars()
            connectedTodo = services.todoSync.connectedProvider
            await services.notifications.refreshAuthorization()
            notificationsOn = services.notifications.isAuthorized
        }
    }

    /// A calendar is shown when it's explicitly selected, or when nothing is
    /// selected yet (empty selection means "all").
    private func isShown(_ cal: CalendarInfo) -> Bool {
        settings.selectedCalendarIDs.isEmpty || settings.selectedCalendarIDs.contains(cal.id)
    }

    private func setShown(_ cal: CalendarInfo, _ shown: Bool) {
        var ids = settings.selectedCalendarIDs
        // Materialise "all" into an explicit set the first time the user picks.
        if ids.isEmpty { ids = Set(calendars.map(\.id)) }
        if shown { ids.insert(cal.id) } else { ids.remove(cal.id) }
        settings.selectedCalendarIDs = ids
    }

    @ViewBuilder
    private var calendarStatusView: some View {
        switch calendarStatus {
        case .authorized: Text("Connected").foregroundStyle(.green)
        case .denied: Text("Off").foregroundStyle(.red)
        case .notDetermined: Text("Not connected").foregroundStyle(Theme.Palette.subtleText)
        }
    }

    private func connectTodo(_ provider: TodoProvider) async {
        isConnectingTodo = true
        defer { isConnectingTodo = false }
        if await services.todoSync.connect(provider) {
            connectedTodo = provider
        } else if provider == .ticktick && !services.todoSync.isConfigured(.ticktick) {
            connectError = "TickTick isn't set up yet. Add your API keys in Secrets.plist — see TICKTICK_SETUP.md — then try again."
        } else if provider == .reminders {
            connectError = "Couldn't access Reminders. You can enable it in Settings › LifeTracker."
        } else {
            connectError = "Couldn't connect to \(provider.rawValue). Please try again."
        }
    }
}

#Preview {
    NavigationStack { ConnectionsView() }
        .environment(Services.preview)
        .environment(AppSettings())
}
