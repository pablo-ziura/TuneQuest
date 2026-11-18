# TuneQuest

A native SwiftUI music game for iPhone.

## Continuous integration

[iOS CI](.github/workflows/ios-ci.yml) runs when a pull request targeting `main` or
`develop` is opened, reopened or updated. Manual execution is also available once
the workflow is present on the default branch.

The workflow uses Xcode 27.2 and an iPhone 17 / iOS 27.2 simulator on GitHub's
`xcode-27` runner, which is currently in public preview. It performs these steps:

1. Build the `TuneQuest` app for the simulator.
2. Run tests with the shared `TuneQuest` scheme and `TestPlan`.
3. Run package tests through the `TuneNetwork` scheme in `Packages/TuneNetwork`.
4. Upload available `.xcresult` bundles, including after failure, for seven days.

A failed build or test command fails the check and skips subsequent test steps.
New commits cancel superseded runs for the same pull request. Builds do not
require signing certificates or secrets. Tests use repository doubles and a
URLProtocol stub rather than live Deezer requests.

## Require CI before merging

After the first workflow run, create an active branch ruleset for `main` and
`develop` under **Settings → Rules → Rulesets**. Enable **Require a pull request
before merging** and **Require status checks to pass**, then select
**Build and unit tests** as a required check. Ruleset availability depends on the
repository visibility and GitHub plan.

Run CI on the pull request after pushing this branch to verify the GitHub-hosted
environment.
