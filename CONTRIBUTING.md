# Contributing

Thanks for your interest in contributing to Keystone Monitor.

## Before You Start

- Open an issue first for major feature changes.
- Keep pull requests focused and scoped to one topic.
- Test in-game whenever UI or runtime behavior changes.

## Development Setup

1. Clone this repository into your WoW AddOns folder:
   `World of Warcraft/_retail_/Interface/AddOns/KeystoneMonitor`
2. Launch WoW and enable the addon.
3. Use `/reload` frequently during iteration.

## Coding Guidelines

- Keep Lua code modular by feature area (`Core`, `Runtime`, `UI`, `Data`).
- Favor readable logic over clever shorthand.
- Avoid hardcoding text or styling in multiple places when shared config exists.
- Preserve saved variable compatibility when evolving `KeystoneMonitorDB`.

## UI Changes

- Validate behavior both inside and outside active keys.
- Ensure `/km` preview mode still allows practical positioning/tuning.
- Test at multiple scales and opacity values.

## Pull Request Checklist

- [ ] Feature/bug scope is clear
- [ ] No Lua errors in-game
- [ ] Slash commands still work
- [ ] `/km` opens and updates correctly
- [ ] Saved settings persist after `/reload`
- [ ] Changelog updated when relevant

## Commit Message Style (Recommended)

- `feat: add affix icon tooltips`
- `fix: prevent options overlap on large scale`
- `docs: update setup instructions`
