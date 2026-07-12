import SwiftUI

/// Manages the app's external connections: calendar (real, EventKit), to-do app
/// sync (stubbed), and pantry import (stubbed).
struct ConnectionsView: View {
    @Environment(Services.self) private var services

    @State private var calendarStatus: CalendarAuthStatus = .notDetermined
    @State private var connectedTodo: TodoProvider?
    @State private var isConnectingTodo = false

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
                Text("Your events appear on the Plan tab. Powered by Apple Calendar (EventKit).")
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
                                Label(provider.rawValue, systemImage: provider.systemImage)
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
                Text("Sync tasks into your Plan. Provider APIs are stubbed for now — connecting loads sample tasks.")
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
        .onAppear {
            calendarStatus = services.calendar.authStatus
            connectedTodo = services.todoSync.connectedProvider
        }
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
        }
    }
}

#Preview {
    NavigationStack { ConnectionsView() }
        .environment(Services.preview)
}
