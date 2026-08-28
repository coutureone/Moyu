import SwiftUI

// MARK: - Primary Button
/// 主要按钮 - 用于主要操作（开始学习、提交等）
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(DesignTokens.Animation.spring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignTokens.Animation.spring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignTokens.Typography.label)
                }
                Text(title)
                    .font(DesignTokens.Typography.label)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.buttonHeightMedium)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.primary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(Color.black.opacity(isPressed ? 0.1 : 0))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: DesignTokens.Colors.primary.opacity(0.3),
                radius: isPressed ? 4 : 8,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Button
/// 次要按钮 - 用于次要操作（取消、返回等）
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    @State private var isPressed = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignTokens.Typography.label)
                }
                Text(title)
                    .font(DesignTokens.Typography.label)
            }
            .foregroundColor(DesignTokens.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.buttonHeightMedium)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(isHovered ? DesignTokens.Colors.primaryLight.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(DesignTokens.Colors.primary, lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Text Button
/// 文本按钮 - 用于不太重要的操作
struct TextButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isHovered = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignTokens.Typography.labelSmall)
                }
                Text(title)
                    .font(DesignTokens.Typography.labelSmall)
            }
            .foregroundColor(DesignTokens.Colors.primary)
            .opacity(isHovered ? 0.8 : 1.0)
            .underline(isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Icon Button
/// 图标按钮 - 用于单个图标操作
struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    init(icon: String, size: CGFloat = 24, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.6))
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isHovered ? DesignTokens.Colors.surface(for: colorScheme) : Color.clear)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Quick Select Button
/// 快速选择按钮 - 用于数字快速选择（10, 20, 30 等）
struct QuickSelectButton: View {
    let value: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(value)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(isSelected ? .white : DesignTokens.Colors.text(for: colorScheme))
                .frame(minWidth: 48, minHeight: 32)
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(isSelected ? DesignTokens.Colors.primary : (isHovered ? DesignTokens.Colors.surface(for: colorScheme) : Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .strokeBorder(
                            isSelected ? Color.clear : DesignTokens.Colors.border(for: colorScheme),
                            lineWidth: 1
                        )
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Previews
#Preview("Buttons") {
    VStack(spacing: 20) {
        PrimaryButton("开始学习", icon: "play.fill") {}

        SecondaryButton("取消", icon: "xmark") {}

        TextButton("查看详情", icon: "arrow.right") {}

        HStack {
            QuickSelectButton(value: "10", isSelected: false) {}
            QuickSelectButton(value: "20", isSelected: true)
            QuickSelectButton(value: "30", isSelected: false) {}
        }

        HStack {
            IconButton(icon: "heart") {}
            IconButton(icon: "star") {}
            IconButton(icon: "xmark") {}
        }
    }
    .padding(20)
}
