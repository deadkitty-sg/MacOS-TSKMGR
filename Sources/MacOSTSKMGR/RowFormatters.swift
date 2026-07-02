import Foundation

extension ProcessRowData {
    var canTerminate: Bool {
        pid > 1 && pid != Int32(ProcessInfo.processInfo.processIdentifier)
    }

    var canRestartOnly: Bool {
        !canTerminate && isApp && !path.isEmpty
    }

    /// Finder is never terminated, only restarted (matching Windows, where
    /// Explorer gets "Restart" instead of "End task").
    var prefersRestartOverTerminate: Bool {
        let lowerName = name.lowercased()
        let lowerPath = path.lowercased()
        return lowerName == "finder" || lowerName == "访达" || lowerPath.contains("/system/library/coreservices/finder.app")
    }
}

/// Row-value formatting shared by the Processes and Users tables so their
/// percent/value display modes can never drift apart.
enum ProcessRowFormatter {
    /// Denominator for the disk "percent" display mode: 4 MB/s counts as 100%.
    static let diskPercentDenominatorBytesPerSecond: Double = 4_000_000

    static func memoryText(bytes: UInt64, mode: ProcessResourceDisplayMode, totalMemoryBytes: UInt64) -> String {
        switch mode {
        case .value:
            return DisplayFormat.memory(bytes)
        case .percent:
            guard totalMemoryBytes > 0 else { return "0%" }
            let percent = Double(bytes) / Double(totalMemoryBytes) * 100
            return DisplayFormat.percentWithPrecision(percent, digits: 1)
        }
    }

    static func diskText(bytesPerSecond: UInt64, mode: ProcessResourceDisplayMode) -> String {
        switch mode {
        case .value:
            return DisplayFormat.throughput(bytesPerSecond)
        case .percent:
            let percent = min(Double(bytesPerSecond) / diskPercentDenominatorBytesPerSecond * 100, 100)
            return DisplayFormat.percentWithPrecision(percent, digits: 0)
        }
    }

    static func networkText(bytesPerSecond: UInt64, valueText: String, mode: ProcessResourceDisplayMode, totalNetworkBytesPerSecond: UInt64) -> String {
        switch mode {
        case .value:
            return valueText
        case .percent:
            guard totalNetworkBytesPerSecond > 0 else { return "0%" }
            let percent = min(Double(bytesPerSecond) / Double(totalNetworkBytesPerSecond) * 100, 100)
            return DisplayFormat.percentWithPrecision(percent, digits: 0)
        }
    }
}
