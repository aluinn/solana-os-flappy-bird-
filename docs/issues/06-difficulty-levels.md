---
title: "Add difficulty levels"
labels: ["enhancement"]
---

## Context

Every run uses the same numbers: gap 84 px, speed 100 px/s, gravity 1100 px/s². The first feel-test of the game will probably say "too hard" or "too easy" depending on who plays. Levels solve that and make the best score more meaningful.

## Task

Add Easy, Normal and Hard presets. On the title screen, LEFT and RIGHT cycle the level (`on_key` already gets `"left"` and `"right"`); SELECT starts. Suggested knobs: `GAP`, `SPEED` and perhaps `SPACING`. Keep `Normal` equal to today's numbers.

- Keep the rule changes in `lib/game.lua` (for example `game.set_level(name)`), not in `main.lua`.
- Remember the chosen level with `storage` and keep a **separate best score per level**. `storage` is limited to 16 KB per app, which is plenty for a few numbers.

**A trap to know about:** `main.lua` copies the constants once at the top (`local PIPE_W, GAP = game.PIPE_W, game.GAP`), so a level that changes `GAP` has to make drawing read the current value instead.

## Acceptance

- Three levels, selectable on the title screen, with the current one shown.
- `Normal` plays exactly as before; the existing tests still pass.
- New tests cover each preset (gaps and speed take effect; levels never change mid-run).
- The best score is tracked per level and survives a relaunch (check it in the emulator).
- A short note in the README features list and an entry in `CHANGELOG.md`.

## Pointers

- `solana-flappy/lib/game.lua`: constants `GAP`, `SPEED`, `SPACING`, `GRAVITY` (lines 19 to 29) and `place()`, which uses `M.GAP`.
- `solana-flappy/main.lua`: `on_key()` (line 133), `show_title()`, and the `GAP` copy at line 8.
- [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md): key names, and `storage`.
