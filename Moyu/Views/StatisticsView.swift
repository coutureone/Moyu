import SwiftUI

import Charts

// MARK: - Statistics View (统计页面)
struct StatisticsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var recentRecords: [DailyRecord] = []
    @State private var achievements: [Achievement] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 头部统计卡片
                headerStatsCard
                
                // 今日统计
                todayStatsCard
                
                // 最近7天图表
                weeklyChartCard
                
                // 成就展示
                achievementsCard
                
                // 返回按钮
                backButton
            }
            .padding(16)
        }
        .background(backgroundColor)
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Components
    
    private var backgroundColor: Color {
        MoyuTheme.appBackground(colorScheme)
    }
    
    private var cardBackground: Color {
        MoyuTheme.cardBackground(colorScheme)
    }
    
    private var textColor: Color {
        MoyuTheme.textColor(colorScheme)
    }
    
    private var secondaryTextColor: Color {
        MoyuTheme.secondaryTextColor(colorScheme)
    }
    
    private var headerStatsCard: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "累计学习",
                value: "\(appState.statistics.totalLearned)",
                unit: "词",
                icon: "📚",
                color: Color(hex: "#0077b6")
            )
            
            StatCard(
                title: "学习天数",
                value: "\(appState.statistics.totalDays)",
                unit: "天",
                icon: "📅",
                color: Color(hex: "#00b4d8")
            )
            
            StatCard(
                title: "连续打卡",
                value: "\(appState.statistics.streakDays)",
                unit: "天",
                icon: "🔥",
                color: Color(hex: "#e76f51")
            )
        }
    }
    
    private var todayStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📊 今日学习")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
                Spacer()
                Text(formatDuration(appState.todayLearningDuration))
                    .font(.system(size: 12))
                    .foregroundColor(secondaryTextColor)
            }
            
            HStack(spacing: 15) {
                TodayStatItem(label: "学习", value: appState.statistics.todayLearned, color: Color(hex: "#0077b6"))
                TodayStatItem(label: "正确", value: appState.statistics.todayCorrect, color: .green)
                TodayStatItem(label: "错误", value: appState.statistics.todayWrong, color: Color(hex: "#e76f51"))
                
                Spacer()
                
                // 正确率环形图
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: appState.statistics.todayAccuracy / 100)
                        .stroke(
                            appState.statistics.todayAccuracy >= 80 ? Color.green :
                            appState.statistics.todayAccuracy >= 60 ? Color.orange : Color.red,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(appState.statistics.todayAccuracy))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(textColor)
                }
            }
        }
        .padding(12)
        .moyuCard(colorScheme)
    }
    
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📈 最近7天")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textColor)
            
            if #available(macOS 14.0, *) {
                Chart(recentRecords.reversed()) { record in
                    BarMark(
                        x: .value("日期", formatDateString(record.dateString)),
                        y: .value("数量", record.learnedCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#0077b6"), Color(hex: "#00b4d8")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                    }
                }
            } else {
                // 旧版本回退方案
                SimpleBarChart(records: recentRecords.reversed())
            }
        }
        .padding(12)
        .moyuCard(colorScheme)
    }
    
    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🏆 成就")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
                Spacer()
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryTextColor)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
        .padding(12)
        .moyuCard(colorScheme)
    }
    
    private var backButton: some View {
        Button(action: { appState.currentPage = .home }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("返回")
            }
            .font(.system(size: 13))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(cardBackground)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .onHoverCursor()
    }
    
    // MARK: - Helpers
    
    private func loadData() {
        recentRecords = DatabaseService.shared.getRecentRecords(days: 7)
        achievements = DatabaseService.shared.getAchievements()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "刚开始"
        }
    }
    
    private func formatDateString(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(colorScheme == .dark ? .gray : Color(hex: "#778da9"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(MoyuTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous)
                .stroke(MoyuTheme.border(colorScheme), lineWidth: 1)
        )
    }
}

struct TodayStatItem: View {
    let label: String
    let value: Int
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(colorScheme == .dark ? .gray : Color(hex: "#778da9"))
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 4) {
            Text(achievement.icon)
                .font(.system(size: 24))
                .opacity(achievement.isUnlocked ? 1 : 0.3)
                .grayscale(achievement.isUnlocked ? 0 : 1)
            
            Text(achievement.name)
                .font(.system(size: 9))
                .foregroundColor(achievement.isUnlocked ? .primary : .gray)
                .lineLimit(1)
        }
        .frame(width: 60)
        .help(achievement.description)
    }
}

struct SimpleBarChart: View {
    let records: [DailyRecord]
    
    var maxValue: Int {
        records.map { $0.learnedCount }.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(records) { record in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#0077b6"), Color(hex: "#00b4d8")],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 20, height: max(4, CGFloat(record.learnedCount) / CGFloat(maxValue) * 80))
                    
                    Text(formatDate(record.dateString))
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(height: 100)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
