// =============================================================================
// MacApp.swift — StatsAttack entry point: a menu bar app with a dropdown.
// =============================================================================
// No Dock icon and no main window (INFOPLIST_KEY_LSUIElement: YES in
// project.yml). Everything lives in the menu bar:
//   label     → MenuBarLabel  (compact numbers, e.g. "CPU 23%  MEM 66%")
//   dropdown  → PopoverView   (cards per category, click to expand)
// =============================================================================

import SwiftUI

@main
struct MacApp: App {
    @StateObject private var store = StatsStore()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(store: store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

/// What sits in the menu bar itself. Pieces are toggled in Settings.
struct MenuBarLabel: View {
    @ObservedObject var store: StatsStore
    @AppStorage(SettingsKey.showCPU) private var showCPU = true
    @AppStorage(SettingsKey.showMemory) private var showMemory = true
    @AppStorage(SettingsKey.showNetwork) private var showNetwork = false
    @AppStorage(SettingsKey.showDisk) private var showDisk = false

    var body: some View {
        let text = Self.text(for: store.snapshot, cpu: showCPU, memory: showMemory,
                             network: showNetwork, disk: showDisk)
        if text.isEmpty {
            Image(systemName: "gauge.with.dots.needle.67percent")
        } else {
            Text(text).monospacedDigit()
        }
    }

    /// Kept static + pure so it can be unit-tested.
    static func text(for s: StatsSnapshot, cpu: Bool, memory: Bool, network: Bool, disk: Bool) -> String {
        var parts: [String] = []
        if cpu { parts.append("CPU \(Fmt.percent(s.cpu.totalUsage))") }
        if memory { parts.append("MEM \(Fmt.percent(s.memory.usagePercent))") }
        if network {
            parts.append("↓\(Fmt.compactRate(s.network.downBytesPerSec)) ↑\(Fmt.compactRate(s.network.upBytesPerSec))")
        }
        if disk, let boot = s.disk.bootVolume { parts.append("SSD \(Fmt.bytes(boot.free))") }
        return parts.joined(separator: "  ")
    }
}
