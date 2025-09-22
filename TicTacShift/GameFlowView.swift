//
//  GameFlowView.swift
//  TicTacShift
//
//  Manages the flow from player reveal to game board
//

import SwiftUI

struct GameFlowView: View {
    let gameMode: GameMode
    @State private var showReveal = true
    @State private var game: TicTacShiftGame?
    
    var body: some View {
        Group {
            if let game = game {
                if showReveal {
                    PlayerRevealView(
                        firstPlayer: game.currentPlayer,
                        gameMode: gameMode,
                        botPlayer: game.botPlayer
                    ) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showReveal = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    GameBoardView(game: game)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
            } else {
                ProgressView("Préparation du jeu...")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            createNewGame()
        }
    }
    
    private func createNewGame() {
        game = TicTacShiftGame(gameMode: gameMode)
        showReveal = true
    }
}

#Preview {
    NavigationView {
        GameFlowView(gameMode: .normal)
    }
}