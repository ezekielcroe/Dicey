//
//  RollEngine.swift
//  Dicey
//
//  Pure-function roll logic. No UI state. Reusable by sandbox, opposed rolls, and scenarios.
//

import Foundation

enum RollEngine {

    /// Rolls a pool in-place, applying all mechanics from the configuration.
    static func execute(pool: inout [Die], config: DiceConfiguration) {
        // 1. Initial roll
        for i in pool.indices {
            pool[i].value = Int.random(in: 1...pool[i].sides)
            pool[i].isDropped = false
        }

        // 2. Rerolls (once — take the new result regardless)
        switch config.rerollBehavior {
        case .none:
            break
        case .rerollOnes:
            for i in pool.indices {
                if pool[i].value == 1 {
                    pool[i].value = Int.random(in: 1...pool[i].sides)
                }
            }
        case .rerollBelow:
            for i in pool.indices {
                if let val = pool[i].value, val <= config.rerollThreshold {
                    pool[i].value = Int.random(in: 1...pool[i].sides)
                }
            }
        }

        // 3. Exploding dice — on max face, roll again and add. Chain up to 10.
        if config.exploding {
            for i in pool.indices {
                if pool[i].value == pool[i].sides {
                    var total = pool[i].sides
                    for _ in 0..<10 {
                        let bonus = Int.random(in: 1...pool[i].sides)
                        total += bonus
                        if bonus != pool[i].sides { break }
                    }
                    pool[i].value = total
                }
            }
        }

        // 4. Keep / Drop
        if config.keepOption != .none && config.keepAmount < pool.count {
            let sortedIndices = pool.indices.sorted {
                (pool[$0].value ?? 0) < (pool[$1].value ?? 0)
            }
            let dropCount = pool.count - config.keepAmount

            if config.keepOption == .highest {
                for i in 0..<dropCount {
                    pool[sortedIndices[i]].isDropped = true
                }
            } else if config.keepOption == .lowest {
                let start = sortedIndices.count - dropCount
                for i in start..<sortedIndices.count {
                    pool[sortedIndices[i]].isDropped = true
                }
            }
        }
    }

    /// Computes the sum of active (non-dropped) dice plus modifier.
    static func sum(of pool: [Die], modifier: Int) -> Int {
        pool.filter { !$0.isDropped }.compactMap(\.value).reduce(0, +) + modifier
    }

    /// Counts how many active dice show the target face value.
    static func faceCount(in pool: [Die], targetFace: Int) -> Int {
        pool.filter { !$0.isDropped }.filter { $0.value == targetFace }.count
    }

    /// Checks if a result meets the given success condition.
    static func checkSuccess(sum: Int, faceCount: Int, config: DiceConfiguration) -> Bool {
        switch config.condition {
        case .none:              return false
        case .meetOrAbove:       return sum >= config.targetNumber
        case .meetOrBelow:       return sum <= config.targetNumber
        case .above:             return sum > config.targetNumber
        case .below:             return sum < config.targetNumber
        case .countSpecificFace: return faceCount >= config.targetNumber
        }
    }
}
