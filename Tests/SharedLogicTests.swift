// =============================================================================
// SharedLogicTests.swift — unit tests for StatsAttack's pure logic.
// =============================================================================
// Hermetic: no real sensors, network or clocks. They cover the math and
// formatting that every number in the UI depends on. Run in Xcode (⌘U) or:
//   xcodebuild test -scheme StatsAttackMac -destination 'platform=macOS'
// =============================================================================

import XCTest
@testable import StatsAttack

@MainActor
final class SharedLogicTests: XCTestCase {

    // MARK: CPU tick math

    func testCPUDeltaPercentages() {
        let before = CPUTicks(user: 100, system: 50, nice: 0, idle: 850)
        let after = CPUTicks(user: 130, system: 60, nice: 10, idle: 900)
        let d = after.delta(since: before)          // user 30, system 10, nice 10, idle 50
        XCTAssertEqual(d.total, 100)
        XCTAssertEqual(d.busyPercent, 50, accuracy: 0.001)
        XCTAssertEqual(d.userPercent, 40, accuracy: 0.001)
        XCTAssertEqual(d.systemPercent, 10, accuracy: 0.001)
    }

    func testCPUDeltaSurvivesCounterWrap() {
        let before = CPUTicks(user: UInt32.max - 9, system: 0, nice: 0, idle: 0)
        let after = CPUTicks(user: 10, system: 0, nice: 0, idle: 20)
        let d = after.delta(since: before)
        XCTAssertEqual(d.user, 20)                   // 10 to wrap + 10 after
        XCTAssertEqual(d.busyPercent, 50, accuracy: 0.001)
    }

    func testIdleCPUIsZeroAndEmptyDeltaIsSafe() {
        XCTAssertEqual(CPUTickDelta(idle: 100).busyPercent, 0)
        XCTAssertEqual(CPUTickDelta().busyPercent, 0)   // no division by zero
    }

    // MARK: Rates

    func testWrappingDelta() {
        XCTAssertEqual(RateMath.wrappingDelta(previous: 1_000, current: 5_000), 4_000)
        XCTAssertEqual(RateMath.wrappingDelta(previous: RateMath.wrap32 - 100, current: 50), 150)
    }

    func testMonotonicDeltaTreatsResetAsZero() {
        XCTAssertEqual(RateMath.monotonicDelta(previous: 10, current: 25), 15)
        XCTAssertEqual(RateMath.monotonicDelta(previous: 500, current: 20), 0)
    }

    func testPerSecond() {
        XCTAssertEqual(RateMath.perSecond(4_000, over: 2), 2_000)
        XCTAssertEqual(RateMath.perSecond(4_000, over: 0), 0)
    }

    // MARK: History

    func testHistoryKeepsOnlyCapacity() {
        var h = History(capacity: 3)
        [1, 2, 3, 4, 5].forEach { h.append($0) }
        XCTAssertEqual(h.values, [3, 4, 5])
        XCTAssertEqual(h.latest, 5)
        XCTAssertEqual(h.peak, 5)
    }

    // MARK: Formatting

    func testFormatting() {
        XCTAssertEqual(Fmt.percent(42.4), "42%")
        XCTAssertEqual(Fmt.bytes(512), "512 B")
        XCTAssertEqual(Fmt.bytes(16 << 30), "16 GB")
        XCTAssertEqual(Fmt.bytes(1536 << 20), "1.5 GB")
        XCTAssertEqual(Fmt.rate(1_250_000), "1.3 MB/s")
        XCTAssertEqual(Fmt.rate(850_000), "850 KB/s")
        XCTAssertEqual(Fmt.compactRate(850_000), "850K")
        XCTAssertEqual(Fmt.compactRate(12_400_000), "12M")
        XCTAssertEqual(Fmt.minutes(135), "2h 15m")
        XCTAssertEqual(Fmt.uptime(3 * 86_400 + 5 * 3_600), "3d 5h")
    }

    // MARK: Models

    func testMemoryAndVolumeMath() {
        let m = MemoryStats(total: 16, used: 4)
        XCTAssertEqual(m.usagePercent, 25, accuracy: 0.001)
        let v = VolumeStats(name: "HD", path: "/", total: 200, free: 50)
        XCTAssertEqual(v.used, 150)
        XCTAssertEqual(v.usedPercent, 75, accuracy: 0.001)
    }

    func testMenuBarText() {
        let s = DemoData.snapshot
        XCTAssertEqual(MenuBarLabel.text(for: s, cpu: true, memory: true, network: false, disk: false),
                       "CPU 23%  MEM 66%")
        XCTAssertEqual(MenuBarLabel.text(for: s, cpu: false, memory: false, network: false, disk: false), "")
    }

    // MARK: Automation hooks (screenshots depend on these)

    func testDemoDataIsStableAndPlausible() {
        let s = DemoData.snapshot
        XCTAssertEqual(s.cpu.totalUsage, 23)
        XCTAssertEqual(s.cpu.coreUsages.count, s.cpu.performanceCores + s.cpu.efficiencyCores)
        XCTAssertTrue(s.battery.isPresent)
        XCTAssertNotNil(s.disk.bootVolume)
        XCTAssertEqual(DemoData.wave(low: 10, high: 20).count, 60)
        XCTAssertTrue(DemoData.wave(low: 10, high: 20).allSatisfy { (10...20).contains($0) })
    }

    func testEveryRouteRoundTrips() {
        for route in AppRoute.allCases {
            XCTAssertEqual(AppRoute(rawValue: route.rawValue), route)
        }
    }

    func testDetectsTestHost() {
        XCTAssertTrue(LaunchOptions.isRunningTests)
    }
}
