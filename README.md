# TuneQuest

**Work in progress.** A personal iOS music-game project, currently implemented as a small catalog and audio-preview prototype. Guessing rounds and scoring do not exist yet.

## Try the current slice

Open the app → **Explore catalog** → listen to a preview → pause, stop or replay → move between three tracks → return home.

- A bundled JSON catalog supplies the track IDs; Deezer supplies metadata, artwork and audio previews.
- Previews start automatically on entry and when changing tracks. Playback stops when leaving the catalog.
- Loading, empty-catalog, unavailable-preview and recoverable-error states are explicit. Missing artwork has a placeholder.
- Multiplayer and settings remain placeholders in the source and have no entry points in the app.

Internet access is required. **No account, API key or secret configuration is needed.** There is no offline/demo mode; the mocks are test doubles, not an app data source. Deezer availability and preview rights can vary by track, region and time.

## Requirements and running

- macOS with Xcode and an installed iOS Simulator runtime.
- iOS **18.0** deployment target. This repository is evaluated as an iOS app; macOS and visionOS are not validated.
- The local package requires **Swift tools 6.1+**. The app uses Swift 5 language mode; TuneNetwork uses Swift 6.
- Verified on **Xcode 27.2 (27B52), Swift 6.4.2**, with an **iPhone 17 / iOS 26.5** simulator. Older Xcode versions and physical devices have not been verified.
- No third-party dependencies: `Packages/TuneNetwork` is a local Swift package.

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

In Xcode, use `⌘U` with the **TuneQuest** scheme and **TestPlan**. The single shared [test plan](TestPlan.xctestplan) includes both TuneQuestTests and TuneNetworkTests:

```sh
xcodebuild -project TuneQuest.xcodeproj -scheme TuneQuest -testPlan TestPlan \
  -destination "platform=iOS Simulator,id=$TUNEQUEST_SIMULATOR_ID" \
  -derivedDataPath /tmp/TuneQuest-portfolio-final \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

The tests use Swift Testing, repository doubles and a URLProtocol stub; they require no Deezer access. They cover catalog loading/mapping, use cases, preview error recovery and cancellation, audio cleanup, and HTTP GET/POST behavior. They do not constitute a UI or accessibility test suite.

Verified on 16 November 2026: simulator build and all **30 tests** passed (24 app, 6 package; 31 executed cases including parameterized inputs), with no failures or skipped tests. A separate temporary hosted integration probe exercised real Deezer playback, pause, natural completion, replay, stop and return/reentry. The presentation views were also inspected with repository doubles in Dark Mode at the largest accessibility text size, including scrolling to the controls. The temporary probe is not part of the delivered test suite.

Touch-driven previous/next navigation, VoiceOver, Voice Control, hardware audio interruptions, physical devices, iOS 18 and non-iOS destinations have not been manually verified. Audio was checked through AVPlayer state, not a human listening test. The layout review is not a full accessibility audit.

## Architecture

SwiftUI presentation uses Observation and `@MainActor` state. [DependencyContainer](TuneQuest/DependencyContainer.swift) composes concrete dependencies; [AppCoordinator](TuneQuest/AppCoordinator.swift) injects them and resolves routes for the NavigationStack.

- **Catalog:** [CatalogViewModel](TuneQuest/Presentation/Scenes/CatalogViewModel.swift) → [GetCatalogUseCase](TuneQuest/Domain/UseCase/GetCatalogUseCase.swift) → repository → [CatalogLocalDataSource](TuneQuest/Data/DataSource/CatalogLocalDataSource.swift) → bundled [catalog.json](TuneQuest/catalog.json).
- **Previews:** [AudioPlayerManager](TuneQuest/Presentation/AudioPlayer/AudioPlayerManager.swift) → [GetTrackPreviewUseCase](TuneQuest/Domain/UseCase/GetTrackPreviewUseCase.swift) → [TrackRepository](TuneQuest/Data/Repository/TrackRepository.swift) → [TrackService](TuneQuest/Data/Service/TrackService.swift). AVPlayer handles audio; AsyncImage handles artwork.
- **TuneNetwork:** a reusable URLSession HTTP client with a Sendable [protocol](Packages/TuneNetwork/Sources/TuneNetwork/NetworkClientProtocol.swift), generic JSON decoding, GET/POST and status-code errors. `TrackService` calls `get(endpoint: "track/\(id)", params: nil, headers: nil)`; [URLProtocol-based tests](Packages/TuneNetwork/Tests/TuneNetworkTests/NetworkClientTests.swift) isolate transport from the live API.

The layers are folders within one app target, not separate architectural modules. DTO-to-domain mapping currently lives in domain-model extensions; the container is a singleton. These are existing tradeoffs, not claims of complete architectural isolation. Legacy `GameOnePlayerView` naming reflects the intended product; its current behavior is catalog playback.

## Roadmap

**Available today:** three-track catalog browsing, metadata/artwork, audio previews and basic playback controls, recoverable presentation states, unit tests.

**Future work:** guessing rounds and scoring; multiplayer and settings; broader UI/accessibility/device coverage; interruption/background-audio behavior and visual identity. Offline playback, persistence and search are not implemented.
