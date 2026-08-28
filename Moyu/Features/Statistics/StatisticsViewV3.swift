import SwiftUI
import Charts

// MARK: - Statistics View v3.0
/// 统计页面 - 全新设计
struct StatisticsViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @State private var recentRecords: [DailyRecord] = []
    @State private var achievements: [Achievement] = []

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            MoyuDivider()

            // 内容区域
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // 今日统计
                    todayStatsSection

                    // 7天趋势
                    weeklyTrendSection

                    // 总体统计
                    overallStatsSection

                    // 成就墙
                    achievementsSection

                    Spacer(minLength: DesignTokens.Spacing.xl)
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
        .background(DesignTokens.Colors.background(for: colorScheme))
        .onAppear {
            loadData()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            IconButton(icon: "chevron.left", size: 32) {
                appState.currentPage = .home
            }

            Spacer()

            Text("统计")
                .font(DesignTokens.Typography.h3)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            Spacer()

            // 导出按钮
            IconButton(icon: "square.and.arrow.up", size: 32) {
                // TODO: 导出报告
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface(for: colorScheme))
    }

    // MARK: - Today Stats Section

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("今日学习")
                .font(DesignTokens.Typography.h4)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            // 统计卡片网格
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: DesignTokens.Spacing.sm
            ) {
                StatCard(
                    title: "学习",
                    value: "\(appState.statistics.todayLearned)",
                    icon: "book.fill",
                    color: DesignTokens.Colors.primary
                )

                StatCard(
                    title: "正确",
                    value: "\(appState.statistics.todayCorrect)",
                    icon: "checkmark.circle.fill",
                    color: DesignTokens.Colors.success
                )

                StatCard(
                    title: "错误",
                    value: "\(appState.statistics.todayWrong)",
                    icon: "xmark.circle.fill",
                    color: DesignTokens.Colors.error
                )

                StatCard(
                    title: "正确率",
                    value: "\(Int(appState.statistics.todayAccuracy))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: accuracyColor
                )
            }
        }
    }

    private var accuracyColor: Color {
        let accuracy = appState.statistics.todayAccuracy
        if accuracy >= 90 { return DesignTokens.Colors.success }
        if accuracy >= 70 { return DesignTokens.Colors.primary }
        return DesignTokens.Colors.error
    }

    // MARK: - Weekly Trend Section

    private var weeklyTrendSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("7天学习趋势")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                if !recentRecords.isEmpty {
                    Chart(recentRecords) { record in
                        BarMark(
                            x: .value("日期", weekdayLabel(for: record.date)),
                            y: .value("学习数", record.learnedCount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.primary,
                                    DesignTokens.Colors.primaryLight
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(DesignTokens.Radius.xs)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisValueLabel()
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.textSecondary(for: colorScheme))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.textSecondary(for: colorScheme))
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "暂无数据",
                        message: "开始学习后这里会显示趋势图"
                    )
                    .frame(height: 180)
                }
            }
        }
    }

    // MARK: - Overall Stats Section

    private var overallStatsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("累计数据")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                VStack(spacing: DesignTokens.Spacing.sm) {
                    OverallStatRow(
                        icon: "books.vertical.fill",
                        title: "累计学习",
                        value: "\(appState.statistics.totalLearned) 词",
                        color: DesignTokens.Colors.primary
                    )

                    MoyuDivider()

                    OverallStatRow(
                        icon: "flame.fill",
                        title: "连续天数",
                        value: "\(appState.statistics.streakDays) 天",
                        color: DesignTokens.Colors.warning
                    )

                    MoyuDivider()

                    OverallStatRow(
                        icon: "calendar.badge.clock",
                        title: "学习天数",
                        value: "\(appState.statistics.totalDays) 天",
                        color: DesignTokens.Colors.info
                    )

                    MoyuDivider()

                    OverallStatRow(
                        icon: "clock.fill",
                        title: "今日时长",
                        value: formatDuration(appState.todayLearningDuration),
                        color: DesignTokens.Colors.accent
                    )
                }
            }
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("成就墙")
                        .font(DesignTokens.Typography.h4)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                    Spacer()

                    Text("\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                }

                if achievements.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "暂无成就",
                        message: "继续学习解锁更多成就"
                    )
                    .padding(.vertical, DesignTokens.Spacing.lg)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 80))
                        ],
                        spacing: DesignTokens.Spacing.sm
                    ) {
                        ForEach(achievements, id: \.id) { achievement in
                            AchievementBadgeView(achievement: achievement)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadData() {
        appState.loadStatistics()
        recentRecords = DatabaseService.shared.getRecentRecords(days: 7).reversed()
        achievements = DatabaseService.shared.getAchievements()
    }

    private func weekdayLabel(for dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else { return "" }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        return "周\(weekdays[weekday - 1])"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

// MARK: - Overall Stat Row

struct OverallStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            // 标题
            Text(title)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            Spacer()

            // 数值
            Text(value)
                .font(DesignTokens.Typography.h4)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
        }
    }
}

// MARK: - Achievement Badge View

struct AchievementBadgeView: View {
    let achievement: Achievement

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                            DesignTokens.Colors.warning.opacity(0.1) :
                            DesignTokens.Colors.border(for: colorScheme).opacity(0.3)
                    )
                    .frame(width: 56, height: 56)

                Text(achievement.icon)
                    .font(.system(size: 28))
                    .grayscale(achievement.isUnlocked ? 0 : 1)
                    .opacity(achievement.isUnlocked ? 1 : 0.3)
            }

            // 名称
            Text(achievement.name)
                .font(DesignTokens.Typography.captionBold)
                .foregroundColor(
                    achievement.isUnlocked ?
                        DesignTokens.Colors.text(for: colorScheme) :
                        DesignTokens.Colors.textTertiary(for: colorScheme)
                )
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    StatisticsViewV3()
        .environmentObject({
            let state = AppState()
            state.statistics.todayLearned = 20
            state.statistics.todayCorrect = 16
            state.statistics.todayWrong = 4
            state.statistics.totalLearned = 1234
            state.statistics.streakDays = 15
            state.statistics.totalDays = 45
            return state
        }())
}
