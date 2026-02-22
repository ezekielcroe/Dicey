//
//  ContentView.swift
//  Dicey
//
//  Created by Zhi Zheng Yeo on 22/2/26.
//

import SwiftUI
import Combine

// MARK: - Models & Shapes

enum KeepOption: String, CaseIterable {
    case none = "Keep All"
    case lowest = "Keep Lowest"
    case highest = "Keep Highest"
}

struct Die: Identifiable, Cloneable {
    let id: UUID
    let sides: Int
    var value: Int? = nil
    var isDropped: Bool = false
    
    init(sides: Int, id: UUID = UUID(), value: Int? = nil, isDropped: Bool = false) {
        self.sides = sides
        self.id = id
        self.value = value
        self.isDropped = isDropped
    }
    
    // Helper to create a clean copy for simulation
    func clone() -> Die {
        return Die(sides: self.sides)
    }
}

// Protocol to help copy the array for simulation
protocol Cloneable {
    func clone() -> Self
}

enum SuccessCondition: String, CaseIterable {
    case none = "No Condition"
    case meetOrAbove = "Sum >= Target"
    case meetOrBelow = "Sum <= Target"
    case above = "Sum > Target"
    case below = "Sum < Target"
    case countSpecificFace = "Rolls of Target Face >= Target"
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct RegularPolygon: Shape {
    var sides: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0
        let angle = (Double.pi * 2.0) / Double(sides)
        
        for i in 0..<sides {
            let currentAngle = angle * Double(i) - Double.pi / 2.0
            let point = CGPoint(
                x: center.x + radius * Foundation.cos(currentAngle),
                y: center.y + radius * Foundation.sin(currentAngle)
            )
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

enum AnyShape: Shape {
    case roundedRectangle(cornerRadius: CGFloat)
    case regularPolygon(sides: Int)
    case diamond
    case circle
    case triangle
    
    func path(in rect: CGRect) -> Path {
        switch self {
        case .roundedRectangle(let cornerRadius):
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        case .regularPolygon(let sides):
            return RegularPolygon(sides: sides).path(in: rect)
        case .diamond:
            return Diamond().path(in: rect)
        case .circle:
            return Circle().path(in: rect)
        case .triangle:
            return Triangle().path(in: rect)
        }
    }
}

func dieShape(sides: Int) -> AnyShape {
    switch sides {
    case 4: return .triangle
    case 6: return .roundedRectangle(cornerRadius: 6)
    case 8: return .diamond
    case 10: return .regularPolygon(sides: 5)
    case 12: return .regularPolygon(sides: 6)
    case 20: return .regularPolygon(sides: 8)
    case 100: return .circle
    default: return .roundedRectangle(cornerRadius: 6)
    }
}
// --------------------------------------------------

struct RollHistoryEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let dicePool: [Die]
    let modifier: Int
    let keepOption: KeepOption
    let keepAmount: Int
    let condition: SuccessCondition
    let targetFaceValue: Int
    let targetNumber: Int
    let probability: Double?
    let isSuccess: Bool?
    
    var activeDice: [Die] { dicePool.filter { !$0.isDropped } }
    
    var resultSummary: String {
        let sum = activeDice.compactMap({ $0.value }).reduce(0, +) + modifier
        let faceCount = activeDice.filter({ $0.value == targetFaceValue }).count
        
        switch condition {
        case .none, .meetOrAbove, .meetOrBelow, .above, .below:
            return "Total: \(sum)"
        case .countSpecificFace:
            return "Face \(targetFaceValue) Rolled: \(faceCount)"
        }
    }
}

// MARK: - ViewModel

@MainActor // Ensures UI updates happen on the main thread
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
    
    @Published var hasRolled: Bool = false
    
    // New properties for Monte Carlo results
    @Published var estimatedAverage: Double? = nil
    @Published var estimatedProbability: Double? = nil
    @Published var isCalculating: Bool = false
    
    private var calculationTask: Task<Void, Never>?
    let availableDice = [4, 6, 8, 10, 12, 20, 100]
    
    // MARK: - Computed Properties (Active State)
    var activeDice: [Die] { dicePool.filter { !$0.isDropped } }
    var currentSum: Int { activeDice.compactMap({ $0.value }).reduce(0, +) + modifier }
    var specificFaceCount: Int { activeDice.filter({ $0.value == targetFaceValue }).count }
    
    // Determines success for an actual roll on screen
    var isSuccess: Bool? {
        guard hasRolled, condition != .none else { return nil }
        return checkSuccess(sum: currentSum, faceCount: specificFaceCount, condition: condition, targetNum: targetNumber)
    }
    
    // MARK: - Actions
    
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
        // 1. Perform the actual roll logic
        performRollLogic(on: &dicePool, keepOption: keepOption, keepAmount: keepAmount)
        
        hasRolled = true
        
        // 2. Record history using current estimates
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
            isSuccess: isSuccess
        )
        history.insert(newEntry, at: 0)
        if history.count > 100 { history.removeLast() }
    }
    
    func clearHistory() { history.removeAll() }
    
    private func resetRolls() {
        for i in 0..<dicePool.count {
            dicePool[i].value = nil
            dicePool[i].isDropped = false
        }
        hasRolled = false
        // Whenever pool resets, recalculate stats based on new parameters
        triggerCalculation()
    }
    
    // MARK: - Core Logic Shared by Live Roll and Simulation
    
    /// Applies random values and the keep/drop logic to a given pool
    private func performRollLogic(on pool: inout [Die], keepOption: KeepOption, keepAmount: Int) {
        // 1. Roll
        for i in 0..<pool.count {
            pool[i].value = Int.random(in: 1...pool[i].sides)
            pool[i].isDropped = false
        }
        
        // 2. Apply Keep/Drop Logic
        if keepOption != .none && keepAmount < pool.count {
            // Sort indicies based on the rolled values
            let sortedIndices = pool.indices.sorted {
                (pool[$0].value ?? 0) < (pool[$1].value ?? 0)
            }
            
            let dropCount = pool.count - keepAmount
            
            if keepOption == .highest {
                // Drop the lowest N dice
                for i in 0..<dropCount {
                    pool[sortedIndices[i]].isDropped = true
                }
            } else if keepOption == .lowest {
                // Drop the highest N dice (the end of the sorted array)
                let startIndexToDrop = sortedIndices.count - dropCount
                for i in startIndexToDrop..<sortedIndices.count {
                    pool[sortedIndices[i]].isDropped = true
                }
            }
        }
    }
    
    /// Checks if a given statistical result meets a condition
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
        // Cancel any ongoing simulation if inputs change rapidly
        calculationTask?.cancel()
        
        guard !dicePool.isEmpty else {
            estimatedAverage = nil
            estimatedProbability = nil
            return
        }
        
        isCalculating = true
        
        // Capture current state to pass into the detached task
        let poolSnapshot = dicePool.map { $0.clone() }
        let modSnapshot = modifier
        let keepOptSnapshot = keepOption
        let keepAmtSnapshot = keepAmount
        let condSnapshot = condition
        let targetNumSnapshot = targetNumber
        let targetFaceSnapshot = targetFaceValue
        
        // Run simulation off the main thread with high priority
        calculationTask = Task.detached(priority: .userInitiated) {
            let iterations = 20000 // Higher iterations = more accuracy, slower speed
            var totalSumAccumulator = 0
            var successesAccumulator = 0
            
            // Reusable temporary pool for the loop to reduce allocation overhead
            var tempPool = poolSnapshot
            
            for _ in 0..<iterations {
                // Ensure task cancellation stops the loop early
                if Task.isCancelled { return }
                
                // 1. Run the exact same logic used for a real roll
                await self.performRollLogic(on: &tempPool, keepOption: keepOptSnapshot, keepAmount: keepAmtSnapshot)
                
                // 2. Calculate results for this iteration
                let active = tempPool.filter { !$0.isDropped }
                let iterationSum = active.compactMap({ $0.value }).reduce(0, +) + modSnapshot
                let iterationFaceCount = active.filter({ $0.value == targetFaceSnapshot }).count
                
                totalSumAccumulator += iterationSum
                
                if condSnapshot != .none {
                    if await self.checkSuccess(sum: iterationSum, faceCount: iterationFaceCount, condition: condSnapshot, targetNum: targetNumSnapshot) {
                        successesAccumulator += 1
                    }
                }
            }
            
            // 3. Calculate final estimates
            let finalAvg = Double(totalSumAccumulator) / Double(iterations)
            let finalProb = condSnapshot == .none ? nil : Double(successesAccumulator) / Double(iterations)
            
            guard !Task.isCancelled else { return }
            
            // 4. Update UI back on the main thread
            await MainActor.run {
                self.estimatedAverage = finalAvg
                self.estimatedProbability = finalProb
                self.isCalculating = false
            }
        }
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var vm = DiceViewModel()
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Dice Selection ScrollView (Unchanged) ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(vm.availableDice, id: \.self) { sides in
                            Button(action: {
                                withAnimation { vm.addDie(sides: sides) }
                            }) {
                                ZStack {
                                    dieShape(sides: sides)
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 55, height: 55)
                                    Text("d\(sides)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        // Adjust offset for triangle vs others
                                        .offset(y: sides == 4 ? 6 : 0)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        // --- Pool Header & Clear Button ---
                        HStack {
                            Text("Dice Pool")
                                .font(.headline)
                            Spacer()
                            Button("Clear") {
                                withAnimation { vm.clearPool() }
                            }
                            .foregroundColor(.red)
                            .disabled(vm.dicePool.isEmpty)
                        }
                        
                        // --- Dice Pool Grid (Unchanged visual logic) ---
                        if vm.dicePool.isEmpty {
                            Text("Tap a die above to add it to your pool.")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                                ForEach(Array(vm.dicePool.enumerated()), id: \.element.id) { index, die in
                                    ZStack {
                                        dieShape(sides: die.sides)
                                            .fill(die.value != nil ? Color.blue : Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                        
                                        VStack {
                                            Text("d\(die.sides)")
                                                .font(.system(size: 11))
                                                .foregroundColor(die.value != nil ? .white.opacity(0.7) : .secondary)
                                            Text(die.value != nil ? "\(die.value!)" : "-")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(die.value != nil ? .white : .primary)
                                        }
                                        // Offset for triangle shape
                                        .offset(y: die.sides == 4 ? 6 : 0)
                                        
                                        if die.isDropped {
                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(height: 3)
                                                .rotationEffect(.degrees(-45))
                                                .opacity(0.8)
                                        }
                                    }
                                    .opacity(die.isDropped ? 0.4 : 1.0)
                                    .onTapGesture {
                                        withAnimation { vm.removeDie(at: index) }
                                    }
                                }
                            }
                        }
                        
                        // --- Live Roll Results Box ---
                        if vm.hasRolled && !vm.dicePool.isEmpty {
                            VStack(spacing: 12) {
                                Text("Roll Results")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    StatBox(title: "Sum", value: "\(vm.currentSum)")
                                    if vm.condition == .countSpecificFace {
                                        Divider()
                                        StatBox(title: "Face \(vm.targetFaceValue)s", value: "\(vm.specificFaceCount)")
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .transition(.opacity)
                        }
                        
                        // --- Controls Section ---
                        VStack(spacing: 15) {
                            // Keep/Drop Controls
                            HStack {
                                Text("Keep Option:")
                                Picker("Keep Option", selection: $vm.keepOption) {
                                    ForEach(KeepOption.allCases, id: \.self) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            if vm.keepOption != .none {
                                let maxKeep = vm.dicePool.isEmpty ? 1 : vm.dicePool.count
                                Stepper(value: $vm.keepAmount, in: 1...max(1, maxKeep)) {
                                    HStack {
                                        Text("Amount to Keep:")
                                        Spacer()
                                        Text("\(vm.keepAmount)")
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Modifier Control
                            Stepper(value: $vm.modifier, in: -100...100) {
                                HStack {
                                    Text("Modifier:")
                                    Spacer()
                                    Text("\(vm.modifier > 0 ? "+" : "")\(vm.modifier)")
                                        .fontWeight(.bold)
                                }
                            }
                            
                            Divider()
                            
                            // Condition Controls
                            HStack {
                                Text("Condition:")
                                Picker("Condition", selection: $vm.condition) {
                                    ForEach(SuccessCondition.allCases, id: \.self) { condition in
                                        Text(condition.rawValue).tag(condition)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            if vm.condition == .countSpecificFace {
                                Stepper(value: $vm.targetFaceValue, in: 1...100) {
                                    HStack {
                                        Text("Target Face Value:")
                                        Spacer()
                                        Text("\(vm.targetFaceValue)")
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            
                            if vm.condition != .none {
                                Stepper(value: $vm.targetNumber, in: 0...1000) {
                                    HStack {
                                        Text("Target Goal:")
                                        Spacer()
                                        Text("\(vm.targetNumber)")
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                // --- Statistics Footer (Updated for Monte Carlo) ---
                VStack(spacing: 10) {
                    HStack {
                        Text("Estimated Average:")
                        Spacer()
                        if vm.isCalculating && vm.estimatedAverage == nil {
                             ProgressView()
                                .scaleEffect(0.8)
                        } else if let avg = vm.estimatedAverage {
                            Text(String(format: "%.2f", avg))
                                .fontWeight(.bold)
                        } else {
                            Text("N/A").foregroundColor(.secondary)
                        }
                    }
                    
                    if vm.condition != .none {
                        Divider()
                        HStack {
                            Text("Est. Probability:")
                            Spacer()
                            if vm.isCalculating && vm.estimatedProbability == nil {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let prob = vm.estimatedProbability {
                                Text("\(String(format: "%.1f", prob * 100))%")
                                    .fontWeight(.bold)
                            } else {
                                Text("N/A").foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(resultColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(resultColor, lineWidth: vm.hasRolled && vm.condition != .none ? 3 : 0)
                )
                .cornerRadius(12)
                .padding()
                
                // --- Roll Button ---
                Button(action: {
                    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                    impactMed.impactOccurred()
                    // We don't need withAnimation here as the roll results appear in a separate box
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
        }
    }
    
    private var resultColor: Color {
        guard let isSuccess = vm.isSuccess else { return Color(UIColor.systemBackground) }
        return isSuccess ? .green : .red
    }
    
    private var rollButtonText: String {
        guard let isSuccess = vm.isSuccess else { return "Roll Dice" }
        return isSuccess ? "SUCCESS!" : "FAILED"
    }
}

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

// MARK: - History Views (Minor updates for new success condition display)

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: DiceViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if vm.history.isEmpty {
                    VStack {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        Text("No Roll History Yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(vm.history) { entry in
                            HistoryRow(entry: entry)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Roll History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { withAnimation { vm.clearHistory() } }
                    .foregroundColor(.red)
                    .disabled(vm.history.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let entry: RollHistoryEntry
    
    private var fullDetailString: AttributedString {
        let diceDetails = entry.dicePool.map { die in
            let valStr = die.value.map { String($0) } ?? "?"
            return die.isDropped ? "~~d\(die.sides)(\(valStr))~~" : "d\(die.sides)(\(valStr))"
        }.joined(separator: ", ")
        
        let modifierString = entry.modifier != 0 ? (entry.modifier > 0 ? " +\(entry.modifier)" : " \(entry.modifier)") : ""
        
        let keepString = entry.keepOption != .none ? " | \(entry.keepOption.rawValue) \(entry.keepAmount)" : ""
        
        let combinedString = diceDetails + modifierString + keepString
        
        if let attributed = try? AttributedString(markdown: combinedString) {
            return attributed
        } else {
            return AttributedString(combinedString)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.resultSummary)
                    .font(.caption)
                    .fontWeight(.bold)
                
                if let success = entry.isSuccess {
                    Text(success ? "SUCCESS" : "FAIL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(success ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((success ? Color.green : Color.red).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text(fullDetailString)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            if entry.condition != .none {
                HStack {
                    if entry.condition == .countSpecificFace {
                         Text("\(entry.condition.rawValue) (Face \(entry.targetFaceValue)) : \(entry.targetNumber)")
                    } else {
                         Text("\(entry.condition.rawValue) : \(entry.targetNumber)")
                    }
                   
                    Spacer()
                    if let prob = entry.probability {
                        Text("~ \(String(format: "%.1f", prob * 100))% chance")
                    } else {
                        Text("--")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
