---
title: "Two-badge race over the mesh"
labels: ["enhancement"]
---

## Context

Solana OS apps can talk to other badges running the same app with the `mesh` permission: `mesh.send(to, msg)`, received by `on_mesh(from, msg)`, and `mesh.nearby()` lists who is in range. Flappy Bird is a natural fit for a "who lasts longer" race.

## Task

Add an optional race mode that shares **scores, not positions**. The mesh allows 4 messages a second of at most 200 bytes each, so a stream of positions isn't possible and isn't needed.

Sketch:

1. From the title screen, a key (for example RIGHT) opens a lobby that lists nearby badges (`mesh.nearby()`, `kind == "badge"`).
2. The host sends a small start message; both badges start their own run with the same random seed (`game.new(rand)` already takes the random function, so a seeded generator makes both see the same pipes).
3. Each badge sends `{score = n}` when its score changes (well under the rate limit) and shows the opponent's live score.
4. When both have died, show who won.

Over a **bridge** (Wi-Fi) messages take 1 to 3 seconds, which suits this score-only design but not fast play.

## Acceptance

- `app.json` adds `"mesh"` to `permissions`, and the README FAQ and `SECURITY.md` (which both say the app only needs `led`) are updated to match.
- Messages are small, rate-limited and tolerate loss: repeat the latest score now and then rather than relying on one message.
- Solo play still works unchanged when no one is nearby.
- Tested with two emulator tabs on one origin (`/emulator` and `/emulator?badge=2`, per the Solana OS docs). `tools/emu_drive.mjs` drives one tab, so you may need to extend it or test by hand.
- Notes on what you could and couldn't test on real hardware.

## Pointers

- [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md): the `mesh` section, including limits and "Bridged badges".
- [Connectivity guide](https://github.com/solana-foundation/solana-os/blob/main/docs/CONNECTIVITY.md) and its examples (for instance `examples/mesh-and-wifi`).
- `solana-flappy/lib/game.lua`: `M.new(rand)` takes the random function.
- `solana-flappy/app.json`: `permissions`.
- Heads up: an app with `mesh` takes the radio from Wi-Fi while it runs.
