---
title: "Change the pipe colour as the score climbs"
labels: ["good first issue"]
---

## Context

Pipes are always Solana purple (`COL_PIPE`, `COL_CAP`). A colour change every few points gives the player a sense of progress for almost no cost.

## Task

Pick a short palette (for example purple, then blue, then aqua, then green, using the theme names or hex values) and switch to the next one each time the score reaches a multiple of, say, 10. Recolour the pipe rectangles with `r:color(c)`, which is documented for `ui.rect`. Reset to the first palette when a new run starts.

## Acceptance

- The colour changes only when the score crosses a threshold. Do **not** call `:color()` on every tick; do it once per change.
- The 12 pipe rectangles (`pipe_ui[i].top/topc/bot/botc`) all change together, caps included.
- The first palette comes back on restart.
- No new tables or strings are created per tick.
- Attach screenshots of two palettes. Game rules in `solana-flappy/lib/game.lua` don't change.

## Pointers

- `solana-flappy/main.lua`: `COL_PIPE`, `COL_CAP` (lines 12 and 13), the `pipe_ui` table (around line 26), and the `shown_score` check in `draw()`, which already runs code only when the score changes.
- [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md): `ui.rect` and `r:color(c)`. Theme names resolve when the call is made.
