import Foundation

// MARK: - Word Model (单词模型)
struct Word: Identifiable, Equatable, Hashable {
    var id: Int { wordRank }
    
    let wordRank: Int
    let headWord: String
    let tranCN: String
    let usphone: String
    let phrase: String
    let phraseCN: String
    var status: Int  // 0: 未背过, 1: 已背过
    
    // 日语五十音专用
    let hiragana: String?
    let katakana: String?
    let romaji: String?
    
    // 新增：收藏和错词状态
    var isFavorite: Bool
    var wrongCount: Int  // 答错次数
    var lastWrongDate: Date?  // 最后答错日期
    var bookName: String?     // 所属词书（自定义/错词本等需要）
    
    init(wordRank: Int, 
         headWord: String, 
         tranCN: String, 
         usphone: String = "", 
         phrase: String = "", 
         phraseCN: String = "", 
         status: Int = 0,
         hiragana: String? = nil,
         katakana: String? = nil,
         romaji: String? = nil,
         isFavorite: Bool = false,
         wrongCount: Int = 0,
         lastWrongDate: Date? = nil,
         bookName: String? = nil) {
        self.wordRank = wordRank
        self.headWord = headWord
        self.tranCN = tranCN
        self.usphone = usphone
        self.phrase = phrase
        self.phraseCN = phraseCN
        self.status = status
        self.hiragana = hiragana
        self.katakana = katakana
        self.romaji = romaji
        self.isFavorite = isFavorite
        self.wrongCount = wrongCount
        self.lastWrongDate = lastWrongDate
        self.bookName = bookName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wordRank)
        hasher.combine(headWord)
    }
}

// MARK: - Word Import DTO (用于自定义词库导入)
struct WordImport {
    let headWord: String
    let tranCN: String
    let usphone: String
    let phrase: String
    let phraseCN: String
}

// MARK: - Progress Model (进度模型)
struct BookProgress {
    let bookName: String
    let current: Int
    let total: Int
}

// MARK: - Learning Statistics (学习统计模型)
struct LearningStatistics {
    var todayLearned: Int = 0
    var todayCorrect: Int = 0
    var todayWrong: Int = 0
    var totalLearned: Int = 0
    var totalDays: Int = 0
    var streakDays: Int = 0
    var lastLearnDate: Date?
    
    var todayAccuracy: Double {
        let total = todayCorrect + todayWrong
        guard total > 0 else { return 0 }
        return Double(todayCorrect) / Double(total) * 100
    }
}

// MARK: - Daily Record (每日记录模型)
struct DailyRecord: Identifiable {
    var id: String { dateString }
    let dateString: String
    let learnedCount: Int
    let correctCount: Int
    let wrongCount: Int
    let duration: Int  // 学习时长（秒）
}

// MARK: - Achievement (成就模型)
struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
}

// MARK: - Book Info (词库信息)
struct BookInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let current: Int
    let total: Int
    let isCustom: Bool
}

// MARK: - Theme (主题模型)
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Quiz Mode (测试模式)
enum QuizMode: String, CaseIterable {
    case cnToEn = "cn_to_en"   // 看中文选英文
    case enToCn = "en_to_cn"   // 看英文选中文
    case spelling = "spelling"  // 拼写模式
    
    var displayName: String {
        switch self {
        case .cnToEn: return "中文选英文"
        case .enToCn: return "英文选中文"
        case .spelling: return "拼写模式"
        }
    }
}
