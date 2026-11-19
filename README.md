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

## SonarQube Cloud

[SonarQube analysis](.github/workflows/sonar.yml) analyzes pull requests targeting
`develop` and pushes to `develop`. Push analysis keeps the reference branch up to
date for subsequent pull requests. Manual runs are available once the workflow
is on the GitHub default branch; select `develop`, since other branches are
skipped. The separate iOS CI workflow continues to build and test pull requests
targeting both `main` and `develop`.

The scanner checks the app and local package sources, with their test folders
classified separately in [sonar-project.properties](sonar-project.properties).
It waits for the Quality Gate and fails `SonarQube analysis` if the gate fails.
The workflow uses GitHub OIDC to obtain a temporary Sonar token instead of a
stored repository secret.

Each workflow run invokes the scanner once. GitHub shows two related checks:
`SonarCloud Code Analysis`, published by SonarQube Cloud, and `SonarQube analysis`,
published by GitHub Actions. The workflow waits for the same Quality Gate result,
so both checks fail when that gate fails. These are two status reports, not two
scans. SonarSource action references are pinned to full commit SHAs; when updating
them, verify the new SHA against the official release and update the version comment.

Complete these settings before running the workflow:

1. In the [TuneQuest SonarQube project](https://sonarcloud.io/project/overview?id=pablo-ziura_TuneQuest),
   rename the current main branch to `develop` from the project's branch settings.
   The Free plan only analyzes the main branch and pull requests targeting it.
   This changes the Sonar branch configuration, not GitHub's default branch.
2. Under project **Administration → Analysis Method**, disable **Automatic
   Analysis** when using this CI-based workflow.
3. In the `pablo-ziura` Sonar organization, open **Administration → Organization
   settings → Analysis** and enable **Secretless analysis for GitHub Actions**.
   The Sonar project must be bound to the `pablo-ziura/TuneQuest` GitHub repository.
4. Merge the workflow into `develop` to trigger a reference analysis. After
   verifying analysis on a pull request, require **SonarQube analysis** in the
   GitHub ruleset for `develop`, alongside **Build and unit tests**. Require
   branches to be up to date before merging to keep checks current with `develop`.

This authentication supports pull requests from branches in this repository.
Fork pull requests cannot obtain the required OIDC token and fail authentication;
supporting them requires a separate analysis setup. Coverage reports are not
imported by this workflow. The existing `.xcresult` test artifacts alone do not
provide Sonar-compatible coverage, so coverage conditions in the Quality Gate
require an additional report-generation and import step.
