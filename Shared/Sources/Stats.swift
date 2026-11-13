// =============================================================================
// Stats.swift — plain data for one sample of the Mac's vital signs.
// =============================================================================
// No system calls here: monitors (Mac/Sources/Monitors) fill these in, the UI
// reads them, and DemoData builds fake ones. Keeping them plain makes them
// easy to test and to fake for screenshots.
// =============================================================================

import Foundation

struct CPUStats: Equatable {
    var totalUsage: Double = 0          // 0…100
    var userUsage: Double = 0           // 0…100
    var systemUsage: Double = 0         // 0…100
    var coreUsages: [Double] = []       // 0…100 per logical core
    var loadAverage: [Double] = [0, 0, 0]   // 1, 5, 15 min
    var performanceCores = 0
    var efficiencyCores = 0
}

struct MemoryStats: Equatable {
    var total: UInt64 = 0
    var used: UInt64 = 0                // app + wired + compressed (Activity Monitor's "Memory Used")
    var appMemory: UInt64 = 0
    var wired: UInt64 = 0
    var compressed: UInt64 = 0
    var cachedFiles: UInt64 = 0
    var swapUsed: UInt64 = 0
    var swapTotal: UInt64 = 0
    var pressureLevel = 1               // kernel: 1 normal, 2 warning, 4 critical

    var usagePercent: Double {
        total > 0 ? Double(used) / Double(total) * 100 : 0
    }

    var pressureLabel: String {
        switch pressureLevel {
        case 4: return "Critical"
        case 2: return "Warning"
        default: return "Normal"
        }
    }
}

struct VolumeStats: Equatable, Identifiable {
    var id: String { path }
    var name: String
    var path: String
    var total: UInt64
    var free: UInt64

    var used: UInt64 { total > free ? total - free : 0 }
    var usedPercent: Double { total > 0 ? Double(used) / Double(total) * 100 : 0 }
}

struct DiskStats: Equatable {
    var volumes: [VolumeStats] = []
    var readBytesPerSec: Double = 0
    var writeBytesPerSec: Double = 0
    /// False when the I/O counters can't be read (e.g. some sandboxed builds).
    var ioAvailable = false

    /// The startup disk (mounted at "/"), or the first volume.
    var bootVolume: VolumeStats? {
        volumes.first(where: { $0.path == "/" }) ?? volumes.first
    }
}

struct NetworkStats: Equatable {
    var downBytesPerSec: Double = 0
    var upBytesPerSec: Double = 0
    var sessionDown: UInt64 = 0         // bytes since StatsAttack started
    var sessionUp: UInt64 = 0
    var interfaceName = "—"
    var localIP = "—"
    var isConnected = false
}

struct BatteryStats: Equatable {
    var isPresent = false
    var level: Double = 0               // 0…100
    var isCharging = false
    var onACPower = false
    var minutesRemaining: Int?          // nil while macOS is still estimating
    var cycleCount: Int?
    var healthPercent: Double?
}

struct SystemInfo: Equatable {
    var modelName = "Mac"
    var chipName = ""
    var osVersion = ""
    var uptime: TimeInterval = 0
    var thermalState = "Nominal"
}

struct StatsSnapshot: Equatable {
    var cpu = CPUStats()
    var memory = MemoryStats()
    var disk = DiskStats()
    var network = NetworkStats()
    var battery = BatteryStats()
    var system = SystemInfo()
}
