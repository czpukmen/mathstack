//
//  ContentView.swift
//  Mathstack
//
//  Created by Maksim Burak on 02/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showDifficultySelection = true
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .ignoresSafeArea()
            
            if showDifficultySelection {
                DifficultySelectionView { difficulty in
                    gameState.startNewGame(difficulty: difficulty)
                    showDifficultySelection = false
                }
            } else {
                GameView(gameState: gameState, onNewGame: {
                    // On new game
                    showDifficultySelection = true
                }, onExitToMainMenu: {
                    // Exit to main menu (show difficulty selection)
                    showDifficultySelection = true
                })
                .sheet(isPresented: $gameState.showVictory) {
                    VictoryView(gameState: gameState, onNewGame: {
                        // On new game from victory
                        showDifficultySelection = true
                    }, onRestart: {
                        // Restart current level
                        gameState.restartCurrentLevel()
                    }, onMainMenu: {
                        // Go to main menu
                        showDifficultySelection = true
                    })
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
