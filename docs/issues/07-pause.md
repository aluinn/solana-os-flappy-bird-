---
title: "Pause the game with a key"
labels: ["enhancement"]
---

## Context

CANCEL exits the app and HOME returns to the launcher, so there is no way to stop for a moment without losing the run. The API has unused keys (`"up"`, `"down"`, `"left"`, `"right"`).

## Task

Let UP pause and resume during a run. While paused:

- nothing moves, and time doesn't accumulate (resuming mustn't make the bird jump);
- an overlay says "Paused" with a hint to press UP to continue;
- SELECT does nothing until resumed (so a stray flap can't fire the moment you resume).

Implement the state in `lib/game.lua` (a `paused` flag or phase that `update` and `flap` respect) so it's testable, and keep the overlay in `main.lua`, reusing the title/game-over panel.

## Acceptance

- Pausing and resuming works only during a run (not on the title or game-over cards).
- After a long pause, resuming continues exactly where it stopped: `s.acc` isn't inflated and there's no large step.
- Tests cover: no movement while paused, no flap while paused, resume continues.
- The key hint at the bottom updates, and `docs/ARCHITECTURE.md`'s input diagram is updated.

## Pointers

- `solana-flappy/lib/game.lua`: `M.update` (line 160), `M.flap` (line 81) and the phases `ready`, `play`, `dead`.
- `solana-flappy/main.lua`: `on_key()`, `overlay()`, and `ui.hint(...)`.
- `docs/ARCHITECTURE.md`: "Input handling".
- Note that `on_tick` keeps being called while paused, and `ms` keeps arriving: the pause has to throw that time away.
