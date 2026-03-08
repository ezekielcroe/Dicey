//
//  DistributionChartView.swift
//  Dicey
//
//  Distribution chart with PDF/CDF toggle and tap-to-inspect.
//

import SwiftUI
import Charts

enum ChartMode: String, CaseIterable {
    case pdf = "PDF"
    case cdf = "CDF"
}

@available(iOS 16.0, *)
struct DistributionChartView: View {
    let distribution: DistributionData
    var targetNumber: Int? = nil
    var condition: SuccessCondition = .none
    var accentColor: Color = .blue

    @State private var chartMode: ChartMode = .pdf
    @State private var selectedValue: Int? = nil

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                // Header with mode toggle
                HStack {
                    Text("Distribution")
                        .font(.headline)
                    Spacer()
                    Picker("Mode", selection: $chartMode) {
                        ForEach(ChartMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }

                // Chart
                switch chartMode {
                case .pdf:
                    pdfChart
                case .cdf:
                    cdfChart
                }

                // Selected value tooltip
                if let sel = selectedValue {
                    selectedValueInfo(for: sel)
                }

                // Range info
                HStack {
                    Text("Range: \(distribution.minimum)–\(distribution.maximum)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("σ = \(String(format: "%.2f", distribution.standardDeviation))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - PDF Bar Chart

    private var pdfChart: some View {
        Chart {
            ForEach(distribution.sortedBins, id: \.value) { bin in
                BarMark(
                    x: .value("Sum", bin.value),
                    y: .value("Probability %", bin.probability)
                )
                .foregroundStyle(barColor(for: bin.value))
                .cornerRadius(1)
            }

            // Mean line
            RuleMark(x: .value("Mean", distribution.mean))
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .annotation(position: .top, alignment: .center) {
                    Text("μ \(String(format: "%.1f", distribution.mean))")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                }

            // Target line
            if let target = targetNumber, condition != .none, condition != .countSpecificFace {
                RuleMark(x: .value("Target", target))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text("T:\(target)")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }
            }

            // Selected value highlight
            if let sel = selectedValue {
                RuleMark(x: .value("Selected", sel))
                    .foregroundStyle(.primary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxisLabel("Sum", alignment: .center)
        .chartYAxisLabel("Probability %", alignment: .center)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                if let plotFrame = proxy.plotFrame {
                                    let x = drag.location.x - geo[plotFrame].origin.x
                                    if let val: Int = proxy.value(atX: x) {
                                        selectedValue = val
                                    }
                                }
                            }
                            .onEnded { _ in
                                // Keep selection visible; tap elsewhere to clear
                            }
                    )
                    .onTapGesture {
                        selectedValue = nil
                    }
            }
        }
        .frame(height: 180)
    }

    // MARK: - CDF Line Chart

    private var cdfChart: some View {
        Chart {
            ForEach(distribution.cdfBins, id: \.value) { bin in
                LineMark(
                    x: .value("Sum", bin.value),
                    y: .value("Cumulative %", bin.cumulative)
                )
                .foregroundStyle(accentColor)
                .interpolationMethod(.stepEnd)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            ForEach(distribution.cdfBins, id: \.value) { bin in
                AreaMark(
                    x: .value("Sum", bin.value),
                    y: .value("Cumulative %", bin.cumulative)
                )
                .foregroundStyle(accentColor.opacity(0.1))
                .interpolationMethod(.stepEnd)
            }

            // Target line
            if let target = targetNumber, condition != .none, condition != .countSpecificFace {
                RuleMark(x: .value("Target", target))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text("T:\(target)")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }
            }

            // 50% reference line
            RuleMark(y: .value("50%", 50))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

            // Selected value highlight
            if let sel = selectedValue {
                RuleMark(x: .value("Selected", sel))
                    .foregroundStyle(.primary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxisLabel("Sum", alignment: .center)
        .chartYAxisLabel("Cumulative %", alignment: .center)
        .chartYScale(domain: 0...100)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                if let plotFrame = proxy.plotFrame {
                                    let x = drag.location.x - geo[plotFrame].origin.x
                                    if let val: Int = proxy.value(atX: x) {
                                        selectedValue = val
                                    }
                                }
                            }
                    )
                    .onTapGesture { selectedValue = nil }
            }
        }
        .frame(height: 180)
    }

    // MARK: - Selected Value Info

    private func selectedValueInfo(for value: Int) -> some View {
        let count = distribution.frequencies[value] ?? 0
        let prob = Double(count) / Double(distribution.totalIterations) * 100.0
        let cumulativeCount = distribution.frequencies
            .filter { $0.key <= value }
            .values.reduce(0, +)
        let cumProb = Double(cumulativeCount) / Double(distribution.totalIterations) * 100.0
        let atLeast = 100.0 - cumProb + prob

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Value: \(value)")
                    .fontWeight(.bold)
                Text("Exact: \(String(format: "%.1f", prob))%")
            }
            Divider()
            VStack(alignment: .leading, spacing: 2) {
                Text("≤ \(value): \(String(format: "%.1f", cumProb))%")
                Text("≥ \(value): \(String(format: "%.1f", atLeast))%")
            }
        }
        .font(.caption)
        .padding(8)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Bar Coloring

    private func barColor(for value: Int) -> Color {
        guard let target = targetNumber, condition != .none, condition != .countSpecificFace else {
            return accentColor
        }
        let passes: Bool
        switch condition {
        case .meetOrAbove: passes = value >= target
        case .meetOrBelow: passes = value <= target
        case .above:       passes = value > target
        case .below:       passes = value < target
        default: return accentColor
        }
        return passes ? .green.opacity(0.8) : .red.opacity(0.5)
    }
}

// MARK: - Fallback for pre-iOS 16

struct DistributionChartFallback: View {
    let distribution: DistributionData

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Distribution")
                    .font(.headline)

                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 1) {
                        let bins = distribution.sortedBins
                        let maxProb = bins.map(\.probability).max() ?? 1.0

                        ForEach(bins, id: \.value) { bin in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(
                                    width: max(2, geometry.size.width / CGFloat(bins.count) - 1),
                                    height: max(2, CGFloat(bin.probability / maxProb) * geometry.size.height)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)

                HStack {
                    Text("Range: \(distribution.minimum)–\(distribution.maximum)")
                    Spacer()
                    Text("Mean: \(String(format: "%.1f", distribution.mean))")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
    }
}
