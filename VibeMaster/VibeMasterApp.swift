//
//  VibeMasterApp.swift
//  VibeMaster
//
//  Created by Cursor
//

import SwiftUI

@main
struct VibeMasterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.audioPlaybackService, AudioPlaybackService.shared)
        }
    }
}
