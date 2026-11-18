# Contributing

Thanks for helping with Solana Flappy. This is a small Lua game for the Solana BP26 badge, so most contributions are small too: a tweak, a test, a sprite, an effect. Please read the [Code of Conduct](CODE_OF_CONDUCT.md) first.

## Ways to help

- Pick up one of the drafts in [`docs/issues/`](docs/issues/). Open a GitHub issue from it (or comment on an existing one) so nobody doubles up, then send a PR.
- Report a bug or suggest a feature with the issue templates.
- Try the game on a real badge. It has only run in the emulator so far, and hardware notes are very welcome.

## Setup

You need:

| Tool | Why | Check |
|---|---|---|
| Node 22+ | the emulator driver (`tools/emu_drive.mjs`) | `node -v` |
| Google Chrome | the driver controls it | installed |
| Python 3 | sprite generation (`tools/make_sprite.py`) | `python3 -V` |
| Lua 5.5 | running the tests | `lua -v` should say 5.5 |
| luacheck | linting | `luacheck --version` |

Nothing needs `npm install` or `pip install`: the Node and Python scripts use only their standard libraries.

```sh
git clone https://github.com/aluinn/solana-os-flappy-bird-.git
cd solana-os-flappy-bird-
HEADED=1 node tools/emu_drive.mjs     # play it in the hosted emulator
```

## Commands

| Command | What it does |
|---|---|
| `HEADED=1 node tools/emu_drive.mjs` | Install and run the app in a visible emulator window |
| `node tools/emu_drive.mjs script.json` | Scripted session with screenshots (see the file header) |
| `tools/package_sd.sh [card path]` | Lay the app out for a microSD card |
| `lua tests/run.lua` | Run the unit tests for the game logic |
| `luacheck solana-flappy tests tools` | Lint the Lua |

## Where things live

- `solana-flappy/lib/game.lua`: game rules. **No badge API in here**, so it stays testable under plain Lua. Keep it that way.
- `solana-flappy/main.lua`: drawing, input, LEDs and storage.
- `tests/`: tests for `lib/game.lua`.
- `docs/ARCHITECTURE.md`: how the pieces fit and why.

## Writing badge Lua

Solana OS's [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md) is the source of truth. Don't use a function you can't find there. A few rules that bite:

- **Numbers are 32-bit** on the badge (integers wrap at ±2^31) but 64-bit on your computer. Tests on a desktop won't catch overflow, so keep values small.
- `pos` and `size` take **integers**. A float with a fraction raises an error, so wrap computed coordinates in `math.floor`.
- A callback gets **200,000 VM instructions** and the app gets 128 UI objects, so do work per tick sparingly.
- Keys arrive as `"select"`, `"back"`, `"up"`, `"down"`, `"left"`, `"right"`. Returning false for `"back"` exits.
- Move things by the `ms` passed to `on_tick`, never by counting ticks.
- Avoid garbage in per-frame code: reuse tables and don't build strings every tick.

## Branches

Branch from `main` and name the branch `<type>/<short-description>`, for example `feat/difficulty-levels` or `fix/pipe-gap-overlap`.

## Commits

We use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`, in the imperative, under about 72 characters.

| Type | Use for |
|---|---|
| `feat` | a new feature or behaviour |
| `fix` | a bug fix |
| `docs` | documentation only |
| `test` | adding or changing tests |
| `refactor` | a change that neither fixes a bug nor adds a feature |
| `perf` | a performance improvement |
| `chore` | tooling, config, housekeeping |
| `ci` | CI workflows |

Scopes in use: `app`, `game`, `art`, `tools`, `assets`. Keep commits small and focused.

## Pull requests

- One idea per PR, and say what and why in the description.
- Run `lua tests/run.lua` and `luacheck` before pushing. CI runs both.
- Changed how it looks or plays? **Try it in the emulator** and attach a screenshot.
- Changed game rules in `lib/game.lua`? Add or update a test.
- Update [`CHANGELOG.md`](CHANGELOG.md) under "Unreleased" for anything a player or developer would notice.
- **Don't** commit the Solana logo or fonts from Solana OS's `main/assets/`, or any other asset you don't have the right to share. The existing sprite is the only brand asset here and is not MIT-licensed (see the README's Licence section).
- Keep large media out of Git history. If you need something big, open an issue first.

By contributing you agree your work is released under the [MIT licence](LICENSE).
