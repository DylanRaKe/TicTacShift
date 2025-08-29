import Foundation
import GameKit
import Combine

enum MessageType: String, Codable {
    case move, sync, victory, heartbeat
}

struct MovePayload: Codable {
    let cell: Int
    let player: Int
    let turn: Int
}

struct SyncPayload: Codable {
    let board: [Int]
    let turn: Int
}

struct VictoryPayload: Codable {
    let line: [Int]
    let winner: Int
}

struct HeartbeatPayload: Codable {
    let t: UInt64
}

struct Message: Codable {
    let type: MessageType
    let move: MovePayload?
    let sync: SyncPayload?
    let victory: VictoryPayload?
    let hb: HeartbeatPayload?
}

final class OnlineMatchSession: NSObject, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    private let match: GKMatch
    private var heartbeatTimer: Timer?
    
    var onMessage: ((Message) -> Void)?
    var onPeerStateChanged: ((GKPlayer, GKPlayerConnectionState) -> Void)?
    
    init(match: GKMatch) {
        self.match = match
        super.init()
        self.match.delegate = self
        startHeartbeat()
    }
    
    func send(_ message: Message) throws {
        let data = try JSONEncoder().encode(message)
        try match.sendData(toAllPlayers: data, with: .reliable)
    }
    
    func sendMove(cell: Int, player: Player, turn: Int) throws {
        let payload = MovePayload(cell: cell, player: player.rawValue == "X" ? 0 : 1, turn: turn)
        let message = Message(type: .move, move: payload, sync: nil, victory: nil, hb: nil)
        try send(message)
    }
    
    func sendSync(board: [[Player?]], turn: Int) throws {
        let flatBoard = board.flatMap { row in
            row.map { player in
                if let player = player {
                    return player.rawValue == "X" ? 0 : 1
                } else {
                    return -1
                }
            }
        }
        let payload = SyncPayload(board: flatBoard, turn: turn)
        let message = Message(type: .sync, move: nil, sync: payload, victory: nil, hb: nil)
        try send(message)
    }
    
    func sendVictory(line: [(Int, Int)], winner: Player) throws {
        let lineIndices = line.map { $0.0 * 3 + $0.1 }
        let payload = VictoryPayload(line: lineIndices, winner: winner.rawValue == "X" ? 0 : 1)
        let message = Message(type: .victory, move: nil, sync: nil, victory: payload, hb: nil)
        try send(message)
    }
    
    func close() {
        heartbeatTimer?.invalidate()
        match.disconnect()
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let payload = HeartbeatPayload(t: UInt64(Date().timeIntervalSince1970 * 1000))
            let message = Message(type: .heartbeat, move: nil, sync: nil, victory: nil, hb: payload)
            
            try? self.send(message)
        }
    }
}

extension OnlineMatchSession: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let message = try? JSONDecoder().decode(Message.self, from: data) else { return }
        onMessage?(message)
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        onPeerStateChanged?(player, state)
    }
    
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        // Handle match failure
    }
}