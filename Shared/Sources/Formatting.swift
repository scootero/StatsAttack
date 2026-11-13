// =============================================================================
// Formatting.swift — turn raw numbers into short, readable labels.
// =============================================================================
// Hand-rolled (not ByteCountFormatter) so the output is identical on every Mac
// and locale, which keeps tests and screenshots stable.
// =============================================================================

import Foundation

enum Fmt {
    /// 42.4 → "42%"
    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    /// Memory and disk sizes, 1024-based like Activity Monitor: "16 GB", "512 MB", "1.5 TB".
    static func bytes(_ value: UInt64) -> String {
        scaled(Double(value), base: 1024, units: ["B", "KB", "MB", "GB", "TB", "PB"], suffix: "")
    }

    /// Transfer rates, 1000-based like network speeds: "1.2 MB/s", "850 KB/s".
    static func rate(_ bytesPerSecond: Double) -> String {
        scaled(max(0, bytesPerSecond), base: 1000, units: ["B", "KB", "MB", "GB", "TB"], suffix: "/s")
    }

    /// Compact rate for the menu bar: "0K", "850K", "1.2M", "12M", "1.1G".
    static func compactRate(_ bytesPerSecond: Double) -> String {
        let v = max(0, bytesPerSecond)
        if v < 1_000_000 { return "\(Int((v / 1000).rounded()))K" }
        if v < 1_000_000_000 { return short(v / 1_000_000) + "M" }
        return short(v / 1_000_000_000) + "G"
    }

    /// 135 → "2h 15m", 42 → "42m"
    static func minutes(_ total: Int) -> String {
        let h = total / 60, m = total % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    /// Seconds → "3d 4h", "5h 12m", "18m"
    static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds)) / 60
        let d = total / 1440, h = (total % 1440) / 60, m = total % 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    // MARK: helpers

    private static func scaled(_ value: Double, base: Double, units: [String], suffix: String) -> String {
        var v = value
        var i = 0
        while v >= base && i < units.count - 1 {
            v /= base
            i += 1
        }
        let number = i == 0 ? "\(Int(v.rounded()))" : short(v)
        return "\(number) \(units[i])\(suffix)"
    }

    /// One decimal under 10, none above: 1.24 → "1.2", 12.6 → "13".
    private static func short(_ v: Double) -> String {
        if v < 10 {
            let tenths = (v * 10).rounded() / 10
            return tenths == tenths.rounded() ? "\(Int(tenths))" : String(format: "%.1f", tenths)
        }
        return "\(Int(v.rounded()))"
    }
}
