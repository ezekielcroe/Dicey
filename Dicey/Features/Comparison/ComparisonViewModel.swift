//
//  ComparisonViewModel.swift
//  Dicey
//
//  Manages comparison snapshots independently from the sandbox.
//

import SwiftUI
import Combine

@MainActor
class ComparisonViewModel: ObservableObject {
    @Published var snapshots: [ComparisonSnapshot] = []
    private var nextColorIndex: Int = 0

    func saveSnapshot(name: String, config: DiceConfiguration, distribution: DistributionData) {
        let snapshot = ComparisonSnapshot(
            id: UUID(),
            name: name,
            config: config,
            distribution: distribution,
            colorIndex: nextColorIndex
        )
        snapshots.append(snapshot)
        nextColorIndex += 1
    }

    func removeSnapshot(id: UUID) {
        snapshots.removeAll { $0.id == id }
    }

    func clearAll() {
        snapshots.removeAll()
        nextColorIndex = 0
    }
}
