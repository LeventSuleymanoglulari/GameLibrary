# Repository Guidelines

## Project Structure & Module Organization

This repository develops **Oyun Kütüphanesi**, a local macOS application built with SwiftUI and SwiftData.

- `Game library/Game library/`: application, game model, RAWG search and Keychain storage.
- `Game library/Game libraryTests/`: focused XCTest behavior checks.
- `Game library/Game libraryUITests/`: native application smoke tests.
- `Game library/Game library.xcodeproj`: Xcode project and test targets.
- `README.md`: setup, usage and verification commands.
- `ROADMAP.md`: phased delivery and acceptance criteria.
- `docs/`: product decisions, acceptance scenarios K1–K20 and verification evidence.
- `docs/assets/`: screenshots and the static visual preview.

Keep supporting documents in `docs/` and images in `docs/assets/`.

## Build, Test, and Development Commands

Use Xcode 27 or later with the macOS SDK. The app supports macOS 26 or later.

```sh
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' build
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' '-only-testing:Game libraryTests' test
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' test
git diff --check
```

Native UI tests need an active macOS session. Use temporary or in-memory test stores, never the user's library or RAWG credentials. No separate linter is configured.

`open docs/oyun-kutuphanesi-gorsel.html` opens the standalone design visual. It needs no build step. Google Fonts requires internet access; system fonts provide an offline fallback.

## Coding Style & Naming Conventions

Keep project-facing documentation in Turkish and preserve established UI labels. Use descriptive Markdown headings, relative links, and lowercase hyphen-separated filenames such as `proje-plani.md`. Match the HTML's two-space indentation and existing inline CSS/SVG organization. Preserve semantic elements, accessible labels, and visible keyboard focus. No formatter or linter is configured.

## Testing Guidelines

Use XCTest for the existing behavior seams. Cover persisted identity, migration, import validation and search behavior with deterministic local data. Keep successful live RAWG checks separate from fixture-backed tests and report when a real key was not available.

For documentation changes, check relative links and consistency between the README, roadmap, plan and visual. For visual changes, inspect the native window and keyboard behavior, and include a screenshot when relevant. The static HTML is a design artifact, not the application.

K1–K20 are acceptance contracts. Mark a scenario as verified only with recorded evidence. Platform, storage, rating scale and independent status rules are defined in `docs/ilk-surum-kararlari.md`. Status and rating editing belong to phase 3.

## Commit & Pull Request Guidelines

Recent commits use Conventional Commit messages such as `docs(plan): document game library scope and visual guide`. Use imperative messages and keep each commit focused on one coherent change.

PRs should explain the change and risk, link the relevant issue or plan section, and list verification performed. Include screenshots for visual changes and identify any schema, security, privacy, or deployment impacts. Do not present the static visual as a working application.
