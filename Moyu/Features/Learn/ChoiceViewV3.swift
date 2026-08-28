import SwiftUI

// MARK: - Choice View v3.0
/// 选择模式 - 全新设计
struct ChoiceViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var pronunciationService = PronunciationService.shared

    @State private var selectedOption: Int? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false

    var currentWord: Word? {
        guard appState.currentIndex < appState.words.count else { return nil }
        return appState.words[appState.currentIndex]
    }

    var options: [String] {
        guard let word = currentWord else { return [] }
        var opts = [word.meanings]

        // 获取其他随机单词的释义作为干扰项
        let otherWords = DatabaseService.shared.getRandomWords(count: 3)
            .filter { $0.id != word.id }

        opts.append(contentsOf: otherWords.prefix(3).map { $0.meanings })

        return opts.shuffled()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            // 分割线
            MoyuDivider()

            if let word = currentWord {
                // 选择题区域
                choiceSection(word: word)
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

    // MARK: - Choice Section

    private func choiceSection(word: Word) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)

                // 单词和音标
                wordHeader(word: word)

                // 提示文本
                Text("选择正确的释义")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                // 选项列表
                optionsList(word: word)

                // 结果反馈
                if showResult {
                    resultFeedback(word: word)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
                    .frame(height: DesignTokens.Spacing.xl)
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

    // MARK: - Options List

    private func optionsList(word: Word) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                optionButton(
                    index: index,
                    option: option,
                    correctOption: word.meanings
                )
            }
        }
    }

    private func optionButton(index: Int, option: String, correctOption: String) -> some View {
        Button(action: {
            guard selectedOption == nil else { return }
            selectOption(index: index, option: option, correctOption: correctOption)
        }) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                // 选项编号
                Text(optionLabel(index: index))
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(optionLabelColor(index: index, correctOption: correctOption))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(optionBackgroundColor(index: index, correctOption: correctOption))
                    )

                // 选项内容
                Text(option)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .strokeBorder(
                        optionBorderColor(index: index, correctOption: correctOption),
                        lineWidth: selectedOption == index ? 2 : 1
                    )
            )
            .shadow(
                color: selectedOption == index ? DesignTokens.Colors.primary.opacity(0.2) : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedOption != nil)
    }

    // MARK: - Option Styles

    private func optionLabel(index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }

    private func optionLabelColor(index: Int, correctOption: String) -> Color {
        if showResult {
            if options[index] == correctOption {
                return .white
            } else if selectedOption == index {
                return .white
            }
        }
        return DesignTokens.Colors.text(for: colorScheme)
    }

    private func optionBackgroundColor(index: Int, correctOption: String) -> Color {
        if showResult {
            if options[index] == correctOption {
                return DesignTokens.Colors.success
            } else if selectedOption == index {
                return DesignTokens.Colors.error
            }
        }
        return selectedOption == index ? DesignTokens.Colors.primary.opacity(0.1) : DesignTokens.Colors.border(for: colorScheme).opacity(0.3)
    }

    private func optionBorderColor(index: Int, correctOption: String) -> Color {
        if showResult {
            if options[index] == correctOption {
                return DesignTokens.Colors.success
            } else if selectedOption == index {
                return DesignTokens.Colors.error
            }
        }

        if selectedOption == index {
            return DesignTokens.Colors.primary
        }

        return DesignTokens.Colors.border(for: colorScheme)
    }

    // MARK: - Result Feedback

    private func resultFeedback(word: Word) -> some View {
        Card {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // 结果图标和文本
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(DesignTokens.Typography.h3)
                        .foregroundColor(isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)

                    Text(isCorrect ? "回答正确！" : "回答错误")
                        .font(DesignTokens.Typography.h4)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                }

                // 例句（如果有）
                if let example = word.example, !example.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("例句")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))

                        Text(example)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                            .italic()

                        if let translation = word.translation, !translation.isEmpty {
                            Text(translation)
                                .font(DesignTokens.Typography.bodySmall)
                                .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DesignTokens.Spacing.xs)
                }

                // 下一题按钮
                PrimaryButton("下一题", icon: "arrow.right") {
                    nextWord()
                }
                .padding(.top, DesignTokens.Spacing.xs)
            }
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

    private func selectOption(index: Int, option: String, correctOption: String) {
        selectedOption = index
        isCorrect = (option == correctOption)

        withAnimation(DesignTokens.Animation.spring) {
            showResult = true
        }

        // 记录结果
        if let word = currentWord {
            if isCorrect {
                appState.correctCount += 1
                DatabaseService.shared.markWordAsLearned(word: word, isCorrect: true)
            } else {
                appState.wrongCount += 1
                DatabaseService.shared.markWordAsLearned(word: word, isCorrect: false)
                DatabaseService.shared.addToWrongBook(word: word)
            }
        }
    }

    private func nextWord() {
        selectedOption = nil
        showResult = false

        withAnimation(DesignTokens.Animation.normal) {
            appState.currentIndex += 1
        }
    }

    private func exitLearning() {
        appState.currentPage = .home
    }

    // MARK: - Keyboard Shortcuts

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .selectOption,
            object: nil,
            queue: .main
        ) { notification in
            guard !showResult,
                  let optionIndex = notification.object as? Int,
                  optionIndex < options.count,
                  let word = currentWord else { return }

            selectOption(index: optionIndex, option: options[optionIndex], correctOption: word.meanings)
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
    ChoiceViewV3()
        .environmentObject({
            let state = AppState()
            state.words = [
                Word(
                    id: 1,
                    word: "abandon",
                    phonetic: "əˈbændən",
                    meanings: "v. 放弃；抛弃；遗弃",
                    example: "We had to abandon the car.",
                    translation: "我们不得不弃车而去。"
                )
            ]
            state.currentIndex = 0
            return state
        }())
}
