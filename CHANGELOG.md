# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

## [0.3.1] - 2026-02-14

### Changed

- Timer display now shows elapsed and limit together (example: `20:00/35:00`).
- Failed key runs now show `FAILED` instead of `COMPLETED`.
- Timer text now turns red when the run is over the dungeon time limit.
- Objective list capacity increased to support up to 10 objective rows.
- Remaining incomplete objectives are now finalized at run completion to keep end-of-run objective state consistent.
- Objective Tracker visibility is now managed during active Mythic+ runs to prevent repeated tracker popups and background bar overlap.

### Credits

- Changes in this release were implemented by **Korivash**.

## [0.3.0] - 2026-02-13

### Added

- Advanced preview scenarios in `/km` Behavior (`Live Data`, `Simulated In-Progress`, `Floodgate Completed`).
- Tracker pace hint status line (`PACE: +3/+2/+1/Overtime`) with toggle control in `/km`.

### Changed

- Upgraded `/km` UI Studio layout to a centered two-column composition with expanded spacing and section reflow to reduce overlap risk.
- Expanded Behavior controls with preview scenario selection and pace-hint settings for richer styling workflows.
- Repositioned and centered PB/Best Timed block in the tracker to improve readability and avoid overlap.
- Completion status text now stays below deaths/penalty for clearer post-run status visibility.
- Final run snapshot remains visible after dungeon completion and only clears after leaving the Mythic+ instance.
- Forces row now uses objective-style completion markers (`[ ]` and `[Done]`).
- Objective rows now auto-cap to available vertical space to avoid text clipping/overflow at smaller heights.

### Fixed

- Frame opacity now targets only panel chrome (background + border), leaving tracker text/icons fully opaque.
- Opacity slider/import now supports true `0.00` minimum for fully transparent panel backgrounds.
- Affix icons now show active keystone affixes when available and fall back to weekly affix IDs when no active key data exists.

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
