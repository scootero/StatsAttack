// =============================================================================
// SettingsPanel.swift — shown inside the dropdown when you click "Settings".
// =============================================================================
// Everything is stored in UserDefaults (via @AppStorage), so the menu bar label
// and the store pick changes up immediately.
// =============================================================================

import ServiceManagement
import SwiftUI

struct SettingsPanel: View {
    @ObservedObject var store: StatsStore
    var onDone: () -> Void

    @AppStorage(SettingsKey.refreshInterval) private var refreshInterval: Double = 2
    @AppStorage(SettingsKey.showCPU) private var showCPU = true
    @AppStorage(SettingsKey.showMemory) private var showMemory = true
    @AppStorage(SettingsKey.showNetwork) private var showNetwork = false
    @AppStorage(SettingsKey.showDisk) private var showDisk = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            group("Menu bar shows") {
                Toggle("CPU usage", isOn: $showCPU)
                Toggle("Memory usage", isOn: $showMemory)
                Toggle("Network speed", isOn: $showNetwork)
                Toggle("Disk free space", isOn: $showDisk)
            }

            group("Refresh every") {
                Picker("", selection: $refreshInterval) {
                    Text("1 s").tag(1.0)
                    Text("2 s").tag(2.0)
                    Text("5 s").tag(5.0)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            group("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError).font(.system(size: 10)).foregroundStyle(.red)
                }
            }

            Text("StatsAttack \(Self.version) · inspired by Blip (MIT)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .toggleStyle(.checkbox)
        .font(.system(size: 12))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "Couldn't change login item: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
}
