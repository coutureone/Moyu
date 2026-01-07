import SwiftUI

// MARK: - Choice View (选择题页面)
struct ChoiceView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var currentIndex = 0
    @State private var answers: [String] = []
    @State private var showAnswer = false
    @State private var isComplete = false
    @State private var filterList: [Word] = []
    @State private var inputText: String = ""
    @State private var inputFeedback: String = ""
    
    var currentWord: Word? {
        guard currentIndex < filterList.count else { return nil }
        return filterList[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Group {
                if colorScheme == .dark {
                    Color(hex: "#1a1a2e")
                } else {
                    Color(hex: "#f1ecec")
                }
            }
            .ignoresSafeArea()
            
            if isComplete {
                CongratulateView()
            } else if filterList.isEmpty {
                TooEasyView()
            } else if let word = currentWord {
                VStack(spacing: 0) {
                    // 进度条：当前题目 / 总题目数
                    if !filterList.isEmpty {
                        VStack(spacing: 4) {
                            ProgressView(
                                value: Double(currentIndex + 1),
                                total: Double(filterList.count)
                            )
                            .progressViewStyle(
                                LinearProgressViewStyle(tint: Color(hex: "#0077b6"))
                            )
                            .scaleEffect(x: 1, y: 0.5, anchor: .center)
                            
                            Text("\(currentIndex + 1)/\(filterList.count)")
                                .font(.system(size: 10))
                                .foregroundColor(Color.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 10)
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 10)
                    }
                    
                    // 问题区域
                    questionView(for: word)
                    
                    // 答案区域
                    if appState.quizMode == .spelling {
                        VStack(spacing: 8) {
                            TextField("输入英文单词", text: $inputText, onCommit: {
                                handleSpelling()
                            })
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 12)
                            
                            if !inputFeedback.isEmpty {
                                Text(inputFeedback)
                                    .font(.system(size: 12))
                                    .foregroundColor(showAnswer ? Color(hex: "#e76f51") : .green)
                            }
                        }
                        .padding(.horizontal, 10)
                    } else {
                        HStack(spacing: 5) {
                            ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                                AnswerButton(
                                    title: answer,
                                    index: index + 1,
                                    isCorrect: isCorrect(answer: answer, word: word),
                                    showAnswer: showAnswer
                                ) {
                                    handleChoice(answer)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    // 错误提示
                    if showAnswer, appState.quizMode != .spelling {
                        Text("答错了。正确答案是：\(correctAnswer(for: word))")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#e76f51"))
                            .padding(.top, 10)
                            .padding(.horizontal, 10)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            setupQuiz()
            setupKeyboardShortcuts()
        }
    }
    
    private func questionView(for word: Word) -> some View {
        let questionText: String = {
            switch appState.quizMode {
            case .cnToEn, .spelling:
                return word.tranCN
            case .enToCn:
                return word.headWord
            }
        }()
        
        return ScrollView(.horizontal, showsIndicators: false) {
            Text(questionText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#3d5a80"))
                .padding(.horizontal, 13)
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    private func setupQuiz() {
        // 过滤出未背过的单词
        filterList = appState.wordList.filter { $0.status == 0 }
        currentIndex = 0
        inputText = ""
        inputFeedback = ""
        generateAnswers()
    }
    
    private func generateAnswers() {
        guard let word = currentWord else { return }
        
        // 获取2个错误答案
        let wrongWords = DatabaseService.shared.getRandomWordsForChoice(
            count: 2,
            from: appState.currentBook,
            excluding: word.wordRank
        )
        
        var allAnswers: [String]
        switch appState.quizMode {
        case .cnToEn:
            allAnswers = wrongWords.map { $0.headWord }
            let correctIndex = Int.random(in: 0...2)
            allAnswers.insert(word.headWord, at: min(correctIndex, allAnswers.count))
        case .enToCn:
            allAnswers = wrongWords.map { $0.tranCN }
            let correctIndex = Int.random(in: 0...2)
            allAnswers.insert(word.tranCN, at: min(correctIndex, allAnswers.count))
        case .spelling:
            allAnswers = []
        }
        
        if appState.quizMode != .spelling {
            answers = Array(allAnswers.prefix(3))
        }
    }
    
    private func handleChoice(_ answer: String) {
        guard !showAnswer, let word = currentWord else { return }
        
        if isCorrect(answer: answer, word: word) {
            // 答对
            appState.updateWordStatus(wordRank: word.wordRank, status: 1)
            appState.incrementProgress()
            moveToNext()
        } else {
                // 答错，显示正确答案
            appState.recordWrongAnswer(word: word)
            showAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showAnswer = false
                moveToNext()
            }
        }
    }
    
    private func handleSpelling() {
        guard let word = currentWord else { return }
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased() == word.headWord.lowercased() {
            appState.updateWordStatus(wordRank: word.wordRank, status: 1)
            appState.incrementProgress()
            inputFeedback = "✅ 正确"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                inputText = ""
                inputFeedback = ""
                moveToNext()
            }
        } else {
            inputFeedback = "❌ 正确答案：\(word.headWord)"
            showAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showAnswer = false
                inputText = ""
                moveToNext()
            }
        }
    }
    
    private func isCorrect(answer: String, word: Word) -> Bool {
        switch appState.quizMode {
        case .cnToEn:
            return answer == word.headWord
        case .enToCn:
            return answer == word.tranCN
        case .spelling:
            return false
        }
    }
    
    private func correctAnswer(for word: Word) -> String {
        switch appState.quizMode {
        case .cnToEn: return word.headWord
        case .enToCn: return word.tranCN
        case .spelling: return word.headWord
        }
    }
    
    private func moveToNext() {
        if currentIndex >= filterList.count - 1 {
            isComplete = true
        } else {
            currentIndex += 1
            inputText = ""
            inputFeedback = ""
            generateAnswers()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let characters = event.charactersIgnoringModifiers,
               let num = Int(characters),
               num >= 1 && num <= 3,
               appState.quizMode != .spelling {
                if num <= answers.count {
                    handleChoice(answers[num - 1])
                }
                return nil
            }
            return event
        }
    }
}

// MARK: - Answer Button
struct AnswerButton: View {
    let title: String
    let index: Int
    let isCorrect: Bool
    let showAnswer: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(buttonTextColor)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .frame(minWidth: 60)
                .background(buttonBackground)
                .cornerRadius(5)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private var buttonTextColor: Color {
        if showAnswer && isCorrect {
            return .green
        }
        return isHovered ? Color(hex: "#0077b6") : Color(hex: "#3d5a80")
    }
    
    private var buttonBackground: Color {
        if showAnswer && isCorrect {
            return Color.green.opacity(0.1)
        }
        return .white
    }
}

// MARK: - Too Easy View
struct TooEasyView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("这些词对你来说太简单了")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#0077b6"))
            Text("换一些吧！")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#0077b6"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.reset()
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ChoiceView()
        .environmentObject(AppState.shared)
        .frame(width: 300, height: 150)
}
