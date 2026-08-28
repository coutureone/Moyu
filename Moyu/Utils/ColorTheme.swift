import SwiftUI

// MARK: - Color Theme Manager
struct ColorTheme {
    // Primary Colors
    static let primary = Color(hex: "#0077b6")
    static let primaryLight = Color(hex: "#00b4d8")
    static let primaryDark = Color(hex: "#023e8a")

    // Accent Colors
    static let accent = Color(hex: "#e76f51")
    static let accentLight = Color(hex: "#f4a261")
    static let success = Color.green
    static let warning = Color(hex: "#f4a261")
    static let error = Color(hex: "#e76f51")

    // Text Colors
    static let textPrimary = Color(hex: "#3d5a80")
    static let textSecondary = Color(hex: "#778da9")
    static let textTertiary = Color(hex: "#8d99ae")

    // Background Colors
    static let backgroundLight = Color(hex: "#d7e1ec")
    static let backgroundDark = Color(hex: "#1a1a2e")
    static let cardLight = Color.white
    static let cardDark = Color(hex: "#16213e")

    // Progress Colors
    static let progressGradientStart = Color(hex: "#0077b6")
    static let progressGradientEnd = Color(hex: "#00b4d8")
    static let progressComplete = Color.green

    // Border & Divider
    static let border = Color(hex: "#d0d7e2")
    static let divider = Color(hex: "#e0e7ee")

    // Helper Methods
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardDark : cardLight
    }

    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : textPrimary
    }
}
