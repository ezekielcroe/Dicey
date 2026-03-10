//
//  ReverseCalcView.swift
//  Dicey
//
//  "What DC should I set for X% success?"
//

import SwiftUI
import Charts

struct ReverseCalcView: View {
    @ObservedObject var vm: ReverseCalcViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Dice Selection
                diceSelectionBar

                // Pool display
                if !vm.config.dice.isEmpty {
                    poolSummary
                }

                // Modifier
                CardContainer {
                    Stepper(value: $vm.config.modifier, in: -100...100) {
                        HStack {
                            Text("Modifier:")
                            Spacer()
                            Text("\(vm.config.modifier > 0 ? "+" : "")\(vm.config.modifier)")
                                .fontWeight(.bold)
                        }
                    }
                }

                // Mechanics
                CardContainer {
                    VStack(spacing: 10) {
                        Toggle(isOn: $vm.config.exploding) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Exploding Dice")
                            }
                        }

                        HStack {
                            Text("Keep:")
                            Spacer()
                            Picker("Keep", selection: $vm.config.keepOption) {
                                ForEach(KeepOption.allCases, id: \.self) { opt in
                                    Text(opt.rawValue).tag(opt)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        if vm.config.keepOption != .none {
                            Stepper(value: $vm.config.keepAmount, in: 1...max(1, vm.config.dice.count)) {
                                HStack {
                                    Text("Keep Amount:")
                                    Spacer()
                                    Text("\(vm.config.keepAmount)").fontWeight(.bold)
                                }
                            }
                        }
                    }
                }

                Divider().padding(.horizontal)

                // Condition picker — now a dropdown instead of a segmented control
                CardContainer {
                    VStack(spacing: 12) {
                        SectionLabel(text: "Condition Type", systemImage: "questionmark.circle")

                        HStack {
                            Text("Condition:")
                            Spacer()
                            Picker("Condition", selection: $vm.reverseCondition) {
                                Text("Sum ≥ Target").tag(SuccessCondition.meetOrAbove)
                                Text("Sum ≤ Target").tag(SuccessCondition.meetOrBelow)
                                Text("Sum > Target").tag(SuccessCondition.above)
                                Text("Sum < Target").tag(SuccessCondition.below)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }

                // Desired probability slider
                CardContainer {
                    VStack(spacing: 12) {
                        SectionLabel(text: "Desired Success Rate", systemImage: "slider.horizontal.3")

                        HStack {
                            Text("0%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Slider(value: $vm.desiredProbability, in: 0.05...0.95, step: 0.05)
                                .accentColor(.blue)
                            Text("100%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Text("\(Int(vm.desiredProbability * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }

                // RESULT
                if vm.isCalculating {
                    ProgressView("Simulating...")
                        .padding()
                } else if let target = vm.suggestedTarget {
                    resultCard(target: target)
                } else if !vm.config.dice.isEmpty {
                    Text("Add dice and select a condition to see results.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }

                // Distribution chart
                if let dist = vm.distribution {
                    if #available(iOS 16.0, *) {
                        reverseChart(dist: dist)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Target Finder")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Dice Selection

    private var diceSelectionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.availableDice, id: \.self) { sides in
                    Button(action: { withAnimation { vm.addDie(sides: sides) } }) {
                        ZStack {
                            dieShape(sides: sides)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Text("d\(sides)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)
                                .offset(y: sides == 4 ? 5 : 0)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pool Summary

    private var poolSummary: some View {
        CardContainer {
            HStack {
                Text(vm.config.notation)
                    .font(.headline)
                Spacer()
                Button("Clear") { withAnimation { vm.clearPool() } }
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Result Card

    private func resultCard(target: Int) -> some View {
        CardContainer {
            VStack(spacing: 8) {
                Text("Set Target To")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(target)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.green)

                if let actual = vm.actualProbability {
                    Text("Actual success rate: \(String(format: "%.1f", actual * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("\(vm.reverseCondition.rawValue) \(target)")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Distribution with target highlight

    @available(iOS 16.0, *)
    private func reverseChart(dist: DistributionData) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Distribution")
                    .font(.headline)

                Chart {
                    ForEach(dist.sortedBins, id: \.value) { bin in
                        BarMark(
                            x: .value("Sum", bin.value),
                            y: .value("Probability %", bin.probability)
                        )
                        .foregroundStyle(reverseBarColor(for: bin.value))
                        .cornerRadius(1)
                    }

                    if let target = vm.suggestedTarget {
                        RuleMark(x: .value("Target", target))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [6, 3]))
                            .annotation(position: .top) {
                                Text("DC \(target)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            }
                    }
                }
                .chartXAxisLabel("Sum", alignment: .center)
                .chartYAxisLabel("Probability %", alignment: .center)
                .frame(height: 180)
            }
        }
    }

    private func reverseBarColor(for value: Int) -> Color {
        guard let target = vm.suggestedTarget else { return .blue }
        let passes: Bool
        switch vm.reverseCondition {
        case .meetOrAbove: passes = value >= target
        case .meetOrBelow: passes = value <= target
        case .above:       passes = value > target
        case .below:       passes = value < target
        default: return .blue
        }
        return passes ? .green.opacity(0.8) : .gray.opacity(0.35)
    }
}
