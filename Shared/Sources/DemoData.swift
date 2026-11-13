// =============================================================================
// DemoData.swift — fixed, realistic numbers for screenshots and previews.
// =============================================================================
// Used when the app is launched with `-demo 1`. Everything is deterministic
// (no randomness, no real sensors) so every screenshot run looks identical and
// never shows anything personal. Local IP uses a documentation-only address.
// =============================================================================

import Foundation

enum DemoData {
    private static let gb: UInt64 = 1 << 30

    static let snapshot = StatsSnapshot(
        cpu: CPUStats(
            totalUsage: 23,
            userUsage: 15,
            systemUsage: 8,
            coreUsages: [48, 41, 36, 22, 18, 12, 9, 6, 31, 14],
            loadAverage: [2.41, 2.10, 1.87],
            performanceCores: 6,
            efficiencyCores: 4
        ),
        memory: MemoryStats(
            total: 16 * gb,
            used: 10 * gb + gb / 2,
            appMemory: 7 * gb,
            wired: 2 * gb + gb / 4,
            compressed: gb + gb / 4,
            cachedFiles: 4 * gb,
            swapUsed: gb / 2,
            swapTotal: 2 * gb,
            pressureLevel: 1
        ),
        disk: DiskStats(
            volumes: [
                VolumeStats(name: "Macintosh HD", path: "/", total: 994 * gb, free: 412 * gb),
                VolumeStats(name: "Backup", path: "/Volumes/Backup", total: 1863 * gb, free: 1120 * gb),
            ],
            readBytesPerSec: 18_400_000,
            writeBytesPerSec: 6_200_000,
            ioAvailable: true
        ),
        network: NetworkStats(
            downBytesPerSec: 4_820_000,
            upBytesPerSec: 312_000,
            sessionDown: 3 * gb + gb / 3,
            sessionUp: gb / 2,
            interfaceName: "en0",
            localIP: "192.0.2.24",
            isConnected: true
        ),
        battery: BatteryStats(
            isPresent: true,
            level: 82,
            isCharging: false,
            onACPower: false,
            minutesRemaining: 314,
            cycleCount: 143,
            healthPercent: 96
        ),
        system: SystemInfo(
            modelName: "MacBook Air",
            chipName: "Apple M3",
            osVersion: "macOS 26.0",
            uptime: 3 * 86_400 + 5 * 3_600,
            thermalState: "Nominal"
        )
    )

    /// A smooth, repeatable curve for sparklines: `count` points between `low` and `high`.
    static func wave(count: Int = 60, low: Double, high: Double, phase: Double = 0) -> [Double] {
        (0..<count).map { i in
            let t = Double(i) / 6 + phase
            let s = (sin(t) + sin(t * 0.37 + 1) * 0.6 + 1.6) / 3.2   // 0…1
            return low + (high - low) * s
        }
    }
}
