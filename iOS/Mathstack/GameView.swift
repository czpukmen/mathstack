import SwiftUI

struct GameView: View {
    @ObservedObject var gameState: GameState
    let onNewGame: () -> Void
    let onExitToMainMenu: () -> Void
    
    @State private var showPauseMenu = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with title, stats, and menu
                HeaderView(
                    gameState: gameState,
                    showPauseMenu: $showPauseMenu
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .zIndex(10) // Header should be above game elements
                
                // Main game area - unified container
                VStack(spacing: 0) {
                    // Collections at the top
                    CollectionsView(gameState: gameState)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .zIndex(5) // Collections above game grid
                    
                    // Game Grid in the center
                    GameGridView(gameState: gameState)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .zIndex(1) // Base layer for game grid
                    
                    // Temp Slots
                    TempSlotsView(gameState: gameState)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .zIndex(5) // Temp slots above game grid but below dragged cards
                    
                    // Controls at the bottom
                    ControlsView(gameState: gameState)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .zIndex(5) // Controls above game grid
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.08, green: 0.11, blue: 0.22))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 8)
                .padding(.top, 16)
                .zIndex(0) // Main container base layer
                
                Spacer()
            }
        }
        .overlay(
            // Message overlay
            MessageOverlay(gameState: gameState),
            alignment: .top
        )
        .overlay(
            // Global drag overlay - ensures dragged cards appear above everything
            DragOverlay(gameState: gameState),
            alignment: .topLeading
        )
        .zIndex(2000) // Message overlay should be above everything
        .sheet(isPresented: $gameState.showHowToPlay) {
            HowToPlayView()
        }
        .fullScreenCover(isPresented: $showPauseMenu) {
            PauseMenuView(
                isPresented: $showPauseMenu,
                gameState: gameState,
                onNewGame: { difficulty in
                    gameState.startNewGameFromPause(difficulty: difficulty)
                },
                onRestart: {
                    gameState.restartCurrentLevel()
                },
                onGiveUp: {
                    gameState.giveUpGame()
                    onExitToMainMenu()
                },
                onMainMenu: {
                    gameState.saveAndExitGame()
                    onExitToMainMenu()
                }
            )
        }
        .onChange(of: showPauseMenu) { isShowing in
            if isShowing {
                gameState.pauseTimer()
            } else {
                gameState.resumeTimer()
            }
        }
        .onChange(of: gameState.showHowToPlay) { isShowing in
            if isShowing {
                gameState.pauseTimer()
            } else {
                gameState.resumeTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App is going to background or being interrupted
            if !showPauseMenu && !gameState.showHowToPlay && !gameState.gameWon {
                showPauseMenu = true
            }
        }
    }
}

struct HeaderView: View {
    @ObservedObject var gameState: GameState
    @Binding var showPauseMenu: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            // Timer indicator
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                VStack(spacing: 1) {
                    Text("TIME")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Text(gameState.formattedTime)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            .frame(width: 80, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Level Seed ID
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                VStack(spacing: 1) {
                    Text("LEVEL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Text(gameState.currentSeedID)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            .frame(width: 80, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Moves indicator
            HStack(spacing: 8) {
                Image(systemName: "move.3d")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                VStack(spacing: 1) {
                    Text("MOVES")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Text("\(gameState.moves)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            .frame(width: 80, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Menu button
            Button(action: { showPauseMenu = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
        }
    }
}



struct MessageOverlay: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        if gameState.showMessage {
            Text(gameState.message)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.9))
                        .shadow(radius: 8)
                )
                .padding(.top, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: gameState.showMessage)
        }
    }
}

struct DragOverlay: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        // This overlay will show dragged cards above all other UI elements
        ZStack {
            // Transparent background to capture the full screen area
            Color.clear
            
            // Show dragged card if there's an active drag
            if let dragState = gameState.currentDragState {
                DragPreview(dragState: dragState)
                    .position(dragState.position)
                    .allowsHitTesting(false) // Don't interfere with drop zones
            }
        }
    }
}

struct DragPreview: View {
    let dragState: GameState.DragState
    @State private var appeared = false
    
    var body: some View {
        Group {
            if dragState.stackCards.count == 1 {
                // Single card preview
                singleCardPreview
            } else {
                // Horizontal stack preview
                horizontalStackPreview
            }
        }
        .scaleEffect(appeared ? 1.15 : 0.8)
        .opacity(appeared ? 0.85 : 0.3)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appeared)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }
    
    @ViewBuilder
    private var singleCardPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(dragState.card.color.uiColor)
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                .frame(width: 50, height: 50)
            
            Text("\(dragState.card.number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var horizontalStackPreview: some View {
        let stackCount = dragState.stackCards.count
        let visibleCards = min(stackCount, 3) // Maximum 3 cards visible
        let cardColor = dragState.card.color
        
        HStack(spacing: 0.5) {
            // Visual representation of horizontally stacked cards
            ForEach(0..<visibleCards, id: \.self) { index in
                ZStack {
                    // Card background
                    HStack(spacing: 0) {
                        // Left edge
                        Rectangle()
                            .fill(cardColor.uiColor.opacity(0.8))
                            .frame(width: 1, height: 45)
                        
                        // Card body
                        Rectangle()
                            .fill(cardColor.uiColor.opacity(0.9 - Double(index) * 0.08))
                            .frame(width: 32, height: 45)
                        
                        // Right edge
                        Rectangle()
                            .fill(cardColor.uiColor.opacity(0.6))
                            .frame(width: 1, height: 45)
                    }
                    .cornerRadius(8)
                    
                    // Card number or dots
                    if stackCount > 3 && index == 1 {
                        // Show dots on middle card if more than 3 cards
                        Text("...")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1)
                    } else {
                        // Show card number
                        let cardIndex = stackCount > 3 ? (index == 0 ? 0 : stackCount - 1) : index
                        Text("\(dragState.stackCards[cardIndex].number)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1)
                    }
                }
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                .offset(x: CGFloat(index) * 2, y: CGFloat(index) * 0.5)
                .zIndex(Double(visibleCards - index))
            }
        }
        .frame(height: 45)
    }
}



#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.18),
                Color(red: 0.09, green: 0.13, blue: 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        GameView(gameState: {
            let state = GameState()
            state.startNewGame(difficulty: .hard)
            return state
        }(), onNewGame: {
            print("New game")
        }, onExitToMainMenu: {
            print("Exit to main menu")
        })
    }
} 