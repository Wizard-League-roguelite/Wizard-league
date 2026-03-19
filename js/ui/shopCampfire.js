// ===== shopCampfire.js =====
// ─── CAMPFIRE + SHOP screens ──────────────────────────────────────────────────

function enterCampfire(){
  const pMax = maxHPFor('player');
  const descEl = document.getElementById('campfire-desc');
  const cont   = document.getElementById('campfire-choices');
  if (descEl) descEl.textContent = 'The fire crackles. How do you spend your rest?';

  const CAMPFIRE_OPTS = [
    { emoji:'🔥', label:'Rest & Recover',
      tag:'Rest',
      desc:`Heal ${Math.floor(pMax*0.50)} HP and fully restore all spell PP.`,
      apply(){
        const actual = applyHeal('player', Math.floor(pMax*0.50), null);
        restoreAllPP();
        log(actual>0 ? `🔥 You rest. +${actual} HP, all PP restored.` : '🔥 Already full — PP restored.', 'heal');
      }},
    { emoji:'⚔️', label:'Sharpen Your Edge',
      tag:'Forge',
      desc:`Heal ${Math.floor(pMax*0.20)} HP and permanently gain +8 Attack Power.`,
      apply(){
        const actual = applyHeal('player', Math.floor(pMax*0.20), null);
        player.attackPower += 8; updateStatsUI();
        log(`⚔️ Steel sharpened.${actual>0?' +'+actual+' HP,':''} +8 ATK.`, 'item');
      }},
    { emoji:'✦', label:'Focus Your Craft',
      tag:'Forge',
      desc:`Heal ${Math.floor(pMax*0.20)} HP and permanently gain +8 Effect Power.`,
      apply(){
        const actual = applyHeal('player', Math.floor(pMax*0.20), null);
        player.effectPower += 8; updateStatsUI();
        log(`✦ Mind sharpened.${actual>0?' +'+actual+' HP,':''} +8 EFX.`, 'item');
      }},
    { emoji:'🛡️', label:'Fortify',
      tag:'Forge',
      desc:`Heal ${Math.floor(pMax*0.20)} HP and permanently gain +8 Defense.`,
      apply(){
        const actual = applyHeal('player', Math.floor(pMax*0.20), null);
        player.defense += 8; updateStatsUI();
        log(`🛡️ Armor reinforced.${actual>0?' +'+actual+' HP,':''} +8 DEF.`, 'item');
      }},
    { emoji:'🌿', label:'Forage Supplies',
      tag:'Forage',
      desc:`Heal ${Math.floor(pMax*0.20)} HP and gain 80 gold.`,
      apply(){
        const actual = applyHeal('player', Math.floor(pMax*0.20), null);
        player.gold += 80;
        log(`🌿 Foraged supplies.${actual>0?' +'+actual+' HP,':''} +80 Gold.`, 'item');
      }},
    { emoji:'📖', label:'Study the Arcane',
      tag:'Study',
      desc:'Restore all spell PP and gain +1 reroll token.',
      apply(){
        restoreAllPP();
        player._rerolls = (player._rerolls||0) + 1;
        log('📖 You study by firelight. All PP restored, +1 Reroll.', 'item');
      }},
  ];

  // Rest & Recover is always one of the 3 options; pick 2 more from the rest
  const restOpt = CAMPFIRE_OPTS[0];
  const otherOpts = CAMPFIRE_OPTS.slice(1);
  const chosen = [restOpt, ...pickRandom(otherOpts, 2)];
  if (cont) {
    cont.innerHTML = '';
    chosen.forEach(opt => {
      const btn = document.createElement('button');
      btn.className = 'prog-choice-btn';
      btn.innerHTML = `<div class="pc-tag">${opt.tag}</div><div class="pc-name">${opt.emoji} ${opt.label}</div><div class="pc-desc">${opt.desc}</div>`;
      btn.onclick = () => {
        opt.apply();
        if (descEl) descEl.textContent = '';
        cont.innerHTML = '';
        const leaveBtn = document.createElement('button');
        leaveBtn.className = 'btn-main';
        leaveBtn.style.width = '220px';
        leaveBtn.textContent = 'Continue';
        leaveBtn.onclick = leaveCampfire;
        cont.appendChild(leaveBtn);
      };
      cont.appendChild(btn);
    });
  }

  showScreen('campfire-screen');
  setTimeout(()=>startCampfireScene(''), 0);
}
function leaveCampfire(){ stopCampfireScene(); showMap(); }

function enterShop(){
  document.getElementById("shop-gold-display").textContent=player.gold;
  const c=document.getElementById("shop-items"); c.innerHTML="";
  const _pm = player._mistShopPriceMult || 1.0;
  const addRow=(emoji,name,desc,cost,canBuy,onBuy)=>{
    const row=document.createElement("div");
    row.className="shop-item-row"+(canBuy?"":" cant-afford");
    row.innerHTML=`<div><div class="shop-item-name">${emoji} ${name}</div><div class="shop-item-desc">${desc}</div></div><div class="shop-item-cost">${cost}g</div>`;
    if(canBuy) row.onclick=onBuy;
    c.appendChild(row);
  };
  SHOP_ITEMS.forEach(id=>{
    const item=ITEM_CATALOGUE[id];
    const cost=Math.ceil(item.shopCost*_pm);
    addRow(item.emoji,item.name,item.desc,cost,player.gold>=cost,
      ()=>{player.gold-=cost;addItem(id);enterShop();});
  });
  const revCost = Math.ceil(200*_pm);
  const maxRevives = 6;
  addRow('❤️','Extra Life',`Gain +1 life (${player.revives} now). Revives heal to 75% HP.`,
    revCost, player.gold>=revCost && player.revives<maxRevives,
    ()=>{player.gold-=revCost; player.revives++; enterShop();});

  const actionCost = Math.ceil(350*_pm);
  const maxBonusActions = 2;
  addRow('⚡','Extra Action',
    `Gain +1 permanent action per turn (${player.bonusActions}/${maxBonusActions}). Cooldowns still apply.`,
    actionCost, player.gold>=actionCost && (player.bonusActions||0)<maxBonusActions,
    ()=>{player.gold-=actionCost; player.bonusActions=(player.bonusActions||0)+1; enterShop();});
  const allPassives=Object.entries(PASSIVE_CHOICES).flatMap(([el,ps])=>ps.map(p=>({...p,element:el})));
  const forSale=allPassives.filter(p=>!p.legendary&&!player.passives.includes(p.id));
  pickRandom(forSale,2).forEach(p=>{
    const pCost=Math.ceil(1000*_pm);
    addRow(p.emoji,p.title,`[${p.element}] ${p.desc}`,pCost,player.gold>=pCost,
      ()=>{player.gold-=pCost;addPassiveToBook(p.id);enterShop();});
  });
  updateStatsUI();
  showScreen("shop-screen");
  startShopCanvas();
}
function leaveShop(){
  const c = document.getElementById('shop-canvas');
  if(c && c._stop) c._stop();
  showMap();
}
