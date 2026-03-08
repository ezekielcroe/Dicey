//
//  HistoryView.swift
//  Dicey
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: DicePoolViewModel

    var body: some View {
        Group {
            if vm.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Roll History Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(vm.history) { entry in
                        HistoryRow(entry: entry)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") { withAnimation { vm.clearHistory() } }
                    .foregroundColor(.red)
                    .disabled(vm.history.isEmpty)
            }
        }
    }
}
