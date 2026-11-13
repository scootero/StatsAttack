// =============================================================================
// NetworkMonitor.swift — live upload/download speed, session totals, local IP.
// =============================================================================
// Reads byte counters for the physical interfaces (en0, en1, … = Wi-Fi and
// Ethernet) with getifaddrs. Those counters are 32-bit and wrap every 4 GiB,
// so rates come from wrap-aware deltas (RateMath.wrappingDelta).
// Loopback and VPN tunnels are skipped so traffic isn't counted twice.
// Adapted from Blip (github.com/blaineam/Blip, MIT, © Blaine Miller).
// Works in the App Sandbox.
// =============================================================================

import Darwin
import Foundation

final class NetworkMonitor {
    private var lastIn: [String: UInt64] = [:]
    private var lastOut: [String: UInt64] = [:]
    private var lastTime: Date?
    private var sessionDown: UInt64 = 0
    private var sessionUp: UInt64 = 0

    func read() -> NetworkStats {
        var stats = NetworkStats()
        var currentIn: [String: UInt64] = [:]
        var currentOut: [String: UInt64] = [:]

        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return stats }
        defer { freeifaddrs(head) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }
            let ifa = entry.pointee
            let name = String(cString: ifa.ifa_name)
            guard name.hasPrefix("en"), let addr = ifa.ifa_addr else { continue }

            let flags = Int32(truncatingIfNeeded: ifa.ifa_flags)
            let isUp = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0
            let family = Int32(addr.pointee.sa_family)

            if family == AF_LINK, let data = ifa.ifa_data {
                let counters = data.assumingMemoryBound(to: if_data.self).pointee
                currentIn[name] = UInt64(counters.ifi_ibytes)
                currentOut[name] = UInt64(counters.ifi_obytes)
            } else if family == AF_INET, isUp, stats.localIP == "—" {
                stats.localIP = Self.numericHost(addr) ?? "—"
                stats.interfaceName = name
                stats.isConnected = true
            }
        }

        let now = Date()
        if let last = lastTime {
            var down: UInt64 = 0, up: UInt64 = 0
            for (name, value) in currentIn {
                if let before = lastIn[name] { down += RateMath.wrappingDelta(previous: before, current: value) }
            }
            for (name, value) in currentOut {
                if let before = lastOut[name] { up += RateMath.wrappingDelta(previous: before, current: value) }
            }
            let interval = now.timeIntervalSince(last)
            stats.downBytesPerSec = RateMath.perSecond(down, over: interval)
            stats.upBytesPerSec = RateMath.perSecond(up, over: interval)
            sessionDown += down
            sessionUp += up
        }
        lastIn = currentIn
        lastOut = currentOut
        lastTime = now
        stats.sessionDown = sessionDown
        stats.sessionUp = sessionUp
        return stats
    }

    /// "192.168.1.20" from a socket address.
    private static func numericHost(_ addr: UnsafeMutablePointer<sockaddr>) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let ok = getnameinfo(addr, socklen_t(addr.pointee.sa_len), &buffer, socklen_t(buffer.count),
                             nil, 0, NI_NUMERICHOST)
        guard ok == 0 else { return nil }
        return buffer.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    }
}
