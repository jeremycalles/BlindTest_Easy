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

## Testing

Run the regression test suite from Xcode:

- **Product > Test** (or **⌘U**).
- The shared scheme **VibeMaster** builds the app and runs the **VibeMasterTests** unit tests (GameEngine scoring, podium, flow with a mock audio service).

## Deploy to App Store Connect

- **From Xcode:** Select destination **Any iOS Device**, then **Product > Archive**. In the Organizer, choose **Distribute App** → **App Store Connect** → **Upload** and follow the wizard.
- **Optional – after merge to main:** Use **Xcode Cloud** (Product > Xcode Cloud > Create Workflow). Configure the workflow to start when the `main` branch changes, run tests, then add the post-action **Distribute to App Store Connect** so each merge to `main` builds, tests, and uploads automatically.

## Deezer API

No auth required; uses public endpoints (chart, search, playlist detail). Network access only for Deezer; mock data works offline.
