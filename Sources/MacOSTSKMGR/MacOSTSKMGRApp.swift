import SwiftUI
import AppKit
import Combine

extension Notification.Name {
    /// Posted when the "Menu bar monitor" preference is toggled, so the
    /// AppDelegate can install/remove its NSStatusItem.
    static let menuBarMonitorPreferenceChanged = Notification.Name("MenuBarMonitorPreferenceChanged")
}

@main
struct MacOSTSKMGRApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // A single WindowGroup only. The menu bar monitor is an AppKit
        // NSStatusItem owned by the AppDelegate — NOT a SwiftUI MenuBarExtra:
        // on macOS 26 a second SwiftUI scene forces a full main-menu rebuild
        // every time the window content updates (i.e. every metrics tick),
        // which pins the main thread and freezes the app. The monitor is owned
        // by the AppDelegate and only passed down, so `body` never re-renders
        // on ticks.
        WindowGroup {
            RootWindowView(monitor: appDelegate.monitor)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// Compact CPU/memory monitor shown from the menu bar popover.
struct MenuBarMiniMonitorView: View {
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
        .frame(width: 264)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Single shared monitor for the window and the menu bar item. Owned here
    // (not as an App @StateObject) so the App scene never re-renders on ticks.
    let monitor = SystemMonitor()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cpuCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.windows.forEach(configure(window:))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuBarPreferenceChanged),
            name: .menuBarMonitorPreferenceChanged,
            object: nil
        )
        syncMenuBarItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running while the menu bar item is enabled; otherwise quit like a
        // regular single-window utility.
        statusItem == nil
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Restore the window after "Hide when minimized" sent the app out of view.
        NSApp.unhide(nil)
        if !flag {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    // MARK: - Menu bar status item

    @objc private func menuBarPreferenceChanged() {
        syncMenuBarItem()
    }

    private func syncMenuBarItem() {
        let enabled = UserDefaults.standard.bool(forKey: "pref.showMenuBarExtra")
        if enabled, statusItem == nil {
            installStatusItem()
        } else if !enabled, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
            cpuCancellable = nil
            popover = nil
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "gauge.with.needle", accessibilityDescription: "Task Manager")
            button.imagePosition = .imageLeading
            button.title = " " + DisplayFormat.percent(monitor.cpu.utilizationPercent)
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item

        // Live CPU% in the title. Updating an NSStatusItem title does NOT rebuild
        // the SwiftUI main menu, so this stays cheap even at the refresh cadence.
        cpuCancellable = monitor.cpuStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.statusItem?.button?.title = " " + DisplayFormat.percent(state.utilizationPercent)
            }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        let popover = self.popover ?? makePopover()
        self.popover = popover
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func makePopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarMiniMonitorView(monitor: monitor))
        return popover
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
