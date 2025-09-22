//
//  SimpleMultiplayerView.swift
//  TicTacShift
//
//  Simple multiplayer implementation
//

import SwiftUI

struct SimpleMultiplayerView: View {
    @StateObject private var viewModel = SimpleMultiplayerViewModel()

    var body: some View {
        ZStack {
            NeonBackground(animate: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    stateBadge
                    content
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            }
        }
        .navigationTitle("Mode en ligne")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        NeonGlass(cornerRadius: 32, strokeOpacity: 0.2, shadowColor: .neonCyan.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 18) {
                NeonCapsule(title: "Wi-Fi party", systemImage: "antenna.radiowaves.left.and.right", colors: [Color.neonCyan, Color.neonYellow])
                Text("Créez ou rejoignez une partie locale")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Partagez votre code ou scannez les parties disponibles sur le réseau")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var stateBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundColor(.neonYellow)
                .font(.system(size: 18, weight: .bold))
            Text("État : \(stateText)")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.1)
                )
        )
    }

    @ViewBuilder
    private var content: some View {
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
    }

    private var idleView: some View {
        VStack(spacing: 22) {
            NeonGlass(cornerRadius: 28, strokeOpacity: 0.2, shadowColor: .neonMagenta.opacity(0.28)) {
                VStack(spacing: 16) {
                    Text("Créer une partie")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Button(action: viewModel.createGame) {
                        Label("Lancer un lobby", systemImage: "play.circle")
                    }
                    .buttonStyle(NeonButtonStyle(
                        gradient: LinearGradient(colors: [Color.neonMagenta, Color.neonBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ))
                }
            }

            NeonGlass(cornerRadius: 28, strokeOpacity: 0.2, shadowColor: .neonCyan.opacity(0.28)) {
                VStack(spacing: 16) {
                    Text("Rejoindre une partie")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Button(action: viewModel.startBrowsing) {
                        Label("Scanner le réseau", systemImage: "dot.radiowaves.left.and.right")
                    }
                    .buttonStyle(NeonButtonStyle(
                        gradient: LinearGradient(colors: [Color.neonCyan, Color.neonYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ))
                }
            }
        }
    }

    private func hostingView(code: String) -> some View {
        NeonGlass(cornerRadius: 32, strokeOpacity: 0.2, shadowColor: .neonMagenta.opacity(0.3)) {
            VStack(spacing: 20) {
                Text("En attente d'un challenger")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    Text("Code de la partie")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))

                    Text(code)
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                                )
                        )
                }

                Text("Partagez ce code avec votre adversaire et restez sur cet écran")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                Button(action: viewModel.cancel) {
                    Label("Annuler", systemImage: "xmark")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    foreground: .white.opacity(0.85),
                    scale: 0.97
                ))
            }
        }
    }

    private var browsingView: some View {
        NeonGlass(cornerRadius: 32, strokeOpacity: 0.2, shadowColor: .neonCyan.opacity(0.3)) {
            VStack(spacing: 18) {
                Text("Recherche de parties")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if viewModel.availablePeers.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.neonCyan)
                        Text("Aucune partie trouvée pour le moment")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Parties disponibles")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                        ForEach(viewModel.availablePeers, id: \.self) { peer in
                            Button {
                                viewModel.joinGame(peerName: peer)
                            } label: {
                                Label(peer, systemImage: "link")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .buttonStyle(NeonButtonStyle(
                                gradient: LinearGradient(colors: [Color.neonMagenta, Color.neonBlue], startPoint: .leading, endPoint: .trailing)
                            ))
                        }
                    }
                }

                Button(action: viewModel.cancel) {
                    Label("Annuler", systemImage: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing),
                    foreground: .white.opacity(0.85),
                    scale: 0.97
                ))
            }
        }
    }

    private var connectingView: some View {
        NeonGlass(cornerRadius: 28, strokeOpacity: 0.2, shadowColor: .neonBlue.opacity(0.28)) {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.neonBlue)
                Text("Connexion en cours...")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Button(action: viewModel.cancel) {
                    Label("Annuler", systemImage: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing),
                    foreground: .white.opacity(0.85),
                    scale: 0.97
                ))
            }
        }
    }

    private var connectedView: some View {
        NeonGlass(cornerRadius: 32, strokeOpacity: 0.2, shadowColor: .neonYellow.opacity(0.28)) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.neonYellow)
                Text("Connecté !")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Préparation de la partie...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var gameView: some View {
        NeonGlass(cornerRadius: 32, strokeOpacity: 0.2, shadowColor: .neonMagenta.opacity(0.3)) {
            VStack(spacing: 18) {
                Text("Partie en cours")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let game = viewModel.game {
                    Text("Tu joues : \(viewModel.isHost ? "X" : "O")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Tour de : \(game.currentPlayer.rawValue)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(0..<9, id: \.self) { index in
                            let row = index / 3
                            let column = index % 3

                            Button {
                                viewModel.makeMove(at: row, column: column)
                            } label: {
                                Text(getCellText(game: game, row: row, column: column))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .frame(width: 72, height: 72)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                            .disabled(!game.canPlaceMove(at: row, column: column) || game.currentPlayer != (viewModel.isHost ? .x : .o))
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.neonMagenta)
                }

                Button(action: viewModel.disconnect) {
                    Label("Quitter", systemImage: "escape")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing),
                    foreground: .white.opacity(0.85),
                    scale: 0.97
                ))
            }
        }
    }

    private func errorView(message: String) -> some View {
        NeonGlass(cornerRadius: 32, strokeOpacity: 0.2, shadowColor: .neonYellow.opacity(0.28)) {
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.neonYellow)
                Text("Oups !")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button(action: viewModel.reset) {
                    Label("Réessayer", systemImage: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.neonMagenta, Color.neonBlue], startPoint: .leading, endPoint: .trailing)
                ))
            }
        }
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

    private func getCellText(game: TicTacShiftGame, row: Int, column: Int) -> String {
        let movesAtPosition = game.moves.filter { $0.row == row && $0.column == column }
        guard let latestMove = movesAtPosition.max(by: { $0.timestamp < $1.timestamp }) else {
            return ""
        }
        return latestMove.player.rawValue
    }
}

#Preview {
    SimpleMultiplayerView()
}
