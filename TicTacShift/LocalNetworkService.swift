//
//  LocalNetworkService.swift
//  TicTacShift
//
//  Local network multiplayer using Network framework
//

import Foundation
import Network
import Combine

// MARK: - Message Types
struct GameMessage: Codable {
    let type: MessageType
    let data: MessageData
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case gameMove = "game_move"
        case gameStart = "game_start"
        case gameEnd = "game_end"
        case playerJoined = "player_joined"
        case playerLeft = "player_left"
        case ping = "ping"
        case pong = "pong"
    }
    
    enum MessageData: Codable {
        case move(row: Int, column: Int, player: Player)
        case gameState(isStarted: Bool, currentPlayer: Player?)
        case playerInfo(name: String, isHost: Bool)
        case ping
        case pong
        
        private enum CodingKeys: String, CodingKey {
            case type, row, column, player, isStarted, currentPlayer, name, isHost
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "move":
                let row = try container.decode(Int.self, forKey: .row)
                let column = try container.decode(Int.self, forKey: .column)
                let player = try container.decode(Player.self, forKey: .player)
                self = .move(row: row, column: column, player: player)
            case "gameState":
                let isStarted = try container.decode(Bool.self, forKey: .isStarted)
                let currentPlayer = try? container.decode(Player.self, forKey: .currentPlayer)
                self = .gameState(isStarted: isStarted, currentPlayer: currentPlayer)
            case "playerInfo":
                let name = try container.decode(String.self, forKey: .name)
                let isHost = try container.decode(Bool.self, forKey: .isHost)
                self = .playerInfo(name: name, isHost: isHost)
            case "ping":
                self = .ping
            case "pong":
                self = .pong
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown message type")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .move(let row, let column, let player):
                try container.encode("move", forKey: .type)
                try container.encode(row, forKey: .row)
                try container.encode(column, forKey: .column)
                try container.encode(player, forKey: .player)
            case .gameState(let isStarted, let currentPlayer):
                try container.encode("gameState", forKey: .type)
                try container.encode(isStarted, forKey: .isStarted)
                try container.encode(currentPlayer, forKey: .currentPlayer)
            case .playerInfo(let name, let isHost):
                try container.encode("playerInfo", forKey: .type)
                try container.encode(name, forKey: .name)
                try container.encode(isHost, forKey: .isHost)
            case .ping:
                try container.encode("ping", forKey: .type)
            case .pong:
                try container.encode("pong", forKey: .type)
            }
        }
    }
}

// MARK: - Network Service Protocol
protocol LocalNetworkServiceDelegate: AnyObject {
    func networkDidConnect()
    func networkDidDisconnect(error: Error?)
    func networkDidReceiveMessage(_ message: GameMessage)
    func networkDidDiscoverPeer(_ peerName: String)
    func networkDidLosePeer(_ peerName: String)
}

// MARK: - Local Network Service
final class LocalNetworkService: ObservableObject {
    weak var delegate: LocalNetworkServiceDelegate?
    
    @Published var isConnected: Bool = false
    @Published var availablePeers: [String] = []
    @Published var connectionStatus: ConnectionStatus = .idle
    
    enum ConnectionStatus {
        case idle
        case advertising
        case browsing
        case connecting
        case connected
        case disconnected
        case error(String)
    }
    
    private let serviceName = "tictacshift"
    private let serviceType = "_tictacshift._tcp"
    
    // Server (Host) Components
    private var listener: NWListener?
    private var advertiser: NWBrowser?
    private var connection: NWConnection?
    
    // Client Components
    private var browser: NWBrowser?
    
    private let queue = DispatchQueue(label: "LocalNetworkService")
    
    deinit {
        stopAll()
    }
    
    // MARK: - Host Methods
    func startHosting() {
        print("🏠 Starting to host game...")
        
        do {
            // Create listener
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            
            let service = NWListener.Service(name: serviceName, type: serviceType)
            listener = try NWListener(service: service, using: parameters)
            
            listener?.newConnectionHandler = { [weak self] connection in
                print("🔗 New connection received")
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                self?.handleListenerState(state)
            }
            
            listener?.start(queue: queue)
            
            DispatchQueue.main.async {
                self.connectionStatus = .advertising
            }
            
        } catch {
            print("❌ Failed to start hosting: \(error)")
            DispatchQueue.main.async {
                self.connectionStatus = .error(error.localizedDescription)
            }
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        print("🤝 Handling new connection")
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        connection.start(queue: queue)
        startReceiving(on: connection)
    }
    
    private func handleListenerState(_ state: NWListener.State) {
        print("🎧 Listener state: \(state)")
        
        DispatchQueue.main.async {
            switch state {
            case .ready:
                self.connectionStatus = .advertising
                print("✅ Now advertising as host")
            case .failed(let error):
                self.connectionStatus = .error(error.localizedDescription)
                print("❌ Listener failed: \(error)")
            case .cancelled:
                self.connectionStatus = .idle
                print("🛑 Listener cancelled")
            default:
                break
            }
        }
    }
    
    // MARK: - Client Methods
    func startBrowsing() {
        print("🔍 Starting to browse for games...")
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        let descriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(type: serviceType, domain: nil)
        browser = NWBrowser(for: descriptor, using: parameters)
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleBrowseResults(results, changes: changes)
        }
        
        browser?.stateUpdateHandler = { [weak self] state in
            self?.handleBrowserState(state)
        }
        
        browser?.start(queue: queue)
        
        DispatchQueue.main.async {
            self.connectionStatus = .browsing
        }
    }
    
    private func handleBrowseResults(_ results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        print("📡 Browse results changed")
        
        DispatchQueue.main.async {
            self.availablePeers = results.compactMap { result in
                if case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                    return name
                }
                return nil
            }
            
            print("🎮 Available peers: \(self.availablePeers)")
        }
        
        for change in changes {
            switch change {
            case .added(let result):
                if case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                    print("➕ Discovered peer: \(name)")
                    delegate?.networkDidDiscoverPeer(name)
                }
            case .removed(let result):
                if case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                    print("➖ Lost peer: \(name)")
                    delegate?.networkDidLosePeer(name)
                }
            default:
                break
            }
        }
    }
    
    private func handleBrowserState(_ state: NWBrowser.State) {
        print("🔍 Browser state: \(state)")
        
        DispatchQueue.main.async {
            switch state {
            case .ready:
                self.connectionStatus = .browsing
                print("✅ Now browsing for games")
            case .failed(let error):
                self.connectionStatus = .error(error.localizedDescription)
                print("❌ Browser failed: \(error)")
            case .cancelled:
                self.connectionStatus = .idle
                print("🛑 Browser cancelled")
            default:
                break
            }
        }
    }
    
    func connectToPeer(_ peerName: String) {
        guard let browser = browser else {
            print("❌ No browser available")
            return
        }
        
        // Find the peer result
        let results = browser.browseResults
        guard let peerResult = results.first(where: { result in
            if case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                return name == peerName
            }
            return false
        }) else {
            print("❌ Peer \(peerName) not found")
            return
        }
        
        print("🔗 Connecting to peer: \(peerName)")
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        connection = NWConnection(to: peerResult.endpoint, using: parameters)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        connection?.start(queue: queue)
        startReceiving(on: connection!)
        
        DispatchQueue.main.async {
            self.connectionStatus = .connecting
        }
    }
    
    // MARK: - Connection Handling
    private func handleConnectionState(_ state: NWConnection.State) {
        print("🔗 Connection state: \(state)")
        
        DispatchQueue.main.async {
            switch state {
            case .ready:
                self.isConnected = true
                self.connectionStatus = .connected
                self.delegate?.networkDidConnect()
                print("✅ Connection established")
            case .failed(let error):
                self.isConnected = false
                self.connectionStatus = .error(error.localizedDescription)
                self.delegate?.networkDidDisconnect(error: error)
                print("❌ Connection failed: \(error)")
            case .cancelled:
                self.isConnected = false
                self.connectionStatus = .disconnected
                self.delegate?.networkDidDisconnect(error: nil)
                print("🛑 Connection cancelled")
            default:
                break
            }
        }
    }
    
    // MARK: - Message Sending
    func sendMessage(_ message: GameMessage) {
        guard let connection = connection, isConnected else {
            print("❌ No active connection to send message")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let dataWithLength = Data(data.count.bigEndian.bytes) + data
            
            connection.send(content: dataWithLength, completion: .contentProcessed { error in
                if let error = error {
                    print("❌ Failed to send message: \(error)")
                } else {
                    print("✅ Message sent: \(message.type.rawValue)")
                }
            })
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    // MARK: - Message Receiving
    private func startReceiving(on connection: NWConnection) {
        receiveLength(on: connection)
    }
    
    private func receiveLength(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: MemoryLayout<Int>.size, 
                          maximumLength: MemoryLayout<Int>.size) { [weak self] data, _, isComplete, error in
            
            if let error = error {
                print("❌ Error receiving length: \(error)")
                return
            }
            
            guard let data = data, data.count == MemoryLayout<Int>.size else {
                print("❌ Invalid length data")
                return
            }
            
            let length = Int(bigEndian: data.withUnsafeBytes { $0.load(as: Int.self) })
            self?.receiveMessage(on: connection, length: length)
        }
    }
    
    private func receiveMessage(on connection: NWConnection, length: Int) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in
            
            if let error = error {
                print("❌ Error receiving message: \(error)")
                return
            }
            
            guard let data = data, data.count == length else {
                print("❌ Invalid message data")
                self?.receiveLength(on: connection) // Continue receiving
                return
            }
            
            do {
                let message = try JSONDecoder().decode(GameMessage.self, from: data)
                print("📨 Received message: \(message.type.rawValue)")
                
                DispatchQueue.main.async {
                    self?.delegate?.networkDidReceiveMessage(message)
                }
            } catch {
                print("❌ Failed to decode message: \(error)")
            }
            
            // Continue receiving next message
            self?.receiveLength(on: connection)
        }
    }
    
    // MARK: - Cleanup
    func disconnect() {
        print("🔌 Disconnecting...")
        connection?.cancel()
        stopAll()
    }
    
    private func stopAll() {
        listener?.cancel()
        browser?.cancel()
        connection?.cancel()
        
        listener = nil
        browser = nil
        connection = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .idle
            self.availablePeers = []
        }
    }
}

// MARK: - Helper Extensions
private extension Int {
    var bytes: Data {
        var value = self
        return Data(bytes: &value, count: MemoryLayout<Int>.size)
    }
}