# VibeMaster

iOS music quiz (blind test) app per FullSpec.MD.

## Structure

- **VibeMasterCore/** – Swift package (open-source business logic)
  - Domain models: `Track`, `Artist`, `Album`, `PlaylistResponse`
  - Game types: `GameConfig`, `PlayerScore`, `PodiumResult`
  - `GameEngine` and `AudioPlaybackProtocol` (no API keys or app-specific config)
- **VibeMaster/** – SwiftUI app (UI + config)
  - App entry: `VibeMasterApp.swift`, `ContentView.swift`
  - Views, Services (Deezer, audio, haptics, favorites), Resources
  - Injects config and implements protocols; keep API keys or secrets here (or in .gitignore)

## Build

1. Open **VibeMaster.xcodeproj** in Xcode (double-click or `open VibeMaster.xcodeproj`).
2. Select an iOS Simulator (e.g. iPhone 16) or a connected device.
3. Press **⌘R** to build and run.

## Deezer API

No auth required; uses public endpoints (chart, search, playlist detail). Network access only for Deezer; mock data works offline.
