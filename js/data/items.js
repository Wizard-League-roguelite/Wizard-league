// ===== items.js =====
// ─── ITEM DATA ─────────────────────────────────────────────────────────────
// ITEM_CATALOGUE, shop pool, drop pool.

// ===============================
// ITEMS

// ===============================
const ITEM_CATALOGUE = {
  health_potion:{ id:'health_potion', name:'Health Potion', emoji:'🧪', desc:'Restore 20 HP', shopCost:30, type:'consumable',
    use(){ applyHeal('player',20,'🧪 Health Potion'); return null; }},
  dmg_booster:  { id:'dmg_booster', name:'Damage Crystal', emoji:'💎', desc:'+10 dmg this battle', shopCost:50, type:'consumable',
    use(){ combat.tempDmgBonus+=10; return `Damage Crystal shatters — +10 damage for this battle!`; }},
};
const ITEM_DROP_POOL = ['health_potion','dmg_booster'];
const SHOP_ITEMS     = ['health_potion','dmg_booster'];


