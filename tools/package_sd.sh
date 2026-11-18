#!/bin/sh
# Lay the app out the way Solana OS reads it from the microSD card:
#   <root>/hh/apps/<id>/main.lua, app.json, files/<everything else>
#
#   tools/package_sd.sh                     -> dist/sdcard/ in this repo (then copy hh/ to the card)
#   tools/package_sd.sh /Volumes/MYCARD     -> straight onto a mounted card
#
# Only creates or overwrites this app's own files; it never deletes anything.
set -eu

here=$(cd "$(dirname "$0")/.." && pwd)
app=solana-flappy
root=${1:-$here/dist/sdcard}
out=$root/hh/apps/$app

[ -d "$root" ] || [ -z "${1:-}" ] || { echo "not a folder: $root" >&2; exit 1; }
mkdir -p "$out"
cp "$here/$app/main.lua" "$here/$app/app.json" "$out/"

(cd "$here/$app" && find . -type f ! -name main.lua ! -name app.json ! -name '.DS_Store' | sort) |
while IFS= read -r f; do
  mkdir -p "$out/files/$(dirname "$f")"
  cp "$here/$app/$f" "$out/files/$f"
done

echo "Wrote $out"
(cd "$out" && find . -type f | sort)
