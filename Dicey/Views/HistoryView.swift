//
//  HistoryView.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if vm.history.isEmpty {
                    VStack {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
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
            .navigationTitle("Roll History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { withAnimation { vm.clearHistory() } }
                        .foregroundColor(.red)
                        .disabled(vm.history.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let entry: RollHistoryEntry
    
    private var fullDetailString: AttributedString {
        let diceDetails = entry.dicePool.map { die in
            let valStr = die.value.map { String($0) } ?? "?"
            let explodeMarker = die.hasExploded ? "!" : ""
            return die.isDropped ? "~~d\(die.sides)(\(valStr)\(explodeMarker))~~" : "d\(die.sides)(\(valStr)\(explodeMarker))"
        }.joined(separator: ", ")
        
        let modifierString = entry.modifier != 0 ? (entry.modifier > 0 ? " +\(entry.modifier)" : " \(entry.modifier)") : ""
        let keepString = entry.keepOption != .none ? " | \(entry.keepOption.rawValue) \(entry.keepAmount)" : ""
        let combinedString = diceDetails + modifierString + keepString
        
        if let attributed = try? AttributedString(markdown: combinedString) {
            return attributed
        } else {
            return AttributedString(combinedString)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.resultSummary)
                    .font(.caption)
                    .fontWeight(.bold)
                
                if let success = entry.isSuccess {
                    Text(success ? "SUCCESS" : "FAIL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(success ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((success ? Color.green : Color.red).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text(fullDetailString)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Mechanics tags
            if !entry.mechanicsTags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.mechanicsTags, id: \.self) { tag in
                        MechanicTag(
                            text: tag,
                            color: tag.contains("Explod") ? .orange : .purple
                        )
                    }
                }
            }
            
            if entry.condition != .none {
                HStack {
                    if entry.condition == .countSpecificFace {
                        Text("\(entry.condition.rawValue) (Face \(entry.targetFaceValue)) : \(entry.targetNumber)")
                    } else {
                        Text("\(entry.condition.rawValue) : \(entry.targetNumber)")
                    }
                    
                    Spacer()
                    if let prob = entry.probability {
                        Text("~ \(String(format: "%.1f", prob * 100))% chance")
                    } else {
                        Text("--")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
