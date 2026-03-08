//
//  MonteCarloEngine.swift
//  Dicey
//
//  Async Monte Carlo simulation engine. Runs off the main thread.
//

import Foundation

enum MonteCarloEngine {

    static let defaultIterations = 20_000

    // MARK: - Single Pool Simulation

    struct SingleResult {
        let average: Double
        let probability: Double?
        let distribution: DistributionData
    }

    /// Simulates a single dice configuration and returns distribution + stats.
    static func simulate(config: DiceConfiguration, iterations: Int = defaultIterations) async -> SingleResult? {
        guard !config.dice.isEmpty else { return nil }

        var pool = config.blankPool
        var totalSum = 0
        var successes = 0
        var frequencyMap: [Int: Int] = [:]

        for _ in 0..<iterations {
            if Task.isCancelled { return nil }

            RollEngine.execute(pool: &pool, config: config)

            let iterSum = RollEngine.sum(of: pool, modifier: config.modifier)
            let iterFace = RollEngine.faceCount(in: pool, targetFace: config.targetFaceValue)

            totalSum += iterSum
            frequencyMap[iterSum, default: 0] += 1

            if config.condition != .none {
                if RollEngine.checkSuccess(sum: iterSum, faceCount: iterFace, config: config) {
                    successes += 1
                }
            }
        }

        let avg = Double(totalSum) / Double(iterations)
        let prob = config.condition == .none ? nil : Double(successes) / Double(iterations)
        let dist = DistributionData.from(frequencies: frequencyMap, totalIterations: iterations)

        return SingleResult(average: avg, probability: prob, distribution: dist)
    }

    // MARK: - Opposed Roll Simulation

    struct OpposedResult {
        let poolAWinRate: Double
        let poolBWinRate: Double
        let drawRate: Double
        let marginDistribution: DistributionData   // sum_A - sum_B
        let poolADistribution: DistributionData
        let poolBDistribution: DistributionData
        let iterations: Int
    }

    /// Simulates two configurations head-to-head.
    static func simulateOpposed(
        configA: DiceConfiguration,
        configB: DiceConfiguration,
        iterations: Int = defaultIterations
    ) async -> OpposedResult? {
        guard !configA.dice.isEmpty, !configB.dice.isEmpty else { return nil }

        var poolA = configA.blankPool
        var poolB = configB.blankPool

        var aWins = 0
        var bWins = 0
        var draws = 0
        var marginMap: [Int: Int] = [:]
        var freqA: [Int: Int] = [:]
        var freqB: [Int: Int] = [:]

        for _ in 0..<iterations {
            if Task.isCancelled { return nil }

            RollEngine.execute(pool: &poolA, config: configA)
            RollEngine.execute(pool: &poolB, config: configB)

            let sumA = RollEngine.sum(of: poolA, modifier: configA.modifier)
            let sumB = RollEngine.sum(of: poolB, modifier: configB.modifier)
            let margin = sumA - sumB

            freqA[sumA, default: 0] += 1
            freqB[sumB, default: 0] += 1
            marginMap[margin, default: 0] += 1

            if sumA > sumB { aWins += 1 }
            else if sumB > sumA { bWins += 1 }
            else { draws += 1 }
        }

        let total = Double(iterations)
        return OpposedResult(
            poolAWinRate: Double(aWins) / total,
            poolBWinRate: Double(bWins) / total,
            drawRate: Double(draws) / total,
            marginDistribution: DistributionData.from(frequencies: marginMap, totalIterations: iterations),
            poolADistribution: DistributionData.from(frequencies: freqA, totalIterations: iterations),
            poolBDistribution: DistributionData.from(frequencies: freqB, totalIterations: iterations),
            iterations: iterations
        )
    }
}
