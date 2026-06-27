import Foundation
import IOKit

@_silgen_name("mach_task_self")
func mach_task_self_() -> UInt32
@_silgen_name("IOServiceOpen")
func IOServiceOpen_(_ service: io_service_t, _ owningTask: UInt32, _ type: UInt32, _ connect: UnsafeMutablePointer<UInt32>) -> kern_return_t
@_silgen_name("IOServiceClose")
func IOServiceClose_(_ connect: UInt32) -> kern_return_t
@_silgen_name("IOConnectCallStructMethod")
func IOConnectCallStructMethod_(_ conn: UInt32, _ selector: UInt32, _ input: UnsafeRawPointer, _ inputSize: Int, _ output: UnsafeMutableRawPointer, _ outputSize: UnsafeMutablePointer<Int>) -> kern_return_t

struct KeyDataVer {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

struct PLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPowerLimit: UInt32 = 0
    var gpuPowerLimit: UInt32 = 0
    var memPowerLimit: UInt32 = 0
}

struct KeyInfo {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
    var p0: UInt8 = 0
    var p1: UInt8 = 0
    var p2: UInt8 = 0
}

struct KeyData {
    var key: UInt32 = 0
    var vers = KeyDataVer()
    var versPadding: UInt16 = 0
    var pLimitData = PLimitData()
    var keyInfo = KeyInfo()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data8Padding: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    ) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

final class SMCReader {
    private let connection: UInt32

    init?() {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleSMC"), &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var conn: UInt32 = 0
        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            defer { IOObjectRelease(service) }

            var name = [CChar](repeating: 0, count: 128)
            guard IORegistryEntryGetName(service, &name) == KERN_SUCCESS else { continue }
            let serviceName = String(decoding: name.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
            if serviceName == "AppleSMCKeysEndpoint" {
                if IOServiceOpen_(service, mach_task_self_(), 0, &conn) == KERN_SUCCESS {
                    break
                }
            }
        }

        guard conn != 0 else { return nil }
        self.connection = conn
    }

    deinit {
        _ = IOServiceClose_(connection)
    }

    private func parseKey(_ key: String) -> UInt32 {
        key.utf8.reduce(0) { ($0 << 8) + UInt32($1) }
    }

    private func fourCC(_ value: UInt32) -> String {
        let bigEndian = value.bigEndian
        return withUnsafeBytes(of: bigEndian) { String(bytes: $0, encoding: .utf8) ?? "" }
    }

    private func call(_ input: inout KeyData) -> KeyData? {
        var output = KeyData()
        var outSize = MemoryLayout<KeyData>.stride
        let kr = withUnsafePointer(to: &input) { ip in
            withUnsafeMutablePointer(to: &output) { op in
                IOConnectCallStructMethod_(connection, 2, ip, MemoryLayout<KeyData>.stride, op, &outSize)
            }
        }
        guard kr == KERN_SUCCESS, output.result == 0 else { return nil }
        return output
    }

    private func keyInfo(_ key: String) -> KeyInfo? {
        var request = KeyData()
        request.key = parseKey(key)
        request.data8 = 9
        return call(&request)?.keyInfo
    }

    func readValue(for key: String) -> (String, [UInt8])? {
        guard let info = keyInfo(key) else { return nil }
        var request = KeyData()
        request.key = parseKey(key)
        request.data8 = 5
        request.keyInfo = info
        guard let output = call(&request) else { return nil }
        let bytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(Int(info.dataSize))) }
        return (fourCC(info.dataType), bytes)
    }

    func readFloatValue(for key: String) -> Double? {
        guard let (type, data) = readValue(for: key), type == "flt ", data.count >= 4 else { return nil }
        let bits = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        return Double(Float(bitPattern: UInt32(littleEndian: bits)))
    }
}

let candidates: [(String, String)] = [
    ("Airport Wireless", "TW0P"),
    ("Logic Board A", "TH0a"),
    ("Logic Board B", "TH0x"),
    ("Logic Board C", "TH0b"),
    ("SoC", "TSCD"),
    ("Enclosure A", "Tm0p"),
    ("Enclosure B", "Tm2p"),
    ("Enclosure C", "TRDX"),
    ("Power Supply A", "TPD0"),
    ("Power Supply B", "TPD5"),
    ("Power Supply C", "TPDX"),
    ("PM Board", "TCMb"),
    ("PM Die", "TCMz")
]

guard let smc = SMCReader() else {
    fputs("Failed to open AppleSMC\n", stderr)
    exit(1)
}

print("Thermal probe started. Press Ctrl+C to stop.")
print("time\tlabel\tkey\tvalue")

while true {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    for (label, key) in candidates {
        if let value = smc.readFloatValue(for: key), value > 0, value <= 150 {
            print("\(timestamp)\t\(label)\t\(key)\t" + String(format: "%.2f", value))
        } else {
            print("\(timestamp)\t\(label)\t\(key)\t--")
        }
    }
    fflush(stdout)
    Thread.sleep(forTimeInterval: 1.0)
}
