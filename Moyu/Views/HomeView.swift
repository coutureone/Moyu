import SwiftUI

// MARK: - Home View (首页)
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCount: Int = 20
    @State private var customCount: Int? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 14) {
            DailyProgressView()

            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本次学习")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                        Text("\(customCount ?? selectedCount) 词")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(MoyuTheme.textColor(colorScheme))
                    }

                    Spacer()

                    Image(systemName: "timer")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(MoyuTheme.primary)
                        .frame(width: 38, height: 38)
                        .background(MoyuTheme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous))
                }

                WheelPicker(
                    selection: Binding(
                        get: { customCount ?? selectedCount },
                        set: { customCount = $0 }
                    ),
                    range: Array(2...100)
                )

                Button(action: startLearning) {
                    HStack(spacing: 7) {
                        Image(systemName: "play.fill")
                        Text("开始学习")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(MoyuPrimaryButtonStyle(tone: MoyuTheme.accent))
                .onHoverCursor()
            }
            .padding(14)
            .moyuCard(colorScheme)
            
            if showError {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(MoyuTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                QuickLinkButton(title: "错词本", icon: "book.closed") { appState.currentPage = .wrongBook }
                QuickLinkButton(title: "收藏夹", icon: "star") { appState.currentPage = .favorites }
                QuickLinkButton(title: "统计", icon: "chart.bar") { appState.currentPage = .statistics }
                QuickLinkButton(title: "设置", icon: "slider.horizontal.3") { appState.currentPage = .settings }
            }
        }
        .padding(16)
        .background(MoyuTheme.appBackground(colorScheme))
        .onAppear {
            selectedCount = appState.defaultWordCount
            customCount = nil
            appState.loadStatistics()
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

// MARK: - Daily Progress View (今日进度)
private struct DailyProgressView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private var progress: Double {
        guard appState.dailyGoal > 0 else { return 0 }
        return min(Double(appState.statistics.todayLearned) / Double(appState.dailyGoal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日目标")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoyuTheme.textColor(colorScheme))
                    Text("\(appState.statistics.todayLearned)/\(appState.dailyGoal) 词")
                        .font(.system(size: 11))
                        .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                }
                
                Spacer()
                
                if appState.isDailyGoalCompleted {
                    Label("已完成", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(MoyuTheme.primary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MoyuTheme.border(colorScheme))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            appState.isDailyGoalCompleted
                                ? Color.green
                                : MoyuTheme.primary
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .moyuCard(colorScheme)
    }
}

// MARK: - Quick Link Button
private struct QuickLinkButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(MoyuTheme.textColor(colorScheme))
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(MoyuTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous)
                    .stroke(MoyuTheme.border(colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHoverCursor()
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
            .frame(width: 170, height: 118)
            .background(
                RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous)
                    .fill(Color.white.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MoyuTheme.radius, style: .continuous)
                    .stroke(Color(hex: "#d0d7e2"), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MoyuTheme.controlRadius, style: .continuous)
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
