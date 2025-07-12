import SwiftUI
import Combine

// MARK: - Game Models
struct Card: Identifiable, Equatable, Hashable {
    let id = UUID()
    let number: Int
    let color: CardColor
}

enum CardColor: String, CaseIterable, Codable {
    case red, blue, yellow, green, purple
    
    var uiColor: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.28, blue: 0.34)      // #ff4757
        case .blue: return Color(red: 0.22, green: 0.26, blue: 0.98)    // #3742fa
        case .yellow: return Color(red: 1.0, green: 0.65, blue: 0.01)   // #ffa502
        case .green: return Color(red: 0.18, green: 0.84, blue: 0.45)   // #2ed573
        case .purple: return Color(red: 0.65, green: 0.37, blue: 0.92)  // #a55eea
        }
    }
    
    var emoji: String {
        switch self {
        case .red: return "🔴"
        case .blue: return "🔵"
        case .yellow: return "🟡"
        case .green: return "🟢"
        case .purple: return "🟣"
        }
    }
}

struct GridCell {
    var stack: [Card] = []
    var isUnlocked: Bool = false
    
    var isEmpty: Bool {
        stack.isEmpty
    }
    
    var topCard: Card? {
        stack.last
    }
}

enum Difficulty: CaseIterable, Codable {
    case easy, medium, hard
    
    var maxNumber: Int {
        switch self {
        case .easy: return 5
        case .medium: return 10
        case .hard: return 15
        }
    }
    
    var gridSize: (rows: Int, cols: Int) {
        switch self {
        case .easy: return (3, 5)    // supereasy from web version
        case .medium: return (4, 5)  // easy from web version
        case .hard: return (5, 5)    // hard from web version
        }
    }
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var subtitle: String {
        switch self {
        case .easy: return "1-\(maxNumber) (\(gridSize.rows)×\(gridSize.cols))"
        case .medium: return "1-\(maxNumber) (\(gridSize.rows)×\(gridSize.cols))"
        case .hard: return "1-\(maxNumber) (\(gridSize.rows)×\(gridSize.cols))"
        }
    }
    
    var emoji: String {
        switch self {
        case .easy: return "🌟"
        case .medium: return "⭐"
        case .hard: return "🔥"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Game State
class GameState: ObservableObject {
    @Published var grid: [[GridCell]] = []
    @Published var collections: [CardColor: [Int]] = [:]
    @Published var tempSlots: [[Card]] = [[], [], []]
    @Published var selectedGridPosition: (row: Int, col: Int)? = nil
    @Published var selectedTempSlot: Int? = nil
    @Published var selectedCollection: (color: CardColor, index: Int)? = nil
    @Published var moves: Int = 0
    @Published var timer: Int = 0
    @Published var gameWon: Bool = false
    @Published var showVictory: Bool = false
    @Published var showHowToPlay: Bool = false
    @Published var message: String = ""
    @Published var showMessage: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentDragState: DragState? = nil
    @Published var currentSeedID: String = ""
    
    var difficulty: Difficulty = .hard
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var pauseStartTime: Date?
    private var gameTimer: Timer?
    private var history: [GameSnapshot] = []
    private var messageTimer: Timer?
    private var autoSaveTimer: Timer?
    private let gameDataManager = GameDataManager.shared
    
    struct GameSnapshot {
        let grid: [[GridCell]]
        let collections: [CardColor: [Int]]
        let tempSlots: [[Card]]
        let moves: Int
    }
    
    struct DragState {
        let card: Card
        let position: CGPoint
        let sourceType: DragData.SourceType
        let stackCards: [Card]
    }
    
    init() {
        setupCollections()
    }
    
    // MARK: - Game Control
    func startNewGame(difficulty: Difficulty) {
        self.difficulty = difficulty
        loadRandomLevel()
        resetTimer()
        setupCollections()
        tempSlots = [[], [], []]
        moves = 0
        gameWon = false
        showVictory = false
        clearSelection()
        history.removeAll()
        startTimer()
        startAutoSave()
    }
    
    func startGameWithSeed(difficulty: Difficulty, seedID: String) {
        self.difficulty = difficulty
        if let level = LevelDatabase.shared.getLevel(difficulty: difficulty, seedID: seedID) {
            loadLevel(level)
        } else {
            // Fallback to random level if seed not found
            loadRandomLevel()
        }
        resetTimer()
        setupCollections()
        tempSlots = [[], [], []]
        moves = 0
        gameWon = false
        showVictory = false
        clearSelection()
        history.removeAll()
        startTimer()
        startAutoSave()
    }
    
    private func loadRandomLevel() {
        let level = LevelDatabase.shared.getRandomLevel(difficulty: difficulty)
        loadLevel(level)
    }
    
    private func loadLevel(_ level: PreDefinedLevel) {
        currentSeedID = level.seedID
        grid = level.createGrid()
        unlockBottomRow()
    }
    
    func resetGame() {
        stopTimer()
        stopAutoSave()
        
        // Record abandoned game if it was in progress
        if timer > 0 && !gameWon {
            gameDataManager.recordGameAbandoned(difficulty: difficulty)
        }
        
        gameWon = false
        showVictory = false
        clearSelection()
    }
    
    func giveUpGame() {
        stopTimer()
        stopAutoSave()
        
        // Record game as given up (affects win rate)
        if timer > 0 && !gameWon {
            gameDataManager.recordGameGivenUp(difficulty: difficulty)
        }
        
        // Delete saved game
        gameDataManager.deleteSavedGame()
        
        gameWon = false
        showVictory = false
        clearSelection()
    }
    
    func saveAndExitGame() {
        // Save current game state
        if timer > 0 && !gameWon {
            gameDataManager.saveGame(self)
        }
        
        pauseTimer()
        clearSelection()
    }
    
    func startNewGameFromPause(difficulty: Difficulty) {
        // Record current game as abandoned if in progress
        if timer > 0 && !gameWon {
            gameDataManager.recordGameAbandoned(difficulty: self.difficulty)
        }
        
        // Delete saved game
        gameDataManager.deleteSavedGame()
        
        // Start new game
        startNewGame(difficulty: difficulty)
    }
    
    func restartCurrentLevel() {
        let currentDifficulty = difficulty
        let currentSeed = currentSeedID
        gameDataManager.deleteSavedGame()
        startGameWithSeed(difficulty: currentDifficulty, seedID: currentSeed)
    }
    
    // MARK: - Level Generation (Legacy - kept for reference)
    // These functions are now handled by LevelDatabase and LevelGenerator
    
    private func unlockBottomRow() {
        let rows = grid.count
        guard rows > 0 else { return }
        
        // Find the bottom-most row with cards and unlock it
        for row in stride(from: rows - 1, through: 0, by: -1) {
            var hasCards = false
            for col in 0..<grid[row].count {
                if !grid[row][col].isEmpty {
                    grid[row][col].isUnlocked = true
                    hasCards = true
                }
            }
            if hasCards { break }
        }
    }
    
    private func setupCollections() {
        collections = [:]
        for color in CardColor.allCases {
            collections[color] = []
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        startTime = Date()
        pausedTime = 0
        isPaused = false
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.startTime, !self.isPaused {
                self.timer = Int(Date().timeIntervalSince(startTime) - self.pausedTime)
            }
        }
    }
    
    func pauseTimer() {
        guard !isPaused, gameTimer != nil else { return }
        isPaused = true
        pauseStartTime = Date()
    }
    
    func resumeTimer() {
        guard isPaused, let pauseStart = pauseStartTime else { return }
        isPaused = false
        pausedTime += Date().timeIntervalSince(pauseStart)
        pauseStartTime = nil
    }
    
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
        isPaused = false
        pauseStartTime = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timer = 0
        startTime = nil
        pausedTime = 0
    }
    
    // MARK: - Auto Save Management
    private func startAutoSave() {
        stopAutoSave()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.autoSaveGame()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func autoSaveGame() {
        guard !gameWon else { return }
        gameDataManager.saveGame(self)
    }
    
    func loadSavedGame() -> Bool {
        guard let saveData = gameDataManager.loadGame() else { return false }
        
        // Restore game state
        self.difficulty = saveData.difficulty
        self.currentSeedID = saveData.seedID
        self.moves = saveData.moves
        self.timer = saveData.timeInSeconds
        self.isPaused = saveData.isPaused
        
        // Restore grid
        grid = restoreGrid(from: saveData.grid)
        
        // Restore collections
        collections = [:]
        for color in CardColor.allCases {
            collections[color] = []
        }
        for (colorKey, numbers) in saveData.collections {
            if let color = CardColor(rawValue: colorKey) {
                collections[color] = numbers
            }
        }
        
        // Restore temp slots
        tempSlots = saveData.tempSlots.map { slotData in
            slotData.map { $0.card }
        }
        
        gameWon = false
        showVictory = false
        clearSelection()
        
        // Start timers
        startTimer()
        startAutoSave()
        
        print("✅ Game loaded successfully")
        return true
    }
    
    private func restoreGrid(from gridData: [[[Int]]]) -> [[GridCell]] {
        var grid: [[GridCell]] = []
        
        for rowData in gridData {
            var row: [GridCell] = []
            for cellData in rowData {
                var cell = GridCell()
                
                // Parse cards from cellData (pairs of [number, colorIndex])
                for i in stride(from: 0, to: cellData.count, by: 2) {
                    if i + 1 < cellData.count {
                        let number = cellData[i]
                        let colorIndex = cellData[i + 1]
                        let color = CardColor.allCases[colorIndex % CardColor.allCases.count]
                        cell.stack.append(Card(number: number, color: color))
                    }
                }
                
                // Set unlocked status based on whether cell has cards and position
                cell.isUnlocked = !cell.isEmpty
                
                row.append(cell)
            }
            grid.append(row)
        }
        
        // Re-apply unlocking logic
        unlockBottomRow()
        
        return grid
    }
    
    // MARK: - Selection Management
    func clearSelection() {
        selectedGridPosition = nil
        selectedTempSlot = nil
        selectedCollection = nil
    }
    
    func selectGridCell(row: Int, col: Int) {
        guard grid[row][col].isUnlocked && !grid[row][col].isEmpty else { return }
        
        clearSelection()
        selectedGridPosition = (row, col)
    }
    
    func selectTempSlot(_ index: Int) {
        guard !tempSlots[index].isEmpty else { return }
        
        clearSelection()
        selectedTempSlot = index
    }
    
    func selectCollection(color: CardColor, index: Int) {
        // If index is -1, select the collection itself (for visual feedback)
        if index == -1 {
            clearSelection()
            selectedCollection = (color, index)
            return
        }
        
        guard let collection = collections[color], 
              !collection.isEmpty, 
              index >= 0,
              index < collection.count,
              index == collection.count - 1 else { 
            // Only allow selection of the last card in collection
            return 
        }
        
        clearSelection()
        selectedCollection = (color, index)
    }
    
    // MARK: - Game Logic
    func canAddToCollection(_ number: Int, color: CardColor) -> Bool {
        guard let collection = collections[color] else { return false }
        
        if collection.isEmpty {
            return number == 1 || number == difficulty.maxNumber
        }
        
        let lastNumber = collection.last!
        let firstNumber = collection.first!
        
        if firstNumber == 1 {
            // Ascending sequence (1, 2, 3, ...)
            return number == lastNumber + 1 && number <= difficulty.maxNumber
        } else {
            // Descending sequence (15, 14, 13, ...)
            return number == lastNumber - 1 && number >= 1
        }
    }
    
    func collectCard(from row: Int, col: Int) {
        guard let card = grid[row][col].topCard,
              canAddToCollection(card.number, color: card.color) else { return }
        
        print("🎯 collectCard: \(card.color.rawValue.capitalized) \(card.number)")
        
        saveState()
        
        // Remove card from grid
        grid[row][col].stack.removeLast()
        
        // Add to collection
        collections[card.color]?.append(card.number)
        
        // Unlock adjacent cells if grid cell is now empty
        if grid[row][col].isEmpty {
            unlockAdjacentCells(row: row, col: col)
        } else {
            // Unlock adjacent cells anyway (from web version behavior)
            unlockAdjacentCells(row: row, col: col)
        }
        
        moves += 1
        clearSelection()
        
        // Show collection message
        showMessage("✅ Collected \(card.color.rawValue.capitalized) \(card.number)")
        
        checkWinCondition()
    }
    
    // MARK: - Movement Functions
    func moveToEmptyCell(targetRow: Int, targetCol: Int) {
        guard let (sourceRow, sourceCol) = selectedGridPosition,
              grid[targetRow][targetCol].isEmpty else { return }
        
        saveState()
        
        // Move top card
        let card = grid[sourceRow][sourceCol].stack.removeLast()
        grid[targetRow][targetCol].stack.append(card)
        grid[targetRow][targetCol].isUnlocked = true
        
        // Unlock adjacent cells
        if grid[sourceRow][sourceCol].isEmpty {
            unlockCellsAbove(row: sourceRow, col: sourceCol)
        }
        unlockAdjacentCells(row: sourceRow, col: sourceCol)
        unlockAdjacentCells(row: targetRow, col: targetCol)
        
        moves += 1
        clearSelection()
    }
    
    func moveFromTempToEmptyCell(targetRow: Int, targetCol: Int) {
        guard let slotIndex = selectedTempSlot,
              !tempSlots[slotIndex].isEmpty,
              grid[targetRow][targetCol].isEmpty else { return }
        
        saveState()
        
        // Move entire temp slot stack
        let allCards = tempSlots[slotIndex]
        tempSlots[slotIndex] = []
        
        for card in allCards {
            grid[targetRow][targetCol].stack.append(card)
        }
        
        grid[targetRow][targetCol].isUnlocked = true
        unlockAdjacentCells(row: targetRow, col: targetCol)
        
        moves += 1
        clearSelection()
    }
    
    func moveFromCollectionToEmptyCell(targetRow: Int, targetCol: Int) {
        guard let selectedCollection = selectedCollection,
              let collection = collections[selectedCollection.color],
              !collection.isEmpty,
              grid[targetRow][targetCol].isEmpty else { return }
        
        saveState()
        
        if selectedCollection.index == -1 {
            // Move entire collection
            let allNumbers = collections[selectedCollection.color]!
            collections[selectedCollection.color] = []
            
            for number in allNumbers {
                let card = Card(number: number, color: selectedCollection.color)
                grid[targetRow][targetCol].stack.append(card)
            }
        } else {
            // Move single card (legacy behavior)
            guard selectedCollection.index == collection.count - 1 else { return }
            let number = collections[selectedCollection.color]!.removeLast()
            let card = Card(number: number, color: selectedCollection.color)
            grid[targetRow][targetCol].stack.append(card)
        }
        
        grid[targetRow][targetCol].isUnlocked = true
        unlockAdjacentCells(row: targetRow, col: targetCol)
        
        moves += 1
        clearSelection()
    }
    
    // MARK: - Temp Slot Logic
    func canAddToTempSlot(_ card: Card, slotIndex: Int) -> Bool {
        let slot = tempSlots[slotIndex]
        
        if slot.isEmpty { return true }
        
        let topCard = slot.last!
        let bottomCard = slot.first!
        
        // Check if can add to top
        let canAddToTop = card.color == topCard.color &&
                         (card.number == topCard.number + 1 || card.number == topCard.number - 1)
        
        // Check if can add to bottom
        let canAddToBottom = card.color == bottomCard.color &&
                            (card.number == bottomCard.number + 1 || card.number == bottomCard.number - 1)
        
        return canAddToTop || canAddToBottom
    }
    
    func addCardToTempSlot(_ card: Card, slotIndex: Int) {
        let slot = tempSlots[slotIndex]
        
        if slot.isEmpty {
            tempSlots[slotIndex].append(card)
            return
        }
        
        let topCard = slot.last!
        let bottomCard = slot.first!
        
        let canAddToTop = card.color == topCard.color &&
                         (card.number == topCard.number + 1 || card.number == topCard.number - 1)
        let canAddToBottom = card.color == bottomCard.color &&
                            (card.number == bottomCard.number + 1 || card.number == bottomCard.number - 1)
        
        if canAddToTop {
            tempSlots[slotIndex].append(card)
        } else if canAddToBottom {
            tempSlots[slotIndex].insert(card, at: 0)
        }
    }
    
    func moveToTempSlot(slotIndex: Int) {
        if let (row, col) = selectedGridPosition {
            moveFromGridToTempSlot(row: row, col: col, slotIndex: slotIndex)
        } else if let collectionData = selectedCollection {
            moveFromCollectionToTempSlot(color: collectionData.color, slotIndex: slotIndex)
        }
    }
    
    private func moveFromGridToTempSlot(row: Int, col: Int, slotIndex: Int) {
        guard let card = grid[row][col].topCard,
              canAddToTempSlot(card, slotIndex: slotIndex) else {
            showMessage("❌ Card doesn't fit in this stack")
            clearSelection()
            return
        }
        
        saveState()
        
        let removedCard = grid[row][col].stack.removeLast()
        addCardToTempSlot(removedCard, slotIndex: slotIndex)
        
        if grid[row][col].isEmpty {
            unlockCellsAbove(row: row, col: col)
        }
        unlockAdjacentCells(row: row, col: col)
        
        moves += 1
        clearSelection()
    }
    
    private func moveFromCollectionToTempSlot(color: CardColor, slotIndex: Int) {
        guard let collection = collections[color], !collection.isEmpty else { return }
        
        // Check if we're moving entire collection or just last card
        if let selectedCollection = selectedCollection, selectedCollection.index == -1 {
            // Move entire collection
            let allNumbers = collections[color]!
            let allCards = allNumbers.map { Card(number: $0, color: color) }
            
            // Check if entire collection can fit
            guard tempSlots[slotIndex].isEmpty else {
                showMessage("❌ Can't move entire collection to occupied slot")
                clearSelection()
                return
            }
            
            saveState()
            
            collections[color] = []
            tempSlots[slotIndex] = allCards
            
            moves += 1
            clearSelection()
        } else {
            // Move single card (legacy behavior)
            let number = collection.last!
            let card = Card(number: number, color: color)
            
            guard canAddToTempSlot(card, slotIndex: slotIndex) else {
                showMessage("❌ Card doesn't fit in this stack")
                clearSelection()
                return
            }
            
            saveState()
            
            collections[color]?.removeLast()
            addCardToTempSlot(card, slotIndex: slotIndex)
            
            moves += 1
            clearSelection()
        }
    }
    
    // MARK: - Collection Logic
    func canAddSlotStackToCollection(_ stack: [Card], color: CardColor) -> Bool {
        guard !stack.isEmpty, stack.first!.color == color else { return false }
        
        let collection = collections[color] ?? []
        let stackNumbers = stack.map { $0.number }
        
        if stack.count == 1 {
            return canAddToCollection(stackNumbers[0], color: color)
        }
        
        if collection.isEmpty {
            let minNum = stackNumbers.min()!
            let maxNum = stackNumbers.max()!
            return minNum == 1 || maxNum == difficulty.maxNumber
        }
        
        let lastInCollection = collection.last!
        let minStackNum = stackNumbers.min()!
        let maxStackNum = stackNumbers.max()!
        
        if collection.first! == 1 {
            // Ascending collection
            return minStackNum == lastInCollection + 1
        } else {
            // Descending collection
            return maxStackNum == lastInCollection - 1
        }
    }
    
    func moveSlotStackToCollection(slotIndex: Int, color: CardColor) -> Bool {
        // Add bounds checking for slotIndex
        guard slotIndex >= 0 && slotIndex < tempSlots.count else {
            showMessage("❌ No stack selected")
            clearSelection()
            return false
        }
        
        let stack = tempSlots[slotIndex]
        
        guard canAddSlotStackToCollection(stack, color: color) else {
            showMessage("❌ Stack doesn't fit in collection")
            clearSelection()
            return false
        }
        
        print("🎯 moveSlotStackToCollection: \(stack.count) cards to \(color.rawValue.capitalized)")
        
        saveState()
        
        let stackNumbers = stack.map { $0.number }.sorted()
        let collection = collections[color] ?? []
        
        if collection.isEmpty {
            if stackNumbers.first! == 1 {
                // Start ascending
                collections[color] = stackNumbers
            } else {
                // Start descending
                collections[color] = stackNumbers.reversed()
            }
        } else {
            if collection.first! == 1 {
                // Ascending - add in order
                collections[color]?.append(contentsOf: stackNumbers)
            } else {
                // Descending - add in reverse order
                collections[color]?.append(contentsOf: stackNumbers.reversed())
            }
        }
        
        tempSlots[slotIndex] = []
        moves += 1
        clearSelection()
        
        // Show collection message
        showMessage("✅ Collected \(stackNumbers.count) cards to \(color.rawValue.capitalized)")
        
        checkWinCondition()
        return true
    }
    
    // MARK: - Unlocking Logic
    private func unlockAdjacentCells(row: Int, col: Int) {
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        
        for (dr, dc) in directions {
            let newRow = row + dr
            let newCol = col + dc
            
            if newRow >= 0 && newRow < grid.count &&
               newCol >= 0 && newCol < grid[0].count &&
               !grid[newRow][newCol].isEmpty {
                grid[newRow][newCol].isUnlocked = true
            }
        }
    }
    
    private func unlockCellsAbove(row: Int, col: Int) {
        if row > 0 && !grid[row - 1][col].isEmpty {
            grid[row - 1][col].isUnlocked = true
        }
    }
    
    // MARK: - Undo/Shuffle
    private func saveState() {
        let snapshot = GameSnapshot(
            grid: grid,
            collections: collections,
            tempSlots: tempSlots,
            moves: moves
        )
        history.append(snapshot)
    }
    
    func undoMove() {
        guard !history.isEmpty else { return }
        
        let lastState = history.removeLast()
        grid = lastState.grid
        collections = lastState.collections
        tempSlots = lastState.tempSlots
        moves = lastState.moves + 1 // Add penalty for undo
        
        clearSelection()
        showMessage("Move undone (+1 move)")
    }
    
    func shuffleCards() {
        saveState()
        
        // Collect all cards from grid
        var allCards: [Card] = []
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                allCards.append(contentsOf: grid[row][col].stack)
                grid[row][col].stack.removeAll()
                grid[row][col].isUnlocked = false
            }
        }
        
        guard !allCards.isEmpty else {
            showMessage("❌ No cards to shuffle")
            return
        }
        
        allCards.shuffle()
        
        // Redistribute cards
        var cardIndex = 0
        let (rows, cols) = difficulty.gridSize
        
        for row in 0..<rows {
            for col in 0..<cols {
                if cardIndex < allCards.count {
                    let stackSize = min(Int.random(in: 1...3), allCards.count - cardIndex)
                    for _ in 0..<stackSize {
                        grid[row][col].stack.append(allCards[cardIndex])
                        cardIndex += 1
                    }
                }
            }
        }
        
        // Distribute remaining cards
        while cardIndex < allCards.count {
            let row = Int.random(in: 0..<rows)
            let col = Int.random(in: 0..<cols)
            if grid[row][col].stack.count < 5 {
                grid[row][col].stack.append(allCards[cardIndex])
                cardIndex += 1
            }
        }
        
        unlockBottomRow()
        
        moves += 2 // Shuffle penalty reduced from 10 to 2
        clearSelection()
        showMessage("🔀 Cards shuffled! (+2 moves)")
    }
    
    // MARK: - Win Condition
    private func checkWinCondition() {
        print("🔍 Checking win condition...")
        
        var completedCount = 0
        let allComplete = CardColor.allCases.allSatisfy { color in
            let count = collections[color]?.count ?? 0
            let isComplete = count == difficulty.maxNumber
            if isComplete { completedCount += 1 }
            print("🔍 Collection \(color.rawValue): \(count)/\(difficulty.maxNumber) - Complete: \(isComplete)")
            return isComplete
        }
        
        print("🔍 Completed collections: \(completedCount)/\(CardColor.allCases.count)")
        
        gameWon = allComplete
        
        if gameWon {
            print("🎉 VICTORY DETECTED! All \(CardColor.allCases.count) collections complete!")
            print("🎉 Current showVictory value: \(showVictory)")
            stopTimer()
            stopAutoSave()
            
            // Record game result
            let gameResult = GameResult(
                id: UUID().uuidString,
                difficulty: difficulty,
                seedID: currentSeedID,
                timeInSeconds: timer,
                moves: moves,
                score: calculateFinalScore(),
                date: Date()
            )
            gameDataManager.recordGameResult(gameResult)
            gameDataManager.deleteSavedGame()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🎉 Setting showVictory = true (was: \(self.showVictory))")
                self.showVictory = true
                print("🎉 showVictory is now: \(self.showVictory)")
            }
        } else {
            print("🔍 Not all collections complete yet (\(completedCount)/\(CardColor.allCases.count))")
        }
    }
    
    // MARK: - Message System
    func showMessage(_ text: String) {
        message = text
        showMessage = true
        
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.showMessage = false
        }
    }
    
    var canUndo: Bool {
        !history.isEmpty
    }
    
    var formattedTime: String {
        let minutes = timer / 60
        let seconds = timer % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func calculateFinalScore() -> Int {
        let baseScore = switch difficulty {
        case .easy: 1000
        case .medium: 1500
        case .hard: 2000
        }
        
        // Time bonus (faster = better)
        let idealTime = switch difficulty {
        case .easy: 120    // 2 minutes
        case .medium: 180  // 3 minutes
        case .hard: 300    // 5 minutes
        }
        
        let timeBonus = max(0, (idealTime - timer) * 10)
        
        // Move penalty (fewer moves = better)
        let idealMoves = switch difficulty {
        case .easy: 30
        case .medium: 50
        case .hard: 80
        }
        
        let movePenalty = max(0, (moves - idealMoves) * 5)
        
        let finalScore = baseScore + timeBonus - movePenalty
        return max(100, finalScore) // Minimum score of 100
    }
    
    // MARK: - Drag State Management
    func startDrag(card: Card, sourceType: DragData.SourceType, position: CGPoint, stackCards: [Card] = []) {
        let stack = stackCards.isEmpty ? [card] : stackCards
        currentDragState = DragState(card: card, position: position, sourceType: sourceType, stackCards: stack)
    }
    
    func updateDragPosition(_ position: CGPoint) {
        guard let dragState = currentDragState else { return }
        currentDragState = DragState(card: dragState.card, position: position, sourceType: dragState.sourceType, stackCards: dragState.stackCards)
    }
    
    func endDrag() {
        currentDragState = nil
        highlightedDropZone = nil
    }
    
    func handleDrop(at location: CGPoint) -> Bool {
        guard let dragState = currentDragState else { return false }
        
        // Check which drop zone contains the location
        for dropZone in dropZones {
            if dropZone.frame.contains(location) {
                let dragData = DragData(sourceType: dragState.sourceType, card: dragState.card, stackCards: dragState.stackCards)
                return dropZone.handler(dragData)
            }
        }
        
        return false
    }
    
    // MARK: - Drop Zone Registration
    @Published var dropZones: [DropZone] = []
    @Published var highlightedDropZone: String? = nil
    
    struct DropZone {
        let id: String
        let frame: CGRect
        let handler: (DragData) -> Bool
        let canAccept: (DragData) -> Bool
    }
    
    func registerDropZone(id: String, frame: CGRect, canAccept: @escaping (DragData) -> Bool, handler: @escaping (DragData) -> Bool) {
        dropZones.removeAll { $0.id == id }
        dropZones.append(DropZone(id: id, frame: frame, handler: handler, canAccept: canAccept))
    }
    
    func removeDropZone(id: String) {
        dropZones.removeAll { $0.id == id }
    }
    
    func updateDropZoneHighlight(at location: CGPoint) {
        guard let dragState = currentDragState else {
            highlightedDropZone = nil
            return
        }
        
        for dropZone in dropZones {
            if dropZone.frame.contains(location) {
                highlightedDropZone = dropZone.id
                return
            }
        }
        
        highlightedDropZone = nil
    }
    
    func canDropAt(location: CGPoint) -> Bool? {
        guard let dragState = currentDragState else { return nil }
        
        let dragData = DragData(sourceType: dragState.sourceType, card: dragState.card, stackCards: dragState.stackCards)
        
        for dropZone in dropZones {
            if dropZone.frame.contains(location) {
                return dropZone.canAccept(dragData)
            }
        }
        
        return nil
    }
    
    // MARK: - Drag and Drop Methods
    func moveCardFromGrid(from source: (row: Int, col: Int), to target: (row: Int, col: Int)) -> Bool {
        guard grid[source.row][source.col].isUnlocked,
              !grid[source.row][source.col].isEmpty,
              grid[target.row][target.col].isEmpty else { return false }
        
        saveState()
        
        let card = grid[source.row][source.col].stack.removeLast()
        grid[target.row][target.col].stack.append(card)
        grid[target.row][target.col].isUnlocked = true
        
        // Unlock adjacent cells
        if grid[source.row][source.col].isEmpty {
            unlockCellsAbove(row: source.row, col: source.col)
        }
        unlockAdjacentCells(row: source.row, col: source.col)
        unlockAdjacentCells(row: target.row, col: target.col)
        
        moves += 1
        clearSelection()
        return true
    }
    
    func moveCardFromTempSlot(slotIndex: Int, to target: (row: Int, col: Int)) -> Bool {
        guard !tempSlots[slotIndex].isEmpty,
              grid[target.row][target.col].isEmpty else { return false }
        
        saveState()
        
        // Move entire temp slot stack
        let allCards = tempSlots[slotIndex]
        tempSlots[slotIndex] = []
        
        for card in allCards {
            grid[target.row][target.col].stack.append(card)
        }
        
        grid[target.row][target.col].isUnlocked = true
        unlockAdjacentCells(row: target.row, col: target.col)
        
        moves += 1
        clearSelection()
        return true
    }
    
    func moveCardFromCollection(color: CardColor, index: Int, to target: (row: Int, col: Int)) -> Bool {
        guard let collection = collections[color],
              !collection.isEmpty,
              grid[target.row][target.col].isEmpty else { return false }
        
        saveState()
        
        if index == -1 {
            // Move entire collection
            let allNumbers = collections[color]!
            collections[color] = []
            
            for number in allNumbers {
                let card = Card(number: number, color: color)
                grid[target.row][target.col].stack.append(card)
            }
        } else {
            // Move single card (legacy behavior)
            guard index == collection.count - 1 else { return false }
            let number = collections[color]!.removeLast()
            let card = Card(number: number, color: color)
            grid[target.row][target.col].stack.append(card)
        }
        
        grid[target.row][target.col].isUnlocked = true
        unlockAdjacentCells(row: target.row, col: target.col)
        
        moves += 1
        clearSelection()
        return true
    }
    
    func moveCardFromGridToTempSlot(from source: (row: Int, col: Int), slotIndex: Int) -> Bool {
        guard grid[source.row][source.col].isUnlocked,
              let card = grid[source.row][source.col].topCard,
              canAddToTempSlot(card, slotIndex: slotIndex) else {
            showMessage("❌ Card doesn't fit in this stack")
            return false
        }
        
        saveState()
        
        let removedCard = grid[source.row][source.col].stack.removeLast()
        addCardToTempSlot(removedCard, slotIndex: slotIndex)
        
        if grid[source.row][source.col].isEmpty {
            unlockCellsAbove(row: source.row, col: source.col)
        }
        unlockAdjacentCells(row: source.row, col: source.col)
        
        moves += 1
        clearSelection()
        
        return true
    }
    
    func moveCardBetweenTempSlots(from sourceSlot: Int, to targetSlot: Int) -> Bool {
        guard !tempSlots[sourceSlot].isEmpty else {
            showMessage("❌ No cards to move")
            return false
        }
        
        saveState()
        
        // Move entire temp slot stack
        let allCards = tempSlots[sourceSlot]
        tempSlots[sourceSlot] = []
        
        // Check if target slot is empty
        if tempSlots[targetSlot].isEmpty {
            tempSlots[targetSlot] = allCards
        } else {
            // Try to merge stacks (simplified logic)
            tempSlots[targetSlot].append(contentsOf: allCards)
        }
        
        moves += 1
        clearSelection()
        
        return true
    }
    
    func moveCardFromCollectionToTempSlot(color: CardColor, index: Int, slotIndex: Int) -> Bool {
        guard let collection = collections[color],
              !collection.isEmpty else { return false }
        
        saveState()
        
        if index == -1 {
            // Move entire collection
            let allNumbers = collections[color]!
            let allCards = allNumbers.map { Card(number: $0, color: color) }
            
            // Check if target slot is empty
            guard tempSlots[slotIndex].isEmpty else {
                showMessage("❌ Can't move entire collection to occupied slot")
                return false
            }
            
            collections[color] = []
            tempSlots[slotIndex] = allCards
        } else {
            // Move single card (legacy behavior)
            guard index == collection.count - 1 else { return false }
            let number = collection.last!
            let card = Card(number: number, color: color)
            
            guard canAddToTempSlot(card, slotIndex: slotIndex) else {
                showMessage("❌ Card doesn't fit in this stack")
                return false
            }
            
            collections[color]?.removeLast()
            addCardToTempSlot(card, slotIndex: slotIndex)
        }
        
        moves += 1
        clearSelection()
        
        return true
    }
    
    func moveCardFromGridToCollection(from source: (row: Int, col: Int), color: CardColor) -> Bool {
        guard let card = grid[source.row][source.col].topCard,
              card.color == color,
              canAddToCollection(card.number, color: color) else {
            showMessage("❌ Card doesn't fit in collection")
            return false
        }
        
        print("🎯 moveCardFromGridToCollection: \(card.color.rawValue.capitalized) \(card.number)")
        
        saveState()
        
        // Remove card from grid
        grid[source.row][source.col].stack.removeLast()
        
        // Add to collection
        collections[color]?.append(card.number)
        
        // Unlock adjacent cells if grid cell is now empty
        if grid[source.row][source.col].isEmpty {
            unlockAdjacentCells(row: source.row, col: source.col)
        } else {
            // Unlock adjacent cells anyway (from web version behavior)
            unlockAdjacentCells(row: source.row, col: source.col)
        }
        
        moves += 1
        clearSelection()
        
        // Show collection message
        showMessage("✅ Collected \(card.color.rawValue.capitalized) \(card.number)")
        
        checkWinCondition()
        return true
    }
    
    func moveCardFromTempSlotToCollection(slotIndex: Int, color: CardColor) -> Bool {
        guard !tempSlots[slotIndex].isEmpty,
              let card = tempSlots[slotIndex].last,
              card.color == color,
              canAddToCollection(card.number, color: color) else {
            showMessage("❌ Card doesn't fit in collection")
            return false
        }
        
        print("🎯 moveCardFromTempSlotToCollection: \(card.color.rawValue.capitalized) \(card.number)")
        
        saveState()
        
        tempSlots[slotIndex].removeLast()
        collections[color]?.append(card.number)
        
        moves += 1
        clearSelection()
        
        // Show collection message
        showMessage("✅ Collected \(card.color.rawValue.capitalized) \(card.number)")
        
        checkWinCondition()
        return true
    }
} 

// MARK: - Predefined Levels
struct PreDefinedLevel: Codable {
    let seedID: String
    let difficulty: Difficulty
    let gridData: [[[Int]]] // [row][col][cardIndex] -> cardData as [number, colorIndex]
    
    init(seedID: String, difficulty: Difficulty, grid: [[GridCell]]) {
        self.seedID = seedID
        self.difficulty = difficulty
        
        // Convert grid to simple data structure
        var gridData: [[[Int]]] = []
        for row in grid {
            var rowData: [[Int]] = []
            for cell in row {
                var cellData: [Int] = []
                for card in cell.stack {
                    cellData.append(card.number)
                    // Convert color to index (0-4)
                    if let colorIndex = CardColor.allCases.firstIndex(of: card.color) {
                        cellData.append(colorIndex)
                    } else {
                        cellData.append(0) // fallback
                    }
                }
                rowData.append(cellData)
            }
            gridData.append(rowData)
        }
        self.gridData = gridData
    }
    
    func createGrid() -> [[GridCell]] {
        var grid: [[GridCell]] = []
        
        for rowData in gridData {
            var row: [GridCell] = []
            for cellData in rowData {
                var cell = GridCell()
                
                // Parse cards from cellData (pairs of [number, colorIndex])
                for i in stride(from: 0, to: cellData.count, by: 2) {
                    if i + 1 < cellData.count {
                        let number = cellData[i]
                        let colorIndex = cellData[i + 1]
                        let color = CardColor.allCases[colorIndex % CardColor.allCases.count]
                        cell.stack.append(Card(number: number, color: color))
                    }
                }
                
                row.append(cell)
            }
            grid.append(row)
        }
        
        return grid
    }
}

struct LevelDatabase {
    static let shared = LevelDatabase()
    
    private let easyLevels: [PreDefinedLevel]
    private let mediumLevels: [PreDefinedLevel]
    private let hardLevels: [PreDefinedLevel]
    
    private init() {
        // Initialize with generated levels
        self.easyLevels = Self.generateLevels(for: .easy, count: 999)
        self.mediumLevels = Self.generateLevels(for: .medium, count: 999)
        self.hardLevels = Self.generateLevels(for: .hard, count: 999)
    }
    
    func getLevel(difficulty: Difficulty, seedID: String) -> PreDefinedLevel? {
        let levels = getLevels(for: difficulty)
        return levels.first { $0.seedID == seedID }
    }
    
    func getRandomLevel(difficulty: Difficulty) -> PreDefinedLevel {
        let levels = getLevels(for: difficulty)
        return levels.randomElement()!
    }
    
    func getLevels(for difficulty: Difficulty) -> [PreDefinedLevel] {
        switch difficulty {
        case .easy: return easyLevels
        case .medium: return mediumLevels
        case .hard: return hardLevels
        }
    }
    
    private static func generateLevels(for difficulty: Difficulty, count: Int) -> [PreDefinedLevel] {
        var levels: [PreDefinedLevel] = []
        let generator = LevelGenerator()
        
        for i in 1...count {
            let seedID = generateSeedID(difficulty: difficulty, index: i)
            let grid = generator.generateGrid(for: difficulty, seed: i)
            let level = PreDefinedLevel(seedID: seedID, difficulty: difficulty, grid: grid)
            levels.append(level)
        }
        
        return levels
    }
    
    private static func generateSeedID(difficulty: Difficulty, index: Int) -> String {
        let prefix = difficulty.seedPrefix
        return "\(prefix)\(String(format: "%03d", index))"
    }
}

// Helper class for level generation
private class LevelGenerator {
    func generateGrid(for difficulty: Difficulty, seed: Int = 0) -> [[GridCell]] {
        let (rows, cols) = difficulty.gridSize
        var grid = Array(repeating: Array(repeating: GridCell(), count: cols), count: rows)
        
        // Generate all cards
        var allCards: [Card] = []
        for color in CardColor.allCases {
            for number in 1...difficulty.maxNumber {
                allCards.append(Card(number: number, color: color))
            }
        }
        
        // Use seeded random for consistent generation
        var generator = SeededRandomGenerator(seed: seed)
        allCards.shuffle(using: &generator)
        
        // Use existing distribution logic
        var cardIndex = 0
        
        if difficulty == .easy {
            cardIndex = distributeEasyMode(grid: &grid, cards: allCards, rows: rows, cols: cols, generator: &generator)
        } else {
            cardIndex = distributeNormalMode(grid: &grid, cards: allCards, rows: rows, cols: cols, generator: &generator)
        }
        
        // Distribute remaining cards
        distributeRemainingCards(grid: &grid, cards: allCards, from: cardIndex, rows: rows, cols: cols, generator: &generator)
        
        // Validate that all cards are unique (debug check)
        validateGridUniqueness(grid: grid, difficulty: difficulty)
        
        return grid
    }
    
    private func distributeEasyMode(grid: inout [[GridCell]], cards: [Card], rows: Int, cols: Int, generator: inout SeededRandomGenerator) -> Int {
        let positions = generateRandomPositions(rows: rows, cols: cols, generator: &generator)
        var cardIndex = 0
        
        for i in 0..<min(positions.count, cards.count) {
            let (row, col) = positions[i]
            
            if cardIndex < cards.count {
                // Create occasional stacks
                if Int.random(in: 1...100, using: &generator) <= 15 && cardIndex + 1 < cards.count {
                    let stackSize = min(2, cards.count - cardIndex)
                    for _ in 0..<stackSize {
                        grid[row][col].stack.append(cards[cardIndex])
                        cardIndex += 1
                    }
                } else if Int.random(in: 1...100, using: &generator) <= 85 || row == rows - 1 {
                    grid[row][col].stack.append(cards[cardIndex])
                    cardIndex += 1
                }
            }
        }
        
        return cardIndex
    }
    
    private func distributeNormalMode(grid: inout [[GridCell]], cards: [Card], rows: Int, cols: Int, generator: inout SeededRandomGenerator) -> Int {
        var cardIndex = 0
        
        for row in 0..<rows {
            for col in 0..<cols {
                if cardIndex < cards.count {
                    // Create random stacks
                    if Int.random(in: 1...100, using: &generator) <= 30 && cardIndex + 1 < cards.count {
                        let stackSize = min(Int.random(in: 2...4, using: &generator), cards.count - cardIndex)
                        for _ in 0..<stackSize {
                            grid[row][col].stack.append(cards[cardIndex])
                            cardIndex += 1
                        }
                    } else {
                        grid[row][col].stack.append(cards[cardIndex])
                        cardIndex += 1
                    }
                }
            }
        }
        
        return cardIndex
    }
    
    private func distributeRemainingCards(grid: inout [[GridCell]], cards: [Card], from startIndex: Int, rows: Int, cols: Int, generator: inout SeededRandomGenerator) {
        var cardIndex = startIndex
        
        // First pass: try to distribute remaining cards randomly
        var attempts = 0
        while cardIndex < cards.count && attempts < 1000 {
            let row = Int.random(in: 0..<rows, using: &generator)
            let col = Int.random(in: 0..<cols, using: &generator)
            if grid[row][col].stack.count < 5 {
                grid[row][col].stack.append(cards[cardIndex])
                cardIndex += 1
                attempts = 0 // Reset attempts counter
            } else {
                attempts += 1
            }
        }
        
        // Second pass: force distribute any remaining cards
        if cardIndex < cards.count {
            for row in 0..<rows {
                for col in 0..<cols {
                    if cardIndex >= cards.count { break }
                    if grid[row][col].stack.count < 6 { // Allow up to 6 cards per cell if needed
                        grid[row][col].stack.append(cards[cardIndex])
                        cardIndex += 1
                    }
                }
                if cardIndex >= cards.count { break }
            }
        }
    }
    

    private func validateGridUniqueness(grid: [[GridCell]], difficulty: Difficulty) {
        var cardCounts: [String: Int] = [:]
        
        // Count all cards in the grid
        for row in grid {
            for cell in row {
                for card in cell.stack {
                    let key = "\(card.color.rawValue)_\(card.number)"
                    cardCounts[key, default: 0] += 1
                }
            }
        }
        
        // Check for duplicates
        var duplicates: [String] = []
        for (cardKey, count) in cardCounts {
            if count > 1 {
                duplicates.append("\(cardKey) (x\(count))")
            }
        }
        
        if !duplicates.isEmpty {
            print("⚠️ DUPLICATE CARDS FOUND: \(duplicates.joined(separator: ", "))")
        }
        
        // Check if we have the right total number of cards
        let expectedTotal = CardColor.allCases.count * difficulty.maxNumber
        let actualTotal = cardCounts.values.reduce(0, +)
        if actualTotal != expectedTotal {
            print("⚠️ CARD COUNT MISMATCH: Expected \(expectedTotal), got \(actualTotal)")
        }
    }
    
    private func generateRandomPositions(rows: Int, cols: Int, generator: inout SeededRandomGenerator) -> [(Int, Int)] {
        var positions: [(Int, Int)] = []
        for row in 0..<rows {
            for col in 0..<cols {
                positions.append((row, col))
            }
        }
        positions.shuffle(using: &generator)
        return positions
    }
}

extension Difficulty {
    var seedPrefix: String {
        switch self {
        case .easy: return "E"
        case .medium: return "M"
        case .hard: return "H"
        }
    }
}

// Seeded random number generator for consistent level generation
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        self.state = UInt64(seed)
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
} 
