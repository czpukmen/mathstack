import SwiftUI
import Foundation

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    // MARK: - Published Properties
    @Published var playerLevel: Int = 1
    @Published var currentXP: Int = 0
    @Published var totalGamesPlayed: Int = 0
    @Published var gamesWon: Int = 0
    @Published var totalScore: Int = 0
    @Published var gameHistory: [GameResult] = []
    @Published var unlockedAchievements: Set<String> = []
    
    // Current game state
    @Published var hasCurrentGame: Bool = false
    @Published var currentGameDifficulty: Difficulty?
    @Published var currentGameSeedID: String?
    @Published var currentGameTime: String = "00:00"
    @Published var currentGameMoves: Int = 0
    
    // MARK: - Constants
    private let maxHistoryItems = 50
    private let xpPerLevel = 1000
    
    private init() {
        loadProfile()
    }
    
    // MARK: - Computed Properties
    var winRate: Double {
        guard totalGamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(totalGamesPlayed)
    }
    
    var bestTime: String {
        guard !gameHistory.isEmpty else { return "--:--" }
        let bestSeconds = gameHistory.map { $0.timeInSeconds }.min() ?? 0
        return formatTime(bestSeconds)
    }
    
    var averageTime: String {
        guard !gameHistory.isEmpty else { return "--:--" }
        let avgSeconds = gameHistory.map { $0.timeInSeconds }.reduce(0, +) / gameHistory.count
        return formatTime(avgSeconds)
    }
    
    var perfectGames: Int {
        gameHistory.filter { $0.score >= 95 }.count
    }
    
    var xpToNextLevel: Int {
        let xpForCurrentLevel = (playerLevel - 1) * xpPerLevel
        let xpForNextLevel = playerLevel * xpPerLevel
        return xpForNextLevel - currentXP
    }
    
    var levelProgress: Double {
        let xpForCurrentLevel = (playerLevel - 1) * xpPerLevel
        let xpInCurrentLevel = currentXP - xpForCurrentLevel
        return Double(xpInCurrentLevel) / Double(xpPerLevel)
    }
    
    // MARK: - Game Management
    func startGame(difficulty: Difficulty, seedID: String) {
        hasCurrentGame = true
        currentGameDifficulty = difficulty
        currentGameSeedID = seedID
        currentGameTime = "00:00"
        currentGameMoves = 0
        saveProfile()
    }
    
    func updateCurrentGame(time: String, moves: Int) {
        currentGameTime = time
        currentGameMoves = moves
    }
    
    func finishGame(difficulty: Difficulty, seedID: String, timeInSeconds: Int, moves: Int) {
        let score = calculateScore(difficulty: difficulty, timeInSeconds: timeInSeconds, moves: moves)
        let gameResult = GameResult(
            id: UUID().uuidString,
            difficulty: difficulty,
            seedID: seedID,
            timeInSeconds: timeInSeconds,
            moves: moves,
            score: score,
            date: Date()
        )
        
        // Add to history
        gameHistory.insert(gameResult, at: 0)
        if gameHistory.count > maxHistoryItems {
            gameHistory.removeLast()
        }
        
        // Update stats
        totalGamesPlayed += 1
        gamesWon += 1 // Assuming only completed games are tracked
        totalScore += score
        
        // Award XP
        let xpGained = calculateXP(difficulty: difficulty, score: score)
        addXP(xpGained)
        
        // Check achievements
        checkAchievements(gameResult: gameResult)
        
        // Clear current game
        hasCurrentGame = false
        currentGameDifficulty = nil
        currentGameSeedID = nil
        
        saveProfile()
    }
    
    // MARK: - XP and Leveling
    private func addXP(_ amount: Int) {
        currentXP += amount
        
        // Check for level up
        while currentXP >= playerLevel * xpPerLevel {
            playerLevel += 1
        }
    }
    
    private func calculateXP(difficulty: Difficulty, score: Int) -> Int {
        let baseXP = switch difficulty {
        case .easy: 50
        case .medium: 75
        case .hard: 100
        }
        
        let multiplier = Double(score) / 100.0
        return Int(Double(baseXP) * multiplier)
    }
    
    // MARK: - Score Calculation
    private func calculateScore(difficulty: Difficulty, timeInSeconds: Int, moves: Int) -> Int {
        let baseScore = switch difficulty {
        case .easy: 60
        case .medium: 70
        case .hard: 80
        }
        
        // Time bonus (faster = better)
        let idealTime = switch difficulty {
        case .easy: 120    // 2 minutes
        case .medium: 180  // 3 minutes
        case .hard: 300    // 5 minutes
        }
        
        let timeBonus = max(0, (idealTime - timeInSeconds) / 10)
        
        // Move penalty (fewer moves = better)
        let idealMoves = switch difficulty {
        case .easy: 30
        case .medium: 50
        case .hard: 80
        }
        
        let movePenalty = max(0, (moves - idealMoves) / 5)
        
        let finalScore = baseScore + timeBonus - movePenalty
        return max(0, min(100, finalScore))
    }
    
    // MARK: - Achievements
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        unlockedAchievements.contains(achievementId)
    }
    
    private func checkAchievements(gameResult: GameResult) {
        // First Victory
        if !isAchievementUnlocked("first_win") && gamesWon == 1 {
            unlockAchievement("first_win")
        }
        
        // Speed Demon
        if !isAchievementUnlocked("speed_demon") && gameResult.timeInSeconds < 120 {
            unlockAchievement("speed_demon")
        }
        
        // Perfectionist
        if !isAchievementUnlocked("perfectionist") && gameResult.score >= 95 {
            unlockAchievement("perfectionist")
        }
        
        // Marathon
        if !isAchievementUnlocked("marathon") && totalGamesPlayed >= 50 {
            unlockAchievement("marathon")
        }
        
        // Hard Master
        let hardWins = gameHistory.filter { $0.difficulty == .hard }.count
        if !isAchievementUnlocked("hard_master") && hardWins >= 10 {
            unlockAchievement("hard_master")
        }
        
        // Efficient
        let idealMoves = switch gameResult.difficulty {
        case .easy: 25
        case .medium: 40
        case .hard: 60
        }
        if !isAchievementUnlocked("efficient") && gameResult.moves <= idealMoves {
            unlockAchievement("efficient")
        }
    }
    
    private func unlockAchievement(_ achievementId: String) {
        unlockedAchievements.insert(achievementId)
        // TODO: Show achievement notification
    }
    
    // MARK: - Statistics by Difficulty
    func getStatsFor(difficulty: Difficulty) -> DifficultyStats {
        let difficultyGames = gameHistory.filter { $0.difficulty == difficulty }
        
        let gamesPlayed = difficultyGames.count
        let bestTimeSeconds = difficultyGames.map { $0.timeInSeconds }.min() ?? 0
        let bestTime = gamesPlayed > 0 ? formatTime(bestTimeSeconds) : "--:--"
        let averageScore = gamesPlayed > 0 ? difficultyGames.map { $0.score }.reduce(0, +) / gamesPlayed : 0
        
        return DifficultyStats(
            gamesPlayed: gamesPlayed,
            bestTime: bestTime,
            averageScore: averageScore
        )
    }
    
    // MARK: - Persistence
    private func saveProfile() {
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(ProfileData(from: self)) {
            UserDefaults.standard.set(encoded, forKey: "PlayerProfile")
        }
    }
    
    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: "PlayerProfile"),
              let profileData = try? JSONDecoder().decode(ProfileData.self, from: data) else {
            return
        }
        
        self.playerLevel = profileData.playerLevel
        self.currentXP = profileData.currentXP
        self.totalGamesPlayed = profileData.totalGamesPlayed
        self.gamesWon = profileData.gamesWon
        self.totalScore = profileData.totalScore
        self.gameHistory = profileData.gameHistory
        self.unlockedAchievements = Set(profileData.unlockedAchievements)
        self.hasCurrentGame = profileData.hasCurrentGame
        self.currentGameDifficulty = profileData.currentGameDifficulty
        self.currentGameSeedID = profileData.currentGameSeedID
        self.currentGameTime = profileData.currentGameTime
        self.currentGameMoves = profileData.currentGameMoves
    }
    
    // MARK: - Utility
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Data Models
struct GameResult: Identifiable, Codable {
    let id: String
    let difficulty: Difficulty
    let seedID: String
    let timeInSeconds: Int
    let moves: Int
    let score: Int
    let date: Date
    
    var formattedTime: String {
        let minutes = timeInSeconds / 60
        let seconds = timeInSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DifficultyStats {
    let gamesPlayed: Int
    let bestTime: String
    let averageScore: Int
}

private struct ProfileData: Codable {
    let playerLevel: Int
    let currentXP: Int
    let totalGamesPlayed: Int
    let gamesWon: Int
    let totalScore: Int
    let gameHistory: [GameResult]
    let unlockedAchievements: [String]
    let hasCurrentGame: Bool
    let currentGameDifficulty: Difficulty?
    let currentGameSeedID: String?
    let currentGameTime: String
    let currentGameMoves: Int
    
    init(from manager: ProfileManager) {
        self.playerLevel = manager.playerLevel
        self.currentXP = manager.currentXP
        self.totalGamesPlayed = manager.totalGamesPlayed
        self.gamesWon = manager.gamesWon
        self.totalScore = manager.totalScore
        self.gameHistory = manager.gameHistory
        self.unlockedAchievements = Array(manager.unlockedAchievements)
        self.hasCurrentGame = manager.hasCurrentGame
        self.currentGameDifficulty = manager.currentGameDifficulty
        self.currentGameSeedID = manager.currentGameSeedID
        self.currentGameTime = manager.currentGameTime
        self.currentGameMoves = manager.currentGameMoves
    }
} 