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
                
                let word = Word(
                    wordRank: wordRank,
                    headWord: headWord,
                    tranCN: tranCN,
                    usphone: usphone,
                    phrase: phrase,
                    phraseCN: phraseCN,
                    status: status
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
}
