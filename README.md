# Keystone Monitor

A modern Mythic+ tracker addon for World of Warcraft, focused on clarity during runs and deep UI customization outside runs.

Created by **Korivash**.

## Why This Addon

Most M+ trackers are either too noisy or too rigid. Keystone Monitor aims to stay compact in combat while still giving players full control over layout, colors, fonts, and profile sharing.

## Core Features

- Real-time run timer and chest breakpoints (`+3`, `+2`, `+1`)
- Enemy forces progress + percentage
- Death counter + death penalty time
- Objective completion tracking
- Boss-style completion markers for forces and objectives (`[ ]` / `[Done]`)
- Dungeon PB summary tracking
- Active affix icons with hover tooltips (current keystone with weekly fallback)
- Unlockable/lockable draggable tracker
- `/km` UI Studio with advanced customization

## Run Completion Behavior

- On dungeon completion, final run stats remain visible on the tracker.
- The tracker keeps completed run data until you leave the Mythic+ instance.
- Completion status text (`COMPLETED` / `COMPLETED (Timed)`) is shown below the deaths/penalty row.
- Objective rows automatically hide when vertical space is limited so text stays inside the frame.
- Frame opacity controls only the panel background/border, not text/icon visibility.

## UI Studio (`/km`)

Open with:

```text
/km
```

### Behavior

- Lock tracker position
- Show tracker while unlocked
- Class-color accent toggle
- Pace hint status toggle (`PACE: +3/+2/+1/Overtime`)
- Preview Scenario selector:
  - Live Data
  - Simulated In-Progress
  - Floodgate Completed

### Layout

- Centered two-column studio layout with expanded spacing to prevent overlap
- Frame width
- Frame height
- Frame scale
- Frame opacity
- Font scale

### Visual Skinning

- Hex color controls (`RRGGBB` or `RRGGBBAA`)
- Clickable color swatches that open WoW color wheel
- Manual hex input support

Important:

- If you want custom accent color, uncheck **Use class color for accent** first.

### Fonts

- Independent font selection for:
  - Title
  - Timer
  - Body text

### Presets and Profiles

- Built-in theme presets
- Export profile string
- Import profile string

## Commands

- `/km` - open/close UI Studio
- `/km unlock` - unlock tracker movement
- `/km lock` - lock tracker movement
- `/km show` - show while unlocked
- `/km hide` - hide while unlocked
- `/km reset` - reset tracker position

Aliases:

- `/keystonemonitor`
- `/mplus`

## Installation

### Manual

1. Place this folder in:
   `World of Warcraft/_retail_/Interface/AddOns/KeystoneMonitor`
2. Launch or restart WoW.
3. Run `/reload`.

### Addon Manager

- Install through CurseForge/Wago if packaged there.

## Compatibility

- Retail WoW
- TOC currently targets `12.0.x` era interface versions

## Project Structure

```text
KeystoneMonitor/
  src/
    Core/        # boot + shared utilities
    Data/        # saved variable defaults
    Runtime/     # challenge state, events, timer, records
    UI/          # tracker rendering, options, slash commands
  assets/        # design assets/mockups
```

## Development Notes

- SavedVariables: `KeystoneMonitorDB`
- Primary entry point: `KeystoneMonitor.toc`
- Addon namespace exposed as `_G.KeystoneMonitor`

## Documentation

- Changelog: `CHANGELOG.md`
- Roadmap: `ROADMAP.md`
- Contributing: `CONTRIBUTING.md`
- Support and bug reports: `SUPPORT.md`

## License

No license file is currently included. All rights reserved by default until a license is added.
