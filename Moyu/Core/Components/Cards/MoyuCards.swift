import SwiftUI

// MARK: - Card Container
/// 基础卡片容器
struct Card<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .strokeBorder(
                        colorScheme == .dark ? DesignTokens.Colors.border(for: colorScheme) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: DesignTokens.Shadow.md(for: colorScheme).color,
                radius: DesignTokens.Shadow.md(for: colorScheme).radius,
                x: DesignTokens.Shadow.md(for: colorScheme).x,
                y: DesignTokens.Shadow.md(for: colorScheme).y
            )
    }
}

// MARK: - Stat Card
/// 统计数据卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            // 数值
            Text(value)
                .font(DesignTokens.Typography.h2)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            // 标题
            Text(title)
                .font(DesignTokens.Typography.bodySmall)
                .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(
                    colorScheme == .dark ? DesignTokens.Colors.border(for: colorScheme) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(
            color: DesignTokens.Shadow.sm(for: colorScheme).color,
            radius: DesignTokens.Shadow.sm(for: colorScheme).radius,
            x: DesignTokens.Shadow.sm(for: colorScheme).x,
            y: DesignTokens.Shadow.sm(for: colorScheme).y
        )
    }
}

// MARK: - Progress Card
/// 进度卡片
struct ProgressCard: View {
    let title: String
    let current: Int
    let total: Int
    let icon: String

    @Environment(\.colorScheme) var colorScheme

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 标题和百分比
            HStack {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: icon)
                        .font(DesignTokens.Typography.body)
                    Text(title)
                        .font(DesignTokens.Typography.h4)
                }
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                Spacer()

                Text("\(percentage)%")
                    .font(DesignTokens.Typography.h3)
                    .foregroundColor(DesignTokens.Colors.primary)
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.full)
                        .fill(DesignTokens.Colors.border(for: colorScheme))
                        .frame(height: 8)

                    // 进度
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.full)
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // 详情文本
            Text("\(current)/\(total) 词")
                .font(DesignTokens.Typography.bodySmall)
                .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

            if current < total {
                Text("再学 \(total - current) 词完成目标")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textTertiary(for: colorScheme))
            } else {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                    Text("今日目标已完成！")
                        .foregroundColor(DesignTokens.Colors.success)
                }
                .font(DesignTokens.Typography.caption)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(
                    colorScheme == .dark ? DesignTokens.Colors.border(for: colorScheme) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(
            color: DesignTokens.Shadow.md(for: colorScheme).color,
            radius: DesignTokens.Shadow.md(for: colorScheme).radius,
            x: DesignTokens.Shadow.md(for: colorScheme).x,
            y: DesignTokens.Shadow.md(for: colorScheme).y
        )
    }
}

// MARK: - Action Card
/// 快捷操作卡片
struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let count: Int?
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        count: Int? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.count = count
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // 图标和数量
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(DesignTokens.Colors.primary)

                    Spacer()

                    if let count = count {
                        Text("\(count)")
                            .font(DesignTokens.Typography.h3)
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                    }
                }

                // 标题
                HStack {
                    Text(title)
                        .font(DesignTokens.Typography.h4)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary(for: colorScheme))
                        .opacity(isHovered ? 1 : 0.6)
                        .offset(x: isHovered ? 2 : 0)
                }

                // 副标题
                if let subtitle = subtitle {
                    HStack {
                        Text(subtitle)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                        Spacer()
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .strokeBorder(
                        isHovered ? DesignTokens.Colors.primary.opacity(0.3) :
                            (colorScheme == .dark ? DesignTokens.Colors.border(for: colorScheme) : Color.clear),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isHovered ? DesignTokens.Colors.primary.opacity(0.15) : DesignTokens.Shadow.sm(for: colorScheme).color,
                radius: isHovered ? 8 : DesignTokens.Shadow.sm(for: colorScheme).radius,
                y: isHovered ? 4 : DesignTokens.Shadow.sm(for: colorScheme).y
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
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
#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            // 基础卡片
            Card {
                Text("基础卡片内容")
                    .font(DesignTokens.Typography.body)
            }

            // 统计卡片
            HStack(spacing: 12) {
                StatCard(
                    title: "学习",
                    value: "20",
                    icon: "book.fill",
                    color: DesignTokens.Colors.primary
                )

                StatCard(
                    title: "正确",
                    value: "16",
                    icon: "checkmark.circle.fill",
                    color: DesignTokens.Colors.success
                )
            }

            // 进度卡片
            ProgressCard(
                title: "今日进度",
                current: 12,
                total: 20,
                icon: "chart.bar.fill"
            )

            // 操作卡片
            HStack(spacing: 12) {
                ActionCard(
                    icon: "book.closed.fill",
                    title: "错词本",
                    subtitle: "复习巩固",
                    count: 15
                ) {}

                ActionCard(
                    icon: "star.fill",
                    title: "收藏夹",
                    subtitle: "重点单词",
                    count: 8
                ) {}
            }
        }
        .padding(20)
    }
}
