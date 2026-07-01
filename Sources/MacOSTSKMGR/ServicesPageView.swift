import SwiftUI

struct ServicesPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var language
    @ObservedObject var monitor: SystemMonitor
    @Binding var selectedPID: Int32?
    let onStartService: (ServiceRowData) -> Void
    let onStopService: (ServiceRowData) -> Void
    let onRestartService: (ServiceRowData) -> Void
    let onSearchWeb: (String) -> Void
    let onOpenDetailsTab: (Int32) -> Void

    var body: some View {
        MetricTable(
            rows: monitor.serviceRows,
            columns: columns,
            initialSortColumnID: "name",
            initialAscending: true,
            minUsableWidth: 900,
            isSelected: { row in
                if let pid = row.pid { return selectedPID == pid }
                return false
            },
            onSelect: { selectedPID = $0.pid },
            rowMenu: { row in serviceContextMenu(for: row) }
        )
        .onAppear {
            monitor.refreshServicesNow()
        }
    }

    private var columns: [MetricColumn<ServiceRowData>] {
        [
            MetricColumn(
                id: "name",
                title: language.text("名称", "Name"),
                baseWidth: 200,
                comparator: { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                cell: { AnyView(MetricTableNameCell(icon: $0.icon, name: $0.name)) }
            ),
            .text(id: "pid", title: "PID", baseWidth: 80, defaultAscending: false,
                  comparator: { ($0.pid ?? -1) < ($1.pid ?? -1) },
                  value: { $0.pid.map(String.init) ?? "" }),
            .text(id: "description", title: language.text("描述", "Description"), baseWidth: 420,
                  comparator: { $0.serviceDescription.localizedStandardCompare($1.serviceDescription) == .orderedAscending },
                  value: { $0.serviceDescription }),
            .text(id: "status", title: language.text("状态", "Status"), baseWidth: 110, defaultAscending: false,
                  comparator: { $0.status.sortRank < $1.status.sortRank },
                  value: { $0.status.displayTitle(in: language) }),
            .text(id: "group", title: language.text("组", "Group"), baseWidth: 140,
                  comparator: { $0.group.localizedStandardCompare($1.group) == .orderedAscending },
                  value: { $0.group }),
        ]
    }

    private func serviceContextMenu(for row: ServiceRowData) -> some View {
        Group {
            Button(language.text("开始", "Start")) {
                onStartService(row)
            }
            .disabled(!row.status.canStart)

            Button(language.text("停止", "Stop")) {
                onStopService(row)
            }
            .disabled(!row.status.canStop)

            Button(language.text("重新启动", "Restart")) {
                onRestartService(row)
            }
            .disabled(!row.status.canRestart)

            Divider()

            Button(language.text("打开服务", "Open service")) {
                if let pid = row.pid {
                    onOpenDetailsTab(pid)
                }
            }
            .disabled(row.pid == nil)

            Button(language.text("在线搜索", "Search online")) {
                onSearchWeb(row.name)
            }

            Button(language.text("转到详细信息", "Go to details")) {
                if let pid = row.pid {
                    onOpenDetailsTab(pid)
                }
            }
            .disabled(row.pid == nil)
        }
    }
}
