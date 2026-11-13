// =============================================================================
// DiskMonitor.swift — volumes (space used/free) and live read/write speed.
// =============================================================================
// Volumes: FileManager, works everywhere.
// Read/write speed: sums the cumulative "Bytes (Read)/(Write)" statistics that
// each block-storage driver publishes in the IOKit registry, then takes the
// change per second. Those keys are undocumented; if they can't be read (some
// sandboxed setups), `ioAvailable` stays false and the UI says so.
// I/O approach adapted from Blip (github.com/blaineam/Blip, MIT, © Blaine Miller).
// =============================================================================

import Foundation
import IOKit

final class DiskMonitor {
    private var lastRead: UInt64?
    private var lastWrite: UInt64?
    private var lastTime: Date?

    func read(includeVolumes: Bool = true) -> DiskStats {
        var stats = DiskStats()
        if includeVolumes { stats.volumes = Self.readVolumes() }

        if let totals = Self.readIOTotals() {
            let now = Date()
            if let lr = lastRead, let lw = lastWrite, let lt = lastTime {
                let interval = now.timeIntervalSince(lt)
                stats.readBytesPerSec = RateMath.perSecond(
                    RateMath.monotonicDelta(previous: lr, current: totals.read), over: interval)
                stats.writeBytesPerSec = RateMath.perSecond(
                    RateMath.monotonicDelta(previous: lw, current: totals.write), over: interval)
            }
            lastRead = totals.read
            lastWrite = totals.write
            lastTime = now
            stats.ioAvailable = true
        }
        return stats
    }

    /// Visible, mounted volumes with a real size (skips system/hidden ones).
    static func readVolumes() -> [VolumeStats] {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey,
            .volumeIsBrowsableKey,
        ]
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else { return [] }

        return urls.compactMap { url -> VolumeStats? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.volumeIsBrowsable ?? true,
                  let total = values.volumeTotalCapacity, total > 0 else { return nil }
            // "Important usage" counts purgeable space as free, like Finder does.
            let important = values.volumeAvailableCapacityForImportantUsage ?? 0
            let plain = Int64(values.volumeAvailableCapacity ?? 0)
            let free = max(important, plain)
            return VolumeStats(
                name: values.volumeName ?? url.lastPathComponent,
                path: url.path,
                total: UInt64(total),
                free: UInt64(max(0, free))
            )
        }
    }

    /// Cumulative bytes read/written by all disks since boot, or nil if unreadable.
    private static func readIOTotals() -> (read: UInt64, write: UInt64)? {
        var iterator: io_iterator_t = 0
        guard let matching = IOServiceMatching("IOBlockStorageDriver"),
              IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS
        else { return nil }
        defer { IOObjectRelease(iterator) }

        var read: UInt64 = 0, write: UInt64 = 0, found = false
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any],
               let io = dict["Statistics"] as? [String: Any] {
                if let r = (io["Bytes (Read)"] as? NSNumber)?.uint64Value { read += r; found = true }
                if let w = (io["Bytes (Write)"] as? NSNumber)?.uint64Value { write += w; found = true }
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
        return found ? (read, write) : nil
    }
}
