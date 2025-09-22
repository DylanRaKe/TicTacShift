//
//  PlayerRevealView.swift
//  TicTacShift
//
//  Player reveal animation screen showing who starts first
//

import SwiftUI

struct PlayerRevealView: View {
    let firstPlayer: Player
    let gameMode: GameMode
    let botPlayer: Player? // Which player is the bot in bot mode
    let onComplete: () -> Void
    
    @State private var animationPhase: AnimationPhase = .initial
    @State private var crossScale: CGFloat = 0
    @State private var circleScale: CGFloat = 0
    @State private var crossOpacity: Double = 0.3
    @State private var circleOpacity: Double = 0.3
    @State private var selectedPlayerGlow: Double = 0
    @State private var messageOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    enum AnimationPhase {
        case initial
        case showingBoth
        case revealing
        case complete
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching game mode
            LinearGradient(
                colors: gameMode.gradient.map { $0.opacity(0.1) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title
                VStack(spacing: 16) {
                    Text("Qui commence ?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(animationPhase == .initial ? 0 : 1)
                        .animation(.easeOut(duration: 0.6), value: animationPhase)
                    
                    // Mode indicator
                    HStack {
                        Image(systemName: gameMode.icon)
                            .foregroundColor(.blue)
                        Text(gameMode == .normal ? "Normal" : gameMode == .bot ? "vs Bot" : "Versus")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    .opacity(animationPhase == .initial ? 0 : 1)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animationPhase)
                }
                
                // Player symbols with animations
                HStack(spacing: 60) {
                    // Cross (X)
                    PlayerSymbolView(
                        player: .x,
                        scale: crossScale,
                        opacity: crossOpacity,
                        glowIntensity: firstPlayer == .x ? selectedPlayerGlow : 0,
                        isSelected: firstPlayer == .x && animationPhase == .revealing,
                        gameMode: gameMode,
                        reduceMotion: reduceMotion
                    )
                    
                    Text("VS")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .opacity(animationPhase == .initial ? 0 : 0.8)
                        .scaleEffect(animationPhase == .showingBoth ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animationPhase)
                    
                    // Circle (O)
                    PlayerSymbolView(
                        player: .o,
                        scale: circleScale,
                        opacity: circleOpacity,
                        glowIntensity: firstPlayer == .o ? selectedPlayerGlow : 0,
                        isSelected: firstPlayer == .o && animationPhase == .revealing,
                        gameMode: gameMode,
                        reduceMotion: reduceMotion
                    )
                }
                
                // Winner message
                VStack(spacing: 12) {
                    Text("🎯")
                        .font(.system(size: 40))
                        .opacity(messageOpacity)
                        .scaleEffect(messageOpacity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: messageOpacity)
                    
                    Text("\(getPlayerName(firstPlayer)) commence !")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(firstPlayer == .x ? .blue : .red)
                        .opacity(messageOpacity)
                        .scaleEffect(messageOpacity * 0.3 + 0.7)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: messageOpacity)
                }
                .frame(height: 100)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 40)
        }
        .onAppear {
            startRevealSequence()
        }
        .onTapGesture {
            if animationPhase == .complete {
                onComplete()
            }
        }
    }
    
    private func getPlayerName(_ player: Player) -> String {
        switch gameMode {
        case .normal:
            return "Joueur \(player.rawValue)"
        case .bot:
            return player == botPlayer ? "Bot" : "Joueur \(player.rawValue)"
        case .versus:
            return "Joueur \(player.rawValue)"
        }
    }
    
    private func startRevealSequence() {
        // Phase 1: Show both symbols (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = .showingBoth
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                crossScale = 1.0
                circleScale = 1.0
                crossOpacity = 0.8
                circleOpacity = 0.8
            }
        }
        
        // Phase 2: Reveal winner (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            animationPhase = .revealing
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                // Fade out the non-selected player
                if firstPlayer == .x {
                    circleOpacity = 0.2
                    circleScale = 0.8
                } else {
                    crossOpacity = 0.2
                    crossScale = 0.8
                }
                
                // Highlight selected player
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        selectedPlayerGlow = 1.0
                    }
                }
            }
            
            // Show message
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                messageOpacity = 1.0
            }
        }
        
        // Phase 3: Auto-complete (3s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            animationPhase = .complete
            
            withAnimation(.easeOut(duration: 0.5)) {
                onComplete()
            }
        }
    }
}

struct PlayerSymbolView: View {
    let player: Player
    let scale: CGFloat
    let opacity: Double
    let glowIntensity: Double
    let isSelected: Bool
    let gameMode: GameMode
    let reduceMotion: Bool
    
    var body: some View {
        ZStack {
            // Background circle for the symbol
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            (player == .x ? Color.blue : Color.red).opacity(0.1),
                            (player == .x ? Color.blue : Color.red).opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scale * 1.1)
                .opacity(opacity * 0.5)
            
            // Player symbol
            Text(player.rawValue)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(player == .x ? .blue : .red)
                .shadow(
                    color: (player == .x ? Color.blue : Color.red).opacity(0.5),
                    radius: glowIntensity * (reduceMotion ? 5 : 15)
                )
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Rotating ring for selected player
            if isSelected && !reduceMotion {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                (player == .x ? Color.blue : Color.red).opacity(0.8),
                                Color.clear,
                                (player == .x ? Color.blue : Color.red).opacity(0.8),
                                Color.clear
                            ],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(glowIntensity * 360))
                    .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: glowIntensity)
            }
        }
    }
}

#Preview {
    PlayerRevealView(
        firstPlayer: .x,
        gameMode: .normal,
        botPlayer: nil,
        onComplete: {}
    )
}