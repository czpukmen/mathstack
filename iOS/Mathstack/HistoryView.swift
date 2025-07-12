import SwiftUI

struct HistoryView: View {
    @StateObject private var gameDataManager = GameDataManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if gameDataManager.statistics.gameHistory.isEmpty {
                    emptyStateView
                } else {
                    gameHistoryList
                }
            }
            .navigationTitle("Game History")
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
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Games Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first game to see your history here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var gameHistoryList: some View {
        List {
            ForEach(gameDataManager.statistics.gameHistory) { game in
                GameHistoryRow(game: game)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
}

struct GameHistoryRow: View {
    let game: GameResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Difficulty indicator
            VStack(spacing: 4) {
                Text(game.difficulty.emoji)
                    .font(.title2)
                
                Text(game.difficulty.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
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
            VStack(spacing: 2) {
                Circle()
                    .fill(scoreColor(for: game.score))
                    .frame(width: 16, height: 16)
                
                Text("\(game.score)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor(for: game.score))
            }
            .frame(width: 30, alignment: .center)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
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
}

#Preview {
    HistoryView()
} 