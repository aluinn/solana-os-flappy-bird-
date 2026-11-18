---
title: "Add edge-case tests for the game logic"
labels: ["good first issue"]
---

## Context

The core rules (physics, collision, scoring) have tests in `tests/`. Several behaviours that are easy to break are still untested.

## Task

Add test cases to `tests/run.lua` (or a new file it loads) for:

1. **Stall clamp.** `game.update(s, 1000)` runs the same number of steps as `game.update(s, game.MAX_FRAME_MS)`.
2. **Accumulator.** Two `update(s, 8)` calls make exactly one 15 ms step in total; `s.acc` carries the remainder.
3. **Restart delay.** In the `dead` phase, `game.flap(s)` returns `false` and does nothing until `RESTART_DELAY_MS` has passed, then starts a fresh run with score 0.
4. **Ceiling.** Flapping at the top never kills the bird and holds `y` at `BIRD_R`.
5. **Recycling.** After many steps there are always `NPIPES` pipes, spaced `SPACING` apart, and every gap has `GAP_MARGIN <= gap_y <= PLAY_H - GAP_MARGIN - GAP`.
6. **Score once.** Each pipe adds exactly 1 to the score, even over many steps.

Pass a seeded or fixed `rand` function to `game.new(rand)` so the tests are deterministic.

## Acceptance

- `lua tests/run.lua` passes and fails correctly: break a rule on purpose and confirm the matching test fails.
- Tests use only plain Lua (no badge API) and no new dependencies.
- `luacheck` stays clean.

## Pointers

- `solana-flappy/lib/game.lua`: `M.new(rand)`, `M.update`, `M.flap`, `M.reset`, and the constants at the top of the file.
- `tests/run.lua`: the existing tests show the style.
- Remember that desktop Lua has 64-bit integers and the badge has 32-bit. Keep test values small.
