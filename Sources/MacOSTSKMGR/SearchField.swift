import SwiftUI

/// Reusable search/filter field shared by the Processes, Details, Users,
/// Services and Startup tabs.
struct ProcessSearchField: View {
    @Binding var text: String
    let colorScheme: ColorScheme
    let language: AppLanguage
    var placeholder: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField(placeholder ?? language.text("筛选进程", "Filter processes"), text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(language.text("清除", "Clear"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.tableHeader(colorScheme), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppTheme.separator(colorScheme), lineWidth: 1)
        )
    }
}
