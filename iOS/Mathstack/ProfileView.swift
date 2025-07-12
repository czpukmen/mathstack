import SwiftUI

struct ProfileView: View {
    @StateObject private var gameDataManager = GameDataManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Player Level Section
                    playerLevelSection
                    
                    // Achievements Section
                    achievementsSection
                    
                    // Detailed Statistics
                    statisticsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.18),
                        Color(red: 0.09, green: 0.13, blue: 0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
    
    @ViewBuilder
    private var playerLevelSection: some View {
        VStack(spacing: 16) {
            // Level Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                VStack(spacing: 4) {
                    Text("LVL")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(calculatePlayerLevel())")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 8) {
                Text("Player Level \(calculatePlayerLevel())")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // XP Progress Bar
                VStack(spacing: 4) {
                    HStack {
                        Text("\(gameDataManager.statistics.totalXP) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(calculateXPToNextLevel()) to next level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: calculateLevelProgress())
                        .tint(.blue)
                        .scaleEffect(y: 2)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Achievements")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Achievement.allAchievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: gameDataManager.isAchievementUnlocked(achievement.id)
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ProfileStatRow(title: "Total Games", value: "\(gameDataManager.statistics.totalGamesPlayed)")
                ProfileStatRow(title: "Games Won", value: "\(gameDataManager.statistics.gamesWon)")
                ProfileStatRow(title: "Win Rate", value: "\(Int(gameDataManager.statistics.winRate * 100))%")
                ProfileStatRow(title: "Best Time", value: gameDataManager.statistics.bestTime)
                ProfileStatRow(title: "Average Time", value: gameDataManager.statistics.averageTime)
                ProfileStatRow(title: "Total Score", value: "\(gameDataManager.statistics.totalScore)")
                ProfileStatRow(title: "Perfect Games", value: "\(gameDataManager.statistics.perfectGames)")
                ProfileStatRow(title: "Average Score", value: String(format: "%.1f", gameDataManager.statistics.averageScore))
                ProfileStatRow(title: "Average Moves", value: String(format: "%.1f", gameDataManager.statistics.averageMoves))
                
                // Streak information
                Divider()
                    .padding(.vertical, 8)
                
                Text("Streaks")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ProfileStatRow(title: "Current Win Streak", value: "\(gameDataManager.statistics.streaks.currentWinStreak)")
                ProfileStatRow(title: "Longest Win Streak", value: "\(gameDataManager.statistics.streaks.longestWinStreak)")
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("Difficulty Breakdown")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    let stats = gameDataManager.getStatsFor(difficulty: difficulty)
                    DifficultyStatRow(
                        difficulty: difficulty,
                        gamesPlayed: stats.gamesPlayed,
                        bestTime: stats.bestTimeFormatted,
                        averageScore: Int(stats.averageScore)
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Helper Methods
    private func calculatePlayerLevel() -> Int {
        let totalXP = gameDataManager.statistics.totalXP
        let xpPerLevel = 1000
        return max(1, totalXP / xpPerLevel + 1)
    }
    
    private func calculateXPToNextLevel() -> Int {
        let currentLevel = calculatePlayerLevel()
        let totalXP = gameDataManager.statistics.totalXP
        let xpPerLevel = 1000
        let xpForNextLevel = currentLevel * xpPerLevel
        return max(0, xpForNextLevel - totalXP)
    }
    
    private func calculateLevelProgress() -> Double {
        let currentLevel = calculatePlayerLevel()
        let totalXP = gameDataManager.statistics.totalXP
        let xpPerLevel = 1000
        let xpForCurrentLevel = (currentLevel - 1) * xpPerLevel
        let xpInCurrentLevel = totalXP - xpForCurrentLevel
        return min(1.0, max(0.0, Double(xpInCurrentLevel) / Double(xpPerLevel)))
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? achievement.color : .secondary)
                .frame(height: 24) // Fixed height for icon
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 50) // Minimum height for text area
            
            Spacer(minLength: 0) // Pushes content to top, ensures equal heights
        }
        .padding(12)
        .frame(height: 120) // Increased height to accommodate all text
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isUnlocked ? achievement.color.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct ProfileStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct DifficultyStatRow: View {
    let difficulty: Difficulty
    let gamesPlayed: Int
    let bestTime: String
    let averageScore: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Text(difficulty.emoji)
                        .font(.caption)
                    Text(difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(difficulty.color)
                }
                
                Spacer()
                
                Text("\(gamesPlayed) games")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Best: \(bestTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Avg Score: \(averageScore)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Achievement Model
struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    static let allAchievements: [Achievement] = [
        Achievement(id: "first_win", title: "First Victory", description: "Win your first game", icon: "flag.fill", color: .green),
        Achievement(id: "speed_demon", title: "Speed Demon", description: "Complete a game in under 2 minutes", icon: "bolt.fill", color: .yellow),
        Achievement(id: "perfectionist", title: "Perfectionist", description: "Get a perfect score", icon: "star.fill", color: .purple),
        Achievement(id: "marathon", title: "Marathon", description: "Play 50 games", icon: "figure.run", color: .blue),
        Achievement(id: "hard_master", title: "Hard Master", description: "Win 10 hard games", icon: "crown.fill", color: .orange),
        Achievement(id: "efficient", title: "Efficient", description: "Win with minimal moves", icon: "target", color: .red),
        Achievement(id: "streak_5", title: "On Fire", description: "Win 5 games in a row", icon: "flame.fill", color: .red),
        Achievement(id: "streak_10", title: "Unstoppable", description: "Win 10 games in a row", icon: "flame.circle.fill", color: .orange)
    ]
}

#Preview {
    ProfileView()
} 
