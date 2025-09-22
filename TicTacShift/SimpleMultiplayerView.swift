//
//  SimpleMultiplayerView.swift
//  TicTacShift
//
//  Simple multiplayer implementation
//

import SwiftUI

struct SimpleMultiplayerView: View {
    @StateObject private var viewModel = SimpleMultiplayerViewModel()
    @State private var selectedTab: Tab = .create
    
    enum Tab {
        case create, join
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Multijoueur Simple")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("État: \(stateText)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            switch viewModel.state {
            case .idle:
                idleView
            case .hosting(let code):
                hostingView(code: code)
            case .browsing:
                browsingView
            case .connecting:
                connectingView
            case .connected:
                connectedView
            case .inGame:
                gameView
            case .error(let message):
                errorView(message: message)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Mode En Ligne")
    }
    
    private var stateText: String {
        switch viewModel.state {
        case .idle: return "Prêt"
        case .hosting: return "Hébergement"
        case .browsing: return "Recherche"
        case .connecting: return "Connexion"
        case .connected: return "Connecté"
        case .inGame: return "En jeu"
        case .error: return "Erreur"
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Créer une partie")
                    .font(.headline)
                
                Button("Héberger une partie") {
                    viewModel.createGame()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            VStack(spacing: 16) {
                Text("Rejoindre une partie")
                    .font(.headline)
                
                Button("Rechercher des parties") {
                    viewModel.startBrowsing()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func hostingView(code: String) -> some View {
        VStack(spacing: 20) {
            Text("En attente d'un joueur...")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Text("Code de la partie:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Text("Partagez ce code avec votre adversaire")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Annuler") {
                viewModel.cancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var browsingView: some View {
        VStack(spacing: 20) {
            Text("Recherche de parties...")
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.availablePeers.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Aucune partie trouvée")
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 12) {
                    Text("Parties disponibles:")
                        .font(.headline)
                    
                    ForEach(viewModel.availablePeers, id: \.self) { peer in
                        Button(peer) {
                            viewModel.joinGame(peerName: peer)
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Button("Annuler") {
                viewModel.cancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var connectingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Connexion en cours...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button("Annuler") {
                viewModel.cancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var connectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Connecté!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Lancement de la partie...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var gameView: some View {
        VStack(spacing: 20) {
            Text("Partie en cours")
                .font(.title2)
                .fontWeight(.bold)
            
            if let game = viewModel.game {
                Text("Vous jouez: \(viewModel.isHost ? "X" : "O")")
                    .font(.headline)
                    .foregroundColor(viewModel.isHost ? .blue : .red)
                
                Text("Tour de: \(game.currentPlayer == .x ? "X" : "O")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Simple game board representation
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                    ForEach(0..<9, id: \.self) { index in
                        let row = index / 3
                        let column = index % 3
                        
                        Button {
                            viewModel.makeMove(at: row, column: column)
                        } label: {
                            Text(getCellText(game: game, row: row, column: column))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .disabled(!game.canPlaceMove(at: row, column: column) || 
                                 game.currentPlayer != (viewModel.isHost ? .x : .o))
                    }
                }
            } else {
                Text("Chargement du jeu...")
                    .foregroundColor(.secondary)
            }
            
            Button("Quitter") {
                viewModel.disconnect()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Erreur")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Réessayer") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func getCellText(game: TicTacShiftGame, row: Int, column: Int) -> String {
        // Find the most recent move at this position
        let movesAtPosition = game.moves.filter { $0.row == row && $0.column == column }
        guard let latestMove = movesAtPosition.max(by: { $0.timestamp < $1.timestamp }) else {
            return ""
        }
        return latestMove.player == .x ? "X" : "O"
    }
}

#Preview {
    SimpleMultiplayerView()
}