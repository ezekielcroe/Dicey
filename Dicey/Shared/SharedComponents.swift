//
//  SharedComponents.swift
//  Dicey
//
//  Reusable UI components used across multiple features.
//

import SwiftUI

// MARK: - Section Label

struct SectionLabel: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Mechanic Tag Pill

struct MechanicTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - Card Container

struct CardContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Percentile Box

struct PercentileBox: View {
    let label: String
    let value: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.caption)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mechanics Tags Row

/// Convenience: renders the standard set of mechanic tags for a configuration.
struct MechanicsTagsRow: View {
    let config: DiceConfiguration

    var body: some View {
        HStack(spacing: 4) {
            if config.exploding {
                MechanicTag(text: "Exploding", color: .orange)
            }
            switch config.rerollBehavior {
            case .none: EmptyView()
            case .rerollOnes: MechanicTag(text: "Reroll 1s", color: .purple)
            case .rerollBelow: MechanicTag(text: "Reroll ≤\(config.rerollThreshold)", color: .purple)
            }
            if config.keepOption == .highest {
                MechanicTag(text: "KH\(config.keepAmount)", color: .teal)
            } else if config.keepOption == .lowest {
                MechanicTag(text: "KL\(config.keepAmount)", color: .teal)
            }
        }
    }
}
