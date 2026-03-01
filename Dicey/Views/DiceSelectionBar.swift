//
//  DiceSelectionBar.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

struct DiceSelectionBar: View {
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(vm.availableDice, id: \.self) { sides in
                    Button(action: {
                        withAnimation { vm.addDie(sides: sides) }
                    }) {
                        ZStack {
                            dieShape(sides: sides)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 55, height: 55)
                            Text("d\(sides)")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .offset(y: sides == 4 ? 6 : 0)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
    }
}
