import SwiftUI

/// The Profile tab: account info, integration connections, and sign out.
struct ProfileView: View {
    @Environment(Session.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Theme.Spacing.lg) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Theme.Palette.accent)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(session.currentUser?.displayName ?? "Guest")
                                .font(.title3.weight(.semibold))
                            if let email = session.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Palette.subtleText)
                            }
                            if let provider = session.currentUser?.provider {
                                Pill(
                                    text: "Signed in with \(provider.rawValue.capitalized)",
                                    systemImage: provider == .apple ? "apple.logo" : "g.circle"
                                )
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }

                Section("Integrations") {
                    NavigationLink {
                        ConnectionsView()
                    } label: {
                        Label("Connections", systemImage: "app.connected.to.app.below.fill")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Label("SSO only — Apple & Google", systemImage: "lock.shield")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.subtleText)
                }

                Section {
                    Button(role: .destructive) {
                        session.signOut()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        return version
    }
}

#Preview {
    ProfileView()
        .environment(Services.preview)
        .environment(Session(auth: MockAuthService()))
}
