import SwiftUI

// MARK: - Content View (主内容视图)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var keyboardMonitor: Any?
    
    var body: some View {
        ZStack {
            // 背景色
            Group {
                if colorScheme == .dark {
                    MoyuTheme.appBackground(colorScheme)
                } else {
                    MoyuTheme.appBackground(colorScheme)
                }
            }
                .ignoresSafeArea()
            
            // 主内容
            Group {
                switch appState.currentPage {
                case .home:
                    HomeView()
                case .remember:
                    RememberView()
                case .choice:
                    ChoiceView()
                case .congratulate:
                    CongratulateView()
                case .wrongBook:
                    WrongBookView()
                case .favorites:
                    FavoritesView()
                case .statistics:
                    StatisticsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // 允许窗口随用户调整大小，同时给一个合理的最小值
        .frame(minWidth: 340, minHeight: 240)
        .onAppear {
            setupKeyboardShortcuts()
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC
                if let window = NSApplication.shared.mainWindow {
                    window.close()
                }
                return nil
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
}
