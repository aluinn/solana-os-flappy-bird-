# Security policy

## Reporting a vulnerability

Please report security problems **privately** through GitHub's private vulnerability reporting:

1. Go to the repository's **Security** tab.
2. Choose **Report a vulnerability** (or open [this link](https://github.com/aluinn/solana-os-flappy-bird-/security/advisories/new)).
3. Describe what you found, how to reproduce it, and what you think the impact is.

Please don't open a public issue or pull request for a vulnerability. I'll acknowledge reports as soon as I can, say whether I can reproduce it, and credit you in the fix if you'd like.

## Scope

Solana Flappy is a single-player game that runs inside Solana OS's Lua sandbox. It asks for one permission, `led`, and uses no network, Bluetooth, mesh, wallet or file access beyond its own bundled files and `storage`. So the realistic issues here are things like a crash or a way to exhaust the badge's memory or instruction budget from a game state, or a problem in the repository's scripts (`tools/`).

Out of scope, and best reported to their owners:

- Bugs in Solana OS, its Lua host or the emulator: [solana-foundation/solana-os](https://github.com/solana-foundation/solana-os).
- Problems with the Solana website or the hosted emulator.

## Supported versions

Only the latest commit on `main` is supported.
