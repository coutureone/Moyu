import SwiftUI
import Combine

// MARK: - App State (全局状态管理)
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentPage: Page = .home
    @Published var currentBook: String = "CET4_1"
    @Published var defaultWordCount: Int = 20
    @Published var wordList: [Word] = []
    @Published var currentIndex: Int = 0
    
    private init() {
        // 从数据库加载设置
        loadSettings()
    }
    
    func loadSettings() {
        if let savedBook = UserDefaults.standard.string(forKey: "currentBook") {
            currentBook = savedBook
        }
        defaultWordCount = UserDefaults.standard.integer(forKey: "defaultWordCount")
        if defaultWordCount == 0 {
            defaultWordCount = 20
        }
        
        // 从数据库同步
        let (book, count) = DatabaseService.shared.getGlobalSettings()
        currentBook = book
        defaultWordCount = count
    }
    
    func createWordList(count: Int) {
        wordList = DatabaseService.shared.getRandomWords(count: count, from: currentBook)
        currentIndex = 0
    }
    
    func updateWordStatus(wordRank: Int, status: Int) {
        DatabaseService.shared.updateWordStatus(wordRank: wordRank, status: status, in: currentBook)
        
        // 更新本地列表状态
        if let index = wordList.firstIndex(where: { $0.wordRank == wordRank }) {
            wordList[index].status = status
        }
    }
    
    func incrementProgress() {
        DatabaseService.shared.incrementProgress(for: currentBook)
    }
    
    func reset() {
        currentPage = .home
        currentIndex = 0
        wordList = []
    }
}

// MARK: - Page Enum
enum Page: Hashable {
    case home
    case remember
    case choice
    case congratulate
}
