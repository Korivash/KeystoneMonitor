# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

## [0.2.1] - 2026-02-13

### Added

- Affix icon row with tooltips in the main tracker.
- Color wheel integration for all hex skin fields in `/km`.
- Profile import/export support in UI Studio.
- Theme preset system in UI Studio.
- Per-element font selection (title/timer/body).

### Changed

- Expanded and reflowed UI Studio layout for improved readability.
- Actions bar anchored and centered for cleaner composition.
- Enhanced rendering pipeline to support broader appearance customization.
- Preserved final run stats on tracker after `CHALLENGE_MODE_COMPLETED`; state now clears when leaving the dungeon instance.
- Moved completion status text (`COMPLETED` / `COMPLETED (Timed)`) below deaths/penalty for improved readability.
- Updated forces display to use boss-style completion markers (`[ ]` in progress, `[Done]` at 100%).
- Added objective-row fit capping so rows hide when space is limited, preventing overflow at smaller frame sizes or larger font scales.

## [0.1.0] - 2026-02-13

### Added

- Initial addon runtime for Mythic+ session tracking.
- Timer, deaths, objective, and forces tracking.
- PB summary storage per dungeon map.
- Slash command support (`/km`, `/keystonemonitor`, `/mplus`).
- Customizable options menu with live preview mode.
- Draggable tracker behavior with lock/unlock support.
