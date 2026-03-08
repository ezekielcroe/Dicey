//
//  OpposedRollViewModel.swift
//  Dicey
//
//  Two pools, head-to-head. "Attacker vs. Defender — who wins?"
//

import SwiftUI
import Combine

@MainActor
class OpposedRollViewModel: ObservableObject {

    @Published var configA = DiceConfiguration() { didSet { triggerSimulation() } }
    @Published var configB = DiceConfiguration() { didSet { triggerSimulation() } }

    @Published var result: MonteCarloEngine.OpposedResult? = nil
    @Published var isCalculating: Bool = false

    @Published var labelA: String = "Pool A"
    @Published var labelB: String = "Pool B"

    let availableDice = [4, 6, 8, 10, 12, 20, 100]
    private var calculationTask: Task<Void, Never>?

    // MARK: - Pool Actions

    func addDie(to pool: Pool, sides: Int) {
        switch pool {
        case .a: configA.dice.append(Die(sides: sides))
        case .b: configB.dice.append(Die(sides: sides))
        }
    }

    func removeDie(from pool: Pool, at index: Int) {
        switch pool {
        case .a: configA.dice.remove(at: index)
        case .b: configB.dice.remove(at: index)
        }
    }

    func clearPool(_ pool: Pool) {
        switch pool {
        case .a: configA.dice.removeAll()
        case .b: configB.dice.removeAll()
        }
    }

    enum Pool { case a, b }

    // MARK: - Simulation

    private func triggerSimulation() {
        calculationTask?.cancel()

        guard !configA.dice.isEmpty, !configB.dice.isEmpty else {
            result = nil
            return
        }

        isCalculating = true
        let snapA = configA
        let snapB = configB

        calculationTask = Task.detached(priority: .userInitiated) {
            do {
                try await Task.sleep(nanoseconds: 400_000_000) // 0.4s debounce
            } catch { return }

            guard !Task.isCancelled else { return }

            let simResult = await MonteCarloEngine.simulateOpposed(configA: snapA, configB: snapB)

            guard !Task.isCancelled, let simResult = simResult else { return }

            await MainActor.run {
                self.result = simResult
                self.isCalculating = false
            }
        }
    }
}
