import SwiftUI
import Foundation

// MARK: - Game Save Data Models
struct GameSaveData: Codable {
    let difficulty: Difficulty
    let seedID: String
    let grid: [[[Int]]] // [row][col][cardIndex] -> [number, colorIndex]
    let collections: [String: [Int]] // color.rawValue -> numbers
    let tempSlots: [[GameCard]] // temp slots with cards
    let moves: Int
    let timeInSeconds: Int
    let startTime: Date
    let pausedTime: TimeInterval
    let isPaused: Bool
    let history: [GameSnapshot]
    
    struct GameCard: Codable {
        let number: Int
        let colorIndex: Int
        
        init(from card: Card) {
            self.number = card.number
            self.colorIndex = CardColor.allCases.firstIndex(of: card.color) ?? 0
        }
        
        var card: Card {
            let color = CardColor.allCases[colorIndex % CardColor.allCases.count]
            return Card(number: number, color: color)
        }
    }
    
    struct GameSnapshot: Codable {
        let grid: [[[Int]]]
        let collections: [String: [Int]]
        let tempSlots: [[GameCard]]
        let moves: Int
    }
    
    init(from gameState: GameState) {
        self.difficulty = gameState.difficulty
        self.seedID = gameState.currentSeedID
        self.moves = gameState.moves
        self.timeInSeconds = gameState.timer
        self.startTime = Date() // We'll need to track this in GameState
        self.pausedTime = 0 // We'll need to track this in GameState
        self.isPaused = gameState.isPaused
        
        // Convert grid
        var gridData: [[[Int]]] = []
        for row in gameState.grid {
            var rowData: [[Int]] = []
            for cell in row {
                var cellData: [Int] = []
                for card in cell.stack {
                    cellData.append(card.number)
                    cellData.append(CardColor.allCases.firstIndex(of: card.color) ?? 0)
                }
                rowData.append(cellData)
            }
            gridData.append(rowData)
        }
        self.grid = gridData
        
        // Convert collections
        var collectionsData: [String: [Int]] = [:]
        for (color, numbers) in gameState.collections {
            collectionsData[color.rawValue] = numbers
        }
        self.collections = collectionsData
        
        // Convert temp slots
        var tempSlotsData: [[GameCard]] = []
        for slot in gameState.tempSlots {
            let slotData = slot.map { GameCard(from: $0) }
            tempSlotsData.append(slotData)
        }
        self.tempSlots = tempSlotsData
        
        // Convert history (we'll need to add this to GameState)
        self.history = []
    }
}

// MARK: - Enhanced Game Statistics
struct GameStatistics: Codable {
    var totalGamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalScore: Int = 0
    var totalXP: Int = 0 // Separate XP for player level
    var totalTimeInSeconds: Int = 0
    var totalMoves: Int = 0
    var gameHistory: [GameResult] = []
    var difficultyStats: [String: DifficultyStatistics] = [:]
    var streaks: StreakData = StreakData()
    var achievements: Set<String> = []
    
    // Computed properties
    var winRate: Double {
        guard totalGamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(totalGamesPlayed)
    }
    
    var averageScore: Double {
        guard gamesWon > 0 else { return 0.0 }
        return Double(totalScore) / Double(gamesWon)
    }
    
    var averageTime: String {
        guard gamesWon > 0 else { return "--:--" }
        let avgSeconds = totalTimeInSeconds / gamesWon
        return formatTime(avgSeconds)
    }
    
    var bestTime: String {
        guard !gameHistory.isEmpty else { return "--:--" }
        let bestSeconds = gameHistory.map { $0.timeInSeconds }.min() ?? 0
        return formatTime(bestSeconds)
    }
    
    var averageMoves: Double {
        guard gamesWon > 0 else { return 0.0 }
        return Double(totalMoves) / Double(gamesWon)
    }
    
    var perfectGames: Int {
        gameHistory.filter { $0.score >= 95 }.count
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct DifficultyStatistics: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalScore: Int = 0
    var totalTimeInSeconds: Int = 0
    var totalMoves: Int = 0
    var bestTime: Int = Int.max
    var bestScore: Int = 0
    var bestMoves: Int = Int.max
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
    
    var averageScore: Double {
        guard gamesWon > 0 else { return 0.0 }
        return Double(totalScore) / Double(gamesWon)
    }
    
    var averageTime: String {
        guard gamesWon > 0 else { return "--:--" }
        let avgSeconds = totalTimeInSeconds / gamesWon
        let minutes = avgSeconds / 60
        let seconds = avgSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var bestTimeFormatted: String {
        guard bestTime != Int.max else { return "--:--" }
        let minutes = bestTime / 60
        let seconds = bestTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var averageMoves: Double {
        guard gamesWon > 0 else { return 0.0 }
        return Double(totalMoves) / Double(gamesWon)
    }
}

struct StreakData: Codable {
    var currentWinStreak: Int = 0
    var longestWinStreak: Int = 0
    var currentLossStreak: Int = 0
    var longestLossStreak: Int = 0
    var lastGameWon: Bool = false
    
    mutating func recordWin() {
        if lastGameWon {
            currentWinStreak += 1
        } else {
            currentWinStreak = 1
            currentLossStreak = 0
        }
        longestWinStreak = max(longestWinStreak, currentWinStreak)
        lastGameWon = true
    }
    
    mutating func recordLoss() {
        if !lastGameWon {
            currentLossStreak += 1
        } else {
            currentLossStreak = 1
            currentWinStreak = 0
        }
        longestLossStreak = max(longestLossStreak, currentLossStreak)
        lastGameWon = false
    }
}

// MARK: - Game Data Manager
class GameDataManager: ObservableObject {
    static let shared = GameDataManager()
    
    @Published var statistics = GameStatistics()
    @Published var hasSavedGame = false
    
    private let savedGameKey = "SavedGame"
    private let statisticsKey = "GameStatistics"
    
    private init() {
        loadStatistics()
        checkForSavedGame()
    }
    
    // MARK: - Game Save/Load
    func saveGame(_ gameState: GameState) {
        let saveData = GameSaveData(from: gameState)
        
        if let encoded = try? JSONEncoder().encode(saveData) {
            UserDefaults.standard.set(encoded, forKey: savedGameKey)
            hasSavedGame = true
            print("✅ Game saved successfully")
        } else {
            print("❌ Failed to save game")
        }
    }
    
    func loadGame() -> GameSaveData? {
        guard let data = UserDefaults.standard.data(forKey: savedGameKey),
              let saveData = try? JSONDecoder().decode(GameSaveData.self, from: data) else {
            return nil
        }
        
        return saveData
    }
    
    func deleteSavedGame() {
        UserDefaults.standard.removeObject(forKey: savedGameKey)
        hasSavedGame = false
        print("🗑️ Saved game deleted")
    }
    
    private func checkForSavedGame() {
        hasSavedGame = UserDefaults.standard.data(forKey: savedGameKey) != nil
    }
    
    // MARK: - Statistics Management
    func recordGameResult(_ result: GameResult) {
        // Update general statistics
        statistics.totalGamesPlayed += 1
        statistics.gamesWon += 1 // Assuming only completed games are recorded
        statistics.totalScore += result.score
        
        // Calculate and add XP separately
        let xpGained = calculateXP(difficulty: result.difficulty, score: result.score)
        statistics.totalXP += xpGained
        
        statistics.totalTimeInSeconds += result.timeInSeconds
        statistics.totalMoves += result.moves
        
        // Add to history
        statistics.gameHistory.insert(result, at: 0)
        if statistics.gameHistory.count > 100 { // Keep last 100 games
            statistics.gameHistory.removeLast()
        }
        
        // Update difficulty-specific statistics
        let difficultyKey = result.difficulty.stringValue
        if statistics.difficultyStats[difficultyKey] == nil {
            statistics.difficultyStats[difficultyKey] = DifficultyStatistics()
        }
        
        var diffStats = statistics.difficultyStats[difficultyKey]!
        diffStats.gamesPlayed += 1
        diffStats.gamesWon += 1
        diffStats.totalScore += result.score
        diffStats.totalTimeInSeconds += result.timeInSeconds
        diffStats.totalMoves += result.moves
        diffStats.bestTime = min(diffStats.bestTime, result.timeInSeconds)
        diffStats.bestScore = max(diffStats.bestScore, result.score)
        diffStats.bestMoves = min(diffStats.bestMoves, result.moves)
        statistics.difficultyStats[difficultyKey] = diffStats
        
        // Update streaks
        statistics.streaks.recordWin()
        
        // Check achievements
        checkAchievements(result)
        
        // Save statistics
        saveStatistics()
        
        print("📊 Game result recorded: \(result.difficulty.displayName) - Score: \(result.score) - Time: \(result.formattedTime)")
    }
    
    func recordGameAbandoned(difficulty: Difficulty) {
        statistics.totalGamesPlayed += 1
        statistics.streaks.recordLoss()
        
        // Update difficulty-specific statistics
        let difficultyKey = difficulty.stringValue
        if statistics.difficultyStats[difficultyKey] == nil {
            statistics.difficultyStats[difficultyKey] = DifficultyStatistics()
        }
        
        var diffStats = statistics.difficultyStats[difficultyKey]!
        diffStats.gamesPlayed += 1
        statistics.difficultyStats[difficultyKey] = diffStats
        
        saveStatistics()
        
        print("📊 Game abandoned: \(difficulty.displayName)")
    }
    
    func recordGameGivenUp(difficulty: Difficulty) {
        // Same as abandoned but with different logging
        recordGameAbandoned(difficulty: difficulty)
        print("📊 Game given up: \(difficulty.displayName)")
    }
    
    // MARK: - XP Calculation
    private func calculateXP(difficulty: Difficulty, score: Int) -> Int {
        let baseXP = switch difficulty {
        case .easy: 50
        case .medium: 75
        case .hard: 100
        }
        
        // Normalize score to 0-100 range for XP calculation
        let normalizedScore = switch difficulty {
        case .easy: min(100, max(0, (score - 1000) / 10 + 60))
        case .medium: min(100, max(0, (score - 1500) / 15 + 70))
        case .hard: min(100, max(0, (score - 2000) / 20 + 80))
        }
        
        let multiplier = Double(normalizedScore) / 100.0
        return Int(Double(baseXP) * multiplier)
    }
    
    // MARK: - Achievements
    private func checkAchievements(_ result: GameResult) {
        // First Victory
        if !statistics.achievements.contains("first_win") && statistics.gamesWon == 1 {
            unlockAchievement("first_win")
        }
        
        // Speed Demon
        if !statistics.achievements.contains("speed_demon") && result.timeInSeconds < 120 {
            unlockAchievement("speed_demon")
        }
        
        // Perfectionist
        if !statistics.achievements.contains("perfectionist") && result.score >= 95 {
            unlockAchievement("perfectionist")
        }
        
        // Marathon
        if !statistics.achievements.contains("marathon") && statistics.totalGamesPlayed >= 50 {
            unlockAchievement("marathon")
        }
        
        // Hard Master
        let hardStats = statistics.difficultyStats["hard"]
        if !statistics.achievements.contains("hard_master") && (hardStats?.gamesWon ?? 0) >= 10 {
            unlockAchievement("hard_master")
        }
        
        // Efficient
        let idealMoves = switch result.difficulty {
        case .easy: 25
        case .medium: 40
        case .hard: 60
        }
        if !statistics.achievements.contains("efficient") && result.moves <= idealMoves {
            unlockAchievement("efficient")
        }
        
        // Streak achievements
        if !statistics.achievements.contains("streak_5") && statistics.streaks.currentWinStreak >= 5 {
            unlockAchievement("streak_5")
        }
        
        if !statistics.achievements.contains("streak_10") && statistics.streaks.currentWinStreak >= 10 {
            unlockAchievement("streak_10")
        }
    }
    
    private func unlockAchievement(_ achievementId: String) {
        statistics.achievements.insert(achievementId)
        print("🏆 Achievement unlocked: \(achievementId)")
        // TODO: Show achievement notification
    }
    
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        statistics.achievements.contains(achievementId)
    }
    
    // MARK: - Persistence
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: statisticsKey)
        }
    }
    
    private func loadStatistics() {
        guard let data = UserDefaults.standard.data(forKey: statisticsKey),
              let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) else {
            return
        }
        
        statistics = stats
    }
    
    // MARK: - Utility Methods
    func getStatsFor(difficulty: Difficulty) -> DifficultyStatistics {
        return statistics.difficultyStats[difficulty.stringValue] ?? DifficultyStatistics()
    }
    
    func resetAllData() {
        statistics = GameStatistics()
        deleteSavedGame()
        UserDefaults.standard.removeObject(forKey: statisticsKey)
        print("🔄 All game data reset")
    }
}

// MARK: - Extensions
extension Difficulty {
    var stringValue: String {
        switch self {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        }
    }
} 