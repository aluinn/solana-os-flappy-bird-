---
title: "Brighten the \"Best\" line on the game-over card"
labels: ["good first issue"]
---

## Context

On the game-over card the "Best N" line is drawn in the theme colour `"dim"`, which is low-contrast against the dark card (see `docs/assets/shot-screen-game-over.png`). The same label (`line2`) is blank on the title screen, so only the game-over card is affected.

## Task

Make the "Best" line easier to read. Use a fixed `0xRRGGBB` colour or another theme name from the [Lua API colour list](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md) (`"text" "dim" "bg" "panel" "border" "purple" "green" "pink" "lpurple" "blue" "aqua" "lime" "yellow" "orange"`). Consider highlighting it (for example `"green"`) when the run just set a new best, which needs `show_game_over()` to know whether `s.score` beat the previous best before `save_best()` ran.

## Acceptance

- The "Best" line is clearly legible on the game-over card in the emulator.
- Colours are still fixed or theme names; no new dependencies.
- You attach a before/after screenshot (`node tools/emu_drive.mjs` can capture one; see the file header).
- `docs/assets/shot-screen-game-over.png` is replaced by a new retake, **under a new filename**, and the README points at it.

## Pointers

- `solana-flappy/main.lua`: `line2` is created near line 54 with `color = "dim"`; `show_game_over()` sets its text.
- `solana-flappy/main.lua`: `save_best()` and `on_tick` show the order in which `best` is updated.
