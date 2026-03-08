//
//  ComparisonView.swift
//  Dicey
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct ComparisonView: View {
    @ObservedObject var comparisonVM: ComparisonViewModel

    var body: some View {
        Group {
            if comparisonVM.snapshots.isEmpty {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                if !comparisonVM.snapshots.isEmpty {
                    Button("Clear All") {
                        withAnimation { comparisonVM.clearAll() }
                    }
                    .foregroundColor(.red)
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
            Text("Set up a dice pool in the Sandbox tab, then tap \"Add to Comparison\" to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Overlay Chart

    private var overlayChart: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Distribution Overlay")
                    .font(.headline)

                Chart {
                    ForEach(comparisonVM.snapshots) { snapshot in
                        let bins = snapshot.distribution.sortedBins
                        ForEach(bins, id: \.value) { bin in
                            LineMark(
                                x: .value("Sum", bin.value),
                                y: .value("Probability %", bin.probability),
                                series: .value("Config", snapshot.name)
                            )
                            .foregroundStyle(snapshot.color)
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }

                        ForEach(bins, id: \.value) { bin in
                            AreaMark(
                                x: .value("Sum", bin.value),
                                y: .value("Probability %", bin.probability),
                                series: .value("Config", snapshot.name)
                            )
                            .foregroundStyle(snapshot.color.opacity(0.12))
                            .interpolationMethod(.monotone)
                        }
                    }
                }
                .chartXAxisLabel("Sum", alignment: .center)
                .chartYAxisLabel("Probability %", alignment: .center)
                .frame(height: 250)

                // Legend
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(comparisonVM.snapshots) { snapshot in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(snapshot.color)
                                .frame(width: 8, height: 8)
                            Text(snapshot.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("— \(snapshot.config.notation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats Table

    private var statsTable: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)

                HStack {
                    Text("Config")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Mean").frame(width: 50)
                    Text("σ").frame(width: 45)
                    Text("Med").frame(width: 40)
                    Text("Range").frame(width: 70)
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

                Divider()

                ForEach(comparisonVM.snapshots) { snapshot in
                    let d = snapshot.distribution
                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(snapshot.color).frame(width: 6, height: 6)
                            Text(snapshot.name).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1f", d.mean)).frame(width: 50)
                        Text(String(format: "%.1f", d.standardDeviation)).frame(width: 45)
                        Text(String(format: "%.0f", d.median)).frame(width: 40)
                        Text("\(d.minimum)–\(d.maximum)").frame(width: 70)
                    }
                    .font(.caption)
                }
            }
        }
    }

    // MARK: - Snapshot List

    private var snapshotList: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Saved Configurations")
                    .font(.headline)

                ForEach(comparisonVM.snapshots) { snapshot in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Circle().fill(snapshot.color).frame(width: 8, height: 8)
                                Text(snapshot.name).fontWeight(.medium)
                            }
                            Text(snapshot.config.notation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            MechanicsTagsRow(config: snapshot.config)
                        }

                        Spacer()

                        Button(action: {
                            withAnimation { comparisonVM.removeSnapshot(id: snapshot.id) }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 6)

                    if snapshot.id != comparisonVM.snapshots.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
