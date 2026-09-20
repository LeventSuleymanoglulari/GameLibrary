# Repository Guidelines

## Project Structure & Module Organization

This repository plans **Oyun Kütüphanesi**, a PC desktop application for tracking games, statuses, and personal ratings. It currently contains documentation only:

- `README.md`: project overview and links.
- `docs/proje-plani.md`: requirements, proposed rules, open decisions, and acceptance scenarios K1–K12.
- `docs/oyun-kutuphanesi-gorsel.html`: standalone visual explanation with inline CSS and SVG.
- `docs/assets/oyun-kutuphanesi-onizleme.png`: preview embedded in the README.

There are no application source or test directories. Keep supporting documents in `docs/` and images in `docs/assets/`.

## Build, Test, and Development Commands

No dependency manifest, build system, application runner, or automated test command exists yet.

- `open docs/oyun-kutuphanesi-gorsel.html` (macOS): preview the visual in a browser. On other systems, open the file directly with a browser.
- `git diff --check`: check tracked changes for whitespace errors before committing.
- `git diff`: review the scope and wording of changes.

The HTML needs no build step. Google Fonts requires internet access; system fonts provide an offline fallback.

## Coding Style & Naming Conventions

Keep project-facing documentation in Turkish and preserve established UI labels. Use descriptive Markdown headings, relative links, and lowercase hyphen-separated filenames such as `proje-plani.md`. Match the HTML's two-space indentation and existing inline CSS/SVG organization. Preserve semantic elements, accessible labels, and visible keyboard focus. No formatter or linter is configured.

## Testing Guidelines

No testing framework, test naming convention, or coverage threshold is established. For documentation changes, check relative links and consistency between the README, plan, and visual. For visual changes, inspect desktop and narrow layouts, keyboard scrolling, and offline font fallback; update the preview image when needed.

K1–K12 describe future application acceptance checks, not currently passing tests. Distinguish confirmed requirements from proposals; platform, desktop technology, storage, and rating scale remain undecided.

## Commit & Pull Request Guidelines

Recent commits use Conventional Commit messages such as `docs(plan): document game library scope and visual guide`. Use imperative messages and keep each commit focused on one coherent change.

PRs should explain the change and risk, link the relevant issue or plan section, and list verification performed. Include screenshots for visual changes and identify any schema, security, privacy, or deployment impacts. Do not present the static visual as a working application.
