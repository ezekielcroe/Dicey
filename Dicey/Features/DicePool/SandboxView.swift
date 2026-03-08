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

                        // Add to Comparison
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
                }
                .padding()
            }

            // Statistics Footer
            StatisticsFooter(vm: vm)

            // Roll Button
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
            .padding(.horizontal)
            .padding(.bottom)
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
