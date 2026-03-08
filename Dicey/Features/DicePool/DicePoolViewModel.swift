//
//  DicePoolViewModel.swift
//  Dicey
//
//  Manages the sandbox: dice pool, rolling, and Monte Carlo distribution.
//  Uses DiceConfiguration + RollEngine instead of inline logic.
//

import SwiftUI
import Combine

@MainActor
class DicePoolViewModel: ObservableObject {

    // MARK: - Published State

    @Published var config = DiceConfiguration() {
        didSet { triggerCalculation() }
    }

    @Published var hasRolled: Bool = false
    @Published var history: [RollHistoryEntry] = []

    // Monte Carlo results
    @Published var estimatedAverage: Double? = nil
    @Published var estimatedProbability: Double? = nil
    @Published var isCalculating: Bool = false
    @Published var distribution: DistributionData? = nil

    let availableDice = [4, 6, 8, 10, 12, 20, 100]
    private var calculationTask: Task<Void, Never>?

    // MARK: - Computed

    var activeDice: [Die] { config.activeDice }
    var currentSum: Int { config.currentSum }
    var specificFaceCount: Int { config.specificFaceCount }

    var isSuccess: Bool? {
        guard hasRolled, config.condition != .none else { return nil }
        return RollEngine.checkSuccess(
            sum: currentSum,
            faceCount: specificFaceCount,
            config: config
        )
    }

    // MARK: - Pool Actions

    func addDie(sides: Int) {
        config.dice.append(Die(sides: sides))
        resetRolls()
    }

    func removeDie(at index: Int) {
        config.dice.remove(at: index)
        resetRolls()
    }

    func clearPool() {
        config.dice.removeAll()
        resetRolls()
    }

    // MARK: - Roll

    func rollDice() {
        RollEngine.execute(pool: &config.dice, config: config)
        hasRolled = true

        let entry = RollHistoryEntry(
            timestamp: Date(),
            config: config,
            rolledDice: config.dice,
            probability: estimatedProbability,
            isSuccess: isSuccess
        )
        history.insert(entry, at: 0)
        if history.count > 100 { history.removeLast() }
    }

    func clearHistory() { history.removeAll() }

    // MARK: - Private

    private func resetRolls() {
        for i in config.dice.indices {
            config.dice[i].value = nil
            config.dice[i].isDropped = false
        }
        hasRolled = false
    }

    private func triggerCalculation() {
        calculationTask?.cancel()

        guard !config.dice.isEmpty else {
            estimatedAverage = nil
            estimatedProbability = nil
            distribution = nil
            return
        }

        isCalculating = true
        let snapshot = config

        calculationTask = Task.detached(priority: .userInitiated) {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3s debounce
            } catch { return }

            guard !Task.isCancelled else { return }

            let result = await MonteCarloEngine.simulate(config: snapshot)

            guard !Task.isCancelled, let result = result else { return }

            await MainActor.run {
                self.estimatedAverage = result.average
                self.estimatedProbability = result.probability
                self.distribution = result.distribution
                self.isCalculating = false
            }
        }
    }
}
