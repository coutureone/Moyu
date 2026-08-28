import SwiftUI

// MARK: - Moyu Dropdown
/// 下拉选择器
struct MoyuDropdown: View {
    let title: String
    @Binding var selectedValue: Int
    let options: [Int]

    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // 标题
            if !title.isEmpty {
                Text(title)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
            }

            // 选择器
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(DesignTokens.Animation.fast) {
                            selectedValue = option
                        }
                    } label: {
                        HStack {
                            Text("\(option)")
                            if option == selectedValue {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("\(selectedValue)")
                        .font(DesignTokens.Typography.h3)
                        .foregroundColor(DesignTokens.Colors.text(for: colorScheme))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.surface(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.border(for: colorScheme), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Text Input
/// 文本输入框
struct MoyuTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?

    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary(for: colorScheme))
            }

            TextField(placeholder, text: $text)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.text(for: colorScheme))
                .focused($isFocused)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(
                    isFocused ? DesignTokens.Colors.primary : DesignTokens.Colors.border(for: colorScheme),
                    lineWidth: isFocused ? 2 : 1
                )
        )
    }
}

// MARK: - Previews
#Preview("Inputs") {
    VStack(spacing: 20) {
        MoyuDropdown(
            title: "学习数量",
            selectedValue: .constant(20),
            options: [10, 20, 30, 50, 100]
        )

        MoyuTextField("搜索单词...", text: .constant(""), icon: "magnifyingglass")
    }
    .padding(20)
}
