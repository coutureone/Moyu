import Foundation

// MARK: - Spaced Repetition Algorithm (间隔重复算法)
class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()

    private init() {}

    /// 计算下次复习时间（基于 SM-2 算法简化版）
    /// - Parameters:
    ///   - quality: 回答质量 (0-5)，0=完全忘记，5=完美记忆
    ///   - repetitions: 已复习次数
    ///   - easeFactor: 难度系数（默认2.5）
    ///   - interval: 当前间隔天数
    /// - Returns: (新的间隔天数, 新的难度系数, 新的复习次数)
    func calculateNextReview(
        quality: Int,
        repetitions: Int,
        easeFactor: Double,
        interval: Int
    ) -> (interval: Int, easeFactor: Double, repetitions: Int) {

        var newEaseFactor = easeFactor
        var newInterval = interval
        var newRepetitions = repetitions

        // 根据回答质量调整难度系数
        if quality >= 3 {
            // 回答正确
            newRepetitions += 1

            // 计算新的间隔
            switch newRepetitions {
            case 1:
                newInterval = 1  // 第一次：1天后
            case 2:
                newInterval = 6  // 第二次：6天后
            default:
                newInterval = Int(Double(interval) * newEaseFactor)
            }

            // 更新难度系数
            newEaseFactor = max(1.3, easeFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)))

        } else {
            // 回答错误，重新开始
            newRepetitions = 0
            newInterval = 1
            newEaseFactor = max(1.3, easeFactor - 0.2)
        }

        return (newInterval, newEaseFactor, newRepetitions)
    }

    /// 获取今天需要复习的单词数量
    func getDueWordsCount(for bookName: String) -> Int {
        // 这里可以实现从数据库查询到期单词的逻辑
        return 0
    }

    /// 判断单词是否需要复习
    func isDueForReview(lastReviewDate: Date, interval: Int) -> Bool {
        let dueDate = Calendar.current.date(byAdding: .day, value: interval, to: lastReviewDate) ?? Date()
        return Date() >= dueDate
    }
}

// MARK: - Learning Strategy (学习策略)
enum LearningStrategy {
    case newWords         // 新单词
    case review           // 复习
    case wrongWords       // 错词复习
    case favorites        // 收藏复习
    case mixed            // 混合模式

    var displayName: String {
        switch self {
        case .newWords: return "学习新词"
        case .review: return "定期复习"
        case .wrongWords: return "错词强化"
        case .favorites: return "收藏复习"
        case .mixed: return "混合练习"
        }
    }

    var icon: String {
        switch self {
        case .newWords: return "sparkles"
        case .review: return "arrow.clockwise"
        case .wrongWords: return "exclamationmark.triangle"
        case .favorites: return "star.fill"
        case .mixed: return "shuffle"
        }
    }
}

// MARK: - Word Review Info (单词复习信息)
struct WordReviewInfo {
    let wordRank: Int
    let bookName: String
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    var repetitions: Int = 0
    var easeFactor: Double = 2.5
    var interval: Int = 0

    var isDue: Bool {
        guard let nextDate = nextReviewDate else { return true }
        return Date() >= nextDate
    }

    var daysUntilReview: Int {
        guard let nextDate = nextReviewDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
        return max(0, days)
    }
}

// MARK: - Study Session Statistics (学习会话统计)
struct StudySessionStats {
    var wordsLearned: Int = 0
    var wordsReviewed: Int = 0
    var correctAnswers: Int = 0
    var wrongAnswers: Int = 0
    var startTime: Date
    var endTime: Date?

    var duration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }

    var accuracy: Double {
        let total = correctAnswers + wrongAnswers
        guard total > 0 else { return 0 }
        return Double(correctAnswers) / Double(total) * 100
    }

    var totalWords: Int {
        wordsLearned + wordsReviewed
    }

    init(startTime: Date = Date()) {
        self.startTime = startTime
    }
}

// MARK: - Learning Goal (学习目标)
struct LearningGoal: Codable {
    var dailyNewWords: Int = 20
    var dailyReviewWords: Int = 50
    var weeklyGoal: Int = 140
    var monthlyGoal: Int = 600

    func isDailyGoalMet(todayLearned: Int) -> Bool {
        return todayLearned >= dailyNewWords
    }

    func dailyProgress(todayLearned: Int) -> Double {
        return min(1.0, Double(todayLearned) / Double(dailyNewWords))
    }
}
