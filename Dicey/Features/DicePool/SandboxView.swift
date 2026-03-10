//
//  SandboxView.swift
//  Dicey
//
//  The main dice rolling workspace — pool, controls, chart, roll button.
//

import SwiftUI

struct SandboxView: View {
    @ObservedObject var vm: DicePoolViewModel
    @ObservedObject var comparisonVM: ComparisonViewModel
    @State private var showingSnapshotAlert = false
    @State private var snapshotName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Dice Selection Bar
            DiceSelectionBar(vm: vm)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    // Dice Pool Display
                    DicePoolGrid(vm: vm)

                    // Controls (accordion)
                    ControlsSection(vm: vm)

                    // Distribution Chart
                    if let dist = vm.distribution {
                        if #available(iOS 16.0, *) {
                            DistributionChartView(
                                distribution: dist,
                                targetNumber: vm.config.condition != .none ? vm.config.targetNumber : nil,
                                condition: vm.config.condition
                            )
                        } else {
                            DistributionChartFallback(distribution: dist)
                        }
                    }

                    // Inline Statistics (replaces the old pinned footer card)
                    InlineStatisticsSection(vm: vm)

                    // Add to Comparison
                    if vm.distribution != nil {
                        Button(action: {
                            snapshotName = vm.config.notation
                            showingSnapshotAlert = true
                        }) {
                            HStack {
                                Image(systemName: "plus.square.on.square")
                                Text("Add to Comparison")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 4)
                    }

                    // Roll Button (now scrollable, no longer pinned)
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                        vm.rollDice()
                    }) {
                        Text(rollButtonText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(vm.config.dice.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .disabled(vm.config.dice.isEmpty)
                    .padding(.top, 4)
                }
                .padding()
            }
        }
        .alert("Save to Comparison", isPresented: $showingSnapshotAlert) {
            TextField("Configuration name", text: $snapshotName)
            Button("Save") {
                let name = snapshotName.trimmingCharacters(in: .whitespaces)
                if let dist = vm.distribution {
                    comparisonVM.saveSnapshot(
                        name: name.isEmpty ? vm.config.notation : name,
                        config: vm.config,
                        distribution: dist
                    )
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this configuration a name for the comparison chart.")
        }
    }

    private var rollButtonText: String {
        guard let isSuccess = vm.isSuccess else { return "Roll Dice" }
        return isSuccess ? "SUCCESS!" : "FAILED"
    }
}

// MARK: - Inline Statistics Section

/// Replaces the old StatisticsFooter that was pinned at the bottom.
/// Now lives inside the ScrollView as part of the natural content flow.
struct InlineStatisticsSection: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        if vm.config.dice.isEmpty && vm.estimatedAverage == nil {
            EmptyView()
        } else {
            VStack(spacing: 10) {
                // Average
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

                if vm.config.condition != .none {
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

                // Roll Result (appears after rolling)
                if vm.hasRolled && !vm.config.dice.isEmpty {
                    Divider()

                    HStack {
                        Text("Roll Result:")
                        Spacer()
                        Text("\(vm.currentSum)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    if vm.config.condition == .countSpecificFace {
                        HStack {
                            Text("Face \(vm.config.targetFaceValue) Count:")
                            Spacer()
                            Text("\(vm.specificFaceCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }

                    if let isSuccess = vm.isSuccess {
                        HStack {
                            Spacer()
                            Text(isSuccess ? "SUCCESS" : "FAILED")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(isSuccess ? .green : .red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background((isSuccess ? Color.green : Color.red).opacity(0.15))
                                .cornerRadius(6)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(resultColor.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(resultColor, lineWidth: vm.hasRolled && vm.config.condition != .none ? 3 : 0)
            )
            .cornerRadius(12)
        }
    }

    private var resultColor: Color {
        guard let isSuccess = vm.isSuccess else { return Color(UIColor.systemBackground) }
        return isSuccess ? .green : .red
    }
}
