import Foundation
import GameKit
import Combine

final class GameCenterAuth: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    var isAuthenticated = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    var localPlayer: GKLocalPlayer? {
        willSet {
            objectWillChange.send()
        }
    }
    
    var authError: String? {
        willSet {
            objectWillChange.send()
        }
    }
    
    static let shared = GameCenterAuth()
    
    private init() {
        localPlayer = GKLocalPlayer.local
        setupAuthHandler()
    }
    
    private func setupAuthHandler() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                print("🎮 Game Center Auth Handler Called")
                
                if let error = error {
                    print("🚨 Game Center Error: \(error)")
                    print("🚨 Error Domain: \(error.localizedDescription)")
                    if let gkError = error as? GKError {
                        print("🚨 GK Error Code: \(gkError.code.rawValue)")
                        print("🚨 GK Error Details: \(gkError.userInfo)")
                    }
                    self?.authError = error.localizedDescription
                    self?.isAuthenticated = false
                    return
                }
                
                if let viewController = viewController {
                    print("🚨 Game Center needs UI presentation")
                    self?.authError = "Authentication required"
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    print("✅ Game Center Authenticated Successfully")
                    print("👤 Player: \(GKLocalPlayer.local.displayName ?? "Unknown")")
                    print("🆔 Player ID: \(GKLocalPlayer.local.gamePlayerID)")
                    self?.isAuthenticated = true
                    self?.localPlayer = GKLocalPlayer.local
                    self?.authError = nil
                } else {
                    print("❌ Game Center Not Authenticated")
                    self?.isAuthenticated = false
                    self?.authError = "Not authenticated"
                }
            }
        }
    }
    
    func authenticate() {
        guard !isAuthenticated else { return }
        setupAuthHandler()
    }
}