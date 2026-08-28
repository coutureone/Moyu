import SwiftUI

// MARK: - Design Tokens
/// Moyu v3.0 设计系统 - 核心设计 Token
/// 定义了应用的基础设计语言：颜色、排版、间距、圆角、阴影

struct DesignTokens {

    // MARK: - Color System

    /// 主色调 - 清爽的青色，体现"摸鱼"的轻松感
    struct Colors {
        // Primary - 主色
        static let primary = Color(hex: "#06B6D4")      // Cyan 500
        static let primaryDark = Color(hex: "#0891B2")  // Cyan 600
        static let primaryLight = Color(hex: "#22D3EE") // Cyan 400
        static let primaryLighter = Color(hex: "#67E8F9") // Cyan 300

        // Accent - 强调色
        static let accent = Color(hex: "#F59E0B")       // Amber 500
        static let accentDark = Color(hex: "#D97706")   // Amber 600
        static let accentLight = Color(hex: "#FCD34D")  // Amber 300

        // Semantic - 语义色
        static let success = Color(hex: "#10B981")      // Green 500
        static let successLight = Color(hex: "#34D399") // Green 400
        static let warning = Color(hex: "#F59E0B")      // Amber 500
        static let warningLight = Color(hex: "#FBBF24") // Amber 400
        static let error = Color(hex: "#EF4444")        // Red 500
        static let errorLight = Color(hex: "#F87171")   // Red 400
        static let info = Color(hex: "#3B82F6")         // Blue 500
        static let infoLight = Color(hex: "#60A5FA")    // Blue 400

        // Neutral - 中性色（浅色模式）
        struct Light {
            static let background = Color(hex: "#F8FAFC")    // Slate 50
            static let surface = Color.white                 // White
            static let surfaceHover = Color(hex: "#F1F5F9")  // Slate 100
            static let surfacePressed = Color(hex: "#E2E8F0") // Slate 200
            static let overlay = Color.black.opacity(0.5)    // 遮罩层

            static let text = Color(hex: "#0F172A")          // Slate 900
            static let textSecondary = Color(hex: "#475569") // Slate 600
            static let textTertiary = Color(hex: "#94A3B8")  // Slate 400
            static let textDisabled = Color(hex: "#CBD5E1")  // Slate 300

            static let border = Color(hex: "#E2E8F0")        // Slate 200
            static let borderHover = Color(hex: "#CBD5E1")   // Slate 300
            static let divider = Color(hex: "#F1F5F9")       // Slate 100
        }

        // Neutral - 中性色（深色模式）
        struct Dark {
            static let background = Color(hex: "#0F172A")    // Slate 900
            static let surface = Color(hex: "#1E293B")       // Slate 800
            static let surfaceHover = Color(hex: "#334155")  // Slate 700
            static let surfacePressed = Color(hex: "#475569") // Slate 600
            static let overlay = Color.black.opacity(0.7)    // 遮罩层

            static let text = Color(hex: "#F8FAFC")          // Slate 50
            static let textSecondary = Color(hex: "#CBD5E1") // Slate 300
            static let textTertiary = Color(hex: "#64748B")  // Slate 500
            static let textDisabled = Color(hex: "#475569")  // Slate 600

            static let border = Color(hex: "#334155")        // Slate 700
            static let borderHover = Color(hex: "#475569")   // Slate 600
            static let divider = Color(hex: "#1E293B")       // Slate 800
        }

        // Helpers - 便捷访问
        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.background : Light.background
        }

        static func surface(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.surface : Light.surface
        }

        static func text(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.text : Light.text
        }

        static func textSecondary(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.textSecondary : Light.textSecondary
        }

        static func border(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Dark.border : Light.border
        }
    }

    // MARK: - Typography System

    /// 排版系统 - 统一的字体大小和权重
    struct Typography {
        // Display - 大标题（用于欢迎页、空状态等）
        static let displayLarge = Font.system(size: 48, weight: .bold)
        static let display = Font.system(size: 36, weight: .bold)
        static let displaySmall = Font.system(size: 32, weight: .bold)

        // Heading - 标题
        static let h1 = Font.system(size: 28, weight: .bold)
        static let h2 = Font.system(size: 24, weight: .semibold)
        static let h3 = Font.system(size: 20, weight: .semibold)
        static let h4 = Font.system(size: 18, weight: .medium)
        static let h5 = Font.system(size: 16, weight: .medium)

        // Body - 正文
        static let bodyLarge = Font.system(size: 16, weight: .regular)
        static let body = Font.system(size: 14, weight: .regular)
        static let bodySmall = Font.system(size: 12, weight: .regular)

        // Label - 标签（用于按钮、输入框等）
        static let labelLarge = Font.system(size: 16, weight: .semibold)
        static let label = Font.system(size: 14, weight: .semibold)
        static let labelSmall = Font.system(size: 12, weight: .semibold)

        // Caption - 辅助文本（用于提示、说明等）
        static let caption = Font.system(size: 11, weight: .regular)
        static let captionBold = Font.system(size: 11, weight: .semibold)
        static let overline = Font.system(size: 10, weight: .medium)
    }

    // MARK: - Spacing System

    /// 间距系统 - 基于 8px 的间距单位
    struct Spacing {
        static let xxs: CGFloat = 4     // 0.5x
        static let xs: CGFloat = 8      // 1x
        static let sm: CGFloat = 12     // 1.5x
        static let md: CGFloat = 16     // 2x
        static let lg: CGFloat = 24     // 3x
        static let xl: CGFloat = 32     // 4x
        static let xxl: CGFloat = 48    // 6x
        static let xxxl: CGFloat = 64   // 8x
    }

    // MARK: - Border Radius

    /// 圆角系统
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let full: CGFloat = 9999  // 完全圆角
    }

    // MARK: - Shadow System

    /// 阴影系统
    struct Shadow {
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static func sm(for colorScheme: ColorScheme) -> ShadowStyle {
            ShadowStyle(
                color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                radius: 2,
                x: 0,
                y: 1
            )
        }

        static func md(for colorScheme: ColorScheme) -> ShadowStyle {
            ShadowStyle(
                color: colorScheme == .dark ? .clear : .black.opacity(0.08),
                radius: 4,
                x: 0,
                y: 2
            )
        }

        static func lg(for colorScheme: ColorScheme) -> ShadowStyle {
            ShadowStyle(
                color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
        }

        static func xl(for colorScheme: ColorScheme) -> ShadowStyle {
            ShadowStyle(
                color: colorScheme == .dark ? .clear : .black.opacity(0.12),
                radius: 16,
                x: 0,
                y: 8
            )
        }
    }

    // MARK: - Animation

    /// 动画系统
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)

        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }

    // MARK: - Layout

    /// 布局系统
    struct Layout {
        // 最大宽度
        static let maxWidthSmall: CGFloat = 480
        static let maxWidthMedium: CGFloat = 640
        static let maxWidthLarge: CGFloat = 768

        // 容器内边距
        static let containerPadding = Spacing.md
        static let containerPaddingLarge = Spacing.lg

        // 卡片尺寸
        static let cardMinHeight: CGFloat = 80
        static let cardMaxHeight: CGFloat = 600

        // 按钮尺寸
        static let buttonHeightSmall: CGFloat = 32
        static let buttonHeightMedium: CGFloat = 44
        static let buttonHeightLarge: CGFloat = 52

        // 输入框尺寸
        static let inputHeight: CGFloat = 40
        static let inputHeightLarge: CGFloat = 48
    }
}

// MARK: - Color Extension (保持兼容性)
extension Color {
    init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
