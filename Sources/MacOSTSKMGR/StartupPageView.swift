import SwiftUI

struct StartupPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var language
    @ObservedObject var monitor: SystemMonitor
    @State private var selectedRowID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                if let bootDuration = monitor.currentBootDurationSeconds() {
                    Text(language.text("本次系统启动时间: ", "Startup time: ") + "\(String(format: "%.1f", bootDuration)) " + language.text("秒", "s"))
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.primaryText(colorScheme))
                }
            }
            .padding(.top, 18)
            .padding(.leading, 8)
            .padding(.trailing, 14)
            .padding(.bottom, 10)

            MetricTable(
                rows: monitor.startupRows,
                columns: columns,
                initialSortColumnID: "name",
                initialAscending: true,
                minUsableWidth: 720,
                topPadding: 0,
                isSelected: { $0.id == selectedRowID },
                onSelect: { selectedRowID = $0.id },
                rowMenu: { row in
                    Button(toggleMenuTitle(for: row)) {
                        toggleStartupItem(row)
                    }
                    .disabled(!canToggleStartupItem(row))

                    Button(language.text("打开文件所在的位置", "Open file location")) {
                        revealStartupItem(row)
                    }
                    .disabled(!canRevealStartupItem(row))

                    Button(language.text("在线搜索", "Search online")) {
                        searchStartupItem(row)
                    }

                    Button(language.text("属性", "Properties")) {
                        showStartupItemProperties(row)
                    }
                    .disabled(!canShowStartupItemProperties(row))
                }
            )
        }
    }

    private var columns: [MetricColumn<StartupItemRowData>] {
        [
            MetricColumn(
                id: "name",
                title: language.text("名称", "Name"),
                baseWidth: 280,
                comparator: { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                cell: { AnyView(MetricTableNameCell(icon: $0.icon, name: $0.name)) }
            ),
            .text(id: "publisher", title: language.text("发布者", "Publisher"), baseWidth: 210,
                  comparator: { $0.publisher.localizedStandardCompare($1.publisher) == .orderedAscending },
                  value: { language.localizeDirectoryLabel($0.publisher) }),
            .text(id: "status", title: language.text("状态", "Status"), baseWidth: 120,
                  comparator: { $0.status.displayTitle(in: language).localizedStandardCompare($1.status.displayTitle(in: language)) == .orderedAscending },
                  value: { $0.status.displayTitle(in: language) }),
            .text(id: "impact", title: language.text("启动影响", "Impact"), baseWidth: 110,
                  comparator: { $0.startupImpact.localizedStandardCompare($1.startupImpact) == .orderedAscending },
                  value: { language.localizeStartupImpact($0.startupImpact) }),
        ]
    }

    private func isDisabled(_ row: StartupItemRowData) -> Bool {
        row.status == .disabled
    }

    private func toggleMenuTitle(for row: StartupItemRowData) -> String {
        isDisabled(row) ? language.text("启用", "Enable") : language.text("禁用", "Disable")
    }

    private func canToggleStartupItem(_ row: StartupItemRowData) -> Bool {
        guard row.id.hasPrefix("/") else { return false }
        if row.id.hasPrefix("/System/Library/") {
            return false
        }
        return startupLabel(forPlistAt: row.id) != nil
    }

    private func canRevealStartupItem(_ row: StartupItemRowData) -> Bool {
        row.id.hasPrefix("/")
    }

    private func canShowStartupItemProperties(_ row: StartupItemRowData) -> Bool {
        row.id.hasPrefix("/")
    }

    private func toggleStartupItem(_ row: StartupItemRowData) {
        guard canToggleStartupItem(row) else { return }
        let path = row.id
        let label = startupLabel(forPlistAt: path) ?? URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let group = startupGroup(for: path)
        let enable = isDisabled(row)

        if group == "system" {
            toggleSystemStartupItem(path: path, label: label, enable: enable)
        } else {
            toggleUserStartupItem(path: path, label: label, enable: enable)
        }
        monitor.refreshNow()
    }

    private func startupLabel(forPlistAt path: String) -> String? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return nil }
        return plist["Label"] as? String
    }

    private func startupGroup(for path: String) -> String {
        if path.contains("LaunchDaemons") {
            return "system"
        }
        return "gui/\(getuid())"
    }

    private func toggleUserStartupItem(path: String, label: String, enable: Bool) {
        let domain = "gui/\(getuid())/\(label)"
        let command = enable ? ["enable", domain] : ["disable", domain]
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = command
        try? process.run()
        process.waitUntilExit()
        setDisabledFlagInPlist(path: path, disabled: !enable)
    }

    private func toggleSystemStartupItem(path: String, label: String, enable: Bool) {
        // The label lands on the shell command line, so restrict it to reverse-DNS
        // characters; the path is passed through AppleScript's `quoted form of`.
        // Never interpolate either into the script source (shell-injection risk).
        let allowedLabelCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")
        guard !label.isEmpty, label.unicodeScalars.allSatisfy({ allowedLabelCharacters.contains($0) }) else { return }
        let script = """
        on run argv
            set verb to item 1 of argv
            set theLabel to item 2 of argv
            set plistFlag to item 3 of argv
            set thePath to item 4 of argv
            do shell script "/bin/launchctl " & verb & " system/" & theLabel & "; /usr/bin/plutil -replace Disabled -bool " & plistFlag & " " & quoted form of thePath with administrator privileges
        end run
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, enable ? "enable" : "disable", label, enable ? "false" : "true", path]
        try? process.run()
        process.waitUntilExit()
    }

    private func setDisabledFlagInPlist(path: String, disabled: Bool) {
        guard let data = FileManager.default.contents(atPath: path),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return }
        plist["Disabled"] = disabled
        if let updated = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            try? updated.write(to: URL(fileURLWithPath: path))
        }
    }

    private func revealStartupItem(_ row: StartupItemRowData) {
        guard canRevealStartupItem(row) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: row.id)])
    }

    private func searchStartupItem(_ row: StartupItemRowData) {
        FinderInfo.searchWeb(query: row.name)
    }

    private func showStartupItemProperties(_ row: StartupItemRowData) {
        guard canShowStartupItemProperties(row) else { return }
        FinderInfo.showProperties(path: row.id)
    }
}
