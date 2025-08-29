import Foundation
import GameKit
import SwiftUI
import Combine

enum VersusState: Equatable {
    case idle
    case creating(code: String)
    case joining(code: String)
    case searching
    case matched
    case inGame
    case error(String)
}

final class VersusViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    var state: VersusState = .idle {
        willSet {
            objectWillChange.send()
        }
    }
    
    var inputCode = "" {
        willSet {
            objectWillChange.send()
        }
    }
    
    var isLocalPlayerX = true {
        willSet {
            objectWillChange.send()
        }
    }
    
    private let gameAuth = GameCenterAuth.shared
    private let matchmaking = MatchmakingService.shared
    private var matchSession: OnlineMatchSession?
    
    var game: TicTacShiftGame?
    var onGameUpdate: (() -> Void)?
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        gameAuth.authenticate()
    }
    
    @MainActor
    func createRoom() {
        guard gameAuth.isAuthenticated else {
            state = .error("Game Center authentication required")
            return
        }
        
        Task {
            do {
                await MainActor.run { state = .searching }
                let code = try await matchmaking.createRoom()
                await MainActor.run { state = .creating(code: code) }
                
                if let match = matchmaking.currentMatch {
                    await setupMatchSession(match)
                }
            } catch {
                await MainActor.run { state = .error(error.localizedDescription) }
            }
        }
    }
    
    @MainActor
    func joinWithCode() {
        let code = inputCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !code.isEmpty else {
            state = .error("Please enter a room code")
            return
        }
        
        guard gameAuth.isAuthenticated else {
            state = .error("Game Center authentication required")
            return
        }
        
        Task {
            do {
                await MainActor.run { state = .searching }
                let match = try await matchmaking.joinRoom(code: code)
                await MainActor.run { state = .joining(code: code) }
                await setupMatchSession(match)
            } catch {
                await MainActor.run { state = .error(error.localizedDescription) }
            }
        }
    }
    
    @MainActor
    func cancel() {
        matchmaking.leaveMatch()
        matchSession?.close()
        matchSession = nil
        game = nil
        state = .idle
        inputCode = ""
    }
    
    @MainActor
    func rematch() {
        if let currentCode = matchmaking.currentRoomCode {
            Task {
                do {
                    await MainActor.run { state = .searching }
                    let match = try await matchmaking.joinRoom(code: currentCode)
                    await setupMatchSession(match)
                } catch {
                    await MainActor.run { state = .error(error.localizedDescription) }
                }
            }
        }
    }
    
    @MainActor
    func quit() {
        cancel()
    }
    
    private func setupMatchSession(_ match: GKMatch) async {
        let session = OnlineMatchSession(match: match)
        await MainActor.run { matchSession = session }
        
        session.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.handleMessage(message)
            }
        }
        
        session.onPeerStateChanged = { [weak self] player, connectionState in
            Task { @MainActor in
                self?.handlePeerStateChanged(player, connectionState)
            }
        }
        
        await startGame()
    }
    
    @MainActor
    private func startGame() async {
        isLocalPlayerX = GKLocalPlayer.local.gamePlayerID.hashValue % 2 == 0
        game = TicTacShiftGame(gameMode: .normal)
        state = .inGame
        onGameUpdate?()
    }
    
    private func handleMessage(_ message: Message) {
        switch message.type {
        case .move:
            if let payload = message.move {
                handleRemoteMove(payload)
            }
        case .sync:
            if let payload = message.sync {
                handleSyncMessage(payload)
            }
        case .victory:
            if let payload = message.victory {
                handleVictoryMessage(payload)
            }
        case .heartbeat:
            break
        }
    }
    
    private func handleRemoteMove(_ payload: MovePayload) {
        guard let game = game else { return }
        
        let row = payload.cell / 3
        let col = payload.cell % 3
        let player: Player = payload.player == 0 ? .x : .o
        
        if game.canPlaceMove(at: row, column: col) {
            _ = game.placeMove(at: row, column: col)
            onGameUpdate?()
        }
    }
    
    private func handleSyncMessage(_ payload: SyncPayload) {
        // Handle board synchronization
    }
    
    private func handleVictoryMessage(_ payload: VictoryPayload) {
        // Handle victory message
    }
    
    @MainActor
    private func handlePeerStateChanged(_ player: GKPlayer, _ connectionState: GKPlayerConnectionState) {
        switch connectionState {
        case .connected:
            switch state {
            case .creating(_), .joining(_):
                state = .matched
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await self.startGame()
                }
            default:
                break
            }
        case .disconnected:
            state = .error("Player disconnected")
        @unknown default:
            break
        }
    }
    
    @MainActor
    func makeMove(at row: Int, column: Int) {
        guard let game = game,
              let session = matchSession,
              state == .inGame else { return }
        
        let localPlayer: Player = isLocalPlayerX ? .x : .o
        guard game.currentPlayer == localPlayer else { return }
        
        if game.canPlaceMove(at: row, column: column) {
            _ = game.placeMove(at: row, column: column)
            
            let cell = row * 3 + column
            try? session.sendMove(cell: cell, player: localPlayer, turn: game.moveCounter)
            
            onGameUpdate?()
        }
    }
}