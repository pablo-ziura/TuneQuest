# TuneQuest

**Work in progress.** A personal iOS music-game project, currently implemented as a small catalog and audio-preview prototype. Guessing rounds and scoring do not exist yet.

## Try the current slice

Open the app → **Explore catalog** → listen to a preview → pause, stop or replay → move between tracks → return home.

- The bundled [catalog.json](TuneQuest/catalog.json) currently supplies five track IDs; Deezer supplies metadata, artwork and audio previews. The resource contains `version`, `modified` and `ids` fields, not complete local track metadata.
- Previews start automatically on entry and when changing tracks. Playback stops when leaving the catalog.
- Loading, empty-catalog, unavailable-preview and recoverable-error states are explicit. Missing artwork has a placeholder.
- Multiplayer and settings remain placeholders in the source and have no entry points in the app.

Internet access is required. **Running the app requires no account, API key or secret configuration.** SonarQube CI has its own account and repository-binding requirements, documented below. There is no offline/demo mode; the mocks are test doubles, not an app data source. Deezer availability and preview rights can vary by track, region and time.

## Requirements and running

- macOS with Xcode and an installed iOS Simulator runtime.
- iOS **18.0** deployment target. This repository is evaluated as an iOS app; macOS and visionOS are not validated.
- The local package requires **Swift tools 6.1+**. The app uses Swift 5 language mode; TuneNetwork uses Swift 6.
- Reference toolchain: **Xcode 27.2 (27B52), Swift 6.4.2**. Earlier verification used an **iPhone 17 / iOS 26.5** simulator; CI selects **iPhone 17 / iOS 27.2**. See the dated verification results below. Older Xcode versions and physical devices have not been verified.
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

In Xcode, use `⌘U` with the **TuneQuest** scheme and **TestPlan**. The shared [test plan](TestPlan.xctestplan) currently includes both TuneQuestTests and TuneNetworkTests:

```sh
xcodebuild -project TuneQuest.xcodeproj -scheme TuneQuest -testPlan TestPlan \
  -destination "platform=iOS Simulator,id=$TUNEQUEST_SIMULATOR_ID" \
  -derivedDataPath /tmp/TuneQuest-portfolio-final \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

To run the package suite independently, use its own scheme:

```sh
(cd Packages/TuneNetwork && xcodebuild -scheme TuneNetwork \
  -destination "platform=iOS Simulator,id=$TUNEQUEST_SIMULATOR_ID" \
  -derivedDataPath /tmp/TuneQuest-network-verification CODE_SIGNING_ALLOWED=NO test)
```

CI runs both suites once through the shared plan. The standalone command verifies the package's own scheme when needed; it does not represent additional unique tests.

The tests use Swift Testing, repository doubles and a URLProtocol stub; they require no Deezer access. They cover catalog loading/mapping, use cases, preview error recovery and cancellation, audio cleanup, and HTTP GET/POST behavior. They do not constitute a UI or accessibility test suite.

Merge verification on 19 November 2026: the simulator build and all **30 tests** in the shared plan passed (24 app, 6 package) with Xcode 27.2 / Swift 6.4.2 on iPhone 17 / iOS 27.2. The six package tests also passed independently through the `TuneNetwork` scheme. This verifies compilation and automated tests for the merged code; it does not establish manual UI, playback or accessibility verification of this merge.

Historical verification before this merge, on 16 November 2026: simulator build and all **30 tests** passed (24 app, 6 package; 31 executed cases including parameterized inputs), with no failures or skipped tests. A separate temporary hosted integration probe exercised real Deezer playback, pause, natural completion, replay, stop and return/reentry. The presentation views were also inspected with repository doubles in Dark Mode at the largest accessibility text size, including scrolling to the controls. The temporary probe is not part of the delivered test suite, and those checks do not establish manual verification of later merges.

Touch-driven previous/next navigation, VoiceOver, Voice Control, hardware audio interruptions, physical devices, iOS 18 and non-iOS destinations have not been manually verified. Audio was checked through AVPlayer state, not a human listening test. The layout review is not a full accessibility audit.

## Continuous integration

[iOS CI](.github/workflows/ios-ci.yml) runs when a pull request targeting `main` or
`develop` is opened, reopened or updated. Manual execution is also available once
the workflow is present on GitHub's default branch.

The workflow selects Xcode 27.2 and an iPhone 17 / iOS 27.2 simulator on GitHub's
`xcode-27` runner. It performs these steps:

1. Resolve the exact simulator UDID and wait for it to finish booting (3-minute limit).
2. Compile the app and both test suites with `build-for-testing` (10-minute limit).
3. Run `TestPlan` with `test-without-building`, executing TuneQuestTests and
   TuneNetworkTests once (10-minute limit).
4. On failure or cancellation, save the process list and available CoreSimulator
   log before querying simulator state and logs (2-minute limit).
5. Upload environment, boot, build and test logs, available `.xcresult` bundles
   and failure diagnostics for seven days (3-minute upload limit).

The job retains its overall 30-minute limit. Build and test commands preserve
their exit status while saving output with `tee`, so a failed command fails
**Build and unit tests**. Simulator preparation failures stop compilation, and
build failures skip test execution. Diagnostic collection and artifact upload
are best effort; forced cancellation or runner loss can prevent them from completing.
New commits cancel superseded runs for the same pull request.
Simulator builds do not require signing certificates, and the unit tests do not
require live Deezer access.

## SonarQube Cloud

[SonarQube analysis](.github/workflows/sonar.yml) analyzes pull requests targeting
`develop` when opened, reopened, updated, retargeted or marked ready for review,
as well as pushes to `develop`. Push analysis keeps the reference branch up to
date for subsequent pull requests. For manual runs, select `develop`; other branches are skipped.
Manual execution requires the workflow to be present on GitHub's default branch.

The scanner checks app and local package sources, with their test folders
classified separately in [sonar-project.properties](sonar-project.properties).
It waits for the Quality Gate and fails **SonarQube analysis** if the gate fails.
GitHub OIDC provides a temporary Sonar token instead of a stored repository secret.

Each workflow run invokes the scanner once. GitHub shows two related checks:
**SonarCloud Code Analysis**, published by SonarQube Cloud, and **SonarQube
analysis**, published by GitHub Actions. The job waits for the same Quality Gate
result, so both checks fail when that gate fails. These are two status reports
for one scan. SonarSource action references are pinned to full commit SHAs; verify
the new SHA against the official release and update its version comment when
updating an action.

Keep these settings aligned with the workflow:

1. In the [TuneQuest SonarQube project](https://sonarcloud.io/project/overview?id=pablo-ziura_TuneQuest),
   use `develop` as the project's main branch. The Free plan only analyzes that
   branch and pull requests targeting it. This setting does not change GitHub's
   default branch.
2. Under project **Administration → Analysis Method**, keep **Automatic Analysis**
   disabled while using this CI-based workflow.
3. In the `pablo-ziura` Sonar organization, enable **Secretless analysis for GitHub
   Actions** under **Administration → Organization settings → Analysis**. Bind the
   Sonar project to the `pablo-ziura/TuneQuest` GitHub repository.

This authentication supports pull requests from branches in this repository.
Fork pull requests cannot obtain the required OIDC token and fail authentication;
supporting them requires a separate analysis setup.

No minimum test coverage is required by the current project policy. The setting
`sonar.coverage.exclusions=**/*` excludes all files from Sonar's coverage
calculations only. Source and test analysis, duplication checks and the other
Quality Gate conditions remain enabled, and the iOS CI job still runs the unit
tests. Coverage remains unmeasured by Sonar for this project.

The built-in **Sonar way** gate includes an 80% new-code coverage condition, which
was not a project requirement. The Free plan does not support custom quality
gates, so coverage is explicitly outside the scope of this integration. If a
coverage requirement is adopted later, define the policy first, remove the
coverage exclusion and generate/import a compatible Xcode coverage report.
The existing `.xcresult` artifacts alone do not supply that report to Sonar.

## Require CI before merging

Manage branch rulesets under **Settings → Rules → Rulesets** in GitHub. Keep them
**Active**, with an empty bypass list, and require pull requests, successful status
checks and branches to be up to date before merging. Enable **Restrict deletions**
and **Block force pushes** to protect the branches from deletion and history
rewrites. Ruleset availability depends on repository visibility and the GitHub plan.

| Target branch | Required GitHub Actions checks |
|---|---|
| `develop` | **Build and unit tests**, **SonarQube analysis** |
| `main` | **Build and unit tests** |

The Sonar service check **SonarCloud Code Analysis** can also be required on
`develop`; it reports the same Quality Gate. Sonar does not run for pull requests
targeting `main`, so do not require its checks there. Check names must match the
configured jobs, and the expected source for the workflow checks is **GitHub Actions**.

## Architecture

SwiftUI presentation uses Observation and `@MainActor` state. [DependencyContainer](TuneQuest/DependencyContainer.swift) composes concrete dependencies; [AppCoordinator](TuneQuest/AppCoordinator.swift) injects them and resolves routes for the NavigationStack.

- **Catalog:** [CatalogViewModel](TuneQuest/Presentation/Scenes/CatalogViewModel.swift) → [GetCatalogUseCase](TuneQuest/Domain/UseCase/GetCatalogUseCase.swift) → repository → [CatalogLocalDataSource](TuneQuest/Data/DataSource/CatalogLocalDataSource.swift) → bundled [catalog.json](TuneQuest/catalog.json).
- **Previews:** [AudioPlayerManager](TuneQuest/Presentation/AudioPlayer/AudioPlayerManager.swift) → [GetTrackPreviewUseCase](TuneQuest/Domain/UseCase/GetTrackPreviewUseCase.swift) → [TrackRepository](TuneQuest/Data/Repository/TrackRepository.swift) → [TrackService](TuneQuest/Data/Service/TrackService.swift). AVPlayer handles audio; AsyncImage handles artwork.
- **TuneNetwork:** a reusable URLSession HTTP client with a Sendable [protocol](Packages/TuneNetwork/Sources/TuneNetwork/NetworkClientProtocol.swift), generic JSON decoding, GET/POST and status-code errors. `TrackService` calls `get(endpoint: "track/\(id)", params: nil, headers: nil)`; [URLProtocol-based tests](Packages/TuneNetwork/Tests/TuneNetworkTests/NetworkClientTests.swift) isolate transport from the live API.

The layers are folders within one app target, not separate architectural modules. DTO-to-domain mapping currently lives in domain-model extensions; the container is a singleton. These are existing tradeoffs, not claims of complete architectural isolation. Legacy `GameOnePlayerView` naming reflects the intended product; its current behavior is catalog playback.

[GameOnePlayerViewModel](TuneQuest/Presentation/Scenes/GameOnePlayerViewModel.swift)
and [TrackRowView](TuneQuest/Presentation/Scenes/TrackRowView.swift) remain in source
from the earlier card-list implementation. The container still constructs the
model and the coordinator injects it, but the current `GameOnePlayerView` reads
`CatalogViewModel` and does not render those rows or expose drag-and-drop controls.
Restoring card placement is separate work from the current preview flow.

## Roadmap

**Available today:** catalog browsing, metadata/artwork, audio previews and basic playback controls, recoverable presentation states, unit tests, build/test CI and SonarQube analysis.

**Future work:** guessing rounds and scoring; multiplayer and settings; broader UI/accessibility/device coverage; interruption/background-audio behavior and visual identity. Offline playback, persistence and search are not implemented.
