import Foundation
import IOKit
import IOKit.ps

/// Battery/power-source sampling via the public IOPowerSources API plus the
/// AppleSmartBattery registry entry (cycle count, health, temperature). All
/// calls are cheap in-process lookups, safe to run every refresh tick. On a
/// desktop Mac `sample().isPresent` is false and the UI hides the page.
enum BatteryProbe {
    struct Sample: Sendable {
        var isPresent = false
        var chargePercent: Double = 0
        var isCharging = false
        var onACPower = false
        var timeRemainingMinutes: Int?
        var cycleCount: Int?
        var healthPercent: Double?
        var temperatureCelsius: Double?
        var adapterWatts: Double?
    }

    static func sample() -> Sample {
        var result = Sample()

        if let infoRef = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(infoRef)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                guard let description = IOPSGetPowerSourceDescription(infoRef, source)?.takeUnretainedValue() as? [String: Any],
                      (description[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType
                else { continue }

                result.isPresent = true
                let current = (description[kIOPSCurrentCapacityKey] as? NSNumber)?.doubleValue ?? 0
                let maximum = (description[kIOPSMaxCapacityKey] as? NSNumber)?.doubleValue ?? 0
                result.chargePercent = maximum > 0 ? min(max(current / maximum * 100, 0), 100) : 0
                result.isCharging = (description[kIOPSIsChargingKey] as? NSNumber)?.boolValue ?? false
                result.onACPower = (description[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
                let minutesKey = result.isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
                if let minutes = (description[minutesKey] as? NSNumber)?.intValue, minutes > 0 {
                    result.timeRemainingMinutes = minutes
                }
                break
            }
        }

        guard result.isPresent else { return result }

        readSmartBatteryRegistry(into: &result)

        if result.onACPower,
           let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any],
           let watts = (adapter[kIOPSPowerAdapterWattsKey] as? NSNumber)?.doubleValue, watts > 0 {
            result.adapterWatts = watts
        }
        return result
    }

    private static func readSmartBatteryRegistry(into sample: inout Sample) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }

        func number(_ key: String) -> NSNumber? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber
        }

        if let cycles = number("CycleCount")?.intValue, cycles >= 0 {
            sample.cycleCount = cycles
        }
        if let design = number("DesignCapacity")?.doubleValue,
           let nominal = (number("NominalChargeCapacity") ?? number("AppleRawMaxCapacity") ?? number("MaxCapacity"))?.doubleValue,
           design > 0, nominal > 0 {
            sample.healthPercent = min(nominal / design * 100, 100)
        }
        if let rawTemperature = number("Temperature")?.doubleValue, rawTemperature > 0 {
            // The registry reports hundredths of a degree; some firmware uses
            // centi-Kelvin, most uses centi-Celsius — disambiguate by range.
            let scaled = rawTemperature / 100.0
            let celsius = scaled > 200 ? scaled - 273.15 : scaled
            if celsius > 0, celsius < 120 {
                sample.temperatureCelsius = celsius
            }
        }
    }
}
