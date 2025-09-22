//
//  ContentView.swift
//  TicTacShift
//
//  Created by Novalan on 8/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showOfflineModal = false
    @State private var animateBackground = false
    @State private var navigationPath = NavigationPath()
    @State private var hasBootstrapped = false

    private let featureHighlights: [GameFeature] = [
        GameFeature(
            icon: "sparkles",
            title: "Shift Instinctif",
            description: "Les symboles se déplacent et disparaissent après trois tours. Maîtrisez le tempo pour prendre l'avantage.",
            gradient: [Color.neonMagenta, Color.neonBlue]
        ),
        GameFeature(
            icon: "bolt.horizontal.circle",
            title: "Rythme Arcade",
            description: "Animations rebondissantes, feedback lumineux, tout est pensé pour garder la tension maximale.",
            gradient: [Color.neonCyan, Color.neonYellow]
        ),
        GameFeature(
            icon: "network",
            title: "Connexion Express",
            description: "Affrontez vos amis sur le même réseau en quelques secondes grâce au mode en ligne simplifié.",
            gradient: [Color.neonBlue, Color.purple]
        )
    ]

    private let vibeTokens: [VibeToken] = [
        VibeToken(title: "Parties rapides", value: "3 à 5 min", icon: "timer"),
        VibeToken(title: "Intensité", value: "⚡⚡⚡⚡", icon: "flame.fill"),
        VibeToken(title: "Accessibilité", value: "Solo & Duo", icon: "person.2.fill")
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                NeonBackground(animate: animateBackground)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 44) {
                        heroSection
                        modeSelector
                        featureGrid
                        vibeFooter
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 42)
                }
            }
            .navigationDestination(for: GameMode.self) { mode in
                GameFlowView(gameMode: mode)
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "multiplayer" {
                    SimpleMultiplayerView()
                }
            }
            .task {
                startAnimations()
            }
        }
        .sheet(isPresented: $showOfflineModal) {
            OfflineGameModal(isPresented: $showOfflineModal) { mode in
                navigationPath.append(mode)
            }
            .background(NeonBackground(animate: animateBackground))
        }
    }

    private var heroSection: some View {
        VStack(spacing: 26) {
            NeonGlass(cornerRadius: 36, strokeOpacity: 0.32, shadowColor: .neonMagenta.opacity(0.35)) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 14) {
                        NeonCapsule(title: "Arcade Shift", systemImage: "gamecontroller.fill")
                        NeonCapsule(title: "Nouvelle Saison", systemImage: "sparkle.magnifyingglass", colors: [Color.neonYellow, Color.neonMagenta])
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("TicTacShift")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.white, Color.neonCyan.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: Color.neonCyan.opacity(0.4), radius: 18, y: 10)

                        Text("Le morpion qui pulse enfin comme un jeu d'arcade.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.85))
                    }

                    AnimatedHeroBoard()
                        .padding(.top, 6)

                    HStack(spacing: 18) {
                        ForEach(vibeTokens) { token in
                            VibeCard(token: token)
                        }
                    }
                }
            }

            Text("Choisis la vibe de ta prochaine partie")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
        }
    }

    private var modeSelector: some View {
        VStack(spacing: 18) {
            ModeHeader()

            VStack(spacing: 18) {
                ModeCard(
                    title: "Duel local instantané",
                    subtitle: "Basculer entre duel humain ou bot sans quitter le flow.",
                    icon: "person.2.wave.2.fill",
                    colors: [Color.neonBlue, Color.neonMagenta],
                    action: { showOfflineModal = true }
                )

                ModeCard(
                    title: "Versus réseau",
                    subtitle: "Connectez-vous à vos amis sur le même Wi-Fi et entrez dans l'arène.",
                    icon: "antenna.radiowaves.left.and.right",
                    colors: [Color.neonCyan, Color.neonYellow],
                    action: { navigationPath.append("multiplayer") }
                )
            }
        }
    }

    private var featureGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ce qui change tout")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 18, alignment: .top)], spacing: 18) {
                ForEach(featureHighlights) { feature in
                    FeatureTile(feature: feature)
                }
            }
        }
    }

    private var vibeFooter: some View {
        VStack(spacing: 16) {
            Divider().background(Color.white.opacity(0.2))

            HStack(spacing: 18) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.neonCyan)
                    .shadow(color: .neonCyan.opacity(0.5), radius: 12, y: 6)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Shift tes parties classiques")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Un plateau qui respire, une interface bouncy, des animations signature.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
        }
    }

    private func startAnimations() {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        withAnimation(.easeInOut(duration: 1.2)) {
            animateBackground = true
        }
    }
}

// MARK: - Supporting Views

private struct ModeHeader: View {
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                    )
                Image(systemName: "rectangle.grid.3x2")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.neonYellow)
                    .shadow(color: .neonYellow.opacity(0.6), radius: glow ? 18 : 6)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glow)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sélection des modes")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                Text("Choisissez votre style de confrontation en un tap.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .onAppear {
            guard !reduceMotion else { return }
            glow = true
        }
    }
}

private struct ModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: colors.last?.opacity(0.5) ?? .black.opacity(0.3), radius: 18, y: 9)
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(subtitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Interface vibing et feedback lumineux")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
                    )
                    .shadow(color: colors.first?.opacity(0.3) ?? .black.opacity(0.3), radius: 26, y: 16)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { isHovered = true },
            onRelease: { isHovered = false }
        )
    }
}

private struct FeatureTile: View {
    let feature: GameFeature
    @State private var shimmer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: feature.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: feature.gradient.last?.opacity(0.4) ?? .black.opacity(0.3), radius: 18, y: 10)
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(reduceMotion ? 1 : shimmer ? 1.05 : 0.95)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: shimmer)

            Text(feature.title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(feature.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(colors: feature.gradient.map { $0.opacity(0.3) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.1
                        )
                )
        )
        .onAppear {
            guard !reduceMotion else { return }
            shimmer = true
        }
    }
}

private struct VibeCard: View {
    let token: VibeToken
    @State private var highlight = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: token.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(token.title.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(token.value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.neonCyan.opacity(highlight ? 0.4 : 0.12), lineWidth: 2)
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: highlight)
        .onAppear {
            guard !reduceMotion else { return }
            highlight = true
        }
    }
}

private struct AnimatedHeroBoard: View {
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let layout: [[HeroBoardSymbol]] = [
        [.x, .shift, .empty],
        [.o, .empty, .x],
        [.shift, .o, .empty]
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Aperçu dynamique du plateau")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 10) {
                ForEach(0..<layout.count, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<layout[row].count, id: \.self) { column in
                            HeroTile(symbol: layout[row][column], glow: glow, reduceMotion: reduceMotion)
                        }
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .neonCyan.opacity(0.25), radius: 16, y: 10)
            )
        }
        .onAppear {
            guard !reduceMotion else { return }
            glow = true
        }
    }
}

private struct GameFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

private struct VibeToken: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
}

private enum HeroBoardSymbol {
    case x, o, shift, empty

    var gradient: LinearGradient {
        switch self {
        case .x:
            return LinearGradient(colors: [Color.neonMagenta, Color.neonBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .o:
            return LinearGradient(colors: [Color.neonCyan, Color.neonYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .shift:
            return LinearGradient(colors: [Color.purple, Color.neonCyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .empty:
            return LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var shadowColor: Color {
        switch self {
        case .x:
            return Color.neonMagenta.opacity(0.35)
        case .o:
            return Color.neonCyan.opacity(0.35)
        case .shift:
            return Color.neonYellow.opacity(0.35)
        case .empty:
            return Color.white.opacity(0.15)
        }
    }

    var scale: CGFloat {
        switch self {
        case .shift:
            return 1.08
        case .x, .o:
            return 1.05
        case .empty:
            return 1.0
        }
    }

    var animationDuration: Double {
        switch self {
        case .x: return 1.4
        case .o: return 1.6
        case .shift: return 1.8
        case .empty: return 2.1
        }
    }
}

private struct HeroTile: View {
    let symbol: HeroBoardSymbol
    let glow: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(symbol.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: symbol.shadowColor, radius: 18, y: 10)

            symbolContent
        }
        .frame(width: 64, height: 64)
        .scaleEffect(reduceMotion ? 1 : glow ? symbol.scale : 0.95)
        .animation(reduceMotion ? nil : .easeInOut(duration: symbol.animationDuration).repeatForever(autoreverses: true), value: glow)
    }

    @ViewBuilder
    private var symbolContent: some View {
        switch symbol {
        case .x:
            Text("X")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 6, y: 4)
        case .o:
            Text("O")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 6, y: 4)
        case .shift:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 4, y: 4)
        case .empty:
            Circle()
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 2)
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 12, height: 12)
                )
        }
    }
}

#Preview {
    ContentView()
}
