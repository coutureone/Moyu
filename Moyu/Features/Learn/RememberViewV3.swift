import SwiftUI

// MARK: - Remember View v3.0
/// 记忆模式 - 全新设计
struct RememberViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var pronunciationService = PronunciationService.shared

    @State private var showMeaning = false
    @State private var isExiting = false
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false

    var currentWord: Word? {
        guard appState.currentIndex < appState.words.count else { return nil }
        return appState.words[appState.currentIndex]
    }

    var progress: Double {
        guard !appState.words.isEmpty else { return 0 }
        return Double(appState.currentIndex) / Double(appState.words.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            // 分割线
            MoyuDivider()

            if let word = currentWord {
                // 单词卡片区域
                wordCardSection(word: word)
            } else {
                // 完成状态
                completionView
            }
        }
        .background(DesignTokens.Colors.background(for: colorScheme))
        .onAppear {
            setupNotifications()
            // 自动发音
            if autoPlayPronunciation, let word = currentWord {
                playPronunciation(word: word)
            }
        }
        .onDisappear {
            removeNotifications()
            pronunciationService.stop()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // 返回按钮
            IconButton(icon: "chevron.left", size: 32) {
                exitLearning()
            }

            Spacer()

            // 进度文本
            Text("\(appState.currentIndex + 1)/\(appState.words.count)")
                .font(DesignTokens.Typography.h4)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            Spacer()

            // 进度点
            ProgressDots(
                current: min(appState.currentIndex + 1, 5),
                total: min(appState.words.count, 5)
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface(for: colorScheme))
    }

    // MARK: - Word Card Section

    private func wordCardSection(word: Word) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)

                // 单词和音标
                wordHeader(word: word)

                // 释义（可显示/隐藏）
                if showMeaning {
                    meaningSection(word: word)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                } else {
                    showMeaningButton
                }

                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)

                // 底部操作区
                actionButtons(word: word)

                Spacer()
                    .frame(height: DesignTokens.Spacing.md)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }

    // MARK: - Word Header

    private func wordHeader(word: Word) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // 单词
            Text(word.word)
                .font(DesignTokens.Typography.display)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

            // 音标
            if let phonetic = word.phonetic {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text("[\(phonetic)]")
                        .font(DesignTokens.Typography.h4)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                    // 发音按钮
                    Button(action: {
                        playPronunciation(word: word)
                    }) {
                        Image(systemName: pronunciationService.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(DesignTokens.Typography.h4)
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Show Meaning Button

    private var showMeaningButton: some View {
        Button(action: {
            withAnimation(DesignTokens.Animation.spring) {
                showMeaning = true
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "eye")
                Text("显示释义")
            }
            .font(DesignTokens.Typography.label)
            .foregroundColor(DesignTokens.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.buttonHeightMedium)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(DesignTokens.Colors.primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meaning Section

    private func meaningSection(word: Word) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // 释义
            Card {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    ForEach(word.meanings.split(separator: ";"), id: \.self) { meaning in
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                            Text("•")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.primary)

                            Text(String(meaning).trimmingCharacters(in: .whitespaces))
                                .font(DesignTokens.Typography.bodyLarge)
                                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                        }
                    }
                }
            }

            // 例句（如果有）
            if let example = word.example, !example.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("例句")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                    Card {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(example)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                                .italic()

                            if let translation = word.translation, !translation.isEmpty {
                                Text(translation)
                                    .font(DesignTokens.Typography.bodySmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                                    .padding(.top, DesignTokens.Spacing.xxs)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(word: Word) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // 快捷操作
            HStack(spacing: DesignTokens.Spacing.sm) {
                // 收藏按钮
                QuickActionButton(
                    icon: appState.favoriteWords.contains(where: { $0.id == word.id }) ? "heart.fill" : "heart",
                    title: "收藏",
                    color: DesignTokens.Colors.error
                ) {
                    toggleFavorite(word: word)
                }

                // 错词按钮
                QuickActionButton(
                    icon: appState.wrongBookWords.contains(where: { $0.id == word.id }) ? "xmark.circle.fill" : "xmark.circle",
                    title: "错词",
                    color: DesignTokens.Colors.warning
                ) {
                    toggleWrongBook(word: word)
                }
            }

            // 主要操作
            VStack(spacing: DesignTokens.Spacing.xs) {
                SecondaryButton("不认识", icon: "xmark") {
                    markAsWrong(word: word)
                }

                PrimaryButton("认识", icon: "checkmark") {
                    markAsCorrect(word: word)
                }
            }

            // 快捷键提示
            Text("快捷键: 1-认识  2-不认识  3-发音  4-收藏")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textTertiary(for: colorScheme))
                .padding(.top, DesignTokens.Spacing.xs)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // 完成图标
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.success.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignTokens.Colors.success)
            }

            // 完成文本
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("学习完成！")
                    .font(DesignTokens.Typography.h2)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                Text("共学习 \(appState.words.count) 个单词")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
            }

            // 统计卡片
            HStack(spacing: DesignTokens.Spacing.sm) {
                StatCard(
                    title: "正确",
                    value: "\(appState.correctCount)",
                    icon: "checkmark.circle.fill",
                    color: DesignTokens.Colors.success
                )

                StatCard(
                    title: "错误",
                    value: "\(appState.wrongCount)",
                    icon: "xmark.circle.fill",
                    color: DesignTokens.Colors.error
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            // 返回按钮
            PrimaryButton("返回首页", icon: "house.fill") {
                appState.currentPage = .home
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            Spacer()
        }
    }

    // MARK: - Actions

    private func markAsCorrect(word: Word) {
        appState.correctCount += 1
        DatabaseService.shared.markWordAsLearned(word: word, isCorrect: true)
        nextWord()
    }

    private func markAsWrong(word: Word) {
        appState.wrongCount += 1
        DatabaseService.shared.markWordAsLearned(word: word, isCorrect: false)
        DatabaseService.shared.addToWrongBook(word: word)
        nextWord()
    }

    private func nextWord() {
        showMeaning = false
        withAnimation(DesignTokens.Animation.normal) {
            appState.currentIndex += 1
        }
    }

    private func toggleFavorite(word: Word) {
        if appState.favoriteWords.contains(where: { $0.id == word.id }) {
            DatabaseService.shared.removeFromFavorites(word: word)
        } else {
            DatabaseService.shared.addToFavorites(word: word)
        }
        appState.loadFavorites()
    }

    private func toggleWrongBook(word: Word) {
        if appState.wrongBookWords.contains(where: { $0.id == word.id }) {
            DatabaseService.shared.removeFromWrongBook(word: word)
        } else {
            DatabaseService.shared.addToWrongBook(word: word)
        }
        appState.loadWrongBook()
    }

    private func exitLearning() {
        appState.currentPage = .home
    }

    // MARK: - Keyboard Shortcuts

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .showAnswer,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(DesignTokens.Animation.spring) {
                showMeaning = true
            }
        }

        NotificationCenter.default.addObserver(
            forName: .markCorrect,
            object: nil,
            queue: .main
        ) { _ in
            guard let word = currentWord else { return }
            markAsCorrect(word: word)
        }

        NotificationCenter.default.addObserver(
            forName: .markWrong,
            object: nil,
            queue: .main
        ) { _ in
            guard let word = currentWord else { return }
            markAsWrong(word: word)
        }

        NotificationCenter.default.addObserver(
            forName: .playPronunciation,
            object: nil,
            queue: .main
        ) { _ in
            guard let word = currentWord else { return }
            playPronunciation(word: word)
        }

        NotificationCenter.default.addObserver(
            forName: .toggleFavorite,
            object: nil,
            queue: .main
        ) { _ in
            guard let word = currentWord else { return }
            toggleFavorite(word: word)
        }
    }

    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Pronunciation

    private func playPronunciation(word: Word) {
        pronunciationService.loadRateFromSettings()
        pronunciationService.speak(word: word.word)
    }
}

// MARK: - Quick Action Button Component

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(DesignTokens.Typography.captionBold)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(DesignTokens.Animation.fast) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(DesignTokens.Animation.fast) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview
#Preview {
    RememberViewV3()
        .environmentObject({
            let state = AppState()
            state.words = [
                Word(
                    id: 1,
                    word: "abandon",
                    phonetic: "əˈbændən",
                    meanings: "v. 放弃；抛弃；遗弃; n. 放任；放纵",
                    example: "We had to abandon the car.",
                    translation: "我们不得不弃车而去。"
                )
            ]
            state.currentIndex = 0
            return state
        }())
}
