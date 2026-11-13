// =============================================================================
// SystemInfoReader.swift — Mac model, chip, macOS version, uptime, thermals.
// =============================================================================

import Foundation

final class SystemInfoReader {
    private lazy var modelName = Self.friendlyModelName()
    private lazy var chipName = CPUMonitor.sysctlString("machdep.cpu.brand_string") ?? ""
    private lazy var osVersion: String = {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion)" + (v.patchVersion > 0 ? ".\(v.patchVersion)" : "")
    }()

    func read() -> SystemInfo {
        SystemInfo(
            modelName: modelName,
            chipName: chipName,
            osVersion: osVersion,
            uptime: ProcessInfo.processInfo.systemUptime,
            thermalState: Self.thermalLabel(ProcessInfo.processInfo.thermalState)
        )
    }

    static func thermalLabel(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    /// "MacBook Air" from an identifier like "Mac15,12" is not available offline,
    /// so map the family prefix; good enough for a header line.
    private static func friendlyModelName() -> String {
        let id = CPUMonitor.sysctlString("hw.model") ?? "Mac"
        if id.hasPrefix("MacBookAir") { return "MacBook Air" }
        if id.hasPrefix("MacBookPro") { return "MacBook Pro" }
        if id.hasPrefix("Macmini") { return "Mac mini" }
        if id.hasPrefix("iMac") { return "iMac" }
        if id.hasPrefix("MacPro") { return "Mac Pro" }
        // Apple silicon models report "Mac14,2"-style ids: show the id as-is.
        return id
    }
}
