// swift-tools-version: 6.2
import PackageDescription

// Packaging note for the standalone runtime .app wrapper:
// The final macOS 26 app bundle must preserve:
// - AppIcon.icns
// - Assets.car
// - CFBundleIconFile = "AppIcon"
// - CFBundleIconName = "AppIcon"
// This keeps the newer macOS 26 icon presentation intact when packaging the
// executable outside the Xcode-generated app bundle.
enum RuntimeAppPackagingDefaults {
    static let appName = "MacOSTSKMGR"
    static let bundleIdentifier = "com.linqin.MacOSTSKMGR"
    static let minimumMacOSVersion = "26.0"
    static let iconBaseName = "AppIcon"
    static let requiresAssetCatalog = true
    static let requiresCFBundleIconName = true
}

let package = Package(
    name: "MacOSTSKMGR",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "MacOSTSKMGR", targets: ["MacOSTSKMGR"])
    ],
    targets: [
        .executableTarget(
            name: "MacOSTSKMGR"
        )
    ]
)
