//
//  ControlsSection.swift
//  Dicey
//
//  Accordion-style controls with segmented picker.
//

import SwiftUI

enum ControlTab: String, CaseIterable {
    case mechanics = "Mechanics"
    case keepDrop = "Keep/Drop"
    case condition = "Target"
}

struct ControlsSection: View {
    @ObservedObject var vm: DicePoolViewModel
    @State private var activeTab: ControlTab = .mechanics

    var body: some View {
        CardContainer {
            VStack(spacing: 12) {
                // Segmented Picker
                Picker("Controls", selection: $activeTab) {
                    ForEach(ControlTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                // Active section
                switch activeTab {
                case .mechanics:
                    MechanicsControls(vm: vm)
                case .keepDrop:
                    KeepDropControls(vm: vm)
                case .condition:
                    ConditionControls(vm: vm)
                }
            }
        }
    }
}

// MARK: - Mechanics Controls

struct MechanicsControls: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionLabel(text: "Dice Mechanics", systemImage: "gearshape.2")

            Toggle(isOn: $vm.config.exploding) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Exploding Dice")
                }
            }

            HStack {
                Text("Reroll:")
                Spacer()
                Picker("Reroll", selection: $vm.config.rerollBehavior) {
                    ForEach(RerollBehavior.allCases, id: \.self) { behavior in
                        Text(behavior.rawValue).tag(behavior)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            if vm.config.rerollBehavior == .rerollBelow {
                Stepper(value: $vm.config.rerollThreshold, in: 2...20) {
                    HStack {
                        Text("Reroll if ≤")
                        Spacer()
                        Text("\(vm.config.rerollThreshold)")
                            .fontWeight(.bold)
                    }
                }
            }

            Divider()

            // Modifier (always visible since it's commonly used)
            Stepper(value: $vm.config.modifier, in: -100...100) {
                HStack {
                    Text("Modifier:")
                    Spacer()
                    Text("\(vm.config.modifier > 0 ? "+" : "")\(vm.config.modifier)")
                        .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Keep / Drop Controls

struct KeepDropControls: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionLabel(text: "Keep / Drop", systemImage: "arrow.up.arrow.down")

            HStack {
                Text("Keep Option:")
                Picker("Keep Option", selection: $vm.config.keepOption) {
                    ForEach(KeepOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            if vm.config.keepOption != .none {
                let maxKeep = vm.config.dice.isEmpty ? 1 : vm.config.dice.count
                Stepper(value: $vm.config.keepAmount, in: 1...max(1, maxKeep)) {
                    HStack {
                        Text("Amount to Keep:")
                        Spacer()
                        Text("\(vm.config.keepAmount)")
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}

// MARK: - Condition Controls

struct ConditionControls: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionLabel(text: "Success Condition", systemImage: "checkmark.circle")

            HStack {
                Text("Condition:")
                Picker("Condition", selection: $vm.config.condition) {
                    ForEach(SuccessCondition.allCases, id: \.self) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            if vm.config.condition == .countSpecificFace {
                Stepper(value: $vm.config.targetFaceValue, in: 1...100) {
                    HStack {
                        Text("Target Face Value:")
                        Spacer()
                        Text("\(vm.config.targetFaceValue)")
                            .fontWeight(.bold)
                    }
                }
            }

            if vm.config.condition != .none {
                Stepper(value: $vm.config.targetNumber, in: 0...1000) {
                    HStack {
                        Text("Target Goal:")
                        Spacer()
                        Text("\(vm.config.targetNumber)")
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}
