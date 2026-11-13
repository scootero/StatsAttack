// =============================================================================
// StatsStore.swift — polls the monitors and publishes the latest numbers.
// =============================================================================
// One object the whole UI observes. Every `refreshInterval` seconds it reads
// CPU, memory, network and battery; disk volumes are slower to read, so they
// refresh every 5th tick. It keeps short histories for the sparklines.
//
// `-demo 1` swaps all of this for DemoData (see LaunchOptions.swift).
// Runs on the main actor: each read takes well under a millisecond.
// =============================================================================

import Combine
import SwiftUI

@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var snapshot = StatsSnapshot()
    @Published private(set) var cpuHistory = History()
    @Published private(set) var memoryHistory = History()
    @Published private(set) var downHistory = History()
    @Published private(set) var upHistory = History()
    @Published private(set) var diskReadHistory = History()
    @Published private(set) var diskWriteHistory = History()

    let isDemo: Bool

    private let cpu = CPUMonitor()
    private let memory = MemoryMonitor()
    private let network = NetworkMonitor()
    private let disk = DiskMonitor()
    private let battery = BatteryMonitor()
    private let system = SystemInfoReader()
    private var tick = 0
    private var loop: Task<Void, Never>?

    init(demo: Bool = LaunchOptions.isDemo) {
        isDemo = demo
        if demo {
            loadDemo()
        } else if !LaunchOptions.isRunningTests {
            start()
        }
    }

    /// Seconds between samples. Changed in Settings (stored in UserDefaults).
    var refreshInterval: Double {
        let v = UserDefaults.standard.double(forKey: SettingsKey.refreshInterval)
        return v > 0 ? v : 2
    }

    func start() {
        loop?.cancel()
        sample()   // fill the UI right away
        loop = Task { [weak self] in
            while !Task.isCancelled {
                let seconds = self?.refreshInterval ?? 2
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                guard let self, !Task.isCancelled else { return }
                self.sample()
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    /// Take one reading of everything.
    func sample() {
        var next = snapshot
        next.cpu = cpu.read()
        next.memory = memory.read()
        next.network = network.read()
        next.battery = battery.read()
        next.system = system.read()
        // Read/write speed updates every tick; the volume list every 5th.
        let refreshVolumes = tick % 5 == 0 || snapshot.disk.volumes.isEmpty
        var d = disk.read(includeVolumes: refreshVolumes)
        if !refreshVolumes { d.volumes = snapshot.disk.volumes }
        next.disk = d
        tick += 1

        snapshot = next
        cpuHistory.append(next.cpu.totalUsage)
        memoryHistory.append(next.memory.usagePercent)
        downHistory.append(next.network.downBytesPerSec)
        upHistory.append(next.network.upBytesPerSec)
        diskReadHistory.append(next.disk.readBytesPerSec)
        diskWriteHistory.append(next.disk.writeBytesPerSec)
    }

    private func loadDemo() {
        snapshot = DemoData.snapshot
        for v in DemoData.wave(low: 12, high: 38) { cpuHistory.append(v) }
        for v in DemoData.wave(low: 60, high: 68, phase: 2) { memoryHistory.append(v) }
        for v in DemoData.wave(low: 300_000, high: 6_000_000, phase: 1) { downHistory.append(v) }
        for v in DemoData.wave(low: 50_000, high: 600_000, phase: 3) { upHistory.append(v) }
        for v in DemoData.wave(low: 2_000_000, high: 24_000_000, phase: 4) { diskReadHistory.append(v) }
        for v in DemoData.wave(low: 500_000, high: 9_000_000, phase: 5) { diskWriteHistory.append(v) }
    }
}

/// UserDefaults keys shared by the store, the menu bar label and Settings.
enum SettingsKey {
    static let refreshInterval = "refreshInterval"
    static let showCPU = "menuBar.showCPU"
    static let showMemory = "menuBar.showMemory"
    static let showNetwork = "menuBar.showNetwork"
    static let showDisk = "menuBar.showDisk"
}
