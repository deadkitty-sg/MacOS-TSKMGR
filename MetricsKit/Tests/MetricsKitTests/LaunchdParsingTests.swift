import XCTest
@testable import MetricsKit

final class LaunchdParsingTests: XCTestCase {
    // Shape captured from real `launchctl print gui/501` output.
    private let fixture = """
    com.apple.xpc.launchd.user.domain.501 = {
        type = user
        handle = 501
        active count = 552
        services = {
              536    0    com.apple.homed
                -    0    com.apple.mdmclient.agent
              793    -9    com.example.crashy
                0    0    com.apple.storeagent
                -    0    application.com.apple.Safari.12345
                -    0    com.apple.xpc.helper.thing
            garbage line
              812    0    org.nixos.nix-daemon
        }
        disabled = {
            "com.apple.something" => disabled
        }
    }
    """

    func testParsesServicesBlockEntries() {
        let entries = LaunchdParsing.parseServicesBlock(fixture)
        XCTAssertEqual(entries.count, 5)

        XCTAssertEqual(entries[0], .init(label: "com.apple.homed", pid: 536, stateToken: "0"))
        XCTAssertEqual(entries[1], .init(label: "com.apple.mdmclient.agent", pid: nil, stateToken: "0"))
        XCTAssertEqual(entries[2], .init(label: "com.example.crashy", pid: 793, stateToken: "-9"))
        XCTAssertEqual(entries[3], .init(label: "com.apple.storeagent", pid: nil, stateToken: "0"))
        XCTAssertEqual(entries[4], .init(label: "org.nixos.nix-daemon", pid: 812, stateToken: "0"))
    }

    func testZeroPidMeansNotRunning() {
        let all = LaunchdParsing.parseServicesBlock("""
        services = {
              0    0    com.example.idle
        }
        """)
        XCTAssertEqual(all, [.init(label: "com.example.idle", pid: nil, stateToken: "0")])
    }

    func testFiltersApplicationAndXPCLabels() {
        let entries = LaunchdParsing.parseServicesBlock(fixture)
        XCTAssertFalse(entries.contains { $0.label.hasPrefix("application.") })
        XCTAssertFalse(entries.contains { $0.label.hasPrefix("com.apple.xpc.") })
    }

    func testStopsAtServicesBlockEnd() {
        // The disabled block after `}` must not be parsed as services.
        let entries = LaunchdParsing.parseServicesBlock(fixture)
        XCTAssertFalse(entries.contains { $0.label.contains("=>") })
    }

    func testMalformedInputReturnsEmpty() {
        XCTAssertEqual(LaunchdParsing.parseServicesBlock(""), [])
        XCTAssertEqual(LaunchdParsing.parseServicesBlock("no services here"), [])
    }

    func testShouldIncludeServiceLabel() {
        XCTAssertTrue(LaunchdParsing.shouldIncludeServiceLabel("com.apple.homed"))
        XCTAssertFalse(LaunchdParsing.shouldIncludeServiceLabel(""))
        XCTAssertFalse(LaunchdParsing.shouldIncludeServiceLabel("application.com.foo.1"))
        XCTAssertFalse(LaunchdParsing.shouldIncludeServiceLabel("com.apple.xpc.helper"))
    }
}
