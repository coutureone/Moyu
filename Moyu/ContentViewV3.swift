import SwiftUI

// MARK: - Content View v3.0
/// 主内容视图 - 集成所有 V3 页面
struct ContentViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var keyboardMonitor: Any?

    var body: some View {
        ZStack {
            // 背景色
            DesignTokens.Colors.background(for: colorScheme)
                .ignoresSafeArea()

            // 主内容
            Group {
                switch appState.currentPage {
                case .home:
                    HomeViewV3()
                case .remember:
                    RememberViewV3()
                case .choice:
                    ChoiceViewV3()
                case .wrongBook:
                    WrongBookViewV3()
                case .favorites:
                    FavoritesViewV3()
                case .statistics:
                    StatisticsViewV3()
                case .practiceSession(let words, let source):
                    PracticeSessionViewV3(words: words, source: source)
                case .settings:
                    SettingsViewV3()
                case .congratulate:
                    // 保留旧的完成页面或用新的完成视图
                    CongratulateView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 380, minHeight: 320)
        .onAppear {
            setupKeyboardShortcuts()
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
    }

    // MARK: - Keyboard Shortcuts

    private func setupKeyboardShortcuts() {
        guard keyboardMonitor == nil else { return }

        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 获取当前页面
            let currentPage = appState.currentPage

            // ESC - 返回或退出
            if event.keyCode == 53 { // ESC
                handleEscKey()
                return nil
            }

            // Space - 显示答案（记忆模式和练习模式）
            if event.keyCode == 49 { // Space
                if case .remember = currentPage {
                    NotificationCenter.default.post(name: .showAnswer, object: nil)
                    return nil
                }
                if case .practiceSession = currentPage {
                    NotificationCenter.default.post(name: .showAnswer, object: nil)
                    return nil
                }
            }

            // 数字键快捷键（学习页面）
            if case .remember = currentPage {
                switch event.keyCode {
                case 18: // 1 - 认识
                    NotificationCenter.default.post(name: .markCorrect, object: nil)
                    return nil
                case 19: // 2 - 不认识
                    NotificationCenter.default.post(name: .markWrong, object: nil)
                    return nil
                case 20: // 3 - 发音
                    NotificationCenter.default.post(name: .playPronunciation, object: nil)
                    return nil
                case 21: // 4 - 收藏
                    NotificationCenter.default.post(name: .toggleFavorite, object: nil)
                    return nil
                default:
                    break
                }
            }

            // 选择模式快捷键
            if case .choice = currentPage {
                switch event.keyCode {
                case 0: // A
                    NotificationCenter.default.post(name: .selectOption, object: 0)
                    return nil
                case 11: // B
                    NotificationCenter.default.post(name: .selectOption, object: 1)
                    return nil
                case 8: // C
                    NotificationCenter.default.post(name: .selectOption, object: 2)
                    return nil
                case 2: // D
                    NotificationCenter.default.post(name: .selectOption, object: 3)
                    return nil
                default:
                    break
                }
            }

            // 练习模式快捷键
            if case .practiceSession = currentPage {
                switch event.keyCode {
                case 18: // 1 - 记住了
                    NotificationCenter.default.post(name: .markRemembered, object: nil)
                    return nil
                case 19: // 2 - 忘记了
                    NotificationCenter.default.post(name: .markForgot, object: nil)
                    return nil
                case 20: // 3 - 发音
                    NotificationCenter.default.post(name: .playPronunciation, object: nil)
                    return nil
                default:
                    break
                }
            }

            return event
        }
    }

    private func removeKeyboardShortcuts() {
        if let keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
            self.keyboardMonitor = nil
        }
    }

    private func handleEscKey() {
        switch appState.currentPage {
        case .home:
            // 主页按 ESC 退出应用
            NSApplication.shared.terminate(nil)
        case .remember, .choice, .wrongBook, .favorites, .statistics, .settings, .practiceSession:
            // 其他页面返回主页
            appState.currentPage = .home
        case .congratulate:
            appState.currentPage = .home
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    // 通用
    static let showAnswer = Notification.Name("showAnswer")
    static let playPronunciation = Notification.Name("playPronunciation")

    // 记忆模式
    static let markCorrect = Notification.Name("markCorrect")
    static let markWrong = Notification.Name("markWrong")
    static let toggleFavorite = Notification.Name("toggleFavorite")

    // 选择模式
    static let selectOption = Notification.Name("selectOption")

    // 练习模式
    static let markRemembered = Notification.Name("markRemembered")
    static let markForgot = Notification.Name("markForgot")
}

// MARK: - Preview
#Preview {
    ContentViewV3()
        .environmentObject(AppState())
}
