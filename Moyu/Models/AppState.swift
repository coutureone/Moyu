import SwiftUI
import Combine
import UserNotifications

// MARK: - App State (全局状态管理)
class AppState: ObservableObject {
    static let shared = AppState()
    
    // 页面状态
    @Published var currentPage: Page = .home
    @Published var currentBook: String = "CET4_1"
    @Published var defaultWordCount: Int = 20 {
        didSet {
            UserDefaults.standard.set(defaultWordCount, forKey: "defaultWordCount")
        }
    }
    @Published var wordList: [Word] = []
    @Published var currentIndex: Int = 0
    
    // 新增：主题设置
    @Published var appTheme: AppTheme = .system {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme")
            applyTheme()
        }
    }
    
    // 新增：测试模式
    @Published var quizMode: QuizMode = .cnToEn {
        didSet {
            UserDefaults.standard.set(quizMode.rawValue, forKey: "quizMode")
        }
    }
    
    // 新增：学习统计
    @Published var statistics: LearningStatistics = LearningStatistics()
    
    // 新增：提醒设置
    @Published var reminderEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
            if reminderEnabled {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date() {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
            if reminderEnabled {
                scheduleReminder()
            }
        }
    }
    
    // 新增：学习计时
    private var learningStartTime: Date?
    @Published var todayLearningDuration: Int = 0
    
    // 新增：每日目标
    @Published var dailyGoal: Int = 50 {
        didSet {
            UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        }
    }
    
    // 新增：TTS语速 (0.1 - 1.0)
    @Published var ttsSpeed: Double = 0.4 {
        didSet {
            UserDefaults.standard.set(ttsSpeed, forKey: "ttsSpeed")
        }
    }
    
    // 新增：窗口尺寸记忆
    @Published var windowWidth: CGFloat = 320 {
        didSet {
            UserDefaults.standard.set(windowWidth, forKey: "windowWidth")
        }
    }
    @Published var windowHeight: CGFloat = 200 {
        didSet {
            UserDefaults.standard.set(windowHeight, forKey: "windowHeight")
        }
    }
    
    // 新增：今日是否完成目标
    var isDailyGoalCompleted: Bool {
        statistics.todayLearned >= dailyGoal
    }
    
    private init() {
        loadSettings()
        loadStatistics()
        requestNotificationPermission()
    }
    
    // MARK: - Settings
    
    func loadSettings() {
        if let savedBook = UserDefaults.standard.string(forKey: "currentBook") {
            currentBook = savedBook
        }
        defaultWordCount = UserDefaults.standard.integer(forKey: "defaultWordCount")
        if defaultWordCount == 0 {
            defaultWordCount = 20
        }
        
        // 加载主题设置
        if let themeRaw = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeRaw) {
            appTheme = theme
        }
        
        // 加载测试模式
        if let modeRaw = UserDefaults.standard.string(forKey: "quizMode"),
           let mode = QuizMode(rawValue: modeRaw) {
            quizMode = mode
        }
        
        // 加载提醒设置
        reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
        if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            reminderTime = savedTime
        }
        
        // 加载每日目标
        let savedGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        dailyGoal = savedGoal > 0 ? savedGoal : 50
        
        // 加载TTS语速
        let savedSpeed = UserDefaults.standard.double(forKey: "ttsSpeed")
        ttsSpeed = savedSpeed > 0 ? savedSpeed : 0.4
        
        // 加载窗口尺寸
        let savedWidth = UserDefaults.standard.double(forKey: "windowWidth")
        let savedHeight = UserDefaults.standard.double(forKey: "windowHeight")
        windowWidth = savedWidth > 0 ? CGFloat(savedWidth) : 320
        windowHeight = savedHeight > 0 ? CGFloat(savedHeight) : 200
        
        // 从数据库同步
        let (book, count) = DatabaseService.shared.getGlobalSettings()
        currentBook = book
        defaultWordCount = count
        
        applyTheme()
    }
    
    func loadStatistics() {
        statistics = DatabaseService.shared.getStatistics()
        todayLearningDuration = DatabaseService.shared.getTodayLearningDuration()
    }
    
    // MARK: - Theme
    
    func applyTheme() {
        DispatchQueue.main.async {
            switch self.appTheme {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
    
    // MARK: - Word List
    
    func createWordList(count: Int) {
        wordList = DatabaseService.shared.getRandomWords(count: count, from: currentBook)
        currentIndex = 0
        startLearning()
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
    
    // MARK: - Learning Timer
    
    func startLearning() {
        learningStartTime = Date()
    }
    
    func endLearning() {
        guard let startTime = learningStartTime else { return }
        let duration = Int(Date().timeIntervalSince(startTime))
        DatabaseService.shared.addLearningDuration(duration)
        todayLearningDuration += duration
        learningStartTime = nil
    }
    
    // MARK: - Statistics
    
    func recordCorrectAnswer() {
        DatabaseService.shared.recordAnswer(isCorrect: true)
        statistics.todayCorrect += 1
        statistics.todayLearned += 1
    }
    
    func recordWrongAnswer(word: Word) {
        DatabaseService.shared.recordAnswer(isCorrect: false)
        DatabaseService.shared.addToWrongBook(word: word, book: currentBook)
        statistics.todayWrong += 1
    }
    
    // MARK: - Favorites
    
    func toggleFavorite(word: Word) {
        let newState = !word.isFavorite
        DatabaseService.shared.updateFavoriteStatus(wordRank: word.wordRank, isFavorite: newState, in: currentBook)
        
        if let index = wordList.firstIndex(where: { $0.wordRank == word.wordRank }) {
            wordList[index].isFavorite = newState
        }
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知权限已获取")
            }
        }
    }
    
    func scheduleReminder() {
        cancelReminder()
        
        let content = UNMutableNotificationContent()
        content.title = "📚 该背单词了"
        content.body = "今天的单词还没背完哦，快来学习吧！"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "moyuReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["moyuReminder"])
    }
    
    // MARK: - Reset
    
    func reset() {
        endLearning()
        currentPage = .home
        currentIndex = 0
        wordList = []
        loadStatistics()
    }
    
    func resetBookProgress(book: String) {
        DatabaseService.shared.resetProgress(for: book)
    }
}

// MARK: - Page Enum
enum Page: Hashable {
    case home
    case remember
    case choice
    case congratulate
    case wrongBook      // 新增：错词本
    case favorites      // 新增：收藏夹
    case statistics     // 新增：统计页面
    case settings       // 新增：设置页面
}
