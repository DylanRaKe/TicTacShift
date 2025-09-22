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
    let botPlayer: Player?
    let onComplete: () -> Void

    @State private var animationPhase: AnimationPhase = .initial
    @State private var crossScale: CGFloat = 0.6
    @State private var circleScale: CGFloat = 0.6
    @State private var crossOpacity: Double = 0.2
    @State private var circleOpacity: Double = 0.2
    @State private var spotlight = false
    @State private var messageOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum AnimationPhase {
        case initial, showingBoth, revealing, complete
    }

    var body: some View {
        ZStack {
            NeonBackground(animate: true)

            VStack(spacing: 40) {
                Spacer()

                NeonGlass(cornerRadius: 40, strokeOpacity: 0.2, shadowColor: .neonMagenta.opacity(0.35)) {
                    VStack(spacing: 28) {
                        VStack(spacing: 12) {
                            Text("Qui prend la main ?")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.95))
                                .opacity(animationPhase == .initial ? 0 : 1)
                                .animation(.easeOut(duration: 0.6), value: animationPhase)

                            NeonCapsule(title: gameModeTitle, systemImage: gameMode.icon, colors: gameMode.gradient)
                                .scaleEffect(animationPhase == .initial ? 0.8 : 1)
                                .opacity(animationPhase == .initial ? 0 : 1)
                                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1), value: animationPhase)
                        }

                        HStack(spacing: 40) {
                            PlayerRevealSymbol(
                                player: .x,
                                scale: crossScale,
                                opacity: crossOpacity,
                                isWinner: firstPlayer == .x && animationPhase == .revealing,
                                spotlight: spotlight,
                                reduceMotion: reduceMotion
                            )

                            VStack(spacing: 6) {
                                Text("VS")
                                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.65))
                                    .opacity(animationPhase == .initial ? 0 : 1)
                                Divider()
                                    .frame(height: 32)
                                    .overlay(Color.white.opacity(0.2))
                            }

                            PlayerRevealSymbol(
                                player: .o,
                                scale: circleScale,
                                opacity: circleOpacity,
                                isWinner: firstPlayer == .o && animationPhase == .revealing,
                                spotlight: spotlight,
                                reduceMotion: reduceMotion
                            )
                        }

                        VStack(spacing: 12) {
                            Text("✨")
                                .font(.system(size: 42))
                                .opacity(messageOpacity)
                                .scaleEffect(messageOpacity)
                                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: messageOpacity)

                            Text("\(playerName(firstPlayer)) commence !")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(firstPlayer == .x ? .neonMagenta : .neonCyan)
                                .opacity(messageOpacity)
                                .scaleEffect(messageOpacity * 0.3 + 0.7)
                                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2), value: messageOpacity)
                        }
                        .frame(height: 90)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Text("Tapote pour lancer la partie")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(animationPhase == .complete ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: animationPhase)
            }
            .padding(.top, 60)
        }
        .onAppear { startRevealSequence() }
        .contentShape(Rectangle())
        .onTapGesture {
            if animationPhase == .complete { onComplete() }
        }
    }

    private var gameModeTitle: String {
        switch gameMode {
        case .normal: return "Duel local"
        case .bot: return "Défi bot"
        case .versus: return "Versus"
        }
    }

    private func playerName(_ player: Player) -> String {
        switch gameMode {
        case .bot:
            return player == botPlayer ? "Le bot" : "Toi"
        case .normal, .versus:
            return "Joueur \(player.rawValue)"
        }
    }

    private func startRevealSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            animationPhase = .showingBoth
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                crossScale = 1.0
                circleScale = 1.0
                crossOpacity = 0.9
                circleOpacity = 0.9
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            animationPhase = .revealing
            spotlight = true

            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                if firstPlayer == .x {
                    circleOpacity = 0.2
                    circleScale = 0.75
                } else {
                    crossOpacity = 0.2
                    crossScale = 0.75
                }
            }

            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                messageOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            animationPhase = .complete
            withAnimation(.easeOut(duration: 0.6)) {
                onComplete()
            }
        }
    }
}

private struct PlayerRevealSymbol: View {
    let player: Player
    let scale: CGFloat
    let opacity: Double
    let isWinner: Bool
    let spotlight: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(symbolGradient)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
                )
                .shadow(color: baseColor.opacity(0.45), radius: isWinner ? 24 : 12, y: 10)

            Text(player.rawValue)
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: baseColor.opacity(0.6), radius: 14, y: 8)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .overlay(
            Circle()
                .stroke(baseColor.opacity(isWinner ? 0.8 : 0.25), lineWidth: 6)
                .blur(radius: 6)
                .scaleEffect(spotlight ? 1.15 : 0.95)
                .opacity(reduceMotion ? 0 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: spotlight)
        )
    }

    private var baseColor: Color {
        player == .x ? .neonMagenta : .neonCyan
    }

    private var symbolGradient: LinearGradient {
        LinearGradient(colors: [baseColor.opacity(0.25), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    PlayerRevealView(firstPlayer: .x, gameMode: .normal, botPlayer: nil, onComplete: {})
}
