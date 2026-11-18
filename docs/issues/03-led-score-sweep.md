---
title: "Sweep the 8 LEDs on score"
labels: ["good first issue"]
---

## Context

Scoring currently flashes all 8 LEDs purple for 120 ms with `led.fill`. The badge has 8 individually addressable RGB LEDs, and the API has `led.set(i, r, g, b)` (1-based, `led.count` is 8: 1..6 across the top, 7..8 on the right edge).

## Task

Replace the score flash with a quick sweep: light the LEDs one after another across the top and down the side over about 200 ms, then turn them off. Keep the flap (green) and crash (red) flashes as they are, or restyle them if you like.

Do the timing in `on_tick` with the elapsed `ms`, the way `led_ms` already works. Don't use `timer.after`: only 8 timers exist and each call creates a closure.

## Acceptance

- Score triggers the sweep; a second score during a sweep restarts it cleanly.
- A crash or flap during a sweep still takes over the LEDs (a crash should always show red).
- `led` is guarded (`if led then`) so the game still runs where the module is missing.
- All LEDs go off when the effect ends, and the game still turns them off on exit (the OS does that automatically; just don't leave them lit during play).
- It works in the emulator, whose page shows the LEDs on the drawn badge. Attach a screenshot or short recording.

## Pointers

- `solana-flappy/main.lua`: `flash()` and `led_ms` (around lines 83 to 88), and the countdown in `on_tick` (around line 152).
- [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md): the `led` section.
