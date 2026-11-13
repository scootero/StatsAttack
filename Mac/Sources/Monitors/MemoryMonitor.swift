// =============================================================================
// MemoryMonitor.swift — memory used, its breakdown, swap and pressure.
// =============================================================================
// Uses the same definitions as Activity Monitor:
//   App Memory   = internal pages − purgeable pages
//   Cached Files = purgeable + external (file-backed) pages
//   Memory Used  = App Memory + Wired + Compressed
// Adapted from Blip (github.com/blaineam/Blip, MIT, © Blaine Miller).
// Works in the App Sandbox.
// =============================================================================

import Darwin
import Foundation

final class MemoryMonitor {
    func read() -> MemoryStats {
        var stats = MemoryStats()
        stats.total = ProcessInfo.processInfo.physicalMemory

        var vm = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &vm) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return stats }

        let page = UInt64(getpagesize())
        let internalPages = UInt64(vm.internal_page_count) * page
        let purgeable = UInt64(vm.purgeable_count) * page
        let external = UInt64(vm.external_page_count) * page

        stats.wired = UInt64(vm.wire_count) * page
        stats.compressed = UInt64(vm.compressor_page_count) * page
        stats.appMemory = internalPages > purgeable ? internalPages - purgeable : 0
        stats.cachedFiles = purgeable + external
        stats.used = min(stats.total, stats.appMemory + stats.wired + stats.compressed)

        var pressure: Int32 = 0
        var pressureSize = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &pressure, &pressureSize, nil, 0) == 0 {
            stats.pressureLevel = Int(pressure)
        }

        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0 {
            stats.swapUsed = swap.xsu_used
            stats.swapTotal = swap.xsu_total
        }
        return stats
    }
}
