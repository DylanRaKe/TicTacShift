//
//  GameBoardView.swift
//  TicTacShift
//
//  Game board interface for TicTacShift
//

import SwiftUI

struct GameBoardView: View {
    @Bindable var game: TicTacShiftGame
    @State private var animatingSquares: Set<String> = []
    @State private var victoryManager = VictoryAnimationManager()
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var isPlayerTurn: Bool {
        // In normal mode, always allow moves (both players are human)
        // In bot mode, only allow moves when it's player X's turn (human) and bot is not thinking
        if game.gameMode == .bot {
            return game.currentPlayer == .x && !game.isWaitingForBot
        } else {
            return true
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: game.gameMode.gradient.map { $0.opacity(0.05) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Game status header
                    gameStatusHeader
                    
                    // Game board
                    gameBoard
                    
                    // Game controls
                    gameControls
                    
                    // Move history
                    if !game.moves.isEmpty {
                        moveHistorySection
                    }
                }
                .padding()
            }
            
            // Victory animation overlay
            VictoryAnimationView(
                animationManager: victoryManager,
                winnerText: getVictoryText()
            )
        }
        .navigationTitle(game.gameMode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkForBotMove()
        }
        .onChange(of: game.currentPlayer) {
            checkForBotMove()
        }
        .onChange(of: game.gameResult) {
            if case .win(_) = game.gameResult {
                let winningSquares = getWinningSquares()
                victoryManager.startVictoryAnimation(winningSquares: winningSquares)
            }
        }
    }
    
    private var gameStatusHeader: some View {
        VStack(spacing: 12) {
            // Mode indicator
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: game.gameMode.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: game.gameMode.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(game.gameMode == .normal ? "Normal" : game.gameMode == .bot ? "vs Bot" : "Spécial")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            // Game status
            switch game.gameResult {
            case .ongoing:
                VStack(spacing: 8) {
                    HStack {
                        Text("Tour \(game.moveCounter + 1)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        if game.gameMode == .bot && game.isWaitingForBot {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Bot réfléchit...")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    
                    // Current player indicator
                    HStack(spacing: 16) {
                        PlayerIndicator(
                            player: .x,
                            isActive: game.currentPlayer == .x && !game.isWaitingForBot,
                            gameMode: game.gameMode
                        )
                        
                        Text("VS")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        PlayerIndicator(
                            player: .o,
                            isActive: game.currentPlayer == .o && !game.isWaitingForBot,
                            gameMode: game.gameMode
                        )
                    }
                }
                
            case .win(let player):
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("\(game.gameMode == .bot && player == .o ? "Bot" : "Joueur \(player.rawValue)") gagne !")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(player == .x ? .blue : .red)
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Text("Game finished in \(game.moveCounter) moves")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .draw:
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "equal")
                            .foregroundColor(.orange)
                        Text("It's a Draw!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Image(systemName: "equal")
                            .foregroundColor(.orange)
                    }
                    
                    Text("20 moves completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var gameBoard: some View {
        VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 6) {
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
                        .winningSquareGlow(
                            isWinning: victoryManager.winningPositions.contains { $0.0 == row && $0.1 == column },
                            reduceMotion: reduceMotion
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var gameControls: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.5)) {
                    game.resetGame()
                    victoryManager.stopAnimation()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("New Game")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            if game.gameResult != .ongoing {
                Button {
                    withAnimation(.spring(response: 0.5)) {
                        game.resetGame()
                        victoryManager.stopAnimation()
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Play Again")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
    
    private var moveHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                Text("Move History")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(game.getVisibleMoves().reversed(), id: \.moveNumber) { move in
                        HStack(spacing: 12) {
                            // Move number
                            ZStack {
                                Circle()
                                    .fill(move.player == .x ? Color.blue : Color.red)
                                    .frame(width: 24, height: 24)
                                
                                Text("\(move.moveNumber + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(game.gameMode == .bot && move.player == .o ? "Bot" : "Player \(move.player.rawValue)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(move.player == .x ? .blue : .red)
                                
                                Text("Position (\(move.row + 1), \(move.column + 1))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Fading indicator
                            if game.moves.count > 6 && move.moveNumber < game.moveCounter - 6 {
                                VStack {
                                    Image(systemName: "hourglass.tophalf.filled")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Fading")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            .frame(maxHeight: 150)
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Pieces disappear after 3 complete turns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Functions
    
    private func getVictoryText() -> String {
        if case .win(let player) = game.gameResult {
            return "\(game.gameMode == .bot && player == .o ? "Bot" : "Joueur \(player.rawValue)") remporte la partie !"
        }
        return ""
    }
    
    private func getWinningSquares() -> [(Int, Int)] {
        guard case .win(_) = game.gameResult else { return [] }
        
        let board = game.boardState
        
        // Check rows
        for row in 0..<3 {
            if let player = board[row][0],
               board[row][1] == player && board[row][2] == player {
                return [(row, 0), (row, 1), (row, 2)]
            }
        }
        
        // Check columns  
        for col in 0..<3 {
            if let player = board[0][col],
               board[1][col] == player && board[2][col] == player {
                return [(0, col), (1, col), (2, col)]
            }
        }
        
        // Check diagonals
        if let player = board[0][0],
           board[1][1] == player && board[2][2] == player {
            return [(0, 0), (1, 1), (2, 2)]
        }
        
        if let player = board[0][2],
           board[1][1] == player && board[2][0] == player {
            return [(0, 2), (1, 1), (2, 0)]
        }
        
        return []
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
              game.currentPlayer == .o,
              game.gameResult == .ongoing,
              !game.isWaitingForBot else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _ = game.makeBotMove()
            }
        }
    }
}

struct PlayerIndicator: View {
    let player: Player
    let isActive: Bool
    let gameMode: GameMode
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(player == .x ? Color.blue : Color.red)
                    .frame(width: 40, height: 40)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isActive)
                
                Text(player.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(gameMode == .bot && player == .o ? "Bot" : "Player \(player.rawValue)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? (player == .x ? .blue : .red) : .secondary)
                
                if isActive {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(player == .x ? .blue : .red)
                            .frame(width: 4, height: 4)
                            .scaleEffect(isActive ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
                        
                        Text("Turn")
                            .font(.caption2)
                            .foregroundColor(player == .x ? .blue : .red)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? (player == .x ? Color.blue.opacity(0.1) : Color.red.opacity(0.1)) : Color(.systemGray6))
        )
    }
}

struct EnhancedGameSquareView: View {
    let player: Player?
    let isEnabled: Bool
    let isAnimating: Bool
    let willFadeNext: Bool
    let gameMode: GameMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
                
                if let player = player {
                    ZStack {
                        // Player symbol
                        Text(player.rawValue)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(player == .x ? .blue : .red)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .opacity(willFadeNext ? 0.3 : 1.0)
                            .animation(willFadeNext ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .none, value: willFadeNext)
                        
                        // Subtle glow effect
                        Text(player.rawValue)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(player == .x ? .blue.opacity(0.3) : .red.opacity(0.3))
                            .blur(radius: 8)
                            .scaleEffect(1.1)
                        
                    }
                } else if isEnabled {
                    // Hint for available move
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .opacity(isEnabled ? 0.6 : 0)
                        .scaleEffect(isEnabled ? 1.0 : 0.5)
                }
            }
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: player)
        .animation(.spring(response: 0.2), value: isEnabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
    }
    
    private var backgroundColor: Color {
        if player != nil {
            return Color(.systemBackground)
        } else if isEnabled {
            return Color.blue.opacity(0.05)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var borderColor: Color {
        if let player = player {
            return player == .x ? .blue : .red
        } else if isEnabled {
            return .blue.opacity(0.4)
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var borderWidth: CGFloat {
        if player != nil {
            return 3
        } else if isEnabled {
            return 2
        } else {
            return 1
        }
    }
    
    private var shadowColor: Color {
        if player != nil {
            return (player == .x ? Color.blue : Color.red).opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        player != nil ? 8 : 4
    }
    
    private var shadowY: CGFloat {
        player != nil ? 4 : 2
    }
}

// MARK: - Game Logic Extensions

#Preview {
    NavigationView {
        GameBoardView(game: TicTacShiftGame(gameMode: .bot))
    }
}