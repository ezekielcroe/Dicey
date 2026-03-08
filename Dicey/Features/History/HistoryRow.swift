//
//  HistoryRow.swift
//  Dicey
//

import SwiftUI

struct HistoryRow: View {
    let entry: RollHistoryEntry

    private var fullDetailString: AttributedString {
        let diceDetails = entry.rolledDice.map { die in
            let valStr = die.value.map { String($0) } ?? "?"
            let explodeMarker = die.hasExploded ? "!" : ""
            return die.isDropped
                ? "~~d\(die.sides)(\(valStr)\(explodeMarker))~~"
                : "d\(die.sides)(\(valStr)\(explodeMarker))"
        }.joined(separator: ", ")

        let modStr = entry.config.modifier != 0
            ? (entry.config.modifier > 0 ? " +\(entry.config.modifier)" : " \(entry.config.modifier)")
            : ""
        let keepStr = entry.config.keepOption != .none
            ? " | \(entry.config.keepOption.rawValue) \(entry.config.keepAmount)"
            : ""
        let combined = diceDetails + modStr + keepStr

        return (try? AttributedString(markdown: combined)) ?? AttributedString(combined)
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

            MechanicsTagsRow(config: entry.config)

            if entry.config.condition != .none {
                HStack {
                    if entry.config.condition == .countSpecificFace {
                        Text("\(entry.config.condition.rawValue) (Face \(entry.config.targetFaceValue)) : \(entry.config.targetNumber)")
                    } else {
                        Text("\(entry.config.condition.rawValue) : \(entry.config.targetNumber)")
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
