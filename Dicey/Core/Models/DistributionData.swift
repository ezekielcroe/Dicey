//
//  DistributionData.swift
//  Dicey
//

import Foundation

struct DistributionData {
    let frequencies: [Int: Int]
    let totalIterations: Int
    let mean: Double
    let standardDeviation: Double
    let minimum: Int
    let maximum: Int
    let percentiles: [Double: Double]

    /// Sorted bins for charting, probability as percentage
    var sortedBins: [(value: Int, probability: Double)] {
        frequencies.keys.sorted().map { key in
            (value: key, probability: Double(frequencies[key]!) / Double(totalIterations) * 100.0)
        }
    }

    /// Cumulative distribution — each bin shows "probability of rolling ≤ this value"
    var cdfBins: [(value: Int, cumulative: Double)] {
        let sorted = frequencies.keys.sorted()
        var cumulative = 0.0
        return sorted.map { key in
            cumulative += Double(frequencies[key]!) / Double(totalIterations) * 100.0
            return (value: key, cumulative: cumulative)
        }
    }

    var p10: Double { percentiles[0.10] ?? Double(minimum) }
    var p25: Double { percentiles[0.25] ?? Double(minimum) }
    var median: Double { percentiles[0.50] ?? mean }
    var p75: Double { percentiles[0.75] ?? Double(maximum) }
    var p90: Double { percentiles[0.90] ?? Double(maximum) }

    // MARK: - Factory

    static func from(frequencies: [Int: Int], totalIterations: Int) -> DistributionData {
        guard !frequencies.isEmpty else {
            return DistributionData(
                frequencies: [:], totalIterations: 0, mean: 0, standardDeviation: 0,
                minimum: 0, maximum: 0, percentiles: [:]
            )
        }

        let minVal = frequencies.keys.min()!
        let maxVal = frequencies.keys.max()!

        var totalSum: Double = 0
        for (value, count) in frequencies {
            totalSum += Double(value) * Double(count)
        }
        let mean = totalSum / Double(totalIterations)

        var sumOfSquaredDiffs: Double = 0
        for (value, count) in frequencies {
            sumOfSquaredDiffs += pow(Double(value) - mean, 2) * Double(count)
        }
        let stdDev = sqrt(sumOfSquaredDiffs / Double(totalIterations))

        let percentiles = computePercentiles(from: frequencies, totalCount: totalIterations)

        return DistributionData(
            frequencies: frequencies, totalIterations: totalIterations,
            mean: mean, standardDeviation: stdDev,
            minimum: minVal, maximum: maxVal, percentiles: percentiles
        )
    }

    /// Given a desired success probability (0–1), find the target number from the CDF
    func reverseTarget(for desiredProbability: Double, condition: SuccessCondition) -> Int? {
        guard !frequencies.isEmpty else { return nil }
        let sorted = frequencies.keys.sorted()

        switch condition {
        case .none, .countSpecificFace:
            return nil

        case .meetOrAbove, .above:
            // Walk from high to low; find the lowest value where P(≥ value) ≈ desired
            var cumFromTop = 0.0
            for key in sorted.reversed() {
                cumFromTop += Double(frequencies[key]!) / Double(totalIterations)
                if cumFromTop >= desiredProbability {
                    return condition == .above ? key - 1 : key
                }
            }
            return sorted.first

        case .meetOrBelow, .below:
            // Walk from low to high; find the highest value where P(≤ value) ≈ desired
            var cumFromBottom = 0.0
            for key in sorted {
                cumFromBottom += Double(frequencies[key]!) / Double(totalIterations)
                if cumFromBottom >= desiredProbability {
                    return condition == .below ? key + 1 : key
                }
            }
            return sorted.last
        }
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

        while targetIndex < targets.count {
            percentiles[targets[targetIndex]] = Double(sortedKeys.last ?? 0)
            targetIndex += 1
        }

        return percentiles
    }
}
