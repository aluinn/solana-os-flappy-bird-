# Performance

Every number here was measured by a script in this repository and can be reproduced. What I could **not** measure is on-badge timing: I have no hardware, so there are no frame-time or battery figures, and the desktop numbers below should not be read as badge speed.

## What matters on the badge

Solana OS limits an app per its [Lua API reference](https://github.com/solana-foundation/solana-os/blob/main/docs/LUA_API.md): a **6 MB Lua heap**, **200,000 VM instructions per callback**, and 128 UI objects. The game's cost is measured against those.

## On Solana OS's firmware (emulator)

Measured by [`tools/perf_emulator.json`](../tools/perf_emulator.json) in the hosted emulator, which runs the badge's own firmware compiled to WebAssembly. The scenario launches the unmodified app, then presses SELECT about every 450 ms for about 23 seconds (40 presses). That covers the title screen, several runs, crashes and restarts. It then closes the app and asks the firmware for its figures (`lua mem`).

| Metric | Result | Limit | Share of limit |
|---|---|---|---|
| Lua heap right after launch | 18,249 bytes | 6,291,456 | 0.29 % |
| Lua heap, peak over the session | 36,039 bytes | 6,291,456 | 0.57 % |
| VM instructions, busiest single callback | 2,808 | 200,000 | 1.4 % |
| UI objects (counted from `main.lua`) | 21 | 128 | 16 % |

Four runs gave identical peak figures (36,039 bytes, 2,808 instructions); boot heap was read in one of them.

How to read these:

- The firmware's "steps" figure is the most VM instructions any one callback used. It counts in blocks of 1,000 and includes work done in C on the app's behalf, so treat it as a close upper-bound estimate, not an exact count.
- The peak heap is about twice the launch heap because it includes garbage the collector hadn't cleared yet, not live data.
- The app was **sideloaded**, so the firmware compiled it from source on load ("compiled here"). An app installed from the App Store runs precompiled code from flash, which the docs say lowers heap use. This game has not been through the store, so I can't give that figure.
- The emulator is not a badge. Its README says its Lua heap accounting matches the badge's, but it has no real heap limit and its timing is cooperative. Out-of-memory paths aren't exercised.

## Game logic on a desktop

Measured by [`tools/bench_logic.lua`](../tools/bench_logic.lua), which runs `solana-flappy/lib/game.lua` under plain Lua with a cheap bot that restarts the game whenever it dies.

Machine: Apple M1 Pro, macOS 15.7.4, Lua 5.5.1 built from the lua.org source (`make macosx`). Three runs of 2,000,000 steps each:

| Metric | Result |
|---|---|
| Heap growth over 2,000,000 steps, GC stopped | 0.125 KB, identical in all three runs |
| One fixed step (15 ms of game time), bot included | 570 to 589 ns |
| One 30 ms badge tick (two steps), bot included | 1,065 to 1,097 ns |
| The bot alone | 41 ns |

The 0.125 KB is the measurement's own overhead, not growth: it comes out the same at 20,000, 200,000 and 20,000,000 steps. That backs the design claim that **stepping the simulation allocates nothing**. It says nothing about `main.lua`'s drawing code, which the firmware measurement above covers.

The nanosecond figures only show that the logic is cheap and let you compare one change against another. The badge runs a different CPU and a 32-bit Lua, so don't scale them to predict its speed.

## Reproduce

```sh
# desktop logic benchmark (needs Lua 5.5), from the repository root
lua tools/bench_logic.lua            # or: lua tools/bench_logic.lua 200000

# firmware figures (needs Node 22+ and Google Chrome; the run takes about a minute)
node tools/emu_drive.mjs tools/perf_emulator.json
```

The emulator run was done with Google Chrome 157 in headless mode against `https://solana.com/breakpoint/badge/emulator`. The hosted emulator is updated by Solana, so its figures could shift if the firmware changes.
