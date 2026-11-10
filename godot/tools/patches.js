// Textual fixes applied to the JavaScript before conversion.
// Each entry: [find, replace, replaceAll?]
module.exports = {
  'js/data/spells.js': [
    // Getter was lost anyway when spells are copied with {...def}; a plain value behaves identically.
    [`get priority(){
      const dd = typeof player !== 'undefined' ? (player.spellbook||[]).find(s=>s.id==='dynamic_drift') : null;
      return dd ? (dd._battlePriority||0) : 0;
    },
    set priority(_){},`, `priority:0,`],
  ],
  'js/logic/hit.js': [
    [`get state(){ return {
      self: attackerSide==='player' ? status.player : (combat.enemies[combat.activeEnemyIdx]||{}).status,
      target: defenderSide==='player' ? status.player : (combat.enemies[combat.activeEnemyIdx]||{}).status,
    }; },`, ``],
  ],
  'js/ui/library.js': [
    // The preview simulator swapped global functions through window[name]; restore by removing the hooks.
    [`if (_saved[k] !== undefined) window[k] = _saved[k];`, `JS_unhook(k);`],
    [`get state() {
      return { self: { ...STATUS_DEFAULTS }, target: { ...STATUS_DEFAULTS } };
    },`, ``],
  ],
  'js/main.js': [
    // confirm() cannot block in Godot: ask through an in-game dialog instead.
    [`if (!confirm(\`Delete Save \${slot+1}? This cannot be undone.\`)) return;
  deleteSlot(slot);
  localStorage.removeItem('elemental_meta_v1_slot' + slot);
  if (window._metaBySlot) delete window._metaBySlot[slot];
  showSaveSelect();`, `JS_confirmDialog(\`Delete Save \${slot+1}? This cannot be undone.\`, () => {
    deleteSlot(slot);
    localStorage.removeItem('elemental_meta_v1_slot' + slot);
    if (window._metaBySlot) delete window._metaBySlot[slot];
    showSaveSelect();
  });`],
    // BUG FIX: `isDeck` was never defined, so the sandbox deck picker threw a ReferenceError.
    [`(isDeck ? '⚡ Generic Deck' : '⚡ Generic')`, `'⚡ Generic Deck'`],
    [`(cat.element || '') + (isDeck ? ' Deck' : ' Book')`, `(cat.element || '') + ' Deck'`],
  ],
  'js/rendering/sprites.js': [
    // per-pixel sprite loop → cached texture (same pixels, far fewer script calls per frame)
    [`for (let row = 0; row < rows.length; row++) {
        for (let col = 0; col < 24; col++) {
          const c = (rows[row] || '')[col] || '.';
          const color = colorMap[c];
          if (!color) continue;
          ctx.fillStyle = color;
          ctx.fillRect(Math.floor(px + col * P_SCALE), Math.floor(py + row * P_SCALE), P_SCALE, P_SCALE);
        }
      }`, `JS_drawPixelRows(ctx, rows, px, py, P_SCALE, colorMap, 24);`],
  ],
  'js/rendering/lobbyMap.js': [
    [`for (let row = 0; row < rows.length; row++) {
      for (let col = 0; col < 24; col++) {
        const c = (rows[row] || '')[col] || '.';
        const color = colorMap[c];
        if (!color) continue;
        ctx.fillStyle = color;
        ctx.fillRect(Math.floor(sx + col * scale), Math.floor(sy + row * scale), scale, scale);
      }
    }`, `JS_drawPixelRows(ctx, rows, sx, sy, scale, colorMap, 24);`],
    // BUG FIX: clicking a location whose path node is the one the wizard already stands on
    // produced an empty route and a TypeError; walk straight to the destination instead.
    [`const first = route.shift();
  _lobbyTargetX = first.x; _lobbyTargetY = first.y;`, `const first = route.shift() || { x: destX, y: destY, finalDest: hit.id };
  _lobbyTargetX = first.x; _lobbyTargetY = first.y;`],
  ],
  'js/analytics.js': [
    [`location.hostname === 'localhost' || location.hostname === '127.0.0.1'`, `JS_isLocalBuild()`],
    [`fetch(_ANALYTICS_URL, {`, `JS_fetch(_ANALYTICS_URL, {`],
    [`}).catch(() => {}); // ignore network errors`, `});`],
  ],
};
