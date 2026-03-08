//
//  ContentView.swift
//  Dicey
//
//  Tab-based navigation: Sandbox, Opposed, Target Finder, Compare, History.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sandboxVM = DicePoolViewModel()
    @StateObject private var comparisonVM = ComparisonViewModel()
    @StateObject private var opposedVM = OpposedRollViewModel()
    @StateObject private var reverseVM = ReverseCalcViewModel()

    @State private var selectedTab: AppTab = .sandbox

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Sandbox
            NavigationStack {
                SandboxView(vm: sandboxVM, comparisonVM: comparisonVM)
                    .navigationTitle("Sandbox")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Sandbox", systemImage: "dice")
            }
            .tag(AppTab.sandbox)

            // MARK: - Opposed Roll
            NavigationStack {
                OpposedRollView(vm: opposedVM)
            }
            .tabItem {
                Label("Opposed", systemImage: "person.2")
            }
            .tag(AppTab.opposed)

            // MARK: - Reverse Calculator
            NavigationStack {
                ReverseCalcView(vm: reverseVM)
            }
            .tabItem {
                Label("Target Finder", systemImage: "target")
            }
            .tag(AppTab.reverse)

            // MARK: - Comparison
            NavigationStack {
                if #available(iOS 16.0, *) {
                    ComparisonView(comparisonVM: comparisonVM)
                } else {
                    Text("Comparison requires iOS 16+")
                        .foregroundColor(.secondary)
                        .navigationTitle("Compare")
                }
            }
            .tabItem {
                Label {
                    Text("Compare")
                } icon: {
                    ZStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .badge(comparisonVM.snapshots.count > 0 ? comparisonVM.snapshots.count : 0)
            .tag(AppTab.compare)

            // MARK: - History
            NavigationStack {
                HistoryView(vm: sandboxVM)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(AppTab.history)
        }
    }
}

enum AppTab: Hashable {
    case sandbox
    case opposed
    case reverse
    case compare
    case history
}
