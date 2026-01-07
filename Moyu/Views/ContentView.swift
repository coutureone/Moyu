import SwiftUI

// MARK: - Content View (主内容视图)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "#d7e1ec")
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
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 300, height: 150)
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC
                if let window = NSApplication.shared.mainWindow {
                    window.close()
                }
                return nil
            }
            return event
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
