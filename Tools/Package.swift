// swift-tools-version: 6.2
import PackageDescription

// Standalone diagnostic probes that accompany the app but are not part of the
// Xcode target. Build with `swift build` in Tools/; run e.g.
// `swift run thermal-probe`.
//
// Packaging note for the standalone runtime .app wrapper
// (Tools/package_swift_runtime_app.sh): the final macOS 26 app bundle must
// preserve AppIcon.icns, Assets.car, CFBundleIconFile = "AppIcon" and
// CFBundleIconName = "AppIcon" (bundle id com.linqin.MacOSTSKMGR, minimum
// macOS 26.0). This keeps the newer macOS 26 icon presentation intact when
// packaging the executable outside the Xcode-generated app bundle.

let package = Package(
    name: "Tools",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "thermal-probe",
            path: ".",
            sources: ["thermal_probe.swift"]
        ),
        // ane_probe.swift is intentionally NOT a target: it sketches an ANE
        // load generator against an `MLProgram { ... }` builder DSL that is not
        // public CoreML API, so it does not compile. It is kept as a design
        // reference only.
        // Reference-only documentation of the pmgr voltage-state detection
        // strategy; a library target so it at least keeps compiling.
        .target(
            name: "FrequencyTierReference",
            path: ".",
            sources: ["cpu_frequency_tier_reference.swift"]
        ),
    ]
)
