// ===== animations.js =====
// ─── ANIMATIONS — Spell / battle visual effects ───────────────────────────────
// Non-blocking. Game state updates instantly; animations are purely cosmetic.
// tickAnims(ctx, W, H) is called from renderBattlefield() each rAF frame.

const ACTIVE_ANIMS = [];

// ─── Particle factory ─────────────────────────────────────────────────────────
function _makeParticles(count, spread) {
  const ps = [];
  for (let i = 0; i < count; i++) {
    ps.push({
      offset: (i / count) * -0.18,
      yOff:   ((i * 137 + 31) % (spread * 2 + 1)) - spread,
      size:   2 + (i % 3),
      alpha:  0.55 + (i % 4) * 0.12,
    });
  }
  return ps;
}

// ─── Per-element / per-type animation definitions ─────────────────────────────
// type: 'arc' | 'bolt' | 'ring' | 'rise' | 'shield'
const ANIM_DEFS = {
  Fire:      { type:'arc',    dur:22, count:9,  spread:14, c1:'#FF6622', c2:'#FF2200', burst:'#FFAA44' },
  Water:     { type:'arc',    dur:22, count:7,  spread:8,  c1:'#44AAFF', c2:'#0055CC', burst:'#88DDFF' },
  Ice:       { type:'arc',    dur:20, count:7,  spread:6,  c1:'#CCEFFF', c2:'#33AACC', burst:'#FFFFFF' },
  Lightning: { type:'bolt',   dur:14, count:5,  spread:0,  c1:'#FFEE22', c2:'#FFAA00', burst:'#FFFFFF' },
  Earth:     { type:'arc',    dur:26, count:6,  spread:16, c1:'#CC9933', c2:'#886622', burst:'#EEDD88' },
  Nature:    { type:'arc',    dur:22, count:8,  spread:18, c1:'#44EE55', c2:'#118833', burst:'#AAFFAA' },
  Plasma:    { type:'ring',   dur:20, count:7,  spread:8,  c1:'#EE44FF', c2:'#8800BB', burst:'#FF88FF' },
  Air:       { type:'arc',    dur:18, count:7,  spread:20, c1:'#AAEEFF', c2:'#3399BB', burst:'#EEFFFF' },
  Neutral:   { type:'arc',    dur:18, count:5,  spread:8,  c1:'#CCCCCC', c2:'#888888', burst:'#FFFFFF' },
  heal:      { type:'rise',   dur:28, count:7,  spread:12, c1:'#44DD66', c2:'#118833', burst:'#AAFFAA' },
  block:     { type:'shield', dur:22, count:0,  spread:0,  c1:'#DDAA22', c2:'#AA7700', burst:'#FFEE88' },
  armor:     { type:'shield', dur:18, count:0,  spread:0,  c1:'#888888', c2:'#555555', burst:'#CCCCCC' },
};

// ─── Public API ───────────────────────────────────────────────────────────────
function triggerSpellAnim(abilityElement, attackerSide, targetEnemyIdx) {
  const def = ANIM_DEFS[abilityElement] || ANIM_DEFS.Neutral;
  ACTIVE_ANIMS.push({
    ...def,
    particles: (def.type === 'arc' || def.type === 'ring')
      ? _makeParticles(def.count, def.spread) : [],
    attackerSide,
    targetEnemyIdx: targetEnemyIdx != null ? targetEnemyIdx : (combat.activeEnemyIdx || 0),
    t: 0,
  });
}

function triggerHealAnim() {
  const def = ANIM_DEFS.heal;
  ACTIVE_ANIMS.push({
    ...def,
    particles: _makeParticles(def.count, def.spread),
    attackerSide: 'player', targetEnemyIdx: -1, t: 0,
  });
}

function triggerBlockAnim(variant) {
  // variant: 'block' | 'armor'
  const def = ANIM_DEFS[variant] || ANIM_DEFS.block;
  ACTIVE_ANIMS.push({
    ...def,
    particles: [], attackerSide: 'player', targetEnemyIdx: -1, t: 0,
  });
}

// ─── Position helpers ─────────────────────────────────────────────────────────
function _spriteCenter(side, enemyIdx, W, H) {
  if (side === 'player') {
    if (typeof playerSpritePos === 'function') {
      const p = playerSpritePos(W, H);
      return { x: p.x + p.w / 2, y: p.y + p.h / 2 };
    }
    return { x: W * 0.15, y: H * 0.7 };
  }
  if (typeof enemySpritePos === 'function') {
    const allE = (typeof combat !== 'undefined') ? (combat.enemies || []) : [];
    const ep = enemySpritePos(enemyIdx, allE, W, H);
    return { x: ep.x + ep.w / 2, y: ep.y + ep.h / 2 };
  }
  return { x: W * 0.72, y: H * 0.38 };
}

// ─── Drawers ──────────────────────────────────────────────────────────────────
function _drawArc(ctx, a, W, H) {
  const from = _spriteCenter(a.attackerSide, a.targetEnemyIdx, W, H);
  const toSide = a.attackerSide === 'player' ? 'enemy' : 'player';
  const to = _spriteCenter(toSide, a.targetEnemyIdx, W, H);
  const prog = a.t / a.dur;

  a.particles.forEach(p => {
    const pt = Math.min(1, Math.max(0, prog + p.offset));
    if (pt <= 0 || pt >= 1) return;
    const x  = from.x + (to.x - from.x) * pt;
    const dy = from.y + (to.y - from.y) * pt;
    const arc = -(Math.abs(to.x - from.x) * 0.22 + 8);
    const y  = dy + arc * Math.sin(pt * Math.PI) + p.yOff * (1 - pt);
    ctx.save();
    ctx.globalAlpha = Math.sin(pt * Math.PI) * p.alpha;
    ctx.fillStyle = pt < 0.55 ? a.c1 : a.c2;
    const sz = Math.max(1, Math.round(p.size * (1 - pt * 0.4)));
    ctx.fillRect(Math.round(x) - (sz >> 1), Math.round(y) - (sz >> 1), sz, sz);
    ctx.restore();
  });

  // Impact burst
  if (prog > 0.72) {
    const bp = (prog - 0.72) / 0.28;
    ctx.save();
    ctx.globalAlpha = (1 - bp) * 0.65;
    ctx.fillStyle = a.burst;
    const r = bp * 14;
    ctx.beginPath();
    ctx.arc(to.x, to.y, r, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
}

function _drawBolt(ctx, a, W, H) {
  const from = _spriteCenter(a.attackerSide, a.targetEnemyIdx, W, H);
  const toSide = a.attackerSide === 'player' ? 'enemy' : 'player';
  const to = _spriteCenter(toSide, a.targetEnemyIdx, W, H);
  const prog = a.t / a.dur;
  const alpha = 1 - Math.pow(prog, 1.4);

  // Main bolt — zigzag
  const segs = 6;
  const drawLine = (strokeColor, lw, alpha2) => {
    ctx.save();
    ctx.globalAlpha = alpha * alpha2;
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = lw;
    ctx.beginPath();
    ctx.moveTo(from.x, from.y);
    for (let i = 1; i <= segs; i++) {
      const t = i / segs;
      const x = from.x + (to.x - from.x) * t;
      const y = from.y + (to.y - from.y) * t;
      const jitter = i < segs ? (((i * 173 + 7) % 18) - 9) : 0;
      ctx.lineTo(Math.round(x + jitter), Math.round(y - jitter * 0.6));
    }
    ctx.stroke();
    ctx.restore();
  };
  drawLine(a.c1, 2, 1);
  drawLine('#FFFFFF', 1, 0.5);

  // Impact flash
  if (prog > 0.5) {
    const fp = (prog - 0.5) / 0.5;
    ctx.save();
    ctx.globalAlpha = (1 - fp) * 0.7;
    ctx.fillStyle = a.burst;
    ctx.beginPath();
    ctx.arc(to.x, to.y, fp * 10, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
}

function _drawRing(ctx, a, W, H) {
  const from = _spriteCenter(a.attackerSide, a.targetEnemyIdx, W, H);
  const toSide = a.attackerSide === 'player' ? 'enemy' : 'player';
  const to = _spriteCenter(toSide, a.targetEnemyIdx, W, H);
  const prog = a.t / a.dur;

  // Orbiting particles travel the path
  a.particles.forEach(p => {
    const pt = Math.min(1, Math.max(0, prog + p.offset));
    if (pt <= 0 || pt >= 1) return;
    const x = from.x + (to.x - from.x) * pt;
    const arc = -(Math.abs(to.x - from.x) * 0.2 + 6);
    const y = from.y + (to.y - from.y) * pt + arc * Math.sin(pt * Math.PI) + p.yOff * 0.5;
    ctx.save();
    ctx.globalAlpha = Math.sin(pt * Math.PI) * p.alpha;
    ctx.fillStyle = a.c1;
    ctx.beginPath();
    ctx.arc(x, y, p.size * 0.8, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  });

  // Expanding ring at impact
  if (prog > 0.58) {
    const rp = (prog - 0.58) / 0.42;
    ctx.save();
    ctx.globalAlpha = (1 - rp) * 0.85;
    ctx.strokeStyle = a.burst;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(to.x, to.y, rp * 20, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
  }
}

function _drawRise(ctx, a, W, H) {
  const center = _spriteCenter('player', 0, W, H);
  const prog = a.t / a.dur;

  a.particles.forEach((p, i) => {
    const delay = (i / a.particles.length) * 0.28;
    const pt = Math.max(0, (prog - delay) / (1 - delay));
    if (pt <= 0 || pt >= 1) return;
    const x = center.x + p.yOff;
    const y = center.y - pt * 32 - 4;
    ctx.save();
    ctx.globalAlpha = Math.sin(pt * Math.PI) * p.alpha;
    ctx.fillStyle = pt < 0.5 ? a.c1 : a.c2;
    ctx.fillRect(Math.round(x), Math.round(y), p.size, p.size);
    ctx.restore();
  });
}

function _drawShield(ctx, a, W, H) {
  const p = typeof playerSpritePos === 'function'
    ? playerSpritePos(W, H)
    : { x: W * 0.06, y: H * 0.5, w: 48, h: 64 };
  const prog = a.t / a.dur;
  const grow = Math.min(1, prog * 3);
  const fade = prog < 0.35 ? prog / 0.35 : 1 - (prog - 0.35) / 0.65;
  const pad  = 5 * grow;

  ctx.save();
  ctx.globalAlpha = fade * 0.55;
  ctx.fillStyle = a.burst;
  ctx.fillRect(p.x - pad, p.y - pad, p.w + pad * 2, p.h + pad * 2);
  ctx.globalAlpha = fade * 0.9;
  ctx.strokeStyle = a.c1;
  ctx.lineWidth = Math.round(2 * grow) + 1;
  ctx.strokeRect(p.x - pad, p.y - pad, p.w + pad * 2, p.h + pad * 2);
  ctx.restore();
}

// ─── Main tick — called every rAF frame from renderBattlefield ────────────────
function tickAnims(ctx, W, H) {
  for (let i = ACTIVE_ANIMS.length - 1; i >= 0; i--) {
    const a = ACTIVE_ANIMS[i];
    switch (a.type) {
      case 'arc':    _drawArc(ctx, a, W, H);    break;
      case 'bolt':   _drawBolt(ctx, a, W, H);   break;
      case 'ring':   _drawRing(ctx, a, W, H);   break;
      case 'rise':   _drawRise(ctx, a, W, H);   break;
      case 'shield': _drawShield(ctx, a, W, H); break;
    }
    a.t++;
    if (a.t >= a.dur) ACTIVE_ANIMS.splice(i, 1);
  }
}

// ═══ CAMPFIRE SCENE ════════════════════════════════════════════════════════════
// Full animated rest scene: player sitting by crackling campfire, night sky.

let _cfRAF = null;
let _cfTick = 0;
let _cfHealText = '';

// ── Zone-themed campfire environments ─────────────────────────────────────────
function _cfStars(ctx, W, H, groundY, t) {
  for(let i=0;i<55;i++){
    const sx=(i*137+17)%W, sy=(i*97+31)%Math.floor(groundY*0.85);
    const blink=Math.sin(t*0.025+i*0.7)>0.55;
    ctx.globalAlpha=blink?0.7:0.2; ctx.fillStyle='#ffffff';
    ctx.fillRect(sx,sy,1,1);
  }
  ctx.globalAlpha=1;
}
function _cfMoon(ctx, W, H, t, col, x, y) {
  ctx.save(); ctx.globalAlpha=0.55; ctx.fillStyle=col||'#e8e0c0';
  ctx.beginPath(); ctx.arc(Math.round(W*(x||0.82)),Math.round(H*(y||0.13)),9,0,Math.PI*2); ctx.fill();
  ctx.globalAlpha=1; ctx.fillStyle='#02020a';
  ctx.beginPath(); ctx.arc(Math.round(W*(x||0.82))+5,Math.round(H*(y||0.13))-2,8,0,Math.PI*2); ctx.fill();
  ctx.restore();
}

function _cfDrawEnvironment(ctx, W, H, groundY, t, zone) {
  switch(zone) {
    case 'Fire':      _cfEnvFire(ctx,W,H,groundY,t);      break;
    case 'Water':     _cfEnvWater(ctx,W,H,groundY,t);     break;
    case 'Ice':       _cfEnvIce(ctx,W,H,groundY,t);       break;
    case 'Lightning': _cfEnvLightning(ctx,W,H,groundY,t); break;
    case 'Earth':     _cfEnvEarth(ctx,W,H,groundY,t);     break;
    case 'Nature':    _cfEnvNature(ctx,W,H,groundY,t);    break;
    case 'Plasma':    _cfEnvPlasma(ctx,W,H,groundY,t);    break;
    case 'Air':       _cfEnvAir(ctx,W,H,groundY,t);       break;
    default:          _cfEnvFire(ctx,W,H,groundY,t);      break;
  }
}

// FIRE: dark ember sky, glowing horizon, cracked lava ground
function _cfEnvFire(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#0a0200'); sky.addColorStop(0.6,'#1a0600'); sky.addColorStop(1,'#2a0c00');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  // Ember horizon glow
  ctx.save(); ctx.globalAlpha=0.18+0.06*Math.sin(t*0.04);
  const hg=ctx.createLinearGradient(0,gY-20,0,gY);
  hg.addColorStop(0,'transparent'); hg.addColorStop(1,'#FF4400');
  ctx.fillStyle=hg; ctx.fillRect(0,gY-20,W,20); ctx.restore();
  // Stars (sparse, reddish)
  for(let i=0;i<30;i++){const sx=(i*137+17)%W,sy=(i*97+31)%Math.floor(gY*0.7);ctx.globalAlpha=0.25;ctx.fillStyle='#ff9944';ctx.fillRect(sx,sy,1,1);}
  ctx.globalAlpha=1;
  // Ground — cracked dark lava
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#2a1000'); gg.addColorStop(1,'#0a0400');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#3a1400'; ctx.fillRect(0,gY,W,2);
  // Lava crack lines
  ctx.save(); ctx.globalAlpha=0.5+0.2*Math.sin(t*0.06);
  ctx.fillStyle='#FF4400';
  for(let i=0;i<5;i++){const cx=(i*W/4+W*0.1)%W;ctx.fillRect(Math.round(cx),gY+2,1,H-gY-2);}
  ctx.restore();
  // Small fire hazard spots on ground
  for(let i=0;i<3;i++){
    const gfx=Math.round((i*0.28+0.12)*W);
    ctx.save();ctx.globalAlpha=(0.3+0.15*Math.sin(t*0.08+i))*0.7;
    ctx.fillStyle='#FF8800';ctx.fillRect(gfx-3,gY+4,6,3);ctx.restore();
  }
}

// WATER: deep ocean night, moonlit water reflection, sandy shore
function _cfEnvWater(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#01050f'); sky.addColorStop(0.6,'#050e1a'); sky.addColorStop(1,'#0a1828');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  _cfStars(ctx,W,H,gY,t);
  _cfMoon(ctx,W,H,t,'#c0d8f0',0.80,0.12);
  // Ground — wet sand / shore
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#1a2a1a'); gg.addColorStop(0.4,'#0e1a10'); gg.addColorStop(1,'#060e0a');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#1e3020'; ctx.fillRect(0,gY,W,2);
  // Water shimmer at horizon
  ctx.save();
  for(let i=0;i<6;i++){
    const wx=Math.round((i*W/5+Math.sin(t*0.03+i)*8)%W);
    ctx.globalAlpha=0.12+0.08*Math.sin(t*0.05+i*1.3);
    ctx.fillStyle='#4488cc'; ctx.fillRect(wx,gY-2,Math.round(W*0.08),1);
  }
  ctx.restore();
  // Moon reflection ripple on ground
  ctx.save();
  for(let i=0;i<4;i++){
    const rx=Math.round(W*0.8+Math.sin(t*0.04+i)*6);
    ctx.globalAlpha=(0.06-i*0.012)*Math.abs(Math.sin(t*0.03));
    ctx.fillStyle='#aaccee';ctx.fillRect(rx-i*4,gY+4+i*3,8+i*8,1);
  }
  ctx.restore();
}

// ICE: pale blue arctic night, aurora, snow ground
function _cfEnvIce(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#010814'); sky.addColorStop(0.6,'#05101e'); sky.addColorStop(1,'#0a1828');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  // Aurora bands
  ctx.save();
  [[0.2,0.3,'#004422'],[0.45,0.25,'#003344'],[0.7,0.35,'#002233']].forEach(([fx,fy,col],i)=>{
    ctx.globalAlpha=0.10+0.05*Math.sin(t*0.02+i);
    ctx.fillStyle=col;
    ctx.fillRect(0,Math.round(gY*fy),W,Math.round(gY*0.12));
  });
  ctx.restore();
  _cfStars(ctx,W,H,gY,t);
  _cfMoon(ctx,W,H,t,'#ddeeff',0.78,0.11);
  // Ground — snow
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#c8ddf0'); gg.addColorStop(0.3,'#8aaac8'); gg.addColorStop(1,'#405870');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#e8f4ff'; ctx.fillRect(0,gY,W,3);
  // Snow sparkles on ground
  ctx.save();
  for(let i=0;i<12;i++){
    const sx=(i*71+13)%W;
    ctx.globalAlpha=0.4+0.3*Math.sin(t*0.04+i);
    ctx.fillStyle='#ffffff'; ctx.fillRect(sx,gY+2+(i%4)*3,1,1);
  }
  ctx.restore();
  // Snow drift mounds
  ctx.fillStyle='#d0e8ff';
  for(let i=0;i<4;i++){
    const mx=Math.round((i*W/3+W*0.05)%(W-20));
    ctx.fillRect(mx,gY-2,Math.round(W*0.08),4);
  }
}

// LIGHTNING: storm sky, lightning flashes, scorched stone ground
function _cfEnvLightning(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#04060a'); sky.addColorStop(0.6,'#0a0e14'); sky.addColorStop(1,'#14141a');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  // Storm cloud banks
  ctx.save();
  [[0.15,0.18,80],[0.5,0.12,100],[0.75,0.20,70]].forEach(([fx,fy,cw])=>{
    ctx.globalAlpha=0.35; ctx.fillStyle='#1a1e28';
    ctx.fillRect(Math.round(fx*W-cw/2),Math.round(fy*gY),cw,18);
  });
  ctx.restore();
  // Lightning flash across sky
  if(Math.floor(t/90)%5===0&&t%90<8){
    ctx.save();ctx.globalAlpha=0.12;ctx.fillStyle='#eeeeff';ctx.fillRect(0,0,W,gY);ctx.restore();
  }
  _cfStars(ctx,W,H,gY,t);
  // Ground — dark scorched stone
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#12121a'); gg.addColorStop(1,'#06060e');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#1e1e2a'; ctx.fillRect(0,gY,W,2);
  // Stone tile lines
  ctx.save(); ctx.globalAlpha=0.2; ctx.fillStyle='#0a0a14';
  for(let i=0;i<6;i++) ctx.fillRect(Math.round(i*W/5),gY,1,H-gY);
  ctx.restore();
  // Static crackle on ground
  for(let i=0;i<4;i++){
    const sx=Math.round((i*W*0.22+W*0.08)%W);
    ctx.save();ctx.globalAlpha=0.12+0.08*Math.sin(t*0.15+i*2.1);
    ctx.fillStyle='#8888ff';ctx.fillRect(sx,gY+2,1,6);ctx.restore();
  }
}

// EARTH: warm dusk sky, distant mountains, dirt ground
function _cfEnvEarth(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#0a0810'); sky.addColorStop(0.5,'#1a1010'); sky.addColorStop(1,'#2a1a08');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  // Distant mountain silhouettes
  ctx.save(); ctx.fillStyle='#1a1008'; ctx.globalAlpha=0.8;
  [[0.1,0.55,0.12],[0.25,0.50,0.09],[0.45,0.48,0.14],[0.6,0.52,0.10],[0.8,0.46,0.13]].forEach(([fx,fy,fw])=>{
    const mx=Math.round(fx*W), my=Math.round(fy*gY), mw=Math.round(fw*W), mh=gY-my;
    for(let px=mx-mw/2;px<mx+mw/2;px++){
      const h2=mh*Math.max(0,1-Math.pow((px-mx)/(mw/2),2));
      ctx.fillRect(Math.round(px),Math.round(my+mh-h2),1,Math.round(h2));
    }
  });
  ctx.restore();
  _cfStars(ctx,W,H,gY,t);
  _cfMoon(ctx,W,H,t,'#e0c890',0.83,0.14);
  // Ground — rich soil
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#2a1a08'); gg.addColorStop(1,'#0e0a04');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#3a2010'; ctx.fillRect(0,gY,W,2);
  // Dirt texture pebbles
  ctx.save(); ctx.globalAlpha=0.3;
  for(let i=0;i<8;i++){const px=(i*67+23)%W;ctx.fillStyle='#4a2a12';ctx.fillRect(px,gY+3+(i%3)*4,2,1);}
  ctx.restore();
}

// NATURE: lush forest night, fireflies, mossy ground
function _cfEnvNature(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#010a04'); sky.addColorStop(0.6,'#040e06'); sky.addColorStop(1,'#0a1a08');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  // Tree silhouettes L and R
  ctx.save(); ctx.fillStyle='#040e04'; ctx.globalAlpha=0.9;
  [[0.04,0.42,16,gY*0.55],[0.10,0.38,12,gY*0.60],[0.86,0.40,15,gY*0.58],[0.93,0.45,11,gY*0.52]].forEach(([fx,_,tw,th])=>{
    ctx.fillRect(Math.round(fx*W)-Math.round(tw/2),gY-Math.round(th),tw,Math.round(th));
  });
  ctx.restore();
  _cfStars(ctx,W,H,gY,t);
  _cfMoon(ctx,W,H,t,'#d0eec0',0.80,0.12);
  // Ground — moss
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#0e2008'); gg.addColorStop(1,'#040c04');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#1a3a10'; ctx.fillRect(0,gY,W,2);
  // Fireflies
  for(let i=0;i<8;i++){
    const age=(t*0.4+i*14)%70;
    const alpha=age<10?age/10:Math.max(0,1-(age-10)/60);
    const fx=Math.round(W*0.1+((i*59+age*0.5)%(W*0.8)));
    const fy=Math.round(gY*0.5+((i*37)%Math.round(gY*0.4))-age*0.3);
    ctx.save();ctx.globalAlpha=alpha*0.8;ctx.fillStyle='#aaff44';ctx.fillRect(fx,fy,2,2);ctx.restore();
  }
}

// PLASMA: void night, dimensional rifts, arcane ground
function _cfEnvPlasma(ctx,W,H,gY,t){
  const sky=ctx.createLinearGradient(0,0,0,gY);
  sky.addColorStop(0,'#05020e'); sky.addColorStop(0.6,'#0a0518'); sky.addColorStop(1,'#150a22');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,gY);
  // Plasma rift wisps in sky
  ctx.save();
  for(let i=0;i<3;i++){
    const rx=Math.round((i*W*0.3+W*0.1+Math.sin(t*0.02+i)*12)%W);
    const ry=Math.round(gY*(0.2+i*0.12));
    ctx.globalAlpha=0.08+0.05*Math.sin(t*0.03+i*1.4);
    ctx.fillStyle=['#8844ff','#ff44cc','#44aaff'][i];
    ctx.fillRect(rx-25,ry,50,3);
  }
  ctx.restore();
  _cfStars(ctx,W,H,gY,t);
  _cfMoon(ctx,W,H,t,'#cc88ff',0.81,0.12);
  // Ground — dark arcane stone
  const gg=ctx.createLinearGradient(0,gY,0,H);
  gg.addColorStop(0,'#1a0a28'); gg.addColorStop(1,'#080412');
  ctx.fillStyle=gg; ctx.fillRect(0,gY,W,H);
  ctx.fillStyle='#2a1040'; ctx.fillRect(0,gY,W,2);
  // Glowing rune cracks on ground
  for(let i=0;i<5;i++){
    const rx=(i*W*0.18+W*0.06)%W;
    ctx.save();ctx.globalAlpha=0.15+0.10*Math.sin(t*0.05+i*1.7);
    ctx.fillStyle='#aa44ff';ctx.fillRect(Math.round(rx),gY+3,2,H-gY-3);ctx.restore();
  }
}

// AIR: open night sky, player sits on cloud, stars close
function _cfEnvAir(ctx,W,H,gY,t){
  // Full night sky — no ground, we're on a cloud
  const sky=ctx.createLinearGradient(0,0,0,H);
  sky.addColorStop(0,'#03050d'); sky.addColorStop(0.6,'#07101e'); sky.addColorStop(1,'#0d1a2e');
  ctx.fillStyle=sky; ctx.fillRect(0,0,W,H);
  // Many stars (closer, brighter)
  for(let i=0;i<80;i++){
    const sx=(i*131+19)%W, sy=(i*89+41)%(H*0.90);
    const blink=Math.sin(t*0.022+i*0.6)>0.45;
    ctx.globalAlpha=blink?0.85:0.30; ctx.fillStyle=i%7===0?'#aaccff':'#ffffff';
    ctx.fillRect(sx,sy,i%11===0?2:1,i%11===0?2:1);
  }
  ctx.globalAlpha=1;
  // Moon — large, bright
  ctx.save();ctx.globalAlpha=0.70;ctx.fillStyle='#e8f4ff';
  ctx.fillRect(Math.round(W*0.79)-8,Math.round(H*0.10)-8,16,16);
  ctx.globalAlpha=1;ctx.fillStyle='#03050d';
  ctx.fillRect(Math.round(W*0.79)+2,Math.round(H*0.10)-7,7,14);
  ctx.restore();
  // Distant clouds in background
  ctx.save();
  [[0.15,0.65,55,8],[0.60,0.55,70,10],[0.85,0.72,45,7]].forEach(([fx,fy,cw,ch])=>{
    ctx.globalAlpha=0.12;ctx.fillStyle='#4a6a8a';
    ctx.fillRect(Math.round(fx*W-cw/2),Math.round(fy*H),cw,ch);
  });
  ctx.restore();
  // "Ground" is a large cloud platform — drawn at gY level
  // Cloud platform (the one player sits on)
  const cw=Math.round(W*0.7), ch=20, cx=Math.round(W*0.5), cy=gY+2;
  ctx.save();
  ctx.globalAlpha=0.9;ctx.fillStyle='#5a7898';ctx.fillRect(cx-cw/2,cy+Math.round(ch*0.45),cw,Math.round(ch*0.55));
  const bumps=[{ox:0.05,bw:0.20,bh:0.65},{ox:0.22,bw:0.18,bh:0.50},{ox:0.38,bw:0.22,bh:0.75},{ox:0.58,bw:0.20,bh:0.52},{ox:0.76,bw:0.18,bh:0.62}];
  bumps.forEach(({ox,bw,bh})=>{
    const bx=cx-cw/2+Math.round(ox*cw),bwPx=Math.round(bw*cw),bhPx=Math.round(bh*ch*0.65),bTop=cy+Math.round(ch*0.45)-bhPx;
    ctx.fillStyle='#6a8aae';ctx.fillRect(bx,bTop+2,bwPx,bhPx+Math.round(ch*0.55)-2);
    ctx.fillStyle='#9abcd0';ctx.fillRect(bx+1,bTop,bwPx-2,2);
  });
  ctx.fillStyle='#9abcd0';ctx.fillRect(cx-cw/2+1,cy+Math.round(ch*0.45),cw-2,1);
  ctx.restore();
}

// Seated player sprite (back-left view, legs tucked to the right)
const SPRITE_PLAYER_SITTING = [
  '....hhhhh...',
  '...hhhhhhh..',
  '..3hhhhhhh..',
  '...ssssss...',
  '...111111...',
  '..11111111..',
  '.1111111111.',
  '111111111111',
  '111222222111',
  '111222222111',
  '111222222bbb',  // legs out to side
  '.......bbbbb',
];

// Campfire structure sprite (12-col, drawn large)
const SPRITE_CF_LOGS = [
  '..3.....3...',
  '.333...333..',
  '3333.3.3333.',
  '333333333333',
  '222222222222',
  '212122212122',
];

const SPRITE_CF_FLAME_A = [
  '....3111....',
  '...311113...',
  '..31111113..',
  '.3111111113.',
  '..31111113..',
  '...311113...',
];
const SPRITE_CF_FLAME_B = [
  '.....111....',
  '....11113...',
  '...3111113..',
  '..311111113.',
  '...3111113..',
  '....31113...',
];
const SPRITE_CF_FLAME_C = [
  '....3113....',
  '...311113...',
  '...311113...',
  '..31111113..',
  '.311111113..',
  '..311111....',
];

function startCampfireScene(healText) {
  _cfHealText = healText || '';
  _cfTick = 0;
  const canvas = document.getElementById('campfire-canvas');
  if (!canvas) return;

  const W = canvas.parentElement ? canvas.parentElement.clientWidth : 400;
  canvas.width  = Math.min(W, 520);
  canvas.height = Math.round(canvas.width * 0.48);

  if (_cfRAF) cancelAnimationFrame(_cfRAF);
  const tick = () => {
    _renderCampfireScene(canvas);
    _cfTick++;
    _cfRAF = requestAnimationFrame(tick);
  };
  _cfRAF = requestAnimationFrame(tick);
}

function stopCampfireScene() {
  if (_cfRAF) { cancelAnimationFrame(_cfRAF); _cfRAF = null; }
}

function _renderCampfireScene(canvas) {
  const ctx = canvas.getContext('2d');
  const W = canvas.width, H = canvas.height;
  const t = _cfTick;

  // ── Zone-themed environment ─────────────────────────────────────────────
  const _cfZone = (typeof currentZoneElement !== 'undefined' && currentZoneElement) || 'Fire';
  const groundY = Math.floor(H * 0.68);
  _cfDrawEnvironment(ctx, W, H, groundY, t, _cfZone);

  // ── Fire warm glow on ground ──────────────────────────────────────────────
  const fireX = Math.round(W * 0.5);
  const fireY = groundY - 4;
  const flicker = 0.85 + 0.15 * Math.sin(t * 0.13);
  const glowR = (Math.round(W * 0.28)) * flicker;
  ctx.save();
  const glow = ctx.createRadialGradient(fireX, fireY, 0, fireX, fireY, glowR);
  glow.addColorStop(0,   `rgba(255,120,20,${0.18 * flicker})`);
  glow.addColorStop(0.4, `rgba(200,80,10,${0.10 * flicker})`);
  glow.addColorStop(1,   'rgba(0,0,0,0)');
  ctx.fillStyle = glow;
  ctx.fillRect(0, groundY - glowR, W, glowR * 2);
  ctx.restore();

  // ── Campfire logs ─────────────────────────────────────────────────────────
  const logScale = Math.round(Math.max(2, W / 160));
  const logPal = ['#6a3810', '#3a1808', '#c8a060', '#2a1004'];
  const logW = 12 * logScale;
  const logH = SPRITE_CF_LOGS.length * logScale;
  const logSX = Math.round(fireX - logW / 2);
  const logSY = groundY - logH + 2;
  if (typeof drawSprite === 'function') {
    drawSprite(ctx, SPRITE_CF_LOGS, logSX, logSY, logScale, logPal);
  }

  // ── Animated flame ────────────────────────────────────────────────────────
  const frameIdx = Math.floor(t / 5) % 3;
  const flameRows = [SPRITE_CF_FLAME_A, SPRITE_CF_FLAME_B, SPRITE_CF_FLAME_C][frameIdx];
  const flickPals = [
    ['#FF7700','#FFAA00','#FF3300','#FF9900'],
    ['#FF5500','#FF8800','#FF2200','#FFCC00'],
    ['#FF9900','#FFCC00','#FF4400','#FFAA00'],
  ];
  const flamePal = flickPals[frameIdx];
  const flameScale = logScale;
  const flameW = 12 * flameScale;
  const flameH = flameRows.length * flameScale;
  const flameSX = Math.round(fireX - flameW / 2);
  const flameSY = logSY - flameH + flameScale * 2;
  if (typeof drawSprite === 'function') {
    drawSprite(ctx, flameRows, flameSX, flameSY, flameScale, flamePal);
  }

  // ── Smoke particles ───────────────────────────────────────────────────────
  for (let i = 0; i < 8; i++) {
    const age   = (t * 0.7 + i * 11) % 60;
    const alpha = Math.max(0, 0.25 - age / 100);
    if (alpha <= 0) continue;
    const px = fireX + Math.sin(age * 0.18 + i) * 7;
    const py = flameSY - age * 1.1;
    const r  = 1 + age * 0.12;
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.fillStyle = '#888888';
    ctx.beginPath();
    ctx.arc(px, py, r, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  // ── Player sitting left of fire ───────────────────────────────────────────
  const pScale = Math.round(Math.max(2, W / 180));
  const pRows  = typeof getPlayerCharSprite === 'function' ? getPlayerCharSprite() : SPRITE_PLAYER_SITTING;
  // Use sitting sprite
  const sitRows = SPRITE_PLAYER_SITTING;
  const sitPal  = typeof getElemPal === 'function' && typeof playerElement !== 'undefined'
                  ? getElemPal(playerElement) : ['#888888','#555555','#aaaaaa','#dddddd'];

  // Add hair color — override 'h' in palette via custom charToColor
  const sitW = 12 * pScale;
  const sitH = sitRows.length * pScale;
  const sitX = Math.round(fireX - logW * 1.55 - sitW * 0.5);
  const sitY = groundY - sitH + pScale;

  // Gentle warm tint from fire on player
  ctx.save();
  ctx.globalAlpha = 0.12 + 0.05 * Math.sin(t * 0.1);
  ctx.fillStyle = '#FF8822';
  ctx.fillRect(sitX, sitY, sitW, sitH);
  ctx.restore();

  if (typeof drawSprite === 'function') {
    drawSprite(ctx, sitRows, sitX, sitY, pScale, sitPal);
  }

  // ── Heal text ─────────────────────────────────────────────────────────────
  if (_cfHealText) {
    const fadeIn = Math.min(1, t / 35);
    ctx.save();
    ctx.globalAlpha = fadeIn * (0.75 + 0.25 * Math.sin(t * 0.04));
    ctx.font = `bold ${Math.round(W * 0.03)}px 'Cinzel', serif`;
    ctx.textAlign = 'center';
    ctx.fillStyle = '#55ee88';
    ctx.fillText(_cfHealText, W / 2, Math.round(H * 0.92));
    ctx.restore();
  }

  // ── Firefly sparks floating up ────────────────────────────────────────────
  for (let i = 0; i < 5; i++) {
    const age   = (t * 0.5 + i * 17) % 80;
    const alpha = age < 10 ? age / 10 : Math.max(0, 1 - (age - 10) / 70);
    if (alpha <= 0) continue;
    const spark_x = logSX + 8 + ((i * 37 + Math.floor(age)) % (logW - 8));
    const spark_y = logSY - age * 0.7;
    ctx.save();
    ctx.globalAlpha = alpha * 0.85;
    ctx.fillStyle = age < 30 ? '#FFCC44' : '#FF6600';
    ctx.fillRect(Math.round(spark_x), Math.round(spark_y), 2, 2);
    ctx.restore();
  }
}


