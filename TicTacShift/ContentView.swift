//
//  ContentView.swift
//  TicTacShift
//
//  Created by Novalan on 8/29/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showOfflineModal = false
    @State private var animateElements = false
    @State private var navigationPath = NavigationPath()
    @State private var heroBounce = false
    @State private var glowPulse = false
    @State private var hasStartedAnimations = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var featureHighlights: [GameFeature] {
        [
            GameFeature(
                icon: "sparkles",
                title: "Shift magique",
                description: "Faites disparaître vos anciens coups après trois tours pour libérer de nouvelles stratégies.",
                colors: [Color.purple, Color.blue]
            ),
            GameFeature(
                icon: "arrow.triangle.2.circlepath",
                title: "Tension permanente",
                description: "Chaque déplacement change la donne : anticipez, adaptez-vous et surprenez votre adversaire.",
                colors: [Color.orange, Color.pink]
            ),
            GameFeature(
                icon: "wifi",
                title: "Multijoueur instantané",
                description: "Connectez-vous en un clin d'œil sur le même réseau et partagez des duels endiablés.",
                colors: [Color.green, Color.teal]
            )
        ]
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AnimatedBackgroundView(animateElements: animateElements)

                ScrollView {
                    VStack(spacing: 36) {
                        Spacer(minLength: 32)

                        heroHeaderView

                        mainActionButtons

                        featuresSection

                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: GameMode.self) { mode in
                GameFlowView(gameMode: mode)
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "multiplayer" {
                    SimpleMultiplayerView()
                }
            }
        }
        .sheet(isPresented: $showOfflineModal) {
            OfflineGameModal(isPresented: $showOfflineModal) { mode in
                navigationPath.append(mode)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var heroHeaderView: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.27, green: 0.16, blue: 0.85),
                                Color(red: 0.19, green: 0.49, blue: 0.96),
                                Color(red: 0.31, green: 0.82, blue: 0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1.5)
                    )
                    .shadow(color: Color.blue.opacity(0.35), radius: 40, y: 24)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 250
                        )
                    )
                    .scaleEffect(glowPulse ? 1.15 : 0.9)
                    .offset(x: -40, y: -60)
                    .opacity(reduceMotion ? 0.18 : 0.3)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 3.4).repeatForever(autoreverses: true),
                        value: glowPulse
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.01)],
                            center: .bottomTrailing,
                            startRadius: 30,
                            endRadius: 220
                        )
                    )
                    .scaleEffect(glowPulse ? 1.1 : 0.95)
                    .offset(x: 140, y: 160)
                    .opacity(reduceMotion ? 0.15 : 0.22)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 3.6).repeatForever(autoreverses: true),
                        value: glowPulse
                    )

                VStack(alignment: .leading, spacing: 20) {
                    Label("Mode Shift intensifié", systemImage: "bolt.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.18), in: Capsule())
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("TicTacShift")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.25), radius: 8, y: 6)

                        Text("Le morpion repensé en duel rythmé")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.92))
                    }

                    HeroBoardPreview(glow: glowPulse, reduceMotion: reduceMotion)
                }
                .padding(28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 290)
            .scaleEffect(reduceMotion ? 1 : heroBounce ? 1.03 : 0.97)
            .animation(
                reduceMotion ? nil : .spring(response: 1.6, dampingFraction: 0.68).repeatForever(autoreverses: true),
                value: heroBounce
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Glissez, anticipez, vibrez.")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Une interface chatoyante pour un gameplay qui bouge sans cesse.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }

    private var mainActionButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choisis ton terrain de jeu")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            Button {
                showOfflineModal = true
            } label: {
                CompactModeButton(
                    title: "Mode Local",
                    subtitle: "Affrontez un ami sur le même appareil",
                    icon: "iphone.gen3",
                    color: Color.blue
                )
            }
            .buttonStyle(BouncyButtonStyle())

            Button {
                navigationPath.append("multiplayer")
            } label: {
                CompactModeButton(
                    title: "Mode En Ligne",
                    subtitle: "Multijoueur WiFi ultra fluide",
                    icon: "bolt.horizontal.circle",
                    color: Color.green
                )
            }
            .buttonStyle(BouncyButtonStyle())
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pourquoi tu vas adorer")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                ForEach(featureHighlights) { feature in
                    FeatureCard(feature: feature, glow: glowPulse, reduceMotion: reduceMotion)
                }
            }
        }
    }

    private func startAnimations() {
        guard !hasStartedAnimations else { return }
        hasStartedAnimations = true

        if reduceMotion {
            animateElements = true
            heroBounce = true
            glowPulse = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animateElements = true
                heroBounce = true
                glowPulse = true
            }
        }
    }
}

// MARK: - Supporting Models & Views

internal struct GameFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let colors: [Color]
}

struct AnimatedBackgroundView: View {
    let animateElements: Bool
    @State private var rotateOuter = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.05, blue: 0.18),
                    Color(red: 0.09, green: 0.08, blue: 0.3),
                    Color(red: 0.05, green: 0.15, blue: 0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if reduceMotion {
                Color.clear
            } else {
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink.opacity(0.55), Color.purple.opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: size * 1.35, height: size * 1.35)
                            .blur(radius: 140)
                            .offset(
                                x: animateElements ? -size * 0.28 : -size * 0.45,
                                y: animateElements ? -size * 0.38 : -size * 0.55
                            )
                            .animation(
                                .easeInOut(duration: 5.5).repeatForever(autoreverses: true),
                                value: animateElements
                            )

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.45), Color.cyan.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: size * 1.1, height: size * 1.1)
                            .blur(radius: 120)
                            .offset(
                                x: animateElements ? size * 0.32 : size * 0.18,
                                y: animateElements ? size * 0.36 : size * 0.2
                            )
                            .animation(
                                .easeInOut(duration: 6.2).repeatForever(autoreverses: true),
                                value: animateElements
                            )

                        RoundedRectangle(cornerRadius: size * 0.6, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                            .frame(width: size * 1.4, height: size * 1.4)
                            .rotationEffect(.degrees(rotateOuter ? 360 : 0))
                            .opacity(0.35)
                            .animation(
                                .linear(duration: 38).repeatForever(autoreverses: false),
                                value: rotateOuter
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: animateElements) { newValue in
            guard newValue, !reduceMotion else { return }
            rotateOuter = true
        }
        .onAppear {
            if animateElements && !reduceMotion {
                rotateOuter = true
            }
        }
    }
}

struct CompactModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @State private var shimmer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(backgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1.1)
                    )
                    .shadow(color: color.opacity(0.35), radius: 28, y: 18)

                if !reduceMotion {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.28))
                        .frame(width: width * 0.4)
                        .blur(radius: 40)
                        .rotationEffect(.degrees(20))
                        .offset(x: shimmer ? width : -width * 0.8)
                        .animation(
                            .linear(duration: 3.2).repeatForever(autoreverses: false),
                            value: shimmer
                        )
                }

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(iconBackground)
                                .frame(width: 58, height: 58)
                                .shadow(color: color.opacity(0.4), radius: 16, y: 8)

                            Image(systemName: icon)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 6, y: 4)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white)

                            Text(subtitle)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.8))
                        Text("Tapote pour une partie énergique !")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                }
                .padding(26)
            }
            .onAppear {
                guard !reduceMotion else { return }
                shimmer = true
            }
        }
        .frame(height: 150)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.9),
                color.opacity(0.7),
                color.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.28),
                Color.white.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct FeatureCard: View {
    let feature: GameFeature
    let glow: Bool
    let reduceMotion: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: feature.colors.last?.opacity(0.35) ?? Color.black.opacity(0.25), radius: 18, y: 9)

                Image(systemName: feature.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .scaleEffect(reduceMotion ? 1 : glow ? 1.06 : 0.94)
            .animation(
                reduceMotion ? nil : .spring(response: 1.4, dampingFraction: 0.72).repeatForever(autoreverses: true),
                value: glow
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(feature.description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: feature.colors.map { $0.opacity(0.35) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.1
                        )
                )
                .shadow(color: feature.colors.first?.opacity(0.18) ?? Color.black.opacity(0.12), radius: 18, y: 12)
        )
    }
}

struct HeroBoardPreview: View {
    let glow: Bool
    let reduceMotion: Bool

    private let board: [[HeroBoardSymbol]] = [
        [.x, .o, .x],
        [.empty, .shift, .o],
        [.x, .empty, .o]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<board.count, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<board[row].count, id: \.self) { column in
                        HeroTile(symbol: board[row][column], glow: glow, reduceMotion: reduceMotion)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

private enum HeroBoardSymbol {
    case x
    case o
    case shift
    case empty

    var gradient: LinearGradient {
        switch self {
        case .x:
            return LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.32, blue: 0.98),
                    Color(red: 0.41, green: 0.45, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .o:
            return LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.58, blue: 0.42),
                    Color(red: 0.99, green: 0.78, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .shift:
            return LinearGradient(
                colors: [
                    Color(red: 0.29, green: 0.92, blue: 0.76),
                    Color(red: 0.31, green: 0.76, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .empty:
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var shadowColor: Color {
        switch self {
        case .x:
            return Color.purple.opacity(0.35)
        case .o:
            return Color.orange.opacity(0.35)
        case .shift:
            return Color.green.opacity(0.35)
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
        case .x:
            return 1.6
        case .o:
            return 1.8
        case .shift:
            return 2.0
        case .empty:
            return 2.4
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
                .shadow(color: symbol.shadowColor, radius: 16, y: 9)

            symbolContent
        }
        .frame(width: 64, height: 64)
        .scaleEffect(reduceMotion ? 1 : glow ? symbol.scale : 0.95)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: symbol.animationDuration).repeatForever(autoreverses: true),
            value: glow
        )
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
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 4, y: 4)
        case .empty:
            Circle()
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 12, height: 12)
                )
        }
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(
                .spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.2),
                value: configuration.isPressed
            )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TicTacShiftGame.self, GameMove.self], inMemory: true)
}
