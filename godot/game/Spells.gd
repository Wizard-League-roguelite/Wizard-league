# Spells — generated from js/data/spells.js by tools/js2gd.js
extends Node

var STARTER_SPELL = null
var SPELL_CATALOGUE = null
var NEUTRAL_SPELL_IDS = null

func _boot():
	# ===== spells.js =====
	# ─── SPELL CATALOGUE ─────────────────────────────────────────────────────────
	STARTER_SPELL = {
		"Fire": "ignite",
		"Water": "tidal_surge",
		"Ice": "frost_bolt",
		"Lightning": "zap",
		"Earth": "seismic_wave",
		"Nature": "vine_strike",
		"Plasma": "plasma_lance",
		"Air": "quintuple_hit",
	}
	SPELL_CATALOGUE = {
		"ignite": {
			"id": "ignite",
			"tier": "primary",
			"name": "Ignite",
			"emoji": "🔥",
			"element": "Fire",
			"tags": ["burn"],
			"desc": "Strike and heavily ignite the target",
			"baseCooldown": 1,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__ignite__execute,
		},
		"ember_storm": {
			"id": "ember_storm",
			"tier": "primary",
			"name": "Ember Storm",
			"emoji": "🔥",
			"element": "Fire",
			"tags": ["burn"],
			"desc": "Three rapid strikes, each fanning the flames",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__ember_storm__execute,
		},
		"flame_wave": {
			"id": "flame_wave",
			"tier": "primary",
			"name": "Flame Wave",
			"emoji": "🌊",
			"element": "Fire",
			"tags": ["burn"],
			"desc": "Scorching wave washes over all enemies",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__flame_wave__execute,
		},
		"firewall": {
			"id": "firewall",
			"tier": "primary",
			"name": "Firewall",
			"emoji": "🔥🛡",
			"element": "Fire",
			"desc": "Raise a burning shield that punishes attackers",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__firewall__execute,
		},
		"grease_fire": {
			"id": "grease_fire",
			"tier": "secondary",
			"name": "Grease Fire",
			"emoji": "🛢️",
			"element": "Fire",
			"requiresTag": "burn",
			"desc": "Fuel the fire — Burn erupts harder this round",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__grease_fire__execute,
		},
		"extinguish": {
			"id": "extinguish",
			"tier": "secondary",
			"name": "Extinguish",
			"emoji": "💧",
			"element": "Fire",
			"requiresTag": "burn",
			"desc": "Trigger burn, then douse both sides — damage from the ashes",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__extinguish__execute,
		},
		"fire_heal": {
			"id": "fire_heal",
			"tier": "secondary",
			"name": "Fire Heal",
			"emoji": "❤️‍🔥",
			"element": "Fire",
			"requiresTag": "burn",
			"desc": "Draw life from all fire on the battlefield",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__fire_heal__execute,
		},
		"fire_rage": {
			"id": "fire_rage",
			"tier": "secondary",
			"name": "Fire Rage",
			"emoji": "😤",
			"element": "Fire",
			"requiresTag": "burn",
			"desc": "Channel the rage of fire into raw Power for 1 turn",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__fire_rage__execute,
		},
		"brave_burn": {
			"id": "brave_burn",
			"tier": "legendary",
			"name": "Brave Burn",
			"emoji": "🔥💀",
			"element": "Fire",
			"desc": "Copy the highest burn stack count from any enemy onto yourself — gain debuff immunity for 1 turn",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__brave_burn__execute,
		},
		"melt_strike": {
			"id": "melt_strike",
			"tier": "primary",
			"name": "Melt Strike",
			"emoji": "⚒️",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "A focused lance of molten force that eats through armor at triple efficiency",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__melt_strike__execute,
		},
		"forge_blast": {
			"id": "forge_blast",
			"tier": "primary",
			"name": "Forge Blast",
			"emoji": "💥",
			"element": "Fire",
			"tags": ["melt", "burn"],
			"desc": "A forge explosion — Melt first, then scorches the target with Burn",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__forge_blast__execute,
		},
		"crucible": {
			"id": "crucible",
			"tier": "primary",
			"name": "Crucible",
			"emoji": "🌡️",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "Super-heat the target's armor — doubles it, then strikes with Melt equal to half the doubled value",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__crucible__execute,
		},
		"scorch_through": {
			"id": "scorch_through",
			"tier": "primary",
			"name": "Scorch Through",
			"emoji": "🌊",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "A wave of scorching heat melts through all enemies",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__scorch_through__execute,
		},
		"slag": {
			"id": "slag",
			"tier": "primary",
			"name": "Slag",
			"emoji": "🔶",
			"element": "Fire",
			"tags": ["melt", "burn"],
			"desc": "Coat the target in molten slag — small Melt hit that converts any armor consumed into Burn stacks",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__slag__execute,
		},
		"heat_surge": {
			"id": "heat_surge",
			"tier": "primary",
			"name": "Heat Surge",
			"emoji": "❤️‍🔥",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "A surge of intense heat — heavy Melt damage and heals you for half the HP damage dealt",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__heat_surge__execute,
		},
		"smelt": {
			"id": "smelt",
			"tier": "secondary",
			"name": "Smelt",
			"emoji": "⚗️",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "Convert enemy Burn into Melt energy — each 3 Burn stacks consumed = 1 Melt point, then armor, then HP",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__smelt__execute,
		},
		"overheat": {
			"id": "overheat",
			"tier": "secondary",
			"name": "Overheat",
			"emoji": "🌡️",
			"element": "Fire",
			"requiresTag": "burn",
			"tags": ["melt"],
			"desc": "Consume your own Burn stacks — deal Melt equal to stacks consumed plus power scaling",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__overheat__execute,
		},
		"crucible_burst": {
			"id": "crucible_burst",
			"tier": "secondary",
			"name": "Crucible Burst",
			"emoji": "💥",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "Massive Melt if the enemy has heavy armor (15+), weaker otherwise",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__crucible_burst__execute,
		},
		"molten_surge": {
			"id": "molten_surge",
			"tier": "secondary",
			"name": "Molten Surge",
			"emoji": "🌋",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "The forge surges — all Melt hits this turn deal double damage",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__molten_surge__execute,
		},
		"melt_down": {
			"id": "melt_down",
			"tier": "secondary",
			"name": "Melt Down",
			"emoji": "🫠",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "Force-break all enemy armor and deal 1.5× its value as Melt damage",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__melt_down__execute,
		},
		"temper": {
			"id": "temper",
			"tier": "secondary",
			"name": "Temper",
			"emoji": "⚔️",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "Temper your next strike — the next Melt hit this battle deals double damage",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__temper__execute,
		},
		"white_heat": {
			"id": "white_heat",
			"tier": "legendary",
			"name": "White Heat",
			"emoji": "🤍",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "Pure molten force — no base value, scales entirely with Attack Power for massive late-game damage",
			"baseCooldown": 5,
			"execute": SPELL_CATALOGUE__white_heat__execute,
		},
		"searing_verdict": {
			"id": "searing_verdict",
			"tier": "legendary",
			"name": "Searing Verdict",
			"emoji": "⚖️",
			"element": "Fire",
			"tags": ["melt"],
			"desc": "A final judgment — scales with every kill this run. More kills = more Melt.",
			"baseCooldown": 5,
			"execute": SPELL_CATALOGUE__searing_verdict__execute,
		},
		"tidal_surge": {
			"id": "tidal_surge",
			"tier": "primary",
			"name": "Tidal Surge",
			"emoji": "💧",
			"element": "Water",
			"desc": "Strike and restore your health",
			"baseCooldown": 1,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__tidal_surge__execute,
		},
		"whirlpool": {
			"id": "whirlpool",
			"tier": "primary",
			"name": "Whirlpool",
			"emoji": "🌀",
			"element": "Water",
			"desc": "Spinning vortex hits all enemies and coats them with Foam",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__whirlpool__execute,
		},
		"healing_tide": {
			"id": "healing_tide",
			"tier": "primary",
			"name": "Healing Tide",
			"emoji": "💚",
			"element": "Water",
			"desc": "A healing wave washes over you",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__healing_tide__execute,
		},
		"riptide": {
			"id": "riptide",
			"tier": "primary",
			"name": "Riptide",
			"emoji": "🌊",
			"element": "Water",
			"desc": "Rapid water strikes. Hits increase with incantation level.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__riptide__execute,
		},
		"drown": {
			"id": "drown",
			"tier": "secondary",
			"name": "Drown",
			"emoji": "🌊💀",
			"element": "Water",
			"desc": "If target has enough Foam, drown them. Otherwise, apply more",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__drown__execute,
		},
		"tidal_shield": {
			"id": "tidal_shield",
			"tier": "secondary",
			"name": "Tidal Shield",
			"emoji": "🌊🛡",
			"element": "Water",
			"desc": "Shield of water — reflects Foam and heals you if struck",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__tidal_shield__execute,
		},
		"deep_current": {
			"id": "deep_current",
			"tier": "secondary",
			"name": "Deep Current",
			"emoji": "💠",
			"element": "Water",
			"desc": "Ride the current — your next Water spell fires twice",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__deep_current__execute,
		},
		"cleanse_current": {
			"id": "cleanse_current",
			"tier": "secondary",
			"name": "Cleanse Current",
			"emoji": "✨",
			"element": "Water",
			"desc": "Cleanse yourself and draw healing from each effect removed",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__cleanse_current__execute,
		},
		"tsunami": {
			"id": "tsunami",
			"tier": "legendary",
			"name": "Tsunami",
			"emoji": "🌊🌊",
			"element": "Water",
			"desc": "Unleash all Foam in a devastating tidal wave",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__tsunami__execute,
		},
		"frost_bolt": {
			"id": "frost_bolt",
			"tier": "primary",
			"name": "Frost Bolt",
			"emoji": "❄️",
			"element": "Ice",
			"tags": ["freeze"],
			"desc": "Cold bolt that frosts the target",
			"baseCooldown": 1,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__frost_bolt__execute,
		},
		"ice_block": {
			"id": "ice_block",
			"tier": "primary",
			"name": "Ice Block",
			"emoji": "🧊",
			"element": "Ice",
			"desc": "Become invulnerable and freeze the battlefield",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__ice_block__execute,
		},
		"glacial_spike": {
			"id": "glacial_spike",
			"tier": "primary",
			"name": "Glacial Spike",
			"emoji": "🗡️",
			"element": "Ice",
			"tags": ["freeze"],
			"desc": "Heavy ice spike drives frost into the target",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__glacial_spike__execute,
		},
		"snowstorm": {
			"id": "snowstorm",
			"tier": "primary",
			"name": "Snowstorm",
			"emoji": "🌨️",
			"element": "Ice",
			"tags": ["freeze"],
			"desc": "Blizzard sweeps all enemies with frost",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__snowstorm__execute,
		},
		"flash_freeze": {
			"id": "flash_freeze",
			"tier": "secondary",
			"name": "Flash Freeze",
			"emoji": "❄️❄️",
			"element": "Ice",
			"requiresTag": "freeze",
			"desc": "Rapidly stack Frost on the target",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__flash_freeze__execute,
		},
		"shatter": {
			"id": "shatter",
			"tier": "secondary",
			"name": "Shatter",
			"emoji": "💎",
			"element": "Ice",
			"requiresTag": "freeze",
			"desc": "Consume all Frost stacks. Deal Frost×4 damage. Upgrades increase the multiplier.",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__shatter__execute,
		},
		"frozen_ground": {
			"id": "frozen_ground",
			"tier": "secondary",
			"name": "Frozen Ground",
			"emoji": "🌍❄️",
			"element": "Ice",
			"desc": "Persistent frost field chills all enemies over time",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__frozen_ground__execute,
		},
		"cryostasis": {
			"id": "cryostasis",
			"tier": "secondary",
			"name": "Cryostasis",
			"emoji": "🧊💤",
			"element": "Ice",
			"desc": "Freeze yourself briefly — emerge healed and armored",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__cryostasis__execute,
		},
		"ice_age": {
			"id": "ice_age",
			"tier": "legendary",
			"name": "Ice Age",
			"emoji": "❄️🌍",
			"element": "Ice",
			"desc": "Lock the entire battlefield in deep frost",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__ice_age__execute,
		},
		"zap": {
			"id": "zap",
			"tier": "primary",
			"name": "Zap",
			"emoji": "⚡",
			"element": "Lightning",
			"desc": "Fast lightning jab that applies Shock",
			"baseCooldown": 0,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__zap__execute,
		},
		"chain_lightning": {
			"id": "chain_lightning",
			"tier": "primary",
			"name": "Chain Lightning",
			"emoji": "⚡⚡",
			"element": "Lightning",
			"desc": "Arcing lightning bounces between enemies. Stops when no new targets remain — dumps remaining shock stacks on the last hit enemy.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__chain_lightning__execute,
		},
		"overcharge": {
			"id": "overcharge",
			"tier": "primary",
			"name": "Overcharge",
			"emoji": "⚡💪",
			"element": "Lightning",
			"desc": "Load the target with Shock and charge yourself up",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__overcharge__execute,
		},
		"blitz": {
			"id": "blitz",
			"tier": "secondary",
			"name": "Blitz",
			"emoji": "💥⚡",
			"element": "Lightning",
			"desc": "Detonate all Shock on target for burst damage",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__blitz__execute,
		},
		"recharge": {
			"id": "recharge",
			"tier": "secondary",
			"name": "Recharge",
			"emoji": "🔋",
			"element": "Lightning",
			"desc": "Reset your Overload damage to maximum",
			"baseCooldown": 8,
			"execute": SPELL_CATALOGUE__recharge__execute,
		},
		"electrocute": {
			"id": "electrocute",
			"tier": "secondary",
			"name": "Electrocute",
			"emoji": "☠️⚡",
			"element": "Lightning",
			"desc": "Double the Shock on target at a painful cost",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__electrocute__execute,
		},
		"feedback": {
			"id": "feedback",
			"tier": "secondary",
			"name": "Feedback",
			"emoji": "🔄⚡",
			"element": "Lightning",
			"desc": "Surge of power — Shock the target and charge for next turn",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__feedback__execute,
		},
		"short_circuit": {
			"id": "short_circuit",
			"tier": "secondary",
			"name": "Short Circuit",
			"emoji": "💡",
			"element": "Lightning",
			"desc": "Scramble an enemy action — it misfires or backfires",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__short_circuit__execute,
		},
		"static_cleanse": {
			"id": "static_cleanse",
			"tier": "secondary",
			"name": "Static Cleanse",
			"emoji": "🧹⚡",
			"element": "Lightning",
			"desc": "Discharge yourself clean and shock enemies for each effect",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__static_cleanse__execute,
		},
		"charge_shot": {
			"id": "charge_shot",
			"tier": "legendary",
			"name": "Charge Shot",
			"emoji": "🎯⚡",
			"element": "Lightning",
			"desc": "Spend two actions to unleash a delayed area lightning blast",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__charge_shot__execute,
		},
		"bolt": {
			"id": "bolt",
			"tier": "primary",
			"name": "Bolt",
			"emoji": "⚡",
			"element": "Lightning",
			"desc": "Quick lightning strike that loads a Surge onto the target",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__bolt__execute,
		},
		"thunder_strike": {
			"id": "thunder_strike",
			"tier": "primary",
			"name": "Thunder Strike",
			"emoji": "🌩️",
			"element": "Lightning",
			"desc": "Heavy strike that hits hard and loads Shock",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__thunder_strike__execute,
		},
		"ball_lightning": {
			"id": "ball_lightning",
			"tier": "primary",
			"name": "Ball Lightning",
			"emoji": "🔮⚡",
			"element": "Lightning",
			"desc": "Rolling orb of lightning hits all enemies and loads Surge on each",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__ball_lightning__execute,
		},
		"static_charge": {
			"id": "static_charge",
			"tier": "primary",
			"name": "Static Charge",
			"emoji": "⚡🔋",
			"element": "Lightning",
			"desc": "No damage — loads a heavy Surge onto the target",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__static_charge__execute,
		},
		"megavolt": {
			"id": "megavolt",
			"tier": "primary",
			"name": "Megavolt",
			"emoji": "💥⚡",
			"element": "Lightning",
			"desc": "Massive lightning burst — pure damage",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__megavolt__execute,
		},
		"supercharge": {
			"id": "supercharge",
			"tier": "secondary",
			"name": "Supercharge",
			"emoji": "⚡⚡",
			"element": "Lightning",
			"desc": "Load a huge Surge, or add to an existing one",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__supercharge__execute,
		},
		"overclock": {
			"id": "overclock",
			"tier": "secondary",
			"name": "Overclock",
			"emoji": "⏫⚡",
			"element": "Lightning",
			"desc": "Double the current Surge value on the target",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__overclock__execute,
		},
		"residual_current": {
			"id": "residual_current",
			"tier": "secondary",
			"name": "Residual Current",
			"emoji": "🔄⚡",
			"element": "Lightning",
			"desc": "After Surge triggers this turn, apply a new Surge 30. Cast before or after.",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__residual_current__execute,
		},
		"detonator": {
			"id": "detonator",
			"tier": "secondary",
			"name": "Detonator",
			"emoji": "💣⚡",
			"element": "Lightning",
			"desc": "Instantly trigger the Surge on the target",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__detonator__execute,
		},
		"grounded": {
			"id": "grounded",
			"tier": "secondary",
			"name": "Grounded",
			"emoji": "🌱⚡",
			"element": "Lightning",
			"desc": "Remove all your debuffs — each removed adds +5 to target Surge",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__grounded__execute,
		},
		"thunderclap": {
			"id": "thunderclap",
			"tier": "legendary",
			"name": "Thunderclap",
			"emoji": "🌩️💥",
			"element": "Lightning",
			"desc": "Massive lightning blast hits all enemies, loading Surge 100 on each",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__thunderclap__execute,
		},
		"fulgurite": {
			"id": "fulgurite",
			"tier": "legendary",
			"name": "Fulgurite",
			"emoji": "🪨⚡",
			"element": "Lightning",
			"desc": "Strike that permanently lowers the Surge threshold this battle by 5",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__fulgurite__execute,
		},
		"seismic_wave": {
			"id": "seismic_wave",
			"tier": "primary",
			"name": "Seismic Wave",
			"emoji": "🌊🪨",
			"element": "Earth",
			"desc": "Armor Strip: steal armor from the target and add it to yours",
			"baseCooldown": 2,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__seismic_wave__execute,
		},
		"fortify": {
			"id": "fortify",
			"tier": "primary",
			"name": "Fortify",
			"emoji": "🏰",
			"element": "Earth",
			"desc": "Armor up — it converts to Stone stacks next turn",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__fortify__execute,
		},
		"echo_slam": {
			"id": "echo_slam",
			"tier": "primary",
			"name": "Echo Slam",
			"emoji": "🌍",
			"element": "Earth",
			"desc": "Tremor deals more damage the more enemies are present",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__echo_slam__execute,
		},
		"stone_stance": {
			"id": "stone_stance",
			"tier": "secondary",
			"name": "Stone Stance",
			"emoji": "🪨💪",
			"element": "Earth",
			"desc": "Channel your Stone for double its effect this turn",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__stone_stance__execute,
		},
		"stone_sanctuary": {
			"id": "stone_sanctuary",
			"tier": "secondary",
			"name": "Stone Sanctuary",
			"emoji": "🏔️",
			"element": "Earth",
			"desc": "Multiply your Stone stacks instantly",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__stone_sanctuary__execute,
		},
		"earthshaker": {
			"id": "earthshaker",
			"tier": "secondary",
			"name": "Earthshaker",
			"emoji": "👊🪨",
			"element": "Earth",
			"desc": "A devastating strike that scales purely with Power",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__earthshaker__execute,
		},
		"dig": {
			"id": "dig",
			"tier": "secondary",
			"name": "Dig",
			"emoji": "⛏️",
			"element": "Earth",
			"desc": "Dig in — shake off debuffs and reinforce yourself",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__dig__execute,
		},
		"cataclysm": {
			"id": "cataclysm",
			"tier": "legendary",
			"name": "Cataclysm",
			"emoji": "💥🪨",
			"element": "Earth",
			"desc": "Release your Stone in a crushing area collapse",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__cataclysm__execute,
		},
		"vine_strike": {
			"id": "vine_strike",
			"tier": "primary",
			"name": "Vine Strike",
			"emoji": "🌿",
			"element": "Nature",
			"desc": "Three quick strikes each trying to root the target",
			"baseCooldown": 0,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__vine_strike__execute,
		},
		"thornwall": {
			"id": "thornwall",
			"tier": "primary",
			"name": "Thornwall",
			"emoji": "🌵",
			"element": "Nature",
			"desc": "Raise thorned armor and ensnare the target",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__thornwall__execute,
		},
		"natures_call": {
			"id": "natures_call",
			"tier": "primary",
			"name": "Nature's Call",
			"emoji": "🌳",
			"element": "Nature",
			"desc": "Call a Treant ally to fight alongside you",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__natures_call__execute,
		},
		"bramble_burst": {
			"id": "bramble_burst",
			"tier": "primary",
			"name": "Bramble Burst",
			"emoji": "🌵💥",
			"element": "Nature",
			"desc": "Thorny burst hits all enemies and tries to root each",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__bramble_burst__execute,
		},
		"wild_growth": {
			"id": "wild_growth",
			"tier": "secondary",
			"name": "Wild Growth",
			"emoji": "🌿🌿",
			"element": "Nature",
			"desc": "Vines multiply — double the target's Root stacks",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__wild_growth__execute,
		},
		"living_forest": {
			"id": "living_forest",
			"tier": "secondary",
			"name": "Living Forest",
			"emoji": "🌲",
			"element": "Nature",
			"desc": "Command all Treants to strike twice this turn",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__living_forest__execute,
		},
		"spreading_vines": {
			"id": "spreading_vines",
			"tier": "secondary",
			"name": "Spreading Vines",
			"emoji": "🌿🌍",
			"element": "Nature",
			"desc": "Spreading vines root all enemies over several rounds",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__spreading_vines__execute,
		},
		"nourish": {
			"id": "nourish",
			"tier": "secondary",
			"name": "Nourish",
			"emoji": "💚🌳",
			"element": "Nature",
			"desc": "Strengthen and heal all your Treant allies",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__nourish__execute,
		},
		"natures_wrath": {
			"id": "natures_wrath",
			"tier": "legendary",
			"name": "Nature's Wrath",
			"emoji": "🌿💥",
			"element": "Nature",
			"desc": "Consume all Root in a crushing Nature's Wrath",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__natures_wrath__execute,
		},
		"damage_seed": {
			"id": "damage_seed",
			"tier": "primary",
			"name": "Damage Seed",
			"emoji": "🌱",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Plant a Damage Seed on the target — germinates in 3 turns, dealing 30+EFX/2 damage per stack",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__damage_seed__execute,
		},
		"root_seed": {
			"id": "root_seed",
			"tier": "primary",
			"name": "Root Seed",
			"emoji": "🌱",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Plant a Root Seed on the target — germinates in 3 turns, applying 3 Root per stack",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__root_seed__execute,
		},
		"silence_seed": {
			"id": "silence_seed",
			"tier": "primary",
			"name": "Silence Seed",
			"emoji": "🤫",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Plant a Silence Seed on the target — germinates in 3 turns, silencing 4 random player spells (prioritizing active book). Cannot stack — each cast is independent. +1 spell per upgrade.",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__silence_seed__execute,
		},
		"armor_seed": {
			"id": "armor_seed",
			"tier": "primary",
			"name": "Armor Seed",
			"emoji": "🛡️",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Plant an Armor Seed on yourself — germinates in 3 turns, granting 30 Armor per stack",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__armor_seed__execute,
		},
		"accelerate": {
			"id": "accelerate",
			"tier": "secondary",
			"name": "Accelerate",
			"emoji": "⚡",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Reduce all active Seed germination timers by 1 — can trigger immediate blooms",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__accelerate__execute,
		},
		"overgrow": {
			"id": "overgrow",
			"tier": "secondary",
			"name": "Overgrow",
			"emoji": "🌿",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Double all current Seed stacks on the target",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__overgrow__execute,
		},
		"cross_pollinate": {
			"id": "cross_pollinate",
			"tier": "secondary",
			"name": "Cross Pollinate",
			"emoji": "🌼",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Copy all Seed stacks from the target onto all other enemies — exact same timer state",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__cross_pollinate__execute,
		},
		"seed_surge": {
			"id": "seed_surge",
			"tier": "secondary",
			"name": "Seed Surge",
			"emoji": "💥",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Your next Seed planted this turn costs no cooldown and gains 2 free stacks",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__seed_surge__execute,
		},
		"deep_soil": {
			"id": "deep_soil",
			"tier": "secondary",
			"name": "Deep Soil",
			"emoji": "🌍",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Reset all active Seed timers back to 4 turns — each Seed gains 1 free stack",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__deep_soil__execute,
		},
		"reap": {
			"id": "reap",
			"tier": "secondary",
			"name": "Reap",
			"emoji": "🌾",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Consume all active Seeds — each triggers a weakened bloom at half power (incantations included)",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__reap__execute,
		},
		"bloom_storm": {
			"id": "bloom_storm",
			"tier": "legendary",
			"name": "Bloom Storm",
			"emoji": "🌺",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "All Seeds on all enemies germinate simultaneously",
			"baseCooldown": 5,
			"execute": SPELL_CATALOGUE__bloom_storm__execute,
		},
		"world_tree": {
			"id": "world_tree",
			"tier": "legendary",
			"name": "World Tree",
			"emoji": "🌳",
			"element": "Nature",
			"tags": ["seed"],
			"desc": "Plant all four Seed types on the target (×2 stacks each). Healing Seed goes on you.",
			"baseCooldown": 6,
			"execute": SPELL_CATALOGUE__world_tree__execute,
		},
		"plasma_lance": {
			"id": "plasma_lance",
			"tier": "primary",
			"name": "Plasma Lance",
			"emoji": "🔮",
			"element": "Plasma",
			"desc": "Spend Charge for a focused beam — heals 3 HP per Charge consumed",
			"baseCooldown": 0,
			"isStarter": true,
			"isPlasmaAbility": true,
			"chargeCost": "variable",
			"execute": SPELL_CATALOGUE__plasma_lance__execute,
		},
		"energy_infusion": {
			"id": "energy_infusion",
			"tier": "primary",
			"name": "Energy Infusion",
			"emoji": "⚡",
			"element": "Plasma",
			"desc": "Spend Charge to permanently boost Power — heals 3 HP per Charge consumed",
			"baseCooldown": 2,
			"isPlasmaAbility": true,
			"chargeCost": "variable",
			"execute": SPELL_CATALOGUE__energy_infusion__execute,
		},
		"plasma_shield": {
			"id": "plasma_shield",
			"tier": "primary",
			"name": "Plasma Shield",
			"emoji": "🛡️",
			"element": "Plasma",
			"desc": "Each Charge spent adds 1% damage reduction for the battle — heals 3 HP per Charge",
			"baseCooldown": 0,
			"isPlasmaAbility": true,
			"chargeCost": "variable",
			"execute": SPELL_CATALOGUE__plasma_shield__execute,
		},
		"self_sacrifice": {
			"id": "self_sacrifice",
			"tier": "secondary",
			"name": "Self Sacrifice",
			"emoji": "💉",
			"element": "Plasma",
			"desc": "Spend Charge to deal repeated self-damage — each hit generates Charge back",
			"baseCooldown": 0,
			"isPlasmaAbility": true,
			"chargeCost": "variable",
			"execute": SPELL_CATALOGUE__self_sacrifice__execute,
		},
		"borrowed_power": {
			"id": "borrowed_power",
			"tier": "secondary",
			"name": "Borrowed Power",
			"emoji": "⏳",
			"element": "Plasma",
			"desc": "Borrow 10 Charge immediately — owe heavy damage next turn for each unpaid",
			"baseCooldown": 0,
			"isPlasmaAbility": true,
			"chargeCost": 10,
			"execute": SPELL_CATALOGUE__borrowed_power__execute,
		},
		"plasma_stall": {
			"id": "plasma_stall",
			"tier": "secondary",
			"name": "Stall",
			"emoji": "🫧",
			"element": "Plasma",
			"desc": "Store all Charge and become immune this turn — regain it all next turn",
			"baseCooldown": 3,
			"isPlasmaAbility": true,
			"chargeCost": 0,
			"execute": SPELL_CATALOGUE__plasma_stall__execute,
		},
		"obliteration": {
			"id": "obliteration",
			"tier": "secondary",
			"name": "Obliteration",
			"emoji": "💀",
			"element": "Plasma",
			"desc": "Spend Charge as a barrage of hits — heals 3 HP per Charge, deals 2 hits per Charge",
			"baseCooldown": 0,
			"isPlasmaAbility": true,
			"chargeCost": "variable",
			"execute": SPELL_CATALOGUE__obliteration__execute,
		},
		"singularity": {
			"id": "singularity",
			"tier": "legendary",
			"name": "Singularity",
			"emoji": "🌌",
			"element": "Plasma",
			"desc": "Double the effects of your next Plasma ability this turn",
			"baseCooldown": 4,
			"isPlasmaAbility": true,
			"chargeCost": 0,
			"execute": SPELL_CATALOGUE__singularity__execute,
		},
		"quintuple_hit": {
			"id": "quintuple_hit",
			"tier": "primary",
			"name": "Quintuple Hit",
			"emoji": "💨",
			"element": "Air",
			"priority": 0,
			"desc": "Strike multiple times for 3 damage each. Each hit generates Momentum.",
			"baseCooldown": 0,
			"isStarter": true,
			"execute": SPELL_CATALOGUE__quintuple_hit__execute,
		},
		"become_wind": {
			"id": "become_wind",
			"tier": "primary",
			"name": "Become Wind",
			"emoji": "🌬️",
			"element": "Air",
			"priority": 1,
			"desc": "Gain Momentum. Your next successful dodge does not cause Momentum decay.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__become_wind__execute,
		},
		"wind_wall": {
			"id": "wind_wall",
			"tier": "primary",
			"name": "Wind Wall",
			"emoji": "🛡️",
			"element": "Air",
			"priority": 2,
			"desc": "Delay one instance of incoming damage until the next turn.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__wind_wall__execute,
		},
		"tornado": {
			"id": "tornado",
			"tier": "primary",
			"name": "Tornado",
			"emoji": "🌪️",
			"element": "Air",
			"priority": -1,
			"desc": "Deal damage to all enemies. Your next offensive Air ability becomes AoE.",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__tornado__execute,
		},
		"dynamic_drift": {
			"id": "dynamic_drift",
			"tier": "primary",
			"name": "Dynamic Drift",
			"emoji": "🔀",
			"element": "Air",
			"priority": 0,
			"desc": "Deal damage scaled by how far your priority has drifted from 0. Each cast shifts its own priority +1 or −1 based on when in your turn you use it.",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__dynamic_drift__execute,
		},
		"gust_forward": {
			"id": "gust_forward",
			"tier": "primary",
			"name": "Gust Forward",
			"emoji": "💨",
			"element": "Air",
			"priority": 0,
			"desc": "Instant — does not enter the queue. Choose +2 or −2: all spells you queue this turn gain that priority shift. One use per battle.",
			"baseCooldown": 32,
			"isFreeAction": true,
			"instantUse": true,
			"pickPriority": [{"label": "+2 (fast)", "value": 2}, {"label": "−2 (slow)", "value": -2}],
			"execute": SPELL_CATALOGUE__gust_forward__execute,
		},
		"twin_strike": {
			"id": "twin_strike",
			"tier": "secondary",
			"name": "Twin Strike",
			"emoji": "⚔️",
			"element": "Air",
			"priority": 1,
			"desc": "Strike multiple times for 1 damage each. Scales with Power. Does not consume an action.",
			"baseCooldown": 1,
			"isFreeAction": true,
			"execute": SPELL_CATALOGUE__twin_strike__execute,
		},
		"windy_takedown": {
			"id": "windy_takedown",
			"tier": "secondary",
			"name": "Windy Takedown",
			"emoji": "💥",
			"element": "Air",
			"priority": 0,
			"desc": "Powerful strike. No cooldown — use multiple times per turn.",
			"baseCooldown": 0,
			"multiUse": true,
			"execute": SPELL_CATALOGUE__windy_takedown__execute,
		},
		"sleeper_gust": {
			"id": "sleeper_gust",
			"tier": "secondary",
			"name": "Sleeper Gust",
			"emoji": "😴",
			"element": "Air",
			"priority": -1,
			"desc": "Hit twice for 1 damage each. Gain +1 action next turn per hit.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__sleeper_gust__execute,
		},
		"queue_slash": {
			"id": "queue_slash",
			"tier": "secondary",
			"name": "Queue Slash",
			"emoji": "⚡",
			"element": "Air",
			"priority": 0,
			"desc": "Deal damage plus a bonus for each point of total absolute priority in your other queued spells this turn.",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__queue_slash__execute,
		},
		"slipcut": {
			"id": "slipcut",
			"tier": "secondary",
			"name": "Slipcut",
			"emoji": "🌬️",
			"element": "Air",
			"priority": 0,
			"desc": "Deal damage. If you acted before all enemies (0 enemy actions before), consume 1 Momentum stack for +15 bonus damage.",
			"baseCooldown": 1,
			"execute": SPELL_CATALOGUE__slipcut__execute,
		},
		"wind_surge": {
			"id": "wind_surge",
			"tier": "secondary",
			"name": "Wind Surge",
			"emoji": "🌊",
			"element": "Air",
			"priority": 0,
			"desc": "Deal damage to all enemies. Choose +1 or −1 — all spells queued after this one this turn gain that priority shift.",
			"baseCooldown": 2,
			"pickPriority": [{"label": "+1 (faster)", "value": 1}, {"label": "−1 (slower)", "value": -1}],
			"undoOnQueue": SPELL_CATALOGUE__wind_surge__undoOnQueue,
			"execute": SPELL_CATALOGUE__wind_surge__execute,
		},
		"break_momentum": {
			"id": "break_momentum",
			"tier": "secondary",
			"name": "Break Momentum",
			"emoji": "💫",
			"element": "Air",
			"priority": 0,
			"desc": "Consume all Momentum. Deal 5 damage per Momentum stack.",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__break_momentum__execute,
		},
		"winds_end": {
			"id": "winds_end",
			"tier": "legendary",
			"element": "Air",
			"legendary": true,
			"name": "Wind's End",
			"emoji": "🌀",
			"desc": "This spell's priority mirrors your Dynamic Drift value. Deal AoE damage scaled by |drift| × Momentum stacks.",
			"baseCooldown": 4,
			"priority": 0,
			"execute": SPELL_CATALOGUE__winds_end__execute,
		},
		"absolute_zero": {
			"id": "absolute_zero",
			"tier": "legendary",
			"element": "Air",
			"legendary": true,
			"name": "Absolute Zero",
			"emoji": "❄️",
			"priority": 0,
			"desc": "Deal AoE damage based on the total absolute priority of every spell in your queue this turn. Zero the wind.",
			"baseCooldown": 5,
			"execute": SPELL_CATALOGUE__absolute_zero__execute,
		},
		"storm_rush": {
			"id": "storm_rush",
			"tier": "legendary",
			"name": "Storm Rush",
			"emoji": "⚡",
			"element": "Air",
			"priority": 0,
			"desc": "Gain 3 extra actions this turn. Gain 5 Momentum. Reduce all cooldowns by 1.",
			"baseCooldown": 4,
			"legendary": true,
			"onQueue": SPELL_CATALOGUE__storm_rush__onQueue,
			"undoOnQueue": SPELL_CATALOGUE__storm_rush__undoOnQueue,
			"execute": SPELL_CATALOGUE__storm_rush__execute,
		},
		"power_strike": {
			"id": "power_strike",
			"tier": "secondary",
			"name": "Power Strike",
			"emoji": "⚔️",
			"element": "Neutral",
			"desc": "Raw powerful strike that benefits greatly from Attack Power",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__power_strike__execute,
		},
		"double_tap": {
			"id": "double_tap",
			"tier": "secondary",
			"name": "Double Tap",
			"emoji": "👊",
			"element": "Neutral",
			"desc": "Two rapid strikes in quick succession",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__double_tap__execute,
		},
		"shield_bash": {
			"id": "shield_bash",
			"tier": "secondary",
			"name": "Shield Bash",
			"emoji": "🛡️",
			"element": "Neutral",
			"desc": "Grant armor then deal damage equal to armor granted. Defense scaling applies.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__shield_bash__execute,
		},
		"vampiric_strike": {
			"id": "vampiric_strike",
			"tier": "secondary",
			"name": "Vampiric Strike",
			"emoji": "🩸",
			"element": "Neutral",
			"desc": "Life-stealing strike — drain health from the target",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__vampiric_strike__execute,
		},
		"war_cry": {
			"id": "war_cry",
			"tier": "secondary",
			"name": "War Cry",
			"emoji": "📯",
			"element": "Neutral",
			"desc": "Battle cry — surge of Power for this fight",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__war_cry__execute,
		},
		"plasma_arc": {
			"id": "plasma_arc",
			"tier": "merged",
			"name": "Plasma Arc",
			"emoji": "⚡🔥",
			"element": "Lightning/Fire",
			"desc": "Deal Melt damage and load a Surge onto the target",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__plasma_arc__execute,
		},
		"superheated": {
			"id": "superheated",
			"tier": "merged",
			"name": "Superheated",
			"emoji": "🌡️⚡",
			"element": "Lightning/Fire",
			"desc": "Double target Burn stacks and instantly trigger Surge",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__superheated__execute,
		},
		"thunderroot": {
			"id": "thunderroot",
			"tier": "merged",
			"name": "Thunderroot",
			"emoji": "⚡🌿",
			"element": "Lightning/Nature",
			"desc": "Strike with lightning, load Surge, and root the target",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__thunderroot__execute,
		},
		"static_bloom": {
			"id": "static_bloom",
			"tier": "merged",
			"name": "Static Bloom",
			"emoji": "⚡🌸",
			"element": "Lightning/Nature",
			"desc": "Trigger all Seeds on the target. Apply 1 Shock per stack that bloomed.",
			"baseCooldown": 4,
			"execute": SPELL_CATALOGUE__static_bloom__execute,
		},
		"burning_grove": {
			"id": "burning_grove",
			"tier": "merged",
			"name": "Burning Grove",
			"emoji": "🔥🌱",
			"element": "Fire/Nature",
			"desc": "Apply Burn and plant a Damage Seed",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__burning_grove__execute,
		},
		"char_bloom": {
			"id": "char_bloom",
			"tier": "merged",
			"name": "Char Bloom",
			"emoji": "🔥🌸",
			"element": "Fire/Nature",
			"desc": "Consume all Burn on the target — plant a Damage Seed with stacks equal to Burn consumed ÷ 10",
			"baseCooldown": 3,
			"execute": SPELL_CATALOGUE__char_bloom__execute,
		},
		"storm_window": {
			"id": "storm_window",
			"tier": "merged",
			"name": "Storm Window",
			"emoji": "⚡💨",
			"element": "Air/Lightning",
			"desc": "Free action. If this is your 2nd+ action before any enemy acts, instantly trigger Surge. Otherwise load a Surge that scales with how many enemy actions preceded it.",
			"baseCooldown": 2,
			"isFreeAction": true,
			"priority": 0,
			"execute": SPELL_CATALOGUE__storm_window__execute,
		},
		"arc_load": {
			"id": "arc_load",
			"tier": "merged",
			"name": "Arc Load",
			"emoji": "💨⚡",
			"element": "Air/Lightning",
			"desc": "Deal lightning damage and apply Shock equal to your current Momentum stacks. Momentum is not consumed.",
			"baseCooldown": 3,
			"priority": 0,
			"execute": SPELL_CATALOGUE__arc_load__execute,
		},
		"windfall_seed": {
			"id": "windfall_seed",
			"tier": "merged",
			"name": "Windfall Seed",
			"emoji": "🌱💨",
			"element": "Air/Nature",
			"desc": "Plant a Momentum Seed on yourself (timer 3). While germinating, all your actions gain +1 priority. On bloom: +10 Momentum per stack.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__windfall_seed__execute,
		},
		"gale_bind": {
			"id": "gale_bind",
			"tier": "merged",
			"name": "Gale Bind",
			"emoji": "🌿💨",
			"element": "Air/Nature",
			"desc": "Free action. Convert 50% of your Momentum into Root stacks on the active enemy. Those Root stacks expire at the start of next round. Momentum is halved.",
			"baseCooldown": 2,
			"isFreeAction": true,
			"execute": SPELL_CATALOGUE__gale_bind__execute,
		},
		"afterburn": {
			"id": "afterburn",
			"tier": "merged",
			"name": "Afterburn",
			"emoji": "🔥💨",
			"element": "Air/Fire",
			"desc": "Free instant action. Burn ticks once before and once after all actions resolve this turn.",
			"baseCooldown": 2,
			"isFreeAction": true,
			"instantUse": true,
			"execute": SPELL_CATALOGUE__afterburn__execute,
		},
		"ember_flurry": {
			"id": "ember_flurry",
			"tier": "merged",
			"name": "Ember Flurry",
			"emoji": "🔥💨",
			"element": "Air/Fire",
			"desc": "Three rapid fire hits — each scales with Momentum, applies Burn, and generates Momentum.",
			"baseCooldown": 2,
			"execute": SPELL_CATALOGUE__ember_flurry__execute,
		},
	}
	NEUTRAL_SPELL_IDS = ["power_strike", "double_tap", "shield_bash", "vampiric_strike", "war_cry"]

# ── Plasma Charge Helpers ─────────────────────────────────────────────────────
func _plasmaSpend():
	# At execution time reserved is a planning artifact — use raw charge as ceiling
	return max(1, min(JS.or_(State.combat.get("plasmaCurrentSpend"), 1), JS.or_(State.status.player.get("plasmaCharge"), 0)))

func _plasmaConsumeHeal(amount = null, s = null):
	if amount <= 0:
		return
	State.status.player.plasmaCharge = max(0, State.status.player.plasmaCharge - amount)
	State.combat.plasmaChargeReserved = max(0, State.combat.plasmaChargeReserved - amount)
	var overMult = (1.5 if JS.t(State.combat.get("plasmaOvercharged")) else 1.0)
	# Reactive Field: only fires when NOT overcharged
	# When active: self-damage partially offsets the heal + damages all enemies
	# When overcharged: field goes dormant, you get full healing as reward
	if (Main.hasPassive("plasma_reactive_field") and not JS.t(State.combat.get("plasmaOvercharged"))):
		var selfDmg = amount * 5
		var reactDmg = amount * 5
		Hit.applyDirectDamage.call("enemy", "player", selfDmg, "💥 Reactive Sacrifice")
		for e in JS.iter(Helpers.aliveEnemies()):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, e))
			Hit.applyDirectDamage.call("player", "enemy", reactDmg, "💥 Reactive Field")
	# Heal (always — Reactive Field self-damage offsets it when not overcharged)
	var healPer = JS.round(3 * overMult)
	var totalHeal = healPer * amount
	if totalHeal > 0:
		Helpers.applyHeal("player", totalHeal, "🔮 Charge Heal (" + JS.s(amount) + "×" + JS.s(healPer) + ")")
	UI.renderStatusTags()
	updateChargeUI()

func _plasmaConsume(amount = null, s = null):
	if amount <= 0:
		JS.callm(s, "log", ["⚠ No Charge to spend!", "status"])
		return false
	# At execution time, reserved is a planning artifact — check raw charge
	if amount > State.status.player.plasmaCharge:
		JS.callm(s, "log", ["⚠ Not enough Charge (have " + JS.s(State.status.player.plasmaCharge) + ")", "status"])
		return false
	# Singularity: double amount
	if JS.t(State.status.player.get("singularityActive")):
		State.status.player.singularityActive = false
		amount = min(amount * 2, State.status.player.plasmaCharge)
		State.combat.plasmaCurrentSpend = floori(amount / 2.0)
		JS.callm(s, "log", ["🌌 Singularity! Charge doubled.", "status"])
	_plasmaConsumeHeal(amount, s)
	return true

func _plasmaChargeReserveAdjust(delta = null):
	State.combat.plasmaChargeReserved = max(0, (JS.or_(State.combat.get("plasmaChargeReserved"), 0)) + delta)

func updateChargeUI():
	var wrap_ = document.getElementById("plasma-charge-wrap")
	var bar = document.getElementById("plasma-charge-bar")
	var txt = document.getElementById("plasma-charge-txt")
	if not JS.t(wrap_):
		return
	if State.playerElement != "Plasma":
		wrap_.style.display = "none"
		return
	wrap_.style.display = "block"
	var cap = 20
	var c = JS.or_(State.status.player.get("plasmaCharge"), 0)
	if JS.t(bar):
		bar.style.width = JS.s(min(100, (c / float(cap)) * 100)) + "%"
		bar.style.background = ("#da70d6" if c >= cap else ("#a04ab0" if c >= 15 else "#6a2a8a"))
	if JS.t(txt):
		txt.textContent = "⚡ Charge: " + JS.s(c) + " / " + JS.s(cap) + (" ✦ OVERCHARGED" if JS.t(State.combat.get("plasmaOvercharged")) else "")

# ── Helpers ──────────────────────────────────────────────────────────────────
func giveStarterSpell():
	if State.playerElement == "Plasma":
		# Plasma starts with all primary abilities — check all books to avoid duplicates
		for s in JS.iter(JS.values(SPELL_CATALOGUE)):
			if (s.get("element") == "Plasma" and s.get("tier") == "primary"):
				var alreadyOwned = JS.some(JS.or_(State.player.get("spellbooks"), []), func(b = null): return JS.some(b.spells, func(x = null): return JS.eq(x.id, s.id)))
				if not alreadyOwned:
					addSpellById(s.id)

func addSpellById(id = null, skipBookCheck = null, rarity = null, bookIdx = null):
	var def = JS.idx(SPELL_CATALOGUE, id)
	if not JS.t(def):
		return null
	var rarityKey = JS.or_(rarity, "dim")
	var incantationLevel = (JS.idx(Incantations.SPELL_RARITY, rarityKey).level if (true and JS.t(JS.idx(Incantations.SPELL_RARITY, rarityKey))) else 1)
	var spell = JS.merge([def, {"currentCD": 0, "upgradeLevel": 0, "dmgMult": 1.0, "rarity": rarityKey, "incantationLevel": incantationLevel}])
	Library.markSpellSeen(id)
	if ((not JS.t(skipBookCheck) and JS.t(State.player.get("spellbooks"))) and JS.t(len(State.player.spellbooks))):
		State.addSpellToBook(spell, bookIdx)
	else:
		State.player.spellbook.append(spell)
	return spell

func addItem(id = null):
	State.player.inventory.append(JS.merge([JS.idx(Items.ITEM_CATALOGUE, id)]))

func removeItemAt(idx = null):
	JS.splice(State.player.inventory, idx, 1)

func SPELL_CATALOGUE__ignite__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ FIRE ══════════════════════════════════════
	var stacks = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	JS.callm(s, "hit", [{"baseDamage": 5, "effects": [{"type": "burn", "stacks": stacks}], "abilityElement": "Fire"}])
	JS.callm(s, "log", ["🔥 Ignite!", "player"])

func SPELL_CATALOGUE__ember_storm__execute(s = null):
	var this = JS._this
	var hits = 3 + JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	JS.callm(s, "hit", [{"baseDamage": 5, "hits": hits, "effects": [{"type": "burn", "stacks": 3}], "abilityElement": "Fire"}])
	JS.callm(s, "log", ["🔥 Ember Storm!", "player"])

func SPELL_CATALOGUE__flame_wave__execute(s = null):
	var this = JS._this
	var bonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9))
	var burn = 5 + bonus
	var dmg = 10 + bonus
	var _arr1 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr1)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [{"type": "burn", "stacks": burn}], "abilityElement": "Fire", "isAOE": true}])
	JS.callm(s, "log", ["🌊🔥 Flame Wave!", "player"])

func SPELL_CATALOGUE__firewall__execute(s = null):
	var this = JS._this
	var stacks = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	State.status.player.firewallStacks = (JS.or_(State.status.player.get("firewallStacks"), 0)) + stacks
	JS.callm(s, "log", ["🔥 Firewall raised! +" + JS.s(stacks) + " stacks", "player"])

func SPELL_CATALOGUE__grease_fire__execute(s = null):
	var this = JS._this
	# Secondary
	var burn = JS.round(4 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	State.status.enemy.burnStacks = (JS.or_(State.status.enemy.get("burnStacks"), 0)) + burn
	State.status.player.greasefirePending = true
	JS.callm(s, "log", ["🛢️ Grease Fire! +" + JS.s(burn) + " Burn, double burn tick next round", "player"])

func SPELL_CATALOGUE__extinguish__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	# Trigger enemy burn tick now
	if (JS.t(e) and e.status.burnStacks > 0):
		var tickDmg = JS.round(e.status.burnStacks * Helpers.burnDmgPerStack("player", Helpers.effectPowerFor("player")))
		Hit.applyDirectDamage.call("player", "enemy", tickDmg, "🔥 Burn (triggered)")
		if JS.t(State.combat.get("over")):
			return
	var eRemoved = (ceili((JS.or_(e.status.get("burnStacks"), 0)) / 2.0) if JS.t(e) else 0)
	var pRemoved = ceili((JS.or_(State.status.player.get("burnStacks"), 0)) / 2.0)
	if JS.t(e):
		e.status.burnStacks = max(0, (JS.or_(e.status.get("burnStacks"), 0)) - eRemoved)
	State.status.player.burnStacks = max(0, (JS.or_(State.status.player.get("burnStacks"), 0)) - pRemoved)
	var dmgMult = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var bonusDmg = ((eRemoved + pRemoved) * dmgMult) + JS.callm(s, "attackPow", [])
	if bonusDmg > 0:
		Hit.applyDirectDamage.call("player", "enemy", bonusDmg, "💧 Extinguish bonus")
	JS.callm(s, "log", ["💧 Extinguish! −" + JS.s(eRemoved) + " enemy burn, −" + JS.s(pRemoved) + " self burn, +" + JS.s(bonusDmg) + " dmg", "player"])

func SPELL_CATALOGUE__fire_heal__execute(s = null):
	var this = JS._this
	var total = Helpers.totalEnemyBurnStacks.call() + (JS.or_(State.status.player.get("burnStacks"), 0))
	var healPer = 1 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.2, 0.95)
	var healed = max(1, JS.round(total * healPer))
	JS.callm(s, "healSelf", [healed])
	JS.callm(s, "log", ["❤️‍🔥 Fire Heal: +" + JS.s(healed) + " HP from " + JS.s(total) + " burn stacks", "player"])

func SPELL_CATALOGUE__fire_rage__execute(s = null):
	var this = JS._this
	var total = Helpers.totalEnemyBurnStacks.call() + (JS.or_(State.status.player.get("burnStacks"), 0))
	var boost = floori(total / 2.0)
	var rageTurns = 1 + JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	State.status.player.rageBoostPow = boost
	State.status.player.rageBoostTurns = rageTurns
	JS.callm(s, "log", ["😤 Fire Rage! +" + JS.s(boost) + " Power for " + JS.s(rageTurns) + " turn" + ("s" if rageTurns > 1 else ""), "player"])

func SPELL_CATALOGUE__brave_burn__execute(s = null):
	var maxStacks = JS.arrMax(JS.arr(State.combat.enemies).map(func(e = null): return (JS.or_(e.status.get("burnStacks"), 0) if JS.t(e.get("alive")) else 0)))
	if maxStacks > 0:
		State.status.player.burnStacks = (JS.or_(State.status.player.get("burnStacks"), 0)) + maxStacks
		JS.callm(s, "log", ["🔥💀 Brave Burn! +" + JS.s(maxStacks) + " burn to self", "player"])
	var immuneTurns = 1
	State.status.player.debuffImmune = (JS.or_(State.status.player.get("debuffImmune"), 0)) + immuneTurns
	JS.callm(s, "log", ["🛡️ Debuff immune for " + JS.s(immuneTurns) + " turn" + ("s" if immuneTurns > 1 else ""), "player"])

func SPELL_CATALOGUE__melt_strike__execute(s = null):
	var this = JS._this
	# ──────────────────────── FIRE / MELT ────────────────────────────────────────
	# Melt is a secondary Fire damage type. applyMelt(attacker, target, pts, label)
	# strips armor at 3:1 cost (ceil(armor/3) pts to destroy all armor), then
	# remaining pts deal direct HP damage at 1:1 — bypasses shock and shields.
	var pts = floori((12 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	Hit.applyMelt.call("player", "enemy", pts, "⚒️ Melt Strike")
	JS.callm(s, "log", ["⚒️ Melt Strike!", "player"])

func SPELL_CATALOGUE__forge_blast__execute(s = null):
	var this = JS._this
	var pts = floori((8 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	var burn = JS.round(8 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9))
	Hit.applyMelt.call("player", "enemy", pts, "💥 Forge Blast")
	if JS.t(State.combat.get("over")):
		return
	JS.callm(s, "hit", [{"baseDamage": 0, "effects": [{"type": "burn", "stacks": burn}], "abilityElement": "Fire"}])
	JS.callm(s, "log", ["💥 Forge Blast! +" + JS.s(burn) + " Burn", "player"])

func SPELL_CATALOGUE__crucible__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var baseArmor = JS.or_(e.status.get("block"), 0)
	var armorMult = 2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.5, 0.9)
	var boosted = floori(baseArmor * armorMult)
	if boosted > 0:
		e.status._armorPeak = max(JS.or_(e.status.get("_armorPeak"), 0), boosted)
		e.status.block = boosted
		JS.callm(s, "log", ["🌡️ Crucible! Armor " + JS.s(baseArmor) + " → " + JS.s(boosted), "player"])
	var pts = floori((boosted * 0.5) + (JS.callm(s, "attackPow", []) * 0.25))
	if pts > 0:
		Hit.applyMelt.call("player", "enemy", pts, "🌡️ Crucible")
	else:
		JS.callm(s, "log", ["🌡️ Crucible — no armor to exploit.", "player"])

func SPELL_CATALOGUE__scorch_through__execute(s = null):
	var this = JS._this
	var pts = floori((8 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	var origTarget = State.combat.targetIdx
	var _arr2 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr2)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		Hit.applyMelt.call("player", "enemy", pts, "🌊 Scorch Through")
		if JS.t(State.combat.get("over")):
			continue
	if not JS.t(State.combat.get("over")):
		State.setActiveEnemy(origTarget)
	JS.callm(s, "log", ["🌊 Scorch Through! (" + JS.s(pts) + " Melt to all)", "player"])

func SPELL_CATALOGUE__slag__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var armorBefore = JS.or_(e.status.get("block"), 0)
	var pts = floori((6 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	Hit.applyMelt.call("player", "enemy", pts, "🔶 Slag")
	if JS.t(State.combat.get("over")):
		return
	var armorConsumed = armorBefore - (JS.or_(e.status.get("block"), 0))
	if (armorConsumed > 0 and not Main.hasPassive("fire_slag_trail")):
		# Slag Trail passive handles this globally; Slag spell does it independently
		e.status.burnStacks = (JS.or_(e.status.get("burnStacks"), 0)) + armorConsumed
		JS.callm(s, "log", ["🔶 Slag: +" + JS.s(armorConsumed) + " Burn from melted armor!", "player"])

func SPELL_CATALOGUE__heat_surge__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var pts = floori((16 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	var hpBefore = e.hp
	Hit.applyMelt.call("player", "enemy", pts, "❤️‍🔥 Heat Surge")
	if JS.t(State.combat.get("over")):
		return
	var hpDmg = max(0, hpBefore - (JS.or_(e.get("hp"), 0)))
	if hpDmg > 0:
		var healed = floori(hpDmg * 0.5)
		if healed > 0:
			JS.callm(s, "healSelf", [healed])
			JS.callm(s, "log", ["❤️‍🔥 Heat Surge: healed " + JS.s(healed) + " from " + JS.s(hpDmg) + " HP damage", "player"])

func SPELL_CATALOGUE__smelt__execute(s = null):
	var this = JS._this
	# Secondary Melt
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var pts = floori((8 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	var burn = JS.or_(e.status.get("burnStacks"), 0)
	if (burn > 0 and pts > 0):
		var burnCost = ceili(burn / 3.0)
		if pts >= burnCost:
			pts -= burnCost
			e.status.burnStacks = 0
			JS.callm(s, "log", ["⚗️ Smelt: burns out all " + JS.s(burn) + " Burn! (" + JS.s(burnCost) + " pts used, " + JS.s(pts) + " remain)", "player"])
		else:
			e.status.burnStacks = max(0, burn - (pts * 3))
			JS.callm(s, "log", ["⚗️ Smelt: chips " + JS.s(pts * 3) + " Burn (" + JS.s(e.status.burnStacks) + " remain)", "player"])
			pts = 0
	if pts > 0:
		Hit.applyMelt.call("player", "enemy", pts, "⚗️ Smelt")
	elif burn == 0:
		JS.callm(s, "log", ["⚗️ Smelt! (no Burn to convert)", "player"])

func SPELL_CATALOGUE__overheat__execute(s = null):
	var this = JS._this
	var selfBurn = JS.or_(State.status.player.get("burnStacks"), 0)
	if selfBurn > 0:
		State.status.player.burnStacks = 0
	var pts = floori((selfBurn + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5))
	JS.callm(s, "log", ["🌡️ Overheat! " + JS.s(selfBurn) + " Burn consumed → " + JS.s(pts) + " Melt pts", "player"])
	if pts > 0:
		Hit.applyMelt.call("player", "enemy", pts, "🌡️ Overheat")

func SPELL_CATALOGUE__crucible_burst__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var armor = JS.or_(e.status.get("block"), 0)
	var pts = (floori((30 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5)) if armor >= 15 else floori((10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9)) + (JS.callm(s, "attackPow", []) * 0.5)))
	JS.callm(s, "log", ["💥 Crucible Burst! " + ("Heavy" if armor >= 15 else "Light") + " armor — " + JS.s(pts) + " Melt pts", "player"])
	Hit.applyMelt.call("player", "enemy", pts, "💥 Crucible Burst")

func SPELL_CATALOGUE__molten_surge__execute(s = null):
	State.combat.meltDoubleTurn = true
	JS.callm(s, "log", ["🌋 Molten Surge! All Melt ×2 this turn.", "player"])

func SPELL_CATALOGUE__melt_down__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var armor = JS.or_(e.status.get("block"), 0)
	var mult = 1.5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.2, 0.9)
	var pts = null
	if armor > 0:
		e.status._armorPeak = max(JS.or_(e.status.get("_armorPeak"), 0), armor)
		pts = floori(armor * mult)
		# Trigger Meltdown legendary manually (bypassing applyMelt's armor path)
		if Main.hasPassive("fire_meltdown"):
			var peak = e.status._armorPeak
			pts += JS.round(peak)
			JS.callm(s, "log", ["🌋 Meltdown! +" + JS.s(JS.round(peak)) + " from peak armor!", "player"])
		e.status._armorPeak = 0
		e.status.block = 0
		JS.callm(s, "log", ["🫠 Melt Down! " + JS.s(armor) + " armor broken → " + JS.s(pts) + " Melt pts", "player"])
		# Slag Trail (manually, since block is already 0 when applyMelt runs)
		if Main.hasPassive("fire_slag_trail"):
			e.status.burnStacks = (JS.or_(e.status.get("burnStacks"), 0)) + armor
			JS.callm(s, "log", ["🔥 Slag Trail: +" + JS.s(armor) + " Burn from Melt Down!", "player"])
	else:
		pts = floori(12 + (JS.callm(s, "attackPow", []) * 0.5))
		JS.callm(s, "log", ["🫠 Melt Down! No armor — " + JS.s(pts) + " Melt", "player"])
	if pts > 0:
		Hit.applyMelt.call("player", "enemy", pts, "🫠 Melt Down")

func SPELL_CATALOGUE__temper__execute(s = null):
	State.combat.nextMeltDouble = true
	JS.callm(s, "log", ["⚔️ Temper! Next Melt hit ×2.", "player"])

func SPELL_CATALOGUE__white_heat__execute(s = null):
	# Legendary Melt
	var pts = floori(JS.callm(s, "attackPow", []) * 0.5)
	JS.callm(s, "log", ["🤍 White Heat! " + JS.s(pts) + " pure Melt", "player"])
	if pts > 0:
		Hit.applyMelt.call("player", "enemy", pts, "🤍 White Heat")

func SPELL_CATALOGUE__searing_verdict__execute(s = null):
	var kills = JS.or_(State._runKillsThisRun, 0)
	var pts = floori((15 + (kills * 3)) + (JS.callm(s, "attackPow", []) * 0.5))
	JS.callm(s, "log", ["⚖️ Searing Verdict! " + JS.s(kills) + " kills → " + JS.s(pts) + " Melt pts", "player"])
	Hit.applyMelt.call("player", "enemy", pts, "⚖️ Searing Verdict")

func SPELL_CATALOGUE__tidal_surge__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ WATER ══════════════════════════════════════
	JS.callm(s, "hit", [Helpers.applyFlowToWaterPkg({"baseDamage": 20, "effects": [], "abilityElement": "Water"})])
	var healBase = 10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9)
	JS.callm(s, "healSelf", [JS.round(healBase) + ceili(JS.callm(s, "defStat", []) / 2.0)])
	JS.callm(s, "log", ["💧 Tidal Surge!", "player"])

func SPELL_CATALOGUE__whirlpool__execute(s = null):
	var this = JS._this
	var foam = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var _arr3 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr3)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [Helpers.applyFlowToWaterPkg({"baseDamage": 25, "effects": [], "abilityElement": "Water", "isAOE": true, "apMult": 1.25})])
		Helpers.applyFoam("player", "enemy", foam)
	JS.callm(s, "log", ["🌀 Whirlpool! +" + JS.s(foam) + " Foam to all", "player"])

func SPELL_CATALOGUE__healing_tide__execute(s = null):
	var this = JS._this
	var amt = JS.round(40 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 8, 0.95))
	JS.callm(s, "healSelf", [amt])
	JS.callm(s, "log", ["💚 Healing Tide!", "player"])

func SPELL_CATALOGUE__riptide__execute(s = null):
	var this = JS._this
	var hits = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	JS.callm(s, "hit", [Helpers.applyFlowToWaterPkg({"baseDamage": 5, "hits": hits, "effects": [], "abilityElement": "Water", "apMult": 0.35})])
	JS.callm(s, "log", ["🌊 Riptide!", "player"])

func SPELL_CATALOGUE__drown__execute(s = null):
	var this = JS._this
	# Secondary
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	var foam = (JS.or_(e.status.get("foamStacks"), 0) if JS.t(e) else 0)
	# Adjust CD based on branch: override after the fact
	var self_ = JS.find(State.player.spellbook, func(sp = null): return sp.get("id") == "drown")
	if foam >= 6:
		if JS.t(self_):
			self_.currentCD = 3
		# big branch costs more
		State.status.enemy.stunned = max(JS.or_(State.status.enemy.get("stunned"), 0), 1)
		if ((JS.t(e) and Main.hasPassive("water_abyssal_pain")) and foam > 0):
			var reapply = floori(foam / 2.0)
			e.status.foamStacks = reapply
			var abyssalDmg = (reapply * 15) + JS.callm(s, "attackPow", [])
			if reapply > 0:
				Hit.applyDirectDamage.call("player", "enemy", abyssalDmg, "🌊 Abyssal Pain")
			JS.callm(s, "log", ["🌊 Drown stuns! Abyssal Pain: " + JS.s(reapply) + " Foam reapplied, " + JS.s(abyssalDmg) + " dmg", "player"])
		else:
			if JS.t(e):
				e.status.foamStacks = 0
			JS.callm(s, "log", ["🌊💀 Drown! Stunned + all Foam removed", "player"])
	else:
		if JS.t(self_):
			self_.currentCD = 1
		# cheap branch stays at CD1
		var foamAmt = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
		if JS.t(e):
			Helpers.applyFoam("player", "enemy", foamAmt)
		JS.callm(s, "log", ["🌊 Drown: +" + JS.s(foamAmt) + " Foam", "player"])

func SPELL_CATALOGUE__tidal_shield__execute(s = null):
	var this = JS._this
	var base = JS.round(20 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.95))
	var amt = base + floori(JS.callm(s, "defStat", []) / 2.0)
	Helpers.gainBlock("player", amt)
	State.status.player.tidalShieldActive = true
	JS.callm(s, "log", ["🌊🛡 Tidal Shield! +" + JS.s(amt) + " Armor, reactive active", "player"])

func SPELL_CATALOGUE__deep_current__execute(s = null):
	var this = JS._this
	var armor = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.95))
	State.status.player.deepCurrentActive = true
	if armor > 0:
		Helpers.gainBlock("player", armor)
	JS.callm(s, "log", ["💠 Deep Current — next Water spell fires twice!" + (" +" + JS.s(armor) + " Armor" if armor > 0 else ""), "player"])

func SPELL_CATALOGUE__cleanse_current__execute(s = null):
	var this = JS._this
	var healPer = JS.round(20 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.9))
	var n = Helpers.countPlayerDebuffs()
	Helpers.clearPlayerDebuffs()
	JS.callm(s, "healSelf", [n * healPer])
	JS.callm(s, "log", ["✨ Cleanse Current! " + JS.s(n) + " effects removed, +" + JS.s(n * healPer) + " HP", "player"])

func SPELL_CATALOGUE__tsunami__execute(s = null):
	var this = JS._this
	var dmgPerFoam = JS.round(10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	for e in JS.iter(Helpers.aliveEnemies()):
		var foam = JS.or_(e.status.get("foamStacks"), 0)
		if foam <= 0:
			continue
		var idx = JS.indexOf(State.combat.enemies, e)
		State.setActiveEnemy(idx)
		for i in range(ceili(foam)):
			if JS.t(State.combat.get("over")):
				continue
			Hit.applyDirectDamage.call("player", "enemy", dmgPerFoam, "🌊 Tsunami")
		if (not JS.t(State.combat.get("over")) and JS.callm(s, "attackPow", []) > 0):
			Hit.applyDirectDamage.call("player", "enemy", JS.callm(s, "attackPow", []), "🌊 Tsunami (Power)")
		if not JS.t(State.combat.get("over")):
			if Main.hasPassive("water_abyssal_pain"):
				var reapply = floori(foam / 2.0)
				e.status.foamStacks = reapply
				if reapply > 0:
					Hit.applyDirectDamage.call("player", "enemy", (reapply * 15) + JS.callm(s, "attackPow", []), "🌊 Abyssal Pain")
			else:
				e.status.foamStacks = 0
	if not JS.t(State.combat.get("over")):
		JS.callm(s, "log", ["🌊🌊 Tsunami! All Foam consumed", "player"])

func SPELL_CATALOGUE__frost_bolt__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ ICE ════════════════════════════════════════
	var frost = 2.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.4, 0.9)
	JS.callm(s, "hit", [{"baseDamage": 12, "effects": [], "abilityElement": "Ice"}])
	Helpers.applyFrost("player", "enemy", frost)
	JS.callm(s, "log", ["❄️ Frost Bolt!", "player"])

func SPELL_CATALOGUE__ice_block__execute(s = null):
	var this = JS._this
	var frost = 2.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.4, 0.9)
	State.status.player.phaseTurns = 1
	for e in JS.iter(Helpers.aliveEnemies()):
		var idx = JS.indexOf(State.combat.enemies, e)
		State.setActiveEnemy(idx)
		Helpers.applyFrost("player", "enemy", frost)
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	JS.callm(s, "log", ["🧊 Ice Block! Immune this round, " + JS.toFixed(frost, 1) + " Frost to all enemies", "player"])

func SPELL_CATALOGUE__glacial_spike__execute(s = null):
	var this = JS._this
	var dmg = JS.round(25 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 10, 0.95))
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Ice"}])
	Helpers.applyFrost("player", "enemy", 1)
	JS.callm(s, "log", ["🗡️ Glacial Spike!", "player"])

func SPELL_CATALOGUE__snowstorm__execute(s = null):
	var this = JS._this
	var frost = 2.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.4, 0.9)
	var _arr4 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr4)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": 8, "effects": [], "abilityElement": "Ice", "isAOE": true}])
		Helpers.applyFrost("player", "enemy", frost)
	JS.callm(s, "log", ["🌨️ Snowstorm!", "player"])

func SPELL_CATALOGUE__flash_freeze__execute(s = null):
	var this = JS._this
	# Secondary
	var frost = 5.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9)
	Helpers.applyFrost("player", "enemy", frost)
	JS.callm(s, "log", ["❄️❄️ Flash Freeze! +" + JS.toFixed(frost, 1) + " Frost", "player"])

func SPELL_CATALOGUE__shatter__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if not JS.t(e):
		return
	var stacks = floori(JS.or_(e.status.get("frostStacks"), 0))
	e.status.frostStacks = 0
	var mult = 4.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.5, 0.9)
	var dmg = JS.round(stacks * mult)
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Ice", "_noAtk": true}])
	JS.callm(s, "log", ["💎 Shatter! " + JS.s(stacks) + " Frost×" + JS.toFixed(mult, 2) + " = " + JS.s(dmg) + " dmg", "player"])

func SPELL_CATALOGUE__frozen_ground__execute(s = null):
	var this = JS._this
	var turns = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	State.status.player.frozenGroundTurns = turns
	JS.callm(s, "log", ["🌍❄️ Frozen Ground! " + JS.s(turns) + " rounds of frost", "player"])

func SPELL_CATALOGUE__cryostasis__execute(s = null):
	var this = JS._this
	var heal = JS.round(30 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 6, 0.95))
	State.status.player.stunned = max(JS.or_(State.status.player.get("stunned"), 0), 1)
	JS.callm(s, "healSelf", [heal])
	Helpers.gainBlock("player", 20)
	State.status.player.cryostasisActive = true
	JS.callm(s, "log", ["🧊💤 Cryostasis! +" + JS.s(heal) + " HP while frozen", "player"])

func SPELL_CATALOGUE__ice_age__execute(s = null):
	var this = JS._this
	var frostAmt = 5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9)
	for e in JS.iter(Helpers.aliveEnemies()):
		var idx = JS.indexOf(State.combat.enemies, e)
		State.setActiveEnemy(idx)
		var prev = JS.or_(e.status.get("frostStacks"), 0)
		Helpers.applyFrost("player", "enemy", frostAmt)
		# If this triggered a freeze, stun extra
		var frostWithPassive = frostAmt + (1 if Main.hasPassive("ice_stay_frosty") else 0)
		if (not JS.t(e.status.get("frozen")) and (prev + frostWithPassive) >= 10):
			e.status.stunned = (JS.or_(e.status.get("stunned"), 0)) + 1
		elif (JS.t(e.status.get("frozen")) and e.status.stunned <= 1):
			e.status.stunned = max(JS.or_(e.status.get("stunned"), 0), 2)
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	JS.callm(s, "log", ["❄️🌍 Ice Age! " + JS.toFixed(frostAmt, 1) + " Frost to all enemies", "player"])

func SPELL_CATALOGUE__zap__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ LIGHTNING ══════════════════════════════════
	var bonus = floori(JS.callm(s, "attackPow", []) / 10.0)
	var dmgBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9))
	JS.callm(s, "hit", [{"baseDamage": (25 + bonus) + dmgBonus, "effects": [], "abilityElement": "Lightning"}])
	if not JS.t(State.combat.get("over")):
		var shockBase = 2.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.4, 0.9)
		var shockAmt = shockBase
		if Main.hasPassive("lightning_conduction"):
			shockAmt += 1
		shockAmt += JS.or_(State.player.get("_talentShockBonus"), 0)
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			e.status.shockStacks = (JS.or_(e.status.get("shockStacks"), 0)) + shockAmt
			UI.log_("⚡ Shock +" + JS.toFixed(shockAmt, 1) + " (×" + JS.toFixed(e.status.shockStacks, 1) + ")", "status")
			Hit._plasmaChargeOnDebuff("enemy")
	JS.callm(s, "log", ["⚡ Zap!", "player"])

func SPELL_CATALOGUE__chain_lightning__execute(s = null):
	var this = JS._this
	var alive = Helpers.aliveEnemies()
	if not JS.t(len(alive)):
		return
	var maxBounces = JS.round(4 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	var hitSet = JSSet.new()
	var lastIdx = State.combat.activeEnemyIdx
	for i in range(ceili(maxBounces)):
		var unhit = JS.arr(alive).filter(func(e = null): return not hitSet.has(e))
		if not JS.t(len(unhit)):
			var remaining = maxBounces - i
			var stacksPerBounce = 1
			if Main.hasPassive("lightning_conduction"):
				stacksPerBounce += 1
			stacksPerBounce += JS.or_(State.player.get("_talentShockBonus"), 0)
			var shockToApply = remaining * stacksPerBounce
			var e = JS.idx(State.combat.enemies, lastIdx)
			if (JS.t(e) and JS.t(e.get("alive"))):
				e.status.shockStacks = (JS.or_(e.status.get("shockStacks"), 0)) + shockToApply
				UI.log_("⚡ Chain fizzles — +" + JS.s(shockToApply) + " Shock to " + JS.s(e.name) + "!", "status")
			break
		var target = JS.idx(unhit, floori(randf() * len(unhit)))
		hitSet.add(target)
		lastIdx = JS.indexOf(State.combat.enemies, target)
		State.setActiveEnemy(lastIdx)
		JS.callm(s, "hit", [{"baseDamage": 11, "effects": [], "abilityElement": "Lightning", "apMult": 1.25}])
		if JS.t(State.combat.get("over")):
			return
	JS.callm(s, "log", ["⚡⚡ Chain Lightning bounces!", "player"])

func SPELL_CATALOGUE__overcharge__execute(s = null):
	var this = JS._this
	var shock = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var powerBonus = JS.round(30 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	State.status.enemy.shockStacks = (JS.or_(State.status.enemy.get("shockStacks"), 0)) + shock
	State.status.player.overchargePowerPending = (JS.or_(State.status.player.get("overchargePowerPending"), 0)) + powerBonus
	JS.callm(s, "log", ["⚡💪 Overcharge! +" + JS.s(shock) + " Shock, +" + JS.s(powerBonus) + " Power next turn", "player"])

func SPELL_CATALOGUE__blitz__execute(s = null):
	# Secondary
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	var stacks = (JS.or_(e.status.get("shockStacks"), 0) if JS.t(e) else 0)
	if stacks > 0:
		var perStack = max(1, ceili(JS.callm(s, "attackPow", []) / 3.0))
		var dmg = stacks * perStack
		if JS.t(e):
			e.status.shockStacks = 0
		Hit.applyDirectDamage.call("player", "enemy", dmg, "💥 Blitz (" + JS.s(stacks) + " Shock)")
		JS.callm(s, "log", ["💥⚡ Blitz! " + JS.s(stacks) + "×" + JS.s(perStack) + " = " + JS.s(dmg) + " dmg", "player"])
	else:
		JS.callm(s, "log", ["💥 Blitz — no Shock to detonate", "player"])

func SPELL_CATALOGUE__recharge__execute(s = null):
	State.status.player.lightningMult = 2.0
	JS.callm(s, "log", ["🔋 Recharge! Overload reset to 200%", "player"])

func SPELL_CATALOGUE__electrocute__execute(s = null):
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if JS.t(e):
		var prev = JS.or_(e.status.get("shockStacks"), 0)
		e.status.shockStacks = JS.round(prev * 2)
		JS.callm(s, "log", ["☠️⚡ Electrocute! Shock ×2 (" + JS.s(e.status.shockStacks) + ")", "player"])
	Helpers.applySelfDamage(10, "☠️ Electrocute")

func SPELL_CATALOGUE__feedback__execute(s = null):
	var this = JS._this
	var shock = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var powerBonus = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9))
	State.status.enemy.shockStacks = (JS.or_(State.status.enemy.get("shockStacks"), 0)) + shock
	Helpers.applySelfDamage(5, "🔄 Feedback")
	State.status.player.overchargePowerPending = (JS.or_(State.status.player.get("overchargePowerPending"), 0)) + powerBonus
	JS.callm(s, "log", ["🔄⚡ Feedback! +" + JS.s(shock) + " Shock, 5 self dmg, +" + JS.s(powerBonus) + " Power next turn", "player"])

func SPELL_CATALOGUE__short_circuit__execute(s = null):
	var this = JS._this
	var alive = Helpers.aliveEnemies()
	if not JS.t(len(alive)):
		return
	var target = JS.idx(alive, floori(randf() * len(alive)))
	var tIdx = JS.indexOf(State.combat.enemies, target)
	State.setActiveEnemy(tIdx)
	# Randomly determine what action was "cancelled"
	var roll = randf()
	if roll < 0.33:
		# Buff action cancelled → player gains it (simulate as a power boost)
		var pow_ = floori(10 + (JS.callm(s, "effectPow", []) * 0.1))
		State.status.player.nextTurnPowerBonus = (JS.or_(State.status.player.get("nextTurnPowerBonus"), 0)) + pow_
		JS.callm(s, "log", ["💡 Short Circuit! Cancelled " + JS.s(target.name) + "'s buff — you gain +" + JS.s(pow_) + " Power next turn!", "player"])
	elif roll < 0.66:
		# Damage action cancelled → enemy hits themselves
		var selfDmg = JS.or_(target.get("enemyDmg"), 10)
		JS.callm(s, "log", ["💡 Short Circuit! " + JS.s(target.name) + "'s attack backfires — " + JS.s(selfDmg) + " self damage!", "player"])
		target.hp = max(0, target.hp - selfDmg)
		if target.hp <= 0:
			target.alive = false
			UI.log_("💀 " + JS.s(target.name) + " defeated by own attack!", "win")
			UI.renderEnemyCards()
			if (len(Helpers.aliveEnemies()) == 0 and not JS.t(State.combat.get("over"))):
				Combat.endBattle(true)
				return
		else:
			UI.renderEnemyCards()
	else:
		# Debuff cancelled → enemy applies it to themselves (simulate as stun)
		target.status.stunned = max(JS.or_(target.status.get("stunned"), 0), 1)
		JS.callm(s, "log", ["💡 Short Circuit! " + JS.s(target.name) + "'s debuff reflects — they are stunned!", "player"])
	# Also apply Shock to target regardless
	var _scShock = JS.round(1 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	target.status.shockStacks = (JS.or_(target.status.get("shockStacks"), 0)) + _scShock
	UI.renderEnemyCards()
	if (len(Helpers.aliveEnemies()) == 0 and not JS.t(State.combat.get("over"))):
		Combat.endBattle(true)

func SPELL_CATALOGUE__static_cleanse__execute(s = null):
	var n = Helpers.countPlayerDebuffs() + Helpers.countPlayerBuffs()
	Helpers.clearPlayerDebuffs()
	Helpers.clearPlayerBuffs()
	if n > 0:
		State.status.enemy.shockStacks = (JS.or_(State.status.enemy.get("shockStacks"), 0)) + (n * 2)
		JS.callm(s, "log", ["🧹⚡ Static Cleanse! " + JS.s(n) + " effects cleared → +" + JS.s(n * 2) + " Shock", "player"])
	else:
		JS.callm(s, "log", ["🧹 Static Cleanse — nothing to clear", "player"])

func SPELL_CATALOGUE__charge_shot__execute(s = null):
	State.status.player.chargeShotCharging = true
	JS.callm(s, "log", ["🎯⚡ Charge Shot charging — fires next round!", "player"])

func SPELL_CATALOGUE__bolt__execute(s = null):
	var this = JS._this
	# ── Lightning / Surge primaries ──────────────────────────────────────────────
	var surgeVal = JS.round(25 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9))
	var dmgBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	JS.callm(s, "hit", [{"baseDamage": 15 + dmgBonus, "effects": [], "abilityElement": "Lightning"}])
	if not JS.t(State.combat.get("over")):
		Surge._applySurge("enemy", surgeVal, "⚡ Bolt — Surge")
		JS.callm(s, "log", ["⚡ Bolt! Surge " + JS.s(surgeVal) + " loaded.", "player"])

func SPELL_CATALOGUE__thunder_strike__execute(s = null):
	var this = JS._this
	var shockAmt = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.5, 0.9))
	var dmgBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.9))
	JS.callm(s, "hit", [{"baseDamage": 35 + dmgBonus, "effects": [], "abilityElement": "Lightning"}])
	if not JS.t(State.combat.get("over")):
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			e.status.shockStacks = (JS.or_(e.status.get("shockStacks"), 0)) + shockAmt
			UI.log_("⚡ Thunder Strike! +" + JS.s(shockAmt) + " Shock (×" + JS.toFixed(e.status.shockStacks, 1) + ")", "status")
		JS.callm(s, "log", ["🌩️ Thunder Strike!", "player"])

func SPELL_CATALOGUE__ball_lightning__execute(s = null):
	var this = JS._this
	var surgeVal = JS.round(20 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.9))
	var dmgBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9))
	var _arr5 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr5)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": 10 + dmgBonus, "effects": [], "abilityElement": "Lightning", "isAOE": true}])
		if JS.t(State.combat.get("over")):
			continue
		Surge._applySurge("enemy", surgeVal, "🔮⚡ Ball Lightning — Surge")
	if not JS.t(State.combat.get("over")):
		JS.callm(s, "log", ["🔮⚡ Ball Lightning! Surge " + JS.s(surgeVal) + " on all enemies.", "player"])

func SPELL_CATALOGUE__static_charge__execute(s = null):
	var this = JS._this
	var surgeVal = JS.round(60 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 10, 0.9))
	Surge._applySurge("enemy", surgeVal, "⚡ Static Charge — Surge")
	JS.callm(s, "log", ["⚡🔋 Static Charge! Surge " + JS.s(surgeVal) + " loaded.", "player"])

func SPELL_CATALOGUE__megavolt__execute(s = null):
	var this = JS._this
	var bonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 8, 0.9))
	JS.callm(s, "hit", [{"baseDamage": 50 + bonus, "effects": [], "abilityElement": "Lightning"}])
	JS.callm(s, "log", ["💥⚡ Megavolt!", "player"])

func SPELL_CATALOGUE__supercharge__execute(s = null):
	var this = JS._this
	# ── Lightning / Surge secondaries ────────────────────────────────────────────
	var largeBon = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 10, 0.9))
	var smallBon = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9))
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	if JS.t(e.status.get("surgeActive")):
		e.status.surgeValue += 40 + smallBon
		JS.callm(s, "log", ["⚡⚡ Supercharge! Surge +" + JS.s(40 + smallBon) + " → " + JS.s(e.status.surgeValue), "player"])
	else:
		e.status.surgeActive = true
		e.status.surgeValue = 80 + largeBon
		e.status.surgeMeter = 0
		JS.callm(s, "log", ["⚡⚡ Supercharge! Surge " + JS.s(e.status.surgeValue) + " loaded.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__overclock__execute(s = null):
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	if JS.t(e.status.get("surgeActive")):
		e.status.surgeValue = JS.round(e.status.surgeValue * 2)
		JS.callm(s, "log", ["⏫⚡ Overclock! Surge doubled → " + JS.s(e.status.surgeValue), "player"])
	else:
		JS.callm(s, "log", ["⏫ Overclock — no Surge active to double", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__residual_current__execute(s = null):
	var this = JS._this
	var bonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 10, 0.9))
	var surgeVal = 30 + bonus
	if JS.t(State.combat.get("_surgeTriggeredThisTurn")):
		# Surge already fired this turn — apply immediately
		Surge._applySurge("enemy", surgeVal, "🔄⚡ Residual Current — Surge")
		JS.callm(s, "log", ["🔄⚡ Residual Current! Surge " + JS.s(surgeVal) + " applied.", "player"])
	else:
		# Register to fire when Surge triggers later this turn
		State.combat._residualCurrentPending = true
		State.combat._residualCurrentValue = surgeVal
		JS.callm(s, "log", ["🔄⚡ Residual Current primed — Surge " + JS.s(surgeVal) + " fires on next trigger.", "player"])

func SPELL_CATALOGUE__detonator__execute(s = null):
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	if JS.t(e.status.get("surgeActive")):
		JS.callm(s, "log", ["💣⚡ Detonator! Triggering Surge (" + JS.s(e.status.surgeValue) + " dmg)!", "player"])
		Surge._triggerSurge("enemy")
	else:
		JS.callm(s, "log", ["💣 Detonator — no Surge active to detonate", "player"])

func SPELL_CATALOGUE__grounded__execute(s = null):
	var this = JS._this
	var bonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var surgePerDebuff = 5 + bonus
	var n = Helpers.countPlayerDebuffs()
	Helpers.clearPlayerDebuffs()
	if n > 0:
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			if JS.t(e.status.get("surgeActive")):
				e.status.surgeValue += n * surgePerDebuff
				UI.log_("🌱⚡ Grounded! " + JS.s(n) + " debuffs cleared → Surge +" + JS.s(n * surgePerDebuff) + " (" + JS.s(e.status.surgeValue) + ")", "player")
			else:
				e.status.surgeActive = true
				e.status.surgeValue = n * surgePerDebuff
				e.status.surgeMeter = 0
				UI.log_("🌱⚡ Grounded! " + JS.s(n) + " debuffs cleared → Surge " + JS.s(e.status.surgeValue) + " loaded", "player")
			UI.renderStatusTags()
	else:
		JS.callm(s, "log", ["🌱 Grounded — no debuffs to clear", "player"])

func SPELL_CATALOGUE__thunderclap__execute(s = null):
	# ── Lightning / Surge legendaries ────────────────────────────────────────────
	var surgeVal = 100
	var _arr6 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr6)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": 60, "effects": [], "abilityElement": "Lightning", "isAOE": true}])
		if JS.t(State.combat.get("over")):
			continue
		Surge._applySurge("enemy", surgeVal, "🌩️ Thunderclap — Surge")
	if not JS.t(State.combat.get("over")):
		JS.callm(s, "log", ["🌩️💥 Thunderclap! Surge " + JS.s(surgeVal) + " on all enemies.", "player"])

func SPELL_CATALOGUE__fulgurite__execute(s = null):
	JS.callm(s, "hit", [{"baseDamage": 30, "effects": [], "abilityElement": "Lightning"}])
	if not JS.t(State.combat.get("over")):
		State.combat._surgeFulguriteMinus = (JS.or_(State.combat.get("_surgeFulguriteMinus"), 0)) + 5
		JS.callm(s, "log", ["🪨⚡ Fulgurite! Surge threshold now " + JS.s(Surge._getSurgeThreshold()) + ".", "player"])

func SPELL_CATALOGUE__seismic_wave__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ EARTH ══════════════════════════════════════
	JS.callm(s, "hit", [{"baseDamage": 20, "effects": [], "abilityElement": "Earth"}])
	if not JS.t(State.combat.get("over")):
		var stripAmt = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if JS.t(e):
			e.status.block = max(0, (JS.or_(e.status.get("block"), 0)) - stripAmt)
		State.status.player.block = (JS.or_(State.status.player.get("block"), 0)) + stripAmt
		JS.callm(s, "log", ["🌊🪨 Seismic Wave! Armor Strip −" + JS.s(stripAmt) + " enemy, +" + JS.s(stripAmt) + " yours", "player"])

func SPELL_CATALOGUE__fortify__execute(s = null):
	var this = JS._this
	var amt = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	Helpers.gainBlock("player", amt)
	State.status.player.fortifyPending = (JS.or_(State.status.player.get("fortifyPending"), 0)) + amt
	JS.callm(s, "log", ["🏰 Fortify! +" + JS.s(amt) + " Armor (converts to Stone at end of turn)", "player"])

func SPELL_CATALOGUE__echo_slam__execute(s = null):
	var this = JS._this
	var count = len(Helpers.aliveEnemies())
	var dmgBase = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.95))
	var dmgPerEnemy = dmgBase * count
	var _arr7 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr7)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmgPerEnemy, "effects": [], "abilityElement": "Earth", "isAOE": true}])
	JS.callm(s, "log", ["🌍 Echo Slam! " + JS.s(count) + " enemies × " + JS.s(dmgBase) + " = " + JS.s(dmgPerEnemy) + " each", "player"])

func SPELL_CATALOGUE__stone_stance__execute(s = null):
	var this = JS._this
	# Secondary
	var powBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9))
	State.status.player.stoneStanceThisTurn = true
	if powBonus > 0:
		State.status.player.battlePowerBonus = (JS.or_(State.status.player.get("battlePowerBonus"), 0)) + powBonus
		UI.updateStatsUI()
	JS.callm(s, "log", ["🪨💪 Stone Stance! Stone effects doubled this turn" + (" +" + JS.s(powBonus) + " Power" if powBonus > 0 else ""), "player"])

func SPELL_CATALOGUE__stone_sanctuary__execute(s = null):
	var this = JS._this
	var mult = 2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.5, 0.9)
	State.status.player.stoneStacks = JS.round((JS.or_(State.status.player.get("stoneStacks"), 0)) * mult)
	JS.callm(s, "log", ["🏔️ Stone Sanctuary! ×" + JS.toFixed(mult, 2) + " Stone (" + JS.s(State.status.player.stoneStacks) + ")", "player"])

func SPELL_CATALOGUE__earthshaker__execute(s = null):
	var this = JS._this
	var mult = 3.0 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.5, 0.9)
	var dmg = JS.round(JS.callm(s, "attackPow", []) * mult)
	Hit.applyDirectDamage.call("player", "enemy", dmg, "👊 Earthshaker")
	JS.callm(s, "log", ["👊🪨 Earthshaker! " + JS.s(dmg) + " dmg (" + JS.s(JS.callm(s, "attackPow", [])) + "×" + JS.toFixed(mult, 2) + ")", "player"])

func SPELL_CATALOGUE__dig__execute(s = null):
	var this = JS._this
	var amt = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	Helpers.clearPlayerDebuffs()
	Helpers.gainBlock("player", amt)
	Helpers.addStoneStacks("player", amt)
	JS.callm(s, "log", ["⛏️ Dig! Debuffs cleared, +" + JS.s(amt) + " Armor, +" + JS.s(amt) + " Stone", "player"])

func SPELL_CATALOGUE__cataclysm__execute(s = null):
	var this = JS._this
	var stacks = JS.or_(State.status.player.get("stoneStacks"), 0)
	State.status.player.stoneStacks = 0
	var perStack = JS.round(25 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9))
	var dmg = (stacks * perStack) + JS.callm(s, "attackPow", [])
	if dmg > 0:
		var _arr8 = JS.iter(Helpers.aliveEnemies())
		for i in range(len(_arr8)):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
			Hit.applyDirectDamage.call("player", "enemy", dmg, "💥 Cataclysm (" + JS.s(stacks) + " Stone)")
	JS.callm(s, "log", ["💥🪨 Cataclysm! " + JS.s(stacks) + " Stone × " + JS.s(perStack) + " = " + JS.s(dmg) + " dmg to all", "player"])

func SPELL_CATALOGUE__vine_strike__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ NATURE ══════════════════════════════════════
	var hits = 3 + JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	for i in range(ceili(hits)):
		if JS.t(State.combat.get("over")):
			return
		JS.callm(s, "hit", [{"baseDamage": 5, "effects": [], "abilityElement": "Nature", "apMult": 0.75}])
		if (not JS.t(State.combat.get("over")) and randf() < 0.5):
			Helpers.applyRoot("player", "enemy", 1)
	JS.callm(s, "log", ["🌿 Vine Strike!", "player"])

func SPELL_CATALOGUE__thornwall__execute(s = null):
	var this = JS._this
	var root = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	var armor = JS.round(30 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.9))
	Helpers.gainBlock("player", armor)
	Helpers.applyRoot("player", "enemy", root)
	JS.callm(s, "log", ["🌵 Thornwall! +" + JS.s(armor) + " Armor, +" + JS.s(root) + " Root", "player"])

func SPELL_CATALOGUE__natures_call__execute(s = null):
	var this = JS._this
	if len(State.combat.summons) >= 4:
		JS.callm(s, "log", ["🌳 Max summons reached!", "status"])
		return
	var isLegendary = Main.hasPassive("nature_verdant_legion")
	var hpBase = (50 if isLegendary else 25) + JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.95))
	var hp = hpBase + (JS.or_(State.player.get("_talentTreantHP"), 0))
	var dmgBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	State.combat._treantDmgBonus = max(JS.or_(State.combat.get("_treantDmgBonus"), 0), dmgBonus)
	var dmg = (15 if isLegendary else 5) + (JS.or_(State.combat.get("_treantDmgBonus"), 0))
	State.combat.summons.append({
		"name": "Treant",
		"emoji": "🌳",
		"hp": hp,
		"maxHP": hp,
		"dmg": dmg,
		"cd": 0,
		"rootChance": (1.0 if isLegendary else 0.5),
		"id": JS.dateNow() + randf(),
	})
	JS.callm(s, "log", ["🌳 A Treant rises! (" + JS.s(hp) + " HP, " + JS.s(dmg) + " dmg)", "player"])
	UI.renderSummonsRow()

func SPELL_CATALOGUE__bramble_burst__execute(s = null):
	var this = JS._this
	var dmg = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 8, 0.9))
	var _arr9 = JS.iter(Helpers.aliveEnemies())
	for i in range(len(_arr9)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Nature", "isAOE": true}])
		if (not JS.t(State.combat.get("over")) and randf() < 0.5):
			Helpers.applyRoot("player", "enemy", 1)
	JS.callm(s, "log", ["🌵💥 Bramble Burst!", "player"])

func SPELL_CATALOGUE__wild_growth__execute(s = null):
	# Secondary
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if JS.t(e):
		e.status.rootStacks = JS.round((JS.or_(e.status.get("rootStacks"), 0)) * 2)
		JS.callm(s, "log", ["🌿🌿 Wild Growth! Root ×2 (" + JS.s(e.status.rootStacks) + ")", "player"])

func SPELL_CATALOGUE__living_forest__execute(s = null):
	var alive = Helpers.aliveEnemies()
	if (not JS.t(len(alive)) or not JS.t(len(State.combat.summons))):
		JS.callm(s, "log", ["🌲 No Treants to command!", "player"])
		return
	var attacks = 2
	for t in JS.iter(State.combat.summons):
		if t.hp <= 0:
			continue
		for i in range(ceili(attacks)):
			var target = JS.idx(alive, floori(randf() * len(alive)))
			var idx = JS.indexOf(State.combat.enemies, target)
			State.setActiveEnemy(idx)
			Hit.applyDirectDamage.call("player", "enemy", t.dmg, "🌲 " + JS.s(t.name))
			if (not JS.t(State.combat.get("over")) and randf() < t.rootChance):
				Helpers.applyRoot("player", "enemy", 1)
			if JS.t(State.combat.get("over")):
				continue
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	JS.callm(s, "log", ["🌲 Living Forest! All treants strike " + JS.s(attacks) + "×", "player"])

func SPELL_CATALOGUE__spreading_vines__execute(s = null):
	var this = JS._this
	var turns = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	State.status.player.spreadingVinesTurns = turns
	JS.callm(s, "log", ["🌿🌍 Spreading Vines! " + JS.s(turns) + " rounds of root to all", "player"])

func SPELL_CATALOGUE__nourish__execute(s = null):
	var this = JS._this
	var heal = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	var dmgGain = JS.round(3 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	for t in JS.iter(State.combat.summons):
		t.maxHP += heal
		t.hp = min(t.maxHP, t.hp + heal)
		t.dmg += dmgGain
	Helpers.gainBlock("player", 1)
	UI.renderSummonsRow()
	JS.callm(s, "log", ["💚🌳 Nourish! Treants +" + JS.s(heal) + " HP and strengthened", "player"])

func SPELL_CATALOGUE__natures_wrath__execute(s = null):
	var perStack = 20
	for e in JS.iter(Helpers.aliveEnemies()):
		var idx = JS.indexOf(State.combat.enemies, e)
		State.setActiveEnemy(idx)
		var stacks = (JS.or_(e.status.get("rootStacks"), 0)) + (JS.or_(e.status.get("overgrowthStacks"), 0))
		e.status.rootStacks = 0
		e.status.overgrowthStacks = 0
		var dmg = (stacks * perStack) + JS.callm(s, "attackPow", [])
		if dmg > 0:
			Hit.applyDirectDamage.call("player", "enemy", dmg, "🌿 Nature's Wrath (" + JS.s(stacks) + "×" + JS.s(perStack) + ")")
		if JS.t(State.combat.get("over")):
			continue
	if not JS.t(State.combat.get("over")):
		JS.callm(s, "log", ["🌿💥 Nature's Wrath! All Root consumed", "player"])

func SPELL_CATALOGUE__damage_seed__execute(s = null):
	var this = JS._this
	# ──────────────────────── NATURE / SEEDS ────────────────────────────────────
	# Seeds are planted with a 3-turn germination timer. Stacking the same type
	# adds stacks without resetting the timer. All stacks bloom simultaneously.
	# Eternal Garden: each stack has an independent timer.
	# Primary Seed spells
	var surgeUsed = Seeds._plantSeed("enemy", "damage", 1, 3, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🌱 Damage Seed planted!", "player"])
	if JS.t(surgeUsed):
		this.currentCD = 0
		JS.callm(s, "log", ["⚡ Seed Surge: free cast +2 stacks!", "status"])

func SPELL_CATALOGUE__root_seed__execute(s = null):
	var this = JS._this
	var surgeUsed = Seeds._plantSeed("enemy", "root", 1, 3, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🌱 Root Seed planted!", "player"])
	if JS.t(surgeUsed):
		this.currentCD = 0
		JS.callm(s, "log", ["⚡ Seed Surge: free cast +2 stacks!", "status"])

func SPELL_CATALOGUE__silence_seed__execute(s = null):
	var this = JS._this
	var surgeUsed = Seeds._plantSeed("enemy", "silence", 1, 3, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🤫 Silence Seed planted!", "player"])
	if JS.t(surgeUsed):
		this.currentCD = 0
		JS.callm(s, "log", ["⚡ Seed Surge: free cast!", "status"])

func SPELL_CATALOGUE__armor_seed__execute(s = null):
	var this = JS._this
	var surgeUsed = Seeds._plantSeed("player", "armor", 1, 3, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🛡️ Armor Seed planted on yourself!", "player"])
	if JS.t(surgeUsed):
		this.currentCD = 0
		JS.callm(s, "log", ["⚡ Seed Surge: free cast +2 stacks!", "status"])

func SPELL_CATALOGUE__accelerate__execute(s = null):
	# Secondary Seed spells
	Seeds._accelerateSeeds(1)
	JS.callm(s, "log", ["⚡ Accelerate! All Seed timers −1.", "player"])

func SPELL_CATALOGUE__overgrow__execute(s = null):
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	if (not JS.t(e.status.get("seeds")) or not JS.t(len(e.status.seeds))):
		JS.callm(s, "log", ["🌿 Overgrow: no Seeds on target.", "player"])
		return
	for seed_ in JS.iter(e.status.seeds):
		seed_.stacks = seed_.stacks * 2
	JS.callm(s, "log", ["🌿 Overgrow! All Seeds on " + JS.s(e.name) + " ×2.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__cross_pollinate__execute(s = null):
	var copied = [null]
	var enemies = Helpers.aliveEnemies()
	if len(enemies) < 2:
		JS.callm(s, "log", ["🌼 Cross Pollinate: need 2+ alive enemies.", "player"])
		return
	var source = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if ((not JS.t(source) or not JS.t(source.status.get("seeds"))) or not JS.t(len(source.status.seeds))):
		JS.callm(s, "log", ["🌼 Cross Pollinate: no Seeds on target.", "player"])
		return
	copied[0] = 0
	for e in JS.iter(enemies):
		if JS.eq(e, source):
			continue
		if not JS.t(e.status.get("seeds")):
			e.status.seeds = []
		for seed_ in JS.iter(source.status.seeds):
			e.status.seeds.append(JS.merge([seed_]))
			copied[0] += 1
	JS.callm(s, "log", ["🌼 Cross Pollinate! " + JS.s(copied[0]) + " Seed" + ("s" if copied[0] != 1 else "") + " copied to " + JS.s(len(enemies) - 1) + " other enem" + ("ies" if (len(enemies) - 1) != 1 else "y") + ".", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__seed_surge__execute(s = null):
	State.combat._seedSurgePending = true
	State.combat._seedSurgeBonus = 2
	JS.callm(s, "log", ["💥 Seed Surge! Next Seed: free cast +2 stacks.", "player"])

func SPELL_CATALOGUE__deep_soil__execute(s = null):
	var this = JS._this
	var count = [null]
	var bonusStacks = JS.round(1 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	count[0] = 0
	for e in JS.iter(State.combat.enemies):
		if (not JS.t(e.get("alive")) or not JS.t(e.status.get("seeds"))):
			continue
		for seed_ in JS.iter(e.status.seeds):
			seed_.timer = 4
			seed_.stacks += bonusStacks
			count[0] += 1
	if JS.t(State.status.player.get("seeds")):
		for seed_ in JS.iter(State.status.player.seeds):
			seed_.timer = 4
			seed_.stacks += bonusStacks
			count[0] += 1
	JS.callm(s, "log", ["🌍 Deep Soil! " + JS.s(count[0]) + " Seed" + ("s" if count[0] != 1 else "") + " reset to 4t, each +" + JS.s(bonusStacks) + " stack" + ("s" if bonusStacks != 1 else "") + ".", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__reap__execute(s = null):
	var results = []
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	# Enemy seeds
	if (((JS.t(e) and JS.t(e.get("alive"))) and JS.t(e.status.get("seeds"))) and JS.t(len(e.status.seeds))):
		var consumed = JS.arr(e.status.seeds)
		e.status.seeds = []
		for seed_ in JS.iter(consumed):
			if JS.t(State.combat.get("over")):
				continue
			Seeds._bloomSeed("enemy", seed_, State.combat.activeEnemyIdx, {"powerMult": 0.5})
			results.append(JS.s(Seeds._seedLabel(seed_.type)) + " ×" + JS.s(seed_.stacks))
	# Player seeds
	if ((not JS.t(State.combat.get("over")) and JS.t(State.status.player.get("seeds"))) and JS.t(len(State.status.player.seeds))):
		var consumed = JS.arr(State.status.player.seeds)
		State.status.player.seeds = []
		for seed_ in JS.iter(consumed):
			if JS.t(State.combat.get("over")):
				continue
			Seeds._bloomSeed("player", seed_, null, {"powerMult": 0.5})
			results.append(JS.s(Seeds._seedLabel(seed_.type)) + " ×" + JS.s(seed_.stacks))
	JS.callm(s, "log", ["🌾 Reap! " + (JS.or_(JS.join(results, ", "), "no Seeds")) + " (weakened)", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__bloom_storm__execute(s = null):
	var anySeeds = [null]
	# Legendary Seed spells
	var prevActive = State.combat.activeEnemyIdx
	anySeeds[0] = false
	var _arr10 = JS.iter(State.combat.enemies)
	for i in range(len(_arr10)):
		var e = _arr10[i]
		if ((not JS.t(e.get("alive")) or not JS.t(e.status.get("seeds"))) or not JS.t(len(e.status.seeds))):
			continue
		anySeeds[0] = true
		var toBloom = JS.arr(e.status.seeds)
		e.status.seeds = []
		State.setActiveEnemy(i)
		for seed_ in JS.iter(toBloom):
			if not JS.t(State.combat.get("over")):
				Seeds._bloomSeed("enemy", JS.merge([seed_]), i)
	State.setActiveEnemy(prevActive)
	JS.callm(s, "log", [("🌺 Bloom Storm! All enemy Seeds germinate!" if anySeeds[0] else "🌺 Bloom Storm! No enemy Seeds active."), "player"])

func SPELL_CATALOGUE__world_tree__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var il = JS.or_(this.get("incantationLevel"), 1)
	Seeds._plantSeed("enemy", "damage", 2, 5, {"incantLevel": il})
	Seeds._plantSeed("enemy", "root", 2, 5, {"incantLevel": il})
	Seeds._plantSeed("enemy", "silence", 2, 5, {"incantLevel": il})
	# 2 separate Silence Seeds
	Seeds._plantSeed("player", "armor", 2, 5, {"incantLevel": il})
	JS.callm(s, "log", ["🌳 World Tree! All 4 Seed types planted (×2 each, Armor on you).", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__plasma_lance__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ PLASMA ══════════════════════════════════════
	# Plasma abilities do NOT consume actions — they consume Charge.
	# Each has isPlasmaAbility:true so the UI queues them separately.
	# chargeCost: fixed cost OR 'variable' (uses combat.plasmaSpendAmount)
	var spend = _plasmaSpend()
	if not _plasmaConsume(spend, s):
		return
	var dmgPerCharge = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var dmg = ((spend * dmgPerCharge) + JS.callm(s, "attackPow", [])) + JS.callm(s, "effectPow", [])
	var tgt = State.combat.targetIdx
	State.setActiveEnemy(tgt)
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Plasma", "_noAtk": true}])
	Hit.applyDirectDamage.call("enemy", "player", 1, "🔮 Recoil")
	JS.callm(s, "log", ["🔮 Plasma Lance! " + JS.s(spend) + " Charge × " + JS.s(dmgPerCharge) + " → " + JS.s(dmg) + " dmg", "player"])

func SPELL_CATALOGUE__energy_infusion__execute(s = null):
	var this = JS._this
	var spend = _plasmaSpend()
	if not _plasmaConsume(spend, s):
		return
	var powPerCharge = 1 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.5, 0.9)
	var gained = JS.round(spend * powPerCharge)
	State.status.player.battlePowerBonus = (JS.or_(State.status.player.get("battlePowerBonus"), 0)) + gained
	JS.callm(s, "log", ["⚡ Energy Infusion! " + JS.s(spend) + " Charge → +" + JS.s(gained) + " Power (total bonus: +" + JS.s(State.status.player.battlePowerBonus) + ")", "player"])
	UI.updateStatsUI()

func SPELL_CATALOGUE__plasma_shield__execute(s = null):
	var this = JS._this
	var spend = _plasmaSpend()
	if not _plasmaConsume(spend, s):
		return
	var mult = (1.5 if JS.t(State.combat.get("plasmaOvercharged")) else 1)
	var pctPerCharge = 1 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.2, 0.9)
	var pct = min(75, JS.round((spend * mult) * pctPerCharge))
	State.status.player.plasmaShieldReduction = min(75, (JS.or_(State.status.player.get("plasmaShieldReduction"), 0)) + pct)
	JS.callm(s, "log", ["🛡️ Plasma Shield! " + JS.s(spend) + " Charge → " + JS.s(pct) + "% dmg reduction (" + JS.s(State.status.player.plasmaShieldReduction) + "% total)", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__self_sacrifice__execute(s = null):
	var this = JS._this
	var spend = _plasmaSpend()
	if spend <= 0:
		return
	# Consume charge WITHOUT healing (it's a sacrifice)
	if State.status.player.plasmaCharge < spend:
		JS.callm(s, "log", ["Not enough Charge!", "status"])
		return
	State.status.player.plasmaCharge -= spend
	_plasmaChargeReserveAdjust(-spend)
	# damage instances per charge consumed — each generates Charge naturally
	var hitsPerCharge = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	for i in range(ceili(spend * hitsPerCharge)):
		if JS.t(State.combat.get("over")):
			return
		Hit.applyDirectDamage.call("enemy", "player", 5, "💉 Self Sacrifice")
	JS.callm(s, "log", ["💉 Self Sacrifice! " + JS.s(spend) + " Charge → " + JS.s(spend * hitsPerCharge) + " hits of 5 self-dmg", "player"])

func SPELL_CATALOGUE__borrowed_power__execute(s = null):
	var this = JS._this
	var borrow = JS.round(10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 1.0))
	State.status.player.plasmaCharge += borrow
	State.status.player.borrowedCharge = (JS.or_(State.status.player.get("borrowedCharge"), 0)) + borrow
	_plasmaConsumeHeal(0, s)
	# No charge consumed, no heal — just a log
	JS.callm(s, "log", ["⏳ Borrowed Power! +" + JS.s(borrow) + " Charge now. " + JS.s(borrow * 50) + " dmg next turn if unpaid.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__plasma_stall__execute(s = null):
	var this = JS._this
	var stored = State.status.player.plasmaCharge
	State.status.player.stallCharge = stored
	State.status.player.stallActive = true
	State.status.player.plasmaCharge = 0
	State.combat.plasmaChargeReserved = 0
	var powGained = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	if powGained > 0:
		State.status.player.battlePowerBonus = (JS.or_(State.status.player.get("battlePowerBonus"), 0)) + powGained
		UI.updateStatsUI()
	JS.callm(s, "log", ["🫧 Stall! " + JS.s(stored) + " Charge stored. Immune this turn. Regain next turn." + (" +" + JS.s(powGained) + " Power" if powGained > 0 else ""), "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__obliteration__execute(s = null):
	var this = JS._this
	var spend = _plasmaSpend()
	if not _plasmaConsume(spend, s):
		return
	var baseDmg = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 0.9))
	var hitDmg = (baseDmg + JS.callm(s, "attackPow", [])) + JS.callm(s, "effectPow", [])
	var totalHits = spend * 2
	var tgt = State.combat.targetIdx
	for i in range(ceili(spend)):
		if JS.t(State.combat.get("over")):
			return
		State.setActiveEnemy(tgt)
		JS.callm(s, "hit", [{"baseDamage": hitDmg, "effects": [], "hits": 2, "abilityElement": "Plasma", "_noAtk": true}])
	JS.callm(s, "log", ["💀 Obliteration! " + JS.s(spend) + " Charge → " + JS.s(totalHits) + " hits", "player"])

func SPELL_CATALOGUE__singularity__execute(s = null):
	var this = JS._this
	var bonusCharge = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	State.status.player.singularityActive = true
	if bonusCharge > 0:
		State.status.player.plasmaCharge = (JS.or_(State.status.player.get("plasmaCharge"), 0)) + bonusCharge
	JS.callm(s, "log", ["🌌 Singularity! Next Plasma ability has doubled effects." + (" +" + JS.s(bonusCharge) + " Charge" if bonusCharge > 0 else ""), "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__quintuple_hit__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ AIR ════════════════════════════════════════
	# Helper: applies s.hit with optional Tornado AoE expansion
	# ── Primary ──────────────────────────────────────────────────────────────────
	var hits = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	if JS.t(State.status.player.get("tornadoAoENext")):
		State.status.player.tornadoAoENext = false
		UI.log_("🌪️ Tornado boost — AoE!", "status")
		var _arr11 = JS.iter(Helpers.aliveEnemies())
		for i in range(len(_arr11)):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
			JS.callm(s, "hit", [{"baseDamage": 3, "effects": [], "hits": hits, "abilityElement": "Air", "apMult": 0.3}])
		if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
			State.setActiveEnemy(State.combat.targetIdx)
	else:
		JS.callm(s, "hit", [{"baseDamage": 3, "effects": [], "hits": hits, "abilityElement": "Air", "apMult": 0.3}])
	JS.callm(s, "log", ["💨 Quintuple Hit!", "player"])

func SPELL_CATALOGUE__become_wind__execute(s = null):
	var this = JS._this
	var gain = JS.round(10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	Helpers.addMomentumStacks(gain)
	State.status.player.momentumNoDecayNext = true
	JS.callm(s, "log", ["🌬️ Become Wind! +" + JS.s(gain) + " Momentum (×" + JS.toFixed(State.status.player.momentumStacks, 1) + "). Next dodge: no decay.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__wind_wall__execute(s = null):
	var this = JS._this
	var armor = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 8, 0.95))
	State.status.player.windWallActive = true
	if armor > 0:
		Helpers.gainBlock("player", armor)
	JS.callm(s, "log", ["🛡️ Wind Wall! Next incoming hit delayed to next turn." + (" +" + JS.s(armor) + " Armor" if armor > 0 else ""), "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__tornado__execute(s = null):
	var this = JS._this
	var dmg = JS.round(10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	var alive = Helpers.aliveEnemies()
	var _arr12 = JS.iter(alive)
	for i in range(len(_arr12)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air", "_isTornadoSelf": true}])
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	if not JS.t(State.combat.get("over")):
		State.status.player.tornadoAoENext = true
	JS.callm(s, "log", ["🌪️ Tornado! All enemies hit. Next Air attack is AoE.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__dynamic_drift__execute(s = null):
	var this = JS._this
	var cur = JS.nn(this.get("_battlePriority"), 0)
	var dmg = JS.round((10 + (abs(cur) * 15)) + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air"}])
	if not JS.t(State.combat.get("over")):
		var idx = JS.or_(State.combat.get("_playerActionIdx"), 1)
		var total = max(1, JS.or_(State.combat.get("_playerActionsTotal"), 1))
		var isFirstHalf = idx <= ceili(total / 2.0)
		var shift = (1 if isFirstHalf else -1)
		var next = cur + shift
		this._battlePriority = next
		this.priority = next
		var sign_ = ("+" if next >= 0 else "")
		JS.callm(s, "log", ["🔀 Dynamic Drift! " + JS.s(dmg) + " dmg. Priority → " + sign_ + JS.s(next) + " (" + ("early cast ↑" if isFirstHalf else "late cast ↓") + ")", "player"])
		UI.renderStatusTags()

func SPELL_CATALOGUE__gust_forward__execute(s = null):
	JS.callm(s, "log", ["💨 Gust Forward!", "player"])

func SPELL_CATALOGUE__twin_strike__execute(s = null):
	var this = JS._this
	# ── Secondary ─────────────────────────────────────────────────────────────────
	var hits = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	if JS.t(State.status.player.get("tornadoAoENext")):
		State.status.player.tornadoAoENext = false
		UI.log_("🌪️ Tornado boost — AoE!", "status")
		var _arr13 = JS.iter(Helpers.aliveEnemies())
		for i in range(len(_arr13)):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
			JS.callm(s, "hit", [{"baseDamage": 1, "effects": [], "hits": hits, "abilityElement": "Air"}])
		if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
			State.setActiveEnemy(State.combat.targetIdx)
	else:
		JS.callm(s, "hit", [{"baseDamage": 1, "effects": [], "hits": hits, "abilityElement": "Air"}])
	JS.callm(s, "log", ["⚔️ Twin Strike!", "player"])

func SPELL_CATALOGUE__windy_takedown__execute(s = null):
	var this = JS._this
	var dmg = JS.round(25 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.95))
	if JS.t(State.status.player.get("tornadoAoENext")):
		State.status.player.tornadoAoENext = false
		UI.log_("🌪️ Tornado boost — AoE!", "status")
		var _arr14 = JS.iter(Helpers.aliveEnemies())
		for i in range(len(_arr14)):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
			JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air", "apMult": 0.75}])
		if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
			State.setActiveEnemy(State.combat.targetIdx)
	else:
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air", "apMult": 0.75}])
	JS.callm(s, "log", ["💥 Windy Takedown!", "player"])

func SPELL_CATALOGUE__sleeper_gust__execute(s = null):
	var this = JS._this
	if JS.t(State.status.player.get("tornadoAoENext")):
		State.status.player.tornadoAoENext = false
		UI.log_("🌪️ Tornado boost — AoE!", "status")
		var _arr15 = JS.iter(Helpers.aliveEnemies())
		for i in range(len(_arr15)):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
			JS.callm(s, "hit", [{"baseDamage": 1, "effects": [], "hits": 2, "abilityElement": "Air", "apMult": 1.5}])
		if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
			State.setActiveEnemy(State.combat.targetIdx)
	else:
		JS.callm(s, "hit", [{"baseDamage": 1, "effects": [], "hits": 2, "abilityElement": "Air", "apMult": 1.5}])
	if not JS.t(State.combat.get("over")):
		var actionsBonus = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
		State.status.player.nextTurnBonusActions = (JS.or_(State.status.player.get("nextTurnBonusActions"), 0)) + actionsBonus
		JS.callm(s, "log", ["😴 Sleeper Gust! +" + JS.s(actionsBonus) + " actions next turn (" + JS.s(State.status.player.nextTurnBonusActions) + " pending).", "player"])

func SPELL_CATALOGUE__queue_slash__execute(s = null):
	var this = JS._this
	var otherPrioritySum = JS.or_(State.combat.get("_queueAbsPrioritySum"), 0)
	var bonus = otherPrioritySum * 10
	var dmg = JS.round((12 + bonus) + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air"}])
	JS.callm(s, "log", ["⚡ Queue Slash! " + JS.s(dmg) + " dmg (" + JS.s(bonus) + " from queue priority).", "player"])

func SPELL_CATALOGUE__slipcut__execute(s = null):
	var this = JS._this
	var eab = JS.or_(State.combat.get("currentQueuePosition"), 0)
	var hasMomentum = (JS.or_(State.status.player.get("momentumStacks"), 0)) >= 1
	var dmg = JS.round(20 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	var bonusNote = ""
	if (eab == 0 and hasMomentum):
		State.status.player.momentumStacks = max(0, (JS.or_(State.status.player.get("momentumStacks"), 0)) - 1)
		dmg += 15
		bonusNote = " (−1 Momentum → +15 dmg)"
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air"}])
	JS.callm(s, "log", ["🌬️ Slipcut! " + JS.s(dmg) + " dmg" + bonusNote, "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__wind_surge__undoOnQueue():
	State.combat._aoPriorityShift = 0

func SPELL_CATALOGUE__wind_surge__execute(s = null):
	var this = JS._this
	var dmg = JS.round(12 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	var alive = Helpers.aliveEnemies()
	var _arr16 = JS.iter(alive)
	for i in range(len(_arr16)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air"}])
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	var shift = JS.or_(State.combat.get("_aoPriorityShift"), 0)
	JS.callm(s, "log", ["🌊 Wind Surge! All enemies hit. Subsequent spells: " + ("+" if shift > 0 else "") + JS.s(shift) + " priority.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__break_momentum__execute(s = null):
	var this = JS._this
	var stacks = floori(JS.or_(State.status.player.get("momentumStacks"), 0))
	if stacks == 0:
		JS.callm(s, "log", ["💫 No Momentum to consume!", "status"])
		return
	var dmgPerStack = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	var dmg = (stacks * dmgPerStack) + JS.callm(s, "attackPow", [])
	State.status.player.momentumStacks = 0
	Hit.applyDirectDamage.call("player", "enemy", dmg, "💫 Break Momentum (" + JS.s(stacks) + "×" + JS.s(dmgPerStack) + ")")
	JS.callm(s, "log", ["💫 Break Momentum! " + JS.s(stacks) + " stacks → " + JS.s(dmg) + " damage!", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__winds_end__execute(s = null):
	var this = JS._this
	# ── Legendary ─────────────────────────────────────────────────────────────────
	var dd = JS.find(JS.or_(State.player.get("spellbook"), []), func(sp = null): return sp.get("id") == "dynamic_drift")
	var drift = (abs(JS.or_(dd.get("_battlePriority"), 0)) if JS.t(dd) else 0)
	var momentum = floori(JS.or_(State.status.player.get("momentumStacks"), 0))
	var dmg = JS.round(((15 + (drift * 12)) + (momentum * 1.5)) + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	var alive = Helpers.aliveEnemies()
	var _arr17 = JS.iter(alive)
	for i in range(len(_arr17)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air"}])
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	JS.callm(s, "log", ["🌪️ Wind's End! " + JS.s(dmg) + " dmg to all (drift ×" + JS.s(drift) + ", " + JS.s(momentum) + " Momentum).", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__absolute_zero__execute(s = null):
	var this = JS._this
	var total = JS.or_(State.combat.get("_turnTotalAbsPrioritySum"), 0)
	var dmg = JS.round((total * 20) + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.95))
	var alive = Helpers.aliveEnemies()
	var _arr18 = JS.iter(alive)
	for i in range(len(_arr18)):
		State.setActiveEnemy(JS.indexOf(State.combat.enemies, JS.idx(Helpers.aliveEnemies(), i)))
		JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Air", "_noAtk": true}])
	if JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)):
		State.setActiveEnemy(State.combat.targetIdx)
	JS.callm(s, "log", ["❄️ Absolute Zero! " + JS.s(dmg) + " dmg to all (" + JS.s(total) + " total |priority| this turn).", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__storm_rush__onQueue():
	State.combat.actionsLeft = (JS.or_(State.combat.get("actionsLeft"), 0)) + 3
	UI.log_("⚡ Storm Rush! +3 actions available this turn.", "status")
	Combat.updateActionUI()

func SPELL_CATALOGUE__storm_rush__undoOnQueue():
	State.combat.actionsLeft = max(1, (JS.or_(State.combat.get("actionsLeft"), 0)) - 3)
	Combat.updateActionUI()

func SPELL_CATALOGUE__storm_rush__execute(s = null):
	var this = JS._this
	var momentumBonus = JS.round(5 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.95))
	Helpers.addMomentumStacks(momentumBonus)
	for sp in JS.iter(State.player.spellbook):
		if (JS.or_(sp.get("currentCD"), 0)) > 0:
			sp.currentCD = max(0, sp.currentCD - 1)
	JS.callm(s, "log", ["⚡ Storm Rush! +" + JS.s(momentumBonus) + " Momentum (×" + JS.toFixed(State.status.player.momentumStacks, 1) + "). All CDs −1.", "player"])
	UI.renderStatusTags()

func SPELL_CATALOGUE__power_strike__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ NEUTRAL ════════════════════════════════════
	var dmg = JS.round(30 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 10, 0.95))
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "apMult": 2}])
	JS.callm(s, "log", ["⚔️ Power Strike!", "player"])

func SPELL_CATALOGUE__double_tap__execute(s = null):
	var this = JS._this
	var dmg = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 5, 0.95))
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "hits": 2, "apMult": 0.75}])
	JS.callm(s, "log", ["👊 Double Tap!", "player"])

func SPELL_CATALOGUE__shield_bash__execute(s = null):
	var this = JS._this
	var armorBase = JS.round(15 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.95))
	Helpers.gainBlock("player", armorBase)
	if not JS.t(State.combat.get("over")):
		var defBonus = floori(Helpers.defenseFor("player") * 2)
		var armorGranted = armorBase + defBonus
		Hit.applyDirectDamage.call("player", "enemy", armorGranted, "🛡 Shield Bash")
		JS.callm(s, "log", ["🛡️ Shield Bash! +" + JS.s(armorGranted) + " Armor → " + JS.s(armorGranted) + " dmg", "player"])

func SPELL_CATALOGUE__vampiric_strike__execute(s = null):
	var this = JS._this
	var lifesteal = 0.4 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 0.08, 0.9)
	JS.callm(s, "hit", [{"baseDamage": 30, "effects": []}])
	JS.callm(s, "healSelf", [JS.round((30 + JS.callm(s, "attackPow", [])) * lifesteal)])
	JS.callm(s, "log", ["🩸 Vampiric Strike!", "player"])

func SPELL_CATALOGUE__war_cry__execute(s = null):
	var this = JS._this
	var bonus = JS.round(10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	State.status.player.battlePowerBonus = (JS.or_(State.status.player.get("battlePowerBonus"), 0)) + bonus
	JS.callm(s, "log", ["📯 War Cry! +" + JS.s(bonus) + " Power this battle (total: +" + JS.s(State.status.player.battlePowerBonus) + ")", "player"])
	UI.updateStatsUI()

func SPELL_CATALOGUE__plasma_arc__execute(s = null):
	var this = JS._this
	# ════════════════════════════════ DUO / MERGED ════════════════════════════════
	# ── Lightning + Fire ─────────────────────────────────────────────────────────
	var meltAmt = JS.round(20 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	var surgeVal = JS.round(30 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.9))
	Hit.applyMelt.call("player", "enemy", meltAmt, "⚡🔥 Plasma Arc")
	if not JS.t(State.combat.get("over")):
		Surge._applySurge("enemy", surgeVal, "⚡🔥 Plasma Arc — Surge")
	JS.callm(s, "log", ["⚡🔥 Plasma Arc! " + JS.s(meltAmt) + " Melt, Surge " + JS.s(surgeVal) + " loaded.", "player"])

func SPELL_CATALOGUE__superheated__execute(s = null):
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	if (JS.or_(e.status.get("burnStacks"), 0)) > 0:
		e.status.burnStacks = JS.round(e.status.burnStacks * 2)
		UI.log_("🌡️ Superheated! Burn ×2 → " + JS.s(e.status.burnStacks), "player")
	if JS.t(e.status.get("surgeActive")):
		UI.log_("⚡ Superheated triggers Surge (" + JS.s(e.status.surgeValue) + " dmg)!", "player")
		Surge._triggerSurge("enemy")
	else:
		UI.log_("⚡ Superheated — no Surge to detonate", "player")
	JS.callm(s, "log", ["🌡️⚡ Superheated!", "player"])

func SPELL_CATALOGUE__thunderroot__execute(s = null):
	var this = JS._this
	# ── Lightning + Nature ────────────────────────────────────────────────────────
	var surgeVal = JS.round(25 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 4, 0.9))
	var rootAmt = JS.round(2 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	JS.callm(s, "hit", [{"baseDamage": 15, "effects": [], "abilityElement": "Lightning"}])
	if not JS.t(State.combat.get("over")):
		Surge._applySurge("enemy", surgeVal, "⚡🌿 Thunderroot — Surge")
		Helpers.applyRoot("player", "enemy", rootAmt)
		JS.callm(s, "log", ["⚡🌿 Thunderroot! Surge " + JS.s(surgeVal) + ", " + JS.s(rootAmt) + " Root.", "player"])

func SPELL_CATALOGUE__static_bloom__execute(s = null):
	var this = JS._this
	var totalStacks = [null]
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var seeds = JS.or_(e.status.get("seeds"), [])
	if len(seeds) == 0:
		JS.callm(s, "log", ["⚡🌸 Static Bloom — no Seeds to trigger", "player"])
		return
	totalStacks[0] = 0
	for seed_ in JS.iter(JS.arr(seeds)):
		totalStacks[0] += JS.or_(seed_.get("stacks"), 1)
		Seeds._bloomSeed("enemy", seed_, State.combat.activeEnemyIdx)
		if JS.t(State.combat.get("over")):
			continue
	if not JS.t(State.combat.get("over")):
		e.status.seeds = []
		var shockBonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
		var shockAmt = totalStacks[0] + shockBonus
		e.status.shockStacks = (JS.or_(e.status.get("shockStacks"), 0)) + shockAmt
		UI.log_("⚡ Static Bloom! +" + JS.s(shockAmt) + " Shock from " + JS.s(totalStacks[0]) + " bloomed stacks (×" + JS.toFixed(e.status.shockStacks, 1) + ")", "status")
		JS.callm(s, "log", ["⚡🌸 Static Bloom! Seeds triggered, +" + JS.s(shockAmt) + " Shock.", "player"])

func SPELL_CATALOGUE__burning_grove__execute(s = null):
	var this = JS._this
	# ── Fire + Nature ─────────────────────────────────────────────────────────────
	var burnAmt = JS.round(10 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9))
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	e.status.burnStacks = (JS.or_(e.status.get("burnStacks"), 0)) + burnAmt
	e.status.burnSourcePower = JS.callm(s, "effectPow", [])
	UI.log_("🔥 Burning Grove: +" + JS.s(burnAmt) + " Burn (×" + JS.s(e.status.burnStacks) + ")", "status")
	Seeds._plantSeed("enemy", "damage", 2, 5, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🔥🌱 Burning Grove! " + JS.s(burnAmt) + " Burn, Damage Seed ×2 planted.", "player"])

func SPELL_CATALOGUE__char_bloom__execute(s = null):
	var this = JS._this
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	var burnConsumed = JS.or_(e.status.get("burnStacks"), 0)
	if burnConsumed <= 0:
		JS.callm(s, "log", ["🔥 Char Bloom — no Burn to consume", "player"])
		return
	e.status.burnStacks = 0
	var seedStacks = max(1, floori(burnConsumed / 10.0))
	var bonus = JS.round(Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 1, 1.0))
	var finalStacks = seedStacks + bonus
	UI.log_("🔥 Char Bloom: " + JS.s(burnConsumed) + " Burn consumed → " + JS.s(finalStacks) + " Seed stacks", "player")
	Seeds._plantSeed("enemy", "damage", finalStacks, 5, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🔥🌸 Char Bloom! " + JS.s(burnConsumed) + " Burn → Damage Seed ×" + JS.s(finalStacks) + ".", "player"])

func SPELL_CATALOGUE__storm_window__execute(s = null):
	var this = JS._this
	# ── Air + Lightning ──────────────────────────────────────────────────────────
	var eab = JS.or_(State.combat.get("currentQueuePosition"), 0)
	var pidx = JS.or_(State.combat.get("_playerActionIdx"), 1)
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	if (eab == 0 and pidx >= 2):
		# Ideal position: detonate Surge
		if JS.t(e.status.get("surgeActive")):
			JS.callm(s, "log", ["⚡💨 Storm Window! Surge detonated early!", "player"])
			Surge._triggerSurge("enemy")
		else:
			JS.callm(s, "log", ["⚡💨 Storm Window! No Surge loaded — nothing to detonate.", "player"])
	else:
		# Fallback: load a Surge scaled by EAB
		var surgeVal = JS.round((20 + (eab * 25)) + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
		Surge._applySurge("enemy", surgeVal, "⚡💨 Storm Window")
		JS.callm(s, "log", ["⚡💨 Storm Window! Surge " + JS.s(surgeVal) + " loaded (EAB=" + JS.s(eab) + ").", "player"])

func SPELL_CATALOGUE__arc_load__execute(s = null):
	var this = JS._this
	var momentum = floori(JS.or_(State.status.player.get("momentumStacks"), 0))
	var dmg = JS.round(18 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 3, 0.9))
	JS.callm(s, "hit", [{"baseDamage": dmg, "effects": [], "abilityElement": "Lightning"}])
	if (not JS.t(State.combat.get("over")) and momentum > 0):
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			e.status.shockStacks = (JS.or_(e.status.get("shockStacks"), 0)) + momentum
			JS.callm(s, "log", ["💨⚡ Arc Load! " + JS.s(dmg) + " dmg + " + JS.s(momentum) + " Shock from Momentum (×" + JS.s(e.status.shockStacks) + " total).", "player"])

func SPELL_CATALOGUE__windfall_seed__execute(s = null):
	var this = JS._this
	# ── Air + Nature ─────────────────────────────────────────────────────────────
	Seeds._plantSeed("player", "momentum", 1, 3, {"incantLevel": JS.or_(this.get("incantationLevel"), 1)})
	JS.callm(s, "log", ["🌱💨 Windfall Seed planted! +1 priority to all actions while germinating.", "player"])

func SPELL_CATALOGUE__gale_bind__execute(s = null):
	var cur = floori(JS.or_(State.status.player.get("momentumStacks"), 0))
	var convert_ = floori(cur * 0.5)
	if convert_ <= 0:
		JS.callm(s, "log", ["🌿💨 Gale Bind — not enough Momentum.", "player"])
		return
	State.status.player.momentumStacks = max(0, (JS.or_(State.status.player.get("momentumStacks"), 0)) - convert_)
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if (JS.t(e) and JS.t(e.get("alive"))):
		Helpers.applyRoot("player", "enemy", convert_)
		e.status._galeBind = (JS.or_(e.status.get("_galeBind"), 0)) + convert_
	JS.callm(s, "log", ["🌿💨 Gale Bind! −" + JS.s(convert_) + " Momentum → " + JS.s(convert_) + " Root (expires next round).", "player"])

func SPELL_CATALOGUE__afterburn__execute(s = null):
	# ── Air + Fire ────────────────────────────────────────────────────────────────
	State.combat._afterburnActive = true
	JS.callm(s, "log", ["🔥💨 Afterburn! Burn ticks before and after actions this turn.", "player"])

func SPELL_CATALOGUE__ember_flurry__execute(s = null):
	var this = JS._this
	var momentum = floori(JS.or_(State.status.player.get("momentumStacks"), 0))
	var base = JS.round(8 + Incantations._incantationBonus(JS.or_(this.get("incantationLevel"), 1), 2, 0.9))
	var momBonus = momentum * 2
	var hitsLanded = 0
	for i in range(3):
		if JS.t(State.combat.get("over")):
			break
		JS.callm(s, "hit", [{
			"baseDamage": base + momBonus,
			"effects": [{"type": "burn", "stacks": 2}],
			"abilityElement": "Fire",
			"momentumChance": 0,
		}])
		hitsLanded += 1
	if (hitsLanded > 0 and not JS.t(State.combat.get("over"))):
		Helpers.addMomentumStacks(hitsLanded)
		JS.callm(s, "log", ["🔥💨 Ember Flurry! " + JS.s(hitsLanded) + "×" + JS.s(base + momBonus) + " dmg (+" + JS.s(momBonus) + " from " + JS.s(momentum) + " Momentum). +" + JS.s(hitsLanded) + " Momentum.", "player"])
