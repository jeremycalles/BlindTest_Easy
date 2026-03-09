# BlindTest Easy

iOS music quiz (blind test) app with a French UI. The Xcode project and targets are still named VibeMaster; the app displays as **BlindTest Easy**. Flow: **Splash** → **Dashboard** → **Setup** → **Game** → **Podium**. Uses Deezer for tracks, haptics and sound (countdown chimes, applause) for feedback, glass-style visuals, and confetti on splash and results; respects **Reduce Motion** accessibility.

## Structure

- **VibeMasterCore/** – Swift package (open-source business logic)
  - Domain models: `Track`, `Artist`, `Album`, `PlaylistResponse`
  - Game types: `GameConfig`, `PlayerScore`, `PodiumResult`
  - `GameEngine` and `AudioPlaybackProtocol` (no API keys or app-specific config)
- **VibeMaster/** – SwiftUI app (UI + config)
  - App entry: `VibeMasterApp.swift`, `ContentView.swift` (navigation: `AppDestination`)
  - Views: `SplashView`, `DashboardView`, `SetupView`, `GameView`, `PodiumView`
  - Services: Deezer, audio, **HapticManager** (impact, timer chimes `chime.wav` / `chime_high.wav`, applause), favorites
  - Resources: WAV assets for chimes and applause
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

**Attribution:** Deezer’s terms require a visible “Powered by Deezer” mention and the official Deezer logo in the app. See [DEEZER_ATTRIBUTION.md](DEEZER_ATTRIBUTION.md) for details and how to add the logo.
