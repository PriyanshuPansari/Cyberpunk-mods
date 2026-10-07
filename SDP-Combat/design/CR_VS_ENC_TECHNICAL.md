# Combat Revolution vs Enemies of Night City: technical comparison

2026-10-05. Source-level comparison of the two staged packages in Vortex:

| | Combat Revolution (AI Overhaul and High-Stakes) | Enemies of Night City (ENC) |
|---|---|---|
| Staged folder | `Combat-20225-1-4-3-1755242153` | `Enemies of Night City-8467-PL-Beta-1-8-8-Hotfix-1720272238` |
| Version / date | 1.4.3, Aug 2025 | PL-Beta-1.8.8 Hotfix, Jul 2024 (a 0.42 "test" file from Mar 2025 also exists on Nexus) |
| Author | ABCdb111 | viperc48 (builds on Scissors Difficulty Options) |
| Nexus | [mods/20225](https://www.nexusmods.com/cyberpunk2077/mods/20225) | [mods/8467](https://www.nexusmods.com/cyberpunk2077/mods/8467) |

Method: I read the files and counted TweakDB writes with a script. I didn't launch the game, so runtime claims below are labelled "likely" or "verify". This document extends `COMBAT_OVERHAUL_COMPARISON.md` (which also covers Combat Evolved) with a closer two-way comparison.

---

## 1. Verdict

**Combat Revolution makes the existing enemy classes more aggressive. ENC writes specific enemies.**

- CR edits about **30 shared archetype ability groups** (GenericRangedT1, FastMeleeT3, NetrunnerT3, ...) plus the AI ticket, cooldown and movement records that every NPC uses. Every ganger of a class gets the same upgrade, and the changes are mostly removed limits: unlimited tickets, near-zero cooldowns, zero shooting-pattern delay, and no restricted movement areas.
- ENC calls `setArchetypeData` **591 times** and references **~1,960 `Character.*` records**. It assigns hand-picked ability groups, resistances, loadouts and behavior to individual faction units, quest NPCs and bosses. It also adds new behavior trees for each boss, its own animations and FX (6.4 MB `.archive`), and world systems such as a faction wanted system, quest level floors and legendary drops.

| Dimension | Combat Revolution | ENC |
|---|---|---|
| Unit of change | Archetype class (`ArchetypeData.*_inline`) and global AI records | Individual `Character.*` record, plus custom boss action trees |
| Main lever | Remove limits: tickets `-1`, cooldowns `0.01`, pattern delay `0` | Add content: ~850 created/cloned records, 83 status effects, 14 custom quickhack actions |
| Difficulty shape | Fast time-to-kill both ways (enemy HP ×0.6, DPS ×1.1–1.2, armor ×1.5–1.6) and much more simultaneous pressure | Default HP/DMG ×1. Difficulty comes from immunities, weakspots, abilities and boss phases |
| Role identity | Gets weaker: most classes gain hacks, Sandy, regen, reinforcements | Gets stronger: faction resistances and weaknesses, specific loadouts |
| Runtime logic | 2 CET observers that change TweakDB during combat | No Lua observers. Everything is built at init, plus 2 redscript `@replaceMethod`s for grapple |
| Player-side edits | Many: cyberware, weapons, reload times, stun, camera shake, vehicles | Few: grapple/break-hold rules, legendary loot |
| Config surface | 22 settings | 126 Native Settings controls, per-boss tuning |
| Failure mode if a dependency is missing | Soft: each module runs in `pcall`, so one failure does not stop the others | Hard: plain `dofile` chain, so a missing Native Settings UI stops the whole mod |

---

## 2. Packaging and dependencies

| | Combat Revolution | ENC |
|---|---|---|
| Files | 291 (≈832 KB) | 16 (≈8 MB, mostly the archive) |
| TweakXL YAML | **277 files** (`r6/tweaks/Combat/...`) ≈ 4,700 flat assignments, 476 full records | **none** |
| CET Lua | 10 modules, ≈100 KB, ≈50 literal `SetFlat` calls plus loops | 9 modules, **19,069 lines** (`Base.lua` 13,100, `EnemyVariety.lua` 4,056) ≈ 3,370 literal `SetFlat` calls, 104 `CreateRecord`, ~830 `CloneRecord` |
| Redscript | none | `r6/scripts/ENC/BreakHold.reds` (2 `@replaceMethod`) |
| Archive | none | `archive/pc/mod/ENC_Anim_FX.archive` (6.4 MB: Sandevistan melee movesets, taunts, FX) |
| Nexus requirements | CET, TweakXL, RED4ext, ArchiveXL | CET, Native Settings UI, redscript, Phantom Liberty |
| Actually needed by the package | CET + TweakXL (+RED4ext for TweakXL). Native Settings UI is optional. **Nothing in 1.4.3 uses ArchiveXL** | CET + Native Settings UI (hard) + redscript + base archive loading |

### Load pipelines

```
COMBAT REVOLUTION
 game boot
   └─ TweakDB load
        └─ TweakXL applies r6/tweaks/Combat/**/*.yaml   (static: tickets, archetypes,
                                                         Sandy, netrunner, rarity, vehicles)
 CET onInit  (mods/Combat/init.lua)
   └─ for each module: pcall(dofile(...))               (one failure doesn't stop the rest)
        Utils → config → EnemyBase → No Shooting Delay → Minotaur → Immersive Effect
        → Consumable → MeleeAction → MeleeThrowKnife → Native Setting UI
             └─ reads Data/Setting_Config.json, re-applies HP/DPS/Sandy/stun values
 runtime
   ├─ ObserveAfter(PlayerPuppet.IsInCombat)              → rewrites Tier{1-4}Accuracy record
   └─ ObserveAfter(HealthStatListener.OnStatPoolValueChanged) → rewrites hack cooldown flats

ENEMIES OF NIGHT CITY
 game boot
   ├─ archive loader mounts ENC_Anim_FX.archive         (anims, FX)
   └─ redscript compiles ENC/BreakHold.reds             (replaces 2 grapple FSM methods)
 CET onInit  (mods/Enemies of NC/init.lua)
   └─ dofile chain, no pcall:
        Native Settings (loads config_new.json → ~120 globals, builds UI)
        → Base (13k lines: helpers, immunities, ability groups, archetype assignment,
                faction stats, Sandy tiers, boss trees, prevention units, loot)
        → EnemyVariety (per-gig / per-quest NPC edits)
        → BreachProtocol → reloadable_config (scalar knobs) → Detection
        → StatusEffects → SmartWeapon → TimeDilation
 runtime
   └─ nothing in Lua; only the grapple decision functions in redscript
      (settings changes re-run reloadable_config.lua)
```

Two consequences of this layout:

1. **CR's YAML is the floor and its Lua is the ceiling.** TweakXL applies the YAML when TweakDB loads. CET `onInit` runs afterwards, so any flat that both CR's YAML and anyone's CET script set ends up with the CET value. ENC is entirely CET, so wherever ENC and CR's YAML set the same flat, **ENC wins**.
2. **ENC is all-or-nothing.** `Native Settings.lua` calls `nativeSettings.addTab` without a nil-check, and `init.lua` uses plain `dofile`. If Native Settings UI is missing, `EnableMod` is never set and every later module is skipped.

---

## 3. Design model: class vs character

### Combat Revolution: rewrite the shared ability group

```yaml
# r6/tweaks/Combat/EnemyAbility/ArchetypeData.GenericRangedT1_inline2.yaml
ArchetypeData.GenericRangedT1_inline2:
  $type: gamedataGameplayAbilityGroup_Record
  abilities:
    - Ability.IsGenericRangedArchetype
    - Ability.IsTier1Archetype
    - Ability.CanUseCovers
    - Ability.CanCatchUp
    - Ability.CanUseCombatStims          # new
    - Ability.HasPassiveHealthRegeneration
    - Ability.CanUseCuttingGrenades
    - Ability.IsNetrunnerArchetype       # every T1 rifleman is now also a netrunner
    - Ability.CanQuickhack
    - Ability.CanOverloadQuickHack
    - Ability.CanOverheatQuickHack
    # ...
```

A single file changes every Tier-1 generic ranged NPC in the game. `NetrunnerT3_inline4` stacks 28 abilities: Sandy, charge jump, dodge, wall sensing, thermovision, regen, stims, a dozen hacks and reinforcement calls. `FastMeleeT3_inline2` has 36 abilities, including Sandy T3, Kerenzikov, berserk, camo, glowing tattoos and quickhacks. Classes end up looking more alike.

### ENC: build named ability groups, assign them per character

```lua
-- Modules/Base.lua:3088
function setArchetypeData(name, abilityGroups, shootingPatternPackages, statModifierGroups, archetypeType, isCreateNew)
    TweakDB:SetFlat(name..".abilityGroups", abilityGroups)
    TweakDB:SetFlat(name..".statModifierGroups", statModifierGroups)
    ...
end

-- Base.lua:3296  a Tyger Claws T3 Sidewinder gunner
setArchetypeData("Character.tyger_claws_gangster3_ranged3_sidewinder_ma_inline4",
  {"Sandy1AbilityGrp", "KerezAbilityGrp", "T3FastRangedAbilityGrp",
   "HitReactionNormalAbilityGrp", "SubdermalLightAbilityGrp", "ShockAbilityGrp", "TacticalAbilityGrp"},
  {}, {"TygerResStatModifierGrp", "TygerHackResStatModifierGrp"}, ..., false)

-- the T2 Copperhead ganger next to him gets much less
setArchetypeData("Character.tyger_claws_gangster2_ranged2_copperhead_ma_inline0",
  {"T2RangedAbilityGrp"}, {}, {"TygerResStatModifierGrp"}, ..., false)
```

The building blocks are reusable groups (`Sandy1AbilityGrp`, `SubdermalNormalAbilityGrp`, `BreakHoldAbilityGrp`, `ElectrocuteImmuneAbilityGrp`, ...) plus faction stat-modifier groups (`TygerResStatModifierGrp`, `AraHack`, `MiliHack`, ...). Because ENC sets `abilityGroups` on the character's own inline archetype record, **it bypasses the shared `ArchetypeData.*` groups**. This is the key fact for running ENC and CR together (section 6).

`EnemyVariety.lua` goes one level further and is organized by gig and quest (`--we have your wife`, `--i walk the line`, `--monster hunt`, ...). It retargets the archetype data and loadouts of specific encounter NPCs.

---

## 4. Subsystem comparison

### 4.1 Base stats and tier scaling

| | CR (`Modules/EnemyBase.lua`) | ENC (`Modules/Base.lua:82-94`, `reloadable_config.lua`) |
|---|---|---|
| Records | `Tier{1-4}{HP,DPS,Accuracy,Armor,Speed}` ConstantStatModifiers | `T{1-3}Enemy{HP,Dmg}`, plus `EliteHP/Dmg`, `BossHP/Dmg`, `MaxtacHP/Dmg`, `MainBossHP`, per-boss records |
| Attachment | `TweakDB:SetFlat("Ability.IsTier1Archetype_inline1.stats", T1List)`: **replaces** the list | `addToList(...)`: **appends** to the list (no dedupe) |
| Defaults | HP ×0.6, DPS ×1.1 (T1/T2) / ×1.2 (T3/T4), Armor ×1.5–1.6, **MaxSpeed ×1.8–2.2** | All ×1, with separate caps (`BossMaxDmgPerHitStat 7`, Smasher −3, ...) |
| Extra | Rarity hacking resistance +1/+1/+2/+3, Boss 8. Stamina 1000. Visual stim range ×2 | Subdermal armor tiers (`SubArmorLight/Normal/Med/High`), Minotaur weakspot 0.4 |

CR uses `SetFlat` to replace the tier list and ENC uses `addToList` to append. If both are active, the CET load order decides the result. "Combat" sorts before "Enemies of NC", so CR's list is written first and ENC appends to it, and **both sets of multipliers stack**. If the order were reversed, CR would delete ENC's tier modifiers.

### 4.2 Shooting and accuracy

**CR: zero pattern delay plus "dynamic accuracy"**

```lua
-- Modules/No Shooting Delay.lua: every AIPatternDelay record → 0 s
for i, v in ipairs(TweakDB:GetRecords("gamedataAIPatternDelay_Record")) do
    TweakDB:SetFlat(v:GetID().value .. ".delay", 0)
end
```

```lua
-- Modules/EnemyBase.lua: rewritten at runtime, throttled to 0.5 s
ObserveAfter("PlayerPuppet", "IsInCombat", function(this)
  if this.inCombat then
    if this:IsMovingHorizontally() then throttledUpdateT1(1.2) ... end  -- T3/T4: 1.6
    if this:IsMovingVertically()   then throttledUpdateT1(0.9) ... end  -- T3/T4: 1.2
    if static                      then throttledUpdateT1(2.6) ... end  -- T2 3.2, T3/T4 6.0
  end
end)
-- throttledUpdate = SetFlatNoUpdate("Tier1Accuracy.value", v); TweakDB:Update("Tier1Accuracy")
```

How it works: the accuracy multiplier is one shared `ConstantStatModifier` record, and the observer mutates that record. Two points to verify:

- The stats system usually copies modifier data when an ability is applied, typically at spawn. Changing the record mid-fight may therefore only affect NPCs that spawn after the change, not the ones already shooting. Use the mod's DEBUG switch and compare hit rates while standing still and while strafing.
- `PlayerPuppet.IsInCombat` is called very often, and the observer runs its branch logic on every call. Only the TweakDB writes are throttled.

The `EnemyBase` table is built before `DynamicvaluesT1..4` are assigned, so the Accuracy records are first created with a nil value and get real values a few lines later. Check `scripting.log` for `[Loaded] modules/EnemyBase.lua` to confirm the module finishes.

**ENC** leaves global firing cadence alone. It sets accuracy and pressure through archetype shooting-pattern packages and loadouts per character, and makes smart weapons much harsher: `SmartWeapLockOnTime 0.5 s` (CR sets 5 s), lock-out 5 s, Kang Tao smart disruption, and glowing tattoos that block smart targeting.

### 4.3 Pursuit, movement and tickets

CR rewrites the ticket system. Tickets are the vanilla throttle on how many squad members may do something at once:

```yaml
# EnemyAI/Chasing/Tickets.Chasing.yaml
Tickets.CatchUp:
  maxNumberOfTickets: -1   # vanilla 2
Tickets.CatchUp_inline0:
  duration: 0.01           # vanilla 30 s cooldown
Tickets.CatchUp_inline8:   # sniper exclusion removed; chase when no cover with LOS in current ring
  OR: [ Condition.NotValidCoversWithLOSCurrentRing ]

# EnemyAI/Melee/MeleeTicket.yaml
Tickets.Melee:        { maxNumberOfTickets: -1, cooldowns: [] }   # vanilla 1
Tickets.QuickMelee:   { maxNumberOfTickets: -1 }
# BaseStats/Ticket系统/
Tickets.Quickhack.maxNumberOfTickets: 20
Tickets.GrenadeThrow.maxNumberOfTickets: 20
```

CR also sets `ignoreRestrictedMovementArea = true` on about 60 movement actions (`EnemyBase.lua` §7) so that chasers stop freezing at invisible area borders. The cost is that quest-authored containment no longer holds NPCs. Expect them to follow you out of encounter spaces. `CatchUpAccuracyCondition` is changed so that NPCs below 0.95 accuracy close the distance.

ENC keeps the vanilla tickets and **edits the decision graphs instead**. It adds cover-exit variants such as Sandy sprint and reckless exit, gated on nearby squadmates and target visibility (`Base.lua:873-883`, `12573-12597`). It also adds low-health retreat actions, Sandy sprints to investigate bodies, and sprint for disengaged shotgunners. Runners are excluded from aggressive cover exits.

**Practical difference:** CR raises the number of enemies acting at once. ENC raises the quality of each enemy's choices without touching that number.

### 4.4 Melee

**CR** composes existing native actions:

```lua
-- MeleeAction.lua: put a Sandevistan approach in front of every charge/strong/light combo
table.insert(Chargelist, 1, "MovementActions.MeleeMoveToChargeAttackRangeSandevistan")

-- animation speed-up: clone a Kerenzikov time-dilation sub-action and attach it to attacks
function SpeedupActionAnimation(name, easeOut, multiplier, override)
    TweakDB:CloneRecord(name, "DashAndDodgeActions.DodgeKerenzikovLeftFrontDefinition_inline7")
    TweakDB:SetFlat(name..".multiplier", multiplier)          -- 2.0 to 2.5
    ...
end
SpeedupActionAnimation("MeleeMantisTimeDilationSubAction", "KereznikovDodgeEaseOut", 2, 2)
addToList("MeleeMantisBladesActions.InfiniteGenericMeleeAttackFromAttack01Definition.subActions", ...)
```

CR does not ship new animations. To make attacks faster, it runs the NPC's **local time dilation** at ×2 during the attack, using the same machinery as an enemy Kerenzikov dodge. It also lowers `toNextPhaseConditionCheckInterval` to 0.05 s, sets `dynamicTargetUpdateTimer` to 0.3 s, adds a knife-throw AIAction (built from cloned Smasher/Animals records and credited to viperc48), adds charge-jump sound sub-actions and block/parry FX, and removes melee ticket caps.

**ENC** ships **new movesets** in its archive: Sandevistan variants for blunt, hammer, fists, knife, mantis blades and katana, plus taunts. It adds block, dodge and parry selector rewrites (`replaceDodgeSelector`), consumable and berserk selectors in combos, and charge-jump knockdowns. It also changes grapple rules in redscript:

```swift
// r6/scripts/ENC/BreakHold.reds
@replaceMethod(GrappleBreakFreeDecisions)
protected final const func EnterCondition(...) -> Bool {
  ...
  // Body requirement = target Stamina/100 + 8 berserk + 6 shotgunner + 8 heavy ranged + 8 strong melee (cap 20)
  // Cool requirement = Sandy 4/6/8/10 by tier + 2 Kerenzikov + 8 fast ranged/sniper/fast melee + 6 techie (cap 20)
  if targetBreakHoldValue > 0 || playerStrengthValue < playerBodyRequirement
     || playerCoolValue < playerCoolRequirement { return true; }   // enemy breaks free
}
@replaceMethod(GrappleStandDecisions)
protected final const func ToGrappleStruggle(...) -> Bool {
  ... if targetBreakHoldValue > 0 || targetRarity >= 5.00 { return true; }  // elites/bosses always struggle
}
```

Because these are `@replaceMethod`, any other mod that replaces or wraps `GrappleBreakFreeDecisions.EnterCondition` or `GrappleStandDecisions.ToGrappleStruggle` will conflict at compile time.

### 4.5 Sandevistan and time dilation

| | CR | ENC |
|---|---|---|
| Enemy Sandy activation | `ReactionsActions.SandevistanTimeDilation`: multiplier 8, override 16 (Lua settings) | Sandy0–3 ability tiers; activation actions built in `Base.lua` |
| Sandy vs player Sandy/Kerenzikov | One modified `ReactionsActions.SandevistanVersusSandevistan` with a new condition `PlayerKerenzikovORSandevistan` and a time-dilation sub-action of **multiplier 8, override 32** (YAML) | Four cloned actions `SandyVSandyTier{0..3}Action` in a priority selector (T3→T0), each with its own extra dilation. Config defaults **1.5 / 2 / 2.5 / 3** |
| Spread | 30 archetype groups with T1–T3 Sandy assignments | Only the characters given `Sandy*AbilityGrp` |
| Melee Sandy | Sandy approach in front of every melee definition | Dedicated Sandy movesets from the archive |

`overrideMultiplerWhenPlayerInTimeDilation` controls how fast the NPC moves while the player is slowing time. CR's value of 32 means Sandy enemies largely ignore your Sandevistan. ENC's 1.5–3 lets a high-tier enemy partly close the gap while still leaving the player ahead. The design intent differs: in CR, player time dilation is countered; in ENC, it is contested by tier.

CR has two separate Sandy knobs (the YAML sets the versus action to 8/32, the Lua UI sets generic Sandy activation to 8/16), and the settings UI only exposes the second one.

### 4.6 Netrunning

**CR**

- Hack abilities are spread to non-netrunner classes, including GenericRangedT1, FastMeleeT3 and TechieT3. `Tickets.Quickhack` is capped at 20 simultaneous hackers.
- Player-health-scaled hack cooldown (`EnemyBase.lua` §6):

  ```lua
  ObserveAfter("HealthStatListener", "OnStatPoolValueChanged", function(this, old, newValue)
    if this.ownerPuppet.inCombat and newValue <= 50 then
      HackCoolDown      = 0.001596 * (newValue - 50)^2 + 0.01   -- 0.01 s at 50% HP → ~4 s at 0%
      QuickHackCoolDown = 0.001596 * (newValue - 50)^2 + 0.1
      HackCoolDownUpdate(HackCoolDown)   -- SetFlatNoUpdate(path) ; TweakDB:Update(path)
  ```

  This curve backs off as V nears death, giving the player a recovery window. Above 50% HP the cooldown is pinned to 0.01 s.

  **Probable bug:** `HackCoolDownUpdate` calls `TweakDB:Update()` with a *flat path* (`"AIQuickHack.AIQuickHack_inline4.duration"`), but `Update` expects a *record ID*. The runtime update therefore probably never reaches the record. Hacks likely stay at the 0.01 s and 0.1 s values set at init, which makes them more relentless than the description suggests. Verify with DEBUG on.
- Shorter durations for `HackDeath`, `HackOverload`, `HackOverheat` and `HackCyberware` (VeryHard variants), plus Camo and ICE buffs.

**ENC**

- Faction hack resistance knobs: Arasaka 6, VDB 6, MaxTac 6, NUSA 6, Kang Tao 5, Trauma 5, Militech 4, Corpo 4, NCPD 4, Tyger 3, Scav 3.
- 14 custom quickhack actions (`createQuickhackAction`) and 83 custom status effects. Includes **reflect quickhacks** (`createReflectQuickhackAction`), which bounce the player's hack effect back, and a rule that NPC hacking stops when the target is closer than 15 m.
- `BreachProtocol.lua`: enemy netrunners can be **remote-breached** like access points. Breach is gated by `BreachMultiPrereq`, which nests `IsNetrunnerArchetype` and `IsTier4Archetype` stat prereqs. The author's comment reads "must be at least a netrunner or tier4 archetype to have breach protocol". Per-program durations are configurable (ICEPick 4 s, Suicide 6 s, ICEBreaker 8 s, ...), as are minigame time limits.

### 4.7 Consumables and regeneration

| Flat | CR | ENC |
|---|---|---|
| `SpecialActions.CombatStimCooldown*.duration` | 30 / 20 / 15 (Normal/Hard/VeryHard) | 120 (all three) |
| `BaseStatusEffect.CombatStim_inline7.valuePerSec` | 12 %/s | 16.67 %/s |
| Stim use conditions | <50% HP, allowed in cover and while chasing, melee weapon no longer required | Stims below 60% HP on a cooldown. Added to taunt/support and some combos |
| Passive regen | T1/T2 2 %/s up to 80%. T3 0.4 %/s up to 60% | Per boss (Smasher 2.5, Sasquatch 0.3, Oda stealth heal, ...) |

ENC writes these flats in CET after CR's YAML, so in a combined install **ENC's stim values win**. CR's Lua (`Consumable.lua`) also writes them in CET, and its folder loads first, so ENC overwrites it there too.

### 4.8 Detection and stealth

- **CR**: one change, `VisualStimRangeMultiplier` ×2 on the NPC base stat group.
- **ENC** (`Detection.lua`): detection curves extended to 50 m. `detectionFactor` set to relaxed 800, alerted 1200, combat 1600, snipers 400, turrets 800. Peripheral range 30 m. The close sniper preset is copied from the 100 m sniper curves. ENC also triggers backup calls when bodies are found and alerts on doors opening.

### 4.9 Bosses and special NPCs

- **CR**: Minotaur (`minotaur.abilities.yaml`, HMG damage and angle, smart-weapon-dazzling armor). Beat on the Brat fighters (`mq025_*`). 8 cyberpsychos. **13 companion records reworked** (Jackie, Judy, Panam, Rogue, Takemura, Songbird, Reed, ...). `Minotaur.lua` sets 23 Minotaur records and 15 outpost minibosses to `NPCRarity.Boss`.
- **ENC**: bespoke behavior trees for Smasher, Oda, Sasquatch, Chimera, Kurt, Yasha and Ribakov, with roughly 4,000 lines of `Base.lua` (5000–9000) for boss logic. Examples: Smasher plate-destroyed phase logic, HMG/laser/shotgun sequences, berserk triggers, voice lines. Oda's mask break removes smart-weapon immunity. Sasquatch has a destructible juice injector. Kurt has knife-throw and LMG keep-distance logic. Also MaxTac, 30+ cyberpsychos and miniboss weakspots (30% HP plus a status effect), Beat on the Brat rebalanced through `NPCStatPreset.Mq025_*`, and about 30 legendary weapon drops (`createLegendaryWeapon`).

### 4.10 World systems (ENC only)

- **Expanded wanted system**: `createPreventionUnit` clones gang units into police-style prevention passengers on NCPD vehicle templates (for example Tyger kunoichi on Apollo bikes), and `createAVPreventionUnit` does the same for AVs.
- Quest minimum levels raised (Ghost Town 12, Life During Wartime 14, endgame 25–30).
- Civilian AI and equipment-pool toggles.

### 4.11 Player-side changes (CR only, unless noted)

- Cyberware: Ex-Disks weakened, Kerenzikov tuned (all rarities), Mantis, Monowire and Gorilla Arms combo speed and damage, Projectile Launcher tracking and damage, Nanotech plates, Humanity cost variant.
- Weapons: Copperhead preset and damage, Carnage, reload times (generic plus Masamune), a constant-stats file.
- Vehicles: car health, Warden and power-weapon smart stats, 200-round MG, missile damage.
- Feel (`Immersive Effect.lua`): stagger and knockdown packages per caliber, camera shake, player stun state, bleed slow on the knife status effect. Also a runtime `IsInCombat` observer that relaxes these for melee.
- ENC's player-facing changes are the grapple rules (BreakHold.reds), armor penetration on tech weapons and legendary loot.

---

## 5. Implementation quality notes

| Issue | Mod | Evidence | Impact |
|---|---|---|---|
| `TweakDB:Update()` called with a flat path | CR | `EnemyBase.lua` `HackCoolDownUpdate` / `QuickHackCoolDownUpdate` | HP-scaled hack cooldown is probably a no-op. Hacks stay near 0.01 s |
| Runtime mutation of a shared stat-modifier record | CR | `Tier{1-4}Accuracy` rewritten from `IsInCombat` | May only affect NPCs spawned after the change. Hot-path observer |
| Same record defined in two YAML files | CR | `NPCRarity.Trash.statModifiers` in both `Rarity/HackingResistance.yaml` (adds `Trash_inline6`) and `Rarity/NPCRarity.Trash.statModifiers.yaml` (does not) | Whether Trash enemies get +1 hacking resistance depends on TweakXL file order |
| Duplicate ability entries | CR | `FastMeleeT3_inline2` lists `IsNetrunnerArchetype` and `CanPingQuickHack` twice | Harmless, but suggests the lists are hand-merged |
| ArchiveXL listed but unused | CR | No `.archive` / `.xl` in 1.4.3 | Unnecessary dependency |
| `addToList` without dedupe, non-idempotent init | ENC | `Base.lua:3-6` | Re-running init (or a second mod calling it) duplicates entries. Use the UI path (`reloadable_config.lua`) for changes |
| No `pcall` around module chain | ENC | `init.lua` | Any error in `Base.lua` silently disables everything after it |
| Unresolved condition name in text | ENC | `SandyVSandyOROR` referenced at `Base.lua:5059, 5458+`, not defined in any text file | Resolve from the TweakDB dump before extending Sandy-vs-Sandy logic |
| Comments acknowledge broken paths | ENC | "push and parry buggy", "MeleeLightCombo01Definition seems to fail if the first attack doesn't hit", known T-posing | Expect occasional animation and behavior glitches, as the author notes |
| Code style | both | CR: small, commented (in Chinese), data-driven tables. ENC: very large, imperative, many commented-out experiments | CR is easier to fork module by module. ENC is easier to mine for working record recipes |

---

## 6. Running both together

The mods do not fail outright, but they **overlap on about 45 literal flats and 37 records**, plus several more written through helper tables. The winner is decided by mechanism, not by intent:

```
priority (last writer wins):
  CR YAML (TweakXL, at TweakDB load)
    < CR Lua  (CET onInit, folder "Combat")
    < ENC Lua (CET onInit, folder "Enemies of NC")
```

| Overlap | Result when both are installed |
|---|---|
| Tier stat lists `Ability.IsTier{1-3}Archetype_inline1.stats` | CR replaces, then ENC appends, so **both stack** (CR HP ×0.6 × ENC T*EnemyHP) |
| ~590 character archetype records | ENC replaces `abilityGroups` per character, so **CR's archetype-group edits vanish for every ENC-authored NPC**. They still apply to NPCs ENC didn't touch. The result is an uneven roster |
| 8 cyberpsychos, `mq025_*` boxers, Rogue/Saul/Reed/Songbird `archetypeData` | ENC wins (later CET write) |
| Combat stim cooldown and regen | ENC wins (120 s, 16.67 %/s) |
| Smart-gun lock-on `Items.Base_NPC_SmartGun_Stats_inline0/1` | ENC wins (0.5 s) |
| `ReactionsActions.SandevistanVersusSandevistan.startupSubActions` | ENC wins, while CR's 8/32 dilation sub-action stays in the loop. Mixed Sandy-vs-Sandy behavior |
| Strafe cooldowns, charge-jump conditions, reload selector | ENC wins on the shared flats |
| Tickets, pattern delay, movement restrictions, netrunner hack lists | Only CR touches these, so CR applies globally, **including to ENC's authored enemies** |
| Breach Protocol | ENC gates breach on `IsNetrunnerArchetype`. CR gives that flag to GenericRangedT1 and others, so **many more enemies become breachable** |

In practice, a combined install gives ENC's roster with CR's global aggression: unlimited chasers and melee, zero burst pauses, hacking from almost everyone, and stacked HP scaling. Neither author tuned for that. The [earlier recommendation](COMBAT_OVERHAUL_COMPARISON.md) stands: **pick one backend**. If you want something from the other mod, port individual records into a patch that you own.

---

## 7. What this means for SkillDrivenProgression

| Topic | CR | ENC |
|---|---|---|
| Rarity XP multipliers (Elite ×2, Boss ×10) | Promotes 23 Minotaur records and 15 outpost minibosses to Boss | Promotes many NPCs to Elite/Boss (see `ENC_BASELINE.md`) |
| Shard damage XP (% of Health) | HP ×0.6 shortens fights, so less time-channel XP per fight | HP ×1, so fights are longer and time channels pay more |
| Attribute-gated mechanics | None | `BreakHold.reds` reads player **Strength and Cool** (up to 20) against target traits. Since SDP derives attributes from skills, grapple success follows SDP progression directly. SDP already stages an identical copy (`.stage/ENC_BreakHold.reds`) |
| Player item balance | Rewrites player cyberware and weapons, which collides with shard/perk balance and Gunsensical | Mostly leaves player items alone |
| Scanner dilation (`ScannerDilation.reds`) | Sandy override 32 effectively negates the player's time dilation against Sandy enemies | Tiered 1.5–3, which leaves room for a hardware-contest design |
| Hook surface for SDP code | Two CET observers that mutate TweakDB. Nothing to wrap | Two redscript methods (`GrappleBreakFreeDecisions.EnterCondition`, `GrappleStandDecisions.ToGrappleStruggle`). SDP must not `@replaceMethod` the same ones |
| Donor value for SDP Combat backend | Ticket and pursuit tuning, the time-dilation speed-up trick, the knife-throw AIAction recipe | Per-faction ability-group recipes, the Sandy tier selector, boss trees, breach-on-NPC |

Recommendation: keep **ENC as the baseline** (as in `ENC_BASELINE.md`). Treat CR as a donor for a few **pressure knobs**, applied after ENC and owned by SDP:

1. `Tickets.CatchUp` max 3–4 (not −1) with a 5–10 s cooldown, instead of unlimited and 0.01 s.
2. Pattern delays scaled ×0.5, instead of zero.
3. The animation speed-up sub-action, only on T3 melee.

Don't import CR's archetype-group YAML, which ENC would mostly override and which blurs roles, or its player cyberware and weapon edits.

---

Sources: [Combat Revolution on Nexus](https://www.nexusmods.com/cyberpunk2077/mods/20225), [Combat Revolution files](https://www.nexusmods.com/cyberpunk2077/mods/20225?tab=files), [Enemies of Night City on Nexus](https://www.nexusmods.com/cyberpunk2077/mods/8467), [ENC files](https://www.nexusmods.com/cyberpunk2077/mods/8467?tab=files), and the local staged packages listed at the top.
