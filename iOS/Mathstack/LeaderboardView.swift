import SwiftUI

struct LeaderboardView: View {
    @StateObject private var gameDataManager = GameDataManager.shared
    @State private var selectedDifficulty: Difficulty = .easy
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Difficulty Selector
                difficultySelector
                
                // Leaderboard Content
                if gameDataManager.statistics.gameHistory.isEmpty {
                    emptyStateView
                } else {
                    leaderboardList
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("Leaderboard")
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
    private var difficultySelector: some View {
        HStack(spacing: 12) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button(action: {
                    selectedDifficulty = difficulty
                }) {
                    VStack(spacing: 4) {
                        Text(difficulty.emoji)
                            .font(.title2)
                        Text(difficulty.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        backgroundForDifficulty(difficulty)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private func backgroundForDifficulty(_ difficulty: Difficulty) -> some View {
        let isSelected = selectedDifficulty == difficulty
        
        if isSelected {
            RoundedRectangle(cornerRadius: 12)
                .fill(difficulty.color.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(difficulty.color, lineWidth: 2)
                )
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.clear, lineWidth: 2)
                )
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Records Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete games to see your best scores here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var leaderboardList: some View {
        let filteredGames = gameDataManager.statistics.gameHistory
            .filter { $0.difficulty == selectedDifficulty }
            .sorted { $0.score > $1.score }
            .prefix(10)
        
        if filteredGames.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No \(selectedDifficulty.displayName) games yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(filteredGames.enumerated()), id: \.element.id) { index, game in
                        LeaderboardRow(game: game, rank: index + 1)
                    }
                }
                .padding(.top, 20)
            }
        }
    }
}

struct LeaderboardRow: View {
    let game: GameResult
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            VStack {
                if rank <= 3 {
                    Text(rankEmoji)
                        .font(.title2)
                } else {
                    Text("\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 40)
            
            // Game details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Score: \(game.score)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(game.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    Label(game.formattedTime, systemImage: "clock")
                    Label("\(game.moves) moves", systemImage: "move.3d")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Seed ID
                Text("Seed: \(game.seedID)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Score indicator
            VStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 16, height: 16)
                
                Text("\(game.score)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor)
            }
        }
        .padding(16)
                    .background(
                backgroundForRank(rank)
            )
    }
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .clear
        }
    }
    
    private var scoreColor: Color {
        switch game.score {
        case 90...100:
            return .green
        case 70...89:
            return .orange
        case 50...69:
            return .yellow
        default:
            return .red
        }
    }
    
    @ViewBuilder
    private func backgroundForRank(_ rank: Int) -> some View {
        if rank <= 3 {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rankColor.opacity(0.5), lineWidth: 2)
                )
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.clear, lineWidth: 2)
                )
        }
    }
}

#Preview {
    LeaderboardView()
} 