#!/bin/sh
# Builds the Android APK (Godot 4.4.1 with the Android export templates, an Android SDK with
# build-tools, and JDK 17; the SDK and JDK paths come from Godot's editor settings).
# Usage: tools/build_android.sh [output.apk]      (default: build/android/wizard-league.apk)
#
#   ANDROID_BUILD   whole number that goes up with every published build. It becomes the APK's
#                   versionCode (Android refuses an update whose code is not higher) and is what
#                   the in-game updater compares against GitHub. 0 or unset = local build, which
#                   never offers updates.
#   Signing: Godot reads GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD.
set -e
cd "$(dirname "$0")/.."
OUT="${1:-build/android/wizard-league.apk}"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
GODOT="${GODOT:-godot}"
BUILD="${ANDROID_BUILD:-0}"
CODE="$BUILD"; [ "$CODE" -ge 1 ] || CODE=1

# build stamp (bottom-left corner) plus the build number the updater reads
VER="$(tr -d '[:space:]' < ../VERSION 2>/dev/null || echo dev)"
SRC="$(git rev-parse HEAD:godot 2>/dev/null || echo unknown)"
STAMP="$(date -u +'%Y-%m-%d %H:%M UTC')"
cp game/Version.gd game/Version.gd.orig
cp export_presets.cfg export_presets.cfg.orig
trap 'mv -f game/Version.gd.orig game/Version.gd; mv -f export_presets.cfg.orig export_presets.cfg' EXIT
sed -i "s|GAME_VERSION = {.*|GAME_VERSION = {\"version\": \"$VER\", \"hash\": \"$(echo "$SRC" | cut -c1-7)\", \"date\": \"$STAMP\", \"build\": $BUILD}|" game/Version.gd
# only the Android preset has version/ keys
sed -i -e "s|^version/code=.*|version/code=$CODE|" -e "s|^version/name=.*|version/name=\"$VER\"|" export_presets.cfg

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
[ -d .godot/imported ] || "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release Android "$OUT"
[ -s "$OUT" ] || { echo "build_android: no APK produced" >&2; exit 1; }
echo "built $OUT  (version $VER, build $BUILD)"
du -h "$OUT"
