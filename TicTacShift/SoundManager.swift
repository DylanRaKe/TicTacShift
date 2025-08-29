//
//  SoundManager.swift
//  TicTacShift
//
//  Sound effects manager for victory animations
//

import Foundation
import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var isEnabled = true
    
    private init() {}
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    func playVictorySound() {
        guard isEnabled else { return }
        
        // Try to play victory sound, fallback to haptic feedback
        if let soundData = createVictorySoundData() {
            do {
                audioPlayer = try AVAudioPlayer(data: soundData)
                audioPlayer?.volume = 0.3
                audioPlayer?.play()
            } catch {
                playHapticFeedback()
            }
        } else {
            playHapticFeedback()
        }
    }
    
    private func playHapticFeedback() {
        // Primary impact
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Success notification after slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
    }
    
    private func createVictorySoundData() -> Data? {
        // Create a simple victory sound programmatically
        // This is a placeholder - in a real app you'd use an actual sound file
        // For now, we'll rely on haptic feedback which works great on iOS
        return nil
    }
}
