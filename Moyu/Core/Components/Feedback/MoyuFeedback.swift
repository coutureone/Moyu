import SwiftUI

// MARK: - Toast Message
/// Toast 消息提示
struct ToastMessage: View {
    let message: String
    let type: ToastType

    @Environment(\.colorScheme) var colorScheme

    enum ToastType {
        case success, error, warning, info

        var color: Color {
            switch self {
            case .success: return DesignTokens.Colors.success
            case .error: return DesignTokens.Colors.error
            case .warning: return DesignTokens.Colors.warning
            case .info: return DesignTokens.Colors.info
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: type.icon)
                .font(DesignTokens.Typography.body)
                .foregroundColor(type.color)

            Text(message)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            Spacer(minLength: 0)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: DesignTokens.Shadow.lg(for: colorScheme).color,
            radius: DesignTokens.Shadow.lg(for: colorScheme).radius,
            y: DesignTokens.Shadow.lg(for: colorScheme).y
        )
    }
}

// MARK: - Loading Indicator
/// 加载指示器
struct LoadingView: View {
    let message: String?

    @Environment(\.colorScheme) var colorScheme

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.surface(for: colorScheme))
        )
        .shadow(
            color: DesignTokens.Shadow.xl(for: colorScheme).color,
            radius: DesignTokens.Shadow.xl(for: colorScheme).radius,
            y: DesignTokens.Shadow.xl(for: colorScheme).y
        )
    }
}

// MARK: - Empty State
/// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 图标
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(DesignTokens.Colors.primary)
            }

            // 文本
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.Typography.h3)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            // 操作按钮
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Progress Indicator
/// 进度指示器（圆点）
struct ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            ForEach(0..<min(total, 5), id: \.self) { index in
                Circle()
                    .fill(index < current ? DesignTokens.Colors.primary : DesignTokens.Colors.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == current - 1 ? 1.2 : 1.0)
                    .animation(DesignTokens.Animation.spring, value: current)
            }
        }
    }
}

// MARK: - Badge
/// 徽章
struct Badge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = DesignTokens.Colors.primary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.captionBold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Divider
/// 分割线
struct MoyuDivider: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Rectangle()
            .fill(DesignTokens.Colors.border(for: colorScheme))
            .frame(height: 1)
    }
}

// MARK: - Previews
#Preview("Feedback") {
    VStack(spacing: 20) {
        ToastMessage(message: "保存成功", type: .success)

        ToastMessage(message: "发生错误", type: .error)

        LoadingView(message: "加载中...")

        EmptyStateView(
            icon: "book.closed",
            title: "暂无错词",
            message: "学习过程中遇到的难词会出现在这里",
            actionTitle: "开始学习",
            action: {}
        )

        ProgressDots(current: 3, total: 5)

        HStack {
            Badge("新")
            Badge("已完成", color: DesignTokens.Colors.success)
            Badge("重要", color: DesignTokens.Colors.error)
        }

        MoyuDivider()
    }
    .padding(20)
}
