import SwiftUI
import AppKit

@main
struct MoyuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(width: 300, height: 150)
                .background(Color(hex: "#d7e1ec"))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupGlobalShortcuts()
        
        // 设置开机启动
        if UserDefaults.standard.bool(forKey: "launchAtLogin") {
            // 开机启动逻辑
        }
        
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
        
        menu.addItem(NSMenuItem.separator())
        
        // 开机启动
        let launchItem = NSMenuItem(title: "开机启动", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = UserDefaults.standard.bool(forKey: "launchAtLogin") ? .on : .off
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
        // Cmd+M 关闭窗口
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "m" {
                if let window = NSApplication.shared.mainWindow {
                    window.close()
                }
            }
        }
    }
    
    @objc func showMainWindow() {
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else {
            // 创建新窗口
            let contentView = ContentView().environmentObject(AppState.shared)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.contentView = NSHostingView(rootView: contentView)
            window.level = .floating
            window.backgroundColor = NSColor(hex: "#d7e1ec")
            
            // 定位到屏幕右上角
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let x = screenRect.maxX - 300
                let y = screenRect.maxY - 150
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func setWordCount(_ sender: NSMenuItem) {
        AppState.shared.defaultWordCount = sender.tag
        UserDefaults.standard.set(sender.tag, forKey: "defaultWordCount")
        
        // 更新菜单状态
        if let menu = sender.menu {
            for item in menu.items {
                item.state = item.tag == sender.tag ? .on : .off
            }
        }
    }
    
    @objc func selectBook(_ sender: NSMenuItem) {
        if let bookId = sender.representedObject as? String {
            AppState.shared.currentBook = bookId
            DatabaseService.shared.updateCurrentBook(bookId)
            
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
        sender.state = newState ? .on : .off
        UserDefaults.standard.set(newState, forKey: "launchAtLogin")
        // 实际的开机启动需要使用 SMLoginItemSetEnabled 或 LaunchAtLogin 库
    }
    
    @objc func openHelp() {
        if let url = URL(string: "https://github.com/Charliecheung2/toastfish-mac/blob/master/README.md") {
            NSWorkspace.shared.open(url)
        }
    }
}
