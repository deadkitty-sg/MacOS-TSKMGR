import XCTest
@testable import MetricsKit

final class CPUMetricsTests: XCTestCase {

    // MARK: - Aggregate utilization

    func testAggregateNormalUtilization() {
        // From previous (total 900, idle 825) to current ticks summing to 975
        // with idle 850: active delta = 75 - 25 = 50 over total delta 75 => 66.67%.
        let result = CPUMetrics.aggregateUtilizationPercent(
            userSystemIdleNice: (100, 25, 850, 0),
            previousTotal: 900,
            previousIdle: 825
        )
        XCTAssertEqual(result.total, 975)
        XCTAssertEqual(result.idle, 850)
        XCTAssertEqual(result.percent, 200.0 / 3.0, accuracy: 0.01)
    }

    /// Regression for the 32-bit overflow crash: summing four near-max UInt32
    /// counters must not trap. The old `UInt64(a + b + c + d)` form crashed here.
    func testAggregateDoesNotOverflowOnHighUptime() {
        let big = UInt32.max
        let result = CPUMetrics.aggregateUtilizationPercent(
            userSystemIdleNice: (big, big, big, big),
            previousTotal: 0,
            previousIdle: 0
        )
        XCTAssertEqual(result.total, UInt64(big) * 4)
        XCTAssertGreaterThanOrEqual(result.percent, 0)
        XCTAssertLessThanOrEqual(result.percent, 100)
    }

    /// Regression for the counter-reset underflow crash: a total lower than the
    /// previous sample must degrade safely instead of trapping.
    func testAggregateHandlesCounterReset() {
        let result = CPUMetrics.aggregateUtilizationPercent(
            userSystemIdleNice: (1, 1, 1, 1),
            previousTotal: 1_000_000,
            previousIdle: 500_000
        )
        XCTAssertGreaterThanOrEqual(result.percent, 0)
        XCTAssertLessThanOrEqual(result.percent, 100)
    }

    // MARK: - Saturating delta

    func testSaturatingDeltaForward() {
        XCTAssertEqual(CPUMetrics.saturatingDelta(300, 100), 200)
    }

    func testSaturatingDeltaBackwardsIsZero() {
        // E-core park/unpark can make the counter go backwards.
        XCTAssertEqual(CPUMetrics.saturatingDelta(100, 300), 0)
    }

    // MARK: - Per-core utilization

    func testCoreUtilizationNormal() {
        let usage = CPUMetrics.coreUtilizationPercent(
            current: [100, 50, 850, 0],
            previous: [50, 25, 825, 0]
        )
        // user 50 + sys 25 + idle 25 = total 100, idle 25 => 75% active.
        XCTAssertEqual(usage, 75.0, accuracy: 0.01)
    }

    /// Regression for the per-core delta crash: any counter moving backwards
    /// (parked core) must not trap and must clamp to a sane range.
    func testCoreUtilizationHandlesParkedCore() {
        let usage = CPUMetrics.coreUtilizationPercent(
            current: [10, 10, 10, 10],
            previous: [20, 20, 20, 20]
        )
        XCTAssertEqual(usage, 0)
    }

    func testCoreUtilizationMalformedInputReturnsZero() {
        XCTAssertEqual(CPUMetrics.coreUtilizationPercent(current: [1, 2], previous: [1, 2, 3, 4]), 0)
    }
}
