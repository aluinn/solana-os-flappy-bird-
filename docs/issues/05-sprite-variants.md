---
title: "Add alternative bird sprites"
labels: ["good first issue"]
---

## Context

`solana-flappy/art/coin.png` is built by `tools/make_sprite.py`: a coin disc with the Solana logomark, an eye and a beak. One look is all there is. A few variants (a gold coin, a monochrome one, a "night" one) would be a fun cosmetic contribution.

## Task

Add a `--variant NAME` option to `tools/make_sprite.py` (standard library only; `argparse` is fine) with at least two new looks besides the current default. The default output must stay exactly as it is today. Choose the sprite at launch by changing which file `main.lua` loads, or just ship the variant PNGs under `art/` and document how to swap one in.

## Acceptance

- `python3 tools/make_sprite.py <logomark.c>` with no flag produces a `coin.png` **byte-identical** to the committed one.
- Each variant is 24×24 RGBA and reads clearly at 1× (look at a 12× preview, as in the repo history, and attach it).
- No new dependency (no Pillow).
- The README's credits and licence notes stay accurate: every variant still contains the Solana logomark, so it is **not MIT**. Say so in the script's header.
- The 24×24 size and the image budget stay the same (a 24×24 PNG is about 1.2 KB of heap).

## Pointers

- `tools/make_sprite.py`: `build()` draws the disc, rim, beak, eye and logomark; `write_png()` writes the file.
- `solana-flappy/main.lua`: the sprite is loaded with `pcall(ui.image, 0, 0, "art/coin.png")` (near line 44).
- Solana OS's `main/assets/img_logomark_40.c` is the source of the logomark. It isn't in this repo; the script takes its path as an argument.
