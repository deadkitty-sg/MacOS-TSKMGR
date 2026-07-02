import Foundation

/// Pure parsing of `nettop -x -P -L 1` CSV output (raw bytes, one aggregated
/// row per process). Column positions come from the header row, so a nettop
/// column reshuffle degrades to "no data" instead of misreads.
public enum NettopParsing {
    public struct ProcessTraffic: Equatable, Sendable {
        /// nettop's process token — usually `name.pid`, but a bare name for
        /// some system entries.
        public let token: String
        public let totalBytes: UInt64

        public init(token: String, totalBytes: UInt64) {
            self.token = token
            self.totalBytes = totalBytes
        }
    }

    public static func processTraffic(fromCSV text: String) -> [ProcessTraffic] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let header = lines.first else { return [] }
        let columns = header.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard
            let bytesInIndex = columns.firstIndex(of: "bytes_in"),
            let bytesOutIndex = columns.firstIndex(of: "bytes_out")
        else {
            return []
        }

        var result: [ProcessTraffic] = []
        for line in lines.dropFirst() {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard parts.count > max(bytesInIndex, bytesOutIndex), parts.count > 1 else { continue }

            let bytesIn = UInt64(parts[bytesInIndex]) ?? 0
            let bytesOut = UInt64(parts[bytesOutIndex]) ?? 0
            result.append(ProcessTraffic(token: parts[1], totalBytes: bytesIn + bytesOut))
        }
        return result
    }

    /// Splits a nettop process token into name and pid when it has the
    /// `name.pid` form; pid is nil for bare names.
    public static func splitToken(_ token: String) -> (name: String, pid: Int32?) {
        guard let dotIndex = token.lastIndex(of: "."),
              let pid = Int32(token[token.index(after: dotIndex)...])
        else {
            return (token, nil)
        }
        return (String(token[..<dotIndex]), pid)
    }
}
