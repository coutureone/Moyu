import SwiftUI

// MARK: - Practice Session View v3.0
/// 练习会话 - 闪卡模式
struct PracticeSessionViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var pronunciationService = PronunciationService.shared

    let words: [Word]
    let source: PracticeSource

    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var rememberedCount = 0
    @State private var forgotCount = 0
    @State private var isComplete = false
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false

    var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            MoyuDivider()

            if isComplete {
                // 完成视图
                completionView
            } else if let word = currentWord {
                // 闪卡视图
                flashcardView(word: word)
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
            IconButton(icon: "xmark", size: 32) {
                exitPractice()
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.xxs) {
                Text("\(currentIndex + 1)/\(words.count)")
                    .font(DesignTokens.Typography.h4)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                ProgressDots(
                    current: min(currentIndex + 1, 5),
                    total: min(words.count, 5)
                )
            }

            Spacer()

            // 来源标签
            Badge(
                sourceTitle,
                color: sourceColor
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface(for: colorScheme))
    }

    private var sourceTitle: String {
        switch source {
        case .wrongBook: return "错词本"
        case .favorites: return "收藏夹"
        }
    }

    private var sourceColor: Color {
        switch source {
        case .wrongBook: return DesignTokens.Colors.error
        case .favorites: return DesignTokens.Colors.warning
        }
    }

    // MARK: - Flashcard View

    private func flashcardView(word: Word) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // 闪卡
            flashcard(word: word)
                .padding(.horizontal, DesignTokens.Spacing.md)

            Spacer()

            // 操作按钮
            actionButtons(word: word)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.lg)
        }
    }

    // MARK: - Flashcard

    private func flashcard(word: Word) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 单词正面
            VStack(spacing: DesignTokens.Spacing.md) {
                Text(word.word)
                    .font(DesignTokens.Typography.displayLarge)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                if let phonetic = word.phonetic {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text("[\(phonetic)]")
                            .font(DesignTokens.Typography.h3)
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                        Button(action: {
                            playPronunciation(word: word)
                        }) {
                            Image(systemName: pronunciationService.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(DesignTokens.Typography.h3)
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 显示/隐藏答案
            if showAnswer {
                answerSection(word: word)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            } else {
                showAnswerButton
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 400)
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Colors.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .strokeBorder(
                    colorScheme == .dark ? DesignTokens.Colors.border(for: colorScheme) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(
            color: DesignTokens.Shadow.xl(for: colorScheme).color,
            radius: DesignTokens.Shadow.xl(for: colorScheme).radius,
            y: DesignTokens.Shadow.xl(for: colorScheme).y
        )
    }

    private var showAnswerButton: some View {
        Button(action: {
            withAnimation(DesignTokens.Animation.spring) {
                showAnswer = true
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "eye")
                Text("显示答案")
            }
            .font(DesignTokens.Typography.label)
            .foregroundColor(DesignTokens.Colors.primary)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .strokeBorder(DesignTokens.Colors.primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func answerSection(word: Word) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            MoyuDivider()

            // 释义
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                ForEach(word.meanings.split(separator: ";"), id: \.self) { meaning in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                        Text("•")
                            .foregroundColor(DesignTokens.Colors.primary)
                        Text(String(meaning).trimmingCharacters(in: .whitespaces))
                            .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                    }
                    .font(DesignTokens.Typography.bodyLarge)
                }
            }

            // 例句
            if let example = word.example, !example.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(example)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        .italic()

                    if let translation = word.translation, !translation.isEmpty {
                        Text(translation)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textTertiary(for: colorScheme))
                    }
                }
                .padding(.top, DesignTokens.Spacing.xs)
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(word: Word) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 忘记了按钮
            Button(action: {
                markAsForgot(word: word)
            }) {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                    Text("忘记了")
                        .font(DesignTokens.Typography.label)
                }
                .foregroundColor(DesignTokens.Colors.error)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.error.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.error.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!showAnswer)
            .opacity(showAnswer ? 1 : 0.5)

            // 记住了按钮
            Button(action: {
                markAsRemembered(word: word)
            }) {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                    Text("记住了")
                        .font(DesignTokens.Typography.label)
                }
                .foregroundColor(DesignTokens.Colors.success)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.success.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.success.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!showAnswer)
            .opacity(showAnswer ? 1 : 0.5)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.success.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignTokens.Colors.success)
            }

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("练习完成！")
                    .font(DesignTokens.Typography.h2)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                Text("共练习 \(words.count) 个单词")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                StatCard(
                    title: "记住",
                    value: "\(rememberedCount)",
                    icon: "checkmark.circle.fill",
                    color: DesignTokens.Colors.success
                )

                StatCard(
                    title: "忘记",
                    value: "\(forgotCount)",
                    icon: "xmark.circle.fill",
                    color: DesignTokens.Colors.error
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            VStack(spacing: DesignTokens.Spacing.xs) {
                PrimaryButton("再练一次", icon: "arrow.clockwise") {
                    restartPractice()
                }

                SecondaryButton("返回", icon: "arrow.left") {
                    exitPractice()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            Spacer()
        }
    }

    // MARK: - Actions

    private func markAsRemembered(word: Word) {
        rememberedCount += 1
        DatabaseService.shared.markWordAsLearned(word: word, isCorrect: true)

        if source == .wrongBook {
            DatabaseService.shared.removeFromWrongBook(word: word)
            appState.loadWrongBook()
        }

        nextWord()
    }

    private func markAsForgot(word: Word) {
        forgotCount += 1
        DatabaseService.shared.markWordAsLearned(word: word, isCorrect: false)
        nextWord()
    }

    private func nextWord() {
        showAnswer = false

        withAnimation(DesignTokens.Animation.normal) {
            if currentIndex + 1 < words.count {
                currentIndex += 1
            } else {
                isComplete = true
            }
        }
    }

    private func restartPractice() {
        currentIndex = 0
        showAnswer = false
        rememberedCount = 0
        forgotCount = 0
        isComplete = false
    }

    private func exitPractice() {
        switch source {
        case .wrongBook:
            appState.currentPage = .wrongBook
        case .favorites:
            appState.currentPage = .favorites
        }
    }

    // MARK: - Keyboard Shortcuts

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .showAnswer,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(DesignTokens.Animation.spring) {
                showAnswer = true
            }
        }

        NotificationCenter.default.addObserver(
            forName: .markRemembered,
            object: nil,
            queue: .main
        ) { _ in
            guard showAnswer, let word = currentWord else { return }
            markAsRemembered(word: word)
        }

        NotificationCenter.default.addObserver(
            forName: .markForgot,
            object: nil,
            queue: .main
        ) { _ in
            guard showAnswer, let word = currentWord else { return }
            markAsForgot(word: word)
        }

        NotificationCenter.default.addObserver(
            forName: .playPronunciation,
            object: nil,
            queue: .main
        ) { _ in
            guard let word = currentWord else { return }
            playPronunciation(word: word)
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

// MARK: - Preview
#Preview {
    PracticeSessionViewV3(
        words: [
            Word(
                id: 1,
                word: "abandon",
                phonetic: "əˈbændən",
                meanings: "v. 放弃；抛弃",
                example: "We had to abandon the car.",
                translation: "我们不得不弃车而去。"
            )
        ],
        source: .wrongBook
    )
    .environmentObject(AppState())
}
