import SwiftUI

// MARK: - Choice View (选择题页面)
struct ChoiceView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    @State private var answers: [String] = []
    @State private var showAnswer = false
    @State private var isComplete = false
    @State private var filterList: [Word] = []
    
    var currentWord: Word? {
        guard currentIndex < filterList.count else { return nil }
        return filterList[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#f1ecec")
                .ignoresSafeArea()
            
            if isComplete {
                CongratulateView()
            } else if filterList.isEmpty {
                TooEasyView()
            } else if let word = currentWord {
                VStack(spacing: 0) {
                    // 问题 (中文释义)
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(word.tranCN)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#3d5a80"))
                            .padding(.horizontal, 13)
                    }
                    .frame(height: 55)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    
                    // 答案选项
                    HStack(spacing: 5) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                            AnswerButton(
                                title: answer,
                                index: index + 1,
                                isCorrect: answer == word.headWord,
                                showAnswer: showAnswer
                            ) {
                                handleAnswer(answer)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    
                    // 错误提示
                    if showAnswer {
                        Text("答错了。正确答案是：\(word.headWord)")
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
    
    private func setupQuiz() {
        // 过滤出未背过的单词
        filterList = appState.wordList.filter { $0.status == 0 }
        currentIndex = 0
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
        
        // 创建答案数组并打乱
        var allAnswers = wrongWords.map { $0.headWord }
        let correctIndex = Int.random(in: 0...2)
        allAnswers.insert(word.headWord, at: min(correctIndex, allAnswers.count))
        
        // 确保只有3个答案
        answers = Array(allAnswers.prefix(3))
    }
    
    private func handleAnswer(_ answer: String) {
        guard !showAnswer, let word = currentWord else { return }
        
        if answer == word.headWord {
            // 答对
            appState.updateWordStatus(wordRank: word.wordRank, status: 1)
            appState.incrementProgress()
            moveToNext()
        } else {
            // 答错，显示正确答案
            showAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showAnswer = false
                moveToNext()
            }
        }
    }
    
    private func moveToNext() {
        if currentIndex >= filterList.count - 1 {
            isComplete = true
        } else {
            currentIndex += 1
            generateAnswers()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let characters = event.charactersIgnoringModifiers,
               let num = Int(characters),
               num >= 1 && num <= 3 {
                if num <= answers.count {
                    handleAnswer(answers[num - 1])
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
