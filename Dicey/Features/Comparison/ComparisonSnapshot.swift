//
//  ComparisonSnapshot.swift
//  Dicey
//

import SwiftUI

struct ComparisonSnapshot: Identifiable {
    let id: UUID
    let name: String
    let config: DiceConfiguration
    let distribution: DistributionData
    let colorIndex: Int

    static let palette: [Color] = [
        .blue, .red, .green, .orange, .purple, .pink, .cyan, .yellow
    ]

    var color: Color {
        Self.palette[colorIndex % Self.palette.count]
    }

    /// Probability of meeting the success condition (sum-based only)
    var successProbability: Double? {
        guard config.condition != .none else { return nil }

        var successes = 0
        for (value, count) in distribution.frequencies {
            let passes: Bool
            switch config.condition {
            case .none:              passes = false
            case .meetOrAbove:       passes = value >= config.targetNumber
            case .meetOrBelow:       passes = value <= config.targetNumber
            case .above:             passes = value > config.targetNumber
            case .below:             passes = value < config.targetNumber
            case .countSpecificFace: passes = false
            }
            if passes { successes += count }
        }
        return Double(successes) / Double(distribution.totalIterations)
    }
}
