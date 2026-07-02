import SwiftUI

private enum UsersColumnLayout {
    static let insetLeading: CGFloat = 8
    static let insetTrailing: CGFloat = 14
    static let scrollBarReserve: CGFloat = 18
    static let user: CGFloat = 330
    static let status: CGFloat = 120
    static let cpu: CGFloat = 88
    static let memory: CGFloat = 108
    static let disk: CGFloat = 96
    static let network: CGFloat = 88
    static let totalWidth: CGFloat = user + status + cpu + memory + disk + network
    static let rowHeight: CGFloat = 34
    static let headerHeight: CGFloat = 44
}

private enum UsersSortKey {
    case user
    case status
    case cpu
    case memory
    case disk
    case network
}

struct UsersPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var language
    @ObservedObject var monitor: SystemMonitor
    @Binding var selectedPID: Int32?
    @Binding var memoryDisplayMode: ProcessResourceDisplayMode
    @Binding var diskDisplayMode: ProcessResourceDisplayMode
    @Binding var networkDisplayMode: ProcessResourceDisplayMode
    let onEndTask: (Int32) -> Void
    let onRestartTask: (ProcessRowData) -> Void
    let onRevealInFinder: (String) -> Void
    let onSearchWeb: (String) -> Void
    let onShowProperties: (ProcessRowData) -> Void
    let onCopyProcessDetails: (ProcessRowData) -> Void
    let onOpenDetailsTab: (Int32) -> Void
    @State private var expanded = true
    @State private var sortKey: UsersSortKey = .memory
    @State private var ascending = false
    @State private var searchText = ""
    // Sorted output is cached and recomputed only when its inputs change, not on
    // every body evaluation (the monitor publishes ~every tick).
    @State private var displayedRows: [ProcessRowData] = []

    var body: some View {
        GeometryReader { proxy in
            let widths = scaledWidths(for: proxy.size.width)
            let rows = displayedRows
            let userName = monitor.currentUserSection?.userName ?? NSFullUserName()
            let totalCPU = rows.reduce(0.0) { $0 + $1.cpuPercent }
            let totalMemory = rows.reduce(UInt64(0)) { $0 + $1.memoryBytes }
            let totalDisk = rows.reduce(UInt64(0)) { $0 + $1.diskBytesPerSecond }
            let totalNetwork = rows.reduce(UInt64(0)) { $0 + $1.networkBytesPerSecond }

            VStack(alignment: .leading, spacing: 0) {
                ProcessSearchField(text: $searchText, colorScheme: colorScheme, language: language)
                    .frame(width: min(widths.total, 340), alignment: .leading)
                    .padding(.bottom, 8)

                HStack(spacing: 0) {
                    headerCell(language.text("用户", "User"), sortKey: .user, width: widths.user)
                    headerCell(language.text("状态", "Status"), sortKey: .status, width: widths.status)
                    metricHeaderCell(DisplayFormat.percent(totalCPU), label: "CPU", sortKey: .cpu, width: widths.cpu)
                    metricHeaderCell(DisplayFormat.memory(totalMemory), label: language.text("内存", "Memory"), sortKey: .memory, width: widths.memory)
                    metricHeaderCell(DisplayFormat.throughput(totalDisk), label: language.text("磁盘", "Disk"), sortKey: .disk, width: widths.disk)
                    metricHeaderCell(totalNetwork == 0 ? "0 Mbps" : DisplayFormat.networkRate(totalNetwork), label: language.text("网络", "Network"), sortKey: .network, width: widths.network)
                }
                .frame(width: widths.total, height: UsersColumnLayout.headerHeight, alignment: .leading)
                .background(AppTheme.tableHeader(colorScheme))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppTheme.strongSeparator(colorScheme)).frame(height: 1)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Button {
                            expanded.toggle()
                        } label: {
                            HStack(spacing: 0) {
                                HStack(spacing: 8) {
                                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("\(userName) (\(rows.count))")
                                        .font(.system(size: 15))
                                }
                                .foregroundStyle(Color(red: 0.16, green: 0.34, blue: 0.77))
                                .padding(.horizontal, 10)
                                .frame(width: widths.user, height: UsersColumnLayout.rowHeight, alignment: .leading)
                                .overlay(alignment: .trailing) {
                                    Rectangle().fill(Color.black.opacity(0.08)).frame(width: 1)
                                }

                                rowCell("", width: widths.status)
                                rowCell(DisplayFormat.percentWithPrecision(totalCPU, digits: 1), width: widths.cpu)
                                rowCell(summaryMemoryText(totalMemory), width: widths.memory)
                                rowCell(summaryDiskText(totalDisk), width: widths.disk)
                                rowCell(summaryNetworkText(totalNetwork), width: widths.network)
                            }
                        }
                        .buttonStyle(.plain)
                        .background(AppTheme.rowEven(colorScheme))

                        if expanded {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                HStack(spacing: 0) {
                                    HStack(spacing: 8) {
                                        Color.clear.frame(width: 12, height: 12)
                                        ProcessIconView(icon: row.icon)
                                        Text(row.name)
                                            .font(.system(size: 13))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .frame(width: widths.user, height: UsersColumnLayout.rowHeight, alignment: .leading)
                                    .overlay(alignment: .trailing) {
                                        Rectangle().fill(Color.black.opacity(0.08)).frame(width: 1)
                                    }

                                    rowCell("", width: widths.status)
                                    rowCell(DisplayFormat.percentWithPrecision(row.cpuPercent, digits: 1), width: widths.cpu)
                                    rowCell(memoryText(for: row), width: widths.memory)
                                    rowCell(diskText(for: row), width: widths.disk)
                                    rowCell(networkText(for: row), width: widths.network)
                                }
                                .frame(height: UsersColumnLayout.rowHeight)
                                .background(userAppRowBackground(row, rowIndex: index))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPID = row.pid
                                }
                                .contextMenu {
                                    ProcessContextMenu(
                                        row: row,
                                        selectedPID: $selectedPID,
                                        memoryDisplayMode: $memoryDisplayMode,
                                        diskDisplayMode: $diskDisplayMode,
                                        networkDisplayMode: $networkDisplayMode,
                                        actions: rowActions
                                    )
                                }
                            }
                        }
                    }
                    .frame(width: widths.total, alignment: .leading)
                    .padding(.bottom, 16)
                }
            }
            .padding(.top, 18)
            .padding(.leading, UsersColumnLayout.insetLeading)
            .padding(.trailing, UsersColumnLayout.insetTrailing)
        }
        .onAppear {
            recomputeDisplayedRows()
        }
        .onChange(of: monitor.currentUserAppRows) { _, _ in
            recomputeDisplayedRows()
        }
        .onChange(of: searchText) { _, _ in
            recomputeDisplayedRows()
        }
    }

    private func recomputeDisplayedRows() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var rows = monitor.currentUserAppRows
        if !query.isEmpty {
            rows = rows.filter { row in
                row.name.lowercased().contains(query)
                    || String(row.pid).contains(query)
                    || row.path.lowercased().contains(query)
            }
        }
        displayedRows = rows.sorted { lhs, rhs in
            let result: Bool
            switch sortKey {
            case .user:
                result = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .status:
                // The status cell is always empty; order by name so the sort is
                // deterministic instead of arbitrary.
                result = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .cpu:
                result = lhs.cpuPercent < rhs.cpuPercent
            case .memory:
                result = lhs.memoryBytes < rhs.memoryBytes
            case .disk:
                result = lhs.diskBytesPerSecond < rhs.diskBytesPerSecond
            case .network:
                result = lhs.networkBytesPerSecond < rhs.networkBytesPerSecond
            }
            return ascending ? result : !result
        }
    }

    private func headerCell(_ title: String, sortKey: UsersSortKey, width: CGFloat) -> some View {
        Button {
            changeSort(to: sortKey)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                if self.sortKey == sortKey {
                    Image(systemName: ascending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(width: width, height: UsersColumnLayout.headerHeight, alignment: .leading)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
        }
    }

    private func metricHeaderCell(_ value: String, label: String, sortKey: UsersSortKey, width: CGFloat) -> some View {
        Button {
            changeSort(to: sortKey)
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 15))
                    if self.sortKey == sortKey {
                        Image(systemName: ascending ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: width, height: UsersColumnLayout.headerHeight)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
        }
    }

    private func rowCell(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.system(size: 13))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(width: width, height: UsersColumnLayout.rowHeight, alignment: .leading)
            .overlay(alignment: .trailing) {
                Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
            }
    }

    private func userAppRowBackground(_ row: ProcessRowData, rowIndex: Int) -> Color {
        if selectedPID == row.pid {
            return AppTheme.selectedRow(colorScheme)
        }
        return rowIndex.isMultiple(of: 2) ? AppTheme.rowEven(colorScheme) : AppTheme.rowOdd(colorScheme)
    }

    private func scaledWidths(for availableWidth: CGFloat) -> UsersScaledWidths {
        let usableWidth = max(
            760,
            availableWidth - UsersColumnLayout.insetLeading - UsersColumnLayout.insetTrailing - UsersColumnLayout.scrollBarReserve
        )
        let scale = usableWidth / UsersColumnLayout.totalWidth
        return UsersScaledWidths(scale: scale)
    }

    private func changeSort(to key: UsersSortKey) {
        if sortKey == key {
            ascending.toggle()
        } else {
            sortKey = key
            ascending = (key == .user || key == .status)
        }
        recomputeDisplayedRows()
    }

    private var rowActions: ProcessRowActions {
        ProcessRowActions(
            onEndTask: onEndTask,
            onRestartTask: onRestartTask,
            onRevealInFinder: onRevealInFinder,
            onSearchWeb: onSearchWeb,
            onShowProperties: onShowProperties,
            onCopyProcessDetails: onCopyProcessDetails,
            onOpenDetailsTab: onOpenDetailsTab
        )
    }

    private var totalNetworkBytesPerSecond: UInt64 {
        monitor.networks.reduce(UInt64(0)) { $0 + $1.sendBytesPerSecond + $1.receiveBytesPerSecond }
    }

    private func memoryText(for row: ProcessRowData) -> String {
        ProcessRowFormatter.memoryText(bytes: row.memoryBytes, mode: memoryDisplayMode, totalMemoryBytes: monitor.memory.totalBytes)
    }

    private func diskText(for row: ProcessRowData) -> String {
        ProcessRowFormatter.diskText(bytesPerSecond: row.diskBytesPerSecond, mode: diskDisplayMode)
    }

    private func networkText(for row: ProcessRowData) -> String {
        ProcessRowFormatter.networkText(
            bytesPerSecond: row.networkBytesPerSecond,
            valueText: row.networkText,
            mode: networkDisplayMode,
            totalNetworkBytesPerSecond: totalNetworkBytesPerSecond
        )
    }

    private func summaryMemoryText(_ totalMemory: UInt64) -> String {
        ProcessRowFormatter.memoryText(bytes: totalMemory, mode: memoryDisplayMode, totalMemoryBytes: monitor.memory.totalBytes)
    }

    private func summaryDiskText(_ totalDisk: UInt64) -> String {
        ProcessRowFormatter.diskText(bytesPerSecond: totalDisk, mode: diskDisplayMode)
    }

    private func summaryNetworkText(_ totalNetwork: UInt64) -> String {
        ProcessRowFormatter.networkText(
            bytesPerSecond: totalNetwork,
            valueText: totalNetwork == 0 ? "0 Mbps" : DisplayFormat.networkRate(totalNetwork),
            mode: networkDisplayMode,
            totalNetworkBytesPerSecond: totalNetworkBytesPerSecond
        )
    }
}

private struct UsersScaledWidths {
    let user: CGFloat
    let status: CGFloat
    let cpu: CGFloat
    let memory: CGFloat
    let disk: CGFloat
    let network: CGFloat

    init(scale: CGFloat) {
        user = UsersColumnLayout.user * scale
        status = UsersColumnLayout.status * scale
        cpu = UsersColumnLayout.cpu * scale
        memory = UsersColumnLayout.memory * scale
        disk = UsersColumnLayout.disk * scale
        network = UsersColumnLayout.network * scale
    }

    var total: CGFloat { user + status + cpu + memory + disk + network }
}
