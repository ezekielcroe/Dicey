//
//  DistributionChartView.swift
//  Dicey
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct DistributionChartView: View {
    let distribution: DistributionData
    var targetNumber: Int? = nil
    var condition: SuccessCondition = .none
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distribution")
                .font(.headline)
            
            Chart {
                ForEach(distribution.sortedBins, id: \.value) { bin in
                    BarMark(
                        x: .value("Sum", bin.value),
                        y: .value("Probability", bin.probability)
                    )
                    .foregroundStyle(barColor(for: bin.value))
                    .cornerRadius(1)
                }
                
                // Median line
                RuleMark(x: .value("Median", distribution.median))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text("μ \(String(format: "%.1f", distribution.mean))")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                
                // Target line (if condition is set)
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
            }
            .chartXAxisLabel("Sum", alignment: .center)
            .chartYAxisLabel("Probability %", alignment: .center)
            .frame(height: 180)
            
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
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    /// Color bars based on whether they pass/fail the success condition
    private func barColor(for value: Int) -> Color {
        guard let target = targetNumber, condition != .none, condition != .countSpecificFace else {
            return accentColor
        }
        
        let passes: Bool
        switch condition {
        case .meetOrAbove: passes = value >= target
        case .meetOrBelow: passes = value <= target
        case .above: passes = value > target
        case .below: passes = value < target
        default: return accentColor
        }
        
        return passes ? .green.opacity(0.8) : .red.opacity(0.5)
    }
}

// MARK: - Fallback for older iOS

struct DistributionChartFallback: View {
    let distribution: DistributionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distribution")
                .font(.headline)
            
            // Simple text-based fallback
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
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
