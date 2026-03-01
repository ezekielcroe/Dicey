//
//  ComparisonSnapshot.swift
//  Dicey
//

import SwiftUI

struct ComparisonSnapshot: Identifiable {
    let id: UUID
    let name: String
    let configDescription: String
    let distribution: DistributionData
    let colorIndex: Int
    
    // Mechanics info for display
    let exploding: Bool
    let rerollBehavior: RerollBehavior
    let rerollThreshold: Int
    let keepOption: KeepOption
    let keepAmount: Int
    let modifier: Int
    let condition: SuccessCondition
    let targetNumber: Int
    let targetFaceValue: Int
    
    static let palette: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .cyan, .yellow
    ]
    
    var color: Color {
        Self.palette[colorIndex % Self.palette.count]
    }
    
    /// Probability of meeting the success condition (if one is set)
    var successProbability: Double? {
        guard condition != .none else { return nil }
        
        var successes = 0
        for (value, count) in distribution.frequencies {
            let passes: Bool
            switch condition {
            case .none: passes = false
            case .meetOrAbove: passes = value >= targetNumber
            case .meetOrBelow: passes = value <= targetNumber
            case .above: passes = value > targetNumber
            case .below: passes = value < targetNumber
            case .countSpecificFace: passes = false // Can't derive from sum distribution
            }
            if passes { successes += count }
        }
        return Double(successes) / Double(distribution.totalIterations)
    }
}
