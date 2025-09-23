//
//  GameBoardView.swift
//  TicTacShift
//
//  Game board interface for TicTacShift
//

import SwiftUI
import SwiftData

struct GameBoardView: View {
    @Bindable var game: TicTacShiftGame
    @State private var animatingSquares: Set<String> = []
    @State private var showVictoryScreen = false
    @State private var boardGlow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    private var isPlayerTurn: Bool {
        if game.gameMode == .bot {
            let humanPlayer = game.botPlayer?.opposite ?? .x
            return game.currentPlayer == humanPlayer && !game.isWaitingForBot
        } else {
            return true
        }
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    GameStatusCard(game: game)
                    boardSection
                    controlsSection
                    if !game.moves.isEmpty {
                        historySection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            }

            if showVictoryScreen {
                ModernVictoryView(
                    gameResult: game.gameResult,
                    gameMode: game.gameMode,
                    botPlayer: game.botPlayer,
                    winningLine: game.winningLine,
                    moveCount: game.moveCounter,
                    onPlayAgain: {
                        withAnimation(.spring(response: 0.6)) {
                            game.resetGame()
                            showVictoryScreen = false
                        }
                    },
                    onBackToMenu: {
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            boardGlow = true
            checkForBotMove()
        }
        .onChange(of: game.currentPlayer) { _ in
            checkForBotMove()
        }
        .onChange(of: game.gameResult) { _ in
            if game.gameResult != .ongoing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        showVictoryScreen = true
                    }
                }
            }
        }
    }

    private var boardSection: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Plateau shifté")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if game.moves.count >= 6 {
                    Text("⚡ disparition des coups anciens active")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.neonYellow.opacity(0.8))
                }
            }

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { column in
                            let squareKey = "\(row)-\(column)"
                            EnhancedGameSquareView(
                                player: game.boardState[row][column],
                                isEnabled: game.canPlaceMove(at: row, column: column) && isPlayerTurn,
                                isAnimating: animatingSquares.contains(squareKey),
                                willFadeNext: game.willPositionFadeNext(row: row, column: column),
                                gameMode: game.gameMode
                            ) {
                                makePlayerMove(row: row, column: column)
                            }
                        }
                    }
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Color.neonCyan.opacity(0.4), Color.neonMagenta.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.4
                            )
                            .shadow(color: .neonCyan.opacity(0.35), radius: 18, y: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(boardGlow ? 0.28 : 0.12), lineWidth: 2)
                            .blur(radius: 8)
                            .opacity(reduceMotion ? 0.15 : 0.5)
                    )
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: boardGlow)
            )
            .overlay(
                Group {
                    if case .win(_) = game.gameResult, let winningLine = game.winningLine {
                        WinningLineOverlay(winningLine: winningLine)
                            .allowsHitTesting(false)
                            .padding(22)
                    }
                }
            )
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.5)) {
                        game.resetGame()
                        showVictoryScreen = false
                    }
                } label: {
                    Label("Relancer", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.neonBlue, Color.neonMagenta], startPoint: .topLeading, endPoint: .bottomTrailing)
                ))

                Button {
                    dismiss()
                } label: {
                    Label("Menu", systemImage: "house.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    foreground: .white.opacity(0.85),
                    scale: 0.98
                ))
            }

            if game.gameResult != .ongoing {
                Button {
                    withAnimation(.spring(response: 0.5)) {
                        game.resetGame()
                        showVictoryScreen = false
                    }
                } label: {
                    Label("Rejouer", systemImage: "sparkles")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .buttonStyle(NeonButtonStyle(
                    gradient: LinearGradient(colors: [Color.neonYellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    foreground: .black
                ))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var historySection: some View {
        NeonGlass(cornerRadius: 28, strokeOpacity: 0.18, shadowColor: .neonBlue.opacity(0.25)) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("Historique des shifts", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Text("Tour actuel : \(game.moveCounter + 1)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(game.getVisibleMoves().reversed(), id: \.moveNumber) { move in
                            HistoryRow(move: move, game: game)
                        }
                    }
                }
                .frame(maxHeight: 180)

                Text("Les coups s'effacent après trois tours complet – anticipez !")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private func makePlayerMove(row: Int, column: Int) {
        let squareKey = "\(row)-\(column)"

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            animatingSquares.insert(squareKey)
            _ = game.placeMove(at: row, column: column)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animatingSquares.remove(squareKey)
        }
    }

    private func checkForBotMove() {
        guard game.gameMode == .bot,
              let botPlayer = game.botPlayer,
              game.currentPlayer == botPlayer,
              game.gameResult == .ongoing,
              !game.isWaitingForBot else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _ = game.makeBotMove()
            }
        }
    }
}

private struct GameStatusCard: View {
    @Bindable var game: TicTacShiftGame
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NeonGlass(cornerRadius: 30, strokeOpacity: 0.22, shadowColor: .neonBlue.opacity(0.25)) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    NeonCapsule(title: game.gameMode.rawValue, systemImage: game.gameMode.icon, colors: game.gameMode.gradient)
                    Spacer()
                    if game.gameMode == .bot && game.isWaitingForBot {
                        Label("Le bot calcule...", systemImage: "cpu")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.neonYellow)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.1), in: Capsule())
                    }
                }

                HStack(spacing: 16) {
                    PlayerBadge(player: .x, isActive: game.currentPlayer == .x && !game.isWaitingForBot)
                    Spacer()
                    PulseDivider(glow: glow)
                    Spacer()
                    PlayerBadge(player: .o, isActive: game.currentPlayer == .o && !game.isWaitingForBot)
                }

                HStack {
                    Text("Tour \(game.moveCounter + 1)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if case .win(let winner) = game.gameResult {
                        Text("Victoire imminente : Joueur \(winner.rawValue)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(winner == .x ? .neonMagenta : .neonCyan)
                    } else if case .draw = game.gameResult {
                        Text("Match nul")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text(isShiftActive ? "Shift actif" : "Prépare le shift")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isShiftActive ? .neonYellow : .white.opacity(0.6))
                    }
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            glow = true
        }
    }

    private var isShiftActive: Bool {
        game.moveCounter >= 6
    }
}

private struct PlayerBadge: View {
    let player: Player
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill((player == .x ? Color.neonMagenta : Color.neonCyan).opacity(0.18))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1.2)
                    )
                    .shadow(color: (player == .x ? Color.neonMagenta : Color.neonCyan).opacity(0.4), radius: isActive ? 18 : 10, y: 8)
                    .overlay(
                        Circle()
                            .stroke((player == .x ? Color.neonMagenta : Color.neonCyan).opacity(isActive ? 0.8 : 0.25), lineWidth: 3)
                            .blur(radius: 4)
                            .opacity(isActive ? 1 : 0)
                    )
                Text(player.rawValue)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(reduceMotion ? 1 : pulse ? 1.05 : 0.95)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

            Text(player == .x ? "Joueur X" : "Joueur O")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isActive ? .white : .white.opacity(0.6))
        }
        .onAppear {
            guard !reduceMotion else { return }
            pulse = isActive
        }
        .onChange(of: isActive) { active in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pulse = active
            }
        }
    }
}

private struct PulseDivider: View {
    let glow: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .frame(width: 4, height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.neonMagenta, Color.neonCyan], startPoint: .top, endPoint: .bottom)
                    )
                    .opacity(glow ? 1 : 0.3)
                    .blur(radius: 4)
            )
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glow)
    }
}

private struct HistoryRow: View {
    let move: GameMove
    @Bindable var game: TicTacShiftGame

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(move.player == .x ? Color.neonMagenta : Color.neonCyan)
                    .frame(width: 28, height: 28)
                Text("\(move.moveNumber + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playerLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(move.player == .x ? .neonMagenta : .neonCyan)
                Text("Case (\(move.row + 1), \(move.column + 1))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            if game.moves.count > 6 && move.moveNumber < game.moveCounter - 6 {
                Label("Fading", systemImage: "hourglass.tophalf.filled")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.neonYellow.opacity(0.8))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var playerLabel: String {
        if game.gameMode == .bot && move.player == game.botPlayer {
            return "Bot"
        }
        return "Joueur \(move.player.rawValue)"
    }
}

struct EnhancedGameSquareView: View {
    let player: Player?
    let isEnabled: Bool
    let isAnimating: Bool
    let willFadeNext: Bool
    let gameMode: GameMode
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(backgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(borderGradient, lineWidth: borderWidth)
                    )
                    .shadow(color: glowColor.opacity(0.35), radius: 14, y: 8)

                if let player = player {
                    ZStack {
                        Text(player.rawValue)
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(symbolColor(for: player))
                            .scaleEffect(isAnimating ? 1.08 : 1.0)
                            .rotationEffect(.degrees(reduceMotion ? 0 : isAnimating ? 8 : 0))
                            .opacity(willFadeNext ? 0.45 : 1.0)
                            .animation(willFadeNext ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default, value: willFadeNext)

                        Text(player.rawValue)
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(symbolColor(for: player).opacity(0.45))
                            .blur(radius: 12)
                            .scaleEffect(1.1)
                    }
                } else if isEnabled {
                    VStack(spacing: 6) {
                        Image(systemName: "circle.dotted")
                            .font(.system(size: 20, weight: .medium))
                        Text("Play")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.55))
                    .scaleEffect(reduceMotion ? 1 : pulse ? 1.08 : 0.94)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                }
            }
            .frame(width: 96, height: 96)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled && player == nil)
        .onAppear {
            guard !reduceMotion else { return }
            pulse = isEnabled
        }
        .onChange(of: isEnabled) { enabled in
            guard !reduceMotion else { return }
            pulse = enabled
        }
    }

    private var backgroundGradient: LinearGradient {
        if let player = player {
            return LinearGradient(colors: [symbolColor(for: player).opacity(0.22), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isEnabled {
            return LinearGradient(colors: [Color.neonBlue.opacity(0.18), Color.neonCyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var borderGradient: LinearGradient {
        if let player = player {
            return LinearGradient(colors: [symbolColor(for: player), Color.white.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isEnabled {
            return LinearGradient(colors: [Color.neonCyan.opacity(0.6), Color.neonBlue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var borderWidth: CGFloat {
        if player != nil {
            return 3
        } else if isEnabled {
            return 2.2
        } else {
            return 1.2
        }
    }

    private var glowColor: Color {
        if let player = player {
            return symbolColor(for: player)
        } else if isEnabled {
            return .neonCyan
        } else {
            return .black
        }
    }

    private func symbolColor(for player: Player) -> Color {
        player == .x ? .neonMagenta : .neonCyan
    }
}

#Preview {
    NavigationView {
        GameBoardView(game: TicTacShiftGame(gameMode: .bot))
    }
}
