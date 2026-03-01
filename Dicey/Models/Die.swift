//
//  Die.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import Foundation

// MARK: - Protocols

/// Helper protocol to create clean copies for simulation
protocol Cloneable {
    func clone() -> Self
}

// MARK: - Enums

enum KeepOption: String, CaseIterable {
    case none = "Keep All"
    case lowest = "Keep Lowest"
    case highest = "Keep Highest"
}

enum SuccessCondition: String, CaseIterable {
    case none = "No Condition"
    case meetOrAbove = "Sum meets/over target"
    case meetOrBelow = "Sum meets/below target"
    case above = "Sum over Target"
    case below = "Sum below Target"
    case countSpecificFace = "Rolls of Target Face"
}

enum RerollBehavior: String, CaseIterable {
    case none = "No Reroll"
    case rerollOnes = "Reroll 1s (once)"
    case rerollBelow = "Reroll ≤ N (once)"
}

// MARK: - Die Model

struct Die: Identifiable, Cloneable {
    let id: UUID
    let sides: Int
    var value: Int? = nil
    var isDropped: Bool = false
    
    init(sides: Int, id: UUID = UUID(), value: Int? = nil, isDropped: Bool = false) {
        self.sides = sides
        self.id = id
        self.value = value
        self.isDropped = isDropped
    }
    
    /// Creates a clean copy for simulation (no rolled value, not dropped)
    func clone() -> Die {
        return Die(sides: self.sides)
    }
    
    /// Whether this die exploded (rolled value exceeds its maximum face)
    var hasExploded: Bool {
        guard let value = value else { return false }
        return value > sides
    }
}
