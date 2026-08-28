import SwiftUI

// MARK: - Settings View v3.0
/// 设置页面
struct SettingsViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("dailyGoal") private var dailyGoal = 20
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false
    @AppStorage("pronunciationSpeed") private var pronunciationSpeed = 1.0
    @AppStorage("learningMode") private var learningMode = "remember"

    @State private var showClearDataAlert = false
    @State private var showExportSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            MoyuDivider()

            // 设置内容
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // 学习设置
                    learningSettingsSection

                    // 发音设置
                    pronunciationSettingsSection

                    // 主题设置
                    appearanceSettingsSection

                    // 数据管理
                    dataManagementSection

                    // 关于
                    aboutSection

                    Spacer(minLength: DesignTokens.Spacing.xl)
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
        .background(DesignTokens.Colors.background(for: colorScheme))
        .alert("清空数据", isPresented: $showClearDataAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("确定要清空所有学习数据吗？此操作不可恢复。")
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            IconButton(icon: "chevron.left", size: 32) {
                appState.currentPage = .home
            }

            Spacer()

            Text("设置")
                .font(DesignTokens.Typography.h3)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            Spacer()

            // 占位，保持居中
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface(for: colorScheme))
    }

    // MARK: - Learning Settings

    private var learningSettingsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("学习设置")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                // 每日目标
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("每日目标")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                    MoyuDropdown(
                        title: "",
                        selectedValue: $dailyGoal,
                        options: [10, 20, 30, 50, 100]
                    )
                }

                MoyuDivider()

                // 学习模式
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("默认学习模式")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                    Picker("", selection: $learningMode) {
                        Text("记忆模式").tag("remember")
                        Text("选择模式").tag("choice")
                        Text("混合模式").tag("mixed")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - Pronunciation Settings

    private var pronunciationSettingsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("发音设置")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                // 自动发音
                Toggle(isOn: $autoPlayPronunciation) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("自动发音")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                        Text("显示单词时自动播放发音")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                    }
                }
                .toggleStyle(.switch)

                MoyuDivider()

                // 发音速度
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("发音速度")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                        Spacer()

                        Text("\(pronunciationSpeed, specifier: "%.1f")x")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.primary)
                    }

                    Slider(value: $pronunciationSpeed, in: 0.5...2.0, step: 0.1)
                        .tint(DesignTokens.Colors.primary)
                }
            }
        }
    }

    // MARK: - Appearance Settings

    private var appearanceSettingsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("外观")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                HStack {
                    Text("主题模式")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                    Spacer()

                    Text("跟随系统")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                }
            }
        }
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("数据管理")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                // 导出数据
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出学习数据")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(DesignTokens.Typography.caption)
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                }
                .buttonStyle(.plain)

                MoyuDivider()

                // 清空数据
                Button(action: {
                    showClearDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("清空所有数据")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(DesignTokens.Typography.caption)
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.error)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("关于")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Text("版本")
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        Spacer()
                        Text("v3.0.0")
                            .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                    }
                    .font(DesignTokens.Typography.body)

                    MoyuDivider()

                    HStack {
                        Text("项目主页")
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        Spacer()
                        Button("GitHub") {
                            if let url = URL(string: "https://github.com/coutureone/Moyu") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .foregroundColor(DesignTokens.Colors.primary)
                    }
                    .font(DesignTokens.Typography.body)
                }
            }
        }
    }

    // MARK: - Actions

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "moyu-data-\(Date().ISO8601Format()).json"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            // TODO: 实现数据导出
            let data: [String: Any] = [
                "exportDate": Date().ISO8601Format(),
                "statistics": [
                    "totalLearned": appState.statistics.totalLearned,
                    "todayLearned": appState.statistics.todayLearned,
                    "streakDays": appState.statistics.streakDays
                ],
                "wrongBook": appState.wrongBookWords.map { ["word": $0.word, "meanings": $0.meanings] },
                "favorites": appState.favoriteWords.map { ["word": $0.word, "meanings": $0.meanings] }
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) {
                try? jsonData.write(to: url)
                showExportSuccess = true
            }
        }
    }

    private func clearAllData() {
        DatabaseService.shared.clearAllData()
        appState.loadStatistics()
        appState.loadWrongBook()
        appState.loadFavorites()
    }
}

// MARK: - Preview
#Preview {
    SettingsViewV3()
        .environmentObject(AppState())
}
