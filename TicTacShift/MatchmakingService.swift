import Foundation
import GameKit
import Combine

enum MatchmakingError: Error, LocalizedError {
    case notAuthenticated
    case codeGeneration
    case matchFailed
    case invalidCode
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Game Center authentication required"
        case .codeGeneration:
            return "Failed to generate room code"
        case .matchFailed:
            return "Failed to find match"
        case .invalidCode:
            return "Invalid room code"
        case .timeout:
            return "Connection timeout"
        }
    }
}

final class MatchmakingService: NSObject, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    var currentMatch: GKMatch? {
        willSet {
            objectWillChange.send()
        }
    }
    
    var isSearching = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    var currentRoomCode: String? {
        willSet {
            objectWillChange.send()
        }
    }
    
    static let shared = MatchmakingService()
    
    private var matchRequest: GKMatchRequest?
    private let timeout: TimeInterval = 20.0
    
    override init() {
        super.init()
    }
    
    func createRoom(codeLength: Int = 4) async throws -> String {
        guard GKLocalPlayer.local.isAuthenticated else {
            throw MatchmakingError.notAuthenticated
        }
        
        let code = generateRoomCode(length: codeLength)
        let playerGroup = hashCode(code)
        
        await MainActor.run {
            isSearching = true
            currentRoomCode = code
        }
        
        do {
            let match = try await findMatch(playerGroup: playerGroup)
            await MainActor.run {
                currentMatch = match
                isSearching = false
            }
            return code
        } catch {
            await MainActor.run {
                isSearching = false
                currentRoomCode = nil
            }
            throw error
        }
    }
    
    func joinRoom(code: String) async throws -> GKMatch {
        guard GKLocalPlayer.local.isAuthenticated else {
            throw MatchmakingError.notAuthenticated
        }
        
        guard isValidCode(code) else {
            throw MatchmakingError.invalidCode
        }
        
        let playerGroup = hashCode(code)
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let match = try await findMatch(playerGroup: playerGroup)
            await MainActor.run {
                currentMatch = match
                isSearching = false
            }
            return match
        } catch {
            await MainActor.run {
                isSearching = false
            }
            throw error
        }
    }
    
    func leaveMatch() {
        Task { @MainActor in
            currentMatch?.disconnect()
            currentMatch = nil
            currentRoomCode = nil
            isSearching = false
        }
    }
    
    private func findMatch(playerGroup: Int32) async throws -> GKMatch {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.playerGroup = Int(playerGroup)
        
        matchRequest = request
        
        return try await withCheckedThrowingContinuation { continuation in
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                continuation.resume(throwing: MatchmakingError.timeout)
            }
            
            GKMatchmaker.shared().findMatch(for: request) { match, error in
                timeoutTask.cancel()
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let match = match {
                    continuation.resume(returning: match)
                } else {
                    continuation.resume(throwing: MatchmakingError.matchFailed)
                }
            }
        }
    }
    
    private func generateRoomCode(length: Int) -> String {
        let digits = "0123456789"
        return String((0..<length).map { _ in digits.randomElement()! })
    }
    
    private func isValidCode(_ code: String) -> Bool {
        return code.count >= 4 && code.count <= 6 && code.allSatisfy(\.isNumber)
    }
    
    private func hashCode(_ code: String) -> Int32 {
        var hash: UInt32 = 2166136261
        for byte in code.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        return Int32(hash & 0x7FFFFFFF)
    }
}
