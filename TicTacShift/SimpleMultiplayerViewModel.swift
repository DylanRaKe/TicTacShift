//
//  SimpleMultiplayerViewModel.swift
//  TicTacShift
//
//  Real multiplayer using Network framework
//

import Foundation
import SwiftUI
import Combine

enum SimpleMultiplayerState: Equatable {
    case idle
    case hosting(code: String)
    case browsing
    case connecting
    case connected
    case inGame
    case error(String)
}

final class SimpleMultiplayerViewModel: ObservableObject {
    @Published var state: SimpleMultiplayerState = .idle
    @Published var inputCode: String = ""
    @Published var game: TicTacShiftGame?
    @Published var availablePeers: [String] = []
    @Published var isConnected: Bool = false
    
    var isHost: Bool = false
    private var networkService: LocalNetworkService?
    private var localPlayer: Player = .x
    private var remotePlayer: Player = .o
    
    init() {
        print("🟡 SimpleMultiplayerViewModel init - Real networking")
    }
    
    @MainActor
    func createGame() {
        print("🟡 createGame() called - Starting to host")
        isHost = true
        localPlayer = .x
        remotePlayer = .o
        
        // Create network service
        networkService = LocalNetworkService()
        networkService?.delegate = self
        
        // Start hosting
        networkService?.startHosting()
        
        let roomCode = generateGameCode()
        state = .hosting(code: roomCode)
        print("✅ Started hosting with room code: \(roomCode)")
    }
    
    @MainActor
    func startBrowsing() {
        print("🟡 startBrowsing() called")
        isHost = false
        localPlayer = .o
        remotePlayer = .x
        
        // Create network service
        networkService = LocalNetworkService()
        networkService?.delegate = self
        
        // Start browsing for games
        networkService?.startBrowsing()
        state = .browsing
        print("✅ Started browsing for games")
    }
    
    @MainActor
    func joinGame(peerName: String? = nil) {
        print("🟡 joinGame() called")
        
        if let peerName = peerName {
            // Join specific peer
            networkService?.connectToPeer(peerName)
            state = .connecting
            print("🔗 Connecting to peer: \(peerName)")
        } else if !availablePeers.isEmpty {
            // Join first available peer
            let firstPeer = availablePeers[0]
            networkService?.connectToPeer(firstPeer)
            state = .connecting
            print("🔗 Connecting to first available peer: \(firstPeer)")
        } else {
            state = .error("Aucune partie disponible")
            print("❌ No available peers to join")
        }
    }
    
    @MainActor
    func cancel() {
        print("🟡 cancel() called")
        disconnect()
        reset()
    }
    
    @MainActor
    func disconnect() {
        print("🟡 disconnect() called")
        networkService?.disconnect()
        networkService = nil
        game = nil
        isConnected = false
    }
    
    @MainActor
    func reset() {
        print("🟡 reset() called")
        state = .idle
        inputCode = ""
        isHost = false
        availablePeers = []
        isConnected = false
    }
    
    @MainActor
    func makeMove(at row: Int, column: Int) {
        guard let game = game,
              state == .inGame,
              isConnected else { 
            print("❌ Cannot make move - game: \(game != nil), state: \(state), connected: \(isConnected)")
            return 
        }
        
        guard game.currentPlayer == localPlayer else {
            print("❌ Not your turn - current: \(game.currentPlayer), local: \(localPlayer)")
            return
        }
        
        if game.canPlaceMove(at: row, column: column) {
            _ = game.placeMove(at: row, column: column)
            
            // Send move to other player
            let message = GameMessage(
                type: .gameMove,
                data: .move(row: row, column: column, player: localPlayer),
                timestamp: Date()
            )
            networkService?.sendMessage(message)
            
            print("✅ Move made and sent: (\(row), \(column)) by \(localPlayer)")
            
            // Check for game end
            if game.gameResult != .ongoing {
                let endMessage = GameMessage(
                    type: .gameEnd,
                    data: .gameState(isStarted: false, currentPlayer: nil),
                    timestamp: Date()
                )
                networkService?.sendMessage(endMessage)
            }
        }
    }
    
    private func generateGameCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<4).map { _ in chars.randomElement()! })
    }
}

// MARK: - LocalNetworkServiceDelegate
extension SimpleMultiplayerViewModel: @preconcurrency LocalNetworkServiceDelegate {
    @MainActor
    func networkDidConnect() {
        print("✅ Network connected")
        isConnected = true
        state = .connected
        
        // Send player joined message
        let joinMessage = GameMessage(
            type: .playerJoined,
            data: .playerInfo(name: "Player \(isHost ? "1" : "2")", isHost: isHost),
            timestamp: Date()
        )
        networkService?.sendMessage(joinMessage)
        
        // Start game after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.startGame()
        }
    }
    
    @MainActor
    func networkDidDisconnect(error: Error?) {
        print("❌ Network disconnected: \(error?.localizedDescription ?? "No error")")
        isConnected = false
        
        if let error = error {
            state = .error("Connexion perdue: \(error.localizedDescription)")
        } else {
            state = .error("Connexion perdue")
        }
    }
    
    @MainActor
    func networkDidReceiveMessage(_ message: GameMessage) {
        print("📨 Received message: \(message.type.rawValue)")
        
        switch message.type {
        case .gameMove:
            if case .move(let row, let column, let player) = message.data {
                handleRemoteMove(row: row, column: column, player: player)
            }
        case .gameStart:
            if case .gameState(let isStarted, let currentPlayer) = message.data {
                handleGameStart(isStarted: isStarted, currentPlayer: currentPlayer)
            }
        case .gameEnd:
            handleGameEnd()
        case .playerJoined:
            if case .playerInfo(let name, let isHost) = message.data {
                print("👥 Player joined: \(name) (host: \(isHost))")
            }
        case .playerLeft:
            handlePlayerLeft()
        case .ping:
            sendPongMessage()
        case .pong:
            print("🏓 Received pong")
        }
    }
    
    @MainActor
    func networkDidDiscoverPeer(_ peerName: String) {
        print("📡 Discovered peer: \(peerName)")
        if !availablePeers.contains(peerName) {
            availablePeers.append(peerName)
        }
    }
    
    @MainActor
    func networkDidLosePeer(_ peerName: String) {
        print("📡 Lost peer: \(peerName)")
        availablePeers.removeAll { $0 == peerName }
    }
    
    // MARK: - Private Message Handlers
    @MainActor
    private func startGame() {
        print("🎮 Starting multiplayer game")
        game = TicTacShiftGame(gameMode: .normal)
        state = .inGame
        
        // Send game start message
        let startMessage = GameMessage(
            type: .gameStart,
            data: .gameState(isStarted: true, currentPlayer: .x),
            timestamp: Date()
        )
        networkService?.sendMessage(startMessage)
    }
    
    @MainActor
    private func handleGameStart(isStarted: Bool, currentPlayer: Player?) {
        print("🎮 Handling game start message")
        if game == nil {
            game = TicTacShiftGame(gameMode: .normal)
            state = .inGame
        }
    }
    
    @MainActor
    private func handleRemoteMove(row: Int, column: Int, player: Player) {
        guard let game = game else {
            print("❌ No game available for remote move")
            return
        }
        
        print("🎮 Handling remote move: (\(row), \(column)) by \(player)")
        
        if game.canPlaceMove(at: row, column: column) {
            _ = game.placeMove(at: row, column: column)
            print("✅ Remote move applied successfully")
        } else {
            print("❌ Remote move invalid")
        }
    }
    
    @MainActor
    private func handleGameEnd() {
        print("🎮 Game ended")
        // Could show game over screen or return to lobby
    }
    
    @MainActor
    private func handlePlayerLeft() {
        print("👋 Player left the game")
        state = .error("L'autre joueur a quitté la partie")
    }
    
    private func sendPongMessage() {
        let pongMessage = GameMessage(
            type: .pong,
            data: .pong,
            timestamp: Date()
        )
        networkService?.sendMessage(pongMessage)
    }
}

