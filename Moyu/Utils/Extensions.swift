import SwiftUI
import AppKit

// MARK: - Color Extension (颜色扩展)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - NSColor Extension
extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - View Extension
extension View {
    func onHoverCursor(_ cursor: NSCursor = .pointingHand) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    func moyuCard(_ colorScheme: ColorScheme) -> some View {
        self
            .background(MoyuTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous)
                    .stroke(MoyuTheme.border(colorScheme), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.07), radius: 10, y: 4)
    }
}

// MARK: - Moyu Theme
enum MoyuTheme {
    static let radius: CGFloat = 8
    static let controlRadius: CGFloat = 6
    static let primary = Color(hex: "#2563eb")
    static let accent = Color(hex: "#0f766e")
    static let danger = Color(hex: "#dc2626")
    static let warning = Color(hex: "#d97706")
    static let text = Color(hex: "#1f2937")
    static let secondaryText = Color(hex: "#64748b")

    static func appBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#111827") : Color(hex: "#eef2f6")
    }

    static func cardBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#1f2937") : Color.white
    }

    static func textColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#f8fafc") : text
    }

    static func secondaryTextColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#94a3b8") : secondaryText
    }

    static func border(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "#d9e2ec")
    }
}

// MARK: - Shared Controls
struct MoyuPrimaryButtonStyle: ButtonStyle {
    var tone: Color = MoyuTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(minHeight: 34)
            .padding(.horizontal, 14)
            .background(tone.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct MoyuSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    var tone: Color = MoyuTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(tone)
            .frame(minHeight: 32)
            .padding(.horizontal, 12)
            .background(tone.opacity(configuration.isPressed ? 0.16 : 0.09))
            .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous)
                    .stroke(colorScheme == .dark ? tone.opacity(0.24) : tone.opacity(0.14), lineWidth: 1)
            )
    }
}

struct MoyuIconButton: View {
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                Text(title)
            }
        }
        .buttonStyle(MoyuSecondaryButtonStyle())
        .onHoverCursor()
    }
}
