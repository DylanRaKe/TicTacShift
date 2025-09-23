//
//  OfflineGameModal.swift
//  TicTacShift
//
//  Modal for selecting offline game modes
//

import SwiftUI

struct OfflineGameModal: View {
    @Binding var isPresented: Bool
    let onModeSelected: (GameMode) -> Void

    @State private var animateContent = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismissModal() }

            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 5)

                    Text("Mode hors-ligne")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Choisissez votre configuration")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 22)

                VStack(spacing: 18) {
                    OfflineModeCard(
                        title: "Joueur vs Joueur",
                        subtitle: "Affrontez un ami sur le même appareil",
                        icon: "person.2.wave.2.fill",
                        colors: [Color.neonMagenta, Color.neonBlue]
                    ) {
                        selectMode(.normal)
                    }

                    OfflineModeCard(
                        title: "Joueur vs Bot",
                        subtitle: "Testez vos réflexes contre notre IA",
                        icon: "cpu",
                        colors: [Color.neonYellow, Color.orange]
                    ) {
                        selectMode(.bot)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.neonBackground.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 26, y: 14)
            )
            .padding(.horizontal, 24)
            .scaleEffect(animateContent ? 1 : 0.86)
            .opacity(animateContent ? 1 : 0)
        }
        .onAppear {
            if reduceMotion {
                animateContent = true
            } else {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }
        }
    }

    private func selectMode(_ mode: GameMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            animateContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onModeSelected(mode)
            isPresented = false
        }
    }

    private func dismissModal() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animateContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

private struct OfflineModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    @State private var highlight = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                        .shadow(color: colors.last?.opacity(0.4) ?? .black.opacity(0.4), radius: 18, y: 10)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(highlight ? 0.28 : 0.16), lineWidth: 1.4)
                    )
            )
            .scaleEffect(highlight ? 1.03 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7), value: highlight)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { highlight = true }, onRelease: { highlight = false })
    }
}

struct PressEvents: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    OfflineGameModal(isPresented: .constant(true)) { _ in }
}
