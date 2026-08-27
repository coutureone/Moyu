import SwiftUI

// MARK: - Practice from Wrong Book/Favorites View
struct PracticeSessionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    let words: [Word]
    let sourceType: PracticeSourceType

    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var sessionComplete = false
    @State private var correctCount = 0
    @State private var wrongCount = 0

    enum PracticeSourceType {
        case wrongBook
        case favorites

        var title: String {
            switch self {
            case .wrongBook: return "错词本练习"
            case .favorites: return "收藏夹练习"
            }
        }
    }

    var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    var body: some View {
        ZStack {
            ColorTheme.background(for: colorScheme)
                .ignoresSafeArea()

            if sessionComplete {
                completionView
            } else if let word = currentWord {
                VStack(spacing: 0) {
                    // Header with title and progress
                    headerView

                    // Word content
                    wordContentView(word: word)

                    Spacer()

                    // Action buttons
                    actionButtons
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(sourceType.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ColorTheme.text(for: colorScheme))

                Spacer()

                Text("\(currentIndex + 1)/\(words.count)")
                    .font(.system(size: 12))
                    .foregroundColor(ColorTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ProgressView(value: Double(currentIndex + 1), total: Double(words.count))
                .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.primary))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                .padding(.horizontal, 16)
        }
    }

    private func wordContentView(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word and pronunciation
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(word.headWord)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ColorTheme.primary)

                if !word.usphone.isEmpty {
                    Text("[\(word.usphone)]")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(ColorTheme.textSecondary)
                }
            }

            // Translation (shown after reveal)
            if showAnswer {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.tranCN)
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme.textPrimary)

                    if !word.phrase.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.phrase)
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme.textSecondary)

                            Text(word.phraseCN)
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }

            // Source indicator
            if let bookName = word.bookName {
                Text("来源: \(bookName)")
                    .font(.system(size: 11))
                    .foregroundColor(ColorTheme.textTertiary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !showAnswer {
                // Show answer button
                Button(action: { withAnimation { showAnswer = true } }) {
                    Text("显示答案")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(ColorTheme.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .buttonHoverEffect()
            } else {
                // Remember/Forgot buttons
                HStack(spacing: 12) {
                    Button(action: { handleAnswer(remembered: false) }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("忘记了")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(ColorTheme.error)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .buttonHoverEffect()

                    Button(action: { handleAnswer(remembered: true) }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("记住了")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(ColorTheme.success)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .buttonHoverEffect()
                }
            }

            // Back button
            Button(action: { appState.currentPage = .home }) {
                Text("返回")
                    .font(.system(size: 13))
                    .foregroundColor(ColorTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .onHoverCursor()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.success)

            Text("练习完成！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ColorTheme.text(for: colorScheme))

            VStack(spacing: 8) {
                HStack {
                    Text("记住:")
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("\(correctCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ColorTheme.success)
                }

                HStack {
                    Text("忘记:")
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("\(wrongCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ColorTheme.error)
                }
            }
            .font(.system(size: 16))

            Button(action: { appState.currentPage = .home }) {
                Text("返回首页")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 160, height: 44)
                    .background(ColorTheme.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .buttonHoverEffect()
        }
    }

    private func handleAnswer(remembered: Bool) {
        if remembered {
            correctCount += 1
        } else {
            wrongCount += 1
        }

        withAnimation {
            showAnswer = false

            if currentIndex >= words.count - 1 {
                sessionComplete = true
            } else {
                currentIndex += 1
            }
        }
    }
}

#Preview {
    PracticeSessionView(
        words: [
            Word(wordRank: 1, headWord: "example", tranCN: "例子", usphone: "ɪɡˈzæmpl", phrase: "For example", phraseCN: "例如")
        ],
        sourceType: .wrongBook
    )
    .environmentObject(AppState.shared)
    .frame(width: 400, height: 500)
}
