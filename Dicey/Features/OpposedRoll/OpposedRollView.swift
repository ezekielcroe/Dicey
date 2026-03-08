//
//  OpposedRollView.swift
//  Dicey
//
//  Head-to-head contest builder.
//

import SwiftUI
import Charts

struct OpposedRollView: View {
    @ObservedObject var vm: OpposedRollViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Shared dice selection bar
                diceBar

                // Two pools side by side
                HStack(alignment: .top, spacing: 12) {
                    poolColumn(pool: .a, config: $vm.configA, label: $vm.labelA, color: .blue)
                    
                    Text("vs.")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.secondary)
                        .padding(.top, 30)

                    poolColumn(pool: .b, config: $vm.configB, label: $vm.labelB, color: .red)
                }

                Divider()

                // Results
                if vm.isCalculating {
                    ProgressView("Simulating contest...")
                        .padding()
                } else if let result = vm.result {
                    ContestResultView(result: result, labelA: vm.labelA, labelB: vm.labelB)
                } else {
                    Text("Add dice to both pools to see contest results.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Opposed Roll")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Dice Bar

    private var diceBar: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tap a die, then tap a pool to add it")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.availableDice, id: \.self) { sides in
                            Menu {
                                Button("Add to \(vm.labelA)") {
                                    withAnimation { vm.addDie(to: .a, sides: sides) }
                                }
                                Button("Add to \(vm.labelB)") {
                                    withAnimation { vm.addDie(to: .b, sides: sides) }
                                }
                            } label: {
                                ZStack {
                                    dieShape(sides: sides)
                                        .fill(Color.purple.opacity(0.15))
                                        .frame(width: 46, height: 46)
                                    Text("d\(sides)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.purple)
                                        .offset(y: sides == 4 ? 5 : 0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pool Column

    private func poolColumn(
        pool: OpposedRollViewModel.Pool,
        config: Binding<DiceConfiguration>,
        label: Binding<String>,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            // Editable label
            TextField("Name", text: label)
                .font(.headline)
                .foregroundColor(color)
                .multilineTextAlignment(.center)

            // Notation
            if !config.wrappedValue.dice.isEmpty {
                Text(config.wrappedValue.notation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Dice chips
            if config.wrappedValue.dice.isEmpty {
                Text("Empty")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 4) {
                    ForEach(Array(config.wrappedValue.dice.enumerated()), id: \.element.id) { index, die in
                        ZStack {
                            dieShape(sides: die.sides)
                                .fill(color.opacity(0.2))
                                .frame(width: 38, height: 38)
                            Text("d\(die.sides)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(color)
                                .offset(y: die.sides == 4 ? 4 : 0)
                        }
                        .onTapGesture {
                            withAnimation { vm.removeDie(from: pool, at: index) }
                        }
                    }
                }
            }

            // Modifier
            Stepper(value: config.modifier, in: -50...50) {
                Text("\(config.wrappedValue.modifier > 0 ? "+" : "")\(config.wrappedValue.modifier)")
                    .font(.caption)
                    .fontWeight(.bold)
            }

            // Exploding toggle
            Toggle(isOn: config.exploding) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            .toggleStyle(.switch)
            .scaleEffect(0.8)

            // Clear
            Button("Clear") { withAnimation { vm.clearPool(pool) } }
                .font(.caption)
                .foregroundColor(.red)
                .disabled(config.wrappedValue.dice.isEmpty)
        }
        .padding(10)
        .background(color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Contest Result View

struct ContestResultView: View {
    let result: MonteCarloEngine.OpposedResult
    let labelA: String
    let labelB: String

    var body: some View {
        VStack(spacing: 16) {
            // Win rate bar
            winRateBar

            // Stats cards
            HStack(spacing: 12) {
                statCard(label: labelA, dist: result.poolADistribution, color: .blue)
                statCard(label: labelB, dist: result.poolBDistribution, color: .red)
            }

            // Margin distribution chart
            if #available(iOS 16.0, *) {
                marginChart
            }
        }
    }

    // MARK: - Win Rate Bar

    private var winRateBar: some View {
        CardContainer {
            VStack(spacing: 10) {
                Text("Win Rates")
                    .font(.headline)

                // Stacked horizontal bar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * result.poolAWinRate)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geo.size.width * result.drawRate)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geo.size.width * result.poolBWinRate)
                    }
                    .cornerRadius(6)
                }
                .frame(height: 28)

                // Labels
                HStack {
                    VStack(alignment: .leading) {
                        Text(labelA)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("\(String(format: "%.1f", result.poolAWinRate * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack {
                        Text("Draw")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", result.drawRate * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(labelB)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("\(String(format: "%.1f", result.poolBWinRate * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }

    // MARK: - Stat Card

    private func statCard(label: String, dist: DistributionData, color: Color) -> some View {
        CardContainer {
            VStack(spacing: 6) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mean").font(.system(size: 9)).foregroundColor(.secondary)
                        Text(String(format: "%.1f", dist.mean))
                            .font(.caption).fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Range").font(.system(size: 9)).foregroundColor(.secondary)
                        Text("\(dist.minimum)–\(dist.maximum)")
                            .font(.caption).fontWeight(.bold)
                    }
                }
            }
        }
    }

    // MARK: - Margin Chart

    @available(iOS 16.0, *)
    private var marginChart: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Victory Margin")
                    .font(.headline)
                Text("Positive = \(labelA) wins by that much")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Chart {
                    ForEach(result.marginDistribution.sortedBins, id: \.value) { bin in
                        BarMark(
                            x: .value("Margin", bin.value),
                            y: .value("Probability %", bin.probability)
                        )
                        .foregroundStyle(bin.value > 0 ? Color.blue.opacity(0.7) : (bin.value < 0 ? Color.red.opacity(0.7) : Color.gray.opacity(0.5)))
                        .cornerRadius(1)
                    }

                    // Zero line
                    RuleMark(x: .value("Zero", 0))
                        .foregroundStyle(.primary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
                .chartXAxisLabel("Margin (\(labelA) − \(labelB))", alignment: .center)
                .chartYAxisLabel("Probability %", alignment: .center)
                .frame(height: 180)
            }
        }
    }
}
