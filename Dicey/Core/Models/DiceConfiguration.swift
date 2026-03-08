//
//  DiceConfiguration.swift
//  Dicey
//

import Foundation

/// Bundles all parameters for a dice roll configuration.
/// Used by RollEngine, MonteCarloEngine, snapshots, and history entries.
struct DiceConfiguration: Equatable {
    var dice: [Die] = []
    var modifier: Int = 0
    var keepOption: KeepOption = .none
    var keepAmount: Int = 1
    var exploding: Bool = false
    var rerollBehavior: RerollBehavior = .none
    var rerollThreshold: Int = 2
    var condition: SuccessCondition = .none
    var targetNumber: Int = 10
    var targetFaceValue: Int = 1

    // MARK: - Computed

    var activeDice: [Die] { dice.filter { !$0.isDropped } }

    var currentSum: Int {
        activeDice.compactMap(\.value).reduce(0, +) + modifier
    }

    var specificFaceCount: Int {
        activeDice.filter { $0.value == targetFaceValue }.count
    }

    /// Dice pool with values cleared and drops reset — ready for simulation
    var blankPool: [Die] {
        dice.map { $0.blank() }
    }

    /// Standard dice notation string, e.g. "2d6 + 1d8 +3 [KH1] [!]"
    var notation: String {
        guard !dice.isEmpty else { return "Empty" }

        var groups: [Int: Int] = [:]
        for die in dice { groups[die.sides, default: 0] += 1 }

        let diceStr = groups.keys.sorted().map { sides in
            "\(groups[sides]!)d\(sides)"
        }.joined(separator: " + ")

        var parts = [diceStr]

        if modifier > 0 { parts.append("+\(modifier)") }
        else if modifier < 0 { parts.append("\(modifier)") }

        if keepOption == .highest { parts.append("[KH\(keepAmount)]") }
        else if keepOption == .lowest { parts.append("[KL\(keepAmount)]") }

        if exploding { parts.append("[!]") }

        switch rerollBehavior {
        case .none: break
        case .rerollOnes: parts.append("[R1]")
        case .rerollBelow: parts.append("[R≤\(rerollThreshold)]")
        }

        return parts.joined(separator: " ")
    }

    static func == (lhs: DiceConfiguration, rhs: DiceConfiguration) -> Bool {
        lhs.dice.map(\.sides) == rhs.dice.map(\.sides)
            && lhs.modifier == rhs.modifier
            && lhs.keepOption == rhs.keepOption
            && lhs.keepAmount == rhs.keepAmount
            && lhs.exploding == rhs.exploding
            && lhs.rerollBehavior == rhs.rerollBehavior
            && lhs.rerollThreshold == rhs.rerollThreshold
            && lhs.condition == rhs.condition
            && lhs.targetNumber == rhs.targetNumber
            && lhs.targetFaceValue == rhs.targetFaceValue
    }
}
