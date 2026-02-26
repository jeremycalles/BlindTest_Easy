# VibeMaster Full Specification

## 1. Product Overview

VibeMaster is an iOS music quiz (blind test) application for local multiplayer. One host (MC) operates the device; multiple players guess artist and title from Deezer playlist previews. The app flow: Dashboard → playlist selection → Setup → Game → Podium.

---

## 2. Technical Specification (Engineering)

### 2.1 Project Structure and Module Boundaries

```
VibeMaster/
├── VibeMasterApp.swift          # @main entry; WindowGroup → ContentView
├── ContentView.swift            # Navigation root, path state, destination routing
├── Models/
│   └── Track.swift             # Domain: Track, Artist, Album; PlaylistResponse (Codable)
├── ViewModels/
│   ├── GameConfig.swift        # GameConfig, PlayerScore, PodiumResult (Hashable)
│   └── GameEngine.swift        # @MainActor ObservableObject; game state + audio/timer
├── Views/
│   ├── SplashView.swift        # Entry screen; NavigationDestination enum
│   ├── DashboardView.swift    # Home: search, chart, favorites, quick start
│   ├── SetupView.swift        # Pre-game form: players, timer, MC mode
│   ├── GameView.swift         # In-game UI; PlayerTile, control bar, timer strip
│   └── PodiumView.swift       # Results + ConfettiOverlay
├── Services/
│   ├── DeezerAPIService.swift  # Deezer HTTP client + DTOs
│   ├── AudioPlaybackService.swift  # AVPlayer wrapper, fade-out
│   ├── MockPlaylistService.swift   # Bundle JSON → [Track]
│   ├── FavoritesManager.swift # UserDefaults persistence
│   └── HapticManager.swift    # UIImpactFeedbackGenerator
└── Resources/
    ├── MockData.json          # Demo playlist (PlaylistResponse shape)
    └── Assets.xcassets
```

**Ownership and dependencies:** Views own local `@State`; `GameView` owns `GameEngine` via `@StateObject`. Services are singletons (`DeezerAPIService.shared`, etc.). No DI container; `GameConfig` is the only explicit data passed into the game flow.

---

### 2.2 Data Models

**Domain (Track.swift)**

| Type | Conformance | Purpose |
|------|-------------|---------|
| `Track` | Codable, Identifiable, Hashable | Single track: id, title, preview (URL string), artist, album |
| `Artist` | Codable, Hashable | name, picture_medium (URL string) |
| `Album` | Codable, Hashable | cover_medium (URL string) |
| `PlaylistResponse` | Codable | Wrapper `{ data: [Track] }` for MockData.json |

**Game (GameConfig.swift)**

| Type | Conformance | Purpose |
|------|-------------|---------|
| `GameConfig` | Hashable | Immutable game params: tracks: [Track], playerNames: [String], timerSeconds: Int (5–30), mcPlaysMode: Bool |
| `PlayerScore` | Hashable | name: String, score: Int (result row) |
| `PodiumResult` | Hashable | playerScores: [PlayerScore], config: GameConfig (for Replay) |

**Deezer DTOs (DeezerAPIService.swift, file-private unless noted)**

- **Playlist detail:** `DeezerPlaylistResponse` → `tracks: DeezerTracksContainer` → `data: [DeezerTrackDTO]`. Each DTO: id, title, preview, artist (DeezerArtistDTO), album (DeezerAlbumDTO). Optional: `artist.picture_medium`.
- **Search/Chart:** Public `DeezerPlaylistItem`: id, title, picture_medium?, nb_tracks?. Response wrappers: `DeezerSearchPlaylistsResponse`, `DeezerChartPlaylistsResponse` → `data: [DeezerPlaylistItem]`, chart also `total: Int?`.

**Mapping:** Deezer track DTO → `Track`: preview required (filtered out if empty); `artist.picture_medium` defaulted to `""` for domain `Artist`.

---

### 2.3 API Layer (Deezer)

- **Base:** `https://api.deezer.com`
- **Session:** `URLSession` default, 15s timeout; no auth.

| Operation | Endpoint | Method | Query/Body | Response |
|-----------|----------|--------|------------|----------|
| Chart playlists | `/chart/0/playlists` | GET | — | DeezerChartPlaylistsResponse |
| Search playlists | `/search/playlist` | GET | `q` = query (URL-encoded) | DeezerSearchPlaylistsResponse |
| Playlist detail | `/playlist/{id}` | GET | — | DeezerPlaylistResponse (includes full track list) |

**Error handling:** `DeezerAPIError`: invalidURL, noData, serverError(Int). Decoding failures surface as thrown errors. Callers (DashboardView, SetupView) catch, set local error state or empty results; no global error bus.

---

### 2.4 State Management and Data Flow

**Navigation (ContentView)**

- Single source of truth: `@State private var navigationPath: NavigationPath([NavigationDestination.dashboard])`.
- Root: `SplashView`; destinations registered via `.navigationDestination(for: GameDestination.self)` and `NavigationDestination.self`.
- **NavigationDestination:** `case dashboard` → pushes `DashboardView`.
- **GameDestination:** `case game(GameConfig)` → `GameView`; `case podium(PodiumResult)` → `PodiumView`.
- Path mutations: append (e.g. `navigationPath.append(GameDestination.game(config))`) or replace (e.g. `navigationPath = NavigationPath([NavigationDestination.dashboard])` for “back to home” or “stop game”).

**DashboardView**

- **Local state:** searchText, chartPlaylists, searchResults, favoritePlaylists, isSearching, isLoadingSearch, isLoadingChart, errorMessage, selectedTracks?, showSetup, searchTask (Task handle for debounce).
- **Flow:** Chart load on appear; favorites from FavoritesManager on appear and when showSetup turns false. Search: onChange(searchText) → if trimmed.count >= 3, cancel previous task, start 300ms debounce Task → runSearch() (sets isLoadingSearch, calls Deezer search, updates searchResults). Selecting a playlist: fetch tracks → set selectedTracks, showSetup = true. Quick start: load mock tracks → same. When showSetup && selectedTracks: present SetupView with onCancel clearing selectedTracks and showSetup.

**SetupView**

- **Inputs:** `navigationPath: Binding`, optional `initialTracks: [Track]?`, optional `onCancel: () -> Void`.
- **Local state:** playerNames [String] (min 2 slots), timerSeconds (5–30), mcPlaysMode, tracks, isLoading, loadError, focusedPlayerIndex (FocusState).
- **Flow:** onAppear: if initialTracks non-empty, use it and set isLoading = false; else loadTracks() (MockPlaylistService on background queue, then main async update). startGame(): validate ≥2 non-empty names and non-empty tracks, build GameConfig (timer clamped 5–30), append GameDestination.game(config).

**GameView**

- **Inputs:** `config: GameConfig` (let), `navigationPath: Binding`.
- **State:** `@StateObject private var engine: GameEngine(config)`, `showStopGameConfirmation: Bool`.
- **Lifecycle:** onAppear → engine.startRound(); onDisappear → engine.togglePlayPause() (stops/pauses when leaving).
- **Engine is single source for:** currentTrackIndex, scores, isPlaying, isRevealed, timeRemaining, roundEnded. No local copy of scores; all scoring and navigation (Next/Podium) driven by engine and path binding.

**PodiumView**

- **Inputs:** `results: PodiumResult` (let), `navigationPath: Binding`.
- **State:** showConfetti (used for winner card animation). Replay: append GameDestination.game(results.config). Home: replace path with `NavigationPath([NavigationDestination.dashboard])`.

---

### 2.5 Concurrency and Threading

- **GameEngine:** `@MainActor`; all published state and methods run on main. Timer implemented with `Task` + `Task.sleep(nanoseconds:)` (0.1s steps); cancellation via `timerTask?.cancel()` on pause/reveal/next.
- **DeezerAPIService:** No MainActor; `session.data(from:)` is async. Callers (DashboardView) use `Task { }` and `await MainActor.run { }` to update UI.
- **DashboardView search:** Debounce with a cancellable `Task`; new keystroke cancels previous task, then after 300_000_000 ns invokes runSearch() on main.
- **SetupView loadTracks:** `DispatchQueue.global(qos: .userInitiated).async` then `DispatchQueue.main.async` for result (inconsistent with rest of app; could be migrated to Task + MainActor).
- **AudioPlaybackService.duckAndFadeOut:** Uses `Timer.scheduledTimer` on main run loop (`RunLoop.main.add(..., forMode: .common)`); completion closure may call back into GameEngine which then uses `Task { @MainActor in ... }` for state updates.

---

### 2.6 Audio Subsystem

- **AVAudioSession:** Category `.playback`, mode `.default`; activated in GameEngine.init via `AudioPlaybackService.configureSession()`.
- **AVPlayer:** One instance per “current track”; `load(url:)` calls `stop()` then creates new `AVPlayer(url:)` with volume 1.0. No queue; next track = explicit `stop()` then load next URL.
- **Fade-out:** `duckAndFadeOut(duration: 2.5)`: 20 steps, stepDuration = duration/20. Each tick: volume = startVolume * (1 - progress). On completion: no pause; playback continues at volume 0. Timer is strong reference; no explicit cleanup if view disappears during fade (potential leak if completion holds self).
- **Lifecycle:** startRound() → load + play + startTimer. When time hits 0 → reveal() → duckAndFadeOut → completion sets roundEnded. nextTrack() → stop() then optionally startRound() for next index. onDisappear GameView → togglePlayPause() (pause and cancel timer).

---

### 2.7 Persistence

- **FavoritesManager:** Key `vibemaster_favorite_playlists` in UserDefaults. Value: JSON-encoded `[DeezerPlaylistItem]`. No versioning; add/remove by playlist id.
- **MockPlaylistService:** Reads `MockData.json` from Bundle; decoded as `PlaylistResponse`. No caching.

---

### 2.8 Error Handling and Recovery

- **Deezer:** Network/decoding errors caught in callers; chart failure sets errorMessage and shows retry in DashboardView; search failure sets searchResults = [] and isLoadingSearch = false; playlist tracks failure sets errorMessage (no retry UX on same screen beyond user re-tapping).
- **Mock load:** SetupView shows loadError and “Réessayer”; DashboardView quick start sets errorMessage (display not wired to a dedicated alert; could appear in list context).
- **Game:** No explicit error state; if track preview URL invalid, startRound() returns early (no user-facing message).

---

### 2.9 Build and Runtime Environment

- **Deployment:** iOS 17.0+, iPhone (TARGETED_DEVICE_FAMILY = 1). Swift 5, SwiftUI.
- **Design target:** When raising minimum deployment to iOS 26, adopt `.glassEffect()` / `.glassBackgroundEffect()` per §3.0 and §3.1; until then use `.ultraThinMaterial` / `.ultraThickMaterial` as the glass-equivalent layer so hierarchy matches Liquid Glass.
- **Dependencies:** System only (AVFoundation, Combine, Foundation, SwiftUI, UIKit for HapticManager). No SPM/CocoaPods.
- **Capabilities:** Audio background not required; playback is foreground-only.

---

## 3. Design System and UI Specification (Design)

### 3.0 Apple Design Alignment: Liquid Glass and Beyond

VibeMaster SHALL follow Apple Human Interface Guidelines and the Liquid Glass design language (iOS 26 / WWDC 2025) where the deployment target allows. On earlier OS versions, use the closest semantic equivalents so hierarchy and behavior stay consistent.

**Liquid Glass principles (HIG)**

- **Content-first hierarchy:** Primary content (playlists, track info, player scores) is the immersive layer; controls and chrome (toolbars, buttons, timer strip) sit as distinct, floating layers so users always know what is content vs. control. Avoid stacking multiple heavy glass layers; prefer one clear glass layer for controls over rich background content.
- **Translucency and depth:** Use translucent materials so background (gradients, album art, imagery) remains visible and informs the glass. Glass reflects and refracts surroundings; color is adaptive to light/dark and context. Prefer system glass APIs over opaque fills so the system can handle light/dark and accessibility.
- **Lensing and dynamics:** Where supported (e.g. iOS 26), glass can respond to motion and touch (scale, shimmer, specular highlights). Use subtle, purposeful motion; avoid decorative motion that competes with content. Respect Reduce Motion: when enabled, disable lensing and non-essential animations (e.g. confetti, winner float).
- **Rounded, floating forms:** Cards, toolbars, and buttons use rounded corners and sit slightly above the content layer. Align corner radius and elevation with system norms (e.g. 12pt for cards, capsule for pills) so the UI feels native and touchable.
- **Harmony and consistency:** Same material and interaction language across Splash, Dashboard, Setup, Game, and Podium. Use system controls (Toggle, Slider, Button, List) with glass or tinted styling so the app feels part of the platform.

**Materials and APIs**

- **iOS 26+ (when targeting):** Prefer `.glassEffect()` / `.glassBackgroundEffect(in:displayMode:)` for control surfaces (cards, list backgrounds, toolbars, timer strip, buttons). Use `.regular` for primary glass; `.clear` where content must stay prominent; `.liquidGlassThick` only for strong separation (e.g. MC overlay). Apply glass to shapes (RoundedRectangle, Capsule) so the system can render lensing and adaptivity. Do not overuse thick/ultra glass; one dominant glass layer per context is sufficient.
- **iOS 17–25 (fallback):** Use `.ultraThinMaterial` for list and card backgrounds, `.ultraThickMaterial` only for the MC “hidden answer” overlay. Keep the same hierarchy (content = background, controls = material layer) so upgrading to glassEffect later is a drop-in.
- **Backgrounds:** Immersive layer is always behind glass: gradient (Splash, Podium), blurred album art (Game), or list content (Dashboard, Setup). No glass-on-glass stacking for primary content; glass is for chrome and cards only.

**Accessibility (required)**

- **Reduce Transparency:** When the user enables Reduce Transparency, the system substitutes more opaque backgrounds for glass. Do not rely on translucency for critical information; ensure text and controls remain legible with solid backgrounds. Test all screens with Reduce Transparency on.
- **Reduce Motion:** When enabled, disable: confetti animation, winner-card float loop, and any decorative lensing or parallax. Keep only essential transitions (e.g. track card reveal for game state). Use `UIAccessibility.isReduceMotionEnabled` (or SwiftUI equivalent) to gate motion.
- **Increase Contrast / Show Borders:** Respect system settings; the system may strengthen borders on glass. Avoid relying solely on subtle borders for interactive boundaries; ensure touch targets and focus order remain clear.
- **Dynamic Type:** All text uses scalable fonts; avoid fixed point sizes for body or labels so that Large Text and accessibility sizes work. Minimum touch target 44×44 pt for icon-only buttons (close, play/pause, heart).

**Summary**

- **Hierarchy:** Background = content (immersive); foreground = one clear glass layer for controls and cards.
- **Materials:** Prefer `glassEffect` (iOS 26) or `ultraThinMaterial` (iOS 17); use thick material only for MC overlay.
- **Motion:** Subtle and purposeful; respect Reduce Motion.
- **Accessibility:** Reduce Transparency, Reduce Motion, Increase Contrast, Dynamic Type, and touch target size are non-negotiable.

---

### 3.1 Design Tokens

**Typography**

- **Large title / hero:** `.largeTitle`, `.bold` (e.g. “VibeMaster”, “Podium”).
- **Titles:** `.title2` (section titles, winner name), `.title3` (winner score).
- **Headlines:** `.headline` / `.headline` + `.semibold` (track title, playlist title, primary CTAs).
- **Body / secondary:** `.subheadline`, `.footnote`; secondary text `.foregroundStyle(.secondary)`.
- **Small / UI:** `.caption`, `.caption2`; tracking 1.5 for labels (e.g. “PISTE 1 / N”, “TEMPS ÉCOULÉ”).
- **Numbers:** `.fontDesign(.rounded)` for scores; `.monospacedDigit()` for timer to avoid layout shift.
- **Weights:** medium (labels), semibold (buttons, headings), bold (scores, key labels), heavy (winner score).
- **Scaling:** Use semantic styles (e.g. .headline) so Dynamic Type applies; avoid hard-coded sizes for body/labels.

**Color**

- **Brand / primary:** Indigo and purple (splash gradient, podium background, fallback when no art).
- **Accent / CTA:** Orange `Color(red: 1.0, green: 0.4, blue: 0.2)` for main play/pause.
- **Semantic:** Coral red for “time’s up” and first player; red for favorite (heart.fill).
- **Player palette (6):** Coral red, Turquoise, Sky blue, Lavender, Amber, Mint green (used in order for tiles).
- **Neutrals:** White with opacity for text on dark; `.secondary`; gray for placeholders; black for destructive/contrast where needed.
- **Surfaces (Liquid Glass–aligned):** Prefer system glass: iOS 26 `.glassEffect(.regular)` (or `.liquidGlass` / `.liquidGlassThin` where appropriate) for cards, list chrome, timer strip, and control capsules. Fallback: `.ultraThinMaterial` for list/cards; `.ultraThickMaterial` only for MC overlay. Ensure sufficient contrast for text on glass in both light and dark appearances.

**Layout and spacing**

- **Safe area:** Content respects safe area; GameView adds 16pt horizontal via safeAreaInset and internal padding; vertical insets: top + 8, bottom max(insets.bottom, 14).
- **Section spacing:** 12pt between major blocks (e.g. track card, player grid, timer, control bar); 8pt in compact headers; 24pt on Podium.
- **List:** `.insetGrouped`; row background `.clear` with parent glass (glassEffect or ultraThinMaterial); padding vertical 4–12 where specified.
- **Corner radius:** 12pt cards/tiles; 20pt podium winner card; 8pt thumbnails; capsule for pills. Rounded, floating forms per Liquid Glass.
- **Touch targets:** Minimum 44×44 pt for all interactive elements (buttons, hearts, player tiles, list rows).

**Motion and feedback**

- **Haptics:** Light for taps (scoring, favorites, cancel); medium for primary actions (start round, next, replay). Preserve even when Reduce Motion is on.
- **Transitions:** 0.3s easeInOut for track card reveal (essential for game state). Confetti and winner float: decorative; MUST be disabled or simplified when Reduce Motion is enabled.
- **Lensing / dynamics (iOS 26):** Optional subtle response on glass (e.g. touch); must not distract from content and must respect Reduce Motion.

---

### 3.2 Screen Specifications

#### 3.2.1 Splash View

**Role:** Brand entry; optional first screen (app can open directly to Dashboard).

**Hierarchy (Liquid Glass):** Single immersive layer (gradient); one foreground layer (button). No glass cards; button is the only control so it stays prominent. Optional: button can use glassEffect (iOS 26) or keep borderedProminent for clarity.

**Layout**

- Full-bleed; `ZStack`: background → content. Content: `VStack(spacing: 32)` — Spacer, logo block, Spacer, primary button with bottom padding 48.
- **Background (immersive):** Linear gradient indigo → purple. Overlay: glass or `.ultraThinMaterial` so gradient remains visible; avoid opaque overlay so Liquid Glass / Reduce Transparency can adapt.
- **Logo:** `VStack(spacing: 16)`: SF Symbol `music.note.list` (72pt, hierarchical), text “VibeMaster” (.largeTitle, .bold). Foreground .white; ensure contrast with gradient when Reduce Transparency is on.
- **Button:** “Commencer la soirée” (.headline, .semibold), full width, vertical padding 16, horizontal 32; `.borderedProminent`, tint .white, foreground .indigo. Min touch target 44pt height.

**Behavior**

- Single action: tap → haptic medium → append `NavigationDestination.dashboard` to path. No loading; no persistence of “has seen splash”.

**States**

- One state; no loading or error.

---

#### 3.2.2 Dashboard View (Home)

**Role:** Hub for starting a game: quick demo, chart playlists, search, favorites.

**Hierarchy (Liquid Glass):** List content (sections, rows) is primary; list container is a single glass layer above the root background. Navigation bar and search are system chrome (floating). No extra glass panes; one glass layer for the list so hierarchy stays content-first.

**Layout**

- Navigation title: “Accueil”, .large. Bar: searchable with prompt “Rechercher des playlists”.
- **Body:** Single `List` (.insetGrouped, scrollContentBackground hidden). Background: `.glassBackgroundEffect` / `.glassEffect` (iOS 26) or `.ultraThinMaterial` (fallback) so list reads as one floating surface. Content depends on mode:
  - **Default:** Three sections: Démarrer, Top playlists, Mes Blind Tests.
  - **Search active (isSearching):** Single section “Résultats” only (replaces all three).

**Sections (default)**

1. **Démarrer**
   - One row: icon `play.circle.fill` (.title2), title “Blind Test rapide” (.medium), subtitle “3 titres (données de démo)” (.caption, .secondary). Row tappable; clear row background.
2. **Top playlists**
   - **Loading:** Centered `ProgressView`.
   - **Error:** Message “Impossible de charger les playlists. Vérifiez votre connexion.” + “Réessayer” (.bordered).
   - **Success:** Up to 10 rows. Each row: `PlaylistRowView` (thumbnail 50×50, title, “X titres” if present, chevron) tappable; trailing heart (outline or fill) for favorite toggle. Row background clear.
3. **Mes Blind Tests**
   - **Empty:** Text “Ajoutez des playlists en favori pour les retrouver ici.” (.subheadline, .secondary).
   - **Non-empty:** One row per favorite; same row layout as chart plus heart.fill to remove. Row tappable.

**Search results section**

- Header “Résultats”.
- **Loading:** Centered `ProgressView`.
- **Empty (after load):** “Aucun résultat” (.secondary).
- **Results:** Same row pattern as Top playlists (thumbnail, title, count, chevron, favorite). Row tappable.

**Interactions**

- **Search:** When searchText trimmed length ≥ 3: set isSearching true, cancel previous search task, after 300ms call runSearch() (Deezer search), show results section only. On submit of search field, runSearch() again. If trimmed length < 3: clear results and isSearching.
- **Chart row / favorite row tap:** Select playlist (fetch tracks) → set selectedTracks, showSetup = true (SetupView presented in same nav with initialTracks and onCancel).
- **Quick start tap:** Load mock tracks → same as above.
- **Heart tap:** Toggle favorite (add/remove in FavoritesManager), reload favorites; haptic light.

**States**

- Default (chart + favorites visible), Search (results only), Loading chart, Chart error, Loading search, Empty search results, Setup overlay (selectedTracks + ShowSetup).

---

#### 3.2.3 Setup View

**Role:** Configure players, timer, MC mode, and start the game.

**Hierarchy (Liquid Glass):** Form content is primary; list is one glass layer. Toolbar (Annuler) is system chrome. Use system Toggle and Slider so they inherit platform glass/accessibility behavior.

**Layout**

- Navigation title “Configuration”, .large. Toolbar: “Annuler” in leading position only when onCancel != nil.
- **Body:** `List` (.insetGrouped, scrollContentBackground hidden). Background: glass (iOS 26) or `.ultraThinMaterial`. Four sections: Joueurs, Timer (secondes), Mode MC, and start button.

**Sections**

1. **Joueurs**
   - For each index: `TextField("Joueur \(index + 1)", text: $playerNames[index])`, autocapitalization .words; if count > 2, trailing minus button (destructive) to remove. Then one row: “Ajouter un joueur” + plus.circle. Row backgrounds clear.
2. **Timer (secondes)**
   - One row: label “\(timerSeconds) s” (.medium), `Slider` 5...30, step 1. Clear background.
3. **Mode MC**
   - One row: Toggle “Le MC joue”, bound to mcPlaysMode. Clear background.
4. **Start**
   - Single full-width button: “Lancer la partie” (.semibold), vertical padding 12. Disabled when !canStart (fewer than 2 non-empty names or tracks empty). Clear background.

**Behavior**

- **onAppear:** If initialTracks provided and non-empty, use it and set isLoading = false; else loadTracks() (mock) and show loading or error.
- **Annuler:** Call onCancel (clears setup overlay on Dashboard).
- **Lancer la partie:** Validate, build GameConfig (timer clamped 5–30), append GameDestination.game(config).

**States**

- Loading (full-screen “Chargement…”), Error (title “Erreur”, message, “Réessayer”), Form (all four sections). No empty-tracks state beyond error.

---

#### 3.2.4 Game View

**Role:** Play round: show track context, timer, player tiles for scoring, play/pause, next/podium.

**Hierarchy (Liquid Glass):** Background = immersive (blurred album art or solid color). Foreground = one glass layer for: track card, player tiles, timer strip, control bar. Clear separation: content (art, track info when revealed) vs. controls (glass cards and buttons). Toolbar close button is system chrome. Do not stack multiple glass layers; each card/tile uses the same glass treatment so the whole screen reads as one floating layer over the background.

**Layout**

- **Chrome:** No back button. Leading toolbar: close (xmark.circle.fill, hierarchical), min 44×44 pt; tap → confirmation dialog “Arrêter la partie ?” with Annuler / “Arrêter la partie” (destructive). Message: “La partie en cours sera abandonnée...”.
- **Background (immersive):** Full-bleed; if current track has cover_medium URL, AsyncImage scaled and blurred (80pt); else indigo 0.6. Overlay: glass or `.ultraThinMaterial` so art remains visible; system will respect Reduce Transparency.
- **Content (VStack, spacing 12):**
  1. **Track header:** Capsule 36×4 (white 0.3); text “PISTE \(index+1) / \(total)” (.caption, .medium, tracking 1.5, .secondary). Centered.
  2. **Track card (if track exists):** HStack: album art 56×56 (rounded 8), VStack title (headline semibold, 1 line, tail truncation, minScale 0.7) + artist (subheadline, .secondary, same truncation). Padding 12, background glass (`.glassEffect(.regular)` or `.ultraThinMaterial`), corner 12. In MC mode when !isRevealed: overlay `.liquidGlassThick` or `.ultraThickMaterial` to hide content. Animated on isRevealed change (0.3 easeInOut); keep animation optional for Reduce Motion.
  3. **Player grid:** Flexible; 2 players = HStack two equal tiles; 3+ = LazyVGrid 2 columns, ScrollView, minHeight two rows (164×2 + 12). Spacing 12. Each tile = one glass card.
  4. **Timer strip:** Horizontal line (1pt, white 0.25) + label + line. Label: if roundEnded “TEMPS ÉCOULÉ” (caption2, semibold, tracking 1.5, coral red); else “M:SS” (caption, semibold, monospacedDigit, .secondary). Padding vertical 4. Strip is part of the foreground glass layer (no extra shape; text on transparent or same glass as content).
  5. **Control bar:** HStack: Spacer, Play/Pause button (60×60 circle, orange, play/pause icon 24pt white), Spacer, trailing slot. When roundEnded: “Suivant” or “Podium” in capsule with glass (or ultraThinMaterial); when !roundEnded: clear placeholder 90×44. Buttons min 44pt touch target.

**Player tile (component)**

- **Content:** Avatar: circle 50, fill color.opacity(0.15), stroke color 2.5pt, initial letter (uppercase) .system 20pt bold in color. Name: caption2, medium, 1 line, minScale 0.7, .secondary. Score: 26pt bold rounded, color. “pts” caption2 .secondary. Min height 140, vertical padding 12. Background: glass (glassEffect or ultraThinMaterial), corner 12; one floating card per Liquid Glass.
- **Gestures:** Tap → +1; double-tap → +2; long-press → -1 (min 0). All with haptic. Ensure full tile is tappable (min 44pt).

**Behavior**

- **onAppear:** engine.startRound() (load track, play, start countdown).
- **onDisappear:** engine.togglePlayPause() (pause and cancel timer).
- **Play/Pause:** Toggle playback and timer.
- **Suivant:** engine.nextTrack() (stop, increment index, startRound for next).
- **Podium:** engine.buildPodiumResult(), append GameDestination.podium(result).
- **Stop game:** navigationPath = NavigationPath([.dashboard]).

**States**

- Per round: playing (timer counting, card hidden in MC mode or visible), paused, round ended (revealed, “TEMPS ÉCOULÉ”, music faded to 0, Next or Podium visible). Engine owns isRevealed, roundEnded, isPlaying, timeRemaining.

---

#### 3.2.5 Podium View

**Role:** Show winner and full ranking; offer Replay or Home.

**Hierarchy (Liquid Glass):** Background = immersive (indigo tint). Foreground = winner card (one glass card), ranking list (one glass surface), action buttons. Confetti is decorative overlay; MUST be disabled or reduced when Reduce Motion is on.

**Layout**

- **Background (immersive):** Indigo 0.4 + glass or .ultraThinMaterial, ignoresSafeArea.
- **Overlay:** ConfettiOverlay (non-interactive, fades out after ~2.5s). **Accessibility:** Omit or show static celebration when Reduce Motion is enabled.
- **Content (VStack spacing 24, padding):**
  1. Title “Podium” (.largeTitle, .bold).
  2. **Winner card (if any):** Circle 80 with glass (or ultraThinMaterial) and shadow; initial letter .largeTitle .bold; name .title2 .semibold; “X point(s)” .title3 .heavy .rounded. Padding 24, background glass, corner 20, horizontal padding 32. Float animation (offset y -4, 0.6s repeatForever autoreverse): **disable when Reduce Motion is on.**
  3. **Ranking list:** List (.insetGrouped, scrollContentBackground hidden), maxHeight 280. Background glass or ultraThinMaterial. Rows: rank number (title2 bold, width 32), name, Spacer, score (headline, rounded). Clear row backgrounds.
  4. Spacer.
  5. **Actions:** “Rejouer” (.semibold, full width, padding vertical 14) .borderedProminent; “Retour à l'accueil” (same padding) .bordered. Spacing 12. Min 44pt touch targets.

**Confetti**

- 30 small rounded rects, random x, size 4–10, colors from fixed palette; on appear animate from top to bottom with random delay and duration (1.2–2s); after 2.5s fade overlay to 0 over 0.5s. allowsHitTesting(false). **When Reduce Motion is on:** do not run animation; optionally show static particles or skip confetti entirely.

**Behavior**

- **Rejouer:** Append GameDestination.game(results.config) (same config, new game).
- **Retour à l'accueil:** navigationPath = NavigationPath([NavigationDestination.dashboard]).

**States**

- Single state: results and config are immutable inputs; no loading.

---

### 3.3 Reusable Components

- **PlaylistRowView(item: DeezerPlaylistItem):** HStack: AsyncImage 50×50 (rounded 8), fallback .quaternary; VStack title (headline, 1 line), optional “\(nb) titres” (caption, .secondary); Spacer; chevron.right (caption, .secondary). Padding vertical 4. Row sits on list’s single glass layer; no additional glass. Used in Dashboard for chart, favorites, and search results. Min touch target for row: full row height ≥ 44pt.
- **PlayerTile:** See Game View above; props: name, score, color, onTap, onDoubleTap, onLongPress. One glass card per tile; rounded 12pt. Respect Reduce Motion (no extra motion beyond tap feedback).
- **ConfettiOverlay:** Private in PodiumView; see Podium layout. Decorative only; must be disabled or simplified when Reduce Motion is on.

---

### 3.4 Accessibility and Responsiveness

- **Reduce Transparency (Apple HIG / Liquid Glass):** When the user enables Reduce Transparency (Settings > Accessibility > Display & Text Size), the system may replace glass with more opaque backgrounds. All screens MUST remain usable: text legible, controls identifiable, hierarchy clear. Do not rely on translucency alone to convey structure; test with Reduce Transparency on for every view.
- **Reduce Motion:** When Reduce Motion is on, disable: confetti animation, winner-card float loop, and any non-essential lensing or parallax. Keep only transitions that communicate state (e.g. track card reveal). Check `UIAccessibility.isReduceMotionEnabled` (or environment) and gate decorative motion.
- **Increase Contrast / Show Borders:** Respect system Increase Contrast and Show Borders; the system may add or strengthen borders on glass. Ensure interactive regions (buttons, tiles, list rows) remain clearly defined without relying only on subtle edges.
- **Dynamic Type:** Use semantic text styles so fonts scale with user settings. Avoid fixed point sizes for body and labels; 26pt/20pt for scores are acceptable but verify at largest accessibility sizes. Support Large Text.
- **Labels:** Buttons and toggles use visible text where possible. Icon-only buttons (close, play/pause, heart, chevron) MUST have accessibilityLabel and optionally accessibilityHint so VoiceOver and Switch Control work.
- **Touch targets:** Minimum 44×44 pt for all tappable elements (Apple HIG). Ensure list rows, player tiles, and toolbar buttons meet this.
- **Contrast:** Primary text on glass or material must meet contrast guidelines in both light and dark appearances; “TEMPS ÉCOULÉ” and player colors chosen for legibility. When Reduce Transparency is on, ensure contrast on solid backgrounds.
- **Orientation:** Support portrait and landscape (iPhone); layout uses flexible frames and ScrollView where content can overflow (player grid, list sections).
- **Safe area:** All main content respects safe area; GameView explicitly adds horizontal insets and top/bottom padding for control bar and timer.

---

This specification documents the application’s product intent, technical architecture, and design system to expert level for engineering and design alignment.
