import SwiftUI

struct PauseMenuView: View {
    @Binding var isPresented: Bool
    @ObservedObject var gameState: GameState
    @State private var showingDifficultySelection = false
    @State private var selectedDifficulty: Difficulty = .easy
    
    let onNewGame: (Difficulty) -> Void
    let onRestart: () -> Void
    let onGiveUp: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.18),
                        Color(red: 0.09, green: 0.13, blue: 0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showingDifficultySelection {
                    difficultySelectionView
                } else {
                    pauseMenuView
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if showingDifficultySelection {
                            showingDifficultySelection = false
                        } else {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            gameState.pauseTimer()
        }
        .onDisappear {
            gameState.resumeTimer()
        }
    }
    
    @ViewBuilder
    private var pauseMenuView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Game Paused")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Take a break and choose your next move")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Menu Buttons
            VStack(spacing: 16) {
                PauseMenuButton(
                    title: "Continue",
                    subtitle: "Resume your current game",
                    icon: "play.fill",
                    color: .green,
                    action: {
                        isPresented = false
                    }
                )
                
                PauseMenuButton(
                    title: "New Game",
                    subtitle: "Start a fresh level",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: {
                        showingDifficultySelection = true
                    }
                )
                
                PauseMenuButton(
                    title: "Restart",
                    subtitle: "Retry this same level",
                    icon: "arrow.clockwise",
                    color: .orange,
                    action: {
                        onRestart()
                        isPresented = false
                    }
                )
                
                PauseMenuButton(
                    title: "Give Up",
                    subtitle: "Exit without saving progress",
                    icon: "xmark.circle.fill",
                    color: .red,
                    action: {
                        onGiveUp()
                        isPresented = false
                    }
                )
                
                PauseMenuButton(
                    title: "Main Menu",
                    subtitle: "Save progress and return home",
                    icon: "house.fill",
                    color: .purple,
                    action: {
                        onMainMenu()
                        isPresented = false
                    }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var difficultySelectionView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("New Game")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose difficulty for your new game")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Difficulty Selection
            VStack(spacing: 16) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultySelectionButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        action: {
                            selectedDifficulty = difficulty
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Start Game Button
            Button(action: {
                onNewGame(selectedDifficulty)
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text("Start New Game")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct PauseMenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultySelectionButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(difficulty.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(difficulty.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(difficulty.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(difficulty.color)
                }
            }
            .padding(16)
            .background(
                backgroundForSelection(isSelected: isSelected, difficulty: difficulty)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func backgroundForSelection(isSelected: Bool, difficulty: Difficulty) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 12)
                .fill(difficulty.color.opacity(0.1))
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
}

#Preview {
    PauseMenuView(
        isPresented: .constant(true),
        gameState: GameState(),
        onNewGame: { _ in },
        onRestart: { },
        onGiveUp: { },
        onMainMenu: { }
    )
} 