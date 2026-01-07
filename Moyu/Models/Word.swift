import Foundation

// MARK: - Word Model (单词模型)
struct Word: Identifiable, Equatable {
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
    
    init(wordRank: Int, 
         headWord: String, 
         tranCN: String, 
         usphone: String = "", 
         phrase: String = "", 
         phraseCN: String = "", 
         status: Int = 0,
         hiragana: String? = nil,
         katakana: String? = nil,
         romaji: String? = nil) {
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
    }
}

// MARK: - Progress Model (进度模型)
struct BookProgress {
    let bookName: String
    let current: Int
    let total: Int
}
