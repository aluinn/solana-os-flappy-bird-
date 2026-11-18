# Roadmap

Plans, not promises. Nothing here has a date. Ideas that are ready to pick up have a draft in [`docs/issues/`](docs/issues/).

## Now

- **Try it on a real badge.** The game has only been played in the hosted emulator. Hardware feel (button latency, LED brightness, the 28 px ground and hint bar on the real panel) is unchecked.
- **Tune the feel.** Gravity, flap strength, gap size and pipe speed are first guesses in `solana-flappy/lib/game.lua`.
- **Tests and CI** for the pure game logic, so rule changes are safe.

## Next

Small, self-contained improvements:

- [Brighten the "Best" line](docs/issues/01-brighten-best-score-line.md)
- [Pipe colour by score](docs/issues/02-pipe-colour-by-score.md)
- [LED sweep on score](docs/issues/03-led-score-sweep.md)
- [More edge-case tests](docs/issues/04-edge-case-tests.md)
- [Alternative bird sprites](docs/issues/05-sprite-variants.md)
- [Difficulty levels](docs/issues/06-difficulty-levels.md)
- [Pause](docs/issues/07-pause.md)

## Later

- [Parallax background](docs/issues/09-parallax-background.md), if it fits the badge's 128 UI-object budget.
- [Two-badge race over the mesh](docs/issues/08-mesh-race-mode.md). The mesh allows 4 messages a second of at most 200 bytes, so it would share scores, not positions.
- **Submit to the Solana OS App Store**, which needs an account with X linked and passes a code review.

## Not planned

- **Sound.** Solana OS has no sound API.
- **Network leaderboards.** They'd need a server and the `http` permission; this app deliberately asks only for `led`.
