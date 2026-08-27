import SwiftUI
import Charts

// MARK: - Enhanced Statistics View (增强统计页面)
struct EnhancedStatisticsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var recentRecords: [DailyRecord] = []
    @State private var achievements: [Achievement] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 今日总览卡片
                todayOverviewCard

                // 7天学习趋势
                weeklyTrendCard

                // 总体统计
                overallStatsCard

                // 成就墙
                achievementsCard

                // 返回按钮
                backButton
            }
            .padding(16)
        }
        .background(ColorTheme.background(for: colorScheme))
        .onAppear {
            loadData()
        }
    }

    // MARK: - Today Overview

    private var todayOverviewCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📊 今日统计")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ColorTheme.text(for: colorScheme))
                Spacer()
            }

            HStack(spacing: 12) {
                StatTile(
                    title: "已学习",
                    value: "\(appState.statistics.todayLearned)",
                    icon: "book.fill",
                    color: ColorTheme.primary
                )

                StatTile(
                    title: "正确",
                    value: "\(appState.statistics.todayCorrect)",
                    icon: "checkmark.circle.fill",
                    color: ColorTheme.success
                )

                StatTile(
                    title: "错误",
                    value: "\(appState.statistics.todayWrong)",
                    icon: "xmark.circle.fill",
                    color: ColorTheme.error
                )
            }

            // 正确率
            if appState.statistics.todayLearned > 0 {
                HStack {
                    Text("正确率")
                        .font(.system(size: 13))
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    Text("\(Int(appState.statistics.todayAccuracy))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(accuracyColor)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var accuracyColor: Color {
        let accuracy = appState.statistics.todayAccuracy
        if accuracy >= 90 { return ColorTheme.success }
        if accuracy >= 70 { return ColorTheme.primary }
        return ColorTheme.error
    }

    // MARK: - Weekly Trend

    private var weeklyTrendCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📈 7天趋势")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ColorTheme.text(for: colorScheme))
                Spacer()
            }

            if !recentRecords.isEmpty {
                WeeklyChart(records: recentRecords)
                    .frame(height: 140)
            } else {
                Text("暂无数据")
                    .font(.system(size: 13))
                    .foregroundColor(ColorTheme.textSecondary)
                    .frame(height: 100)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Overall Stats

    private var overallStatsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🏅 总体统计")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ColorTheme.text(for: colorScheme))
                Spacer()
            }

            VStack(spacing: 10) {
                OverallStatRow(
                    icon: "books.vertical.fill",
                    title: "累计学习",
                    value: "\(appState.statistics.totalLearned) 词",
                    color: ColorTheme.primary
                )

                OverallStatRow(
                    icon: "flame.fill",
                    title: "连续天数",
                    value: "\(appState.statistics.streakDays) 天",
                    color: .orange
                )

                OverallStatRow(
                    icon: "calendar.badge.clock",
                    title: "学习天数",
                    value: "\(appState.statistics.totalDays) 天",
                    color: ColorTheme.primaryDark
                )

                OverallStatRow(
                    icon: "clock.fill",
                    title: "今日时长",
                    value: formatDuration(appState.todayLearningDuration),
                    color: ColorTheme.accentLight
                )
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Achievements

    private var achievementsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🏆 成就墙")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ColorTheme.text(for: colorScheme))
                Spacer()
                Text("\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.textSecondary)
            }

            if achievements.isEmpty {
                Text("暂无成就")
                    .font(.system(size: 13))
                    .foregroundColor(ColorTheme.textSecondary)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                    ForEach(achievements, id: \.id) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var backButton: some View {
        Button(action: { appState.currentPage = .home }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("返回")
            }
            .font(.system(size: 13))
            .foregroundColor(ColorTheme.text(for: colorScheme))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(ColorTheme.cardBackground(for: colorScheme))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .onHoverCursor()
    }

    // MARK: - Helpers

    private func loadData() {
        appState.loadStatistics()
        recentRecords = DatabaseService.shared.getRecentRecords(days: 7).reversed()
        achievements = DatabaseService.shared.getAchievements()
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

// MARK: - Stat Tile
struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ColorTheme.text(for: colorScheme))

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(ColorTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorTheme.text(for: colorScheme))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Weekly Chart
struct WeeklyChart: View {
    let records: [DailyRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(records, id: \.dateString) { record in
                    VStack(spacing: 4) {
                        Spacer()

                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(
                                colors: [ColorTheme.primary, ColorTheme.primaryLight],
                                startPoint: .bottom,
                                endPoint: .top
                            ))
                            .frame(height: barHeight(for: record))

                        Text(dayLabel(for: record.dateString))
                            .font(.system(size: 9))
                            .foregroundColor(ColorTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
    }

    private func barHeight(for record: DailyRecord) -> CGFloat {
        let maxCount = records.map(\.learnedCount).max() ?? 1
        let ratio = CGFloat(record.learnedCount) / CGFloat(max(maxCount, 1))
        return max(ratio * 100, 4)
    }

    private func dayLabel(for dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        dayFormatter.locale = Locale(identifier: "zh_CN")
        return dayFormatter.string(from: date)
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.icon)
                .font(.system(size: 28))
                .opacity(achievement.isUnlocked ? 1.0 : 0.3)

            Text(achievement.name)
                .font(.system(size: 10))
                .foregroundColor(achievement.isUnlocked ? ColorTheme.textPrimary : ColorTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 80, height: 70)
        .background(
            achievement.isUnlocked
                ? ColorTheme.primary.opacity(0.1)
                : Color.gray.opacity(0.1)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    achievement.isUnlocked ? ColorTheme.primary : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

#Preview {
    EnhancedStatisticsView()
        .environmentObject(AppState.shared)
        .frame(width: 400, height: 600)
}
