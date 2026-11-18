# AGENTS.md

Living document for every agent working on `TuneQuest`.
Read it in full before proposing changes or modifying code. Keep it aligned with the actual
repository; do not import architecture or capabilities from other projects.

Act as a Senior iOS Architect. Technical explanations must be direct, professional and concise
in Spanish. Keep code, identifiers, comments, commit titles and commit descriptions in English.
When uncertain about Apple API availability, deprecation or behavior, validate it against official
documentation through the `cupertino` MCP before making a recommendation.

## Project overview

- Native SwiftUI music game with `TuneQuest` and `TuneQuestTests` Xcode targets.
- iPhone app, iOS 18.0 deployment target. Do not assume iPad, macOS or visionOS support from
  inherited test-target settings.
- The app uses Swift 5 language mode, Observation (`@Observable`) and `@MainActor` presentation.
- `Packages/TuneNetwork` is a local Swift package using Swift tools 6.1 and Swift 6 language mode.
- No third-party dependencies, accounts, API keys or persistent player data are required.
- Reference verification environment: Xcode 27.2 and iPhone 17 / iOS 26.5 Simulator. Discover
  available destinations instead of hardcoding a simulator UUID.
- Product scope is a single-player timeline game. Multiplayer and settings are placeholders.

## Composition root and state flow

```text
TuneQuestApp
└── @State AppCoordinator
    └── DependencyContainer.shared
        ├── Router → NavigationStack in ContentView
        ├── CatalogLocalDataSource → CatalogRepository
        ├── NetworkClient → TrackService → TrackRepository
        └── makeSinglePlayerViewModel()
            ├── StartSinglePlayerGameUseCase
            └── AudioPlayerManager → GetTrackPreviewUseCase
```

- `AppCoordinator` resolves routes and creates destination views with opaque `some View` results.
- `DependencyContainer` composes concrete dependencies. Its singleton is an existing tradeoff;
  do not introduce more singletons, service locators or global feature state.
- Every game screen receives a fresh `GameOnePlayerViewModel` and `AudioPlayerManager`.
  The view retains its model with `@State`; never share a live game between destinations.
- Views receive presentation dependencies, not repositories or services, and do not construct the
  data graph. Keep business rules in domain models/use cases and orchestration in the ViewModel.
- `Router` owns the navigation path. Add routes only for active product flows.

## Layers and packages

| Location | Responsibility |
|---|---|
| `TuneQuest/Presentation` | SwiftUI views, observable ViewModels and AVPlayer integration |
| `TuneQuest/Domain` | Game rules, catalog/track models and focused use cases |
| `TuneQuest/Data` | DTOs, bundled catalog loading, repositories and Deezer service |
| `Packages/TuneNetwork` | Reusable URLSession transport, HTTP errors and JSON decoding |
| `TuneQuestTests` | App/domain tests, resource contracts and repository doubles |

- App layers are folders within one target, not independently compiled architectural modules.
- DTO-to-domain mapping currently lives in domain-model extensions. Avoid unrelated migration of
  those existing boundaries while implementing a focused feature.
- Keep `GameSession` independent of SwiftUI, AVFoundation and networking.
- TuneNetwork must not depend on app models, Deezer-specific payloads, game rules or presentation.
- Keep TuneNetwork local at `Packages/TuneNetwork`, registered in the project's Package
  Dependencies and linked once through its `TuneNetwork` library product.
- Protocol names end in `Protocol`; use `DTO` and `ViewModel` suffixes for their actual roles.
- Do not introduce feature-to-feature dependencies or split targets without a concrete need.

## Gameplay and catalog contracts

- `GameConfiguration` centralizes three starting lives and ten correct placements by default.
- One reference song starts the timeline with its year visible and does not count as a correct
  placement. A game chooses eleven distinct entries from the bundled catalog.
- The player selects a gap and confirms. Correct answers insert a fixed card and reveal its year.
- A wrong answer costs one life and retains the same pending song with its year hidden. The third
  failure ends the game; the tenth correct placement wins. Feedback requires explicit advancement.
- Equal years accept every position that maintains nondecreasing chronological order.
- Do not allow repeated confirmation, selection during feedback or mutation of finished sessions.
- `TuneQuest/catalog.json` uses schema v2 with twenty curated recordings. Each entry has a unique
  Deezer ID, title, artist, `originalReleaseYear` and `releaseYearSource` URL.
- The answer is the first publication year of the selected recording, including an earlier album
  release. Remasters/compilations retain that year. Never use Deezer's `release_date` as the answer.
- Verify the recording and source when changing entries; avoid accidentally selecting live,
  remixed or re-recorded versions. Update DTOs, mapping, validation, resources and tests together
  when changing the catalog contract.
- The pending year must remain hidden in visual content and accessibility labels until a correct
  answer or final defeat. Local metadata allows gameplay to continue when media is unavailable.

## Concurrency and audio lifecycle

- Keep the coordinator, container, ViewModels and audio presentation on `MainActor`.
- Preserve Sendable repository/transport contracts. Use actors for mutable asynchronous doubles;
  do not add unsafe annotations merely to suppress concurrency diagnostics.
- Use structured `.task(id:)` view lifecycle work and explicit cancellation/invalidation.
  Late responses must not overwrite a newer game, restore audio after exit or end another load.
- `AudioPlayerManager.loadPreview(trackId:autoplay:)` defaults to autoplay for existing callers;
  the game explicitly passes `false` and activates the audio session only on explicit playback.
- Confirming pauses audio. Finishing, restarting or leaving resets the player and invalidates
  pending previews. Backgrounding pauses without automatically resuming.
- Media failures offer retry and must not block a placement or consume lives.
- `TrackService` validates returned IDs because Deezer may return an error payload with HTTP 200.
- Keep AVPlayer observers and audio-session cleanup idempotent. Do not claim background playback
  or interruption handling beyond what is implemented and verified.

## UI and accessibility

- Use native SwiftUI controls, semantic colors/text styles and the existing navigation flow.
  No shared design system or `DESIGN.md` currently exists.
- Current app text is English. Do not assume a bilingual string catalog exists.
- Preserve light/dark appearance, Dynamic Type, contrast and comfortable touch targets.
- The timeline is vertical. Use selectable gaps with clear position descriptions and selection
  traits; provide explicit text/icon feedback rather than color alone.
- With accessibility text sizes or limited height, keep controls reachable through scrolling.
- Treat VoiceOver focus, announcements and physical-device behavior as separate manual checks;
  successful unit tests or rendered screenshots do not establish that those checks passed.

## Project changes and version control

- Use XcodeProjectCLI (`xcp`) for supported project, build-setting, membership and asset operations.
  Run `xcp list-targets` before target-specific changes and use `--project-only` when retaining files.
- Do not hand-edit `project.pbxproj`. If xcp lacks an operation, explain that limitation and use
  Xcode's native editor for that operation, preserving existing unrelated edits.
- App and test folders use filesystem-synchronized groups. Do not add redundant file references
  or compile the same source in multiple targets. Keep test plans out of app resources.
- Inspect the worktree before editing. Preserve user changes, including staged changes.
- Continue the active feature branch unless requested otherwise. Deliver small, coherent commits
  with Conventional Commit titles and a concise explanatory body, both in English.
- Do not commit unrelated changes or push/publish without authorization.

## Testing and quality

- Tests are risk-based. Add/update focused tests for rules, parsing, contracts, cancellation, audio
  lifecycle and reproducible regressions. Do not add tests that merely mirror trivial wiring or
  static SwiftUI layouts; use a build or visual review for those changes.
- App tests use Swift Testing and injected repository doubles. TuneNetwork uses a URLProtocol
  stub. Automated verification must not depend on live Deezer access.
- The shared `TuneQuest` scheme uses `TuneQuest/TestPlan.xctestplan` for `TuneQuestTests`.
  Run `TuneNetworkTests` through the package's own `TuneNetwork` scheme: Xcode does not expose
  that dependency's tests to the host plan in this setup. Never leave missing test targets in a plan.
- Run checks appropriate to the modified area. A package-link or test-plan change requires
  verifying the integrated app and both test targets; documentation alone needs no full suite.
- Build with native `xcodebuild` and use `xcrun simctl` for simulator discovery/install/launch.
  Keep generated products and result bundles outside tracked source.

Run from the repository root, replacing the destination with an available simulator:

```sh
xcrun simctl list devices available

xcodebuild -project TuneQuest.xcodeproj -scheme TuneQuest \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/TuneQuest-verification CODE_SIGNING_ALLOWED=NO build

xcodebuild -project TuneQuest.xcodeproj -scheme TuneQuest -testPlan TestPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/TuneQuest-verification \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test

(cd Packages/TuneNetwork && xcodebuild -scheme TuneNetwork \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/TuneNetwork-verification CODE_SIGNING_ALLOWED=NO test)
```

Keep this document and `README.md` synchronized with changes to architecture, targets, packages,
resource contracts, gameplay, audio lifecycle or verification strategy. Report exactly what was
verified and any material checks that remain pending.
