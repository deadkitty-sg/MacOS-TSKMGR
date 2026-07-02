import SwiftUI

struct AppHistoryPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var language
    @ObservedObject var monitor: SystemMonitor
    let onSearchWeb: (String) -> Void = { query in
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
    let onShowProperties: (AppHistoryRowData) -> Void = { row in
        guard !row.path.isEmpty else { return }
        let script = """
        tell application "Finder"
            activate
            set targetItem to POSIX file "\(row.path)" as alias
            open information window of targetItem
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
    @State private var selectedRowID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(usageSinceText)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.primaryText(colorScheme))
                Button(language.text("删除使用情况历史记录", "Delete usage history")) {
                    monitor.clearAppHistory()
                }
                .buttonStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.13, green: 0.36, blue: 0.82))
            }
            .padding(.top, 18)
            .padding(.leading, 8)
            .padding(.trailing, 14)
            .padding(.bottom, 10)

            MetricTable(
                rows: monitor.appHistoryRows,
                columns: columns,
                initialSortColumnID: "cpuTime",
                initialAscending: false,
                minUsableWidth: 600,
                rowHeight: 32,
                topPadding: 0,
                showsInactiveSortArrow: true,
                isSelected: { $0.id == selectedRowID },
                onSelect: { selectedRowID = $0.id },
                rowMenu: { row in
                    Button(language.text("在线搜索", "Search online")) { onSearchWeb(row.name) }
                    Button(language.text("属性", "Properties")) { onShowProperties(row) }
                }
            )
        }
    }

    private var usageSinceText: String {
        guard let bootDate = monitor.systemBootDate() else {
            return language.text("当前用户帐户的资源使用情况。", "Resource usage for the current account.")
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.isChinese ? "zh_CN" : "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateText = formatter.string(from: bootDate)
        return language.text(
            "自 \(dateText) 以来，当前用户帐户的资源使用情况。",
            "Resource usage for the current account since \(dateText)."
        )
    }

    private var columns: [MetricColumn<AppHistoryRowData>] {
        [
            MetricColumn(
                id: "name",
                title: language.text("名称", "Name"),
                baseWidth: 210,
                comparator: { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                cell: { AnyView(MetricTableNameCell(icon: $0.icon, name: $0.name)) }
            ),
            .text(id: "cpuTime", title: language.text("CPU 时间", "CPU time"), baseWidth: 110,
                  headerAlignment: .center, cellAlignment: .trailing, defaultAscending: false,
                  comparator: { $0.cpuSeconds < $1.cpuSeconds }, value: { $0.cpuTime }),
            .text(id: "network", title: language.text("网络", "Network"), baseWidth: 110,
                  headerAlignment: .center, cellAlignment: .trailing, defaultAscending: false,
                  comparator: { $0.networkBytes < $1.networkBytes }, value: { $0.network }),
            .text(id: "meteredNetwork", title: language.text("按流量计费的网络", "Metered net"), baseWidth: 118,
                  headerAlignment: .center, cellAlignment: .trailing, defaultAscending: false,
                  comparator: { $0.meteredNetworkBytes < $1.meteredNetworkBytes }, value: { $0.meteredNetwork }),
        ]
    }
}
