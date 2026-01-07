import SwiftUI

// MARK: - Home View (首页)
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCount: Int = 20
    @State private var customCount: Int? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("这次要背多少个？")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#3d5a80"))
            
            // 自定义数量（滚轮式，类似闹钟）
            VStack(spacing: 8) {
                Text("自定义：\(customCount ?? selectedCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#3d5a80"))
                
                WheelPicker(
                    selection: Binding(
                        get: { customCount ?? selectedCount },
                        set: { customCount = $0 }
                    ),
                    range: Array(2...100)
                )
            }
            .padding(.top, 6)
            
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
            
            // 快捷入口
            HStack(spacing: 8) {
                QuickLinkButton(title: "错词本") { appState.currentPage = .wrongBook }
                QuickLinkButton(title: "收藏夹") { appState.currentPage = .favorites }
                QuickLinkButton(title: "统计") { appState.currentPage = .statistics }
                QuickLinkButton(title: "设置") { appState.currentPage = .settings }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .onAppear {
            selectedCount = appState.defaultWordCount
            customCount = nil
        }
    }
    
    private func startLearning() {
        let finalCount: Int
        if let custom = customCount, custom > 0 {
            finalCount = custom
        } else {
            finalCount = selectedCount
        }
        
        print("🚀 开始学习，选择数量: \(finalCount)")
        appState.createWordList(count: finalCount)
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

// MARK: - Quick Link Button
private struct QuickLinkButton: View {
    let title: String
    let action: () -> Void
    
    @State private var hovering = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(hovering ? Color(hex: "#0077b6") : Color(hex: "#3d5a80"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.hovering = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - Wheel Picker (macOS 自定义滚轮效果)
private struct WheelPicker: View {
    @Binding var selection: Int
    let range: [Int]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(range, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: value == selection ? 18 : 14,
                                          weight: value == selection ? .semibold : .regular))
                            .foregroundColor(value == selection ? Color(hex: "#1d3557") : Color(hex: "#8d99ae"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selection = value
                                }
                            }
                            .id(value)
                    }
                }
                .padding(.vertical, 18)
            }
            .frame(width: 160, height: 130)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#d0d7e2"), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.7))
                    .frame(height: 36)
                    .padding(.horizontal, 6)
                    .allowsHitTesting(false)
            )
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
            .onChange(of: selection) { newValue in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
        .frame(width: 300, height: 150)
        .background(Color(hex: "#d7e1ec"))
}
