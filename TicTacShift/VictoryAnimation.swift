//
//  VictoryAnimation.swift
//  TicTacShift
//
//  High-performance victory animation with confetti, glow effects and sound
//

import SwiftUI
import AVFoundation

// MARK: - Victory Animation Manager

@Observable
class VictoryAnimationManager {
    var isActive = false
    var winningPositions: [(Int, Int)] = []
    var audioPlayer: AVAudioPlayer?
    
    func startVictoryAnimation(winningSquares: [(Int, Int)]) {
        winningPositions = winningSquares
        isActive = true
        playVictorySound()
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stopAnimation()
        }
    }
    
    func stopAnimation() {
        isActive = false
        winningPositions = []
    }
    
    private func playVictorySound() {
        SoundManager.shared.playVictorySound()
    }
}

// MARK: - Main Victory Animation View

struct VictoryAnimationView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animationManager: VictoryAnimationManager
    let winnerText: String
    
    @State private var animationPhase: AnimationPhase = .initial
    
    enum AnimationPhase {
        case initial, expanding, falling, complete
    }
    
    var body: some View {
        ZStack {
            if animationManager.isActive {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        animationManager.stopAnimation()
                    }
                
                // High-performance confetti using Canvas
                ConfettiCanvasView(
                    isActive: animationManager.isActive,
                    reduceMotion: reduceMotion
                )
                
                // Victory message with animated glow
                VictoryMessageView(
                    text: winnerText,
                    isActive: animationManager.isActive,
                    reduceMotion: reduceMotion
                )
            }
        }
        .onChange(of: animationManager.isActive) {
            if animationManager.isActive {
                startAnimationSequence()
            } else {
                animationPhase = .initial
            }
        }
    }
    
    private func startAnimationSequence() {
        // Phase 1: Initial burst
        animationPhase = .expanding
        
        // Phase 2: Confetti falling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = .falling
        }
        
        // Phase 3: Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            animationPhase = .complete
        }
    }
}

// MARK: - High-Performance Confetti Canvas

struct ConfettiCanvasView: View {
    let isActive: Bool
    let reduceMotion: Bool
    
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var animationTime: TimeInterval = 0
    
    var body: some View {
        Canvas { context, size in
            // Only render if animation is active
            guard isActive else { return }
            
            // Update and draw each confetti piece
            for piece in confettiPieces {
                drawConfettiPiece(context: context, piece: piece, size: size)
            }
        }
        .onAppear {
            generateConfettiPieces()
        }
        .onChange(of: isActive) {
            if isActive {
                startConfettiAnimation()
            } else {
                stopConfettiAnimation()
            }
        }
    }
    
    private func generateConfettiPieces() {
        confettiPieces = (0..<(reduceMotion ? 20 : 60)).map { index in
            ConfettiPiece(
                id: index,
                x: Double.random(in: -50...450),
                y: Double.random(in: -100...(-50)),
                velocityX: Double.random(in: -2...2),
                velocityY: Double.random(in: 1...3),
                rotation: Double.random(in: 0...360),
                angularVelocity: Double.random(in: -5...5),
                color: ConfettiPiece.colors.randomElement()!,
                shape: ConfettiPiece.Shape.allCases.randomElement()!,
                size: Double.random(in: 4...12),
                delay: Double(index) * 0.05
            )
        }
    }
    
    private func startConfettiAnimation() {
        animationTime = 0
        
        // 60fps animation timer
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            guard isActive else {
                timer.invalidate()
                return
            }
            
            animationTime += 1/60
            updateConfettiPhysics()
            
            if animationTime > 3.0 {
                timer.invalidate()
            }
        }
    }
    
    private func stopConfettiAnimation() {
        animationTime = 0
        generateConfettiPieces() // Reset positions
    }
    
    private func updateConfettiPhysics() {
        for i in 0..<confettiPieces.count {
            var piece = confettiPieces[i]
            
            // Skip if not started yet due to delay
            guard animationTime > piece.delay else { continue }
            
            let effectiveTime = animationTime - piece.delay
            
            // Physics simulation
            piece.velocityY += 0.15 // Gravity
            piece.x += piece.velocityX * (reduceMotion ? 0.5 : 1.0)
            piece.y += piece.velocityY * (reduceMotion ? 0.5 : 1.0)
            piece.rotation += piece.angularVelocity * (reduceMotion ? 0.3 : 1.0)
            
            // Fade out over time
            piece.alpha = max(0, 1.0 - (effectiveTime / 2.5))
            
            confettiPieces[i] = piece
        }
    }
    
    private func drawConfettiPiece(context: GraphicsContext, piece: ConfettiPiece, size: CGSize) {
        guard piece.alpha > 0 else { return }
        
        let position = CGPoint(x: piece.x, y: piece.y)
        let pieceSize = CGSize(width: piece.size, height: piece.size)
        
        var drawContext = context
        drawContext.opacity = piece.alpha
        drawContext.translateBy(x: position.x, y: position.y)
        drawContext.rotate(by: .degrees(piece.rotation))
        
        switch piece.shape {
        case .rectangle:
            let rect = CGRect(
                x: -pieceSize.width/2,
                y: -pieceSize.height/2,
                width: pieceSize.width,
                height: pieceSize.height/2
            )
            drawContext.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(piece.color))
            
        case .circle:
            let rect = CGRect(
                x: -pieceSize.width/2,
                y: -pieceSize.height/2,
                width: pieceSize.width,
                height: pieceSize.height
            )
            let circlePath = Path(ellipseIn: rect)
            drawContext.fill(circlePath, with: .color(piece.color))
            
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: 0, y: -pieceSize.height/2))
            path.addLine(to: CGPoint(x: -pieceSize.width/2, y: pieceSize.height/2))
            path.addLine(to: CGPoint(x: pieceSize.width/2, y: pieceSize.height/2))
            path.closeSubpath()
            drawContext.fill(path, with: .color(piece.color))
        }
    }
}

// MARK: - Victory Message with Glow

struct VictoryMessageView: View {
    let text: String
    let isActive: Bool
    let reduceMotion: Bool
    
    @State private var glowIntensity: Double = 0
    @State private var scale: CGFloat = 0.1
    
    var body: some View {
        VStack(spacing: 16) {
            // Crown icon with glow
            Image(systemName: "crown.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.yellow)
                .shadow(color: .yellow, radius: glowIntensity * (reduceMotion ? 5 : 15))
                .scaleEffect(scale)
                .animation(
                    isActive ?
                        .spring(response: 0.6, dampingFraction: 0.7) :
                        .easeOut(duration: 0.3),
                    value: scale
                )
            
            // Victory text with animated glow
            Text("🎉 VICTOIRE ! 🎉")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .white, radius: glowIntensity * (reduceMotion ? 3 : 10))
                .scaleEffect(scale)
                .animation(
                    isActive ?
                        .spring(response: 0.8, dampingFraction: 0.6).delay(0.2) :
                        .easeOut(duration: 0.3),
                    value: scale
                )
            
            // Winner text
            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(isActive ? 1 : 0)
                .animation(
                    .easeOut(duration: 0.6).delay(0.4),
                    value: isActive
                )
        }
        .onChange(of: isActive) {
            if isActive {
                scale = 1.0
                startGlowAnimation()
            } else {
                scale = 0.1
                glowIntensity = 0
            }
        }
    }
    
    private func startGlowAnimation() {
        guard !reduceMotion else {
            glowIntensity = 0.5 // Static glow for accessibility
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
}

// MARK: - Confetti Piece Data Model

struct ConfettiPiece {
    let id: Int
    var x: Double
    var y: Double
    var velocityX: Double
    var velocityY: Double
    var rotation: Double
    var angularVelocity: Double
    let color: Color
    let shape: Shape
    let size: Double
    let delay: Double
    var alpha: Double = 1.0
    
    enum Shape: CaseIterable {
        case rectangle, circle, triangle
    }
    
    static let colors: [Color] = [
        .red, .blue, .green, .yellow, .purple, .pink, .orange, .cyan
    ]
}

// MARK: - Winning Squares Glow Effect

struct WinningSquareGlowModifier: ViewModifier {
    let isWinning: Bool
    let reduceMotion: Bool
    @State private var glowIntensity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: isWinning ? .yellow : .clear,
                radius: glowIntensity * (reduceMotion ? 5 : 15)
            )
            .scaleEffect(isWinning ? 1.1 : 1.0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7),
                value: isWinning
            )
            .onChange(of: isWinning) {
                if isWinning && !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        glowIntensity = 1.0
                    }
                } else {
                    glowIntensity = isWinning ? 0.5 : 0 // Static glow or no glow
                }
            }
    }
}

extension View {
    func winningSquareGlow(isWinning: Bool, reduceMotion: Bool) -> some View {
        modifier(WinningSquareGlowModifier(isWinning: isWinning, reduceMotion: reduceMotion))
    }
}