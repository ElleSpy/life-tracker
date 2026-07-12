import SwiftUI
import SwiftData

/// Decides whether to show the login screen or the main app, based on session.
struct RootView: View {
    @Environment(Session.self) private var session
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if session.isSignedIn {
                MainTabView()
                    .task { SampleData.seedIfNeeded(in: modelContext) }
            } else {
                LoginView()
            }
        }
        .animation(.default, value: session.isSignedIn)
    }
}

#Preview {
    RootView()
        .environment(Services.preview)
        .environment(Session(auth: MockAuthService()))
        .environment(AppSettings())
        .modelContainer(SampleData.previewContainer)
}
