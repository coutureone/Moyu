import SwiftUI
import AVFoundation

// MARK: - Remember View (记忆页面)
struct RememberView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var keyboardMonitor: Any?
    
    var currentWord: Word? {
        guard appState.currentIndex < appState.wordList.count else { return nil }
        return appState.wordList[appState.currentIndex]
    }
    
    var body: some View {
        VStack(spacing: 10) {
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
                let bookName = appState.bookName(for: word)
                // 根据词书类型显示不同内容
                if bookName == "Goin" {
                    GoinRememberContent(word: word, onAction: handleAction, onSpeak: speakWord, onFavorite: toggleFavorite)
                } else if bookName == "StdJp_Mid" {
                    JapaneseRememberContent(word: word, onAction: handleAction, onSpeak: speakJapanese, onFavorite: toggleFavorite)
                } else {
                    EnglishRememberContent(word: word, onAction: handleAction, onSpeak: speakWord, onFavorite: toggleFavorite)
                }
            } else {
                Text("没有更多单词了")
                    .foregroundColor(Color(hex: "#3d5a80"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .background(MoyuTheme.appBackground(colorScheme))
        .onAppear {
            setupKeyboardShortcuts()
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
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

    private func removeKeyboardShortcuts() {
        if let keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
            self.keyboardMonitor = nil
        }
    }
    
    private func toggleFavorite() {
        guard let word = currentWord else { return }
        appState.toggleFavorite(word: word)
    }
    
    private func handleAction(tooEasy: Bool) {
        if tooEasy, let word = currentWord {
            appState.markWordLearned(word, recordCorrect: true)
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
        utterance.rate = Float(appState.ttsSpeed)
        synthesizer.speak(utterance)
    }
    
    private func speakJapanese() {
        guard let word = currentWord else { return }
        let utterance = AVSpeechUtterance(string: word.headWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = Float(appState.ttsSpeed)
        synthesizer.speak(utterance)
    }
}

// MARK: - English Remember Content
struct EnglishRememberContent: View {
    let word: Word
    let onAction: (Bool) -> Void
    let onSpeak: () -> Void
    let onFavorite: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(word.headWord)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(MoyuTheme.textColor(colorScheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        if !word.usphone.isEmpty {
                            Text("[\(word.usphone)]")
                                .font(.system(size: 13, weight: .medium).italic())
                                .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                        }
                    }

                    Spacer()

                    Button(action: onFavorite) {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(word.isFavorite ? MoyuTheme.warning : MoyuTheme.secondaryTextColor(colorScheme))
                            .frame(width: 32, height: 32)
                            .background((word.isFavorite ? MoyuTheme.warning : MoyuTheme.secondaryTextColor(colorScheme)).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onHoverCursor()
                }
                
                Text(word.tranCN)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MoyuTheme.textColor(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
                
                if !word.phrase.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(word.phrase)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(word.phraseCN)
                            .font(.system(size: 13))
                            .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(MoyuTheme.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .moyuCard(colorScheme)

            Spacer()
            
            HStack(spacing: 8) {
                ActionButton(title: "记住了", icon: "checkmark") {
                    onAction(false)
                }
                
                ActionButton(title: "太简单", icon: "bolt.fill", tone: MoyuTheme.warning) {
                    onAction(true)
                }
                
                ActionButton(title: "发音", icon: "speaker.wave.2", tone: MoyuTheme.primary) {
                    onSpeak()
                }
            }
        }
    }
}

// MARK: - Goin (五十音) Remember Content
struct GoinRememberContent: View {
    let word: Word
    let onAction: (Bool) -> Void
    let onSpeak: () -> Void
    let onFavorite: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.hiragana ?? "")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(MoyuTheme.textColor(colorScheme))
                        Text("片假名 \(word.katakana ?? "")")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                        Text("罗马音 \(word.romaji ?? "")")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                    }

                    Spacer()
                    
                    Button(action: onFavorite) {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(word.isFavorite ? MoyuTheme.warning : MoyuTheme.secondaryTextColor(colorScheme))
                            .frame(width: 32, height: 32)
                            .background((word.isFavorite ? MoyuTheme.warning : MoyuTheme.secondaryTextColor(colorScheme)).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onHoverCursor()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .moyuCard(colorScheme)
            
            Spacer()
            
            HStack(spacing: 8) {
                ActionButton(title: "记住了", icon: "checkmark") {
                    onAction(false)
                }
                
                ActionButton(title: "发音", icon: "speaker.wave.2", tone: MoyuTheme.primary) {
                    onSpeak()
                }
            }
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
    let icon: String
    var tone: Color = MoyuTheme.accent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(MoyuSecondaryButtonStyle(tone: tone))
        .onHoverCursor()
    }
}

#Preview {
    RememberView()
        .environmentObject(AppState.shared)
        .frame(width: 300, height: 150)
        .background(Color(hex: "#d7e1ec"))
}
