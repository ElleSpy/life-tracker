import SwiftUI

/// Central design tokens so spacing, colour and corner radius stay consistent.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 16
        static let pill: CGFloat = 999
    }

    enum Palette {
        static let accent = Color("AccentColor")
        static let cardBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let subtleText = Color(.secondaryLabel)
    }
}

extension Color {
    /// Build a colour from a "#RRGGBB" string, falling back to the accent colour.
    init(hex: String?) {
        guard
            let hex,
            let value = Int(hex.replacingOccurrences(of: "#", with: ""), radix: 16)
        else {
            self = Theme.Palette.accent
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
