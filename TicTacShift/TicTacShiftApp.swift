//
//  TicTacShiftApp.swift
//  TicTacShift
//
//  Created by Novalan on 8/29/25.
//

import SwiftUI
import SwiftData

@main
struct TicTacShiftApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TicTacShiftGame.self,
            GameMove.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("🚀 App launched - Local mode only")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
