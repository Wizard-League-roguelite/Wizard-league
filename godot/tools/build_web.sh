#!/bin/sh
# Builds the web export into a folder that can be served as-is (GitHub Pages, itch.io, any static host).
# Usage: tools/build_web.sh [output-dir]      (default: build/web)
# Music stays outside the .pck: it is copied to <output-dir>/audio and fetched on demand,
# so the game starts without downloading ~35 MB of mp3 first.
set -e
cd "$(dirname "$0")/.."
OUT="${1:-build/web}"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
GODOT="${GODOT:-godot}"

# build stamp shown in the bottom-left corner: game version, source id of godot/, build date
VER="$(tr -d '[:space:]' < ../VERSION 2>/dev/null || true)"
SRC="$(git rev-parse HEAD:godot 2>/dev/null || echo unknown)"
STAMP="$(date -u +'%Y-%m-%d %H:%M UTC')"
cp game/Version.gd game/Version.gd.orig
trap 'mv -f game/Version.gd.orig game/Version.gd' EXIT
sed -i "s|GAME_VERSION = {.*|GAME_VERSION = {\"version\": \"$VER\", \"hash\": \"$(echo "$SRC" | cut -c1-7)\", \"date\": \"$STAMP\"}|" game/Version.gd

rm -rf "$OUT"
mkdir -p "$OUT/audio"
[ -d .godot/imported ] || "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release Web "$OUT/index.html"
for f in index.html index.js index.wasm index.pck; do
	[ -s "$OUT/$f" ] || { echo "build_web: missing $f" >&2; exit 1; }
done
rm -f "$OUT"/*.import
cp audio/*.mp3 "$OUT/audio/"
echo "$SRC" > "$OUT/.build-source"      # lets CI skip rebuilding when godot/ did not change
du -sh "$OUT" && ls -la "$OUT"
