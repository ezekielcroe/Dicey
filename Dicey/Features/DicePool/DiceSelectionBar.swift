//
//  DiceSelectionBar.swift
//  Dicey
//

import SwiftUI

struct DiceSelectionBar: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.availableDice, id: \.self) { sides in
                    Button(action: {
                        withAnimation { vm.addDie(sides: sides) }
                    }) {
                        ZStack {
                            dieShape(sides: sides)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Text("d\(sides)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                                .offset(y: sides == 4 ? 6 : 0)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
    }
}
