## What and why

<!-- What does this change, and why? Link the issue: "Closes #123". -->

## How I checked it

- [ ] `lua tests/run.lua` and `lua tests/smoke_main.lua` pass
- [ ] `luacheck solana-flappy tests tools` is clean
- [ ] I played it in the emulator (`HEADED=1 node tools/emu_drive.mjs`) and it works
- [ ] Screenshot attached, if the look or feel changed

## Checklist

- [ ] Only documented Solana OS Lua API is used
- [ ] Game rules stay in `solana-flappy/lib/game.lua` (no badge API there), with a test for any rule change
- [ ] Coordinates passed to `pos` and `size` are integers
- [ ] `CHANGELOG.md` updated under "Unreleased"
- [ ] My commits follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] I'm not adding the Solana logo or fonts from Solana OS, or other assets I can't share
