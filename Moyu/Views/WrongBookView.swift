import SwiftUI

import AVFoundation

// MARK: - Wrong Book View (错词本页面)
struct WrongBookView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var wrongWords: [Word] = []
    @State private var selectedWord: Word?
    @State private var synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerBar
            
            if wrongWords.isEmpty {
                emptyState
            } else {
                // 单词列表
                wordList
            }
            
            // 底部按钮
            bottomBar
        }
        .background(backgroundColor)
        .onAppear {
            loadWords()
        }
    }
    
    // MARK: - Components
    
    private var backgroundColor: Color {
        MoyuTheme.appBackground(colorScheme)
    }
    
    private var cardBackground: Color {
        MoyuTheme.cardBackground(colorScheme)
    }
    
    private var textColor: Color {
        MoyuTheme.textColor(colorScheme)
    }
    
    private var headerBar: some View {
        HStack {
            Text("📕 错词本")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(textColor)
            Spacer()
            Text("\(wrongWords.count) 词")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(cardBackground.opacity(0.8))
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("🎉")
                .font(.system(size: 40))
            Text("太棒了！没有错词")
                .font(.system(size: 14))
                .foregroundColor(textColor)
            Text("继续保持！")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var wordList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(wrongWords, id: \.self) { word in
                    WrongWordCard(
                        word: word,
                        isSelected: selectedWord?.wordRank == word.wordRank,
                        onTap: { selectedWord = word },
                        onSpeak: { speakWord(word) },
                        onRemove: { removeWord(word) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(action: { appState.currentPage = .home }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("返回")
                }
                .font(.system(size: 13))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(cardBackground)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .onHoverCursor()
            
            if !wrongWords.isEmpty {
                Button(action: startReview) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("复习")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(MoyuTheme.danger)
                    .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous))
                }
                .buttonStyle(.plain)
                .onHoverCursor()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(cardBackground.opacity(0.8))
    }
    
    // MARK: - Actions
    
    private func loadWords() {
        wrongWords = DatabaseService.shared.getWrongBookWords()
    }
    
    private func speakWord(_ word: Word) {
        let utterance = AVSpeechUtterance(string: word.headWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    
    private func removeWord(_ word: Word) {
        DatabaseService.shared.removeFromWrongBook(wordRank: word.wordRank, book: appState.bookName(for: word))
        loadWords()
    }
    
    private func startReview() {
        // 使用新的练习模式
        appState.currentPage = .practiceSession(words: wrongWords, source: .wrongBook)
    }
}

// MARK: - Wrong Word Card
struct WrongWordCard: View {
    let word: Word
    let isSelected: Bool
    let onTap: () -> Void
    let onSpeak: () -> Void
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(word.headWord)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoyuTheme.textColor(colorScheme))
                
                if !word.usphone.isEmpty {
                    Text("[\(word.usphone)]")
                        .font(.system(size: 11, weight: .light).italic())
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 错误次数
                HStack(spacing: 2) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                    Text("\(word.wrongCount)")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: "#e76f51"))
            }
            
            Text(word.tranCN)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .lineLimit(isSelected ? nil : 1)
            
            if isSelected {
                HStack(spacing: 10) {
                    Button(action: onSpeak) {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2")
                            Text("发音")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#0077b6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#0077b6").opacity(0.1))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onRemove) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("移除")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#e76f51"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#e76f51").opacity(0.1))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(
            MoyuTheme.cardBackground(colorScheme)
                .opacity(isHovered ? 0.9 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous)
                .stroke(MoyuTheme.border(colorScheme), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
