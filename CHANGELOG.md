# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

## [0.10.1] - 2026-08-18

### Fixed

- Party/raid announcements (dungeon completion, group-finder fill) no longer throw an `ADDON_ACTION_BLOCKED` error on the current client, which now requires a direct player action to send chat from automated code. `AnnounceToParty` catches the block and falls back to a local chat line instead.
- Forcing an objective tracker refresh after unhiding it could taint the tracker's update chain and later crash Blizzard's own UI (`GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'KeystoneMonitor'`) under the client's new secret-value protections. The addon now just shows the tracker and lets Blizzard's own event cycle refresh it.

## [0.10.0] - 2026-08-08

### Added

- Best Timed and Highest Key tabs alongside Runs in the Run History panel. Best Timed lists every Mythic+ dungeon with the highest level you've timed and your best time at that level; Highest Key lists the highest level you've completed per dungeon (timed or not), flagged TIMED / OVER TIME. Both are built from your full Blizzard Mythic+ run history, not just the last 100 logged runs, and cover the whole current season's dungeon pool even for dungeons you haven't run yet.
- "Announce when Group Finder party fills" option (General tab, on by default). When your party reaches 5, Keystone Monitor prints a local chat line naming the keystone/dungeon, e.g. `Keystone Monitor: Group Filled For +15 Operation: Mechagon`. If you posted the listing, it reads your own held keystone; if you applied to and joined someone else's group instead, it reads that listing's own dungeon and comment text rather than your key. Re-arms if the group drops below 5 and fills again.
- "Also broadcast to party chat" sub-option (General tab, off by default). Sends the same group-filled message to party (or raid) chat via `SendChatMessage` so the whole group sees it, not just you.
- "Announce dungeon completion in party chat" option (General tab, off by default). When any tracked dungeon run finishes, sends a party/raid chat line with the clear time and death count — `Keystone Monitor: Dungeon Timed in 24:15 - 2 deaths` / `Dungeon Not Timed in 32:40 - 5 deaths` for Mythic+, `Dungeon Completed in 18:02 - 1 death` for every other mode.

### Changed

- Run History's Runs/Best Timed/Highest Key tabs and the All/Mythic+/Dungeons filters are now centered as their own rows instead of hugging the left edge, with more vertical breathing room below the summary stats.

## [0.9.0] - 2026-08-05

### Added

- Run History tab in the `/km` window — the run log now lives inside the main options window instead of chat. It shows summary stats (total runs, timed rate, best timed key, average deaths), All / Mythic+ / Dungeons filters, key levels colored by tier, Timed/Depleted/Cleared results, and full per-run tooltips. `/km history` jumps straight to the tab.
- Watch button on the tracker frame (top-right, shown faintly) that opens the Run History tab.
- Run history now stores the last 100 runs (up from 30).

### Changed

- The `/km` window has been redesigned to match the new visual language: near-black neutral surfaces, an accent gradient strip with a soft glow across the top, accent-colored section titles with gradient rules, sidebar tabs with an accent selection bar, and toggles/sliders tinted by your accent or class color instead of the old fixed blue. Changing the accent color (or toggling class color) re-themes the window instantly along with the tracker.
- Tracker visual refresh: gradient accent bar with a soft glow, subtle header sheen tinted by your accent color, smoothly animated progress bar with a spark at the fill edge, and icon-based objective states (green check for done, hourglass for engaged, dim indicator for pending) replacing the `[Done]` / `[Engaged]` / `[ ]` text markers.
- Deaths are highlighted in red on the tracker once the counter is above zero.

### Removed

- The standalone `/km history` window and `/km history chat` chat printout. History is part of the `/km` window now.
- The ko-fi support link. The Help & Feedback section in General now links to the Discord for issues and questions instead.

### Performance

- Progress bar animation runs its OnUpdate handler only while the bar is actually moving; the history panel reuses row frames and only refreshes while visible.

## [0.8.0] - 2026-08-02

### Added

- Timewalking dungeon support, completing coverage of every 5-player dungeon mode: Follower, Normal, Heroic, Timewalking, Mythic 0, and Mythic+.
- Boss tracking for non-Mythic+ dungeons: the full boss roster is detected from the Encounter Journal on zone-in, bosses show `[Engaged]` while pulled and `[Done]` with a kill time when defeated, and a progress bar shows `Bosses X / Y`.
- Automatic run completion detection for non-Mythic+ dungeons — the run is marked `COMPLETE` with the total clear time when the final boss dies.
- Personal best clear times saved per dungeon and difficulty for every mode, shown on the tracker (`Best 12:34`).
- Per-boss split deltas against your best recorded run, shown next to each kill time in green (ahead) or red (behind). Works in Mythic+ and all other modes.
- Party death tracking in every mode, including modes with no built-in death counter.
- Death log tooltip — hovering the Deaths line lists who died and when, class-colored, for the current run.
- Run history: the last 30 runs across all modes with times, deaths, key levels, and Timed/Depleted results. New `/km history` command prints the most recent runs.
- Run persistence — an in-progress run now survives `/reload`, disconnects, and briefly leaving the instance. Timer, boss kills, and deaths restore automatically. New `/km resetrun` command discards the saved snapshot and restarts tracking.
- Automatic keystone insertion when opening the Font of Power, with a General options toggle (`Auto-insert keystone at the font`).
- Optional stopwatch for untimed dungeon modes (General options toggle, off by default). Timing always runs in the background to power records, splits, and the death log.
- Addon icon (`keystone.png`).

### Changed

- Untimed dungeon modes (Follower, Normal, Heroic, Timewalking, Mythic 0) no longer display a clock by default, since those modes have no dungeon timer.
- Default profile refreshed: 288x258 frame, 0.99 scale, fully transparent panel background, unified accent/text/timer/bar coloring, and 1.16 font scale. The `Keystone Monitor Default` preset matches.
- Non-Mythic+ tracker now shows the mode label together with your best time for the current dungeon.
- Profile export/import strings now include the new settings and the Timewalking mode.

### Fixed

- Death tracking is fully compatible with Midnight's instanced combat log restrictions — the addon watches party unit health instead of the combat log, avoiding `ADDON_ACTION_FORBIDDEN` errors.
- Non-Mythic+ dungeons previously showed an empty objective list; they now display real boss objectives.

### Performance

- Timer widgets only redraw when the visible second changes instead of ten times per second.
- Objective data re-renders only when something actually changed, using in-place diffing.
- Death and count updates are event-driven rather than polled.
- All text elements skip redundant updates; affix display data and preview states are cached.
- High-frequency events are registered only while a run is active.

## [0.6.0] - 2026-06-26

### Changed

- Updated TOC interface for WoW Midnight (`120007`).
- Internal state handling updates for the 12.0.7 client.

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
