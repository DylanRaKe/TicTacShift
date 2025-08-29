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

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond sobre et moderne
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // En-tête moderne
                        modernHeaderView
                        
                        // Sélection des modes
                        modernModeSection
                        
                        // Informations
                        modernFooterView
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 50)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var modernHeaderView: some View {
        VStack(spacing: 24) {
            // Logo moderne et sobre
            ZStack {
                // Fond subtil
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                
                // Icône
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 40, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("TicTacShift")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text("L'évolution du morpion")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var modernModeSection: some View {
        VStack(spacing: 24) {
            HStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 32, height: 1)
                
                Text("Choisir un mode")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 32, height: 1)
            }
            
            LazyVStack(spacing: 16) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    if mode.isEnabled {
                        NavigationLink {
                            if mode == .versus {
                                VersusView()
                            } else {
                                GameBoardView(game: TicTacShiftGame(gameMode: mode))
                            }
                        } label: {
                            ModernModeButtonView(mode: mode)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ModernModeButtonView(mode: mode)
                    }
                }
            }
        }
    }
    
    private var modernFooterView: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 0.5)
            
            VStack(spacing: 8) {
                Text("Les pièces disparaissent après 3 tours complets")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
                
                Text("La stratégie évolue • Les parties ne s'enlisent jamais")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
}

struct ModernModeButtonView: View {
    let mode: GameMode
    
    var modeTitle: String {
        switch mode {
        case .normal:
            return "Normal"
        case .bot:
            return "vs Bot"
        case .versus:
            return "Versus"
        }
    }
    
    var modeDescription: String {
        switch mode {
        case .normal:
            return "Jouer contre un autre joueur"
        case .bot:
            return "Défier l'intelligence artificielle"
        case .versus:
            return "Jouer en ligne via Game Center"
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Icône moderne
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        mode.isEnabled ?
                        LinearGradient(
                            colors: mode.gradient.map { $0.opacity(0.8) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray4), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(mode.isEnabled ? .white : .gray)
            }
            
            // Texte sobre
            VStack(alignment: .leading, spacing: 4) {
                Text(modeTitle)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(mode.isEnabled ? .primary : .secondary)
                
                Text(modeDescription)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Indicateur d'état
            Image(systemName: mode.isEnabled ? "chevron.right" : "lock.fill")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(mode.isEnabled ? .blue : .gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: mode.isEnabled ? Color.black.opacity(0.1) : Color.clear,
                    radius: mode.isEnabled ? 8 : 0,
                    x: 0,
                    y: mode.isEnabled ? 4 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    mode.isEnabled ?
                    LinearGradient(
                        colors: mode.gradient.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color(.systemGray4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(mode.isEnabled ? 1.0 : 0.98)
        .animation(.spring(response: 0.3), value: mode.isEnabled)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TicTacShiftGame.self, GameMove.self], inMemory: true)
}