import Foundation
import UIKit
import AuthenticationServices

/// Real `Sign in with Apple`. This compiles without any special setup, but to
/// actually authenticate you must enable the **Sign in with Apple** capability
/// on the target in Xcode (Signing & Capabilities), which requires a
/// development team. Until then the app uses `MockAuthService` — swap the
/// factory in `AppEnvironment` to use this instead.
final class AppleAuthService: NSObject, AuthService {
    private(set) var currentUser: UserAccount?
    private var continuation: CheckedContinuation<UserAccount, Error>?

    override init() {
        super.init()
        currentUser = AuthSessionStore.load()
    }

    func signIn(with provider: AuthProvider) async throws -> UserAccount {
        guard provider == .apple else {
            // Google SSO requires GoogleSignIn SDK + a client ID; not wired yet.
            throw AuthError.failed("Google sign-in isn't configured yet.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func signOut() {
        currentUser = nil
        AuthSessionStore.save(nil)
    }
}

extension AppleAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.failed("Unexpected credential type."))
            continuation = nil
            return
        }
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let account = UserAccount(
            provider: .apple,
            userID: credential.user,
            displayName: name.isEmpty ? "Apple User" : name,
            email: credential.email
        )
        currentUser = account
        AuthSessionStore.save(account)
        continuation?.resume(returning: account)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            continuation?.resume(throwing: AuthError.cancelled)
        } else {
            continuation?.resume(throwing: AuthError.failed(error.localizedDescription))
        }
        continuation = nil
    }
}

extension AppleAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        return windowScene?.keyWindow ?? ASPresentationAnchor()
    }
}
