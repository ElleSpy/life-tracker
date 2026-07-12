import Foundation
import UIKit
import AuthenticationServices

enum TodoSyncError: LocalizedError {
    case notConfigured
    case authFailed
    case network

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "TickTick isn't set up yet. Add your API keys in Secrets.plist (see TICKTICK_SETUP.md), then try again."
        case .authFailed:
            return "TickTick sign-in didn't complete. Please try again."
        case .network:
            return "Couldn't reach TickTick. Check your connection and try again."
        }
    }
}

/// TickTick API credentials, loaded from a git-ignored `Secrets.plist` in the
/// app bundle so secrets never land in source control.
struct TickTickConfig {
    let clientID: String
    let clientSecret: String
    let redirectURI: String

    /// The custom URL scheme portion of the redirect URI (e.g. "lifetracker").
    var callbackScheme: String? { URL(string: redirectURI)?.scheme }

    var isConfigured: Bool {
        !clientID.isEmpty && !clientSecret.isEmpty && !clientID.hasPrefix("YOUR_")
    }

    static func load() -> TickTickConfig {
        let fallbackRedirect = "lifetracker://ticktick-auth"
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            return TickTickConfig(clientID: "", clientSecret: "", redirectURI: fallbackRedirect)
        }
        return TickTickConfig(
            clientID: dict["TickTickClientID"] as? String ?? "",
            clientSecret: dict["TickTickClientSecret"] as? String ?? "",
            redirectURI: dict["TickTickRedirectURI"] as? String ?? fallbackRedirect
        )
    }
}

/// Real TickTick integration: OAuth2 sign-in via `ASWebAuthenticationSession`
/// and task fetching via the Open API. Requires credentials in Secrets.plist.
final class TickTickClient: NSObject {
    private let config = TickTickConfig.load()
    private let tokenKey = "ticktick.accessToken"

    private let authorizeURL = "https://ticktick.com/oauth/authorize"
    private let tokenURL = "https://ticktick.com/oauth/token"
    private let apiBase = "https://api.ticktick.com"
    private let scope = "tasks:read tasks:write"

    var isConfigured: Bool { config.isConfigured }
    var isAuthorized: Bool { Keychain.get(tokenKey) != nil }

    func signOut() { Keychain.delete(tokenKey) }

    /// Run the OAuth flow and store the resulting access token.
    @MainActor
    func authorize() async throws {
        guard config.isConfigured, let scheme = config.callbackScheme else {
            throw TodoSyncError.notConfigured
        }
        let code = try await requestAuthCode(scheme: scheme)
        let token = try await exchange(code: code)
        Keychain.set(token, for: tokenKey)
    }

    @MainActor
    private func requestAuthCode(scheme: String) async throws -> String {
        var components = URLComponents(string: authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "response_type", value: "code")
        ]
        guard let authURL = components.url else { throw TodoSyncError.authFailed }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL, callbackURLScheme: scheme
            ) { callback, error in
                if error != nil {
                    continuation.resume(throwing: TodoSyncError.authFailed)
                    return
                }
                guard
                    let callback,
                    let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: TodoSyncError.authFailed)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() {
                continuation.resume(throwing: TodoSyncError.authFailed)
            }
        }
    }

    private func exchange(code: String) async throws -> String {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        let credentials = Data("\(config.clientID):\(config.clientSecret)".utf8).base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI)
        ]
        request.httpBody = body.query?.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(TokenResponse.self, from: data).access_token
        } catch is DecodingError {
            throw TodoSyncError.authFailed
        } catch {
            throw TodoSyncError.network
        }
    }

    /// Fetch open tasks across all projects.
    func fetchTasks() async -> [RemoteTodo] {
        guard let token = Keychain.get(tokenKey) else { return [] }
        let projects = (try? await get("/open/v1/project", token: token, as: [TickTickProject].self)) ?? []
        var todos: [RemoteTodo] = []
        for project in projects {
            if let data = try? await get("/open/v1/project/\(project.id)/data",
                                         token: token, as: TickTickProjectData.self) {
                todos.append(contentsOf: (data.tasks ?? []).map(\.asRemoteTodo))
            }
        }
        return todos
    }

    private func get<T: Decodable>(_ path: String, token: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: apiBase + path) else { throw TodoSyncError.network }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

extension TickTickClient: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let windowScene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        return windowScene?.keyWindow ?? ASPresentationAnchor()
    }
}

// MARK: - API models

private struct TokenResponse: Decodable {
    let access_token: String
}

private struct TickTickProject: Decodable {
    let id: String
    let name: String?
}

private struct TickTickProjectData: Decodable {
    let tasks: [TickTickTask]?
}

private struct TickTickTask: Decodable {
    let id: String
    let title: String?
    let content: String?
    let dueDate: String?
    let priority: Int?

    var asRemoteTodo: RemoteTodo {
        RemoteTodo(
            id: id,
            title: title ?? "Task",
            notes: content ?? "",
            dueDate: Self.parseDate(dueDate),
            priority: Self.mapPriority(priority ?? 0)
        )
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    /// TickTick priorities: 0 none, 1 low, 3 medium, 5 high.
    private static func mapPriority(_ value: Int) -> Priority {
        switch value {
        case 5: return .high
        case 3: return .medium
        default: return .low
        }
    }
}
