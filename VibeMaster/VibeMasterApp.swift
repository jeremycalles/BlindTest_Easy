//
//  VibeMasterApp.swift
//  VibeMaster
//
//  Created by Cursor
//

import SwiftUI
import UIKit

@main
struct VibeMasterApp: App {
    init() {
        let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: titleFont]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.audioPlaybackService, AudioPlaybackService.shared)
        }
    }
}
