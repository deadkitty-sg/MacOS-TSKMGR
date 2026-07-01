// swift-tools-version: 6.0
import PackageDescription

// Standalone, dependency-free package holding the pure numeric core of the task
// manager's metrics engine so it can be unit-tested with `swift test` without a
// live machine or the Xcode app target. Run: `cd MetricsKit && swift test`.
let package = Package(
    name: "MetricsKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MetricsKit", targets: ["MetricsKit"]),
    ],
    targets: [
        .target(name: "MetricsKit"),
        .testTarget(name: "MetricsKitTests", dependencies: ["MetricsKit"]),
    ]
)
