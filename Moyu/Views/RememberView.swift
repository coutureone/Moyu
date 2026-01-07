import SwiftUI
import AVFoundation

// MARK: - Remember View (记忆页面)
struct RememberView: View {
    @EnvironmentObject var appState: AppState
    @State private var synthesizer = AVSpeechSynthesizer()
    
    var currentWord: Word? {
        guard appState.currentIndex < appState.wordList.count else { return nil }
        return appState.wordList[appState.currentIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 进度条
            if !appState.wordList.isEmpty {
                VStack(spacing: 4) {
                    ProgressView(value: Double(appState.currentIndex + 1), total: Double(appState.wordList.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#0077b6")))
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                    
                    Text("\(appState.currentIndex + 1)/\(appState.wordList.count)")
                        .font(.system(size: 10))
                        .foregroundColor(Color.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 4)
                .padding(.horizontal, 10)
            }

            if let word = currentWord {
                // 根据词书类型显示不同内容
                if appState.currentBook == "Goin" {
                    GoinRememberContent(word: word, onAction: handleAction, onSpeak: speakWord, onFavorite: toggleFavorite)
                } else if appState.currentBook == "StdJp_Mid" {
                    JapaneseRememberContent(word: word, onAction: handleAction, onSpeak: speakJapanese, onFavorite: toggleFavorite)
                } else {
                    EnglishRememberContent(word: word, onAction: handleAction, onSpeak: speakWord, onFavorite: toggleFavorite)
                }
            } else {
                Text("没有更多单词了")
                    .foregroundColor(Color(hex: "#3d5a80"))
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let characters = event.charactersIgnoringModifiers {
                switch characters {
                case "1":
                    handleAction(tooEasy: false)
                    return nil
                case "2":
                    handleAction(tooEasy: true)
                    return nil
                case "3":
                    speakWord()
                    return nil
                case "4":
                    toggleFavorite()
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }
    
    private func toggleFavorite() {
        guard let word = currentWord else { return }
        appState.toggleFavorite(word: word)
    }
    
    private func handleAction(tooEasy: Bool) {
        if tooEasy, let word = currentWord {
            appState.updateWordStatus(wordRank: word.wordRank, status: 1)
            appState.incrementProgress()
        }
        
        if appState.currentIndex >= appState.wordList.count - 1 {
            // 进入选择题页面
            appState.currentPage = .choice
        } else {
            appState.currentIndex += 1
        }
    }
    
    private func speakWord() {
        guard let word = currentWord else { return }
        let utterance = AVSpeechUtterance(string: word.headWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    
    private func speakJapanese() {
        guard let word = currentWord else { return }
        let utterance = AVSpeechUtterance(string: word.headWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}

// MARK: - English Remember Content
struct EnglishRememberContent: View {
    let word: Word
    let onAction: (Bool) -> Void
    let onSpeak: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 单词信息
            VStack(alignment: .leading, spacing: 2) {
                // 单词和音标
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(word.headWord)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#3d5a80"))
                        
                        // 收藏星标
                        Button(action: onFavorite) {
                            Image(systemName: word.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 13))
                                .foregroundColor(word.isFavorite ? Color(hex: "#f4a261") : Color(hex: "#adb5bd"))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("[\(word.usphone)]")
                        .font(.system(size: 12, weight: .light).italic())
                        .foregroundColor(Color(hex: "#3d5a80"))
                }
                
                // 中文释义
                Text(word.tranCN)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#3d5a80"))
                    .lineLimit(1)
                
                // 例句
                if !word.phrase.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(word.phrase)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#778da9"))
                            .lineLimit(1)
                        Text(word.phraseCN)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#778da9"))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 15) {
                ActionButton(title: "记住了", color: Color(hex: "#3d5a80")) {
                    onAction(false)
                }
                
                ActionButton(title: "太简单", color: Color(hex: "#3d5a80")) {
                    onAction(true)
                }
                
                ActionButton(title: "发音", color: Color(hex: "#3d5a80")) {
                    onSpeak()
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Goin (五十音) Remember Content
struct GoinRememberContent: View {
    let word: Word
    let onAction: (Bool) -> Void
    let onSpeak: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("平假名：[\(word.hiragana ?? "")]")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#3d5a80"))
                    
                    Button(action: onFavorite) {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundColor(word.isFavorite ? Color(hex: "#f4a261") : Color(hex: "#adb5bd"))
                    }
                    .buttonStyle(.plain)
                }
                
                Text("片假名：[\(word.katakana ?? "")]")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#3d5a80"))
                
                Text("罗马音：[\(word.romaji ?? "")]")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#3d5a80"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            Spacer()
            
            HStack(spacing: 20) {
                ActionButton(title: "记住了", color: Color(hex: "#3d5a80")) {
                    onAction(false)
                }
                
                ActionButton(title: "发音", color: Color(hex: "#3d5a80")) {
                    onSpeak()
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Japanese Remember Content
struct JapaneseRememberContent: View {
    let word: Word
    let onAction: (Bool) -> Void
    let onSpeak: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        EnglishRememberContent(word: word, onAction: onAction, onSpeak: onSpeak, onFavorite: onFavorite)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(isHovered ? Color(hex: "#0077b6") : color)
                .frame(width: 80, height: 32)
                .background(Color.white)
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
}

#Preview {
    RememberView()
        .environmentObject(AppState.shared)
        .frame(width: 300, height: 150)
        .background(Color(hex: "#d7e1ec"))
}
