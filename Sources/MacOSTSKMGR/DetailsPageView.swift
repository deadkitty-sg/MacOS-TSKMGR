import SwiftUI

struct DetailsPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var language
    @ObservedObject var monitor: SystemMonitor
    @Binding var selectedPID: Int32?
    @Binding var memoryDisplayMode: ProcessResourceDisplayMode
    let onEndTask: (Int32) -> Void
    let onEndProcessTree: (Int32) -> Void
    let onRestartTask: (ProcessRowData) -> Void
    let onRevealInFinder: (String) -> Void
    let onSearchWeb: (String) -> Void
    let onShowProperties: (ProcessRowData) -> Void
    let onCopyProcessDetails: (ProcessRowData) -> Void
    let onOpenDetailsTab: (Int32) -> Void
    let onOpenServicesTab: () -> Void
    let onSetPriority: (Int32, ProcessPriorityPreset) -> Void
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProcessSearchField(text: $searchText, colorScheme: colorScheme, language: language)
                .frame(maxWidth: 340, alignment: .leading)
                .padding(.top, 18)
                .padding(.leading, 8)
                .padding(.trailing, 14)
                .padding(.bottom, 8)

            MetricTable(
                rows: filteredRows,
                columns: columns,
                initialSortColumnID: "memory",
                initialAscending: false,
                minUsableWidth: 900,
                topPadding: 0,
                isSelected: { selectedPID == $0.pid },
                onSelect: { selectedPID = $0.pid },
                rowMenu: { detailsContextMenu(for: $0) }
            )
        }
    }

    private var filteredRows: [DetailProcessRowData] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return monitor.detailProcessRows }
        return monitor.detailProcessRows.filter { row in
            row.name.lowercased().contains(query)
                || String(row.pid).contains(query)
                || row.userName.lowercased().contains(query)
        }
    }

    private var columns: [MetricColumn<DetailProcessRowData>] {
        [
            MetricColumn(
                id: "name",
                title: language.text("名称", "Name"),
                baseWidth: 220,
                comparator: { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                cell: { AnyView(MetricTableNameCell(icon: $0.icon, name: $0.name)) }
            ),
            .text(id: "pid", title: "PID", baseWidth: 70, defaultAscending: false,
                  comparator: { $0.pid < $1.pid }, value: { "\($0.pid)" }),
            .text(id: "status", title: language.text("状态", "Status"), baseWidth: 120,
                  comparator: { $0.status.localizedStandardCompare($1.status) == .orderedAscending },
                  value: { language.localizeProcessStatus($0.status) }),
            .text(id: "user", title: language.text("用户名", "User name"), baseWidth: 120,
                  comparator: { $0.userName.localizedStandardCompare($1.userName) == .orderedAscending },
                  value: { $0.userName }),
            .text(id: "cpu", title: "CPU", baseWidth: 70, defaultAscending: false,
                  comparator: { $0.cpuPercent < $1.cpuPercent },
                  value: { DisplayFormat.percentWithPrecision($0.cpuPercent, digits: 1) }),
            .text(id: "memory", title: language.text("内存(活动...)", "Memory (act...)"), baseWidth: 96, defaultAscending: false,
                  comparator: { $0.memoryBytes < $1.memoryBytes },
                  value: { memoryText(for: $0) }),
            .text(id: "platform", title: language.text("平台", "Platform"), baseWidth: 90,
                  comparator: { $0.platform.localizedStandardCompare($1.platform) == .orderedAscending },
                  value: { language.localizePlatform($0.platform) }),
        ]
    }

    private func detailsContextMenu(for row: DetailProcessRowData) -> some View {
        let processRow = toProcessRow(row)
        return Group {
            if shouldShowRestartInsteadOfTerminate(processRow) {
                Button(language.text("重新启动", "Restart")) {
                    selectedPID = row.pid
                    onRestartTask(processRow)
                }
            } else if canTerminate(processRow) {
                Button(language.text("结束任务", "End task")) {
                    selectedPID = row.pid
                    onEndTask(row.pid)
                }
                Button(language.text("结束进程树", "End process tree")) {
                    selectedPID = row.pid
                    onEndProcessTree(row.pid)
                }
            } else if canRestart(processRow) {
                Button(language.text("重新启动", "Restart")) {
                    selectedPID = row.pid
                    onRestartTask(processRow)
                }
            }

            Menu(language.text("设置优先级", "Set priority")) {
                ForEach(ProcessPriorityPreset.allCases, id: \.niceValue) { preset in
                    Button(preset.title(in: language)) {
                        onSetPriority(row.pid, preset)
                    }
                }
            }

            Button(language.text("打开文件所在的位置", "Open file location")) {
                onRevealInFinder(processRow.path)
            }
            .disabled(processRow.path.isEmpty)

            Button(language.text("在线搜索", "Search online")) {
                onSearchWeb(row.name)
            }

            Button(language.text("属性", "Properties")) {
                onShowProperties(processRow)
            }

            Button(language.text("转到服务", "Go to service")) {
                onOpenServicesTab()
            }

            Divider()

            Button(language.text("复制", "Copy")) {
                onCopyProcessDetails(processRow)
            }
        }
    }

    private func toProcessRow(_ row: DetailProcessRowData) -> ProcessRowData {
        let path = monitor.pidPath(pid: row.pid)
        return ProcessRowData(
            pid: row.pid,
            name: row.name,
            icon: row.icon,
            path: path,
            isApp: path.hasSuffix(".app") || path.contains("/Applications/") || path.contains("/System/Applications/"),
            isParent: false,
            parentPID: nil,
            childCount: 0,
            cpuPercent: row.cpuPercent,
            memoryBytes: row.memoryBytes,
            diskBytesPerSecond: 0,
            networkBytesPerSecond: 0,
            networkText: "0 Mbps",
            powerUsageWatts: 0,
            powerTrendWatts: 0,
            powerImpact: "",
            trend: "",
            threadCount: 0,
            openFiles: 0
        )
    }

    private func canTerminate(_ row: ProcessRowData) -> Bool {
        row.pid > 1 && row.pid != Int32(ProcessInfo.processInfo.processIdentifier)
    }

    private func canRestart(_ row: ProcessRowData) -> Bool {
        !canTerminate(row) && row.isApp && !row.path.isEmpty
    }

    private func shouldShowRestartInsteadOfTerminate(_ row: ProcessRowData) -> Bool {
        let lowerName = row.name.lowercased()
        let lowerPath = row.path.lowercased()
        return lowerName == "finder" || lowerName == "访达" || lowerPath.contains("/system/library/coreservices/finder.app")
    }

    private func memoryText(for row: DetailProcessRowData) -> String {
        switch memoryDisplayMode {
        case .value:
            return DisplayFormat.memory(row.memoryBytes)
        case .percent:
            guard monitor.memory.totalBytes > 0 else { return "0%" }
            let percent = Double(row.memoryBytes) / Double(monitor.memory.totalBytes) * 100
            return DisplayFormat.percentWithPrecision(percent, digits: 1)
        }
    }
}
