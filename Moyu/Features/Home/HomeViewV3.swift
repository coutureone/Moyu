import SwiftUI

// MARK: - Home View v3.0
/// 首页 - 全新设计
struct HomeViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedCount = 20
    @State private var showToast = false
    @State private var toastMessage = ""

    let quickSelectOptions = [10, 20, 30, 50]
    let dropdownOptions = [5, 10, 15, 20, 25, 30, 40, 50, 100]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 今日进度卡片
                todayProgressCard

                // 开始学习卡片
                startLearningCard

                // 快捷入口
                quickActionsSection

                Spacer(minLength: DesignTokens.Spacing.xl)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background(for: colorScheme))
        .overlay(
            // Toast 提示
            VStack {
                if showToast {
                    ToastMessage(message: toastMessage, type: .success)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.top, DesignTokens.Spacing.md)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
        )
    }

    // MARK: - Today Progress Card

    private var todayProgressCard: some View {
        ProgressCard(
            title: "今日进度",
            current: appState.statistics.todayLearned,
            total: appState.dailyGoal,
            icon: "chart.bar.fill"
        )
    }

    // MARK: - Start Learning Card

    private var startLearningCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // 标题
                Text("开始学习")
                    .font(DesignTokens.Typography.h3)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                // 数量选择
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("学习数量")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                    MoyuDropdown(
                        title: "",
                        selectedValue: $selectedCount,
                        options: dropdownOptions
                    )
                }

                // 快速选择
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("快速选择")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(quickSelectOptions, id: \.self) { option in
                            QuickSelectButton(
                                value: "\(option)",
                                isSelected: selectedCount == option
                            ) {
                                withAnimation(DesignTokens.Animation.spring) {
                                    selectedCount = option
                                }
                            }
                        }

                        QuickSelectButton(
                            value: "自定义",
                            isSelected: !quickSelectOptions.contains(selectedCount)
                        ) {
                            // 可以弹出自定义输入框
                        }
                    }
                }

                // 开始按钮
                PrimaryButton("开始学习", icon: "play.fill") {
                    startLearning()
                }
                .padding(.top, DesignTokens.Spacing.xs)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("快捷入口")
                .font(DesignTokens.Typography.h4)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            // 第一行
            HStack(spacing: DesignTokens.Spacing.sm) {
                ActionCard(
                    icon: "book.closed.fill",
                    title: "错词本",
                    subtitle: "复习巩固",
                    count: appState.wrongBookWords.count
                ) {
                    appState.currentPage = .wrongBook
                }

                ActionCard(
                    icon: "star.fill",
                    title: "收藏夹",
                    subtitle: "重点单词",
                    count: appState.favoriteWords.count
                ) {
                    appState.currentPage = .favorites
                }
            }

            // 第二行
            HStack(spacing: DesignTokens.Spacing.sm) {
                ActionCard(
                    icon: "chart.bar.fill",
                    title: "统计",
                    subtitle: "查看报告"
                ) {
                    appState.currentPage = .statistics
                }

                ActionCard(
                    icon: "target",
                    title: "练习",
                    subtitle: "闪卡模式"
                ) {
                    // 打开练习模式选择
                    if !appState.wrongBookWords.isEmpty {
                        appState.currentPage = .practiceSession(
                            words: appState.wrongBookWords,
                            source: .wrongBook
                        )
                    } else {
                        showToastMessage("错词本为空，先去学习吧！")
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func startLearning() {
        // 获取单词
        let words = DatabaseService.shared.getRandomWords(count: selectedCount)

        if words.isEmpty {
            showToastMessage("没有可学习的单词")
            return
        }

        // 开始学习
        appState.setWords(words)
        appState.currentPage = .remember

        showToastMessage("开始学习 \(words.count) 个单词")
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(DesignTokens.Animation.spring) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(DesignTokens.Animation.spring) {
                showToast = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeViewV3()
        .environmentObject({
            let state = AppState()
            state.statistics.todayLearned = 12
            state.statistics.todayCorrect = 10
            state.statistics.todayWrong = 2
            state.dailyGoal = 20
            return state
        }())
}
