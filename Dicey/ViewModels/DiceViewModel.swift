//
//  DiceViewModel.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI
import Combine

@MainActor
class DiceViewModel: ObservableObject {
    @Published var dicePool: [Die] = []
    @Published var history: [RollHistoryEntry] = []
    
    // Inputs that trigger recalculation
    @Published var condition: SuccessCondition = .none { didSet { triggerCalculation() } }
    @Published var targetNumber: Int = 10 { didSet { triggerCalculation() } }
    @Published var targetFaceValue: Int = 1 { didSet { triggerCalculation() } }
    @Published var modifier: Int = 0 { didSet { triggerCalculation() } }
    @Published var keepOption: KeepOption = .none { didSet { triggerCalculation() } }
    @Published var keepAmount: Int = 1 { didSet { triggerCalculation() } }
    
    // New dice mechanics
    @Published var exploding: Bool = false { didSet { triggerCalculation() } }
    @Published var rerollBehavior: RerollBehavior = .none { didSet { triggerCalculation() } }
    @Published var rerollThreshold: Int = 2 { didSet { triggerCalculation() } }
    
    @Published var hasRolled: Bool = false
    
    // Monte Carlo results
    @Published var estimatedAverage: Double? = nil
    @Published var estimatedProbability: Double? = nil
    @Published var isCalculating: Bool = false
    @Published var distribution: DistributionData? = nil
    
    // Comparison snapshots
    @Published var comparisonSnapshots: [ComparisonSnapshot] = []
    private var nextColorIndex: Int = 0
    
    private var calculationTask: Task<Void, Never>?
    let availableDice = [4, 6, 8, 10, 12, 20, 100]
    
    // MARK: - Computed Properties
    
    var activeDice: [Die] { dicePool.filter { !$0.isDropped } }
    var currentSum: Int { activeDice.compactMap({ $0.value }).reduce(0, +) + modifier }
    var specificFaceCount: Int { activeDice.filter({ $0.value == targetFaceValue }).count }
    
    var isSuccess: Bool? {
        guard hasRolled, condition != .none else { return nil }
        return checkSuccess(sum: currentSum, faceCount: specificFaceCount, condition: condition, targetNum: targetNumber)
    }
    
    /// Human-readable description of the current dice configuration
    var configDescription: String {
        guard !dicePool.isEmpty else { return "Empty" }
        
        // Group dice by side count
        var groups: [Int: Int] = [:]
        for die in dicePool {
            groups[die.sides, default: 0] += 1
        }
        
        let diceStr = groups.keys.sorted().map { sides in
            let count = groups[sides]!
            return "\(count)d\(sides)"
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
    
    // MARK: - Dice Pool Actions
    
    func addDie(sides: Int) {
        dicePool.append(Die(sides: sides))
        resetRolls()
    }
    
    func removeDie(at index: Int) {
        dicePool.remove(at: index)
        resetRolls()
    }
    
    func clearPool() {
        dicePool.removeAll()
        resetRolls()
    }
    
    func rollDice() {
        performRollLogic(
            on: &dicePool,
            keepOption: keepOption,
            keepAmount: keepAmount,
            exploding: exploding,
            rerollBehavior: rerollBehavior,
            rerollThreshold: rerollThreshold
        )
        
        hasRolled = true
        
        let newEntry = RollHistoryEntry(
            timestamp: Date(),
            dicePool: dicePool,
            modifier: modifier,
            keepOption: keepOption,
            keepAmount: keepAmount,
            condition: condition,
            targetFaceValue: targetFaceValue,
            targetNumber: targetNumber,
            probability: estimatedProbability,
            isSuccess: isSuccess,
            exploding: exploding,
            rerollBehavior: rerollBehavior,
            rerollThreshold: rerollThreshold
        )
        history.insert(newEntry, at: 0)
        if history.count > 100 { history.removeLast() }
    }
    
    func clearHistory() { history.removeAll() }
    
    // MARK: - Comparison Snapshots
    
    func saveSnapshot(name: String) {
        guard let dist = distribution else { return }
        
        let snapshot = ComparisonSnapshot(
            id: UUID(),
            name: name,
            configDescription: configDescription,
            distribution: dist,
            colorIndex: nextColorIndex,
            exploding: exploding,
            rerollBehavior: rerollBehavior,
            rerollThreshold: rerollThreshold,
            keepOption: keepOption,
            keepAmount: keepAmount,
            modifier: modifier,
            condition: condition,
            targetNumber: targetNumber,
            targetFaceValue: targetFaceValue
        )
        comparisonSnapshots.append(snapshot)
        nextColorIndex += 1
    }
    
    func removeSnapshot(id: UUID) {
        comparisonSnapshots.removeAll { $0.id == id }
    }
    
    func clearSnapshots() {
        comparisonSnapshots.removeAll()
        nextColorIndex = 0
    }
    
    // MARK: - Private Helpers
    
    private func resetRolls() {
        for i in 0..<dicePool.count {
            dicePool[i].value = nil
            dicePool[i].isDropped = false
        }
        hasRolled = false
        triggerCalculation()
    }
    
    // MARK: - Core Roll Logic (shared by live roll and simulation)
    
    private func performRollLogic(
        on pool: inout [Die],
        keepOption: KeepOption,
        keepAmount: Int,
        exploding: Bool,
        rerollBehavior: RerollBehavior,
        rerollThreshold: Int
    ) {
        // 1. Initial roll
        for i in 0..<pool.count {
            pool[i].value = Int.random(in: 1...pool[i].sides)
            pool[i].isDropped = false
        }
        
        // 2. Rerolls (once only — take the new result regardless)
        switch rerollBehavior {
        case .none:
            break
        case .rerollOnes:
            for i in 0..<pool.count {
                if pool[i].value == 1 {
                    pool[i].value = Int.random(in: 1...pool[i].sides)
                }
            }
        case .rerollBelow:
            for i in 0..<pool.count {
                if let val = pool[i].value, val <= rerollThreshold {
                    pool[i].value = Int.random(in: 1...pool[i].sides)
                }
            }
        }
        
        // 3. Exploding dice — on max face, roll again and add. Chain up to 10 times.
        if exploding {
            for i in 0..<pool.count {
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
        
        // 4. Keep / Drop logic
        if keepOption != .none && keepAmount < pool.count {
            let sortedIndices = pool.indices.sorted {
                (pool[$0].value ?? 0) < (pool[$1].value ?? 0)
            }
            let dropCount = pool.count - keepAmount
            
            if keepOption == .highest {
                for i in 0..<dropCount {
                    pool[sortedIndices[i]].isDropped = true
                }
            } else if keepOption == .lowest {
                let startIndexToDrop = sortedIndices.count - dropCount
                for i in startIndexToDrop..<sortedIndices.count {
                    pool[sortedIndices[i]].isDropped = true
                }
            }
        }
    }
    
    private func checkSuccess(sum: Int, faceCount: Int, condition: SuccessCondition, targetNum: Int) -> Bool {
        switch condition {
        case .none: return false
        case .meetOrAbove: return sum >= targetNum
        case .meetOrBelow: return sum <= targetNum
        case .above: return sum > targetNum
        case .below: return sum < targetNum
        case .countSpecificFace: return faceCount >= targetNum
        }
    }

    // MARK: - Monte Carlo Simulation Engine
    
    private func triggerCalculation() {
        calculationTask?.cancel()
        
        guard !dicePool.isEmpty else {
            estimatedAverage = nil
            estimatedProbability = nil
            distribution = nil
            return
        }
        
        isCalculating = true
        
        // Snapshot all parameters for thread-safe simulation
        let poolSnapshot = dicePool.map { $0.clone() }
        let modSnapshot = modifier
        let keepOptSnapshot = keepOption
        let keepAmtSnapshot = keepAmount
        let condSnapshot = condition
        let targetNumSnapshot = targetNumber
        let targetFaceSnapshot = targetFaceValue
        let explodingSnapshot = exploding
        let rerollSnapshot = rerollBehavior
        let rerollThreshSnapshot = rerollThreshold
        
        calculationTask = Task.detached(priority: .userInitiated) {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3s debounce
            } catch {
                return
            }
            
            if Task.isCancelled { return }
            
            let iterations = 20_000
            var totalSumAccumulator = 0
            var successesAccumulator = 0
            var frequencyMap: [Int: Int] = [:]
            var tempPool = poolSnapshot
            
            for _ in 0..<iterations {
                if Task.isCancelled { return }
                
                await self.performRollLogic(
                    on: &tempPool,
                    keepOption: keepOptSnapshot,
                    keepAmount: keepAmtSnapshot,
                    exploding: explodingSnapshot,
                    rerollBehavior: rerollSnapshot,
                    rerollThreshold: rerollThreshSnapshot
                )
                
                var iterationSum = modSnapshot
                var iterationFaceCount = 0
                
                for die in tempPool {
                    if !die.isDropped {
                        if let val = die.value {
                            iterationSum += val
                            if val == targetFaceSnapshot {
                                iterationFaceCount += 1
                            }
                        }
                    }
                }
                
                totalSumAccumulator += iterationSum
                frequencyMap[iterationSum, default: 0] += 1
                
                if condSnapshot != .none {
                    if await self.checkSuccess(
                        sum: iterationSum,
                        faceCount: iterationFaceCount,
                        condition: condSnapshot,
                        targetNum: targetNumSnapshot
                    ) {
                        successesAccumulator += 1
                    }
                }
            }
            
            let finalAvg = Double(totalSumAccumulator) / Double(iterations)
            let finalProb = condSnapshot == .none ? nil : Double(successesAccumulator) / Double(iterations)
            let dist = await DistributionData.from(frequencies: frequencyMap, totalIterations: iterations)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.estimatedAverage = finalAvg
                self.estimatedProbability = finalProb
                self.distribution = dist
                self.isCalculating = false
            }
        }
    }
}
