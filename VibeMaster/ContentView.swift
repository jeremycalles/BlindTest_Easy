//
//  ContentView.swift
//  VibeMaster
//
//  Navigation root, path state, destination routing
//

import SwiftUI
import VibeMasterCore

enum AppDestination: Hashable {
    case dashboard
    case game(GameConfig)
    case podium(PodiumResult)
}

struct ContentView: View {
    @State private var path: [AppDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            SplashView(path: $path)
                .navigationDestination(for: AppDestination.self) { dest in
                    switch dest {
                    case .dashboard:
                        DashboardView(path: $path)
                    case .game(let config):
                        GameView(config: config, path: $path)
                    case .podium(let result):
                        PodiumView(results: result, path: $path)
                    }
                }
        }
    }
}
