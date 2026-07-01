import Foundation

/// Pure, dependency-free CPU/sampling math — the canonical reference for the
/// delta arithmetic used by `SystemMonitor.refreshCPU`.
///
/// Kernel tick counters (`host_cpu_load_info` / `host_processor_info`) are
/// cumulative `natural_t` (UInt32) values. Two things bite naive code:
///   1. Summing the four aggregate counters in 32-bit overflows after a few
///      weeks of uptime on many-core machines (Swift traps on overflow).
///   2. A counter can move *backwards* (E-core park/unpark, counter reset),
///      so `max(a - b, 0)` on unsigned values underflow-traps before `max` runs.
/// Both are handled here by widening to 64-bit and using saturating deltas.
///
/// These functions are covered by `MetricsKitTests`; the shipping engine should
/// eventually call into this module directly instead of duplicating the math.
public enum CPUMetrics {

    /// Saturating delta between two cumulative unsigned counters. Never traps:
    /// if the current sample is lower than the previous one, returns 0.
    public static func saturatingDelta(_ current: UInt32, _ previous: UInt32) -> UInt64 {
        current >= previous ? UInt64(current - previous) : 0
    }

    /// Aggregate host CPU utilization from cumulative user/system/idle/nice ticks.
    /// Returns the utilization percent (clamped 0...100) plus the widened total
    /// and idle counters to carry forward as the next "previous" sample.
    public static func aggregateUtilizationPercent(
        userSystemIdleNice ticks: (UInt32, UInt32, UInt32, UInt32),
        previousTotal: UInt64,
        previousIdle: UInt64
    ) -> (percent: Double, total: UInt64, idle: UInt64) {
        // Widen BEFORE summing so the addition cannot overflow 32 bits.
        let total = UInt64(ticks.0) + UInt64(ticks.1) + UInt64(ticks.2) + UInt64(ticks.3)
        let idle = UInt64(ticks.2)
        let deltaTotal = total >= previousTotal ? max(total - previousTotal, 1) : 1
        let deltaIdle = idle >= previousIdle ? idle - previousIdle : 0
        let activeDelta = deltaTotal >= deltaIdle ? deltaTotal - deltaIdle : 0
        let percent = Double(activeDelta) / Double(deltaTotal) * 100
        return (min(max(percent, 0), 100), total, idle)
    }

    /// Per-core utilization from `[user, system, idle, nice]` tick arrays.
    /// Returns 0 on malformed input or when no time has elapsed.
    public static func coreUtilizationPercent(current: [UInt32], previous: [UInt32]) -> Double {
        guard current.count == 4, previous.count == 4 else { return 0 }
        let totalDelta = zip(current, previous).reduce(UInt64(0)) { $0 + saturatingDelta($1.0, $1.1) }
        let idleDelta = saturatingDelta(current[2], previous[2])
        guard totalDelta != 0 else { return 0 }
        let activeDelta = totalDelta >= idleDelta ? totalDelta - idleDelta : 0
        return min(max(Double(activeDelta) / Double(totalDelta) * 100, 0), 100)
    }
}
