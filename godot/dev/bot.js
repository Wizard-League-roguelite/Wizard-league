// dev/bot.js — deterministic autoplayer. The same file runs in the browser game and (converted)
// in the Godot port, so a seeded run can be compared line by line between the two.
var _botLog = [];
var _botDone = false;
var _botBattles = 0;
var _botMax = 3;
var _botIdx = 0;
var _botSig = '';
var _botTried = 0;
var _botLastScreen = '';
var _botStarted = false;
var _botSteps = 0;
const _BOT_AVOID = ['Quit', 'Abandon', 'Files', 'Back', 'Library', 'Log', 'Stats', 'Decks', 'Reroll', 'Sandbox', 'Rarity', 'Skip', 'Map'];

function _botVisible(el) { return !!el && el.offsetWidth > 0 && !el.disabled; }
function _botRecord(s) { _botLog.push(s + '  @rng' + JS_rngCount()); }

function botStart(seed, maxBattles) {
  JS_seedRandom(seed);
  _botMax = maxBattles || 3;
  _botLog = []; _botDone = false; _botBattles = 0; _botStarted = false; _botLastScreen = ''; _botSteps = 0;
  setTimeout(_botStep, 437);
}

function _botStep() {
  if (_botDone) return;
  _botSteps++;
  if (_botSteps > 6000) { _botRecord('TIMEOUT'); _botDone = true; return; }
  _botAct();
  if (!_botDone) setTimeout(_botStep, 437);
}

function _botAvoided(el) {
  const t = el.textContent || '';
  if (t.length > 60) return false;
  return _BOT_AVOID.some(a => t.includes(a));
}

function _botAct() {
  const scr = document.querySelector('.screen.active');
  const id = scr ? scr.id : 'none';
  if (id !== _botLastScreen) {
    if (_botLastScreen === 'combat-screen') {
      _botBattles++;
      const lines = [...document.querySelectorAll('#battle-log .log-line')].map(l => l.textContent);
      _botRecord('LOG ' + lines.join(' | '));
      _botRecord('STATE hp=' + player.hp + ' gold=' + player.gold + ' battle=' + battleNumber + ' spells=' + player.spellbook.map(s => s.id).join(','));
      if (_botBattles >= _botMax) { _botDone = true; return; }
    }
    _botRecord('SCREEN ' + id);
    _botLastScreen = id; _botIdx = 0; _botSig = ''; _botTried = 0;
  }
  const cut = document.getElementById('cutscene-screen');
  if (cut && cut.offsetWidth > 0) { cut.click(); return; }
  if (id === 'between-runs-screen') {
    if (_botStarted) { _botRecord('RUN OVER'); _botDone = true; return; }
    _botStarted = true;
    showElementScreen();
    return;
  }
  let scope = scr;
  const ovs = ['passive-overflow-overlay', 'book-overflow-overlay', 'book-dest-overlay', 'confirm-modal', 'passive-modal'];
  for (const o of ovs) { const ov = document.getElementById(o); if (ov && ov.classList.contains('open')) scope = ov; }
  if (!scope) return;

  if (id === 'combat-screen' && scope === scr) {
    if (combat.over || !combat.playerTurn) return;
    const cards = [...document.querySelectorAll('#card-hand .spell-card')].filter(_botVisible);
    if ((combat.actionsLeft || 0) > 0 && _botTried < cards.length) {
      const before = combat.actionQueue.length;
      cards[_botTried].click();
      if (combat.actionQueue.length > before) { _botRecord('PLAY ' + _botTried); _botTried = 0; }
      else _botTried++;
      return;
    }
    _botTried = 0;
    const _ll = [...document.querySelectorAll('#battle-log .log-line')].map(l => l.textContent);
    _botRecord('TURNLOG ' + _ll.slice(Math.max(0, _ll.length - 25)).join(' | '));
    const _e0 = combat.enemies[0];
    _botRecord('DBG zone=' + combat.activeZoneElement + ' el=' + _e0.element + ' pow=' + _e0.statPow + ' efx=' + _e0.statEfx + ' def=' + _e0.statDef + ' eshock=' + (_e0.status.shockStacks || 0) + ' pshock=' + (status.player.shockStacks || 0) + ' ap=' + attackPowerFor('enemy', 'player') + ' pdef=' + defenseFor('player') + ' pefx=' + effectPowerFor('player') + ' passive=' + _e0.passive + ' block=' + (status.player.block || 0));
    _botRecord('END hp=' + player.hp + ' enemy=' + combat.enemies.map(e => e.hp).join('/'));
    commitEndTurn();
    return;
  }

  const cands = [...scope.querySelectorAll('*')].filter(el => (!!el.onclick || el.tagName === 'BUTTON') && _botVisible(el) && !_botAvoided(el));
  if (!cands.length) return;
  // walk through the clickable elements in turn until the screen changes
  const el = cands[_botIdx % cands.length];
  _botRecord('CLICK ' + id + ' #' + (_botIdx % cands.length) + '/' + cands.length + ' ' + (el.className || el.id || ''));
  _botIdx++;
  el.click();
}
