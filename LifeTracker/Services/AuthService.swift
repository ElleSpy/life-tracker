import Foundation
import SwiftUI

enum AuthProvider: String, Codable {
    case apple
    case google
}

/// The signed-in user. Persisted locally (UserDefaults) so the app remembers
/// the session between launches. No passwords are ever stored — SSO only.
struct UserAccount: Codable, Equatable {
    var provider: AuthProvider
    var userID: String
    var displayName: String
    var email: String?
}

/// Authentication. Per the product spec this is SSO-only (Apple + Google).
///
/// `MockAuthService` is the default so the app is runnable out of the box in the
/// simulator without provisioning. `AppleAuthService` (see `AppleSignIn.swift`)
/// wires the real `Sign in with Apple` flow once the capability is enabled.
protocol AuthService: AnyObject {
    var currentUser: UserAccount? { get }
    func signIn(with provider: AuthProvider) async throws -> UserAccount
    func signOut()
}

enum AuthError: LocalizedError {
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Sign in was cancelled."
        case .failed(let reason): return reason
        }
    }
}

/// Stores the session locally so `currentUser` survives relaunches.
enum AuthSessionStore {
    private static let key = "lifetracker.currentUser"

    static func load() -> UserAccount? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserAccount.self, from: data)
    }

    static func save(_ account: UserAccount?) {
        if let account, let data = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

/// Demo auth: "signs in" instantly with a fake account. Used until real
/// provider credentials/capabilities are configured.
final class MockAuthService: AuthService {
    private(set) var currentUser: UserAccount?

    init() {
        currentUser = AuthSessionStore.load()
    }

    func signIn(with provider: AuthProvider) async throws -> UserAccount {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let account = UserAccount(
            provider: provider,
            userID: "demo-\(provider.rawValue)",
            displayName: provider == .apple ? "Apple User" : "Google User",
            email: "you@example.com"
        )
        currentUser = account
        AuthSessionStore.save(account)
        return account
    }

    func signOut() {
        currentUser = nil
        AuthSessionStore.save(nil)
    }
}
