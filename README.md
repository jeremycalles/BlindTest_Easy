# VibeMaster

iOS music quiz (blind test) app per FullSpec.MD.

## Structure

- `VibeMaster/` – SwiftUI app source
  - App entry: `VibeMasterApp.swift`, `ContentView.swift`
  - Models, ViewModels, Views, Services, Resources as in spec

## Build

1. Open **VibeMaster.xcodeproj** in Xcode (double-click or `open VibeMaster.xcodeproj`).
2. Select an iOS Simulator (e.g. iPhone 16) or a connected device.
3. Press **⌘R** to build and run.

## Deezer API

No auth required; uses public endpoints (chart, search, playlist detail). Network access only for Deezer; mock data works offline.
