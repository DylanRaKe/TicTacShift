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
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Header
                modalHeader
                
                // Game mode options
                VStack(spacing: 20) {
                    // Player vs Player
                    OfflineGameModeButton(
                        title: "Joueur vs Joueur",
                        subtitle: "Défiez un ami sur le même appareil",
                        icon: "person.2.fill",
                        color: .blue,
                        animateContent: animateContent
                    ) {
                        selectMode(.normal)
                    }
                    
                    // Player vs Bot
                    OfflineGameModeButton(
                        title: "Joueur vs Bot",
                        subtitle: "Affrontez notre intelligence artificielle",
                        icon: "cpu",
                        color: .red,
                        animateContent: animateContent
                    ) {
                        selectMode(.bot)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(animateContent ? 1.0 : 0.8)
            .opacity(animateContent ? 1.0 : 0.0)
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
            } else {
                animateContent = true
            }
        }
    }
    
    private var modalHeader: some View {
        VStack(spacing: 16) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
            
            // Title
            VStack(spacing: 8) {
                Text("🎮")
                    .font(.system(size: 40))
                
                Text("Mode Offline")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Choisissez votre mode de jeu")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
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
        withAnimation(.easeInOut(duration: 0.4)) {
            animateContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPresented = false
        }
    }
}

struct OfflineGameModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let animateContent: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: isPressed ? 5 : 8, y: isPressed ? 2 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 15)
        .animation(
            .spring(response: 0.8, dampingFraction: 0.8)
                .delay(title.contains("Joueur vs Joueur") ? 0.1 : 0.2),
            value: animateContent
        )
    }
}

// Helper for press events
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
    OfflineGameModal(isPresented: .constant(true)) { mode in
        print("Selected mode: \(mode)")
    }
}