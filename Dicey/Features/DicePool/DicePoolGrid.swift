//
//  DicePoolGrid.swift
//  Dicey
//

import SwiftUI

struct DicePoolGrid: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text("Dice Pool")
                    .font(.headline)
                Spacer()
                if !vm.config.notation.isEmpty && vm.config.notation != "Empty" {
                    Text(vm.config.notation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Button("Clear") {
                    withAnimation { vm.clearPool() }
                }
                .foregroundColor(.red)
                .disabled(vm.config.dice.isEmpty)
            }

            // Grid
            if vm.config.dice.isEmpty {
                Text("Tap a die above to add it to your pool.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                    ForEach(Array(vm.config.dice.enumerated()), id: \.element.id) { index, die in
                        DieCell(die: die, explodingEnabled: vm.config.exploding)
                            .onTapGesture {
                                withAnimation { vm.removeDie(at: index) }
                            }
                    }
                }
            }
        }
    }
}
