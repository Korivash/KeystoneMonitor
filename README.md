# Keystone Monitor

## Dungeon Progress Tracker for Normal, Heroic, and Mythic+

Keystone Monitor is a compact, highly customizable dungeon tracker for World of Warcraft Retail.
It supports four tracking modes:

- **Auto** (recommended)
- **Normal**
- **Heroic**
- **Mythic+**

Created by **Korivash**.

## Project Docs

- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)
- [Support](SUPPORT.md)

## What It Tracks

### Normal / Heroic Mode

- **Dungeon Name**
- **Elapsed Dungeon Timer**
- **Boss/Objective Completion List**
- **Clean UI Layout** focused on boss progress and time spent in dungeon

### Mythic+ Mode

- **Active Dungeon & Key Level**
- **Run Timer & Time Limit Display** (`elapsed/limit`)
- **Chest Breakpoints** (`+3`, `+2`, `+1`)
- **Enemy Forces Progress Bar**
- **Death Count & Penalty Time**
- **Scenario Objective Completion**
- **Personal Best + Best Timed Comparison**
- **Active Affix Icons** with tooltips
- **Pace Hints** (`+3/+2/+1/Overtime`, optional)

## Key Commands

- `/km`: Open/close UI Studio
- `/km unlock`: Unlock tracker position for drag
- `/km lock`: Lock tracker position.
- `/km show`: Show tracker while unlocked.
- `/km hide`: Hide tracker while unlocked.
- `/km reset`: Reset tracker position.
- `/km debug`: Toggle mode detection debug logs.
- `/km debug now`: Print current detection snapshot once.

### Aliases

- `/mplus`
- `/keystonemonitor`

## UI Studio (`/km`)

### Behavior

- Lock/unlock tracker movement
- Show/hide while unlocked
- Toggle pace hints
- Select preview scenario
- Select tracked dungeon mode:
  - `Auto` (auto-detect by current dungeon difficulty)
  - `Normal`
  - `Heroic`
  - `Mythic+`

### Visual Skinning

- Hex color inputs for core UI elements
- Clickable color swatches (WoW color picker)
- Manual hex input (`RRGGBB` or `RRGGBBAA`)
- Class-color or custom accent style

### Fonts

- Title font
- Timer font
- Body font

### Presets & Profiles

- Built-in visual presets
- Profile export/import string support

## Design Goals

- **Fast readability** during combat and routing decisions
- **Clear timer + objective context** at a glance
- **Low clutter** overlay style
- **Deep customization** without sacrificing performance

## Installation

### CurseForge (Recommended)

- Install Keystone Monitor through CurseForge.

### Manual

1. Place the addon folder in:
   `World of Warcraft/_retail_/Interface/AddOns/`
2. Ensure the folder is exactly `KeystoneMonitor`
3. Run `/reload` in game

## Support

Found a bug or have a feature request? Please include:

- What mode you were using (`Normal`, `Heroic`, or `Mythic+`)
- Description of issue
- Expected behavior
- Actual behavior
- Lua error text (if any)
- `/km` profile export string (if relevant)
- Screenshot/video for UI issues

Discord: https://discord.gg/JbQQTbH4hR

## Why Choose Keystone Monitor?

Keystone Monitor focuses on practical, low-noise dungeon tracking that you can adapt to your UI quickly, with full support from entry-level dungeon runs to Mythic+ keys.
