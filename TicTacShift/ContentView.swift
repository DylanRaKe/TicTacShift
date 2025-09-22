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
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Dynamic animated background
                AnimatedBackgroundView(animateElements: animateElements)
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 20)
                        
                        // Hero header
                        heroHeaderView
                        
                        // Main action buttons
                        mainActionButtons
                        
                        // Game features
                        featuresSection
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
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
        VStack(spacing: 16) {
            // Simple logo
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Title
            VStack(spacing: 8) {
                Text("TicTacShift")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("L'évolution du morpion")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var mainActionButtons: some View {
        VStack(spacing: 16) {
            // Local Mode Button
            Button {
                showOfflineModal = true
            } label: {
                CompactModeButton(
                    title: "Mode Local",
                    subtitle: "Jouer sur cet appareil",
                    icon: "iphone",
                    color: .blue
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Simple Multiplayer Button
            NavigationLink(value: "multiplayer") {
                CompactModeButton(
                    title: "Mode En Ligne",
                    subtitle: "Multijoueur local via WiFi",
                    icon: "globe",
                    color: .green
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 12) {
            Text("Particularités")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("• Les pièces disparaissent après 3 tours complets")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("• Aucune partie ne peut rester bloquée")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                
                Text("• Stratégie en constante évolution")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func startAnimations() {
        if !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateElements = true
            }
        } else {
            animateElements = true
        }
    }
}

// MARK: - Supporting Views

struct AnimatedBackgroundView: View {
    let animateElements: Bool
    
    var body: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.systemGray6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct CompactModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [TicTacShiftGame.self, GameMove.self], inMemory: true)
}