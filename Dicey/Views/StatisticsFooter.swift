//
//  StatisticsFooter.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

struct StatisticsFooter: View {
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Average & Std Dev
            HStack {
                Text("Estimated Average:")
                Spacer()
                if vm.isCalculating && vm.estimatedAverage == nil {
                    ProgressView().scaleEffect(0.8)
                } else if let avg = vm.estimatedAverage {
                    Text(String(format: "%.2f", avg))
                        .fontWeight(.bold)
                } else {
                    Text("N/A").foregroundColor(.secondary)
                }
            }
            
            if let dist = vm.distribution {
                HStack {
                    Text("Std Deviation:")
                    Spacer()
                    Text(String(format: "%.2f", dist.standardDeviation))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                // Percentile row
                Divider()
                
                VStack(spacing: 6) {
                    Text("Percentiles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 0) {
                        PercentileBox(label: "p10", value: dist.p10)
                        PercentileBox(label: "p25", value: dist.p25)
                        PercentileBox(label: "p50", value: dist.median)
                        PercentileBox(label: "p75", value: dist.p75)
                        PercentileBox(label: "p90", value: dist.p90)
                    }
                }
            }
            
            if vm.condition != .none {
                Divider()
                HStack {
                    Text("Est. Probability:")
                    Spacer()
                    if vm.isCalculating && vm.estimatedProbability == nil {
                        ProgressView().scaleEffect(0.8)
                    } else if let prob = vm.estimatedProbability {
                        Text("\(String(format: "%.1f", prob * 100))%")
                            .fontWeight(.bold)
                    } else {
                        Text("N/A").foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(resultColor.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(resultColor, lineWidth: vm.hasRolled && vm.condition != .none ? 3 : 0)
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var resultColor: Color {
        guard let isSuccess = vm.isSuccess else { return Color(UIColor.systemBackground) }
        return isSuccess ? .green : .red
    }
}

// MARK: - Percentile Box

private struct PercentileBox: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.caption)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}
