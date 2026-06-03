import SwiftUI
import AppKit
import ServiceManagement
import UniformTypeIdentifiers

@main
struct MoyuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .background(MoyuTheme.appBackground(.light))
        }
        .windowStyle(.hiddenTitleBar)
        // 允许用户调整窗口大小
        .windowResizability(.automatic)
        .defaultPosition(.topTrailing)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 Moyu") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Moyu 摸鱼背单词",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0.0"
                        ]
                    )
                }
            }
        }
        
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupGlobalShortcuts()
        
        UserDefaults.standard.set(SMAppService.mainApp.status == .enabled, forKey: "launchAtLogin")
        
        // 隐藏 Dock 图标（可选）
        // NSApp.setActivationPolicy(.accessory)
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: "Moyu")
            button.image?.size = NSSize(width: 18, height: 18)
        }
        
        let menu = NSMenu()
        
        // 开始背词
        let startItem = NSMenuItem(title: "开始背词", action: #selector(showMainWindow), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 默认背词个数子菜单
        let countMenu = NSMenu()
        for count in [5, 10, 15, 20] {
            let item = NSMenuItem(title: "\(count)", action: #selector(setWordCount(_:)), keyEquivalent: "")
            item.tag = count
            item.target = self
            if count == AppState.shared.defaultWordCount {
                item.state = .on
            }
            countMenu.addItem(item)
        }
        let countItem = NSMenuItem(title: "默认背词个数", action: nil, keyEquivalent: "")
        countItem.submenu = countMenu
        menu.addItem(countItem)
        
        // 英语词汇子菜单
        let englishMenu = NSMenu()
        let englishBooks: [(String, String)] = [
            ("CET4_1", "四级核心词汇"),
            ("CET4_3", "四级完整词汇"),
            ("CET6_1", "六级核心词汇"),
            ("CET6_3", "六级完整词汇"),
            ("GMAT_3", "GMAT词汇"),
            ("GRE_2", "GRE词汇"),
            ("IELTS_3", "IELTS词汇"),
            ("TOEFL_2", "TOEFL词汇"),
            ("SAT_2", "SAT词汇"),
            ("KaoYan_1", "考研必备词汇"),
            ("KaoYan_2", "考研完整词汇"),
            ("Level4_1", "专四真题高频词"),
            ("Level4luan_2", "专四核心词汇"),
            ("Level8_1", "专八真题高频词"),
            ("Level8luan_2", "专八核心词汇")
        ]
        for (id, name) in englishBooks {
            let progress = DatabaseService.shared.getProgress(for: id)
            let item = NSMenuItem(title: "\(name)(\(progress.current)/\(progress.total))", action: #selector(selectBook(_:)), keyEquivalent: "")
            item.representedObject = id
            item.target = self
            if id == AppState.shared.currentBook {
                item.state = .on
            }
            englishMenu.addItem(item)
        }
        let englishItem = NSMenuItem(title: "英语词汇", action: nil, keyEquivalent: "")
        englishItem.submenu = englishMenu
        menu.addItem(englishItem)
        
        // 日语词汇子菜单
        let japaneseMenu = NSMenu()
        let japaneseBooks: [(String, String)] = [
            ("Goin", "五十音"),
            ("StdJp_Mid", "标日中级词汇")
        ]
        for (id, name) in japaneseBooks {
            let progress = DatabaseService.shared.getProgress(for: id)
            let item = NSMenuItem(title: "\(name)(\(progress.current)/\(progress.total))", action: #selector(selectBook(_:)), keyEquivalent: "")
            item.representedObject = id
            item.target = self
            if id == AppState.shared.currentBook {
                item.state = .on
            }
            japaneseMenu.addItem(item)
        }
        let japaneseItem = NSMenuItem(title: "日语词汇", action: nil, keyEquivalent: "")
        japaneseItem.submenu = japaneseMenu
        menu.addItem(japaneseItem)
        
        // 扩展词库子菜单 (新导入)
        let extraMenu = NSMenu()
        let extraBooks: [(String, String)] = [
            ("COCA_20000", "COCA常用20000词"),
            ("GRE_8000", "GRE 8000词"),
            ("TOEFL_Extra", "托福扩展词汇"),
            ("NPEE", "考研英语词汇"),
            ("CET4_Extra", "四级扩展"),
            ("CET6_Extra", "六级扩展")
        ]
        for (id, name) in extraBooks {
            let progress = DatabaseService.shared.getProgress(for: id)
            if progress.total > 0 {
                let item = NSMenuItem(title: "\(name)(\(progress.current)/\(progress.total))", action: #selector(selectBook(_:)), keyEquivalent: "")
                item.representedObject = id
                item.target = self
                if id == AppState.shared.currentBook {
                    item.state = .on
                }
                extraMenu.addItem(item)
            }
        }
        let extraItem = NSMenuItem(title: "扩展词库", action: nil, keyEquivalent: "")
        extraItem.submenu = extraMenu
        menu.addItem(extraItem)
        
        // 自定义词库子菜单
        let customMenu = NSMenu()
        // 导入按钮
        let importItem = NSMenuItem(title: "导入自定义词库…", action: #selector(importCustomBook), keyEquivalent: "")
        importItem.target = self
        customMenu.addItem(importItem)
        customMenu.addItem(NSMenuItem.separator())
        
        let customBooks = DatabaseService.shared.getCustomBooks()
        if customBooks.isEmpty {
            let emptyItem = NSMenuItem(title: "暂无自定义词库", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            customMenu.addItem(emptyItem)
        } else {
            for (id, name, progress) in customBooks {
                let item = NSMenuItem(title: "\(name)(\(progress.current)/\(progress.total))", action: #selector(selectBook(_:)), keyEquivalent: "")
                item.representedObject = id
                item.target = self
                if id == AppState.shared.currentBook {
                    item.state = .on
                }
                customMenu.addItem(item)
            }
        }
        let customItem = NSMenuItem(title: "自定义词库", action: nil, keyEquivalent: "")
        customItem.submenu = customMenu
        menu.addItem(customItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 开机启动
        let launchItem = NSMenuItem(title: "开机启动", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchItem)
        
        // 使用说明
        let helpItem = NSMenuItem(title: "使用说明", action: #selector(openHelp), keyEquivalent: "")
        helpItem.target = self
        menu.addItem(helpItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func setupGlobalShortcuts() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKey(event: event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKey(event: event)
            return event
        }
    }
    
    private func handleGlobalKey(event: NSEvent) {
        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return }

        let shortcut = AppState.shared.stealthShortcut
        if shortcut.matches(chars: chars, modifiers: event.modifierFlags, wake: false) {
            if let window = NSApplication.shared.mainWindow {
                window.close()
            }
            return
        }

        if shortcut.matches(chars: chars, modifiers: event.modifierFlags, wake: true) {
            showMainWindow()
        }
    }
    
    // MARK: - Custom Book Import
    @objc func importCustomBook() {
        let panel = NSOpenPanel()
        panel.title = "选择自定义词库文件"
        panel.allowedContentTypes = [.commaSeparatedText, .json]
        panel.allowsMultipleSelection = false
        
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()
            let result: WordImportParseResult
            if ext == "json" {
                result = try parseJSONWordList(data: data)
            } else {
                let content = String(data: data, encoding: .utf8) ?? ""
                result = parseCSVWordList(csv: content)
            }
            
            guard !result.words.isEmpty else {
                showAlert(title: "导入失败", message: result.errors.prefix(5).joined(separator: "\n").isEmpty ? "未解析到词条，请检查文件格式" : result.errors.prefix(5).joined(separator: "\n"))
                return
            }
            
            let fileName = url.deletingPathExtension().lastPathComponent
            let bookId = makeCustomBookId(from: fileName)

            guard confirmImport(fileName: fileName, result: result) else { return }
            
            DatabaseService.shared.importCustomBook(
                bookName: bookId,
                displayName: fileName,
                words: result.words
            )
            
            // 更新当前词库为新导入的
            AppState.shared.setCurrentBook(bookId)
            
            // 重新构建菜单以刷新显示
            setupStatusBar()
            
            showAlert(title: "导入成功", message: "已导入 \(result.words.count) 条词汇")
        } catch {
            showAlert(title: "导入失败", message: error.localizedDescription)
        }
    }
    
    private func parseJSONWordList(data: Data) throws -> WordImportParseResult {
        // 预期格式：数组对象，每项含 headWord, tranCN, usphone?, phrase?, phraseCN?
        var errors: [String] = []
        if let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let words = arr.enumerated().compactMap { index, dict -> WordImport? in
                guard let head = dict["headWord"] as? String ?? dict["word"] as? String,
                      let tran = dict["tranCN"] as? String ?? dict["meaning"] as? String else {
                    errors.append("第 \(index + 1) 条缺少 word/headWord 或 meaning/tranCN")
                    return nil
                }
                let usphone = dict["usphone"] as? String ?? ""
                let phrase = dict["phrase"] as? String ?? ""
                let phraseCN = dict["phraseCN"] as? String ?? ""
                return WordImport(headWord: head, tranCN: tran, usphone: usphone, phrase: phrase, phraseCN: phraseCN)
            }
            return WordImportParseResult(words: words, errors: errors)
        }
        return WordImportParseResult(words: [], errors: ["JSON 顶层必须是数组"])
    }
    
    private func parseCSVWordList(csv: String) -> WordImportParseResult {
        // 列顺序：headWord, tranCN, usphone?, phrase?, phraseCN?
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var result: [WordImport] = []
        var errors: [String] = []

        for (lineIndex, line) in lines.enumerated() {
            let cols = parseCSVLine(line)
            if lineIndex == 0,
               let first = cols.first?.lowercased(),
               ["word", "headword", "单词"].contains(first) {
                continue
            }

            guard cols.count >= 2 else {
                errors.append("第 \(lineIndex + 1) 行列数不足")
                continue
            }
            let head = cols[0]
            let tran = cols[1]
            let usphone = cols.count > 2 ? cols[2] : ""
            let phrase = cols.count > 3 ? cols[3] : ""
            let phraseCN = cols.count > 4 ? cols[4] : ""
            if !head.isEmpty, !tran.isEmpty {
                result.append(WordImport(headWord: head, tranCN: tran, usphone: usphone, phrase: phrase, phraseCN: phraseCN))
            } else {
                errors.append("第 \(lineIndex + 1) 行单词或释义为空")
            }
        }
        return WordImportParseResult(words: result, errors: errors)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let char = iterator.next() {
            if char == "\"" {
                if inQuotes, let next = iterator.next() {
                    if next == "\"" {
                        current.append("\"")
                    } else {
                        inQuotes = false
                        if next == "," {
                            columns.append(current.trimmingCharacters(in: .whitespaces))
                            current = ""
                        } else {
                            current.append(next)
                        }
                    }
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                columns.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }

        columns.append(current.trimmingCharacters(in: .whitespaces))
        return columns
    }

    private func makeCustomBookId(from fileName: String) -> String {
        let safe = fileName.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "_"
        }
        let id = String(safe).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return "custom_\(id.isEmpty ? UUID().uuidString.replacingOccurrences(of: "-", with: "_") : id)"
    }

    private func confirmImport(fileName: String, result: WordImportParseResult) -> Bool {
        let preview = result.words.prefix(5)
            .map { "\($0.headWord) - \($0.tranCN)" }
            .joined(separator: "\n")
        let errorText = result.errors.isEmpty ? "" : "\n\n跳过 \(result.errors.count) 行：\n\(result.errors.prefix(3).joined(separator: "\n"))"

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "导入「\(fileName)」？"
        alert.informativeText = "将导入 \(result.words.count) 条词汇。\n\n预览：\n\(preview)\(errorText)"
        alert.addButton(withTitle: "导入")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = title
            alert.informativeText = message
            alert.runModal()
        }
    }
    
    @objc func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        // 获取保存的窗口尺寸
        let savedWidth = AppState.shared.compactMode ? 340 : AppState.shared.windowWidth
        let savedHeight = AppState.shared.compactMode ? 240 : AppState.shared.windowHeight
        
        // 创建新窗口（可调整尺寸）
        let contentView = ContentView().environmentObject(AppState.shared)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: savedWidth, height: savedHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Moyu 摸鱼背单词"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)
        window.level = .floating
        window.backgroundColor = NSColor(hex: "#eef2f6")
        window.setContentSize(NSSize(width: savedWidth, height: savedHeight))
        window.minSize = NSSize(width: 340, height: 240)
        window.maxSize = NSSize(width: 640, height: 560)
        window.alphaValue = min(max(AppState.shared.windowOpacity, 0.35), 1.0)
        
        // 定位到屏幕右上角
        if AppState.shared.pinToCorner, let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - window.frame.width
            let y = screenRect.maxY - window.frame.height
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // 监听窗口尺寸变化
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { notification in
            if let resizedWindow = notification.object as? NSWindow {
                let newSize = resizedWindow.frame.size
                AppState.shared.windowWidth = newSize.width
                AppState.shared.windowHeight = newSize.height
            }
        }
        
        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func setWordCount(_ sender: NSMenuItem) {
        AppState.shared.setDefaultWordCount(sender.tag)
        
        // 更新菜单状态
        if let menu = sender.menu {
            for item in menu.items {
                item.state = item.tag == sender.tag ? .on : .off
            }
        }
    }
    
    @objc func selectBook(_ sender: NSMenuItem) {
        if let bookId = sender.representedObject as? String {
            AppState.shared.setCurrentBook(bookId)
            
            // 更新菜单状态
            if let menu = sender.menu {
                for item in menu.items {
                    item.state = (item.representedObject as? String) == bookId ? .on : .off
                }
            }
        }
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = sender.state == .off
        do {
            if newState {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            sender.state = newState ? .on : .off
            UserDefaults.standard.set(newState, forKey: "launchAtLogin")
        } catch {
            showAlert(title: "开机启动设置失败", message: error.localizedDescription)
        }
    }
    
    @objc func openHelp() {
        if let url = URL(string: "https://github.com/Charliecheung2/toastfish-mac/blob/master/README.md") {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct WordImportParseResult {
    let words: [WordImport]
    let errors: [String]
}
