//
//  ControlsSection.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

struct ControlsSection: View {
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            
            // MARK: - Dice Mechanics
            
            SectionLabel(text: "Dice Mechanics", systemImage: "gearshape.2")
            
            // Exploding Dice Toggle
            Toggle(isOn: $vm.exploding) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Exploding Dice")
                }
            }
            
            // Reroll Behavior
            HStack {
                Text("Reroll:")
                Spacer()
                Picker("Reroll", selection: $vm.rerollBehavior) {
                    ForEach(RerollBehavior.allCases, id: \.self) { behavior in
                        Text(behavior.rawValue).tag(behavior)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            if vm.rerollBehavior == .rerollBelow {
                Stepper(value: $vm.rerollThreshold, in: 2...20) {
                    HStack {
                        Text("Reroll if ≤")
                        Spacer()
                        Text("\(vm.rerollThreshold)")
                            .fontWeight(.bold)
                    }
                }
            }
            
            Divider()
            
            // MARK: - Keep / Drop
            
            SectionLabel(text: "Keep / Drop", systemImage: "arrow.up.arrow.down")
            
            HStack {
                Text("Keep Option:")
                Picker("Keep Option", selection: $vm.keepOption) {
                    ForEach(KeepOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            if vm.keepOption != .none {
                let maxKeep = vm.dicePool.isEmpty ? 1 : vm.dicePool.count
                Stepper(value: $vm.keepAmount, in: 1...max(1, maxKeep)) {
                    HStack {
                        Text("Amount to Keep:")
                        Spacer()
                        Text("\(vm.keepAmount)")
                            .fontWeight(.bold)
                    }
                }
            }
            
            Divider()
            
            // MARK: - Modifier
            
            Stepper(value: $vm.modifier, in: -100...100) {
                HStack {
                    Text("Modifier:")
                    Spacer()
                    Text("\(vm.modifier > 0 ? "+" : "")\(vm.modifier)")
                        .fontWeight(.bold)
                }
            }
            
            Divider()
            
            // MARK: - Success Condition
            
            SectionLabel(text: "Success Condition", systemImage: "checkmark.circle")
            
            HStack {
                Text("Condition:")
                Picker("Condition", selection: $vm.condition) {
                    ForEach(SuccessCondition.allCases, id: \.self) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            if vm.condition == .countSpecificFace {
                Stepper(value: $vm.targetFaceValue, in: 1...100) {
                    HStack {
                        Text("Target Face Value:")
                        Spacer()
                        Text("\(vm.targetFaceValue)")
                            .fontWeight(.bold)
                    }
                }
            }
            
            if vm.condition != .none {
                Stepper(value: $vm.targetNumber, in: 0...1000) {
                    HStack {
                        Text("Target Goal:")
                        Spacer()
                        Text("\(vm.targetNumber)")
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Section Label Helper

private struct SectionLabel: View {
    let text: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
