import SwiftUI
import Combine
import UserNotifications
import AppKit

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
    @Published var windowWidth: CGFloat = 380 {
        didSet {
            UserDefaults.standard.set(windowWidth, forKey: "windowWidth")
        }
    }
    @Published var windowHeight: CGFloat = 320 {
        didSet {
            UserDefaults.standard.set(windowHeight, forKey: "windowHeight")
        }
    }

    @Published var compactMode: Bool = false {
        didSet {
            UserDefaults.standard.set(compactMode, forKey: "compactMode")
            applyWindowPreferences()
        }
    }

    @Published var pinToCorner: Bool = true {
        didSet {
            UserDefaults.standard.set(pinToCorner, forKey: "pinToCorner")
            applyWindowPreferences()
        }
    }

    @Published var windowOpacity: Double = 1.0 {
        didSet {
            let clamped = min(max(windowOpacity, 0.35), 1.0)
            if clamped != windowOpacity {
                windowOpacity = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: "windowOpacity")
            applyWindowPreferences()
        }
    }

    @Published var stealthShortcut: StealthShortcut = .moyuM {
        didSet {
            UserDefaults.standard.set(stealthShortcut.rawValue, forKey: "stealthShortcut")
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
        windowWidth = savedWidth > 0 ? CGFloat(savedWidth) : 380
        windowHeight = savedHeight > 0 ? CGFloat(savedHeight) : 320

        compactMode = UserDefaults.standard.bool(forKey: "compactMode")
        pinToCorner = UserDefaults.standard.object(forKey: "pinToCorner") as? Bool ?? true
        let savedOpacity = UserDefaults.standard.double(forKey: "windowOpacity")
        windowOpacity = savedOpacity > 0 ? min(max(savedOpacity, 0.35), 1.0) : 1.0
        if let shortcutRaw = UserDefaults.standard.string(forKey: "stealthShortcut"),
           let shortcut = StealthShortcut(rawValue: shortcutRaw) {
            stealthShortcut = shortcut
        }
        
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

    func setCurrentBook(_ book: String) {
        currentBook = book
        UserDefaults.standard.set(book, forKey: "currentBook")
        DatabaseService.shared.updateCurrentBook(book)
    }

    func setDefaultWordCount(_ count: Int) {
        defaultWordCount = count
        DatabaseService.shared.updateWordCount(count)
    }
    
    // MARK: - Theme
    
    func applyTheme() {
        DispatchQueue.main.async {
            let appearance: NSAppearance?
            switch self.appTheme {
            case .system:
                appearance = nil
            case .light:
                appearance = NSAppearance(named: .aqua)
            case .dark:
                appearance = NSAppearance(named: .darkAqua)
            }
            NSApp.appearance = appearance
            NSApp.windows.forEach { window in
                window.appearance = appearance
                window.contentView?.needsDisplay = true
            }
        }
    }

    func applyWindowPreferences() {
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.alphaValue = min(max(self.windowOpacity, 0.35), 1.0)
                window.level = .floating

                if self.compactMode {
                    window.setContentSize(NSSize(width: 340, height: 240))
                } else if window.frame.width < 380 || window.frame.height < 320 {
                    window.setContentSize(NSSize(width: 380, height: 320))
                }

                if self.pinToCorner, let screen = window.screen ?? NSScreen.main {
                    let screenRect = screen.visibleFrame
                    let x = screenRect.maxX - window.frame.width
                    let y = screenRect.maxY - window.frame.height
                    window.setFrameOrigin(NSPoint(x: x, y: y))
                }
            }
        }
    }
    
    // MARK: - Word List
    
    func createWordList(count: Int) {
        wordList = DatabaseService.shared.getRandomWords(count: count, from: currentBook)
        currentIndex = 0
        startLearning()
    }
    
    func bookName(for word: Word) -> String {
        if let bookName = word.bookName, !bookName.isEmpty {
            return bookName
        }
        return currentBook
    }

    func updateWordStatus(wordRank: Int, status: Int, in book: String? = nil) {
        let targetBook = book ?? currentBook
        DatabaseService.shared.updateWordStatus(wordRank: wordRank, status: status, in: targetBook)
        
        // 更新本地列表状态
        if let index = wordList.firstIndex(where: { $0.wordRank == wordRank && (bookName(for: $0) == targetBook || $0.bookName == nil) }) {
            wordList[index].status = status
        }
    }
    
    func incrementProgress(for book: String? = nil) {
        DatabaseService.shared.incrementProgress(for: book ?? currentBook)
    }

    func markWordLearned(_ word: Word, recordCorrect: Bool) {
        let targetBook = bookName(for: word)
        let currentStatus = DatabaseService.shared.getWordStatus(wordRank: word.wordRank, in: targetBook) ?? wordList.first {
            $0.wordRank == word.wordRank && bookName(for: $0) == targetBook
        }?.status ?? word.status

        if currentStatus != 1 {
            updateWordStatus(wordRank: word.wordRank, status: 1, in: targetBook)
            incrementProgress(for: targetBook)
        } else if let index = wordList.firstIndex(where: { $0.wordRank == word.wordRank && bookName(for: $0) == targetBook }) {
            wordList[index].status = 1
        }

        if recordCorrect {
            recordCorrectAnswer()
        }
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
        DatabaseService.shared.checkLearningAchievements()
        statistics.todayCorrect += 1
        statistics.todayLearned += 1
    }
    
    func recordWrongAnswer(word: Word) {
        let targetBook = bookName(for: word)
        DatabaseService.shared.recordAnswer(isCorrect: false)
        DatabaseService.shared.addToWrongBook(word: word, book: targetBook)
        DatabaseService.shared.checkLearningAchievements()
        statistics.todayWrong += 1
    }
    
    // MARK: - Favorites
    
    func toggleFavorite(word: Word) {
        let targetBook = bookName(for: word)
        let newState = !word.isFavorite
        DatabaseService.shared.updateFavoriteStatus(wordRank: word.wordRank, isFavorite: newState, in: targetBook)
        
        if let index = wordList.firstIndex(where: { $0.wordRank == word.wordRank && bookName(for: $0) == targetBook }) {
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
    case practiceSession(words: [Word], source: PracticeSource)  // 新增：练习模式

    static func == (lhs: Page, rhs: Page) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home),
             (.remember, .remember),
             (.choice, .choice),
             (.congratulate, .congratulate),
             (.wrongBook, .wrongBook),
             (.favorites, .favorites),
             (.statistics, .statistics),
             (.settings, .settings):
            return true
        case (.practiceSession, .practiceSession):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine("home")
        case .remember:
            hasher.combine("remember")
        case .choice:
            hasher.combine("choice")
        case .congratulate:
            hasher.combine("congratulate")
        case .wrongBook:
            hasher.combine("wrongBook")
        case .favorites:
            hasher.combine("favorites")
        case .statistics:
            hasher.combine("statistics")
        case .settings:
            hasher.combine("settings")
        case .practiceSession:
            hasher.combine("practiceSession")
        }
    }
}

// MARK: - Practice Source Enum
enum PracticeSource {
    case wrongBook
    case favorites
}

enum StealthShortcut: String, CaseIterable {
    case moyuM = "moyu_m"
    case space = "space"
    case controlOption = "control_option"

    var displayName: String {
        switch self {
        case .moyuM: return "Cmd+Shift+M / Cmd+M"
        case .space: return "Cmd+Shift+Space / Cmd+Option+Space"
        case .controlOption: return "Ctrl+Option+M / Ctrl+Option+H"
        }
    }

    var wakeLabel: String {
        switch self {
        case .moyuM: return "Cmd+Shift+M"
        case .space: return "Cmd+Shift+Space"
        case .controlOption: return "Ctrl+Option+M"
        }
    }

    var hideLabel: String {
        switch self {
        case .moyuM: return "Cmd+M"
        case .space: return "Cmd+Option+Space"
        case .controlOption: return "Ctrl+Option+H"
        }
    }

    var wakeKey: String {
        switch self {
        case .moyuM, .controlOption: return "m"
        case .space: return " "
        }
    }

    var hideKey: String {
        switch self {
        case .moyuM: return "m"
        case .space: return " "
        case .controlOption: return "h"
        }
    }

    var wakeModifiers: NSEvent.ModifierFlags {
        switch self {
        case .moyuM, .space: return [.command, .shift]
        case .controlOption: return [.control, .option]
        }
    }

    var hideModifiers: NSEvent.ModifierFlags {
        switch self {
        case .moyuM: return [.command]
        case .space: return [.command, .option]
        case .controlOption: return [.control, .option]
        }
    }

    func matches(chars: String, modifiers: NSEvent.ModifierFlags, wake: Bool) -> Bool {
        let key = wake ? wakeKey : hideKey
        let expected = wake ? wakeModifiers : hideModifiers
        let active = modifiers.intersection([.command, .shift, .option, .control])
        return chars == key && active == expected
    }
}
