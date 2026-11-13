// =============================================================================
// PopoverView.swift — the dropdown you get when you click StatsAttack in the
// menu bar. One card per category; click a card to expand its details.
// =============================================================================

import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: StatsStore
    // HOOK: `-route cpu` opens with the CPU card expanded (screenshots).
    @State private var expanded: AppRoute? = LaunchOptions.route == .overview ? nil : LaunchOptions.route
    @State private var showingSettings = false

    private var s: StatsSnapshot { store.snapshot }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if showingSettings {
                SettingsPanel(store: store) { showingSettings = false }
            } else {
                VStack(spacing: 8) {
                    cpuCard
                    memoryCard
                    diskCard
                    networkCard
                    if s.battery.isPresent { batteryCard }
                }
                .padding(12)
            }
            Divider()
            footer
        }
        .frame(width: 340)
    }

    private func toggle(_ route: AppRoute) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expanded = expanded == route ? nil : route
        }
    }

    // MARK: header / footer

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("StatsAttack").font(.system(size: 14, weight: .bold))
                    if store.isDemo {
                        Text("DEMO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(Color.orange.opacity(0.25)))
                    }
                }
                Text([s.system.modelName, s.system.chipName].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Text("\(s.system.osVersion) · up \(Fmt.uptime(s.system.uptime))")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Thermal").font(.system(size: 10)).foregroundStyle(.secondary)
                Text(s.system.thermalState)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(s.system.thermalState == "Nominal" ? Color.green : Color.orange)
            }
        }
        .padding(12)
    }

    private var footer: some View {
        HStack {
            Button {
                showingSettings.toggle()
            } label: {
                Label(showingSettings ? "Back" : "Settings",
                      systemImage: showingSettings ? "chevron.left" : "gearshape")
            }
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
        }
        .buttonStyle(.borderless)
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: cards

    private var cpuCard: some View {
        SectionCard(title: "CPU", systemImage: "cpu", color: Palette.cpu,
                    headline: Fmt.percent(s.cpu.totalUsage), percent: s.cpu.totalUsage,
                    history: store.cpuHistory.values,
                    isExpanded: expanded == .cpu, onToggle: { toggle(.cpu) }) {
            StatLine(label: "User", value: Fmt.percent(s.cpu.userUsage))
            StatLine(label: "System", value: Fmt.percent(s.cpu.systemUsage))
            StatLine(label: "Load (1, 5, 15 min)",
                     value: s.cpu.loadAverage.map { String(format: "%.2f", $0) }.joined(separator: "  "))
            if s.cpu.performanceCores > 0 {
                StatLine(label: "Cores",
                         value: "\(s.cpu.performanceCores) performance + \(s.cpu.efficiencyCores) efficiency")
            }
            CoreBars(usages: s.cpu.coreUsages)
                .padding(.top, 4)
        }
    }

    private var memoryCard: some View {
        let m = s.memory
        return SectionCard(title: "Memory", systemImage: "memorychip", color: Palette.memory,
                           headline: "\(Fmt.bytes(m.used)) of \(Fmt.bytes(m.total))",
                           percent: m.usagePercent, history: store.memoryHistory.values,
                           isExpanded: expanded == .memory, onToggle: { toggle(.memory) }) {
            StatLine(label: "App memory", value: Fmt.bytes(m.appMemory))
            StatLine(label: "Wired", value: Fmt.bytes(m.wired))
            StatLine(label: "Compressed", value: Fmt.bytes(m.compressed))
            StatLine(label: "Cached files", value: Fmt.bytes(m.cachedFiles))
            StatLine(label: "Swap used", value: "\(Fmt.bytes(m.swapUsed)) of \(Fmt.bytes(m.swapTotal))")
            StatLine(label: "Pressure", value: m.pressureLabel,
                     valueColor: m.pressureLevel >= 4 ? .red : (m.pressureLevel >= 2 ? .orange : .green))
        }
    }

    private var diskCard: some View {
        let d = s.disk
        let boot = d.bootVolume
        return SectionCard(title: "Disk", systemImage: "internaldrive", color: Palette.disk,
                           headline: boot.map { "\(Fmt.bytes($0.free)) free" } ?? "—",
                           percent: boot?.usedPercent,
                           history: d.ioAvailable ? store.diskReadHistory.values : [],
                           historyMax: nil,
                           isExpanded: expanded == .disk, onToggle: { toggle(.disk) }) {
            if d.ioAvailable {
                StatLine(label: "Read", value: Fmt.rate(d.readBytesPerSec), valueColor: Palette.disk)
                StatLine(label: "Write", value: Fmt.rate(d.writeBytesPerSec))
            } else {
                StatLine(label: "Read / write speed", value: "Not available in this build")
            }
            ForEach(d.volumes) { v in
                VStack(alignment: .leading, spacing: 3) {
                    StatLine(label: v.name, value: "\(Fmt.bytes(v.used)) of \(Fmt.bytes(v.total))")
                    UsageBar(percent: v.usedPercent, color: Palette.load(v.usedPercent, base: Palette.disk), height: 4)
                }
                .padding(.top, 3)
            }
        }
    }

    private var networkCard: some View {
        let n = s.network
        return SectionCard(title: "Network", systemImage: "network", color: Palette.network,
                           headline: n.isConnected
                               ? "↓ \(Fmt.rate(n.downBytesPerSec))  ↑ \(Fmt.rate(n.upBytesPerSec))"
                               : "Offline",
                           percent: nil, history: store.downHistory.values, historyMax: nil,
                           isExpanded: expanded == .network, onToggle: { toggle(.network) }) {
            StatLine(label: "Download", value: Fmt.rate(n.downBytesPerSec), valueColor: Palette.network)
            StatLine(label: "Upload", value: Fmt.rate(n.upBytesPerSec), valueColor: Palette.networkUp)
            Sparkline(values: store.upHistory.values, color: Palette.networkUp, fixedMax: nil, height: 20)
            StatLine(label: "Interface", value: n.interfaceName)
            StatLine(label: "Local IP", value: n.localIP)
            StatLine(label: "This session", value: "↓ \(Fmt.bytes(n.sessionDown))  ↑ \(Fmt.bytes(n.sessionUp))")
        }
    }

    private var batteryCard: some View {
        let b = s.battery
        let status = b.isCharging ? "Charging" : (b.onACPower ? "Plugged in" : "On battery")
        return SectionCard(title: "Battery", systemImage: b.isCharging ? "battery.100.bolt" : "battery.75",
                           color: Palette.battery,
                           headline: "\(Fmt.percent(b.level)) · \(status)",
                           percent: b.level, history: [],
                           isExpanded: expanded == .battery, onToggle: { toggle(.battery) }) {
            if let minutes = b.minutesRemaining {
                StatLine(label: b.isCharging ? "Until full" : "Time remaining", value: Fmt.minutes(minutes))
            }
            if let cycles = b.cycleCount { StatLine(label: "Cycle count", value: "\(cycles)") }
            if let health = b.healthPercent { StatLine(label: "Health", value: Fmt.percent(health)) }
        }
    }
}

/// One small vertical bar per logical core.
struct CoreBars: View {
    var usages: [Double]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(usages.enumerated()), id: \.offset) { item in
                VStack(spacing: 2) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.primary.opacity(0.10))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Palette.load(item.element, base: Palette.cpu))
                            .frame(height: max(2, 34 * item.element / 100))
                    }
                    .frame(height: 34)
                    Text("\(item.offset + 1)")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .animation(.easeOut(duration: 0.35), value: usages)
    }
}
