// =============================================================================
// LaunchOptions.swift — the hooks that make automation possible.
// =============================================================================
// Scripts can't click the menu bar. Instead they launch the app with flags:
//
//   -demo 1            fixed, good-looking numbers (no real sensors). Used by
//                      screenshots and SwiftUI previews.
//   -route <name>      open the dropdown with that section expanded.
//
// Example:  open StatsAttack.app --args -demo 1 -route cpu
// =============================================================================

import Foundation

/// Every section a script (or a screenshot) can jump to.
/// Keep SCREENSHOT_ROUTES in ship.config in sync with the ones worth a screenshot.
enum AppRoute: String, CaseIterable, Sendable {
    case overview
    case cpu
    case memory
    case disk
    case network
    case battery
}

enum LaunchOptions {
    /// `-demo 1` → use DemoData instead of real monitors.
    static var isDemo: Bool {
        UserDefaults.standard.bool(forKey: "demo")
    }

    /// `-route cpu` → open with that section expanded. nil = normal launch.
    static var route: AppRoute? {
        UserDefaults.standard.string(forKey: "route").flatMap(AppRoute.init(rawValue:))
    }

    /// True when XCTest is hosting the app: skip polling so tests stay fast.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
