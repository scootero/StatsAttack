// =============================================================================
// Components.swift — small building blocks shared by the dropdown sections.
// =============================================================================

import Charts
import SwiftUI

/// One color per category, used for bars, charts and icons.
enum Palette {
    static let cpu = Color(red: 0.25, green: 0.60, blue: 1.00)
    static let memory = Color(red: 0.30, green: 0.85, blue: 0.50)
    static let disk = Color(red: 1.00, green: 0.62, blue: 0.20)
    static let network = Color(red: 0.70, green: 0.45, blue: 1.00)
    static let networkUp = Color(red: 1.00, green: 0.40, blue: 0.60)
    static let battery = Color(red: 0.95, green: 0.82, blue: 0.25)

    /// Shifts toward orange/red as usage climbs.
    static func load(_ percent: Double, base: Color) -> Color {
        if percent >= 90 { return .red }
        if percent >= 75 { return .orange }
        return base
    }
}

/// Horizontal capsule bar, 0…100.
struct UsageBar: View {
    var percent: Double
    var color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                Capsule()
                    .fill(color)
                    .frame(width: max(height, geo.size.width * min(1, max(0, percent / 100))))
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.35), value: percent)
    }
}

/// Tiny area chart of recent values. `fixedMax` = 100 for percentages;
/// nil auto-scales to the peak (for speeds).
struct Sparkline: View {
    var values: [Double]
    var color: Color
    var fixedMax: Double? = 100
    var height: CGFloat = 28

    var body: some View {
        let top = fixedMax ?? max(values.max() ?? 1, 1)
        Chart(Array(values.enumerated()), id: \.offset) { point in
            AreaMark(x: .value("t", point.offset), y: .value("v", point.element))
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.35), color.opacity(0.02)],
                                                startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            LineMark(x: .value("t", point.offset), y: .value("v", point.element))
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 1.4))
                .interpolationMethod(.monotone)
        }
        .chartYScale(domain: 0...top)
        .chartXScale(domain: 0...max(1, values.count - 1))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}

/// "Label ........ value" line used inside the detail areas.
struct StatLine: View {
    var label: String
    var value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value).foregroundStyle(valueColor).monospacedDigit()
        }
        .font(.system(size: 11.5))
    }
}

/// A collapsible card: icon, title, headline number, optional bar + sparkline,
/// and a detail area that opens when the header is clicked.
struct SectionCard<Detail: View>: View {
    var title: String
    var systemImage: String
    var color: Color
    var headline: String
    var percent: Double?
    var history: [Double]
    var historyMax: Double? = 100
    var isExpanded: Bool
    var onToggle: () -> Void
    @ViewBuilder var detail: () -> Detail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: systemImage)
                            .foregroundStyle(color)
                            .frame(width: 16)
                        Text(title).font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Text(headline)
                            .font(.system(size: 12, weight: .medium))
                            .monospacedDigit()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    if let percent {
                        UsageBar(percent: percent, color: Palette.load(percent, base: color))
                    }
                    if history.count > 1 {
                        Sparkline(values: history, color: color, fixedMax: historyMax)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 5) {
                    detail()
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
    }
}
