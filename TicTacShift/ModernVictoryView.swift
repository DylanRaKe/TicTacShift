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
    let moveCount: Int
    let onPlayAgain: () -> Void
    let onBackToMenu: () -> Void

    @State private var showContent = false
    @State private var animateBadge = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 28) {
                NeonGlass(cornerRadius: 36, strokeOpacity: 0.22, shadowColor: .neonMagenta.opacity(0.35)) {
                    VStack(spacing: 20) {
                        badge
                        titleBlock
                        if let winningLine { winningLineBlock(winningLine) }
                        modeStats
                    }
                }

                buttonsStack
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 40)
            .scaleEffect(showContent ? 1 : 0.86)
            .opacity(showContent ? 1 : 0)

            if !reduceMotion {
                ParticleSystemView(isActive: showContent, gameResult: gameResult, reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
            }
        }
        .onAppear { startSequence() }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(badgeGradient)
                .frame(width: 110, height: 110)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                )
                .shadow(color: primaryColor.opacity(0.5), radius: 18, y: 12)

            Image(systemName: badgeIcon)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        }
        .scaleEffect(reduceMotion ? 1 : animateBadge ? 1.08 : 0.94)
        .rotationEffect(.degrees(reduceMotion ? 0 : animateBadge ? 6 : -4))
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animateBadge)
    }

    private var titleBlock: some View {
        VStack(spacing: 14) {
            Text(titleText)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.6), radius: 14, y: 6)

            Text(subtitleText)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(primaryColor)
        }
    }

    private func winningLineBlock(_ line: WinningLine) -> some View {
        VStack(spacing: 12) {
            Text("Ligne victorieuse")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .foregroundColor(primaryColor)
                Text(lineDescription(line))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.08), in: Capsule())
        }
    }

    private var modeStats: some View {
        HStack(spacing: 18) {
            StatBadge(title: "Mode", value: gameModeLabel, icon: gameMode.icon)
            StatBadge(title: "Tours", value: "\(max(moveCount, 1))", icon: "timer")
            if case .win(let winner) = gameResult {
                StatBadge(title: "MVP", value: playerName(for: winner), icon: "crown.fill")
            } else if case .draw = gameResult {
                StatBadge(title: "Statut", value: "Égalité", icon: "equal")
            }
        }
    }

    private var buttonsStack: some View {
        VStack(spacing: 14) {
            Button(action: onPlayAgain) {
                Label("Relancer une manche", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .buttonStyle(NeonButtonStyle(
                gradient: LinearGradient(colors: [Color.neonMagenta, Color.neonBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
            ))

            Button(action: onBackToMenu) {
                Label("Retour au menu", systemImage: "house")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .buttonStyle(NeonButtonStyle(
                gradient: LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
                foreground: .white.opacity(0.85),
                scale: 0.98
            ))
        }
    }

    private var primaryColor: Color {
        switch gameResult {
        case .win(let player):
            return player == .x ? .neonMagenta : .neonCyan
        case .draw:
            return .neonYellow
        case .ongoing:
            return .white
        }
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(colors: [primaryColor.opacity(0.28), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var badgeIcon: String {
        switch gameResult {
        case .win:
            return "crown.fill"
        case .draw:
            return "equal.circle.fill"
        case .ongoing:
            return "circle"
        }
    }

    private var titleText: String {
        switch gameResult {
        case .win:
            return "Victoire !"
        case .draw:
            return "Égalité serrée"
        case .ongoing:
            return "Partie en cours"
        }
    }

    private var subtitleText: String {
        switch gameResult {
        case .win(let winner):
            return "\(playerName(for: winner)) prend l'avantage"
        case .draw:
            return "Personne ne cède"
        case .ongoing:
            return "La bataille continue"
        }
    }

    private var gameModeLabel: String {
        switch gameMode {
        case .normal: return "Local"
        case .bot: return "Bot"
        case .versus: return "Versus"
        }
    }

    private func playerName(for player: Player) -> String {
        if gameMode == .bot {
            return player == botPlayer ? "Bot" : "Vous"
        }
        return "Joueur \(player.rawValue)"
    }

    private func lineDescription(_ line: WinningLine) -> String {
        switch line.type {
        case .horizontal:
            return "Ligne horizontale \(line.index + 1)"
        case .vertical:
            return "Colonne \(line.index + 1)"
        case .diagonal:
            return line.index == 0 ? "Diagonale ↘" : "Diagonale ↙"
        }
    }

    private func startSequence() {
        if reduceMotion {
            showContent = true
            return
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            showContent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateBadge = true
        }
    }
}

private struct StatBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
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
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }
        }
        .onAppear {
            guard isActive, !reduceMotion else { return }
            generateParticles()
            animateParticles()
        }
    }

    private func generateParticles() {
        let count: Int
        switch gameResult {
        case .win:
            count = 28
        case .draw:
            count = 16
        case .ongoing:
            count = 0
        }

        particles = (0..<count).map { index in
            VictoryParticle(
                id: UUID(),
                position: CGPoint(x: Double.random(in: 0...1), y: Double.random(in: 0...1)),
                speed: Double.random(in: 0.4...1.2),
                angle: Double.random(in: 0...(Double.pi * 2)),
                color: particleColors.randomElement() ?? .white,
                size: Double.random(in: 4...10),
                delay: Double(index) * 0.08
            )
        }
    }

    private var particleColors: [Color] {
        switch gameResult {
        case .win(let player):
            return [player == .x ? .neonMagenta : .neonCyan, .neonYellow, .white]
        case .draw:
            return [.neonYellow, .white.opacity(0.9)]
        case .ongoing:
            return [.white]
        }
    }

    private func animateParticles() {
        for index in particles.indices {
            let delay = particles[index].delay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                particles[index].isActive = true
            }
        }
    }
}

struct VictoryParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let speed: Double
    let angle: Double
    let color: Color
    let size: Double
    let delay: Double
    var isActive: Bool = false
}

struct ParticleView: View {
    @State var particle: VictoryParticle

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .opacity(particle.isActive ? 0 : 1)
            .offset(x: particle.isActive ? CGFloat(cos(particle.angle) * 140) : 0,
                    y: particle.isActive ? CGFloat(sin(particle.angle) * 140) : 0)
            .animation(
                .easeOut(duration: particle.speed),
                value: particle.isActive
            )
    }
}
