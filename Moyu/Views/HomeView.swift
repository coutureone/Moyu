import SwiftUI

// MARK: - Home View (首页)
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCount: Int = 20
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    let countOptions = [2, 10, 15, 20]
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("这次要背多少个？")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#3d5a80"))
            
            // 选择器 - 修复边框对齐
            Menu {
                ForEach(countOptions, id: \.self) { count in
                    Button("\(count)") {
                        selectedCount = count
                    }
                }
            } label: {
                HStack {
                    Text("\(selectedCount)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#3d5a80"))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#0077b6"))
                }
                .padding(.horizontal, 12)
                .frame(width: 100, height: 32)
                .background(Color.white)
                .cornerRadius(5)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
            }
            .menuStyle(.borderlessButton)
            .onAppear {
                selectedCount = appState.defaultWordCount
                print("📚 当前词书: \(appState.currentBook)")
            }
            
            // 开始按钮
            Button(action: startLearning) {
                Text("开始")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#e76f51"))
                    .frame(width: 100, height: 32)
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            // 错误提示
            if showError {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#e76f51"))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func startLearning() {
        print("🚀 开始学习，选择数量: \(selectedCount)")
        appState.createWordList(count: selectedCount)
        print("📖 获取到 \(appState.wordList.count) 个单词")
        
        if appState.wordList.isEmpty {
            showError = true
            errorMessage = "没有找到单词，请检查词库"
            print("❌ 没有找到单词")
            return
        }
        
        showError = false
        appState.currentPage = .remember
        print("✅ 跳转到记忆页面")
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
        .frame(width: 300, height: 150)
        .background(Color(hex: "#d7e1ec"))
}
