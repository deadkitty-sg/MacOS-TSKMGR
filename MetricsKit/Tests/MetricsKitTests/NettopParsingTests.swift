import XCTest
@testable import MetricsKit

final class NettopParsingTests: XCTestCase {
    private let fixture = """
    time,,interface,state,bytes_in,bytes_out,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsizes,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,arch
    10:00:00.000000,Safari.4821,,,123456,7890,,,,,,,,,,,,,,
    10:00:00.000000,kernel_task.0,,,42,0,,,,,,,,,,,,,,
    10:00:00.000000,mDNSResponder,,,10,20,,,,,,,,,,,,,,
    10:00:00.000000,truncated
    """

    func testParsesTotalsPerProcess() {
        let traffic = NettopParsing.processTraffic(fromCSV: fixture)
        XCTAssertEqual(traffic.count, 3)
        XCTAssertEqual(traffic[0], .init(token: "Safari.4821", totalBytes: 131_346))
        XCTAssertEqual(traffic[1], .init(token: "kernel_task.0", totalBytes: 42))
        XCTAssertEqual(traffic[2], .init(token: "mDNSResponder", totalBytes: 30))
    }

    func testTruncatedRowsAreSkipped() {
        let traffic = NettopParsing.processTraffic(fromCSV: fixture)
        XCTAssertFalse(traffic.contains { $0.token == "truncated" })
    }

    func testMissingHeaderColumnsReturnsEmpty() {
        XCTAssertEqual(NettopParsing.processTraffic(fromCSV: "time,proc,foo\n1,2,3"), [])
        XCTAssertEqual(NettopParsing.processTraffic(fromCSV: ""), [])
    }

    func testSplitToken() {
        let safari = NettopParsing.splitToken("Safari.4821")
        XCTAssertEqual(safari.name, "Safari")
        XCTAssertEqual(safari.pid, 4821)

        // Names can themselves contain dots; only the last component is a pid.
        let dotted = NettopParsing.splitToken("com.apple.WebKit.Networking.998")
        XCTAssertEqual(dotted.name, "com.apple.WebKit.Networking")
        XCTAssertEqual(dotted.pid, 998)

        let bare = NettopParsing.splitToken("mDNSResponder")
        XCTAssertEqual(bare.name, "mDNSResponder")
        XCTAssertNil(bare.pid)
    }
}
