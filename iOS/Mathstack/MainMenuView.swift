import SwiftUI

struct MainMenuView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(gameState: gameState)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
            
            LeaderboardView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Leaderboard")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(.primary)
    }
}

struct HomeView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var gameDataManager = GameDataManager.shared
    @State private var showingGame = false
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingSeedInput = false
    @State private var showingNewGameConfirmation = false
    @State private var pendingGameAction: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Continue Game Section
                    if gameDataManager.hasSavedGame {
                        continueGameSection
                    }
                    
                    // New Game Section
                    newGameSection
                    
                    // Custom Level Section
                    customLevelSection
                    
                    // Quick Stats
                    quickStatsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Mathstack")
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
        .fullScreenCover(isPresented: $showingGame) {
            GameView(gameState: gameState, onNewGame: {
                // New game callback
                gameState.startNewGame(difficulty: selectedDifficulty)
            }, onExitToMainMenu: {
                // Exit to main menu callback
                showingGame = false
            })
            .sheet(isPresented: $gameState.showVictory) {
                VictoryView(gameState: gameState, onNewGame: {
                    // On new game from victory
                    gameState.startNewGame(difficulty: selectedDifficulty)
                }, onRestart: {
                    // Restart current level
                    gameState.restartCurrentLevel()
                }, onMainMenu: {
                    // Go to main menu
                    showingGame = false
                })
            }
        }
        .sheet(isPresented: $showingSeedInput) {
            SeedInputView(isPresented: $showingSeedInput) { difficulty, seedID in
                selectedDifficulty = difficulty
                gameState.startGameWithSeed(difficulty: difficulty, seedID: seedID)
                showingGame = true
            }
        }
        .alert("Start New Game?", isPresented: $showingNewGameConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingGameAction = nil
            }
            Button("Start New Game", role: .destructive) {
                pendingGameAction?()
                pendingGameAction = nil
            }
        } message: {
            Text("Starting a new game will overwrite your current saved game. Do you want to continue?")
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("icon-512")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .cornerRadius(12)
            
            Text("Ready to solve some puzzles?")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var continueGameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Continue Game")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Button(action: {
                // Load saved game
                if gameState.loadSavedGame() {
                    showingGame = true
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Saved Game")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("Continue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        HStack(spacing: 16) {
                            Label("Continue your progress", systemImage: "arrow.clockwise")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var newGameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("New Game")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    HomeDifficultyButton(
                        difficulty: difficulty,
                        action: {
                            selectedDifficulty = difficulty
                            startNewGameWithConfirmation {
                                gameState.startNewGame(difficulty: difficulty)
                                showingGame = true
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var customLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Custom Level")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Button(action: {
                startNewGameWithConfirmation {
                    showingSeedInput = true
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Play by Seed ID")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("E001-E999, M001-M999, H001-H999")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Text("Enter a specific seed ID to play that exact level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Quick Stats")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Games Played",
                    value: "\(gameDataManager.statistics.totalGamesPlayed)",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Best Time",
                    value: gameDataManager.statistics.bestTime,
                    icon: "stopwatch.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Total Score",
                    value: "\(gameDataManager.statistics.totalScore)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Win Rate",
                    value: "\(Int(gameDataManager.statistics.winRate * 100))%",
                    icon: "target",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func startNewGameWithConfirmation(action: @escaping () -> Void) {
        if gameDataManager.hasSavedGame {
            pendingGameAction = {
                // Record saved game as abandoned before starting new game
                if let saveData = gameDataManager.loadGame() {
                    gameDataManager.recordGameAbandoned(difficulty: saveData.difficulty)
                }
                gameDataManager.deleteSavedGame()
                action()
            }
            showingNewGameConfirmation = true
        } else {
            action()
        }
    }
}

struct HomeDifficultyButton: View {
    let difficulty: Difficulty
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(difficulty.emoji)
                            .font(.title2)
                        
                        Text(difficulty.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text(difficulty.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MainMenuView()
} 