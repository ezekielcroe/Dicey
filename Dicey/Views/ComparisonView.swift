//
//  ComparisonView.swift
//  Dicey
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct ComparisonView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if vm.comparisonSnapshots.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            overlayChart
                            statsTable
                            snapshotList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !vm.comparisonSnapshots.isEmpty {
                        Button("Clear All") {
                            withAnimation { vm.clearSnapshots() }
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Configurations Saved")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Set up a dice pool on the main screen, then tap \"Add to Comparison\" to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Overlay Chart
    
    private var overlayChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distribution Overlay")
                .font(.headline)
            
            Chart {
                ForEach(vm.comparisonSnapshots) { snapshot in
                    let bins = snapshot.distribution.sortedBins
                    ForEach(bins, id: \.value) { bin in
                        LineMark(
                            x: .value("Sum", bin.value),
                            y: .value("Probability %", bin.probability),
                            series: .value("Config", snapshot.name)
                        )
                        .foregroundStyle(snapshot.color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    
                    // Shade under curve
                    ForEach(bins, id: \.value) { bin in
                        AreaMark(
                            x: .value("Sum", bin.value),
                            y: .value("Probability %", bin.probability),
                            series: .value("Config", snapshot.name)
                        )
                        .foregroundStyle(snapshot.color.opacity(0.12))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxisLabel("Sum", alignment: .center)
            .chartYAxisLabel("Probability %", alignment: .center)
            .frame(height: 250)
            
            // Legend
            legendView
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(vm.comparisonSnapshots) { snapshot in
                HStack(spacing: 6) {
                    Circle()
                        .fill(snapshot.color)
                        .frame(width: 8, height: 8)
                    Text(snapshot.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("— \(snapshot.configDescription)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Stats Comparison Table
    
    private var statsTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)
            
            // Header
            HStack {
                Text("Config")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Mean")
                    .frame(width: 50)
                Text("σ")
                    .frame(width: 45)
                Text("Med")
                    .frame(width: 40)
                Text("Range")
                    .frame(width: 70)
            }
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
            
            Divider()
            
            ForEach(vm.comparisonSnapshots) { snapshot in
                let d = snapshot.distribution
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(snapshot.color)
                            .frame(width: 6, height: 6)
                        Text(snapshot.name)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(String(format: "%.1f", d.mean))
                        .frame(width: 50)
                    Text(String(format: "%.1f", d.standardDeviation))
                        .frame(width: 45)
                    Text(String(format: "%.0f", d.median))
                        .frame(width: 40)
                    Text("\(d.minimum)–\(d.maximum)")
                        .frame(width: 70)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Snapshot List (with delete)
    
    private var snapshotList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Configurations")
                .font(.headline)
            
            ForEach(vm.comparisonSnapshots) { snapshot in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(snapshot.color)
                                .frame(width: 8, height: 8)
                            Text(snapshot.name)
                                .fontWeight(.medium)
                        }
                        Text(snapshot.configDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Mechanics tags
                        HStack(spacing: 4) {
                            if snapshot.exploding {
                                MechanicTag(text: "Exploding", color: .orange)
                            }
                            if snapshot.rerollBehavior != .none {
                                MechanicTag(
                                    text: snapshot.rerollBehavior == .rerollOnes
                                        ? "Reroll 1s"
                                        : "Reroll ≤\(snapshot.rerollThreshold)",
                                    color: .purple
                                )
                            }
                            if snapshot.keepOption != .none {
                                MechanicTag(
                                    text: snapshot.keepOption == .highest
                                        ? "KH\(snapshot.keepAmount)"
                                        : "KL\(snapshot.keepAmount)",
                                    color: .teal
                                )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation { vm.removeSnapshot(id: snapshot.id) }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 6)
                
                if snapshot.id != vm.comparisonSnapshots.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Mechanic Tag Pill

struct MechanicTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}
