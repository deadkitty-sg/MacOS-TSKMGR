import Foundation

// Reference-only helper for future Apple Silicon CPU tier detection work.
// This file is not wired into the app target. It documents the preferred
// detection strategy for pmgr voltage-state properties.

enum ReferenceCoreTierMode: String {
    case performanceEfficiency = "P/E"
    case superPerformance = "S/P"
    case superEfficiency = "S/E"
    case genericPrimarySecondary = "Primary/Secondary"
    case singlePerformanceTier = "Single-tier"
}

struct ReferenceFrequencyCandidate {
    let propertyName: String
    let rawValue: UInt32
    let normalizedHertz: Double
}

struct ReferenceFrequencyDetectionResult {
    let mode: ReferenceCoreTierMode
    let selected: [ReferenceFrequencyCandidate]
}

enum CPUFrequencyTierReference {
    // Only include properties that have been validated as CPU core-tier
    // candidates. Do not sort over every voltage-states*-sram key blindly.
    static let validatedCandidateKeys: [String] = [
        "voltage-states1-sram",
        "voltage-states5-sram",
        "voltage-states22-sram",
        "voltage-states23-sram",
        "voltage-states24-sram"
    ]

    // Convert raw property values into one comparable unit before sorting.
    // Some pmgr properties have historically appeared in different scales.
    static func normalizeToHertz(_ rawValue: UInt32) -> Double {
        if rawValue > 100_000_000 {
            return Double(rawValue)
        }
        return Double(rawValue) * 1_000
    }

    // Determine how many CPU frequency tiers we expect to display.
    // For today:
    // - Intel: 1
    // - Known Apple Silicon layouts: 2
    // - Future three-tier layouts can be raised to 3 once the UI supports it.
    static func expectedTierCount(for mode: ReferenceCoreTierMode) -> Int {
        switch mode {
        case .singlePerformanceTier:
            return 1
        case .performanceEfficiency, .superPerformance, .superEfficiency, .genericPrimarySecondary:
            return 2
        }
    }

    // Preferred algorithm:
    // 1. Collect only validated CPU frequency candidate keys.
    // 2. Read raw values and normalize them to one unit.
    // 3. For known layouts, map explicitly by validated property semantics.
    // 4. For unknown layouts, sort descending and fall back to generic tier labels.
    static func detectMode(from candidates: [ReferenceFrequencyCandidate]) -> ReferenceCoreTierMode {
        let names = Set(candidates.map(\.propertyName))
        let hasClassicEfficiency = names.contains("voltage-states1-sram")
        let hasPrimary = names.contains("voltage-states5-sram")
        let hasModernPerformance = !names.intersection(["voltage-states22-sram", "voltage-states23-sram", "voltage-states24-sram"]).isEmpty

        if hasPrimary && hasClassicEfficiency && hasModernPerformance {
            return .superEfficiency
        }
        if hasPrimary && hasClassicEfficiency {
            return .performanceEfficiency
        }
        if hasPrimary && hasModernPerformance {
            return .superPerformance
        }
        if candidates.count >= 2 {
            return .genericPrimarySecondary
        }
        return .singlePerformanceTier
    }

    static func selectDisplayTiers(from candidates: [ReferenceFrequencyCandidate]) -> ReferenceFrequencyDetectionResult {
        let sorted = candidates.sorted { lhs, rhs in
            if lhs.normalizedHertz != rhs.normalizedHertz {
                return lhs.normalizedHertz > rhs.normalizedHertz
            }
            return lhs.propertyName < rhs.propertyName
        }

        let mode = detectMode(from: sorted)
        let tierCount = expectedTierCount(for: mode)
        return ReferenceFrequencyDetectionResult(
            mode: mode,
            selected: Array(sorted.prefix(tierCount))
        )
    }
}
