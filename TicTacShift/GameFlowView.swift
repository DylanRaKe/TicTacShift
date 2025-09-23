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
    @State private var animateBackground = false

    var body: some View {
        ZStack {
            NeonBackground(animate: animateBackground)

            Group {
                if let game = game {
                    if showReveal {
                        PlayerRevealView(
                            firstPlayer: game.currentPlayer,
                            gameMode: gameMode,
                            botPlayer: game.botPlayer
                        ) {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                                showReveal = false
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                    } else {
                        GameBoardView(game: game)
                            .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    }
                } else {
                    ProgressView("Mise en place de l'arène...")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, showReveal ? 0 : 16)
        }
        .navigationTitle(gameMode.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black.opacity(0.2), for: .navigationBar)
        .task {
            animateBackground = true
            createNewGame()
        }
    }

    private func createNewGame() {
        game = TicTacShiftGame(gameMode: gameMode)
        showReveal = true
    }
}

private extension GameMode {
    var navTitle: String {
        switch self {
        case .normal:
            return "Duel Local"
        case .bot:
            return "Défi Bot"
        case .versus:
            return "Versus"
        }
    }
}

#Preview {
    NavigationView {
        GameFlowView(gameMode: .normal)
    }
}
