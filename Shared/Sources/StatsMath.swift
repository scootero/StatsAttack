// =============================================================================
// StatsMath.swift — the arithmetic behind the numbers, kept pure + tested.
// =============================================================================
// Counter math adapted from Blip (github.com/blaineam/Blip, MIT License,
// © Blaine Miller): CPU tick deltas and wrap-aware 32-bit network counters.
// =============================================================================

import Foundation

/// Raw CPU tick counters for one core, as the kernel reports them.
/// They only ever count up, and wrap around at 2^32.
struct CPUTicks: Equatable {
    var user: UInt32
    var system: UInt32
    var nice: UInt32
    var idle: UInt32

    /// Ticks spent in each state since `previous` (wrap-safe).
    func delta(since previous: CPUTicks) -> CPUTickDelta {
        CPUTickDelta(
            user: UInt64(user &- previous.user),
            system: UInt64(system &- previous.system),
            nice: UInt64(nice &- previous.nice),
            idle: UInt64(idle &- previous.idle)
        )
    }
}

/// Ticks elapsed between two samples. Summable across cores.
struct CPUTickDelta: Equatable {
    var user: UInt64 = 0
    var system: UInt64 = 0
    var nice: UInt64 = 0
    var idle: UInt64 = 0

    var total: UInt64 { user + system + nice + idle }

    static func + (a: CPUTickDelta, b: CPUTickDelta) -> CPUTickDelta {
        CPUTickDelta(user: a.user + b.user, system: a.system + b.system,
                     nice: a.nice + b.nice, idle: a.idle + b.idle)
    }

    /// Busy share, 0…100. "User" includes nice (low-priority) time.
    var busyPercent: Double { percent(user + nice + system) }
    var userPercent: Double { percent(user + nice) }
    var systemPercent: Double { percent(system) }

    private func percent(_ part: UInt64) -> Double {
        let t = total
        guard t > 0 else { return 0 }
        return min(100, max(0, Double(part) / Double(t) * 100))
    }
}

enum RateMath {
    /// Network byte counters from getifaddrs are 32-bit and wrap at 4 GiB.
    static let wrap32: UInt64 = 1 << 32

    /// Bytes moved between two readings of a 32-bit counter (handles one wrap).
    static func wrappingDelta(previous: UInt64, current: UInt64) -> UInt64 {
        current >= previous ? current - previous : (wrap32 - previous) + current
    }

    /// Bytes moved between two readings of a 64-bit counter that should only grow.
    /// A drop means the counter reset (e.g. a disk was ejected): count it as zero.
    static func monotonicDelta(previous: UInt64, current: UInt64) -> UInt64 {
        current >= previous ? current - previous : 0
    }

    static func perSecond(_ bytes: UInt64, over interval: TimeInterval) -> Double {
        interval > 0 ? Double(bytes) / interval : 0
    }
}

/// A fixed-length list of recent values for the sparkline charts.
struct History: Equatable {
    let capacity: Int
    private(set) var values: [Double] = []

    init(capacity: Int = 60) {
        self.capacity = max(1, capacity)
    }

    mutating func append(_ value: Double) {
        values.append(value)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
    }

    var latest: Double { values.last ?? 0 }
    var peak: Double { values.max() ?? 0 }
}
