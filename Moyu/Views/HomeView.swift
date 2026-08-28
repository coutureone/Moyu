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
        VStack(spacing: 16) {
            DailyProgressView()

            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本次学习")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                        Text("\(customCount ?? selectedCount) 词")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(MoyuTheme.textColor(colorScheme))
                    }

                    Spacer()

                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(MoyuTheme.primary)
                        .frame(width: 44, height: 44)
                        .background(MoyuTheme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                WheelPicker(
                    selection: Binding(
                        get: { customCount ?? selectedCount },
                        set: { customCount = $0 }
                    ),
                    range: Array(2...100)
                )

                Button(action: startLearning) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                        Text("开始学习")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(MoyuPrimaryButtonStyle(tone: MoyuTheme.accent))
                .onHoverCursor()
            }
            .padding(16)
            .moyuCard(colorScheme)

            if showError {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MoyuTheme.danger)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickLinkButton(title: "错词本", icon: "book.closed") { appState.currentPage = .wrongBook }
                QuickLinkButton(title: "收藏夹", icon: "star") { appState.currentPage = .favorites }
                QuickLinkButton(title: "统计", icon: "chart.bar") { appState.currentPage = .statistics }
                QuickLinkButton(title: "设置", icon: "slider.horizontal.3") { appState.currentPage = .settings }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
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
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日目标")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoyuTheme.textColor(colorScheme))
                    Text("\(appState.statistics.todayLearned)/\(appState.dailyGoal) 词")
                        .font(.system(size: 12))
                        .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                }

                Spacer()

                if appState.isDailyGoalCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("已完成")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.green)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MoyuTheme.primary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(MoyuTheme.border(colorScheme).opacity(0.3))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    appState.isDailyGoalCompleted ? Color.green : MoyuTheme.primary,
                                    appState.isDailyGoalCompleted ? Color.green.opacity(0.7) : MoyuTheme.primary.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geometry.size.width * progress, 10), height: 10)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .moyuCard(colorScheme)
    }
}

// MARK: - Quick Link Button
private struct QuickLinkButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
                    .foregroundColor(MoyuTheme.primary)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MoyuTheme.textColor(colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme).opacity(0.4))
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MoyuTheme.cardBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(MoyuTheme.border(colorScheme).opacity(isHovered ? 0.6 : 0.3), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.03),
                    radius: isHovered ? 6 : 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onHoverCursor()
    }
}

// MARK: - Wheel Picker (macOS 自定义滚轮效果)
private struct WheelPicker: View {
    @Binding var selection: Int
    let range: [Int]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(range, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: value == selection ? 20 : 15,
                                          weight: value == selection ? .bold : .regular))
                            .foregroundColor(value == selection
                                ? MoyuTheme.textColor(colorScheme)
                                : MoyuTheme.secondaryTextColor(colorScheme).opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selection = value
                                }
                            }
                            .id(value)
                    }
                }
                .padding(.vertical, 20)
            }
            .frame(width: 200, height: 130)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark
                        ? Color(hex: "#2d3748").opacity(0.6)
                        : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoyuTheme.border(colorScheme).opacity(0.5), lineWidth: 1)
            )
            .overlay(
                // 选中区域高亮
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(MoyuTheme.primary.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    .frame(height: 40)
                    .padding(.horizontal, 8)
                    .allowsHitTesting(false)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                    radius: 8, x: 0, y: 2)
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
