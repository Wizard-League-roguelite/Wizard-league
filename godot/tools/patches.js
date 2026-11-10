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
    [`get state() {
      return { self: { ...STATUS_DEFAULTS }, target: { ...STATUS_DEFAULTS } };
    },`, ``],
  ],
  'js/main.js': [
    // BUG FIX: `isDeck` was never defined, so the sandbox deck picker threw a ReferenceError.
    [`(isDeck ? '⚡ Generic Deck' : '⚡ Generic')`, `'⚡ Generic Deck'`],
    [`(cat.element || '') + (isDeck ? ' Deck' : ' Book')`, `(cat.element || '') + ' Deck'`],
  ],
  'js/rendering/lobbyMap.js': [
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
