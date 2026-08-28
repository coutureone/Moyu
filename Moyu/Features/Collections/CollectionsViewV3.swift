import SwiftUI

// MARK: - Wrong Book View v3.0
/// 错词本 - 全新设计
struct WrongBookViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var wordToDelete: Word?

    var filteredWords: [Word] {
        if searchText.isEmpty {
            return appState.wrongBookWords
        }
        return appState.wrongBookWords.filter {
            $0.word.localizedCaseInsensitiveContains(searchText) ||
            $0.meanings.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            MoyuDivider()

            if appState.wrongBookWords.isEmpty {
                // 空状态
                emptyState
            } else {
                // 内容区域
                contentSection
            }
        }
        .background(DesignTokens.Colors.background(for: colorScheme))
        .onAppear {
            appState.loadWrongBook()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                IconButton(icon: "chevron.left", size: 32) {
                    appState.currentPage = .home
                }

                Spacer()

                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text("错词本")
                        .font(DesignTokens.Typography.h3)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                    Text("\(appState.wrongBookWords.count) 词")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                }

                Spacer()

                IconButton(icon: "trash", size: 32) {
                    // TODO: 清空确认
                }
            }

            // 搜索框
            if !appState.wrongBookWords.isEmpty {
                MoyuTextField(
                    "搜索单词...",
                    text: $searchText,
                    icon: "magnifyingglass"
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface(for: colorScheme))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "book.closed",
            title: "错词本为空",
            message: "学习过程中答错的单词会自动添加到这里",
            actionTitle: "开始学习",
            action: {
                appState.currentPage = .home
            }
        )
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 0) {
            // 单词列表
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(filteredWords, id: \.id) { word in
                        WordRowView(
                            word: word,
                            onDelete: {
                                wordToDelete = word
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }

            // 底部操作栏
            if !appState.wrongBookWords.isEmpty {
                bottomActionBar
            }
        }
        .alert("删除单词", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let word = wordToDelete {
                    deleteWord(word)
                }
            }
        } message: {
            Text("确定要从错词本中删除这个单词吗？")
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            MoyuDivider()

            HStack(spacing: DesignTokens.Spacing.sm) {
                SecondaryButton("复习全部", icon: "arrow.clockwise") {
                    startPractice()
                }

                PrimaryButton("开始练习", icon: "play.fill") {
                    startPractice()
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface(for: colorScheme))
        }
    }

    // MARK: - Actions

    private func deleteWord(_ word: Word) {
        DatabaseService.shared.removeFromWrongBook(word: word)
        appState.loadWrongBook()
    }

    private func startPractice() {
        appState.currentPage = .practiceSession(
            words: appState.wrongBookWords,
            source: .wrongBook
        )
    }
}

// MARK: - Favorites View v3.0
/// 收藏夹 - 全新设计
struct FavoritesViewV3: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var wordToDelete: Word?

    var filteredWords: [Word] {
        if searchText.isEmpty {
            return appState.favoriteWords
        }
        return appState.favoriteWords.filter {
            $0.word.localizedCaseInsensitiveContains(searchText) ||
            $0.meanings.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            navigationBar

            MoyuDivider()

            if appState.favoriteWords.isEmpty {
                // 空状态
                emptyState
            } else {
                // 内容区域
                contentSection
            }
        }
        .background(DesignTokens.Colors.background(for: colorScheme))
        .onAppear {
            appState.loadFavorites()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                IconButton(icon: "chevron.left", size: 32) {
                    appState.currentPage = .home
                }

                Spacer()

                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text("收藏夹")
                        .font(DesignTokens.Typography.h3)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                    Text("\(appState.favoriteWords.count) 词")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                }

                Spacer()

                IconButton(icon: "trash", size: 32) {
                    // TODO: 清空确认
                }
            }

            // 搜索框
            if !appState.favoriteWords.isEmpty {
                MoyuTextField(
                    "搜索单词...",
                    text: $searchText,
                    icon: "magnifyingglass"
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface(for: colorScheme))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "star",
            title: "收藏夹为空",
            message: "点击单词旁的星标图标收藏重点单词",
            actionTitle: "开始学习",
            action: {
                appState.currentPage = .home
            }
        )
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 0) {
            // 单词列表
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(filteredWords, id: \.id) { word in
                        WordRowView(
                            word: word,
                            onDelete: {
                                wordToDelete = word
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }

            // 底部操作栏
            if !appState.favoriteWords.isEmpty {
                bottomActionBar
            }
        }
        .alert("删除单词", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let word = wordToDelete {
                    deleteWord(word)
                }
            }
        } message: {
            Text("确定要从收藏夹中删除这个单词吗？")
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            MoyuDivider()

            HStack(spacing: DesignTokens.Spacing.sm) {
                SecondaryButton("复习全部", icon: "arrow.clockwise") {
                    startPractice()
                }

                PrimaryButton("开始学习", icon: "play.fill") {
                    startPractice()
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface(for: colorScheme))
        }
    }

    // MARK: - Actions

    private func deleteWord(_ word: Word) {
        DatabaseService.shared.removeFromFavorites(word: word)
        appState.loadFavorites()
    }

    private func startPractice() {
        appState.currentPage = .practiceSession(
            words: appState.favoriteWords,
            source: .favorites
        )
    }
}

// MARK: - Word Row View (共用组件)

struct WordRowView: View {
    let word: Word
    let onDelete: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false

    var body: some View {
        Button(action: {
            withAnimation(DesignTokens.Animation.spring) {
                isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    // 单词
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text(word.word)
                            .font(DesignTokens.Typography.h4)
                            .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                        if let phonetic = word.phonetic {
                            Text("[\(phonetic)]")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    // 删除按钮
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.error)
                    }
                    .buttonStyle(.plain)

                    // 展开图标
                    Image(systemName: "chevron.right")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary(for: colorScheme))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }

                // 释义预览
                if !isExpanded {
                    Text(word.meanings.split(separator: ";").first.map(String.init) ?? "")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }

                // 展开内容
                if isExpanded {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        MoyuDivider()

                        // 完整释义
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            ForEach(word.meanings.split(separator: ";"), id: \.self) { meaning in
                                HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                                    Text("•")
                                        .foregroundColor(DesignTokens.Colors.primary)
                                    Text(String(meaning).trimmingCharacters(in: .whitespaces))
                                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                                }
                                .font(DesignTokens.Typography.body)
                            }
                        }

                        // 例句
                        if let example = word.example, !example.isEmpty {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text(example)
                                    .font(DesignTokens.Typography.bodySmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                                    .italic()

                                if let translation = word.translation, !translation.isEmpty {
                                    Text(translation)
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textTertiary(for: colorScheme))
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .strokeBorder(
                        colorScheme == .dark ? DesignTokens.Colors.border(for: colorScheme) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: DesignTokens.Shadow.sm(for: colorScheme).color,
                radius: DesignTokens.Shadow.sm(for: colorScheme).radius,
                y: DesignTokens.Shadow.sm(for: colorScheme).y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews
#Preview("Wrong Book") {
    WrongBookViewV3()
        .environmentObject({
            let state = AppState()
            state.wrongBookWords = [
                Word(id: 1, word: "abandon", phonetic: "əˈbændən", meanings: "v. 放弃；抛弃")
            ]
            return state
        }())
}

#Preview("Favorites") {
    FavoritesViewV3()
        .environmentObject({
            let state = AppState()
            state.favoriteWords = [
                Word(id: 1, word: "abandon", phonetic: "əˈbændən", meanings: "v. 放弃；抛弃")
            ]
            return state
        }())
}
