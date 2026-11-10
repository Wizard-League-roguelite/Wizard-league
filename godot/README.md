# Wizard's League — Godot port

A port of the browser game (repo root) to **Godot 4.4**. Open this `godot/` folder as a project
in the Godot editor and press Play (main scene: `main.tscn`).

The original JavaScript game is untouched and still deploys to GitHub Pages from `main`.

## How the port is built

The browser game is ~30,000 lines of JavaScript that builds its screens from HTML/CSS and draws
with the canvas API. To keep every number, rule and layout identical, the port is made of two parts:

| Folder | What it is |
| --- | --- |
| `game/` | The game itself: one GDScript module per original `.js` file (`Combat.gd`, `Spells.gd`, `UI.gd`, …), produced by the converter in `tools/`. |
| `runtime/` | A small "browser layer" written in GDScript that the game code runs on: an HTML parser, CSS engine, layout (block, inline, flexbox, grid, absolute), painting via `RenderingServer`, a canvas 2D context, SVG icons, audio, timers and `localStorage`. |
| `web/` | The game's page (`index.html`) and stylesheet (`styles.css`), read at start-up. |
| `fonts/`, `audio/` | Bundled fonts (Cinzel; Gelasio standing in for Georgia; DejaVu; Noto Color Emoji) and the music tracks. |
| `tools/` | `js2gd.js` (JavaScript → GDScript converter), `patches.js` (bug fixes applied to the source before conversion), browser reference/screenshot scripts. |
| `dev/` | Test helpers: a scripted UI driver, a random-play tester and a deterministic bot (not needed to play). |

Game logic reads like the original code, for example `Helpers.applyBurn(...)`, `State.player.hp`,
`Spells.SPELL_CATALOGUE`. A few conventions come from JavaScript semantics:

- `obj.get("x")` is used for dictionary reads so a missing field is `null` rather than an error.
- `JS.t(x)` is JavaScript truthiness; `JS.s(x)` formats values the way JavaScript prints them.
- Functions stored in dictionaries (spell `execute`, passive `apply`, …) are called with `JS.callm(obj, "name", [args])`.

## Changing the game

Two workable routes:

1. **Edit the GDScript in `game/` directly.** This is the Godot-native route. Once you do, stop
   re-running the converter for that file (it would overwrite your edits).
2. **Edit the JavaScript and re-convert:** `cd godot/tools && npm install && node js2gd.js`.
   Fixes that should only apply to the port go in `tools/patches.js`.

Screens are styled by `web/styles.css` and the HTML strings in the game modules, exactly as in the
browser version.

## Web build and GitHub Pages

`tools/build_web.sh [output-dir]` exports the game for the web (Godot 4.4.1 with the web
export template installed). The output is a plain static folder:

- No special server headers are needed: thread support is off in the export preset, which is
  what GitHub Pages requires.
- Music is not packed into `index.pck`. The script copies the mp3 files to `audio/` next to
  `index.html` and the game fetches each track when it is first played, so the first load is
  about 13 MB of game data plus the engine instead of an extra 35 MB of music.
- The on-screen keyboard is enabled so the name field works on phones.

`.github/workflows/godot-web.yml` runs that script in CI:

- On pull requests that touch `godot/` it builds and runs `tools/web_smoke.js`, which serves
  the export the way Pages does, boots it in headless Chromium, clicks PLAY and fails on any
  script error, failed request or missing music.
- On `main` it runs after the version bump, rebuilds only when `godot/` changed, and commits
  the result to `play/` at the repository root. Pages then serves it at `<site>/play/`. The
  JavaScript game at the site root is not touched.

To run the smoke test locally: `cd tools && NODE_PATH=$(npm root -g) node web_smoke.js ../build/web`.

## Saves

Saves live in `user://localstorage.json` using the same keys and JSON as the browser's
`localStorage`, so a browser save can be copied across by hand.

## Bugs fixed along the way

- Sandbox deck picker crashed on an undefined `isDeck` variable.
- Clicking a lobby location whose path node the wizard already stands on threw an error (empty route).
- The library's spell preview swapped global functions and could leave them replaced; it now uses explicit hooks that are always removed.
- Save deletion asks through an in-game dialog (the browser `confirm()` cannot block in Godot).

## Testing

`./check.sh` compiles every script. `./run.sh steps.json` runs the game under a virtual display
with a scripted driver (`dev/Driver.gd`) that can click, take screenshots, play randomly
(`{"monkey": seconds}`) or run the deterministic bot (`{"bot": seed}`), whose transcript can be
compared with the same bot in the browser game (`node tools/ref_bot.js`).
