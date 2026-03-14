import SwiftUI

// MARK: - Settings View (设置页面)
    // MARK: - Settings View (设置页面)
// MARK: - Settings View (设置页面)
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var showResetAlert = false
    @State private var bookToReset: String = ""
    @State private var showClearWrongAlert = false
    @State private var showClearFavoritesAlert = false
    @State private var showClearAllAlert = false
    @State private var showExportSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 外观设置
                appearanceSection
                
                // 学习设置
                learningSection
                
                // 提醒设置
                reminderSection
                
                // 词库管理
                bookManagementSection
                
                // 数据管理
                dataManagementSection
                
                // 返回按钮
                backButton
            }
            .padding(16)
        }
        .background(backgroundColor)
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                appState.resetBookProgress(book: bookToReset)
            }
        } message: {
            Text("确定要重置「\(getBookDisplayName(bookToReset))」的学习进度吗？此操作不可恢复。")
        }
    }
    
    // MARK: - Components
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "#1a1a2e") : Color(hex: "#d7e1ec")
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "#16213e") : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "#3d5a80")
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "🎨", title: "外观设置")
            
            VStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                    ThemeOptionRow(
                        theme: theme,
                        isSelected: appState.appTheme == theme,
                        onSelect: { appState.appTheme = theme }
                    )
                }
            }
            .padding(12)
            .background(cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
    
    private var learningSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "📖", title: "学习设置")
            
            VStack(spacing: 12) {
                // 每组单词数量
                HStack {
                    Text("每组单词数量")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Menu {
                        ForEach([10, 20, 30, 50, 100], id: \.self) { count in
                            Button("\(count)") {
                                appState.defaultWordCount = count
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(appState.defaultWordCount)")
                                .font(.system(size: 13))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(Color(hex: "#0077b6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#0077b6").opacity(0.1))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                }
                
                Divider()
                
                // 测试模式选择
                HStack {
                    Text("测试模式")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(QuizMode.allCases, id: \.rawValue) { mode in
                            Button(action: {
                                appState.quizMode = mode
                            }) {
                                HStack {
                                    Text(mode.displayName)
                                    if appState.quizMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(appState.quizMode.displayName)
                                .font(.system(size: 13))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(Color(hex: "#0077b6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#0077b6").opacity(0.1))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                }
                
                Divider()
                
                // 每日学习目标
                HStack {
                    Text("每日目标")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Menu {
                        ForEach([20, 30, 50, 100, 150, 200], id: \.self) { goal in
                            Button("\(goal) 词") {
                                appState.dailyGoal = goal
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(appState.dailyGoal) 词")
                                .font(.system(size: 13))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(Color(hex: "#0077b6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#0077b6").opacity(0.1))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                }
                
                Divider()
                
                // TTS语速调节
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("发音语速")
                            .font(.system(size: 13))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Text(ttsSpeedLabel)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#0077b6"))
                    }
                    
                    Slider(value: $appState.ttsSpeed, in: 0.2...0.8, step: 0.1)
                        .tint(Color(hex: "#0077b6"))
                }
            }
            .padding(12)
            .background(cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
    
    private var ttsSpeedLabel: String {
        switch appState.ttsSpeed {
        case 0.2: return "很慢"
        case 0.3: return "慢速"
        case 0.4: return "正常"
        case 0.5: return "稍快"
        case 0.6: return "快速"
        case 0.7: return "很快"
        case 0.8: return "极快"
        default: return "正常"
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "🔔", title: "学习提醒")
            
            VStack(spacing: 12) {
                Toggle(isOn: $appState.reminderEnabled) {
                    Text("每日提醒")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                }
                .toggleStyle(.switch)
                
                if appState.reminderEnabled {
                    HStack {
                        Text("提醒时间")
                            .font(.system(size: 13))
                            .foregroundColor(textColor)
                        Spacer()
                        DatePicker("", selection: $appState.reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(width: 80)
                    }
                }
            }
            .padding(12)
            .background(cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
    
    private var bookManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "📚", title: "词库管理")
            
            VStack(spacing: 8) {
                let books = [
                    ("CET4_1", "四级核心词汇"),
                    ("CET4_3", "四级完整词汇"),
                    ("CET6_1", "六级核心词汇"),
                    ("CET6_3", "六级完整词汇")
                ]
                
                ForEach(books, id: \.0) { book in
                    BookResetRow(
                        bookId: book.0,
                        bookName: book.1,
                        onReset: {
                            bookToReset = book.0
                            showResetAlert = true
                        }
                    )
                }
            }
            .padding(12)
            .background(cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "💾", title: "数据管理")
            
            VStack(spacing: 8) {
                DataManagementRow(
                    title: "错词本",
                    count: DatabaseService.shared.getWrongBookCount(),
                    icon: "📕"
                ) {
                    showClearWrongAlert = true
                }
                
                DataManagementRow(
                    title: "收藏夹",
                    count: DatabaseService.shared.getFavoritesCount(),
                    icon: "⭐"
                ) {
                    showClearFavoritesAlert = true
                }
                
                DataManagementRow(
                    title: "已解锁成就",
                    count: DatabaseService.shared.getUnlockedAchievementsCount(),
                    icon: "🏆"
                )
                
                Divider()
                
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出学习数据")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#0077b6"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Button(action: { showClearAllAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("清空所有数据")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#e76f51"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .alert("清空错词本", isPresented: $showClearWrongAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                DatabaseService.shared.clearWrongBook()
            }
        } message: {
            Text("确定要清空所有错词记录吗？此操作不可恢复。")
        }
        .alert("清空收藏夹", isPresented: $showClearFavoritesAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                DatabaseService.shared.clearFavorites()
            }
        } message: {
            Text("确定要清空所有收藏吗？此操作不可恢复。")
        }
        .alert("清空所有数据", isPresented: $showClearAllAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                DatabaseService.shared.clearAllProgress()
                appState.loadStatistics()
            }
        } message: {
            Text("确定要清空所有学习进度和数据吗？此操作不可恢复！")
        }
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("学习数据已导出到桌面 (moyu_export.json)")
        }
    }
    
    private var backButton: some View {
        Button(action: { appState.currentPage = .home }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("返回")
            }
            .font(.system(size: 13))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(cardBackground)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .onHoverCursor()
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textColor)
        }
    }
    
    private func getBookDisplayName(_ bookId: String) -> String {
        let names: [String: String] = [
            "CET4_1": "四级核心词汇",
            "CET4_3": "四级完整词汇",
            "CET6_1": "六级核心词汇",
            "CET6_3": "六级完整词汇"
        ]
        return names[bookId] ?? bookId
    }
    
    private func exportData() {
        let data = DatabaseService.shared.exportData()
        
        guard !data.isEmpty else {
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let fileURL = desktopURL.appendingPathComponent("moyu_export.json")
            
            try jsonData.write(to: fileURL)
            showExportSuccess = true
        } catch {
            print("导出失败: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: themeIcon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Color(hex: "#0077b6") : .gray)
                    .frame(width: 20)
                
                Text(theme.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3d5a80"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#0077b6"))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color(hex: "#0077b6").opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private var themeIcon: String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

struct BookResetRow: View {
    let bookId: String
    let bookName: String
    let onReset: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var progress: (current: Int, total: Int) {
        DatabaseService.shared.getProgress(for: bookId)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookName)
                    .font(.system(size: 13))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3d5a80"))
                
                Text("\(progress.current)/\(progress.total)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onReset) {
                Text("重置")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#e76f51"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#e76f51").opacity(0.1))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct DataManagementRow: View {
    let title: String
    let count: Int
    let icon: String
    var action: (() -> Void)? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Text(icon)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3d5a80"))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#0077b6"))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

