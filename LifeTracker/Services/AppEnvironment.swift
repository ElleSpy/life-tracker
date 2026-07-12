import Foundation
import Observation

/// Holds the app's service instances in one place so they can be injected into
/// the SwiftUI environment and swapped for mocks in previews.
///
/// To go live with real integrations, change the factory values here:
///   - `calendar`: already real (EventKit).
///   - `auth`: swap `MockAuthService()` for `AppleAuthService()`.
///   - `todoSync` / `pantryImport`: swap the mocks for real API clients.
@Observable
final class Services {
    let calendar: CalendarService
    let todoSync: TodoSyncService
    let pantryImport: PantryImportService
    let auth: AuthService

    init(
        calendar: CalendarService = EventKitCalendarService(),
        todoSync: TodoSyncService = MockTodoSyncService(),
        pantryImport: PantryImportService = MockPantryImportService(),
        auth: AuthService = MockAuthService()
    ) {
        self.calendar = calendar
        self.todoSync = todoSync
        self.pantryImport = pantryImport
        self.auth = auth
    }

    /// All-mock services for SwiftUI previews.
    static var preview: Services {
        Services(
            calendar: MockCalendarService(),
            todoSync: MockTodoSyncService(),
            pantryImport: MockPantryImportService(),
            auth: MockAuthService()
        )
    }
}

/// Observable wrapper around the auth session so login/logout re-renders the UI.
@Observable
final class Session {
    private let auth: AuthService
    var currentUser: UserAccount?
    var isSigningIn = false
    var errorMessage: String?

    init(auth: AuthService) {
        self.auth = auth
        self.currentUser = auth.currentUser
    }

    var isSignedIn: Bool { currentUser != nil }

    func signIn(with provider: AuthProvider) async {
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }
        do {
            currentUser = try await auth.signIn(with: provider)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        auth.signOut()
        currentUser = nil
    }
}
