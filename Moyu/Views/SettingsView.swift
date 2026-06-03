import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Settings View (设置页面)
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var showResetAlert = false
    @State private var bookToReset: String = ""
    @State private var allBooks: [BookInfo] = []
    @State private var wrongBookCount = 0
    @State private var favoritesCount = 0
    @State private var unlockedAchievementsCount = 0
    @State private var confirmation: SettingsConfirmation?
    @State private var statusMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 外观设置
                appearanceSection
                
                // 学习设置
                learningSection
                
                // 提醒设置
                reminderSection

                // 摸鱼模式
                stealthSection
                
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
        .onAppear {
            reloadManagementData()
        }
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                appState.resetBookProgress(book: bookToReset)
                reloadManagementData()
            }
        } message: {
            Text("确定要重置「\(getBookDisplayName(bookToReset))」的学习进度吗？此操作不可恢复。")
        }
        .alert(item: $confirmation) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                primaryButton: .destructive(Text(item.confirmTitle)) {
                    runConfirmation(item)
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
    
    // MARK: - Components
    
    private var backgroundColor: Color {
        MoyuTheme.appBackground(colorScheme)
    }
    
    private var cardBackground: Color {
        MoyuTheme.cardBackground(colorScheme)
    }
    
    private var textColor: Color {
        MoyuTheme.textColor(colorScheme)
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "🎨", title: "外观设置")
            
            VStack(alignment: .leading, spacing: 10) {
                Picker("外观", selection: $appState.appTheme) {
                    ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                        Label(theme.displayName, systemImage: theme.systemImage)
                            .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(appState.appTheme == .system ? "跟随 macOS 当前外观设置" : "已固定为\(appState.appTheme.displayName)")
                    .font(.system(size: 11))
                    .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
            }
            .padding(12)
            .moyuCard(colorScheme)
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
                                appState.setDefaultWordCount(count)
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
            .moyuCard(colorScheme)
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
            .moyuCard(colorScheme)
        }
    }

    private var stealthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "🫥", title: "摸鱼模式")

            VStack(spacing: 12) {
                Toggle(isOn: $appState.compactMode) {
                    Text("小窗模式")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                }
                .toggleStyle(.switch)

                Divider()

                Toggle(isOn: $appState.pinToCorner) {
                    Text("固定在右上角")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                }
                .toggleStyle(.switch)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("窗口透明度")
                            .font(.system(size: 13))
                            .foregroundColor(textColor)
                        Spacer()
                        Text("\(Int(appState.windowOpacity * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(MoyuTheme.primary)
                    }
                    Slider(value: $appState.windowOpacity, in: 0.35...1.0, step: 0.05)
                        .tint(MoyuTheme.primary)
                }

                Divider()

                HStack {
                    Text("隐藏 / 唤醒")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)

                    Spacer()

                    Picker("", selection: $appState.stealthShortcut) {
                        ForEach(StealthShortcut.allCases, id: \.rawValue) { shortcut in
                            Text(shortcut.displayName).tag(shortcut)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 210)
                }

                Divider()

                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(MoyuTheme.primary)
                    Text("唤醒 \(appState.stealthShortcut.wakeLabel)，隐藏 \(appState.stealthShortcut.hideLabel) / Esc")
                        .font(.system(size: 12))
                        .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                    Spacer()
                }
            }
            .padding(12)
            .moyuCard(colorScheme)
        }
    }
    
    private var bookManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "📚", title: "词库管理")
            
            VStack(spacing: 8) {
                Button(action: importCustomBookFromSettings) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("导入自定义词库")
                        Spacer()
                    }
                }
                .buttonStyle(MoyuSecondaryButtonStyle())
                .onHoverCursor()

                Divider()

                ForEach(allBooks) { book in
                    BookResetRow(
                        book: book,
                        onReset: {
                            bookToReset = book.id
                            showResetAlert = true
                        },
                        onRename: book.isCustom ? {
                            renameCustomBook(book)
                        } : nil,
                        onDelete: book.isCustom ? {
                            confirmation = .deleteCustomBook(book)
                        } : nil
                    )
                }
            }
            .padding(12)
            .moyuCard(colorScheme)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "💾", title: "数据管理")
            
            VStack(spacing: 8) {
                DataManagementRow(
                    title: "错词本",
                    count: wrongBookCount,
                    icon: "book.closed",
                    actionTitle: "清空",
                    actionTone: MoyuTheme.danger
                ) {
                    confirmation = .clearWrongBook
                }
                
                DataManagementRow(
                    title: "收藏夹",
                    count: favoritesCount,
                    icon: "star",
                    actionTitle: "清空",
                    actionTone: MoyuTheme.danger
                ) {
                    confirmation = .clearFavorites
                }
                
                DataManagementRow(
                    title: "已解锁成就",
                    count: unlockedAchievementsCount,
                    icon: "trophy",
                    actionTitle: nil,
                    actionTone: MoyuTheme.primary,
                    action: nil
                )

                Divider()

                HStack(spacing: 8) {
                    Button(action: exportLearningData) {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MoyuSecondaryButtonStyle())
                    .onHoverCursor()

                    Button(action: importLearningData) {
                        Label("导入数据", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MoyuSecondaryButtonStyle(tone: MoyuTheme.warning))
                    .onHoverCursor()
                }

                Button {
                    confirmation = .resetAllProgress
                } label: {
                    Label("重置全部学习进度", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MoyuSecondaryButtonStyle(tone: MoyuTheme.danger))
                .onHoverCursor()

                if let statusMessage {
                    Text(statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(MoyuTheme.secondaryTextColor(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .moyuCard(colorScheme)
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
        DatabaseService.shared.displayName(for: bookId)
    }

    private func reloadManagementData() {
        allBooks = DatabaseService.shared.getAllBooks()
        wrongBookCount = DatabaseService.shared.getWrongBookCount()
        favoritesCount = DatabaseService.shared.getFavoritesCount()
        unlockedAchievementsCount = DatabaseService.shared.getUnlockedAchievementsCount()
        appState.loadStatistics()
    }

    private func runConfirmation(_ item: SettingsConfirmation) {
        switch item {
        case .clearWrongBook:
            DatabaseService.shared.clearWrongBook()
            statusMessage = "错词本已清空"
        case .clearFavorites:
            DatabaseService.shared.clearFavorites()
            statusMessage = "收藏夹已清空"
        case .resetAllProgress:
            DatabaseService.shared.resetAllProgress()
            statusMessage = "全部学习进度已重置"
        case .deleteCustomBook(let book):
            DatabaseService.shared.deleteCustomBook(bookName: book.id)
            if appState.currentBook == book.id {
                appState.setCurrentBook("CET4_1")
            }
            statusMessage = "已删除「\(book.name)」"
        }
        reloadManagementData()
    }

    private func exportLearningData() {
        let panel = NSSavePanel()
        panel.title = "导出 Moyu 学习数据"
        panel.nameFieldStringValue = "Moyu-Data-\(Int(Date().timeIntervalSince1970)).db"
        panel.allowedContentTypes = [UTType(filenameExtension: "db") ?? .data]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try DatabaseService.shared.exportDatabase(to: url)
            statusMessage = "学习数据已导出"
        } catch {
            statusMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func importLearningData() {
        let panel = NSOpenPanel()
        panel.title = "导入 Moyu 学习数据"
        panel.allowedContentTypes = [UTType(filenameExtension: "db") ?? .data]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try DatabaseService.shared.importDatabase(from: url)
            appState.loadSettings()
            reloadManagementData()
            statusMessage = "学习数据已导入"
        } catch {
            statusMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    private func renameCustomBook(_ book: BookInfo) {
        let alert = NSAlert()
        alert.messageText = "重命名自定义词库"
        alert.informativeText = book.name
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        input.stringValue = book.name
        alert.accessoryView = input

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let newName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }

        DatabaseService.shared.renameCustomBook(bookName: book.id, displayName: newName)
        statusMessage = "词库已重命名"
        reloadManagementData()
    }

    private func importCustomBookFromSettings() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.importCustomBook()
            reloadManagementData()
        }
    }
}

private enum SettingsConfirmation: Identifiable {
    case clearWrongBook
    case clearFavorites
    case resetAllProgress
    case deleteCustomBook(BookInfo)

    var id: String {
        switch self {
        case .clearWrongBook: return "clearWrongBook"
        case .clearFavorites: return "clearFavorites"
        case .resetAllProgress: return "resetAllProgress"
        case .deleteCustomBook(let book): return "deleteCustomBook-\(book.id)"
        }
    }

    var title: String {
        switch self {
        case .clearWrongBook: return "清空错词本"
        case .clearFavorites: return "清空收藏夹"
        case .resetAllProgress: return "重置全部学习进度"
        case .deleteCustomBook(let book): return "删除「\(book.name)」"
        }
    }

    var message: String {
        switch self {
        case .clearWrongBook: return "所有错词记录都会被删除，此操作不可恢复。"
        case .clearFavorites: return "所有收藏记录都会被删除，此操作不可恢复。"
        case .resetAllProgress: return "所有词库进度、统计和成就都会重置，此操作不可恢复。"
        case .deleteCustomBook: return "自定义词库和关联的错词、收藏记录都会被删除，此操作不可恢复。"
        }
    }

    var confirmTitle: String {
        switch self {
        case .clearWrongBook, .clearFavorites: return "清空"
        case .resetAllProgress: return "重置"
        case .deleteCustomBook: return "删除"
        }
    }
}

// MARK: - Supporting Views

struct BookResetRow: View {
    let book: BookInfo
    let onReset: () -> Void
    let onRename: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(book.name)
                    .font(.system(size: 13))
                    .foregroundColor(MoyuTheme.textColor(colorScheme))
                
                Text("\(book.current)/\(book.total)\(book.isCustom ? " · 自定义" : "")")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()

            if let onRename {
                Button(action: onRename) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundColor(MoyuTheme.primary)
                .onHoverCursor()
            }
            
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

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundColor(MoyuTheme.danger)
                .onHoverCursor()
            }
        }
        .padding(.vertical, 4)
    }
}

struct DataManagementRow: View {
    let title: String
    let count: Int
    let icon: String
    let actionTitle: String?
    let actionTone: Color
    let action: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 18)
                .foregroundColor(MoyuTheme.primary)
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(MoyuTheme.textColor(colorScheme))
            Spacer()
            Text("\(count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#0077b6"))
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 11))
                    .foregroundColor(actionTone)
                    .buttonStyle(.plain)
                    .onHoverCursor()
            }
        }
        .padding(.vertical, 4)
    }
}
