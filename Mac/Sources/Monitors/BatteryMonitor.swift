// =============================================================================
// BatteryMonitor.swift — charge, charging state, time left, cycles, health.
// =============================================================================
// Charge/time: IOPowerSources (public API, works sandboxed).
// Cycles/health: the AppleSmartBattery entry in the IOKit registry. Those keys
// are undocumented, so they're skipped in App Store builds (`APPSTORE` flag),
// the same choice Blip makes. Desktop Macs simply report no battery.
// Adapted from Blip (github.com/blaineam/Blip, MIT, © Blaine Miller).
// =============================================================================

import Foundation
import IOKit
import IOKit.ps

final class BatteryMonitor {
    func read() -> BatteryStats {
        var stats = BatteryStats()

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return stats }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?
                    .takeUnretainedValue() as? [String: Any],
                  (info[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType
            else { continue }

            stats.isPresent = true
            if let current = info[kIOPSCurrentCapacityKey] as? Int,
               let maximum = info[kIOPSMaxCapacityKey] as? Int, maximum > 0 {
                stats.level = Double(current) / Double(maximum) * 100
            }
            stats.isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
            stats.onACPower = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            if let minutes = info[kIOPSTimeToEmptyKey] as? Int, minutes > 0, !stats.onACPower {
                stats.minutesRemaining = minutes
            } else if let minutes = info[kIOPSTimeToFullChargeKey] as? Int, minutes > 0, stats.isCharging {
                stats.minutesRemaining = minutes
            }
        }

        #if !APPSTORE
        if stats.isPresent { Self.readHealth(into: &stats) }
        #endif
        return stats
    }

    #if !APPSTORE
    private static func readHealth(into stats: inout BatteryStats) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return }

        stats.cycleCount = dict["CycleCount"] as? Int
        let current = (dict["NominalChargeCapacity"] as? Int) ?? (dict["AppleRawMaxCapacity"] as? Int)
        if let current, let design = dict["DesignCapacity"] as? Int, design > 0 {
            stats.healthPercent = min(100, Double(current) / Double(design) * 100)
        }
    }
    #endif
}
