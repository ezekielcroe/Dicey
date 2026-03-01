//
//  RollHistoryEntry.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import Foundation

struct RollHistoryEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let dicePool: [Die]
    let modifier: Int
    let keepOption: KeepOption
    let keepAmount: Int
    let condition: SuccessCondition
    let targetFaceValue: Int
    let targetNumber: Int
    let probability: Double?
    let isSuccess: Bool?
    let exploding: Bool
    let rerollBehavior: RerollBehavior
    let rerollThreshold: Int
    
    var activeDice: [Die] { dicePool.filter { !$0.isDropped } }
    
    var resultSummary: String {
        let sum = activeDice.compactMap({ $0.value }).reduce(0, +) + modifier
        let faceCount = activeDice.filter({ $0.value == targetFaceValue }).count
        
        switch condition {
        case .none, .meetOrAbove, .meetOrBelow, .above, .below:
            return "Total: \(sum)"
        case .countSpecificFace:
            return "Face \(targetFaceValue) Rolled: \(faceCount)"
        }
    }
    
    /// Short description of active mechanics for display
    var mechanicsTags: [String] {
        var tags: [String] = []
        if exploding { tags.append("Exploding") }
        switch rerollBehavior {
        case .none: break
        case .rerollOnes: tags.append("Reroll 1s")
        case .rerollBelow: tags.append("Reroll ≤\(rerollThreshold)")
        }
        return tags
    }
}
