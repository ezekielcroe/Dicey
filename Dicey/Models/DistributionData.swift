//
//  DistributionData.swift
//  Dicey
//

import Foundation

struct DistributionData {
    let frequencies: [Int: Int]     // sum value -> occurrence count
    let totalIterations: Int
    let mean: Double
    let standardDeviation: Double
    let minimum: Int
    let maximum: Int
    let percentiles: [Double: Double]  // e.g. 0.10 -> 5.0, 0.50 -> 10.0

    /// Sorted bins for charting, with probability as percentage
    var sortedBins: [(value: Int, probability: Double)] {
        frequencies.keys.sorted().map { key in
            (value: key, probability: Double(frequencies[key]!) / Double(totalIterations) * 100.0)
        }
    }
    
    var p10: Double { percentiles[0.10] ?? Double(minimum) }
    var p25: Double { percentiles[0.25] ?? Double(minimum) }
    var median: Double { percentiles[0.50] ?? mean }
    var p75: Double { percentiles[0.75] ?? Double(maximum) }
    var p90: Double { percentiles[0.90] ?? Double(maximum) }
    
    // MARK: - Factory

    /// Builds DistributionData from a raw frequency map produced by Monte Carlo
    static func from(frequencies: [Int: Int], totalIterations: Int) -> DistributionData {
        guard !frequencies.isEmpty else {
            return DistributionData(
                frequencies: [:], totalIterations: 0, mean: 0, standardDeviation: 0,
                minimum: 0, maximum: 0, percentiles: [:]
            )
        }
        
        let minVal = frequencies.keys.min()!
        let maxVal = frequencies.keys.max()!
        
        // Mean
        var totalSum: Double = 0
        for (value, count) in frequencies {
            totalSum += Double(value) * Double(count)
        }
        let mean = totalSum / Double(totalIterations)
        
        // Standard deviation (population)
        var sumOfSquaredDiffs: Double = 0
        for (value, count) in frequencies {
            sumOfSquaredDiffs += pow(Double(value) - mean, 2) * Double(count)
        }
        let stdDev = sqrt(sumOfSquaredDiffs / Double(totalIterations))
        
        // Percentiles
        let percentiles = computePercentiles(from: frequencies, totalCount: totalIterations)
        
        return DistributionData(
            frequencies: frequencies,
            totalIterations: totalIterations,
            mean: mean,
            standardDeviation: stdDev,
            minimum: minVal,
            maximum: maxVal,
            percentiles: percentiles
        )
    }
    
    private static func computePercentiles(from frequencies: [Int: Int], totalCount: Int) -> [Double: Double] {
        let sortedKeys = frequencies.keys.sorted()
        let targets: [Double] = [0.10, 0.25, 0.50, 0.75, 0.90]
        var percentiles: [Double: Double] = [:]
        var targetIndex = 0
        var cumulative = 0
        
        for key in sortedKeys {
            cumulative += frequencies[key] ?? 0
            let cumulativeFraction = Double(cumulative) / Double(totalCount)
            
            while targetIndex < targets.count && cumulativeFraction >= targets[targetIndex] {
                percentiles[targets[targetIndex]] = Double(key)
                targetIndex += 1
            }
            
            if targetIndex >= targets.count { break }
        }
        
        // Fill any remaining percentiles with the max value
        while targetIndex < targets.count {
            percentiles[targets[targetIndex]] = Double(sortedKeys.last ?? 0)
            targetIndex += 1
        }
        
        return percentiles
    }
}
