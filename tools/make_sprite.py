#!/usr/bin/env python3
"""Build solana-flappy/art/coin.png, the 24x24 bird sprite.

The Solana logomark is not stored in this repo as a PNG. Solana OS ships it as
an LVGL RGB565A8 array (main/assets/img_logomark_40.c). This script decodes
that array, shrinks it with a box filter, and stamps it on a drawn coin disc.
Pure Python 3 standard library: no Pillow needed.

usage: python3 tools/make_sprite.py <path/to/solana-os/main/assets/img_logomark_40.c> [out.png]

The logomark is a Solana Foundation brand asset (not MIT). See README "Credits".
"""
import math
import re
import struct
import sys
import zlib

SIZE = 24


def load_logomark(path):
    src = open(path, encoding="utf-8").read()
    w = int(re.search(r"\.w = (\d+)", src).group(1))
    h = int(re.search(r"\.h = (\d+)", src).group(1))
    body = src[src.index("_map[]"):src.index("};")]
    data = bytes(int(x, 16) for x in re.findall(r"0x([0-9a-fA-F]{2})", body))
    assert len(data) == w * h * 3, (len(data), w, h)  # RGB565 (2 B) + alpha (1 B)
    px = []
    for i in range(w * h):
        v = data[2 * i] | (data[2 * i + 1] << 8)
        r = (v >> 11) & 31
        g = (v >> 5) & 63
        b = v & 31
        px.append(((r << 3) | (r >> 2), (g << 2) | (g >> 4), (b << 3) | (b >> 2),
                   data[w * h * 2 + i]))
    return w, h, px


def box_resize(w, h, px, tw, th):
    """Area-average downscale, alpha-weighted so edges stay clean."""
    out = []
    for ty in range(th):
        for tx in range(tw):
            x0, x1 = tx * w / tw, (tx + 1) * w / tw
            y0, y1 = ty * h / th, (ty + 1) * h / th
            r = g = b = a = wsum = 0.0
            for sy in range(int(y0), min(h, math.ceil(y1))):
                for sx in range(int(x0), min(w, math.ceil(x1))):
                    cw = (min(x1, sx + 1) - max(x0, sx)) * (min(y1, sy + 1) - max(y0, sy))
                    pr, pg, pb, pa = px[sy * w + sx]
                    r += pr * pa * cw
                    g += pg * pa * cw
                    b += pb * pa * cw
                    a += pa * cw
                    wsum += cw
            if a > 0:
                out.append((round(r / a), round(g / a), round(b / a), round(a / wsum)))
            else:
                out.append((0, 0, 0, 0))
    return out


def blend(dst, src):
    sa = src[3] / 255
    return tuple(round(src[i] * sa + dst[i] * (1 - sa)) for i in range(3)) + (max(dst[3], src[3]),)


def build(logomark_path):
    lw, lh, lpx = load_logomark(logomark_path)
    mw = 15
    mh = round(lh * mw / lw)
    mark = box_resize(lw, lh, lpx, mw, mh)

    img = [(0, 0, 0, 0)] * (SIZE * SIZE)
    c = 11.0  # disc centre, leaves room on the right for the beak
    for y in range(SIZE):
        for x in range(SIZE):
            d = math.hypot(x + 0.5 - 12 + 1, y + 0.5 - 12)
            if d <= 11.2:
                if d > 9.2:   # rim: purple to green, top-left to bottom-right
                    t = (x + y) / (2 * SIZE)
                    rim = (round(153 + (20 - 153) * t), round(69 + (241 - 69) * t),
                           round(255 + (149 - 255) * t), 255)
                    cov = min(1.0, 11.2 - d)
                    img[y * SIZE + x] = rim[:3] + (round(255 * cov),)
                else:
                    img[y * SIZE + x] = (14, 12, 26, 255)
    # beak, so it reads as a bird
    for (bx, by) in [(21, 10), (22, 11), (21, 11), (21, 12), (22, 12), (20, 11), (20, 12), (20, 10), (23, 11)]:
        img[by * SIZE + bx] = (255, 168, 38, 255)
    # eye
    for (ex, ey) in [(15, 6), (16, 6), (15, 7), (16, 7)]:
        img[ey * SIZE + ex] = (255, 255, 255, 255)
    img[7 * SIZE + 16] = (14, 12, 26, 255)
    # logomark, centred on the disc
    ox = (SIZE - 2 - mw) // 2 + 1
    oy = (SIZE - mh) // 2 + 3
    for y in range(mh):
        for x in range(mw):
            p = mark[y * mw + x]
            if p[3]:
                i = (oy + y) * SIZE + ox + x
                img[i] = blend(img[i], p)
    return img


def write_png(path, px, w, h):
    raw = b"".join(b"\x00" + b"".join(bytes(px[y * w + x]) for x in range(w)) for y in range(h))

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    open(path, "wb").write(png)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    out = sys.argv[2] if len(sys.argv) > 2 else "solana-flappy/art/coin.png"
    write_png(out, build(sys.argv[1]), SIZE, SIZE)
    print("wrote", out)
