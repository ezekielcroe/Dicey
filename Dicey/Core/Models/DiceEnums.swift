//
//  DiceEnums.swift
//  Dicey
//

import Foundation

// MARK: - Keep / Drop

enum KeepOption: String, CaseIterable, Codable, Equatable {
    case none = "Keep All"
    case lowest = "Keep Lowest"
    case highest = "Keep Highest"
}

// MARK: - Success Condition

enum SuccessCondition: String, CaseIterable, Codable, Equatable {
    case none = "No Condition"
    case meetOrAbove = "Sum ≥ Target"
    case meetOrBelow = "Sum ≤ Target"
    case above = "Sum > Target"
    case below = "Sum < Target"
    case countSpecificFace = "Count Target Face"
}

// MARK: - Reroll Behavior

enum RerollBehavior: String, CaseIterable, Codable, Equatable {
    case none = "No Reroll"
    case rerollOnes = "Reroll 1s (once)"
    case rerollBelow = "Reroll ≤ N (once)"
}
