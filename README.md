# SDP Combat

Part of SkillDrivenProgression (see SDP-Core). Combat realism for enemies and V: NPC aim and fire cadence driven by
each gun's real stats, 6-point visibility and blind fire, armour as pieces with calibre penetration and integrity,
armour bars, and a cut-down copy of Combat Evolved 4.16.8 (maneuvers, fear and flee, limb crippling) in
`r6/scripts/SDPCombat/CE`. Standalone: needs redscript and TweakXL, not SDP-Core. Built to run with Enemies of Night City.

The Combat Evolved code is from DigitalVixen's mod (nexus 29125) and is for a personal install only; publishing it
needs the author's permission.

- [Realism pass design and results](design/SDP_COMBAT_REALISM_PASS.md)
- [Blind fire](design/BLIND_FIRE.md): blinded shooters aim at a remembered position without following the player's live movement.
- [Overhaul comparison](design/COMBAT_OVERHAUL_COMPARISON.md), [CR vs ENC](design/CR_VS_ENC_TECHNICAL.md), [ENC baseline](design/ENC_BASELINE.md)
- [Backend plan](design/WORLD_PROGRESSION_BACKEND.md)
- `tools/SDPVanillaDump`: Phase 0 CET dump of vanilla combat records.

CET console: `SDPC = Game.GetScriptableSystemsContainer():Get("SDPCombat.SDPCombatSystem")`, then `print(SDPC:LastReport())`.
