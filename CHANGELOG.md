# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The game: flap with SELECT, scrolling pipes with random gaps, collision, score counter, and a game-over card with restart; CANCEL exits to the launcher.
- Fixed-timestep physics (15 ms steps) so the game plays the same at any tick length.
- Best score saved with the app's `storage`.
- LED flashes on flap, score and crash (permission `led`).
- Solana coin sprite generated from the Solana OS logomark by `tools/make_sprite.py`, with a gold-disc fallback.
- `tools/emu_drive.mjs` to install, run and screenshot the app in the hosted emulator (Node built-ins and Chrome only).
- `tools/package_sd.sh` to lay the app out for a microSD card.
- README with real emulator screenshots, plus the licence, contributing guide, code of conduct, security policy, citation file, roadmap and issue and PR templates.

[Unreleased]: https://github.com/aluinn/solana-os-flappy-bird-/commits/main
