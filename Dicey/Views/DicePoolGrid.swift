//
//  DicePoolGrid.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

struct DicePoolGrid: View {
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Pool Header & Clear Button
            HStack {
                Text("Dice Pool")
                    .font(.headline)
                Spacer()
                if !vm.configDescription.isEmpty && vm.configDescription != "Empty" {
                    Text(vm.configDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Button("Clear") {
                    withAnimation { vm.clearPool() }
                }
                .foregroundColor(.red)
                .disabled(vm.dicePool.isEmpty)
            }
            
            // Dice Grid
            if vm.dicePool.isEmpty {
                Text("Tap a die above to add it to your pool.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                    ForEach(Array(vm.dicePool.enumerated()), id: \.element.id) { index, die in
                        DieCell(die: die, explodingEnabled: vm.exploding)
                            .onTapGesture {
                                withAnimation { vm.removeDie(at: index) }
                            }
                    }
                }
            }
            
            // Live Roll Results Box
            if vm.hasRolled && !vm.dicePool.isEmpty {
                VStack(spacing: 12) {
                    Text("Roll Results")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        StatBox(title: "Sum", value: "\(vm.currentSum)")
                        if vm.condition == .countSpecificFace {
                            Divider()
                            StatBox(title: "Face \(vm.targetFaceValue)s", value: "\(vm.specificFaceCount)")
                        }
                    }
                    .padding(.vertical, 5)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Individual Die Cell

private struct DieCell: View {
    let die: Die
    let explodingEnabled: Bool
    
    var body: some View {
        ZStack {
            dieShape(sides: die.sides)
                .fill(fillColor)
                .frame(width: 60, height: 60)
            
            VStack {
                Text("d\(die.sides)")
                    .font(.system(size: 11))
                    .foregroundColor(die.value != nil ? .white.opacity(0.7) : .secondary)
                Text(die.value != nil ? "\(die.value!)" : "-")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(die.value != nil ? .white : .primary)
            }
            .offset(y: die.sides == 4 ? 6 : 0)
            
            // Exploding indicator
            if die.hasExploded {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .offset(x: 22, y: -22)
            }
            
            // Dropped strikethrough
            if die.isDropped {
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 3)
                    .rotationEffect(.degrees(-45))
                    .opacity(0.8)
            }
        }
        .opacity(die.isDropped ? 0.4 : 1.0)
    }
    
    private var fillColor: Color {
        guard die.value != nil else { return Color.gray.opacity(0.3) }
        if die.hasExploded { return Color.orange }
        return Color.blue
    }
}
