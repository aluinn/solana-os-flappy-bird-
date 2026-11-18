---
title: "Add a parallax background"
labels: ["enhancement"]
---

## Context

The background is a flat dark colour (`ui.bg`). A few slow-moving shapes (stars, clouds or Solana-purple blobs) would give the screen depth. UI objects are a budget, though: the game uses 21 of 128, and each costs SRAM and per-tick work.

## Task

Add two or three layers of simple `ui.rect` shapes behind the pipes, scrolling left at different slow speeds (for example 10, 20 and 35 px/s), wrapping around when they leave the screen. Keep it purely visual: nothing in `lib/game.lua` changes.

- Create the objects **before** the pipes so they draw behind them (objects draw in creation order).
- Drive them from `on_tick`'s `ms` (not a tick count), and pass integers to `:pos` (floor them).
- Reuse a fixed pool; don't create or remove objects during play.

## Acceptance

- Background moves smoothly in the emulator; screenshots attached.
- Total UI objects stay well under 128 (state the final count).
- Measure the cost before and after with `node tools/emu_drive.mjs tools/perf_emulator.json` and report the peak instruction count per callback. The baseline is 2,808 (see `docs/PERFORMANCE.md`); say what it becomes, and update that doc if you change the app's numbers.
- The title and game-over cards remain legible over the background.
- Layers freeze (or keep drifting) sensibly on the game-over card; pick one and say which.

## Pointers

- `solana-flappy/main.lua`: scene creation order near the top (`ui.bg`, then `pipe_ui`), and `draw()`.
- `docs/PERFORMANCE.md`: baseline numbers and how to reproduce them.
- [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md): "Limits" (128 UI objects, 200,000 instructions per callback).
