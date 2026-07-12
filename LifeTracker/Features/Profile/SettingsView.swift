import SwiftUI

/// App preferences, reached from the Profile tab.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        return List {
            Section {
                Picker("Week starts on", selection: $settings.weekStart) {
                    ForEach(WeekStart.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
            } header: {
                Text("Calendar")
            } footer: {
                Text("Controls the first day of the week in the planner and meal plan. \"Match phone\" follows your device's region settings.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(AppSettings())
}
