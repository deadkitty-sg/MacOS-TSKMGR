import Foundation

/// Pure parsing of `launchctl print <domain>` output. The format is a private,
/// unstable text dump; this parser scans only the `services = { ... }` block
/// and skips anything it does not recognize rather than failing.
public enum LaunchdParsing {
    public struct ServiceEntry: Equatable, Sendable {
        public let label: String
        public let pid: Int32?
        public let stateToken: String

        public init(label: String, pid: Int32?, stateToken: String) {
            self.label = label
            self.pid = pid
            self.stateToken = stateToken
        }
    }

    /// Filters launchd labels down to user-meaningful services (drops
    /// per-app-instance and XPC helper noise).
    public static func shouldIncludeServiceLabel(_ label: String) -> Bool {
        guard !label.isEmpty else { return false }
        if label.hasPrefix("application.") { return false }
        if label.hasPrefix("com.apple.xpc.") { return false }
        return true
    }

    /// Parses the `services = { ... }` block. Each service line has the form
    /// `<pid|-> <exit-state> <label>`; a pid of `-` or `0` means not running.
    public static func parseServicesBlock(_ text: String) -> [ServiceEntry] {
        var result: [ServiceEntry] = []
        var inServicesBlock = false

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "services = {" {
                inServicesBlock = true
                continue
            }
            if inServicesBlock, trimmed == "}" {
                break
            }
            guard inServicesBlock else { continue }

            let parts = trimmed.split(whereSeparator: \.isWhitespace)
            guard parts.count >= 3 else { continue }

            let label = String(parts.last!)
            guard shouldIncludeServiceLabel(label) else { continue }

            let pidToken = String(parts[0])
            let stateToken = String(parts[1])
            let pid: Int32?
            if let value = Int32(pidToken), value > 0 {
                pid = value
            } else {
                pid = nil
            }

            result.append(ServiceEntry(label: label, pid: pid, stateToken: stateToken))
        }

        return result
    }
}
