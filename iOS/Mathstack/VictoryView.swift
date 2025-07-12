import SwiftUI

struct VictoryView: View {
    @ObservedObject var gameState: GameState
    let onNewGame: () -> Void
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background with blur effect
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.18).opacity(0.95),
                    Color(red: 0.09, green: 0.13, blue: 0.24).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Victory header
                VStack(spacing: 15) {
                    Text("🎉")
                        .font(.system(size: 60))
                        .rotationEffect(.degrees(victoryAnimation ? 10 : -10))
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: victoryAnimation
                        )
                        .onAppear {
                            victoryAnimation = true
                        }
                    
                    Text("Congratulations!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, Color(red: 0.3, green: 0.8, blue: 0.76), Color(red: 1.0, green: 0.85, blue: 0.59)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Level successfully completed!")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                // Statistics
                VStack(spacing: 15) {
                    StatRow(
                        icon: "⏱️",
                        label: "Time:",
                        value: gameState.formattedTime
                    )
                    
                    StatRow(
                        icon: "🎯",
                        label: "Moves:",
                        value: "\(gameState.moves)"
                    )
                    
                    StatRow(
                        icon: "⭐",
                        label: "Difficulty:",
                        value: getDifficultyName()
                    )
                    
                    Divider()
                        .background(Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.3))
                    
                    StatRow(
                        icon: "🏆",
                        label: "Score:",
                        value: "\(calculateScore())",
                        isHighlighted: true
                    )
                }
                .padding(25)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                        onNewGame()
                    }) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text("New Game")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.8, blue: 0.76), Color(red: 0.18, green: 0.84, blue: 0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.3), radius: 8)
                    }
                    .buttonStyle(VictoryButtonStyle())
                    
                    Button(action: {
                        dismiss()
                        onRestart()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.37, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color(red: 0.65, green: 0.37, blue: 0.92).opacity(0.3), radius: 8)
                    }
                    .buttonStyle(VictoryButtonStyle())
                    
                    Button(action: {
                        dismiss()
                        onMainMenu()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Main Menu")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.4, blue: 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3), radius: 8)
                    }
                    .buttonStyle(VictoryButtonStyle())
                }
            }
            .padding(30)
        }
    }
    
    @State private var victoryAnimation = false
    
    private func getDifficultyName() -> String {
        switch gameState.difficulty {
        case .easy: return "Easy (1-5)"
        case .medium: return "Medium (1-10)"
        case .hard: return "Hard (1-15)"
        }
    }
    
    private func calculateScore() -> Int {
        let baseScore: Int
        let timeBonus: Int
        let movesBonus: Int
        
        switch gameState.difficulty {
        case .easy:
            baseScore = 1000
            timeBonus = max(0, 300 - gameState.timer) * 2
            movesBonus = max(0, 50 - gameState.moves) * 10
        case .medium:
            baseScore = 2500
            timeBonus = max(0, 600 - gameState.timer) * 3
            movesBonus = max(0, 100 - gameState.moves) * 15
        case .hard:
            baseScore = 5000
            timeBonus = max(0, 900 - gameState.timer) * 4
            movesBonus = max(0, 150 - gameState.moves) * 20
        }
        
        return baseScore + timeBonus + movesBonus
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title3)
            
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(
                    isHighlighted ? 
                    Color(red: 1.0, green: 0.85, blue: 0.59) : 
                    .white
                )
        }
    }
}

struct VictoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VictoryView(gameState: {
        let state = GameState()
        state.startNewGame(difficulty: .hard)
        // Simulate some game progress
        return state
    }(), onNewGame: {
        print("New game requested")
    }, onRestart: {
        print("Restart requested")
    }, onMainMenu: {
        print("Main menu requested")
    })
} 