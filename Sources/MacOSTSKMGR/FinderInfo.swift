import AppKit

enum FinderInfo {
    /// Opens Finder's Get Info window for a file. The path travels as osascript
    /// argv — never interpolated into the script source — so quotes or other
    /// shell/AppleScript metacharacters in a file name are harmless.
    static func showProperties(path: String) {
        guard path.hasPrefix("/") else { return }
        let script = """
        on run argv
            tell application "Finder"
                activate
                open information window of (POSIX file (item 1 of argv) as alias)
            end tell
        end run
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, path]
        try? process.run()
    }

    static func searchWeb(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}
