# Support

If you run into issues, use GitHub Issues with the details below.

## Bug Report Template

Please include:

- WoW version (Retail build)
- Addon version
- Active tracking mode (`Auto`, `Normal`, `Heroic`, or `Mythic+`)
- Exact command/action performed (for example: `/km`, imported profile, changed dungeon mode, entered dungeon/key)
- Expected behavior
- Actual behavior
- Any Lua error text (full copy)
- Screenshot/video if visual/layout related
- Optional: profile export string from `/km` for reproduction

## Common Troubleshooting

- Run `/reload` after updates.
- Ensure folder name is exactly `KeystoneMonitor`.
- If addon appears out of date after a patch, enable "Load out of date AddOns" temporarily.
- Reset position with `/km reset` if tracker appears off-screen.
- Verify `Tracked Dungeon Mode` in `/km` Behavior matches the dungeon you are in.
- If display looks mismatched after mode changes, switch mode, then re-enter the dungeon instance.
- Use `/km debug` while testing mode auto-detection, then `/km debug` again to disable it.

## Feature Requests

When requesting features, include:

- Problem you are trying to solve
- Why current behavior is insufficient
- Preferred UX (mockup/text flow)
- Whether the feature should be optional
