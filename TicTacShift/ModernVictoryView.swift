//
//  ModernVictoryView.swift
//  TicTacShift
//
//  Modern victory/defeat screen with enhanced animations and winning line
//

import SwiftUI

struct ModernVictoryView: View {
    let gameResult: GameResult
    let gameMode: GameMode
    let botPlayer: Player?
    let winningLine: WinningLine?
    let onPlayAgain: () -> Void
    let onBackToMenu: () -> Void
    
    @State private var showContent = false
    @State private var showButtons = false
    @State private var pulseEffect = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            // Dynamic background based on result
            backgroundView
            
            // Particle system
            if !reduceMotion {
                ParticleSystemView(
                    isActive: showContent,
                    gameResult: gameResult,
                    reduceMotion: reduceMotion
                )
            }
            
            // Main content
            VStack(spacing: 32) {
                Spacer()
                
                // Result icon and title
                resultHeaderView
                
                // Winner information
                winnerInfoView
                
                // Action buttons
                actionButtonsView
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            startVictorySequence()
        }
    }
    
    private var backgroundView: some View {
        Group {
            switch gameResult {
            case .win(let player):
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.7),
                        (player == .x ? Color.blue : Color.red).opacity(0.3),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
            case .draw:
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.7),
                        Color.orange.opacity(0.3),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
            case .ongoing:
                Color.clear
            }
        }
        .ignoresSafeArea()
    }
    
    private var resultHeaderView: some View {
        VStack(spacing: 20) {
            // Animated icon
            Group {
                switch gameResult {
                case .win(let player):
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        (player == .x ? Color.blue : Color.red).opacity(0.6),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: pulseEffect ? 80 : 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: pulseEffect
                            )
                        
                        // Main icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow, radius: 15)
                    }
                    
                case .draw:
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.orange.opacity(0.6),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: pulseEffect ? 80 : 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: pulseEffect
                            )
                        
                        Image(systemName: "equal.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.orange)
                            .shadow(color: .orange, radius: 15)
                    }
                    
                case .ongoing:
                    EmptyView()
                }
            }
            
            // Title text
            Group {
                switch gameResult {
                case .win(let player):
                    VStack(spacing: 8) {
                        Text("🎉 VICTOIRE ! 🎉")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.8), radius: 10)
                        
                        Text(getWinnerName(player))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(player == .x ? .blue : .red)
                            .shadow(color: player == .x ? .blue : .red, radius: 8)
                    }
                    
                case .draw:
                    VStack(spacing: 8) {
                        Text("⚖️ ÉGALITÉ ! ⚖️")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.8), radius: 10)
                        
                        Text("Aucun vainqueur")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                            .shadow(color: .orange, radius: 8)
                    }
                    
                case .ongoing:
                    EmptyView()
                }
            }
        }
    }
    
    private var winnerInfoView: some View {
        VStack(spacing: 16) {
            if case .win(_) = gameResult, let line = winningLine {
                // Winning line info
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(getWinningLineDescription(line))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                )
            }
            
            // Game stats
            HStack(spacing: 24) {
                StatView(
                    icon: "timer",
                    title: "Mode",
                    value: gameMode.rawValue
                )
                
                if case .win(_) = gameResult {
                    StatView(
                        icon: "target",
                        title: "Résultat",
                        value: "Victoire"
                    )
                } else if case .draw = gameResult {
                    StatView(
                        icon: "scale.3d",
                        title: "Résultat", 
                        value: "Égalité"
                    )
                }
            }
        }
        .opacity(showButtons ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(0.8), value: showButtons)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Play Again button
            Button {
                onPlayAgain()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                    Text("Rejouer")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.5), radius: 8, y: 4)
            }
            .scaleEffect(showButtons ? 1.0 : 0.8)
            
            // Back to Menu button
            Button {
                onBackToMenu()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "house")
                        .font(.title2)
                    Text("Menu Principal")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .scaleEffect(showButtons ? 1.0 : 0.8)
        }
        .opacity(showButtons ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.0), value: showButtons)
    }
    
    // MARK: - Helper Functions
    
    private func getWinnerName(_ player: Player) -> String {
        switch gameMode {
        case .bot:
            return player == botPlayer ? "Bot Gagne !" : "Vous Gagnez !"
        case .normal, .versus:
            return "Joueur \(player.rawValue) Gagne !"
        }
    }
    
    private func getWinningLineDescription(_ line: WinningLine) -> String {
        switch line.type {
        case .horizontal:
            return "Ligne horizontale \(line.index + 1)"
        case .vertical:
            return "Colonne \(line.index + 1)"
        case .diagonal:
            return line.index == 0 ? "Diagonale ↘" : "Diagonale ↙"
        }
    }
    
    private func startVictorySequence() {
        // Phase 1: Show main content
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            showContent = true
        }
        
        // Start pulse effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pulseEffect = true
        }
        
        // Phase 2: Show buttons
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showButtons = true
        }
    }
}

struct StatView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ParticleSystemView: View {
    let isActive: Bool
    let gameResult: GameResult
    let reduceMotion: Bool
    
    @State private var particles: [VictoryParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                ParticleView(particle: particle)
            }
        }
        .onAppear {
            if isActive && !reduceMotion {
                generateParticles()
                startParticleAnimation()
            }
        }
    }
    
    private func generateParticles() {
        let particleCount: Int
        switch gameResult {
        case .win(_): 
            particleCount = 30
        case .draw: 
            particleCount = 15
        case .ongoing: 
            particleCount = 0
        }
        
        particles = (0..<particleCount).map { index in
            VictoryParticle(
                id: index,
                startX: Double.random(in: -50...UIScreen.main.bounds.width + 50),
                startY: Double.random(in: -100...(-50)),
                color: getParticleColor(),
                size: Double.random(in: 3...8),
                duration: Double.random(in: 2...4)
            )
        }
    }
    
    private func getParticleColor() -> Color {
        switch gameResult {
        case .win(let player):
            return [Color.yellow, Color.orange, player == .x ? Color.blue : Color.red].randomElement()!
        case .draw:
            return [Color.orange, Color.yellow, Color.red].randomElement()!
        case .ongoing:
            return Color.clear
        }
    }
    
    private func startParticleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            for i in 0..<particles.count {
                particles[i].update()
            }
            
            // Remove particles that are off screen
            particles.removeAll { $0.y > UIScreen.main.bounds.height + 100 }
            
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
}

struct ParticleView: View {
    let particle: VictoryParticle
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
            .opacity(particle.opacity)
    }
}

struct VictoryParticle {
    let id: Int
    var x: Double
    var y: Double
    let color: Color
    let size: Double
    let duration: Double
    var opacity: Double = 1.0
    var velocity: Double = 2.0
    
    init(id: Int, startX: Double, startY: Double, color: Color, size: Double, duration: Double) {
        self.id = id
        self.x = startX
        self.y = startY
        self.color = color
        self.size = size
        self.duration = duration
        self.velocity = Double.random(in: 1...4)
    }
    
    mutating func update() {
        y += velocity
        velocity += 0.1 // Gravity
        opacity = max(0, opacity - 0.01)
    }
}

// MARK: - Winning Line Data

struct WinningLine {
    let type: WinningLineType
    let index: Int
    let positions: [(Int, Int)]
}

enum WinningLineType {
    case horizontal
    case vertical  
    case diagonal
}

#Preview {
    ModernVictoryView(
        gameResult: .win(.x),
        gameMode: .normal,
        botPlayer: nil,
        winningLine: WinningLine(type: .horizontal, index: 0, positions: [(0, 0), (0, 1), (0, 2)]),
        onPlayAgain: {},
        onBackToMenu: {}
    )
}