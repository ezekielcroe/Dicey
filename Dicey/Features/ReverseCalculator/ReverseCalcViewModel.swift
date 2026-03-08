//
//  ReverseCalcViewModel.swift
//  Dicey
//
//  "I want 60% success rate — what DC should I set?"
//

import SwiftUI
import Combine

@MainActor
class ReverseCalcViewModel: ObservableObject {

    // MARK: - Input

    @Published var config = DiceConfiguration() {
        didSet { triggerCalculation() }
    }

    @Published var desiredProbability: Double = 0.65 {
        didSet { recalculateTarget() }
    }

    @Published var reverseCondition: SuccessCondition = .meetOrAbove {
        didSet { recalculateTarget() }
    }

    // MARK: - Output

    @Published var distribution: DistributionData? = nil
    @Published var suggestedTarget: Int? = nil
    @Published var actualProbability: Double? = nil
    @Published var isCalculating: Bool = false

    let availableDice = [4, 6, 8, 10, 12, 20, 100]
    private var calculationTask: Task<Void, Never>?

    // MARK: - Pool Actions

    func addDie(sides: Int) {
        config.dice.append(Die(sides: sides))
    }

    func removeDie(at index: Int) {
        config.dice.remove(at: index)
    }

    func clearPool() {
        config.dice.removeAll()
    }

    // MARK: - Calculation

    private func triggerCalculation() {
        calculationTask?.cancel()

        guard !config.dice.isEmpty else {
            distribution = nil
            suggestedTarget = nil
            actualProbability = nil
            return
        }

        isCalculating = true
        let snapshot = config

        calculationTask = Task.detached(priority: .userInitiated) {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch { return }

            guard !Task.isCancelled else { return }

            let result = await MonteCarloEngine.simulate(config: snapshot)
            guard !Task.isCancelled, let result = result else { return }

            await MainActor.run {
                self.distribution = result.distribution
                self.isCalculating = false
                self.recalculateTarget()
            }
        }
    }

    private func recalculateTarget() {
        guard let dist = distribution else {
            suggestedTarget = nil
            actualProbability = nil
            return
        }

        guard reverseCondition != .none, reverseCondition != .countSpecificFace else {
            suggestedTarget = nil
            actualProbability = nil
            return
        }

        if let target = dist.reverseTarget(for: desiredProbability, condition: reverseCondition) {
            suggestedTarget = target

            // Calculate actual probability at this target
            var successes = 0
            for (value, count) in dist.frequencies {
                let passes: Bool
                switch reverseCondition {
                case .meetOrAbove: passes = value >= target
                case .meetOrBelow: passes = value <= target
                case .above:       passes = value > target
                case .below:       passes = value < target
                default:           passes = false
                }
                if passes { successes += count }
            }
            actualProbability = Double(successes) / Double(dist.totalIterations)
        } else {
            suggestedTarget = nil
            actualProbability = nil
        }
    }
}
