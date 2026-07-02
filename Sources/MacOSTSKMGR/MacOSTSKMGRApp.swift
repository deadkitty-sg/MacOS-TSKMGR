import SwiftUI

@main
struct MacOSTSKMGRApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Owned here (not in RootWindowView) so the main window and the menu bar
    // extra observe the same monitor instance.
    @StateObject private var monitor = SystemMonitor()
    @AppStorage("pref.showMenuBarExtra") private var showMenuBarExtra = false

    var body: some Scene {
        WindowGroup {
            RootWindowView(monitor: monitor)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra(isInserted: $showMenuBarExtra) {
            MenuBarMiniMonitorView(monitor: monitor)
        } label: {
            Image(systemName: "gauge.with.needle")
            Text(DisplayFormat.percent(monitor.cpu.utilizationPercent))
        }
        .menuBarExtraStyle(.window)
    }
}

/// Compact CPU/memory monitor shown from the menu bar extra.
private struct MenuBarMiniMonitorView: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CPU  \(DisplayFormat.percent(monitor.cpu.utilizationPercent))")
                    .font(.system(size: 12, weight: .semibold))
                GridChart(values: monitor.cpu.history, color: Color(red: 0.11, green: 0.55, blue: 0.95), filled: true)
                    .frame(width: 240, height: 46)
                    .overlay(Rectangle().stroke(Color(red: 0.11, green: 0.55, blue: 0.95), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(monitor.language.text("内存", "Memory") + "  \(DisplayFormat.memory(monitor.memory.usedBytes)) / \(DisplayFormat.memory(monitor.memory.totalBytes))")
                    .font(.system(size: 12, weight: .semibold))
                GridChart(values: monitor.memory.historyPercent, color: Color(red: 0.72, green: 0.19, blue: 0.92), filled: true)
                    .frame(width: 240, height: 46)
                    .overlay(Rectangle().stroke(Color(red: 0.72, green: 0.19, blue: 0.92), lineWidth: 1))
            }

            Divider()

            Button(monitor.language.text("打开任务管理器", "Open Task Manager")) {
                NSApp.unhide(nil)
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first { !($0 is NSPanel) && $0.styleMask.contains(.titled) }?.makeKeyAndOrderFront(nil)
            }
        }
        .padding(12)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.windows.forEach(configure(window:))
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running while the menu bar extra is enabled; otherwise quit like
        // a regular single-window utility.
        !UserDefaults.standard.bool(forKey: "pref.showMenuBarExtra")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Restore the window after "Hide when minimized" sent the app out of view.
        NSApp.unhide(nil)
        if !flag {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    private func configure(window: NSWindow) {
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.toolbarStyle = .unifiedCompact
    }
}
