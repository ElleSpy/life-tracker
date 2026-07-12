import SwiftUI

/// SSO-only sign-in (Apple + Google), per the product spec.
struct LoginView: View {
    @Environment(Session.self) private var session

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.Palette.accent)
                Text("LifeTracker")
                    .font(.largeTitle.bold())
                Text("Your plans, food and routines — all in one place.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                signInButton(
                    provider: .apple,
                    title: "Continue with Apple",
                    systemImage: "apple.logo",
                    foreground: .white,
                    background: .black
                )
                signInButton(
                    provider: .google,
                    title: "Continue with Google",
                    systemImage: "g.circle.fill",
                    foreground: .primary,
                    background: Color(.secondarySystemBackground)
                )

                if let error = session.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Text("We only support Apple and Google sign-in. No passwords.")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .overlay {
            if session.isSigningIn {
                ProgressView().controlSize(.large)
            }
        }
    }

    private func signInButton(
        provider: AuthProvider,
        title: String,
        systemImage: String,
        foreground: Color,
        background: Color
    ) -> some View {
        Button {
            Task { await session.signIn(with: provider) }
        } label: {
            HStack {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .disabled(session.isSigningIn)
    }
}

#Preview {
    LoginView()
        .environment(Session(auth: MockAuthService()))
}
