import XCTest
@testable import MetricsKit

final class BootMathTests: XCTestCase {
    func testNormalBootDuration() {
        XCTAssertEqual(BootMath.bootToLoginDurationSeconds(bootTime: 1_000, loginwindowStart: 1_018.5), 18.5)
    }

    func testClockSkewReturnsNil() {
        // loginwindow apparently started before boot — clock changed mid-boot.
        XCTAssertNil(BootMath.bootToLoginDurationSeconds(bootTime: 2_000, loginwindowStart: 1_990))
    }

    func testAbsurdDurationReturnsNil() {
        // loginwindow restarted hours after boot is not a boot duration.
        XCTAssertNil(BootMath.bootToLoginDurationSeconds(bootTime: 1_000, loginwindowStart: 1_000 + 7_200))
    }

    func testZeroDurationReturnsNil() {
        XCTAssertNil(BootMath.bootToLoginDurationSeconds(bootTime: 1_000, loginwindowStart: 1_000))
    }
}
