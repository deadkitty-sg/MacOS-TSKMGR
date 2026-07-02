import SwiftUI

/// Callbacks a page provides to the shared process context menu. All of them
/// are forwarded to handlers owned by RootWindowView.
struct ProcessRowActions {
    let onEndTask: (Int32) -> Void
    let onRestartTask: (ProcessRowData) -> Void
    let onRevealInFinder: (String) -> Void
    let onSearchWeb: (String) -> Void
    let onShowProperties: (ProcessRowData) -> Void
    let onCopyProcessDetails: (ProcessRowData) -> Void
    let onOpenDetailsTab: (Int32) -> Void
}

/// The right-click menu for a process row, shared by the Processes and Users
/// pages so the two menus can never drift apart.
struct ProcessContextMenu: View {
    @Environment(\.appLanguage) private var language
    let row: ProcessRowData
    @Binding var selectedPID: Int32?
    @Binding var memoryDisplayMode: ProcessResourceDisplayMode
    @Binding var diskDisplayMode: ProcessResourceDisplayMode
    @Binding var networkDisplayMode: ProcessResourceDisplayMode
    let actions: ProcessRowActions

    var body: some View {
        Group {
            if row.prefersRestartOverTerminate {
                Button(language.text("重新启动", "Restart")) {
                    selectedPID = row.pid
                    actions.onRestartTask(row)
                }
            } else if row.canTerminate {
                Button(language.text("结束任务", "End task")) {
                    selectedPID = row.pid
                    actions.onEndTask(row.pid)
                }
            } else if row.canRestartOnly {
                Button(language.text("重新启动", "Restart")) {
                    selectedPID = row.pid
                    actions.onRestartTask(row)
                }
            }

            Menu(language.text("资源值", "Resource values")) {
                Menu(language.text("内存", "Memory")) {
                    Button(language.text("百分比", "Percent")) {
                        memoryDisplayMode = .percent
                    }
                    Button(language.text("值", "Values")) {
                        memoryDisplayMode = .value
                    }
                }
                Menu(language.text("磁盘", "Disk")) {
                    Button(language.text("百分比", "Percent")) {
                        diskDisplayMode = .percent
                    }
                    Button(language.text("值", "Values")) {
                        diskDisplayMode = .value
                    }
                }
                Menu(language.text("网络", "Network")) {
                    Button(language.text("百分比", "Percent")) {
                        networkDisplayMode = .percent
                    }
                    Button(language.text("值", "Values")) {
                        networkDisplayMode = .value
                    }
                }
            }

            Button(language.text("转到详细信息", "Go to details")) {
                selectedPID = row.pid
                actions.onOpenDetailsTab(row.pid)
            }

            Button(language.text("打开文件所在的位置", "Open file location")) {
                actions.onRevealInFinder(row.path)
            }
            .disabled(row.path.isEmpty)

            Button(language.text("在线搜索", "Search online")) {
                actions.onSearchWeb(row.name)
            }

            Button(language.text("属性", "Properties")) {
                actions.onShowProperties(row)
            }

            Divider()

            Button(language.text("复制", "Copy")) {
                actions.onCopyProcessDetails(row)
            }
        }
    }
}
