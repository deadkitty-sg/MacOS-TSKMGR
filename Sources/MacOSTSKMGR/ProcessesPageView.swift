import SwiftUI

private enum ProcessColumnLayout {
    static let pageInsetLeading: CGFloat = 8
    static let pageInsetTrailing: CGFloat = 14
    static let scrollBarReserve: CGFloat = 18
    static let name: CGFloat = 380
    static let status: CGFloat = 120
    static let cpu: CGFloat = 88
    static let memory: CGFloat = 108
    static let disk: CGFloat = 96
    static let network: CGFloat = 88
    static let power: CGFloat = 126
    static let trend: CGFloat = 138
    static let totalWidth: CGFloat = name + status + cpu + memory + disk + network + power + trend
    static let rowHeight: CGFloat = 36
    static let headerHeight: CGFloat = 50
}

private enum ProcessColumn {
    case name
    case status
    case cpu
    case memory
    case disk
    case network
    case power
    case trend
}

struct ProcessesPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var language
    @ObservedObject var monitor: SystemMonitor
    @Binding var collapsedSections: Set<String>
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
    @AppStorage("pref.processes.sortKey") private var sortKey: ProcessSortKey = .cpu
    @AppStorage("pref.processes.ascending") private var ascending = false
    @State private var hoveredSortKey: ProcessSortKey?
    @State private var searchText = ""
    // Filter + sort output is cached and recomputed only when its inputs change,
    // not on every body evaluation (the monitor publishes ~every tick).
    @State private var displayedSections: [ProcessSectionData] = []

    var body: some View {
        GeometryReader { proxy in
            let widths = scaledWidths(for: proxy.size.width)

            VStack(alignment: .leading, spacing: 0) {
                ProcessSearchField(text: $searchText, colorScheme: colorScheme, language: language)
                    .frame(width: min(widths.total, 340), alignment: .leading)
                    .padding(.bottom, 8)

                processHeaderRow(widths: widths)
                    .frame(width: widths.total, alignment: .leading)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(displayedSections) { section in
                            sectionHeader(section.title, width: widths.total)

                            if !collapsedSections.contains(section.title) {
                                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                                    processDataRow(row, rowIndex: index, widths: widths)
                                }
                            }
                        }
                    }
                    .frame(width: widths.total, alignment: .leading)
                    .padding(.bottom, 16)
                }
            }
            .padding(.top, 8)
            .padding(.leading, ProcessColumnLayout.pageInsetLeading)
            .padding(.trailing, ProcessColumnLayout.pageInsetTrailing)
        }
        .onAppear {
            recomputeDisplayedSections()
        }
        .onChange(of: monitor.processSections) { _, _ in
            recomputeDisplayedSections()
        }
        .onChange(of: searchText) { _, _ in
            recomputeDisplayedSections()
        }
    }

    private func recomputeDisplayedSections() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        displayedSections = monitor.processSections.map { section in
            var rows = section.rows
            if !query.isEmpty {
                rows = rows.filter { row in
                    row.name.lowercased().contains(query)
                        || String(row.pid).contains(query)
                        || row.path.lowercased().contains(query)
                }
            }
            return ProcessSectionData(title: section.title, rows: rows.sorted(by: compareRows))
        }
    }

    private func processHeaderRow(widths: ProcessScaledWidths) -> some View {
        HStack(spacing: 0) {
            tableCellHeader(language.text("名称", "Name"), sortKey: .name, width: widths.width(for: .name), background: AppTheme.tableHeader(colorScheme), align: .leading)
            tableCellHeader(language.text("状态", "Status"), sortKey: .status, width: widths.width(for: .status), background: AppTheme.tableHeader(colorScheme), align: .leading)
            tableMetricHeader(DisplayFormat.percent(monitor.cpu.utilizationPercent), label: "CPU", sortKey: .cpu, width: widths.width(for: .cpu))
            tableMetricHeader(DisplayFormat.percent(percentMemory), label: language.text("内存", "Memory"), sortKey: .memory, width: widths.width(for: .memory))
            tableMetricHeader(diskBusyLabel, label: language.text("磁盘", "Disk"), sortKey: .disk, width: widths.width(for: .disk))
            tableMetricHeader(networkBusyLabel, label: language.text("网络", "Network"), sortKey: .network, width: widths.width(for: .network))
            tableCellHeader(language.text("电源使用情况", "Power usage"), sortKey: .power, width: widths.width(for: .power), background: AppTheme.tableHeader(colorScheme), align: .leading)
            tableCellHeader(language.text("电源使用情况趋势", "Power trend"), sortKey: .trend, width: widths.width(for: .trend), background: AppTheme.tableHeader(colorScheme), align: .leading)
        }
        .frame(height: ProcessColumnLayout.headerHeight)
        .background(AppTheme.tableHeaderStrong(colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.strongSeparator(colorScheme)).frame(height: 1)
        }
    }

    private var percentMemory: Double {
        guard monitor.memory.totalBytes > 0 else { return 0 }
        return Double(monitor.memory.usedBytes) / Double(monitor.memory.totalBytes) * 100
    }

    private var diskBusyLabel: String {
        DisplayFormat.percent(monitor.disks.map(\.activityPercent).max() ?? 0)
    }

    private var networkBusyLabel: String {
        let totalBytesPerSecond = monitor.networks.reduce(UInt64(0)) { $0 + $1.sendBytesPerSecond + $1.receiveBytesPerSecond }
        let totalLinkBitsPerSecond = monitor.networks.reduce(UInt64(0)) { $0 + $1.linkSpeedBitsPerSecond }
        guard totalLinkBitsPerSecond > 0 else {
            // Without a known link speed there is no honest percentage; show the
            // real throughput instead of an invented value.
            return DisplayFormat.throughput(totalBytesPerSecond)
        }
        let percent = min(Double(totalBytesPerSecond) * 8 / Double(totalLinkBitsPerSecond) * 100, 100)
        return DisplayFormat.percent(percent)
    }

    private func sectionHeader(_ title: String, width: CGFloat) -> some View {
        Button {
            toggleSection(title)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: collapsedSections.contains(title) ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                Text(language.translateProcessSectionTitle(title))
                    .font(.system(size: 15))
            }
            .foregroundStyle(Color(red: 0.16, green: 0.34, blue: 0.77))
            .padding(.top, 12)
            .padding(.bottom, 6)
            .padding(.leading, 10)
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func tableCellHeader(_ title: String, sortKey: ProcessSortKey, width: CGFloat, background: Color, align: Alignment) -> some View {
        Button {
            changeSort(to: sortKey)
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                if self.sortKey == sortKey {
                    Image(systemName: ascending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                } else if hoveredSortKey == sortKey {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(width: width, height: ProcessColumnLayout.headerHeight, alignment: align)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(background)
        .onHover { hovering in
            hoveredSortKey = hovering ? sortKey : nil
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
        }
    }

    private func tableMetricHeader(_ value: String, label: String, sortKey: ProcessSortKey, width: CGFloat) -> some View {
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
                    } else if hoveredSortKey == sortKey {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                }
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: width, height: ProcessColumnLayout.headerHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(AppTheme.tableMetricHeader(colorScheme))
        .onHover { hovering in
            hoveredSortKey = hovering ? sortKey : nil
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
        }
    }

    private func processDataRow(_ row: ProcessRowData, rowIndex: Int, widths: ProcessScaledWidths) -> some View {
        HStack(spacing: 0) {
            rowNameCell(row, width: widths.width(for: .name))
            rowTextCell("", width: widths.width(for: .status))
            rowMetricCell(DisplayFormat.percentWithPrecision(row.cpuPercent, digits: 1), width: widths.width(for: .cpu))
            rowMetricCell(memoryText(for: row), width: widths.width(for: .memory))
            rowMetricCell(diskText(for: row), width: widths.width(for: .disk))
            rowMetricCell(networkText(for: row), width: widths.width(for: .network))
            rowMetricCell(localizedImpactText(row.powerImpact), width: widths.width(for: .power))
            rowMetricCell(localizedImpactText(row.trend), width: widths.width(for: .trend))
        }
        .frame(height: ProcessColumnLayout.rowHeight)
        .background(processRowBackground(row, rowIndex: rowIndex))
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

    private func processRowBackground(_ row: ProcessRowData, rowIndex: Int) -> Color {
        if selectedPID == row.pid {
            return AppTheme.selectedRow(colorScheme)
        }
        return rowIndex.isMultiple(of: 2) ? AppTheme.rowEven(colorScheme) : AppTheme.rowOdd(colorScheme)
    }

    private func rowNameCell(_ row: ProcessRowData, width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: 12, height: 12)
            ProcessIconView(icon: row.icon)
            Text(row.name)
                .font(.system(size: 13))
                .lineLimit(1)
            Spacer()
        }
        .padding(.leading, 10)
        .frame(width: width, height: ProcessColumnLayout.rowHeight, alignment: .leading)
        .overlay(alignment: .trailing) {
            Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
        }
    }

    private func rowTextCell(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.system(size: 13))
            .lineLimit(1)
            .padding(.leading, 8)
            .frame(width: width, height: ProcessColumnLayout.rowHeight, alignment: .leading)
            .overlay(alignment: .trailing) {
                Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
            }
    }

    private func localizedImpactText(_ value: String) -> String {
        language.localizeImpact(value)
    }

    private func rowMetricCell(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.system(size: 13))
            .lineLimit(1)
            .padding(.leading, 8)
            .frame(width: width, height: ProcessColumnLayout.rowHeight, alignment: .leading)
            .overlay(alignment: .trailing) {
                Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
            }
    }

    private func sortKeyForColumn(_ column: ProcessColumn) -> ProcessSortKey {
        switch column {
        case .name: .name
        case .status: .status
        case .cpu: .cpu
        case .memory: .memory
        case .disk: .disk
        case .network: .network
        case .power: .power
        case .trend: .trend
        }
    }

    private func changeSort(to key: ProcessSortKey) {
        if sortKey == key {
            ascending.toggle()
        } else {
            sortKey = key
            ascending = (key == .name || key == .status || key == .power || key == .trend)
        }
        recomputeDisplayedSections()
    }

    private func toggleSection(_ title: String) {
        if collapsedSections.contains(title) {
            collapsedSections.remove(title)
        } else {
            collapsedSections.insert(title)
        }
    }

    private func scaledWidths(for availableWidth: CGFloat) -> ProcessScaledWidths {
        let usableWidth = max(
            720,
            availableWidth - ProcessColumnLayout.pageInsetLeading - ProcessColumnLayout.pageInsetTrailing - ProcessColumnLayout.scrollBarReserve
        )
        let scale = usableWidth / ProcessColumnLayout.totalWidth
        return ProcessScaledWidths(scale: scale)
    }

    private func compareRows(_ lhs: ProcessRowData, _ rhs: ProcessRowData) -> Bool {
        let result: Bool
        switch sortKey {
        case .name:
            result = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        case .status:
            // The status cell is currently always empty (like Windows, which only
            // shows badges such as "Suspended"), so order by name to keep the sort
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
        case .power:
            result = lhs.powerUsageWatts < rhs.powerUsageWatts
        case .trend:
            result = lhs.powerTrendWatts < rhs.powerTrendWatts
        }
        return ascending ? result : !result
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
}

struct ProcessScaledWidths {
    let name: CGFloat
    let status: CGFloat
    let cpu: CGFloat
    let memory: CGFloat
    let disk: CGFloat
    let network: CGFloat
    let power: CGFloat
    let trend: CGFloat

    init(scale: CGFloat) {
        name = ProcessColumnLayout.name * scale
        status = ProcessColumnLayout.status * scale
        cpu = ProcessColumnLayout.cpu * scale
        memory = ProcessColumnLayout.memory * scale
        disk = ProcessColumnLayout.disk * scale
        network = ProcessColumnLayout.network * scale
        power = ProcessColumnLayout.power * scale
        trend = ProcessColumnLayout.trend * scale
    }

    fileprivate func width(for column: ProcessColumn) -> CGFloat {
        switch column {
        case .name: name
        case .status: status
        case .cpu: cpu
        case .memory: memory
        case .disk: disk
        case .network: network
        case .power: power
        case .trend: trend
        }
    }

    var total: CGFloat { name + status + cpu + memory + disk + network + power + trend }
}

struct ProcessIconView: View {
    let icon: NSImage?

    var body: some View {
        if let icon {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.gray.opacity(0.26))
                .frame(width: 16, height: 16)
                .overlay(Image(systemName: "app").font(.system(size: 8)).foregroundStyle(.secondary))
        }
    }
}
