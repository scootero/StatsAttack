// =============================================================================
// CPUMonitor.swift — total + per-core CPU usage, load average, core counts.
// =============================================================================
// Reads per-core tick counters with host_processor_info and turns the change
// since the last call into percentages (see CPUTicks in StatsMath.swift).
// Approach adapted from Blip (github.com/blaineam/Blip, MIT, © Blaine Miller).
// Works in the App Sandbox.
// =============================================================================

import Darwin
import Foundation

final class CPUMonitor {
    private var previous: [CPUTicks] = []
    private lazy var performanceCores = Self.sysctlInt("hw.perflevel0.physicalcpu")
    private lazy var efficiencyCores = Self.sysctlInt("hw.perflevel1.physicalcpu")

    func read() -> CPUStats {
        var stats = CPUStats()
        stats.performanceCores = performanceCores
        stats.efficiencyCores = efficiencyCores

        var load = [Double](repeating: 0, count: 3)
        if getloadavg(&load, 3) == 3 { stats.loadAverage = load }

        let current = Self.readTicks()
        guard !current.isEmpty else { return stats }
        defer { previous = current }

        // First call: no baseline yet, so report zero usage.
        guard previous.count == current.count else {
            stats.coreUsages = Array(repeating: 0, count: current.count)
            return stats
        }

        var sum = CPUTickDelta()
        var cores: [Double] = []
        for (now, before) in zip(current, previous) {
            let d = now.delta(since: before)
            cores.append(d.busyPercent)
            sum = sum + d
        }
        stats.coreUsages = cores
        stats.totalUsage = sum.busyPercent
        stats.userUsage = sum.userPercent
        stats.systemUsage = sum.systemPercent
        return stats
    }

    /// One CPUTicks per logical core.
    private static func readTicks() -> [CPUTicks] {
        var coreCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                         &coreCount, &info, &infoCount)
        guard result == KERN_SUCCESS, let info else { return [] }
        defer {
            // The kernel allocated this array for us; give it back.
            let size = vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        let stride = Int(CPU_STATE_MAX)
        return (0..<Int(coreCount)).map { core in
            let base = core * stride
            return CPUTicks(
                user: UInt32(bitPattern: info[base + Int(CPU_STATE_USER)]),
                system: UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]),
                nice: UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)]),
                idle: UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)])
            )
        }
    }

    static func sysctlInt(_ name: String) -> Int {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? Int(value) : 0
    }

    static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return buffer.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    }
}
