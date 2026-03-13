// ===== lobbyMap.js =====
// ─── LOBBY MAP — between-runs interactive world ───────────────────────────────

const LOBBY_LOCATIONS = [
  { id:'castle',   label:'Begin Run',    icon:'🏰', desc:'Cross the drawbridge — start a new run',  x:0.50, y:0.18 },
  { id:'archive',  label:'History',      icon:'📜', desc:'Review past adventures',                   x:0.14, y:0.55 },
  { id:'vault',    label:'Artifacts',    icon:'🏺', desc:'Artifacts earned from Gym Leaders',        x:0.82, y:0.52 },
  { id:'library',  label:'Spellbooks',   icon:'📖', desc:'Manage your book upgrades',               x:0.28, y:0.78 },
  { id:'talents',  label:'Talent Tree',  icon:'🌟', desc:'Spend Phos on permanent upgrades',        x:0.68, y:0.76 },
  { id:'guild',    label:'Wizard Guild', icon:'🧙', desc:'Unlock and choose your wizard',           x:0.50, y:0.65 },
];

// Player walk state
let _lobbyPlayerX = 0.50;
let _lobbyPlayerY = 0.65;
let _lobbyTargetX = 0.50;
let _lobbyTargetY = 0.65;
let _lobbyWalking = false;
let _lobbyWalkDest = null; // location id to open after arriving
let _lobbyWaypoint = null; // if set, walk here after reaching current target
let _lobbyTick = 0;
let _lobbyAnimFrame = null;
let _lobbyFacingLeft = false;

function showBetweenRuns_map() {
  const canvas = document.getElementById('lobby-map-canvas');
  if (!canvas) return;
  const wrap = canvas.parentElement;
  canvas.width  = Math.round(wrap.clientWidth  || window.innerWidth);
  canvas.height = Math.round(wrap.clientHeight || window.innerHeight);

  // Start player at guild (center)
  _lobbyPlayerX = 0.50; _lobbyPlayerY = 0.65;
  _lobbyTargetX = 0.50; _lobbyTargetY = 0.65;
  _lobbyWalking = false; _lobbyWalkDest = null;

  // Click handler
  canvas.onclick = _lobbyClick;
  canvas.onmousemove = _lobbyHover;
  canvas.style.cursor = 'default';

  if (_lobbyAnimFrame) cancelAnimationFrame(_lobbyAnimFrame);
  _lobbyLoop();
}

function _lobbyLoop() {
  _lobbyTick++;
  _lobbyMovePlayer();
  _lobbyDraw();
  _lobbyAnimFrame = requestAnimationFrame(_lobbyLoop);
}

function _lobbyMovePlayer() {
  if (!_lobbyWalking) return;
  const W = document.getElementById('lobby-map-canvas')?.width || 400;
  const H = document.getElementById('lobby-map-canvas')?.height || 600;
  const px = _lobbyPlayerX * W, py = _lobbyPlayerY * H;
  const tx = _lobbyTargetX * W, ty = _lobbyTargetY * H;
  const dx = tx - px, dy = ty - py;
  const dist = Math.sqrt(dx*dx + dy*dy);
  const speed = 3.1;
  if (dist < speed + 1) {
    _lobbyPlayerX = _lobbyTargetX;
    _lobbyPlayerY = _lobbyTargetY;
    _lobbyWalking = false;
    if (_lobbyWaypoint) {
      // First leg done (arrived at guild) — start second leg to final destination
      const destLoc = LOBBY_LOCATIONS.find(l => l.id === _lobbyWaypoint);
      if (destLoc) {
        _lobbyTargetX = destLoc.x;
        _lobbyTargetY = destLoc.id === 'castle' ? 0.48 : destLoc.y;
        _lobbyWalking = true;
        _lobbyWalkDest = _lobbyWaypoint;
        _lobbyWaypoint = null;
      }
    } else if (_lobbyWalkDest) {
      const dest = _lobbyWalkDest;
      _lobbyWalkDest = null;
      setTimeout(() => _openLobbyLocation(dest), 80);
    }
  } else {
    _lobbyFacingLeft = dx < 0;
    _lobbyPlayerX += (dx / dist) * speed / W;
    _lobbyPlayerY += (dy / dist) * speed / H;
  }
}

function _lobbyDraw() {
  const canvas = document.getElementById('lobby-map-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const W = canvas.width, H = canvas.height;
  _drawLobbyMap(ctx, W, H);
}

function _drawLobbyMap(ctx, W, H) {
  // Sky gradient
  const sky = ctx.createLinearGradient(0, 0, 0, H * 0.5);
  sky.addColorStop(0, '#0a0610');
  sky.addColorStop(1, '#18102a');
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, W, H);

  // Ground
  const gnd = ctx.createLinearGradient(0, H * 0.42, 0, H);
  gnd.addColorStop(0, '#1a120a');
  gnd.addColorStop(1, '#0d0906');
  ctx.fillStyle = gnd;
  ctx.fillRect(0, H * 0.42, W, H);

  // Path/road connecting locations — warm stone color
  ctx.save();
  ctx.strokeStyle = '#2a1e0e';
  ctx.lineWidth = Math.max(4, W * 0.018);
  ctx.lineCap = 'round';
  ctx.setLineDash([]);
  const guild = LOBBY_LOCATIONS.find(l=>l.id==='guild');
  LOBBY_LOCATIONS.forEach(loc => {
    if (loc.id === 'guild') return;
    ctx.beginPath();
    ctx.moveTo(guild.x * W, guild.y * H);
    ctx.lineTo(loc.x * W, loc.y * H);
    ctx.stroke();
  });
  // Castle path extra: guild → castle
  ctx.beginPath();
  ctx.moveTo(guild.x * W, guild.y * H);
  ctx.lineTo(0.50 * W, 0.18 * H);
  ctx.stroke();
  ctx.restore();

  // Stars
  ctx.save();
  for (let i = 0; i < 40; i++) {
    const sx = ((i * 137 + 17) % W);
    const sy = ((i * 97 + 31) % (H * 0.38));
    const alpha = 0.3 + 0.4 * Math.abs(Math.sin(_lobbyTick * 0.02 + i));
    ctx.globalAlpha = alpha;
    ctx.fillStyle = '#fffbe0';
    ctx.fillRect(sx, sy, 1, 1);
  }
  ctx.restore();

  // Moon
  ctx.save();
  ctx.globalAlpha = 0.7;
  ctx.fillStyle = '#e8d8b0';
  ctx.beginPath();
  ctx.arc(W * 0.82, H * 0.10, W * 0.04, 0, Math.PI * 2);
  ctx.fill();
  ctx.globalAlpha = 1;
  ctx.restore();

  // Draw castle
  _drawLobbycastle(ctx, W, H);

  // Draw location markers (skip castle — already drawn)
  LOBBY_LOCATIONS.forEach(loc => {
    if (loc.id === 'castle') return;
    _drawLobbyMarker(ctx, loc, W, H);
  });

  // Draw player
  _drawLobbyPlayer(ctx, W, H);
}

function _drawLobbycastle(ctx, W, H) {
  const cx = W * 0.50;
  const baseY = H * 0.38;
  const castleW = W * 0.28;
  const castleH = H * 0.26;
  const s = Math.min(castleW, castleH);

  ctx.save();

  // Main walls
  ctx.fillStyle = '#1a1220';
  ctx.strokeStyle = '#5a3a8a';
  ctx.lineWidth = 1.5;
  const wallX = cx - s * 0.4;
  const wallY = baseY - castleH;
  const wallW = s * 0.8;
  const wallH = castleH;
  ctx.fillRect(wallX, wallY, wallW, wallH);
  ctx.strokeRect(wallX, wallY, wallW, wallH);

  // Battlements
  const merlonW = s * 0.08;
  const merlonH = s * 0.07;
  const merlonCount = 6;
  for (let i = 0; i < merlonCount; i++) {
    const mx = wallX + i * (wallW / merlonCount);
    ctx.fillStyle = '#22183a';
    ctx.strokeStyle = '#5a3a8a';
    ctx.fillRect(mx, wallY - merlonH, merlonW, merlonH);
    ctx.strokeRect(mx, wallY - merlonH, merlonW, merlonH);
  }

  // Side towers
  const towerW = s * 0.18;
  const towerH = castleH * 1.15;
  [-1, 1].forEach(side => {
    const tx = cx + side * (s * 0.4 + towerW * 0.5) - towerW * 0.5;
    const ty = baseY - towerH;
    ctx.fillStyle = '#150e20';
    ctx.fillRect(tx, ty, towerW, towerH);
    ctx.strokeStyle = '#7a4aaa';
    ctx.strokeRect(tx, ty, towerW, towerH);

    // Tower battlements
    for (let i = 0; i < 3; i++) {
      const mx = tx + i * (towerW / 3);
      ctx.fillStyle = '#1e1430';
      ctx.fillRect(mx, ty - merlonH, towerW / 3 - 1, merlonH);
      ctx.strokeRect(mx, ty - merlonH, towerW / 3 - 1, merlonH);
    }

    // Tower window
    ctx.fillStyle = '#ffdd8844';
    ctx.fillRect(tx + towerW * 0.3, ty + towerH * 0.25, towerW * 0.4, towerH * 0.2);
  });

  // Gate arch
  const gateW = s * 0.2;
  const gateH = s * 0.22;
  const gateX = cx - gateW / 2;
  const gateY = baseY - gateH;
  ctx.fillStyle = '#08060e';
  ctx.beginPath();
  ctx.moveTo(gateX, baseY);
  ctx.lineTo(gateX, gateY + gateW / 2);
  ctx.arc(gateX + gateW / 2, gateY + gateW / 2, gateW / 2, Math.PI, 0);
  ctx.lineTo(gateX + gateW, baseY);
  ctx.fill();
  ctx.strokeStyle = '#7a4aaa';
  ctx.stroke();

  // Drawbridge
  const dbW = gateW * 1.0;
  const dbH = gateH * 0.5;
  const dbX = cx - dbW / 2;
  const dbY = baseY;
  ctx.fillStyle = '#4a3010';
  ctx.fillRect(dbX, dbY, dbW, dbH);
  // Planks
  ctx.strokeStyle = '#2a1808';
  ctx.lineWidth = 1;
  for (let i = 1; i < 4; i++) {
    ctx.beginPath();
    ctx.moveTo(dbX, dbY + dbH * (i / 4));
    ctx.lineTo(dbX + dbW, dbY + dbH * (i / 4));
    ctx.stroke();
  }
  // Chains
  ctx.strokeStyle = '#8a7040';
  ctx.lineWidth = 1.5;
  [[dbX, dbY], [dbX + dbW, dbY]].forEach(([chainX, chainY]) => {
    ctx.beginPath();
    ctx.moveTo(chainX, chainY);
    ctx.lineTo(cx + (chainX < cx ? -gateW * 0.3 : gateW * 0.3), gateY);
    ctx.stroke();
  });

  // Purple glow from gate
  const glow = ctx.createRadialGradient(cx, baseY, 0, cx, baseY, s * 0.25);
  glow.addColorStop(0, '#9a4aff33');
  glow.addColorStop(1, 'transparent');
  ctx.fillStyle = glow;
  ctx.fillRect(cx - s * 0.3, baseY - s * 0.2, s * 0.6, s * 0.4);

  // Castle label
  ctx.font = `bold ${Math.round(W * 0.025)}px 'Cinzel', serif`;
  ctx.textAlign = 'center';
  ctx.fillStyle = '#c8a060';
  ctx.globalAlpha = 0.9;
  ctx.fillText('⚔ Begin Run', cx, baseY + dbH + W * 0.025 + 4);
  ctx.globalAlpha = 1;

  ctx.restore();
}

function _drawLobbyMarker(ctx, loc, W, H) {
  const x = loc.x * W;
  const y = loc.y * H;
  const r = Math.max(18, W * 0.038);
  const hovered = _lobbyHoveredId === loc.id;

  ctx.save();
  // Glow
  if (hovered) {
    const grd = ctx.createRadialGradient(x, y, 0, x, y, r * 1.8);
    grd.addColorStop(0, '#c8a06044');
    grd.addColorStop(1, 'transparent');
    ctx.fillStyle = grd;
    ctx.beginPath();
    ctx.arc(x, y, r * 1.8, 0, Math.PI * 2);
    ctx.fill();
  }

  // Circle
  ctx.fillStyle = hovered ? '#241c0a' : '#160e06';
  ctx.strokeStyle = hovered ? '#c8a060' : '#4a3010';
  ctx.lineWidth = hovered ? 2 : 1;
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();

  // Icon
  ctx.font = `${Math.round(r * 0.9)}px serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(loc.icon, x, y);

  // Label
  ctx.font = `${Math.round(W * 0.018)}px 'Cinzel', serif`;
  ctx.textBaseline = 'alphabetic';
  ctx.fillStyle = hovered ? '#c8a060' : '#6a5030';
  ctx.fillText(loc.label, x, y + r + W * 0.02);

  ctx.restore();
}

function _drawLobbyPlayer(ctx, W, H) {
  const x = Math.round(_lobbyPlayerX * W);
  const y = Math.round(_lobbyPlayerY * H);
  const scale = Math.max(2, Math.min(4, Math.floor(W / 200)));

  // Bob when walking
  const bobY = _lobbyWalking ? Math.round(Math.sin(_lobbyTick * 0.25) * 2) : 0;

  // Get player sprite rows
  const rows = (typeof getPlayerSprite === 'function') ? getPlayerSprite() : SPRITE_CHAR_MAGE;
  const sprW = 24 * scale;
  const sprH = rows.length * scale;
  const sx = x - sprW / 2;
  const sy = y - sprH + bobY;

  // Horizontal flip for facing left
  ctx.save();
  if (_lobbyFacingLeft) {
    ctx.translate(x * 2, 0);
    ctx.scale(-1, 1);
  }

  // Build palette from wizard build
  const pal = _lobbyGetPlayerPal();
  drawSprite(ctx, rows, sx, sy, scale, pal, 24);

  // Name label
  ctx.restore();
  ctx.save();
  ctx.font = `bold ${Math.round(W * 0.018)}px 'Cinzel', serif`;
  ctx.textAlign = 'center';
  ctx.fillStyle = '#c8a060';
  ctx.globalAlpha = 0.85;
  ctx.fillText(playerName || 'Wizard', x, sy - 4);
  ctx.restore();
}

function _lobbyGetPlayerPal() {
  const b = (typeof _wizBuild !== 'undefined') ? _wizBuild : null;
  if (!b) return ['#aa6622','#cc8833','#eebb55','#ffdd88'];
  const outfit = (typeof WIZ_OUTFIT_COLORS !== 'undefined' ? WIZ_OUTFIT_COLORS : []).find(o => o.id === b.outfit);
  if (outfit) return [outfit.p0, outfit.p1, outfit.p2, outfit.p3];
  return ['#aa6622','#cc8833','#eebb55','#ffdd88'];
}

let _lobbyHoveredId = null;

function _lobbyHover(e) {
  const canvas = document.getElementById('lobby-map-canvas');
  if (!canvas) return;
  const r = canvas.getBoundingClientRect();
  const mx = (e.clientX - r.left) * (canvas.width / r.width);
  const my = (e.clientY - r.top)  * (canvas.height / r.height);
  const W = canvas.width, H = canvas.height;
  let hit = null;
  LOBBY_LOCATIONS.forEach(loc => {
    const lx = loc.x * W, ly = loc.y * H;
    const dist = Math.sqrt((mx - lx) ** 2 + (my - ly) ** 2);
    const radius = loc.id === 'castle' ? W * 0.14 : Math.max(22, W * 0.05);
    if (dist < radius) hit = loc.id;
  });
  _lobbyHoveredId = hit;
  canvas.style.cursor = hit ? 'pointer' : 'default';
}

function _lobbyClick(e) {
  const canvas = document.getElementById('lobby-map-canvas');
  if (!canvas) return;
  const r = canvas.getBoundingClientRect();
  const mx = (e.clientX - r.left) * (canvas.width / r.width);
  const my = (e.clientY - r.top)  * (canvas.height / r.height);
  const W = canvas.width, H = canvas.height;

  let hit = null;
  LOBBY_LOCATIONS.forEach(loc => {
    const lx = loc.x * W, ly = loc.y * H;
    const dist = Math.sqrt((mx - lx) ** 2 + (my - ly) ** 2);
    const radius = loc.id === 'castle' ? W * 0.14 : Math.max(22, W * 0.05);
    if (dist < radius) hit = loc;
  });
  if (!hit) return;

  // Walk to guild center first (to follow the paths), then to destination
  const guild = LOBBY_LOCATIONS.find(l => l.id === 'guild');
  const guildX = guild ? guild.x : 0.50;
  const guildY = guild ? guild.y : 0.65;
  const distToGuild = Math.sqrt((_lobbyPlayerX - guildX) ** 2 + (_lobbyPlayerY - guildY) ** 2);
  const destY = hit.id === 'castle' ? 0.48 : hit.y;

  if (hit.id !== 'guild' && distToGuild > 0.08) {
    // Route through guild center first
    _lobbyTargetX = guildX;
    _lobbyTargetY = guildY;
    _lobbyWalking = true;
    _lobbyWalkDest = 'guild';
    _lobbyWaypoint = hit.id;
  } else {
    // Already near guild (or clicking guild itself) — go direct
    _lobbyTargetX = hit.x;
    _lobbyTargetY = destY;
    _lobbyWalking = true;
    _lobbyWalkDest = hit.id;
    _lobbyWaypoint = null;
  }
}

function _openLobbyLocation(id) {
  if (id === 'castle') { lobbyStartRun(); return; }
  const panel = document.getElementById('lobby-panel');
  const content = document.getElementById('lobby-panel-content');
  if (!panel || !content) return;

  const meta = getMeta();
  const loc = LOBBY_LOCATIONS.find(l => l.id === id);
  const title = loc ? `${loc.icon} ${loc.label}` : '';
  const phosLabel = `<div class="lobby-phos-bar">✦ ${meta.phos || 0} Phos available</div>`;

  if (id === 'archive') {
    const history = meta.runHistory || [];
    let html = `<div class="lobby-panel-title">${title}</div>`;
    if (!history.length) {
      html += '<div class="brun-empty">No runs recorded yet.</div>';
    } else {
      html += history.map(r => `
        <div class="brun-hist-row">
          <div class="brun-hist-el">${r.emoji||'⚔'} ${r.element||'?'} <span style="color:#4a6a8a;font-size:.6rem;margin-left:.3rem;">${r.zone && r.zone !== r.element ? '→ '+r.zone+' Zone' : ''}</span></div>
          <div class="brun-hist-stats">
            <span>Lv.${r.level||'?'}</span><span>${r.battles||0} battles</span>
            <span style="color:#c8a830">${r.gold||0}g</span>
            <span style="color:#a080ff">${r.phos||0}✦</span>
          </div>
          <div style="display:flex;gap:.8rem;font-size:.6rem;color:#555;margin-top:.2rem;">
            <span>⚔ ${r.dmgDealt||0} dealt</span><span>🛡 ${r.dmgTaken||0} taken</span>
          </div>
          <div class="brun-hist-date">${r.date||''}</div>
        </div>`).join('');
    }
    content.innerHTML = html;
    panel.style.display = 'block';
  } else if (id === 'vault') {
    let html = `<div class="lobby-panel-title">${title}</div>`;
    if (!meta.artifacts || !meta.artifacts.length) {
      html += '<div class="brun-empty">No artifacts yet — defeat a Gym Leader!</div>';
    } else {
      html += meta.artifacts.map(a => {
        const def = ARTIFACT_CATALOGUE[a.id];
        if (!def) return '';
        const stars = a.star > 0 ? '★'.repeat(a.star) : '—';
        const sColor = ['#888','#c8a030','#e8d060','#00ccff'][Math.min(a.star||0,3)];
        const prog = a.star < 3 ? `${a.roomsUsed||0}/25 rooms` : 'MAX';
        return `<div class="brun-art-row">
          <div class="brun-art-name">${def.emoji} ${def.name} <span class="brun-art-star" style="color:${sColor}">${stars}</span></div>
          <div class="brun-art-desc">${def.desc[a.star||0]} · <span style="color:#4a4a4a">${prog}</span></div>
        </div>`;
      }).join('');
    }
    content.innerHTML = html;
    panel.style.display = 'block';
  } else if (id === 'library') {
    content.innerHTML = `<div class="lobby-panel-title">${title}</div>`;
    renderBookUpgradesTab(content, meta);
    panel.style.display = 'block';
  } else if (id === 'talents') {
    content.innerHTML = `<div class="lobby-panel-title">${title}</div>${phosLabel}`;
    renderTalentTab(content, meta);
    panel.style.display = 'block';
  } else if (id === 'guild') {
    content.innerHTML = `<div class="lobby-panel-title">${title}</div>`;
    _renderWizardUnlockTab(content, meta);
    panel.style.display = 'block';
  }
}

function closeLobbyPanel() {
  const panel = document.getElementById('lobby-panel');
  if (panel) panel.style.display = 'none';
  // Resume map loop
  if (!_lobbyAnimFrame) _lobbyLoop();
}

function stopLobbyMap() {
  if (_lobbyAnimFrame) { cancelAnimationFrame(_lobbyAnimFrame); _lobbyAnimFrame = null; }
  const canvas = document.getElementById('lobby-map-canvas');
  if (canvas) { canvas.onclick = null; canvas.onmousemove = null; }
}
