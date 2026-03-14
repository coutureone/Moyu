import Foundation
import SQLite3

// MARK: - Database Service (数据库服务)
class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        // 数据库路径：应用支持目录
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let moyuDir = appSupportURL.appendingPathComponent("Moyu")
        
        // 创建目录
        try? fileManager.createDirectory(at: moyuDir, withIntermediateDirectories: true)
        
        dbPath = moyuDir.appendingPathComponent("moyu.db").path
        
        // 如果数据库不存在，从 Bundle 复制
        if !fileManager.fileExists(atPath: dbPath) {
            if let bundleDBPath = Bundle.main.path(forResource: "moyu", ofType: "db") {
                do {
                    try fileManager.copyItem(atPath: bundleDBPath, toPath: dbPath)
                    print("✅ 数据库已从 Bundle 复制到: \(dbPath)")
                } catch {
                    print("❌ 复制数据库失败: \(error)")
                }
            } else {
                print("⚠️ Bundle 中未找到 moyu.db，将使用空数据库")
            }
        }
        
        openDatabase()
        createNewTables()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ 无法打开数据库: \(dbPath)")
        } else {
            print("✅ 数据库已打开: \(dbPath)")
        }
    }
    
    private func executeSQL(_ sql: String) {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("❌ SQL错误: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
        }
    }

    /// 检查表中是否已存在指定列，避免重复 ALTER TABLE 报错
    private func columnExists(table: String, column: String) -> Bool {
        let pragmaSQL = "PRAGMA table_info(\(table));"
        var statement: OpaquePointer?
        var exists = false

        if sqlite3_prepare_v2(db, pragmaSQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cName = sqlite3_column_text(statement, 1) {
                    let name = String(cString: cName)
                    if name == column {
                        exists = true
                        break
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        return exists
    }
    
    // MARK: - Create New Tables (创建新表)
    
    private func createNewTables() {
        // 错词本表
        let wrongBookSQL = """
            CREATE TABLE IF NOT EXISTS WrongBook (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                wordRank INTEGER,
                bookName TEXT,
                headWord TEXT,
                tranCN TEXT,
                usphone TEXT,
                phrase TEXT,
                phraseCN TEXT,
                wrongCount INTEGER DEFAULT 1,
                lastWrongDate TEXT,
                UNIQUE(wordRank, bookName)
            )
        """
        executeSQL(wrongBookSQL)
        
        // 收藏表
        let favoritesSQL = """
            CREATE TABLE IF NOT EXISTS Favorites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                wordRank INTEGER,
                bookName TEXT,
                headWord TEXT,
                tranCN TEXT,
                usphone TEXT,
                phrase TEXT,
                phraseCN TEXT,
                addDate TEXT,
                UNIQUE(wordRank, bookName)
            )
        """
        executeSQL(favoritesSQL)
        
        // 学习统计表
        let statisticsSQL = """
            CREATE TABLE IF NOT EXISTS Statistics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                dateString TEXT UNIQUE,
                learnedCount INTEGER DEFAULT 0,
                correctCount INTEGER DEFAULT 0,
                wrongCount INTEGER DEFAULT 0,
                duration INTEGER DEFAULT 0
            )
        """
        executeSQL(statisticsSQL)
        
        // 成就表
        let achievementsSQL = """
            CREATE TABLE IF NOT EXISTS Achievements (
                id TEXT PRIMARY KEY,
                name TEXT,
                description TEXT,
                icon TEXT,
                isUnlocked INTEGER DEFAULT 0,
                unlockedDate TEXT
            )
        """
        executeSQL(achievementsSQL)
        
        // 初始化成就
        initializeAchievements()
        
        // 全局设置表添加新字段
        if !columnExists(table: "Global", column: "streakDays") {
            let alterGlobalSQL = """
                ALTER TABLE Global ADD COLUMN streakDays INTEGER DEFAULT 0
            """
            executeSQL(alterGlobalSQL)
        }
        
        if !columnExists(table: "Global", column: "lastLearnDate") {
            let alterGlobalSQL2 = """
                ALTER TABLE Global ADD COLUMN lastLearnDate TEXT
            """
            executeSQL(alterGlobalSQL2)
        }
        
        // 自定义词库表
        let customBooksSQL = """
            CREATE TABLE IF NOT EXISTS CustomBooks (
                bookName TEXT PRIMARY KEY,
                displayName TEXT,
                total INTEGER DEFAULT 0,
                createdAt TEXT
            )
        """
        executeSQL(customBooksSQL)
        
        print("✅ 新表已创建/更新")
    }
    
    private func initializeAchievements() {
        let achievements = [
            ("first_word", "初学乍练", "背完第一个单词", "🌱"),
            ("ten_words", "小有成就", "累计背完10个单词", "📖"),
            ("hundred_words", "百词斩", "累计背完100个单词", "📚"),
            ("thousand_words", "千词达人", "累计背完1000个单词", "🏆"),
            ("streak_3", "三日打卡", "连续学习3天", "🔥"),
            ("streak_7", "周周向上", "连续学习7天", "💪"),
            ("streak_30", "月度坚持", "连续学习30天", "🌟"),
            ("cet4_complete", "四级过关", "背完四级核心词汇", "🎓"),
            ("cet6_complete", "六级达成", "背完六级核心词汇", "🎯"),
            ("accuracy_90", "精准射手", "单日正确率达到90%", "🎯"),
            ("night_owl", "夜猫子", "凌晨12点后学习", "🦉"),
            ("early_bird", "早起鸟儿", "早上6点前学习", "🐦")
        ]
        
        for (id, name, desc, icon) in achievements {
            let sql = """
                INSERT OR IGNORE INTO Achievements (id, name, description, icon, isUnlocked)
                VALUES ('\(id)', '\(name)', '\(desc)', '\(icon)', 0)
            """
            executeSQL(sql)
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取全局设置
    func getGlobalSettings() -> (book: String, count: Int) {
        var book = "CET4_1"
        var count = 20
        
        let sql = "SELECT currentBookName, currentWordNumber FROM Global LIMIT 1"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    book = String(cString: cString)
                }
                count = Int(sqlite3_column_int(stmt, 1))
                if count == 0 { count = 20 }
            }
        }
        sqlite3_finalize(stmt)
        
        return (book, count)
    }
    
    /// 更新当前词书
    func updateCurrentBook(_ book: String) {
        let sql = "UPDATE Global SET currentBookName = '\(book)'"
        executeSQL(sql)
    }
    
    /// 更新默认背词数量
    func updateWordCount(_ count: Int) {
        let sql = "UPDATE Global SET currentWordNumber = \(count)"
        executeSQL(sql)
    }
    
    /// 获取词书进度
    func getProgress(for book: String) -> (current: Int, total: Int) {
        var current = 0
        var total = 0
        
        let sql = "SELECT current, number FROM Count WHERE bookName = '\(book)'"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                current = Int(sqlite3_column_int(stmt, 0))
                total = Int(sqlite3_column_int(stmt, 1))
            }
        }
        sqlite3_finalize(stmt)
        
        return (current, total)
    }
    
    /// 获取所有词书进度
    func getAllProgress() -> [String: (current: Int, total: Int)] {
        var result: [String: (current: Int, total: Int)] = [:]
        
        let sql = "SELECT bookName, current, number FROM Count"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let bookName = sqlite3_column_text(stmt, 0) {
                    let name = String(cString: bookName)
                    let current = Int(sqlite3_column_int(stmt, 1))
                    let total = Int(sqlite3_column_int(stmt, 2))
                    result[name] = (current, total)
                }
            }
        }
        sqlite3_finalize(stmt)
        
        return result
    }
    
    /// 随机获取指定数量的单词（英语词书）
    func getRandomWords(count: Int, from book: String) -> [Word] {
        var words: [Word] = []
        
        print("🔍 getRandomWords: 从 \(book) 获取 \(count) 个单词")
        
        // 检查是否是日语五十音
        if book == "Goin" {
            return getRandomGoinWords(count: count)
        }
        
        // 获取未背过的单词
        let sql = """
            SELECT wordRank, headWord, tranCN, usphone, phrase, phraseCN, status 
            FROM \(book) 
            WHERE status = 0 
            ORDER BY RANDOM() 
            LIMIT \(count)
        """
        var stmt: OpaquePointer?
        
        let prepareResult = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        print("🔍 SQL准备结果: \(prepareResult == SQLITE_OK ? "成功" : "失败(\(prepareResult))")")
        
        if prepareResult == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let wordRank = Int(sqlite3_column_int(stmt, 0))
                let headWord = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                let tranCN = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let usphone = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                let phrase = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
                let phraseCN = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
                let status = Int(sqlite3_column_int(stmt, 6))
                
                // 检查是否已收藏
                let isFavorite = checkIsFavorite(wordRank: wordRank, book: book)
                
                let word = Word(
                    wordRank: wordRank,
                    headWord: headWord,
                    tranCN: tranCN,
                    usphone: usphone,
                    phrase: phrase,
                    phraseCN: phraseCN,
                    status: status,
                    isFavorite: isFavorite
                )
                words.append(word)
            }
        } else {
            print("❌ SQL错误: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(stmt)
        
        print("📊 获取到 \(words.count) 个单词")
        return words
    }
    
    /// 随机获取五十音
    private func getRandomGoinWords(count: Int) -> [Word] {
        var words: [Word] = []
        
        let sql = """
            SELECT wordRank, hiragana, katakana, romaji, status 
            FROM Goin 
            WHERE status = 0 
            ORDER BY RANDOM() 
            LIMIT \(count)
        """
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let wordRank = Int(sqlite3_column_int(stmt, 0))
                let hiragana = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                let katakana = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let romaji = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                let status = Int(sqlite3_column_int(stmt, 4))
                
                let word = Word(
                    wordRank: wordRank,
                    headWord: hiragana,
                    tranCN: "",
                    status: status,
                    hiragana: hiragana,
                    katakana: katakana,
                    romaji: romaji
                )
                words.append(word)
            }
        }
        sqlite3_finalize(stmt)
        
        return words
    }
    
    /// 获取随机单词用于选择题干扰项
    func getRandomWordsForChoice(count: Int, from book: String, excluding wordRank: Int) -> [Word] {
        var words: [Word] = []
        
        if book == "Goin" {
            return getRandomGoinWordsForChoice(count: count, excluding: wordRank)
        }
        
        let sql = """
            SELECT wordRank, headWord, tranCN 
            FROM \(book) 
            WHERE wordRank != \(wordRank) 
            ORDER BY RANDOM() 
            LIMIT \(count)
        """
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let rank = Int(sqlite3_column_int(stmt, 0))
                let headWord = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                let tranCN = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                
                let word = Word(wordRank: rank, headWord: headWord, tranCN: tranCN)
                words.append(word)
            }
        }
        sqlite3_finalize(stmt)
        
        return words
    }
    
    /// 获取随机五十音用于选择题干扰项
    private func getRandomGoinWordsForChoice(count: Int, excluding wordRank: Int) -> [Word] {
        var words: [Word] = []
        
        let sql = """
            SELECT wordRank, hiragana, katakana, romaji 
            FROM Goin 
            WHERE wordRank != \(wordRank) 
            ORDER BY RANDOM() 
            LIMIT \(count)
        """
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let rank = Int(sqlite3_column_int(stmt, 0))
                let hiragana = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                let katakana = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let romaji = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                
                let word = Word(
                    wordRank: rank,
                    headWord: hiragana,
                    tranCN: "",
                    hiragana: hiragana,
                    katakana: katakana,
                    romaji: romaji
                )
                words.append(word)
            }
        }
        sqlite3_finalize(stmt)
        
        return words
    }
    
    /// 更新单词状态
    func updateWordStatus(wordRank: Int, status: Int, in book: String) {
        let sql = "UPDATE \(book) SET status = \(status) WHERE wordRank = \(wordRank)"
        executeSQL(sql)
    }
    
    /// 增加词书进度
    func incrementProgress(for book: String) {
        let sql = "UPDATE Count SET current = current + 1 WHERE bookName = '\(book)'"
        executeSQL(sql)
    }
    
    /// 重置词书进度
    func resetProgress(for book: String) {
        // 重置 Count 表
        let countSQL = "UPDATE Count SET current = 0 WHERE bookName = '\(book)'"
        executeSQL(countSQL)
        
        // 重置所有单词状态
        let wordSQL = "UPDATE \(book) SET status = 0"
        executeSQL(wordSQL)
    }
    
    /// 获取词书单词总数
    func getWordCount(for book: String) -> Int {
        var count = 0
        
        let sql = "SELECT COUNT(*) FROM \(book)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        
        return count
    }
    
    // MARK: - Custom Books (自定义词库导入)
    
    /// 导入自定义词库（CSV/JSON 已解析好的词条）
    /// - Parameters:
    ///   - bookName: 表名（建议带前缀 custom_）
    ///   - displayName: 展示名称
    ///   - words: 词条列表
    func importCustomBook(bookName: String, displayName: String, words: [WordImport]) {
        guard !bookName.isEmpty, !words.isEmpty else { return }
        
        // 创建表
        let createSQL = """
            CREATE TABLE IF NOT EXISTS \(bookName) (
                wordRank INTEGER PRIMARY KEY,
                headWord TEXT,
                tranCN TEXT,
                usphone TEXT,
                phrase TEXT,
                phraseCN TEXT,
                status INTEGER DEFAULT 0
            )
        """
        executeSQL(createSQL)
        
        // 清空旧数据
        executeSQL("DELETE FROM \(bookName)")
        
        // 批量插入
        var rank = 1
        for w in words {
            let head = w.headWord.replacingOccurrences(of: "'", with: "''")
            let tran = w.tranCN.replacingOccurrences(of: "'", with: "''")
            let phone = w.usphone.replacingOccurrences(of: "'", with: "''")
            let phr = w.phrase.replacingOccurrences(of: "'", with: "''")
            let phrCN = w.phraseCN.replacingOccurrences(of: "'", with: "''")
            let insertSQL = """
                INSERT OR REPLACE INTO \(bookName) (wordRank, headWord, tranCN, usphone, phrase, phraseCN, status)
                VALUES (\(rank), '\(head)', '\(tran)', '\(phone)', '\(phr)', '\(phrCN)', 0)
            """
            executeSQL(insertSQL)
            rank += 1
        }
        
        let total = words.count
        let now = ISO8601DateFormatter().string(from: Date())
        
        // 更新 CustomBooks
        let upsertCustom = """
            INSERT OR REPLACE INTO CustomBooks (bookName, displayName, total, createdAt)
            VALUES ('\(bookName)', '\(displayName.replacingOccurrences(of: "'", with: "''"))', \(total), '\(now)')
        """
        executeSQL(upsertCustom)
        
        // 更新 Count 表
        let upsertCount = """
            INSERT OR REPLACE INTO Count (bookName, number, current)
            VALUES ('\(bookName)', \(total), 0)
        """
        executeSQL(upsertCount)
        
        print("✅ 自定义词库导入完成: \(displayName) (\(total) 条)")
    }
    
    /// 获取自定义词库列表
    func getCustomBooks() -> [(id: String, name: String, progress: (current: Int, total: Int))] {
        var result: [(String, String, (Int, Int))] = []
        
        let sql = "SELECT bookName, displayName, total FROM CustomBooks ORDER BY createdAt DESC"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let book = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
                let name = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? book
                let total = Int(sqlite3_column_int(stmt, 2))
                let progress = getProgress(for: book)
                result.append((book, name, (progress.current, total > 0 ? total : progress.total)))
            }
        }
        sqlite3_finalize(stmt)
        
        return result
    }
    
    // MARK: - Wrong Book (错词本)
    
    /// 添加到错词本
    func addToWrongBook(word: Word, book: String) {
        let dateString = ISO8601DateFormatter().string(from: Date())
        
        // 先检查是否已存在
        let checkSQL = "SELECT wrongCount FROM WrongBook WHERE wordRank = \(word.wordRank) AND bookName = '\(book)'"
        var stmt: OpaquePointer?
        var existingCount = 0
        var exists = false
        
        if sqlite3_prepare_v2(db, checkSQL, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                exists = true
                existingCount = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        
        if exists {
            // 更新错误次数
            let updateSQL = """
                UPDATE WrongBook 
                SET wrongCount = \(existingCount + 1), lastWrongDate = '\(dateString)'
                WHERE wordRank = \(word.wordRank) AND bookName = '\(book)'
            """
            executeSQL(updateSQL)
        } else {
            // 插入新记录
            let insertSQL = """
                INSERT INTO WrongBook (wordRank, bookName, headWord, tranCN, usphone, phrase, phraseCN, wrongCount, lastWrongDate)
                VALUES (\(word.wordRank), '\(book)', '\(word.headWord.replacingOccurrences(of: "'", with: "''"))', 
                        '\(word.tranCN.replacingOccurrences(of: "'", with: "''"))', '\(word.usphone)', 
                        '\(word.phrase.replacingOccurrences(of: "'", with: "''"))', 
                        '\(word.phraseCN.replacingOccurrences(of: "'", with: "''"))', 1, '\(dateString)')
            """
            executeSQL(insertSQL)
        }
    }
    
    /// 获取错词本单词
    func getWrongBookWords(book: String? = nil) -> [Word] {
        var words: [Word] = []
        
        var sql = """
            SELECT wordRank, bookName, headWord, tranCN, usphone, phrase, phraseCN, wrongCount, lastWrongDate 
            FROM WrongBook
        """
        if let book = book {
            sql += " WHERE bookName = '\(book)'"
        }
        sql += " ORDER BY wrongCount DESC, lastWrongDate DESC"
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let wordRank = Int(sqlite3_column_int(stmt, 0))
                let headWord = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let tranCN = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                let usphone = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
                let phrase = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
                let phraseCN = sqlite3_column_text(stmt, 6).map { String(cString: $0) } ?? ""
                let wrongCount = Int(sqlite3_column_int(stmt, 7))
                
                var lastWrongDate: Date? = nil
                if let dateString = sqlite3_column_text(stmt, 8).map({ String(cString: $0) }) {
                    lastWrongDate = ISO8601DateFormatter().date(from: dateString)
                }
                
                let word = Word(
                    wordRank: wordRank,
                    headWord: headWord,
                    tranCN: tranCN,
                    usphone: usphone,
                    phrase: phrase,
                    phraseCN: phraseCN,
                    wrongCount: wrongCount,
                    lastWrongDate: lastWrongDate,
                    bookName: sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? book ?? ""
                )
                words.append(word)
            }
        }
        sqlite3_finalize(stmt)
        
        return words
    }
    
    /// 从错词本移除
    func removeFromWrongBook(wordRank: Int, book: String) {
        let sql = "DELETE FROM WrongBook WHERE wordRank = \(wordRank) AND bookName = '\(book)'"
        executeSQL(sql)
    }
    
    /// 获取错词本数量
    func getWrongBookCount() -> Int {
        var count = 0
        let sql = "SELECT COUNT(*) FROM WrongBook"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        
        return count
    }
    
    // MARK: - Favorites (收藏夹)
    
    /// 检查是否已收藏
    func checkIsFavorite(wordRank: Int, book: String) -> Bool {
        let sql = "SELECT 1 FROM Favorites WHERE wordRank = \(wordRank) AND bookName = '\(book)'"
        var stmt: OpaquePointer?
        var isFavorite = false
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                isFavorite = true
            }
        }
        sqlite3_finalize(stmt)
        
        return isFavorite
    }
    
    /// 更新收藏状态
    func updateFavoriteStatus(wordRank: Int, isFavorite: Bool, in book: String) {
        if isFavorite {
            // 先获取单词信息
            let sql = """
                SELECT headWord, tranCN, usphone, phrase, phraseCN 
                FROM \(book) WHERE wordRank = \(wordRank)
            """
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let headWord = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
                    let tranCN = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                    let usphone = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                    let phrase = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                    let phraseCN = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
                    
                    let dateString = ISO8601DateFormatter().string(from: Date())
                    let insertSQL = """
                        INSERT OR REPLACE INTO Favorites (wordRank, bookName, headWord, tranCN, usphone, phrase, phraseCN, addDate)
                        VALUES (\(wordRank), '\(book)', '\(headWord.replacingOccurrences(of: "'", with: "''"))', 
                                '\(tranCN.replacingOccurrences(of: "'", with: "''"))', '\(usphone)', 
                                '\(phrase.replacingOccurrences(of: "'", with: "''"))', 
                                '\(phraseCN.replacingOccurrences(of: "'", with: "''"))', '\(dateString)')
                    """
                    executeSQL(insertSQL)
                }
            }
            sqlite3_finalize(stmt)
        } else {
            let deleteSQL = "DELETE FROM Favorites WHERE wordRank = \(wordRank) AND bookName = '\(book)'"
            executeSQL(deleteSQL)
        }
    }
    
    /// 获取收藏单词
    func getFavoriteWords(book: String? = nil) -> [Word] {
        var words: [Word] = []
        
        var sql = """
            SELECT wordRank, bookName, headWord, tranCN, usphone, phrase, phraseCN, addDate 
            FROM Favorites
        """
        if let book = book {
            sql += " WHERE bookName = '\(book)'"
        }
        sql += " ORDER BY addDate DESC"
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let wordRank = Int(sqlite3_column_int(stmt, 0))
                let headWord = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let tranCN = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                let usphone = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
                let phrase = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
                let phraseCN = sqlite3_column_text(stmt, 6).map { String(cString: $0) } ?? ""
                
                let word = Word(
                    wordRank: wordRank,
                    headWord: headWord,
                    tranCN: tranCN,
                    usphone: usphone,
                    phrase: phrase,
                    phraseCN: phraseCN,
                    isFavorite: true,
                    bookName: sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? book ?? ""
                )
                words.append(word)
            }
        }
        sqlite3_finalize(stmt)
        
        return words
    }
    
    /// 获取收藏数量
    func getFavoritesCount() -> Int {
        var count = 0
        let sql = "SELECT COUNT(*) FROM Favorites"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        
        return count
    }
    
    // MARK: - Statistics (学习统计)
    
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// 记录答题
    func recordAnswer(isCorrect: Bool) {
        let dateString = getTodayDateString()
        
        // 确保今天的记录存在
        let insertSQL = """
            INSERT OR IGNORE INTO Statistics (dateString, learnedCount, correctCount, wrongCount, duration)
            VALUES ('\(dateString)', 0, 0, 0, 0)
        """
        executeSQL(insertSQL)
        
        // 更新统计
        let updateSQL: String
        if isCorrect {
            updateSQL = """
                UPDATE Statistics 
                SET learnedCount = learnedCount + 1, correctCount = correctCount + 1
                WHERE dateString = '\(dateString)'
            """
        } else {
            updateSQL = """
                UPDATE Statistics 
                SET wrongCount = wrongCount + 1
                WHERE dateString = '\(dateString)'
            """
        }
        executeSQL(updateSQL)
        
        // 更新连续打卡天数
        updateStreakDays()
    }
    
    /// 添加学习时长
    func addLearningDuration(_ duration: Int) {
        let dateString = getTodayDateString()
        
        let insertSQL = """
            INSERT OR IGNORE INTO Statistics (dateString, learnedCount, correctCount, wrongCount, duration)
            VALUES ('\(dateString)', 0, 0, 0, 0)
        """
        executeSQL(insertSQL)
        
        let updateSQL = """
            UPDATE Statistics SET duration = duration + \(duration) WHERE dateString = '\(dateString)'
        """
        executeSQL(updateSQL)
    }
    
    /// 获取今日学习时长
    func getTodayLearningDuration() -> Int {
        let dateString = getTodayDateString()
        var duration = 0
        
        let sql = "SELECT duration FROM Statistics WHERE dateString = '\(dateString)'"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                duration = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        
        return duration
    }
    
    /// 获取学习统计
    func getStatistics() -> LearningStatistics {
        var stats = LearningStatistics()
        let dateString = getTodayDateString()
        
        // 获取今日数据
        let todaySQL = "SELECT learnedCount, correctCount, wrongCount FROM Statistics WHERE dateString = '\(dateString)'"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, todaySQL, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                stats.todayLearned = Int(sqlite3_column_int(stmt, 0))
                stats.todayCorrect = Int(sqlite3_column_int(stmt, 1))
                stats.todayWrong = Int(sqlite3_column_int(stmt, 2))
            }
        }
        sqlite3_finalize(stmt)
        
        // 获取总数据
        let totalSQL = "SELECT SUM(learnedCount), COUNT(DISTINCT dateString) FROM Statistics WHERE learnedCount > 0"
        if sqlite3_prepare_v2(db, totalSQL, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                stats.totalLearned = Int(sqlite3_column_int(stmt, 0))
                stats.totalDays = Int(sqlite3_column_int(stmt, 1))
            }
        }
        sqlite3_finalize(stmt)
        
        // 获取连续打卡天数
        let streakSQL = "SELECT streakDays, lastLearnDate FROM Global LIMIT 1"
        if sqlite3_prepare_v2(db, streakSQL, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                stats.streakDays = Int(sqlite3_column_int(stmt, 0))
                if let dateStr = sqlite3_column_text(stmt, 1).map({ String(cString: $0) }) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    stats.lastLearnDate = formatter.date(from: dateStr)
                }
            }
        }
        sqlite3_finalize(stmt)
        
        return stats
    }
    
    /// 获取最近7天的学习记录
    func getRecentRecords(days: Int = 7) -> [DailyRecord] {
        var records: [DailyRecord] = []
        
        let sql = """
            SELECT dateString, learnedCount, correctCount, wrongCount, duration 
            FROM Statistics 
            ORDER BY dateString DESC 
            LIMIT \(days)
        """
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let dateString = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
                let learnedCount = Int(sqlite3_column_int(stmt, 1))
                let correctCount = Int(sqlite3_column_int(stmt, 2))
                let wrongCount = Int(sqlite3_column_int(stmt, 3))
                let duration = Int(sqlite3_column_int(stmt, 4))
                
                let record = DailyRecord(
                    dateString: dateString,
                    learnedCount: learnedCount,
                    correctCount: correctCount,
                    wrongCount: wrongCount,
                    duration: duration
                )
                records.append(record)
            }
        }
        sqlite3_finalize(stmt)
        
        return records
    }
    
    /// 更新连续打卡天数
    private func updateStreakDays() {
        let today = getTodayDateString()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 获取当前连续天数和上次学习日期
        var currentStreak = 0
        var lastLearnDate: String? = nil
        
        let sql = "SELECT streakDays, lastLearnDate FROM Global LIMIT 1"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                currentStreak = Int(sqlite3_column_int(stmt, 0))
                lastLearnDate = sqlite3_column_text(stmt, 1).map { String(cString: $0) }
            }
        }
        sqlite3_finalize(stmt)
        
        // 计算新的连续天数
        var newStreak = currentStreak
        
        if let lastDate = lastLearnDate, let last = formatter.date(from: lastDate) {
            let calendar = Calendar.current
            let daysDiff = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
            
            if daysDiff == 0 {
                // 同一天，不变
            } else if daysDiff == 1 {
                // 连续打卡
                newStreak += 1
            } else {
                // 中断，重新开始
                newStreak = 1
            }
        } else {
            // 第一次学习
            newStreak = 1
        }
        
        // 更新数据库
        let updateSQL = "UPDATE Global SET streakDays = \(newStreak), lastLearnDate = '\(today)'"
        executeSQL(updateSQL)
        
        // 检查成就
        checkStreakAchievements(streak: newStreak)
    }
    
    // MARK: - Achievements (成就系统)
    
    /// 获取所有成就
    func getAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        let sql = "SELECT id, name, description, icon, isUnlocked, unlockedDate FROM Achievements"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
                let name = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                let description = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let icon = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                let isUnlocked = sqlite3_column_int(stmt, 4) == 1
                
                var unlockedDate: Date? = nil
                if let dateStr = sqlite3_column_text(stmt, 5).map({ String(cString: $0) }) {
                    unlockedDate = ISO8601DateFormatter().date(from: dateStr)
                }
                
                let achievement = Achievement(
                    id: id,
                    name: name,
                    description: description,
                    icon: icon,
                    isUnlocked: isUnlocked,
                    unlockedDate: unlockedDate
                )
                achievements.append(achievement)
            }
        }
        sqlite3_finalize(stmt)
        
        return achievements
    }
    
    /// 解锁成就
    func unlockAchievement(id: String) {
        let dateString = ISO8601DateFormatter().string(from: Date())
        let sql = "UPDATE Achievements SET isUnlocked = 1, unlockedDate = '\(dateString)' WHERE id = '\(id)' AND isUnlocked = 0"
        executeSQL(sql)
    }
    
    /// 检查连续打卡成就
    private func checkStreakAchievements(streak: Int) {
        if streak >= 3 {
            unlockAchievement(id: "streak_3")
        }
        if streak >= 7 {
            unlockAchievement(id: "streak_7")
        }
        if streak >= 30 {
            unlockAchievement(id: "streak_30")
        }
    }
    
    /// 检查学习数量成就
    func checkLearningAchievements() {
        let stats = getStatistics()
        
        if stats.totalLearned >= 1 {
            unlockAchievement(id: "first_word")
        }
        if stats.totalLearned >= 10 {
            unlockAchievement(id: "ten_words")
        }
        if stats.totalLearned >= 100 {
            unlockAchievement(id: "hundred_words")
        }
        if stats.totalLearned >= 1000 {
            unlockAchievement(id: "thousand_words")
        }
        
        // 检查正确率成就
        if stats.todayAccuracy >= 90 && stats.todayLearned >= 10 {
            unlockAchievement(id: "accuracy_90")
        }
        
        // 检查时间成就
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 0 && hour < 5 {
            unlockAchievement(id: "night_owl")
        }
        if hour >= 5 && hour < 7 {
            unlockAchievement(id: "early_bird")
        }
    }
    
    /// 获取已解锁成就数量
    func getUnlockedAchievementsCount() -> Int {
        var count = 0
        let sql = "SELECT COUNT(*) FROM Achievements WHERE isUnlocked = 1"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        
        return count
    }
    
    // MARK: - Data Management
    
    /// 清空错词本
    func clearWrongBook() {
        executeSQL("DELETE FROM WrongBook")
    }
    
    /// 清空收藏夹
    func clearFavorites() {
        executeSQL("DELETE FROM Favorites")
    }
    
    /// 清空所有学习进度
    func clearAllProgress() {
        executeSQL("DELETE FROM WrongBook")
        executeSQL("DELETE FROM Favorites")
        executeSQL("UPDATE Global SET streakDays = 0, lastLearnDate = NULL")
        executeSQL("DELETE FROM Statistics")
        
        let books = getAllBookNames()
        for book in books {
            executeSQL("UPDATE Count SET current = 0 WHERE bookName = '\(book)'")
            executeSQL("UPDATE \(book) SET status = 0")
        }
    }
    
    /// 获取所有词书名称
    private func getAllBookNames() -> [String] {
        var books: [String] = []
        let sql = "SELECT DISTINCT bookName FROM Count"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let name = sqlite3_column_text(stmt, 0).map({ String(cString: $0) }) {
                    books.append(name)
                }
            }
        }
        sqlite3_finalize(stmt)
        
        return books
    }
    
    /// 导出学习数据到JSON
    func exportData() -> [[String: Any]] {
        var data: [[String: Any]] = []
        
        // 导出错词本
        let wrongWords = getWrongBookWords()
        for word in wrongWords {
            data.append([
                "type": "wrong",
                "word": word.headWord,
                "meaning": word.tranCN,
                "wrongCount": word.wrongCount
            ])
        }
        
        // 导出收藏
        let favWords = getFavoriteWords()
        for word in favWords {
            data.append([
                "type": "favorite",
                "word": word.headWord,
                "meaning": word.tranCN
            ])
        }
        
        return data
    }
    
    // MARK: - Search
    
    /// 搜索单词
    func searchWords(keyword: String, in book: String, limit: Int = 50) -> [Word] {
        var words: [Word] = []
        guard !keyword.isEmpty else { return words }
        
        let searchPattern = "%\(keyword)%"
        let sql = """
            SELECT wordRank, headWord, tranCN, usphone, phrase, phraseCN, status 
            FROM \(book) 
            WHERE headWord LIKE '\(searchPattern)' OR tranCN LIKE '\(searchPattern)'
            LIMIT \(limit)
        """
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let wordRank = Int(sqlite3_column_int(stmt, 0))
                let headWord = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                let tranCN = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                let usphone = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                let phrase = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
                let phraseCN = sqlite3_column_text(stmt, 5).map { String(cString: $0) } ?? ""
                let status = Int(sqlite3_column_int(stmt, 6))
                
                let isFavorite = checkIsFavorite(wordRank: wordRank, book: book)
                
                let word = Word(
                    wordRank: wordRank,
                    headWord: headWord,
                    tranCN: tranCN,
                    usphone: usphone,
                    phrase: phrase,
                    phraseCN: phraseCN,
                    status: status,
                    isFavorite: isFavorite
                )
                words.append(word)
            }
        }
        sqlite3_finalize(stmt)
        
        return words
    }
}
