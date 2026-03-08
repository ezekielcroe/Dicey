//
//  RollHistoryEntry.swift
//  Dicey
//

import Foundation

struct RollHistoryEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let config: DiceConfiguration
    let rolledDice: [Die]       // Dice with their rolled values
    let probability: Double?
    let isSuccess: Bool?

    var activeDice: [Die] { rolledDice.filter { !$0.isDropped } }

    var resultSummary: String {
        let sum = activeDice.compactMap(\.value).reduce(0, +) + config.modifier
        let faceCount = activeDice.filter { $0.value == config.targetFaceValue }.count

        switch config.condition {
        case .none, .meetOrAbove, .meetOrBelow, .above, .below:
            return "Total: \(sum)"
        case .countSpecificFace:
            return "Face \(config.targetFaceValue) Rolled: \(faceCount)"
        }
    }
}
