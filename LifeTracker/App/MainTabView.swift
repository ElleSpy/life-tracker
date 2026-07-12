import SwiftUI

/// The four primary tabs from the product spec: Plan / Food / Routine / Profile.
struct MainTabView: View {
    var body: some View {
        TabView {
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar.day.timeline.left") }

            FoodView()
                .tabItem { Label("Food", systemImage: "fork.knife") }

            RoutineListView()
                .tabItem { Label("Routine", systemImage: "repeat") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

#Preview {
    MainTabView()
        .environment(Services.preview)
        .environment(Session(auth: MockAuthService()))
        .environment(AppSettings())
        .modelContainer(SampleData.previewContainer)
}
