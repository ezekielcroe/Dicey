//
//  ContentView.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = DiceViewModel()
    @State private var showingHistory = false
    @State private var showingComparison = false
    @State private var showingSnapshotAlert = false
    @State private var snapshotName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Dice Selection
                DiceSelectionBar(vm: vm)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        // Dice Pool Display
                        DicePoolGrid(vm: vm)
                        
                        // Controls
                        ControlsSection(vm: vm)
                        
                        // Distribution Chart
                        if let dist = vm.distribution {
                            if #available(iOS 16.0, *) {
                                DistributionChartView(
                                    distribution: dist,
                                    targetNumber: vm.condition != .none ? vm.targetNumber : nil,
                                    condition: vm.condition
                                )
                            } else {
                                DistributionChartFallback(distribution: dist)
                            }
                            
                            // Add to Comparison button
                            Button(action: {
                                snapshotName = vm.configDescription
                                showingSnapshotAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.square.on.square")
                                    Text("Add to Comparison")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                }
                
                // Statistics Footer
                StatisticsFooter(vm: vm)
                
                // Roll Button
                Button(action: {
                    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                    impactMed.impactOccurred()
                    vm.rollDice()
                }) {
                    Text(rollButtonText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.dicePool.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .disabled(vm.dicePool.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Dicey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingComparison = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .imageScale(.large)
                            
                            // Badge showing snapshot count
                            if !vm.comparisonSnapshots.isEmpty {
                                Text("\(vm.comparisonSnapshots.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 14, height: 14)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(vm: vm)
            }
            .sheet(isPresented: $showingComparison) {
                if #available(iOS 16.0, *) {
                    ComparisonView(vm: vm)
                } else {
                    // Minimal fallback
                    NavigationView {
                        Text("Comparison requires iOS 16+")
                            .foregroundColor(.secondary)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { showingComparison = false }
                                }
                            }
                    }
                }
            }
            
            .alert("Save to Comparison", isPresented: $showingSnapshotAlert) {
                TextField("Configuration name", text: $snapshotName)
                Button("Save") {
                    let name = snapshotName.trimmingCharacters(in: .whitespaces)
                    vm.saveSnapshot(name: name.isEmpty ? vm.configDescription : name)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Give this configuration a name for the comparison chart.")
            }
        }
    }
    
    private var rollButtonText: String {
        guard let isSuccess = vm.isSuccess else { return "Roll Dice" }
        return isSuccess ? "SUCCESS!" : "FAILED"
    }
}
