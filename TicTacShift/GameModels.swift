//
//  GameModels.swift
//  TicTacShift
//
//  Game models for TicTacShift game
//

import Foundation
import SwiftData
import SwiftUI

enum Player: String, CaseIterable, Codable {
    case x = "X"
    case o = "O"
    
    var opposite: Player {
        self == .x ? .o : .x
    }
}

enum GameResult: Codable, Equatable {
    case ongoing
    case win(Player)
    case draw
}

enum GameMode: String, Codable, CaseIterable {
    case normal = "Normal"
    case bot = "vs Bot"
    case versus = "Versus"
    
    var isEnabled: Bool {
        switch self {
        case .normal, .bot, .versus:
            return true
        }
    }
    
    var icon: String {
        switch self {
        case .normal:
            return "person.2.fill"
        case .bot:
            return "cpu"
        case .versus:
            return "wifi"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .normal:
            return [.blue, .cyan]
        case .bot:
            return [.purple, .pink]
        case .versus:
            return [.green, .mint]
        }
    }
}

@Model
final class GameMove {
    var row: Int
    var column: Int
    var player: Player
    var moveNumber: Int
    var timestamp: Date
    
    init(row: Int, column: Int, player: Player, moveNumber: Int) {
        self.row = row
        self.column = column
        self.player = player
        self.moveNumber = moveNumber
        self.timestamp = Date()
    }
}

@Model
final class TicTacShiftGame {
    var moves: [GameMove]
    var currentPlayer: Player
    var moveCounter: Int
    var gameResult: GameResult
    var createdAt: Date
    var gameMode: GameMode
    var isWaitingForBot: Bool
    
    init(gameMode: GameMode = .normal) {
        self.moves = []
        self.currentPlayer = .x
        self.moveCounter = 0
        self.gameResult = .ongoing
        self.createdAt = Date()
        self.gameMode = gameMode
        self.isWaitingForBot = false
    }
    
    // Get current board state (3x3 grid)
    var boardState: [[Player?]] {
        var board: [[Player?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
        
        // Only show moves that haven't disappeared yet
        let visibleMoves = getVisibleMoves()
        
        for move in visibleMoves {
            board[move.row][move.column] = move.player
        }
        
        return board
    }
    
    // Get moves that are still visible (haven't disappeared after 3 complete turns)
    func getVisibleMoves() -> [GameMove] {
        // After 6 moves (3 complete turns), oldest moves start disappearing
        if moves.count <= 6 {
            return moves
        }
        
        let movesToKeep = moves.count - 6
        return Array(moves.suffix(6))
    }
    
    // Get moves that will disappear on the next turn
    func getMovesWillFadeNext() -> [GameMove] {
        // Les tiles disparaissent après 6 coups (3 tours complets)
        // Si on a exactement 6 moves visibles, les 2 plus anciennes disparaîtront après les 2 prochains coups
        // Mais on veut seulement avertir pour la plus ancienne qui disparaîtra au prochain coup
        
        let visibleMoves = getVisibleMoves()
        
        // Si on a 6 moves visibles et qu'on est sur le point d'ajouter le 7ème coup,
        // alors le plus ancien move va disparaître
        if visibleMoves.count >= 6 {
            // Retourne seulement le plus ancien move (qui va disparaître au prochain placement)
            return [visibleMoves.first!]
        }
        
        return []
    }
    
    // Check if a specific position contains a move that will fade next
    func willPositionFadeNext(row: Int, column: Int) -> Bool {
        let fadingMoves = getMovesWillFadeNext()
        return fadingMoves.contains { $0.row == row && $0.column == column }
    }
    
    // Check if position is valid for a move
    func canPlaceMove(at row: Int, column: Int) -> Bool {
        guard gameResult == .ongoing else { return false }
        guard row >= 0 && row < 3 && column >= 0 && column < 3 else { return false }
        
        let board = boardState
        return board[row][column] == nil
    }
    
    // Place a move
    func placeMove(at row: Int, column: Int) -> Bool {
        guard canPlaceMove(at: row, column: column) else { return false }
        
        let newMove = GameMove(row: row, column: column, player: currentPlayer, moveNumber: moveCounter)
        moves.append(newMove)
        
        moveCounter += 1
        currentPlayer = currentPlayer.opposite
        
        // Reset bot waiting state when move is completed
        isWaitingForBot = false
        
        // Check for win condition
        checkGameResult()
        
        return true
    }
    
    // Check win conditions
    private func checkGameResult() {
        let board = boardState
        
        // Check rows
        for row in 0..<3 {
            if let player = board[row][0],
               board[row][1] == player && board[row][2] == player {
                gameResult = .win(player)
                return
            }
        }
        
        // Check columns  
        for col in 0..<3 {
            if let player = board[0][col],
               board[1][col] == player && board[2][col] == player {
                gameResult = .win(player)
                return
            }
        }
        
        // Check diagonals
        if let player = board[0][0],
           board[1][1] == player && board[2][2] == player {
            gameResult = .win(player)
            return
        }
        
        if let player = board[0][2],
           board[1][1] == player && board[2][0] == player {
            gameResult = .win(player)
            return
        }
        
        // Check for draw (after 20 moves total)
        if moveCounter >= 20 {
            gameResult = .draw
        }
    }
    
    // Reset game
    func resetGame() {
        moves.removeAll()
        currentPlayer = .x
        moveCounter = 0
        gameResult = .ongoing
        isWaitingForBot = false
    }
    
    // Bot AI logic
    func makeBotMove() -> Bool {
        guard gameMode == .bot && currentPlayer == .o && gameResult == .ongoing else { return false }
        
        isWaitingForBot = true
        
        // Simple AI strategy:
        // 1. Try to win
        // 2. Try to block opponent from winning
        // 3. Take center if available
        // 4. Take corner
        // 5. Take random available spot
        
        let board = boardState
        
        // Try to win
        if let winMove = findWinningMove(for: .o, board: board) {
            return placeMove(at: winMove.0, column: winMove.1)
        }
        
        // Try to block opponent
        if let blockMove = findWinningMove(for: .x, board: board) {
            return placeMove(at: blockMove.0, column: blockMove.1)
        }
        
        // Take center
        if canPlaceMove(at: 1, column: 1) {
            return placeMove(at: 1, column: 1)
        }
        
        // Take corners
        let corners = [(0, 0), (0, 2), (2, 0), (2, 2)]
        for corner in corners.shuffled() {
            if canPlaceMove(at: corner.0, column: corner.1) {
                return placeMove(at: corner.0, column: corner.1)
            }
        }
        
        // Take any available spot
        for row in 0..<3 {
            for col in 0..<3 {
                if canPlaceMove(at: row, column: col) {
                    return placeMove(at: row, column: col)
                }
            }
        }
        
        return false
    }
    
    // Find winning move for a player
    private func findWinningMove(for player: Player, board: [[Player?]]) -> (Int, Int)? {
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col] == nil {
                    // Simulate move
                    var testBoard = board
                    testBoard[row][col] = player
                    
                    if checkWin(for: player, board: testBoard) {
                        return (row, col)
                    }
                }
            }
        }
        return nil
    }
    
    // Check if a player has won on the given board
    private func checkWin(for player: Player, board: [[Player?]]) -> Bool {
        // Check rows
        for row in 0..<3 {
            if board[row][0] == player && board[row][1] == player && board[row][2] == player {
                return true
            }
        }
        
        // Check columns
        for col in 0..<3 {
            if board[0][col] == player && board[1][col] == player && board[2][col] == player {
                return true
            }
        }
        
        // Check diagonals
        if board[0][0] == player && board[1][1] == player && board[2][2] == player {
            return true
        }
        
        if board[0][2] == player && board[1][1] == player && board[2][0] == player {
            return true
        }
        
        return false
    }
}