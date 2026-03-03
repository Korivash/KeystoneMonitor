# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

## [0.5.1] - 2026-03-03

### Fixed

- Fixed options UI startup error on some clients where `EditBox:SetNormalFontObject` is unavailable.
- Updated modern input styling to use a safe font-object API fallback path.

## [0.5.0] - 2026-03-03

### Added

- New modern tabbed options UI layout with left sidebar navigation (`General`, `Layout`, `Visual`, `Fonts`, `Profiles`).
- Sidebar search for quick tab discovery.
- Sidebar collapse/expand mode.
- Slider controls with paired numeric input boxes.
- Collapsible options sections for advanced configuration density.

### Changed

- Complete visual redesign of options UI to a black/blue modern theme with cleaner hierarchy and modular panels.
- Updated options controls to reusable component patterns for better maintainability.

## [0.4.1] - 2026-03-03

### Added

- Added tracked dungeon modes for `Follower` and `Mythic 0` in UI Studio.

### Fixed

- Fixed auto-mode difficulty detection to correctly classify `Mythic 0` separately from `Mythic+`.
- Fixed dungeon mode detection to recognize `Follower` dungeons.

### Changed

- Updated non-Mythic+ tracker labeling to show `Follower Dungeon` and `Mythic 0 Dungeon`.

## [0.4.0] - 2026-03-03

### Added

- `Auto` tracked dungeon mode that automatically picks Normal, Heroic, or Mythic+ by current instance difficulty.
- Dungeon mode selector in UI Studio Behavior: `Auto`, `Normal`, `Heroic`, and `Mythic+`.
- Support for tracking Normal and Heroic dungeons in addition to Mythic+.
- New profile field `dungeonMode` with import/export support.
- Optional debug helpers:
  - `/km debug` to toggle dungeon mode detection logging.
  - `/km debug now` to print an immediate snapshot.

### Changed

- Runtime state sync is now mode-aware and follows the selected dungeon mode.
- Normal/Heroic displays now focus on:
  - Dungeon name
  - In-dungeon elapsed timer
  - Boss/objective completion list
- Mythic+ display keeps full feature set (affixes, key level, chest breakpoints, forces, deaths/penalty, pace hints, records).
- Mythic+ event handlers are now gated by selected mode to prevent cross-mode state noise.
- Improved dungeon difficulty detection for Auto mode by using both difficulty ID and difficulty name.
- Improved Mythic+ forces quantity fallback parsing.

### Docs

- Refreshed addon documentation to reflect multi-mode dungeon support.
- Corrected command/alias documentation to match implemented slash commands.

## [0.3.3] - 2026-02-25

### Changed

- Updated TOC interface for the latest WoW retail version (`120001`).
- Bumped addon version to `0.3.3`.

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
