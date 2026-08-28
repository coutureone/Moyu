import AVFoundation
import Foundation

// MARK: - Pronunciation Service
/// 发音服务 - 使用 AVSpeechSynthesizer
class PronunciationService: NSObject, ObservableObject {
    static let shared = PronunciationService()

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?

    @Published var isPlaying = false
    @Published var rate: Float = 0.5 // 发音速度 (0.0 - 1.0)

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public Methods

    /// 播放单词发音
    func speak(word: String, rate: Float? = nil) {
        // 停止当前播放
        stop()

        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: word)

        // 设置语言为英语
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        // 设置语速 (0.0 慢 - 1.0 快)
        utterance.rate = rate ?? self.rate

        // 设置音量
        utterance.volume = 1.0

        // 设置音调
        utterance.pitchMultiplier = 1.0

        currentUtterance = utterance
        isPlaying = true

        // 播放
        synthesizer.speak(utterance)
    }

    /// 停止播放
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        currentUtterance = nil
    }

    /// 暂停播放
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }

    /// 继续播放
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    /// 设置发音速度
    func setRate(_ rate: Float) {
        self.rate = min(max(rate, 0.0), 1.0)
    }

    /// 从 AppStorage 读取速度设置
    func loadRateFromSettings() {
        if let speed = UserDefaults.standard.value(forKey: "pronunciationSpeed") as? Double {
            // 将 0.5-2.0 映射到 0.0-1.0
            self.rate = Float((speed - 0.5) / 1.5)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension PronunciationService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        currentUtterance = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        currentUtterance = nil
    }
}
