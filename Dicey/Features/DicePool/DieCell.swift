//
//  DieCell.swift
//  Dicey
//

import SwiftUI

struct DieCell: View {
    let die: Die
    let explodingEnabled: Bool

    var body: some View {
        ZStack {
            dieShape(sides: die.sides)
                .fill(fillColor)
                .frame(width: 60, height: 60)

            VStack(spacing: 2) {
                Text("d\(die.sides)")
                    .font(.system(size: 11))
                    .foregroundColor(die.value != nil ? .white.opacity(0.7) : .secondary)
                Text(die.value != nil ? "\(die.value!)" : "-")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(die.value != nil ? .white : .primary)
            }
            .offset(y: die.sides == 4 ? 6 : 0)

            if die.hasExploded {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .offset(x: 22, y: -22)
            }

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
