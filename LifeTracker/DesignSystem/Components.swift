import SwiftUI

/// A rounded card container used throughout the app.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// A small rounded tag/pill for categories, sources, tags, etc.
struct Pill: View {
    let text: String
    var systemImage: String?
    var tint: Color = Theme.Palette.accent

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs + 2)
        .foregroundStyle(tint)
        .background(tint.opacity(0.14))
        .clipShape(Capsule())
    }
}

/// A friendly empty-state placeholder with an optional call to action.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Theme.Palette.accent)
            Text(title)
                .font(.headline)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
    }
}

/// A tappable section header with an optional trailing action.
struct SectionHeaderRow: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.medium))
            }
        }
    }
}
