# TuneQuest

An iOS music game: place songs on a timeline by their original release year. This first playable version focuses on single-player games.

## Play a solo game

Open the app → **Play solo** → choose a gap → **Confirm**.

- Start with one reference song and its visible year. Place ten more songs correctly to win.
- You have three lives. A wrong answer costs one life and keeps the same song, with its year hidden, for another attempt.
- Title and artist are always visible. Tap **Play** to hear a preview; playback never starts automatically.
- Songs from the same year can go in either order as long as the timeline remains chronological.
- After a correct answer, the year is revealed. Tap **Continue** for the next song.
- The third incorrect answer ends the game and reveals the pending song's year and correct position. **Play again** starts a fresh game; **Home** returns to the rules.
- **Exit** asks for confirmation before abandoning an active game. Games are not saved between visits or app launches.

The bundled catalog contains twenty international recordings from 1957–2022. Each game randomly selects eleven distinct entries. Titles, artists and reviewed original release years are local; gameplay can continue without a working preview or artwork. Internet access is required for Deezer audio and images. **No account, API key or secret configuration is needed.** Availability and preview rights can vary by track, region and time.

### Release-year policy

The answer is the first publication year of the selected recording, including an album release that preceded its single. Remasters and compilations retain the original recording's year. For example, “Billie Jean” uses 1982 (the album *Thriller*), and “Hotel California” uses 1976 (the album), rather than their later single dates. Deezer's `release_date` is not used for gameplay.

Every entry in [catalog.json](TuneQuest/catalog.json) includes `originalReleaseYear` and a `releaseYearSource` link. When changing the catalog, verify the artist and recording behind the Deezer ID, exclude live versions/remixes/re-recordings unless explicitly curated, and check the first publication year against the cited source. Metadata for all twenty IDs and the presence of preview URLs were checked on 18 November 2026; this does not guarantee future availability.

## Requirements and running

- macOS with Xcode and an installed iOS Simulator runtime.
- iOS **18.0** deployment target. This repository is evaluated as an iOS app; macOS and visionOS are not validated.
- The local package requires **Swift tools 6.1+**. The app uses Swift 5 language mode; TuneNetwork uses Swift 6.
- Verified on **Xcode 27.2 (27B52), Swift 6.4.2**, with an **iPhone 17 / iOS 26.5** simulator. Older Xcode versions and physical devices have not been verified.
- No third-party dependencies: `Packages/TuneNetwork` is registered as a local Swift package under the project's **Package Dependencies**.

Open `TuneQuest.xcodeproj`, select the shared **TuneQuest** scheme and an iPhone simulator, then Run (`⌘R`). `BASE_URL` is already set to `https://api.deezer.com` in [Info.plist](TuneQuest/Info.plist). Simulator builds do not need a signing team; running on a physical device requires your own signing configuration.

For the command line, run from the repository root. List the available devices, then set the UDID of your chosen iPhone simulator:

```sh
xcrun simctl list devices available
export TUNEQUEST_SIMULATOR_ID="<available iPhone simulator UDID>"

xcodebuild -project TuneQuest.xcodeproj -scheme TuneQuest \
  -destination "platform=iOS Simulator,id=$TUNEQUEST_SIMULATOR_ID" \
  -derivedDataPath /tmp/TuneQuest-portfolio-final \
  CODE_SIGNING_ALLOWED=NO build
```

To install and launch that build, boot the selected simulator first if it is shut down:

```sh
xcrun simctl boot "$TUNEQUEST_SIMULATOR_ID" # only if shut down
xcrun simctl bootstatus "$TUNEQUEST_SIMULATOR_ID" -b
xcrun simctl install "$TUNEQUEST_SIMULATOR_ID" \
  /tmp/TuneQuest-portfolio-final/Build/Products/Debug-iphonesimulator/TuneQuest.app
xcrun simctl launch "$TUNEQUEST_SIMULATOR_ID" Pablo.Ruiz.TuneQuest
```

## Tests and verification

In Xcode, use `⌘U` with the **TuneQuest** scheme and **TestPlan**. The shared [test plan](TuneQuest/TestPlan.xctestplan) includes TuneQuestTests. Run TuneNetworkTests through the local package's own scheme; its tests are not exposed to the host plan with the Package Dependencies setup:

```sh
xcodebuild -project TuneQuest.xcodeproj -scheme TuneQuest -testPlan TestPlan \
  -destination "platform=iOS Simulator,id=$TUNEQUEST_SIMULATOR_ID" \
  -derivedDataPath /tmp/TuneQuest-portfolio-final \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test

(cd Packages/TuneNetwork && xcodebuild -scheme TuneNetwork \
  -destination "platform=iOS Simulator,id=$TUNEQUEST_SIMULATOR_ID" \
  -derivedDataPath /tmp/TuneQuest-network-verification CODE_SIGNING_ALLOWED=NO test)
```

The tests use Swift Testing, repository doubles and a URLProtocol stub. The committed suite requires no Deezer access and covers:

- Chronological insertion, equal years, invalid positions, retries, lives, victory, defeat and repeated confirmations.
- Distinct game selection, catalog validation, failures, cancellation and overlapping session loads.
- Audio-independent answers, manual preview preparation, audio-session activation, stale preview responses and cleanup.
- Catalog mapping and bundled data, use cases, playback recovery and HTTP GET/POST behavior.

Verified on 18 November 2026: simulator build and all **49 tests** passed (43 app, 6 package), with no failures or skipped tests. Temporary hosted rendering probes exercised the game state flow through selection, correct/incorrect feedback, victory, defeat and restart. Their screenshots were inspected at a 375 × 667-point viewport, including the largest accessibility text size in Dark Mode. The probes are not part of the committed suite and are not touch-driven UI tests.

The views use semantic controls, accessible position descriptions, selected-state traits, result announcements and a scrolling layout for accessibility text sizes or limited height. Touch-driven navigation/confirmation/exit, VoiceOver focus and announcements, Voice Control, physical devices, iOS 18, hardware audio interruptions and human listening have not been manually verified for this feature. These remain device-validation tasks; the layout inspection is not a full accessibility audit.

## Architecture

SwiftUI presentation uses Observation and `@MainActor` state. [DependencyContainer](TuneQuest/DependencyContainer.swift) composes concrete dependencies; [AppCoordinator](TuneQuest/AppCoordinator.swift) injects them and resolves routes for the NavigationStack.

- **Game:** [GameOnePlayerViewModel](TuneQuest/Presentation/Scenes/GameOnePlayerViewModel.swift) → [StartSinglePlayerGameUseCase](TuneQuest/Domain/UseCase/StartSinglePlayerGameUseCase.swift) → catalog repository. [GameSession](TuneQuest/Domain/Model/GameSession.swift) is a value-type state machine with no UI, networking or audio dependency. `GameConfiguration` centralizes the default three lives and ten correct placements.
- **Catalog:** repository → [CatalogLocalDataSource](TuneQuest/Data/DataSource/CatalogLocalDataSource.swift) → bundled JSON v2. Each `CatalogEntry` includes the Deezer ID, title, artist, reviewed year and source. The previous IDs-only bundle format is replaced; there is no persisted user data to migrate.
- **Previews:** [AudioPlayerManager](TuneQuest/Presentation/AudioPlayer/AudioPlayerManager.swift) → `GetTrackPreviewUseCase` → `TrackRepository` → `TrackService`. `loadPreview(trackId:autoplay:)` preserves autoplay by default; the game explicitly disables it. AVPlayer handles audio and AsyncImage handles artwork. Game results always use local catalog data.
- **Lifecycle:** the container creates a new view model and player for each game screen. Starting/restarting or leaving invalidates pending work. Confirming pauses playback; finishing/leaving releases it. Backgrounding pauses without automatically resuming.
- **TuneNetwork:** a local URLSession HTTP package with a Sendable protocol, generic JSON decoding, GET/POST and status-code errors. URLProtocol-based tests isolate transport from the live API.

The layers are folders within one app target, not separate architectural modules. DTO-to-domain mapping currently lives in domain-model extensions and the composition container is a singleton. These are existing tradeoffs. The catalog-only presentation model remains in source with its regression tests; it is no longer an app entry point. Multiplayer and settings remain placeholders without home-screen entry points.

## Roadmap

**Available today:** a complete solo timeline game, twenty curated songs, three lives, ten correct placements to win, same-song retries, results/replay, optional manual audio previews, recoverable media errors and unit tests.

**Future work:** device and assistive-technology validation, difficulty tuning, persistence, broader catalog coverage, visual identity, multiplayer and settings. There is no timer, extra scoring, difficulty selector, downloaded audio or background playback mode.
