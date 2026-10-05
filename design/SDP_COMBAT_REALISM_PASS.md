# SDP Combat realism pass: remove playability crutches, make the AI smarter

2026-10-05. Design pass for the `SDPCombat` backend ([backend plan](WORLD_PROGRESSION_BACKEND.md)).
It decides, mechanic by mechanic, which vanilla combat rules exist only to keep the game
playable, and what replaces each one.

**Evidence base.**
- **Vanilla script source.** I decompiled `prototype.redscripts`, the full compiled bundle in this repo, with `redscript-cli` v1.0.0-preview.22. That gave the actual `TargetShootComponent`, `AISubActionShootWithWeapon` and `AIStatusEffectCond` code. The bundle contains no Combat Evolved code (0 `GBP` references), so these methods are vanilla.
- **Vanilla TweakDB values.** Measured in-game on 2026-10-05 with the Phase 0 console script (`tools/SDPVanillaDump/console_summary.lua`, read from CET's `scripting.log`). In that session CET skipped ENC, Combat Revolution, Harder Gunfights, No Shooting Delay and TDO (no `init.lua` deployed), and the ticket and stim values match vanilla rather than any donor mod's YAML.
- **No in-game testing.** Every number marked *starting value* is a hypothesis to calibrate, not a measurement.

---

## 0. The rules this pass applies

Every mechanic must pass four tests.

1. **Diegetic test.** Could this happen in Night City, given the actor's body, chrome, gear, training and information? Lore is permissive but not magic: smartlinks, Kiroshi optics, reflex boosters, subdermal armor, biomonitors, combat drugs and quickhacks over a network connection all exist. Free knowledge, infinite stamina and bullets that politely miss do not.
2. **Symmetry test.** One rulebook for V and NPCs. If V's Sandevistan, smartlink or MaxDoc behaves a certain way, an NPC with the same hardware behaves the same way. Hardware tables are shared, not authored twice.
3. **Information honesty.** An NPC acts on what it could know: what it saw, heard, was told over comms, or traced through a network. It never reads V's true position through a wall.
4. **Difficulty comes from the world, not hidden handicaps.** Harder means better-trained, better-equipped, more numerous or better-informed enemies. It never means a secret timer that makes their bullets miss.

Each vanilla mechanic gets one of four verdicts:

| Verdict | Meaning |
|---|---|
| **KEEP** | Already diegetic. Tune values only |
| **REMOVE** | A pure crutch, and removing it is plausible in-world |
| **REPLACE** | The crutch stands in for a real constraint. Model the real constraint, so the limit emerges from it |
| **REMOVE CHEAT** | An NPC advantage with no in-world basis |

Removing crutches alone makes enemies more lethal, not smarter. Smarter means better decisions made from honest information (sections 6 and 9).

---

## 1. What vanilla actually does

### 1.1 Hit decision: a shared "time between hits" clock (the biggest crutch)

`TargetShootComponent.ShouldBeHit` (vanilla, decompiled):

```swift
let timeBetweenHits = this.CalculateTimeBetweenHits(params);   // product of 10 coefficients
let timeSinceLastHit = EngineTime.ToFloat(GameInstance.GetSimTime(gameInstance)) - this.GetLastHitTime();
let shouldBeHit = timeSinceLastHit >= timeBetweenHits;
```

```swift
private final func CalculateTimeBetweenHits(const params: script_ref<TimeBetweenHitsParameters>) -> Float {
  return params.difficultyLevelCoefficient * params.baseCoefficient * params.baseSourceCoefficient
       * params.accuracyCoefficient * params.distanceCoefficient * params.visibilityCoefficient
       * params.playersCountCoefficient * params.groupCoefficient * params.coverCoefficient
       * params.visionBlockerCoefficient;
}
```

What this means:

- **Hits are scheduled, not aimed.** A bullet hits V only if enough time has passed since V was *last hit by anyone*. `LastHitTime` lives on the **target's** component (`SetLastHitTime` / `GetLastHitTime` are native on `TargetShootComponent`), so all shooters share one hit clock.
- **More shooters mean longer gaps.** `groupCoefficient` comes from a native group count fed by `InsertRecentHitter`, mapped through the `rescaled_group_coefficient` curve. Five enemies firing at V is engineered to be far less than five times as dangerous.
- **Misses are placed on purpose.** When the clock says "miss", `HandleMissed` → native `CalculateMissOffset` puts the round near V using `TimeBetweenHits.missShotOffset.*` (Harder Gunfights sets `defaultSpreadAngle`, `specialSpreadAngle`, `minimumDistanceAroundTarget`, `additionalSpreadRandZOffset`). There is also a forced vertical miss for shooters in low cover (`UseForcedTBHZOffset` / `ForcedTBHZOffset`).
- **Measured miss placement:** `missShotOffset.minimumDistanceAroundTarget = 1`, `defaultSpreadAngle = 3`, `specialSpreadAngle = 1`. A designed miss lands **at least 1 m from V**, which is why vanilla misses look like warning shots rather than near misses.
- **Difficulty, cover and accuracy only scale the timer.** Accuracy enters as `1 / Accuracy`, difficulty via `storyModeMultiplier`…`hardModeMultiplier` (**all measured at 1**, so in vanilla this particular difficulty lever does nothing), cover via `coverVsNormalWeaponsMultiplier` (**measured 2.5**: V in cover makes the hit timer 2.5× longer). The HMG group multiplier is 0.5.
- **Vanilla bug:** in `GetCoverCoefficient`, the smart-weapon branch's field name is immediately overwritten, so `coverVsSmartWeaponsMultiplier` (measured 1.5) is never read. Smart weapons get the 2.5 cover penalty too.

### 1.2 Firing cadence: authored pattern delays

`AISubActionShootWithWeapon_Record_Implementation.QueueNextShot` looks up `AIWeapon.GetShootingPatternDelayBetweenShots(totalShots, pattern)`. That is a per-shot delay table (`AIPatternDelay` records keyed by `shotNumber`) cycling through the pattern. The delay is an authored number. It does not depend on recoil, the shooter's skill, target movement, or why the NPC is shooting. CR sets every one to 0.

**Measured:** 1,771 `AIPatternDelay` records across 263 patterns. Three are ≥100 s (500 s, presumably stop markers). The other 1,768 average **1.09 s**:

| Delay | 0–0.1 s | 0.1–0.25 | 0.25–0.5 | 0.5–1 | 1–2 | 2–5 | 5+ |
|---|---:|---:|---:|---:|---:|---:|---:|
| Records | 166 | 114 | 211 | **494** | **530** | 237 | 16 |

Most vanilla pauses are 0.5–2 s, whoever is shooting. That is the "untrained, no chrome" band of the §3 model. In vanilla, a MaxTac operative pauses like a Scav.

### 1.3 Concurrency: tickets (measured)

`AIActionTicket` records cap how many squad members may do something at once. 45 ticket records exist. Measured vanilla values, with CR and CE for comparison:

| Ticket | max | min | % of squad | Cooldown | CR | CE |
|---|---:|---:|---:|---|---|---|
| `Melee` | **1** | – | – | `Melee_inline0` 0.1 s (+ `_inline3`) | −1 | 5 |
| `MeleeApproach` | 2 | – | – | `MeleeApproach_inline0` | −1 | |
| `QuickMelee` | 1 | – | – | none | −1 | |
| `MeleeRing` | **1** | – | – | none | | 5 |
| `CloseRing` | 2 | – | 20% | none | | 7 |
| `MediumRing` | ∞ | 2 | 30% | none | | |
| `FarRing` | ∞ | 1 | 30% | none | | |
| `CatchUp` (Easy/Normal) | 2 | – | – | **30 s** | −1 / 0.01 s | |
| `CatchUpHard` | 3 | 1 | – | 30 s | −1 | |
| `Quickhack` | **1** | – | – | **8 s** | 20 | |
| `GrenadeThrow` (Hard) | 1 (2) | – | – | **15 s** | 20 | |
| `Peek` | 2 | – | – | none | | |
| `StrafeEvade` | 1 | – | – | yes | | 1.5 s |
| `Strafe` | ∞ | – | – | 1.5 s | | |
| `Block` | 3 | 2 | 50% | none | | |
| `Sync` | 1 | – | – | none | | |
| `Dodge`, `TakeCover`, `Charge`, `Equip` | ∞ | – | – | none | | |

Other measured values:

| Record | Vanilla | CR | ENC |
|---|---:|---:|---:|
| `MovementActions.StrafeCooldown.duration` | **15 s** | | |
| `SpecialActions.CombatStimCooldown` (Normal / Hard / Very Hard) | 150 / 60 / 35 s | 30 / 20 / 15 | 120 |
| `AIQuickHack.AIQuickHack_inline4.duration` | 12 s | 0.01 | |
| NPC smart-gun lock-on / lock-out (`Base_NPC_SmartGun_Stats_inline0/1`) | 3 s / 3 s | 5 / 5 | 0.5 / 5 |

Reading the table as a whole: in a vanilla fight, only **one** enemy may be in melee range swinging, at most **two** may chase V (and then nobody may start chasing for 30 s), only **one** netrunner may upload at a time with an 8 s gap, only **one** grenade is in the air every 15 s, and only two enemies may peek out of cover at once. Every one of these is a playability throttle.

### 1.4 Information (measured)

Each AI action aims at an `AIActionTarget` record, and that record's `trackingMode` decides which position of V the action uses. The engine has `BeliefPosition`, `LastKnownPosition`, `RealPosition`, `SharedBeliefPosition` and `SharedLastKnownPosition`. Measured across 1,121 action targets:

| Action category | `RealPosition` | `SharedBeliefPosition` | `BeliefPosition` |
|---|---:|---:|---:|
| Shoot from cover | **258** | 0 | 0 |
| Cover enter / exit | **54** | 0 | 0 |
| Shoot or attack in the open | 50 | 352 | 1 |
| Dodges | 0 | 117 | 0 |
| Reloads | 26 | 30 | 0 |
| Reactions (warnings, hostility, reprimands) | 38 | 2 | 0 |
| Melee | 12 | 28 | 0 |
| Positions, other targets | 16 | 0 | 0 |
| Grenades | 2 | 3 | 0 |
| Other | 82 | 50 | 0 |
| **Total** | **538** | **582** | **1** |

Nothing uses `LastKnownPosition` at all.

What this means:

- **Every shoot-from-cover action aims at V's true position.** An enemy ducking behind cover pops up already aimed at where V *is*, even if V moved while out of its sight. This is the clearest information cheat in the game.
- **Open-ground shooting uses the squad's shared belief.** Belief sharing is instant and needs no comms, so one sighting informs the whole squad immediately.
- **All 8 threat-tracking presets set `moveBeliefOnlyIfVisible = false`.** These are Default, Boss, Cyberpsycho, Prevention, Player, Follower and two character-specific presets. By its name, the belief position keeps moving even when V is not visible. The exact semantics are native and need an in-game test, but the setting reads as continuous tracking without sight. NPC presets also have `visibleBeliefSpeedMultiplier = 5`.
- **Threat memory for enemies:** `dropPerHit = 5`, `dropMax = 15` s. The base drop cooldown is 2 s (Default), 10 s (Boss/Cyberpsycho) and 0 (Prevention).

Movement areas (`ignoreRestrictedMovementArea`) also fence NPCs into designer-drawn arenas.

---

## 2. Inventory and verdicts

| # | Mechanic | Vanilla behaviour | Verdict | In-world reasoning | Replacement (section) |
|---|---|---|---|---|---|
| 1 | Time-between-hits clock | All shooters share one hit timer on V. More shooters means a longer timer | **REPLACE** | Bullets don't coordinate. Accuracy comes from the shooter, the weapon, range, target motion and exposure | Per-shot ballistic hit model (§4) |
| 2 | Designed near-misses | Misses placed near V on purpose | **REPLACE** | Misses fall where dispersion puts them | Miss offset = dispersion sample (§4) |
| 3 | Forced vertical miss above low cover | Fixed Z offset | **REMOVE** | No in-world basis | Exposure fraction (§4) |
| 4 | Difficulty multiplier on hits | Story…Very Hard | **REMOVE** | Difficulty is world composition (§10) | — |
| 5 | Shooting-pattern delays | Authored per-shot table | **REPLACE** | Pauses come from recoil recovery, re-acquiring the target, and intent | Cadence model (§3) |
| 6 | Zero delay (CR) | Global 0 | **Sometimes right** | Correct for suppressive fire, mounted weapons, borg arms. Wrong for an untrained ganger aiming | Emerges from the cadence model (§3) |
| 7 | Melee ticket = 1 | One attacker at a time | **REPLACE** | Real limit: body space around the target, weapon reach, friendly-fire risk | Physical attack slots (§5) |
| 8 | CatchUp tickets + 30 s cooldown | At most 2 pursuers | **REPLACE** | Who pursues depends on orders, doctrine, morale and information | Doctrine pursuit + last-known-position age (§5, §6) |
| 9 | Ring tickets | Caps NPCs per distance ring | **REPLACE** | Positions are limited by real cover and standoff by weapon | Cover/position reservations (§5) |
| 10 | Quickhack ticket | Global cap | **REPLACE** | Real limits: a network connection, target identification, upload time against V's ICE, the deck's RAM | Network model (§6.3) |
| 11 | Grenade ticket + cooldown | Throttled | **REPLACE** | Real limit: how many grenades they carry, plus doctrine (corps avoid property damage) | Inventory + doctrine (§7) |
| 12 | Peek tickets, wait-in-cover cooldown | Throttled | **REPLACE** | Exposure is risk-weighted by suppression | Suppression model (§9) |
| 13 | Strafe/dodge cooldowns | Flat seconds | **REPLACE** | Stamina and reflexware | Stamina/reflex budget (§8) |
| 14 | NPC smart lock 3 s / 0.5 s | Authored | **REPLACE** | A lock depends on the smartlink and the target's ECM | Shared smartlink table (§8) |
| 15 | Sniper laser | Always visible | **REPLACE** | Snipers don't advertise. Lasers are for designators, smart targeting or the untrained | Loadout-driven. Scope glint kept (§8) |
| 16 | Threat tracking `RealPosition` | Possible omniscience | **REMOVE CHEAT** | NPCs know what they perceive or are told | Belief/last-known-position model (§6) |
| 17 | Instant squad knowledge | Shared tracking | **REPLACE** | Sharing needs comms (radio, holo, shouting range) | Comms channel, jammable (§6.2) |
| 18 | Trace reveals V instantly (vanilla) | Hacking an NPC reveals V | **REPLACE** | Tracing needs tracing ICE or a netrunner on the subnet | Trace via ICE/netrunner (§6.3). Trace Position Overhaul pattern |
| 19 | Detection meter factors | Flat factors × difficulty | **KEEP concept, ground values** | Recognition takes time | Senses from optics chrome, light, distance, movement, noise (§6.1) |
| 20 | Search, then forget | Give up after a timer | **REPLACE** | Disciplined forces escalate (lockdown, sweep in pairs). Gangs lose interest by morale | Doctrine search (§6.4) |
| 21 | Optical camo raises TBH coefficient | Camo is a hit-timer penalty | **REPLACE** | Camo defeats eyes, not thermal or sound. It shimmers when you move | Perception-based camo (§6.1) |
| 22 | Restricted movement areas | Invisible arena walls | **REPLACE** | Guards hold their post. Gangs chase within turf. NCPD and MaxTac pursue freely. Quest NPCs stay fenced for technical reasons | Doctrine leash (§5.4) |
| 23 | Level-scaled HP | Power-level curves make bullet sponges | **REPLACE** (SDP-owned) | Durability = body + armor + chrome + hit zone | Lethality model (§7.1) |
| 24 | Passive regen for many archetypes (CR) | Everyone regenerates | **REMOVE** | Needs biomonitor or regen chrome | Chrome-gated (§7.2) |
| 25 | Combat stims heal 60% in 5 s on a cooldown | Ability with a timer | **REPLACE** | The same items V uses, from a finite inventory, with visible, interruptible injection | Shared item table (§7.2) |
| 26 | Getting hit lengthens the shooter's TBH | Flinch via the hit timer | **REPLACE** | Flinching is real | Temporary dispersion penalty, reduced by pain editors or Berserk (§4) |
| 27 | Sandy-vs-Sandy override multipliers (8/16/32, or ENC 1.5–3) | Authored | **REPLACE** | Relative speed follows from both devices | Shared hardware table (§8.2, already in the world-progression plan §6) |
| 28 | Cyberware cooldowns scaled by difficulty | Authored | **REPLACE** | Heat and neural strain of the device | Shared device table (§8) |
| 29 | Hacks or Sandy on every class (CR) | Ability lists | **REMOVE** | NPCs can use only chrome they actually have installed | Loadouts per faction/role (§9.1) |
| 30 | Reinforcements spawn ahead of V (Reinforcements System: 25 m ahead) | Teleported waves | **REPLACE** | A call goes out, then a unit travels from somewhere | Call, then travel, and jammable (§6.2) |
| 31 | Unlimited stamina (CR: 1000) | | **REPLACE** | Sprint budget from body and chrome | §8 |
| 32 | HUD threat telegraphs (grenade marker, upload bar, detection arrows) | Always on | **KEEP, make diegetic** | Allowed when V's chrome could produce them (Kiroshi threat assessment, cyberdeck intrusion alert) | Chrome-gated HUD (§10.2) |
| 33 | Friendly-fire avoidance strafes | Present | **KEEP** | Real | — |
| 34 | Reaction delay at combat start | Present | **KEEP, ground** | Humans need 0.2–0.5 s, more when surprised. Kerenzikov shortens it | Reaction table (§9) |
| 35 | Spawn grace (`GracePeriodAfterSpawn`) and quest god-modes | Technical | **KEEP** | Engine and quest safety, not combat balance | — |

---

## 3. Burst pauses: is zero sensible?

**Short answer: sometimes.** A fixed delay is wrong and a global zero is wrong. The pause should come out of the physics that actually stop a shooter from firing again.

### 3.1 What really sets the time between shots

| Constraint | Physics / lore | Depends on |
|---|---|---|
| Cycle time | The weapon's rate of fire | Weapon |
| Recoil recovery | The muzzle climbs. Sights must settle before an *aimed* shot is worth taking | Weapon kick, shooter strength and training, cyberarms, smartlink stabilisation, stance or bracing |
| Re-acquisition | The target moved, or line of sight broke | Target angular speed, reaction time, Kerenzikov |
| Intent | *Suppressive* fire accepts poor accuracy. *Aimed* fire waits | Doctrine and the current order |
| Ammo and heat | Magazine, reload, Tech/Power charge, LMG heat | Weapon, inventory |
| Fear | Suppressed shooters fire blind or not at all | Suppression state (§9) |

### 3.2 The model

Accumulated recoil error `r` (mrad) grows by the weapon's kick per shot and decays at the shooter's recovery rate `k` (mrad/s):

```
r_after_shot = max(0, r - k * dt) + kick(weapon)
aimed fire : wait until r <= r_ok  (r_ok ≈ half the target's angular half-size, floor 1.5 mrad)
             pause = max(cycle_time, (r - r_ok) / k)
suppression: pause = cycle_time            ← the "zero" case, by intent
burst ends : aimed → when predicted p_hit (§4) < p_min(doctrine)
             suppression → ammo/heat/order, or LoS-free window closes
```

Starting values for an assault rifle (kick 2.5 mrad, cycle 0.1 s, r_ok 1.5 mrad):

| Shooter | Recovery `k` | Pause after 1 aimed shot | Pause after a 4-round burst | Suppressive fire |
|---|---:|---:|---:|---:|
| Untrained, no chrome (Scav, Animals) | 5 mrad/s | 0.20 s | **1.40 s** | cycle only |
| Trained (Arasaka, NCPD, 6th Street veterans) | 10 | 0.10 s | **0.55 s** | cycle only |
| Trained + smartlink stabiliser | 20 | 0.05 s | **0.13 s** | cycle only |
| Gorilla/borg arms + smartlink (MaxTac, Militech heavies) | 40 | cycle | **≈0.03 s** | cycle only |
| Mounted turret, mech, drone | 80+ | cycle | **≈0** | cycle only |

So CR's zero is correct in two cases: **any shooter laying down suppression**, and **recoil-compensated chrome or mounts**. For an untrained human taking aimed shots it is wrong by more than a second per burst. The design keeps realistic pauses everywhere they belong, and zero exactly where the world allows it.

### 3.3 Hook

```swift
// SDPCombat/Shooting/Cadence.reds   (signature verified against the vanilla decompile)
@replaceMethod(AISubActionShootWithWeapon_Record_Implementation)
public final static func QueueNextShot(weapon: wref<WeaponObject>, requestedTriggerMode: gamedataTriggerMode, const duration: Float) {
    let npc = weapon.GetOwner() as NPCPuppet;
    if !IsDefined(npc) || !SDPCombatRegistry.IsEnrolled(npc) {
        // native fallback, byte-for-byte the vanilla body
        let delayFromPattern: Float;
        let pattern = AIWeapon.GetShootingPattern(weapon);
        if IsDefined(pattern) {
            delayFromPattern = AIWeapon.GetShootingPatternDelayBetweenShots(AIWeapon.GetTotalNumberOfShots(weapon), pattern);
        }
        AIWeapon.QueueNextShot(weapon, requestedTriggerMode, duration, delayFromPattern);
        return;
    }
    let delay = SDPCadence.NextShotDelay(npc, weapon);   // recoil state + intent + reacquire
    AIWeapon.QueueNextShot(weapon, requestedTriggerMode, duration, delay);
}
```

Notes:

- `SDPCadence` keeps `r` per actor and weapon. It updates on each queued shot and decays with sim time, so no tick is needed.
- Combat Evolved replaces the same method. CE must stay disabled in the SDP profile, which it already is.
- `AISubActionShootWithWeapon` records also carry `numberOfShots` / `maxNumberOfShots`. Raise those so that our burst-end rule, not the record, ends a burst.

---

## 4. Hit model: replacing the shared clock with ballistics

### 4.1 Model

Treat each shot as an angular error drawn from a circular Gaussian. The shot hits if it lands inside the target's **exposed** angular radius.

```
α        = atan(halfWidth × exposure / distance)                       target angular radius, mrad
σ_total² = σ_weapon² + σ_shooter² + σ_lead² + r² + σ_vis²
σ_lead   = (lateral speed / distance) × reaction_time × (1 − tracking)
p_hit    = 1 − exp(−α² / (2·σ_total²))
```

| Term | Source | Starting values |
|---|---|---|
| `σ_weapon` | Weapon class, attachments | AR 1.5, SMG 3, pistol 3, sniper 0.3 mrad. Shotguns use pellet spread |
| `σ_shooter` | Training tier, smartlink, optics | Untrained 8, poorly disciplined 7, trained 4, smartlink 2, smartlink + Kerenzikov 1.5 |
| `reaction_time`, `tracking` | Training, Kerenzikov, smartlink | Untrained 0.35 s / 0.5. Trained 0.22 / 0.75. Smartlink 0.18 / 0.85. Kerenzikov 0.08 / 0.92 |
| `r` | Cadence state (§3) | Links pause length to accuracy |
| `exposure` | Visible fraction of V: line of sight to primary and secondary points, cover stance | 1.0 in the open, ~0.45 in half cover |
| `σ_vis` | Smoke, darkness, camo vs thermal, blinding | Large under camo without thermal. Blinded ≈ no aimed hits |
| Flinch | Recently hit, pain | +σ for 0.5–1 s, reduced by pain editors, Berserk or stims |

**Resulting hit chances** (starting values, V half-width 0.25 m):

| Shooter | Range | V standing | V strafing 3 m/s | V sprinting 6.5 m/s | V in half cover |
|---|---|---:|---:|---:|---:|
| Scav, Lexington pistol, untrained | 15 m | 85% | 10% | 2% | 32% |
| Maelstrom, Ajax AR, poor discipline | 30 m | 49% | 14% | 4% | 13% |
| Arasaka trooper, Ajax AR, trained | 30 m | 85% | 51% | 19% | 32% |
| Militech, smartlink + coprocessor | 30 m | 100% | 92% | 58% | 68% |
| MaxTac, Kerenzikov + smartlink | 30 m | 100% | 100% | 100% | 79% |

The table shows the design working:
- Movement and cover protect V for physical reasons (CR's "dynamic accuracy" idea, now per shot and per shooter).
- A gang's numbers matter less than a corp squad's training.
- MaxTac is terrifying, as the lore says.
- Each shooter rolls independently, so focus fire is genuinely dangerous. The counter is cover, smoke, breaking line of sight or killing the shooters, not a hidden timer.

### 4.2 Hook

```swift
// SDPCombat/Shooting/HitModel.reds   (replaces the vanilla TBH decision; signature from the decompile)
@replaceMethod(TargetShootComponent)
private final func ShouldBeHit(weaponOwner: GameObject, weapon: wref<WeaponObject>,
                               weaponRecord: WeaponItem_Record, visibilityThresholdCoefficient: Float) -> Bool {
    let target = this.GetGameObject();
    let shooter = weaponOwner as NPCPuppet;
    if !IsDefined(weaponOwner.GetSourceShootComponent()) { return true; }
    if !IsDefined(shooter) || !SDPCombatRegistry.IsEnrolled(shooter) {
        return this.SDP_VanillaShouldBeHit(weaponOwner, weapon, weaponRecord, visibilityThresholdCoefficient);
    }
    let shot = SDPShot.Build(shooter, weapon, target);                 // distance, lateral speed, exposure, vis, flinch
    shot.exposure = weaponOwner.GetSourceShootComponent().CanSeeSecondaryPointOfTarget(target) ? 1.0 : 0.45;
    shot.visionBlock = this.GetVisionBlockersCoefficient(weaponOwner, target);   // vanilla smoke/occlusion term
    let p = SDPHitModel.Probability(shot);                              // §4.1
    SDPTelemetry.Shot(shooter, target, p);
    return RandF() < p;
}
```

`SDP_VanillaShouldBeHit` is an `@addMethod(TargetShootComponent)` holding a copy of the vanilla body. It has to live on the same class because the vanilla helpers it calls (`GetVisibilityCoefficient`, `CalculateTimeBetweenHits`, ...) are private.

Misses still go through native `CalculateMissOffset`. Set `TimeBetweenHits.missShotOffset.minimumDistanceAroundTarget` to 0 and the spread angles small, so misses look like near misses from dispersion, not shots placed safely away from V. Note that `HandleBeingShot` still records `LastHitTime`, but our decision no longer reads it, so the shared clock no longer has any effect.

---

## 5. Engagement capacity: tickets become physical slots, doctrine and orders

### 5.1 What really limits simultaneous attackers

| Activity | Real limit |
|---|---|
| Melee | Space around V: weapon reach needs an arc (knife ~60°, katana ~90°, hammer/fists ~120°). Walls and corridors remove arcs. Attacking through an ally is friendly fire |
| Shooting | Lines of fire that don't cross allies. Cover positions that exist |
| Pursuit | Orders and doctrine: who holds, who chases. Morale |
| Grenades | Grenades carried. Allies inside the blast radius |
| Hacks | A network connection, target ID, the runner's deck |

### 5.2 Slot system

```
            ┌─────────────────────────── SDPEngagement (per encounter) ───────────────────────────┐
 navmesh ──►│ arc sampler around V (8–12 rays, 1.5–3 m) ──► free arcs ──► melee slots            │
 cover   ──►│ cover/position reservations by role standoff                    ──► firing posts    │
 allies  ──►│ friendly-fire cone check                                        ──► line validation │
 doctrine──►│ caps by training: mob ≤ physical, trained squads assign base of fire vs maneuver     │
 leader  ──►│ coordination capacity (alive leader + comms)                                        │
            └──────────────┬───────────────────────────────────────────────────────────────────────┘
                           │ grant / revoke
                           ▼
           status effect with gameplay tag  SDP_MeleeSlot / SDP_PursueOrder / SDP_FlankOrder ...
                           │
                           ▼  (native AI reads it)
           AIStatusEffectCond { target: Owner, gameplayTag: SDP_MeleeSlot } added to ticket activation
```

**The bridge is verified against vanilla code.** `AIStatusEffectCond_Record` has `Target`, `StatusEffect`, `StatusEffectType` and **`GameplayTag`**, and `Check` calls `StatusEffectSystem.ObjectHasStatusEffectWithTag`. So redscript decides, applies a tagged status effect, and the native behaviour tree gates on it. Native AI still does the animation, navigation and attack.

```yaml
# SDPCombat/tweaks/Engagement.yaml  (TweakXL)
SDPCombat.MeleeSlot:                    # carrier status effect, infinite, removed by our system
  $base: BaseStatusEffect.SandevistanBuff     # any simple effect to clone; verify in the dump
  gameplayTags: [ SDP_MeleeSlot ]
  duration: SDPCombat.InfiniteDuration       # define or reuse an infinite duration record

SDPCombat.Cond_HasMeleeSlot:
  $type: gamedataAIStatusEffectCond_Record
  target: AIActionTarget.Owner
  gameplayTag: SDP_MeleeSlot

Tickets.Melee:
  maxNumberOfTickets: -1                # the cap now comes from SDPEngagement
  activationCondition:
    - !append SDPCombat.Cond_HasMeleeSlot
```

Verify after Phase 0: ticket `activationCondition` entries may need to be `gamedataAIActionCondition_Record` wrappers (`condition: SDPCombat.Cond_HasMeleeSlot`), as CR does for its Sandy condition. Also pick the carrier effect's `$base` from the dump.

### 5.3 Doctrine sets how many slots are used, not the engine

| Faction (lore) | Training | Melee | Fire and maneuver | Comms |
|---|---|---|---|---|
| Scavengers, Animals | Untrained | Swarm up to the physical limit, often blocking each other | None. Everyone shoots. Friendly fire happens | Shouting range |
| Maelstrom | Chrome-heavy, poor discipline | Heavy rushes, Berserk | Weak | Radio, unreliable |
| Tyger Claws, Valentinos | Gang-trained | Tyger melee specialists take the free arcs | Pairs | Radio |
| 6th Street | Ex-military veterans | Rare | **Fire-team doctrine** | Radio, disciplined |
| NCPD | Police procedure | Rare | Contain and wait for backup | Dispatch |
| Arasaka, Militech, Kang Tao, Barghest | Professional | Only to finish someone | Base of fire + maneuver, bounding overwatch | Encrypted tactical net |
| MaxTac | Elite | Borgs and mantis users take arcs deliberately | Full doctrine plus overwhelming force | Command net |

### 5.4 Pursuit and leash

The replacement for CatchUp tickets and movement areas:

- **Guards** (corp facilities, gang safehouses) leash to their asset, unless ordered to pursue.
- **Gangs** pursue within their turf plus a morale-scaled margin. They stop at rival turf, which is diegetic and readable.
- **NCPD and MaxTac** pursue freely, using the dispatch logic in §6.2.
- **Quest-controlled actors** keep native restrictions. This is a technical safety rule, and the registry never enrolls them (backend §2).
- **Who pursues** comes from the squad order: trained squads send a pair and hold the rest, mobs send everyone whose morale is high.

`ignoreRestrictedMovementArea` is set to true only on the pursuit/flank actions, and only together with `Cond_HasPursueOrder`.

---

## 6. Information model

### 6.1 Perception

- **Senses come from chrome:**
  - eyes vs Kiroshi grades (range, zoom)
  - thermal (sees through camo and smoke, not walls)
  - wall-sensing chrome (`CanSeeThroughWalls`, rare and scannable)
  - hearing (shots, sprinting, doors; ENC's door alert is a good example)
- **Detection meter kept**, with factors from lighting, distance, movement, stance and the observer's optics instead of difficulty.
- **Optical camo** removes visual detection beyond ~5 m while V is still. It shimmers while V moves. It does nothing against thermal, sound or a smartlink's lock memory.

### 6.2 Belief, sharing and comms

```
each NPC: belief = {position, velocity, time, confidence, source}
  sight      → exact, refreshed each perception tick
  sound      → position ± error by distance
  report     → copy of a squadmate's belief, delayed by comms latency
  trace      → network trace result (§6.3)
confidence decays with age; actions require confidence ≥ action threshold
```

- **Sharing goes through a comms channel per squad.** Vocal range (~25 m) always works. Radio or holo works if the squad has comms gear, and a jamming quickhack or EMP cuts it. Taking out the leader or the radio operator degrades coordination. This is counterplay V can see and understand.
- **Tracking modes (measured targets, §1.4):** retarget the 538 `RealPosition` action targets for enrolled actors. Cover shooting uses the actor's own `BeliefPosition`, so the enemy fires where it last saw V. Squad-level actions use `SharedLastKnownPosition`. Share between actors only through the comms channel below: our script fills shared belief, so jamming, distance and a dead radio operator take effect. Set `moveBeliefOnlyIfVisible = true` on the enemy presets (Default, Boss, Cyberpsycho, Prevention). The record list comes from `tools/SDPVanillaDump/console_tracking.lua`.
- **Avoiding hostility to companions:** don't edit the shared `AIActionTarget` records in place, or companions are affected too. Clone the affected actions under `SDPCombat.*` and point only enrolled actors' action maps at the clones.
- **Reinforcements:** a call is an action (radio animation, interruptible) that creates a dispatch. The dispatched unit spawns out of sight at a plausible origin and drives in, with travel time. Reinforcements System stays the optional vehicle dispatcher, with our admission limit (backend §2).

### 6.3 Netrunning

| Step | Requirement | Counterplay for V |
|---|---|---|
| Identify V | Visual ID via optics, or a ping hack | Camo, staying out of sight |
| Connect | Same subnet or access point, or proximity link | Leave the network, kill the access point |
| Upload | Time = hack size vs V's ICE (cyberdeck and ICE shards) | Interrupt the runner, break line of sight, ICE upgrades |
| Concurrency | Each runner is limited by their deck's RAM and cooldowns, **not a global ticket** | Kill or disrupt the runners |
| Trace | Only a network with tracing ICE or an active netrunner traces V (Trace Position Overhaul's pattern) | Proxy hacking, reverse trace (V's deck feature) |

### 6.4 Search and escalation

There is no "forget after N seconds". Doctrine picks a search plan:
- Corps lock down, hold chokepoints, sweep in pairs and request drones.
- NCPD sets a perimeter and waits for backup.
- Gangs search by morale and loudly lose interest. The leader may order a stay-out-of-sight hold.

Alert state persists for the session through the encounter memory planned in the backend (optional They Will Remember later).

---

## 7. Durability and sustain

### 7.1 Lethality model (SDP-owned, required by §4)

Once the hit timer is gone, the bullet-sponge curve becomes the only thing holding fights together, and it is itself a crutch.

- **Replace level-scaled NPC HP** with body + armor + chrome:
  - Body: an unaugmented human dies from a few rifle hits to the torso and one to an unprotected head.
  - Armor: clothing armor and subdermal plating (light, medium, heavy) reduce damage per caliber class.
  - Chrome: borg plating, armored skull.
- **V gets the same model.** V survives by having better chrome than a Scav (subdermal armor, Kerenzikov, Sandy, optics warnings), not through hidden NPC handicaps.
- **Calibrate armor values**, not hidden multipliers, until fights last as long as intended. That calibration is legitimate because it is diegetic: armor class is something V can scan and plan around.

### 7.2 Healing

- **One item table for V and NPCs.** MaxDoc, BounceBack and combat stims. NPCs carry a finite count (corp troopers 1–2, gangers 0–1, MaxTac more) and use them with a visible, interruptible injection animation.
- **No cooldown timer.** The inventory is the limit.
- **Regeneration exists only with regen chrome** (biomonitor, blood pump, Second Heart analogues). It is scannable, and EMP or Cyberware Malfunction can interrupt it.
- **Stims as combat drugs** mainly suppress pain and stagger for a while, and only heal if the drug says so.

### 7.3 Grenades

Grenades come from the NPC's inventory (Scav 0–1, trooper 1–2, MaxTac 2–3 including flash and EMP) and are thrown when V is in cover and the belief is fresh. Doctrine filters:
- Corps avoid frag grenades inside their own facilities and prefer flash or EMP.
- Nobody throws if an ally is inside the predicted blast radius.

---

## 8. Cyberware and time: one hardware table

### 8.1 Shared device table

One table, keyed by device model and grade and used by V and NPCs alike:
- duration
- cooldown (heat and strain)
- effect strength
- smartlink lock time and tracking
- recoil stabilisation
- Kerenzikov reaction factor
- stamina capacity

NPC values are **never authored separately** from V's. Difficulty does not touch this table.

### 8.2 Sandevistan vs Sandevistan

Relative speed comes from both devices. With global scale `g` (V's Sandy), the NPC's own Sandy speed-up `s_npc` (from the table) and V's speed-up `s_V = 1/g`:

- An NPC without Sandy runs at `g`.
- An NPC with Sandy runs at `g × s_npc`. With equal hardware V and the NPC move alike. Superior hardware wins.
- CR's override of 32 and ENC's 1.5–3 are both replaced by `s_npc` from the shared table.

This is the same model as WORLD_PROGRESSION_PLAN §6, now with the source of the multiplier fixed. Time Dilation Overhaul's `GetSandevistanVsSandevistanSpeed` (using `GetActiveTimeDilation(n"sandevistan", true)`) is a working reference for reading V's live dilation.

---

## 9. Smarter decisions

### 9.1 Loadouts are physical

An NPC can use an ability only if the chrome or item is installed and listed on its scannable loadout. This rules out CR-style hacks on every rifleman. Faction and role kits come from ENC's authored groups (adapted, with credit), checked for animation compatibility (backend §3).

### 9.2 Decision layer

```
 perception/beliefs ─► threat assessment of V ─► doctrine planner ─► orders ─► engagement slots ─► native actions
        ▲                     │                        │                                │
        └── comms ◄───────────┴──── squad state ◄──────┴──── outcomes (hits, losses, suppression) ◄─┘
```

- **Threat assessment** draws on what the squad has *observed or scanned*:
  - V used a Sandevistan → trained squads keep distance, use shotguns and flash grenades.
  - V snipes → smoke, then flank.
  - V hacks → find the hacker's position through a trace, push it, call a runner.
  - V wears heavy armor → AP rounds and grenades, if carried.
  - No adaptation from information they couldn't have.
- **Fire and maneuver** (trained factions): one element suppresses (the §3 zero-pause case) while another moves cover to cover. Bounding overwatch on advance. The flank requires a fresh belief, with the CE pattern as inspiration (rewritten, since CE needs permission).
- **Suppression and morale:** near misses and hits build pressure, so suppressed shooters fire blind or hold cover. Morale drops with casualties and losing the leader, which leads to retreat or surrender. Exempt: cyberpsychos, borgs, drugged Animals.
- **Reload discipline:** reload in cover with an audible "Reloading!" callout (a diegetic cue). Trained squads stagger reloads.
- **Leader effect:** coordination capacity comes from a living leader with comms. Killing the leader turns a squad into a mob. This is the main tactical counterplay, and it rewards scanning.
- **Reaction times:** first reaction 0.2–0.5 s, longer when surprised, shorter with Kerenzikov (shared table).

---

## 10. Consequences

### 10.1 Difficulty becomes world composition

| Lever | Example |
|---|---|
| Training mix | Scav-heavy vs corp patrols |
| Gear grade | Chrome and weapon grades by district and threat band (WORLD_PROGRESSION_PLAN §3) |
| Numbers | Squad size, dispatch limits |
| Information | Alert state, network tracing, drones |

The `TimeBetweenHits` difficulty multipliers and ticket caps are no longer used for enrolled actors.

### 10.2 Diegetic HUD (optional module)

Gate HUD warnings by V's chrome:

| HUD element | Requires |
|---|---|
| Grenade marker, threat arrows | Kiroshi grade with threat assessment |
| Incoming-upload bar | Cyberdeck with intrusion alert |
| Sniper warning | Optics, or ears (sound cue) |

This fits SDP's chrome progression, and it keeps the warnings that make realistic lethality survivable while tying them to the world.

### 10.3 Risk

Realistic lethality without the §7.1 durability work will feel unfair. Ship §4 and §7.1 together, behind one opt-in profile, and benchmark against vanilla, ENC and CE (backend §6).

---

## 11. Architecture and ownership

```
SDPCombat/
├─ tweaks/                 (TweakXL)
│  ├─ Engagement.yaml        tag carriers, AIStatusEffectCond records, ticket caps → -1 + gates
│  ├─ Perception.yaml        threat-tracking presets → LKP/shared-LKP, senses per optics grade
│  ├─ Devices.yaml           shared hardware table (V + NPC)
│  └─ Loadouts/*.yaml        frozen faction/role kits (ENC-derived, credited)
├─ scripts/                (redscript)
│  ├─ Registry.reds          enrollment, eligibility (no quest/companion/neutral actors)
│  ├─ Shooting/HitModel.reds @replaceMethod TargetShootComponent.ShouldBeHit
│  ├─ Shooting/Cadence.reds  @replaceMethod AISubActionShootWithWeapon…QueueNextShot
│  ├─ Engagement.reds        slot sampler, reservations, tag grant/revoke, leash
│  ├─ Beliefs.reds           belief store, comms channel, jamming, trace
│  ├─ Doctrine.reds          faction plans, orders, suppression/morale, leader capacity
│  ├─ Time.reds              Sandy/Kerenzikov coordinator (shared table)
│  └─ Telemetry.reds         shots, p_hit, slots, orders, TTK, frame cost
└─ cet/SDPVanillaDump/       Phase 0 data capture (dev only)
```

**Methods replaced** (no other enabled mod may replace or wrap these):
- `TargetShootComponent.ShouldBeHit`
- `AISubActionShootWithWeapon_Record_Implementation.QueueNextShot`

CE replaces both, so CE stays off. ENC's `BreakHold.reds` touches different methods (grapple).

Every replaced method falls back to a copy of the vanilla body for non-enrolled actors, so companions, quest NPCs and anything outside the test selection behave as vanilla.

---

## 12. Delivery plan

| Phase | Scope | Acceptance |
|---|---|---|
| **0. Capture** | CET dump of vanilla records (below). Telemetry baseline on 4 benchmark encounters | JSON committed. Vanilla p_hit and TTK, slot usage and pursuer counts logged |
| **1. Shots** | §3 cadence + §4 hit model + §7.1 armor calibration, 2 factions (Maelstrom, Arasaka) | Hit rates match the §4.1 table ±10 percentage points. Pauses match §3.2. Fights end inside the target TTK band without hidden multipliers |
| **2. Engagement** | §5 slots + tag bridge, doctrine leash, pursuit orders | Melee attackers = free arcs (open floor ≥3, corridor 1). No arena-wall freezes. Quest NPCs untouched |
| **3. Information** | §6 beliefs, comms, jamming, last-known-position presets, trace rules | No action fires on stale or impossible information. Jamming visibly breaks coordination. Leader kill degrades the squad |
| **4. Sustain and devices** | §7.2–7.3 inventory items, chrome-gated regen, §8 shared device table, Sandy relative speed | NPC healing is finite and visible. Equal Sandy hardware means equal speed |
| **5. Decisions** | §9 threat assessment, fire and maneuver, suppression and morale | Benchmark encounters show completed flanks, suppression-then-move, retreat or surrender |
| **6. HUD** | §10.2 chrome-gated warnings | Warnings appear only with the right chrome |

### Phase 0 dump script (dev-only CET mod)

The script lives in the repo at `tools/SDPVanillaDump/`:

| File | Use |
|---|---|
| `init.lua` | Copy the folder to `<game>\bin\x64\plugins\cyber_engine_tweaks\mods\SDPVanillaDump\`. It runs at game start and writes `vanilla_dump.json` into that folder. Re-run from the CET console with `GetMod("SDPVanillaDump").run()` |
| `console_paste.lua` | A single line with no comments, for pasting straight into the CET console. The console joins lines, so any `--` comment would swallow the rest of a multi-line script |

Both files were syntax-checked and run against a mocked TweakDB under Lua 5.1 (CET's LuaJIT dialect).

- **Disable the donor mods first.** Disable ENC, Combat Revolution, Combat Evolved and Harder Gunfights before running, or the dump contains their values instead of vanilla.
- **Unconfirmed type names report themselves.** Each type prints a record count, and a type name the game doesn't know prints `unknown type`. That shows which of the unconfirmed type names (`gamedataSenses_Record`, the threat-tracking subtypes) need correcting.
- **Output format:** arrays of record IDs are written as name lists, and CNames as strings.

---

## 12a. Phase 1 implementation (2026-10-05)

Phase 1a is the shot model only. Armor and HP calibration (§7.1) comes after measurement, as Phase 1b.

| File | Contents |
|---|---|
| `r6/scripts/SDPCombat/SDPCombatSystem.reds` | Runtime switches and telemetry (`ScriptableSystem`, CET-callable) |
| `r6/scripts/SDPCombat/SDPProfiles.reds` | Training tier from affiliation and rarity, chrome adjustments, weapon dispersion and kick tables, recoil state (fields added to `NPCPuppet`) |
| `r6/scripts/SDPCombat/SDPHitModel.reds` | `@wrapMethod(TargetShootComponent) ShouldBeHit`: §4 probability for enrolled shooters firing at V |
| `r6/scripts/SDPCombat/SDPCadence.reds` | `@wrapMethod(AISubActionShootWithWeapon_Record_Implementation) QueueNextShot`: §3 recoil and intent pauses |
| `r6/tweaks/SDPCombat/MissOffset.yaml` | Designed misses land 0.6 m from V instead of 1 m (cosmetic) |

**Wraps, not replacements.** Both hooks use `@wrapMethod` and call the vanilla body for everything not enrolled, so no vanilla code is copied.

**Enrolled:**
- **Shooters:** Maelstrom and Arasaka, bosses excluded. `SetAllHostiles(true)` widens this to every hostile NPC.
- **Shots:** only shots at V. Companions and NPC-vs-NPC fights stay vanilla.

**Phase 1a simplifications:**
- Tech weapons that pierce walls defer to vanilla.
- Cover exposure is binary: 1.0, or 0.45 behind cover.
- The pause logic uses V as the reference target.
- Flinch, optical camo and the first-shot aiming delay are not modelled yet.

**Compile checks:**
- redscript 0.5.31 (the version the game uses) against `.stage/prototype-build3-wj1epvf2/full-modset.redscripts`: success.
- redscript 1.0.0-preview.22 against `prototype.redscripts`: success.
- No mod in the current build hooks either method.

**CET console controls:**

```lua
local s = Game.GetScriptableSystemsContainer():Get("SDPCombat.SDPCombatSystem")
s:Report()              -- hit rate, mean p, mean pause and zero pauses per training tier
s:ResetStats()
s:SetEnabled(false)     -- A/B against vanilla without reloading
s:SetLogShots(true)     -- per-shot line: tier, faction, weapon, distance, lateral speed, exposure, sigma, alpha, p, hit
s:SetAllHostiles(true)
```

**Phase 1a acceptance test.** Run Maelstrom (Poor discipline) and Arasaka (Trained) fights. In each, stand still at about 15–30 m, then strafe, then take half cover. Compare `Report()` hit rates with the §4.1 table, ±10 percentage points. Compare mean pauses with §3.2. Repeat with `SetEnabled(false)` to get the vanilla time-to-kill.

### Phase 1a results: Maelstrom, 2026-10-05

Two in-game runs against Maelstrom (Poor discipline tier) with rifles, read from `gamelog.log`.

**Run 1** (19:46, 30-second phases, summary only):

| Phase | Shots | Actual hit rate | Predicted (mean p) | Mean pause |
|---|---:|---:|---:|---:|
| V standing still | 40 | 35% | 33.5% | 0.27 s |
| V strafing | 41 | 14.6% | 18.0% | 0.29 s |

**Run 2** (20:15–20:16, 82 s, 235 aimed shots plus 14 blocked for no line of sight, full per-shot data):

| Grouping | Shots | Actual | Predicted | Mean distance |
|---|---:|---:|---:|---:|
| All | 235 | 25% | 24% | 20 m |
| V exposed | 152 | 27% | 29% | 17 m |
| V partly covered (crouched behind cover, 20:16:00–20:16:30) | 83 | 20% | 16% | 24 m |
| V still (< 0.3 m/s sideways) | 153 | 27% | 28% | 22 m |
| V strafing (1.5–4 m/s) | 38 | 16% | 16% | 17 m |
| V sprinting (> 4 m/s) | 28 | 4% | 5% | 13 m |

Pauses: 571 recorded, mean 0.26 s (vanilla's authored mean is 1.09 s). They are 0.16 s while V is exposed and 0.31 s while V is partly covered: a smaller target makes these shooters wait for a steadier aim. There was no suppressive fire, which is as designed, because Maelstrom are tier 1 and suppression starts at tier 2.

Conclusions:
- **Correction:** predicted and actual hit rates agreed in every group, but in Phase 1a every hit was decided by a roll against that same predicted chance, so the agreement only confirms the code runs as written. It says nothing about realism. Realism is checked against the design targets and, from Phase 1b on, against physical projectile hits.
- **Movement and cover protect V for physical reasons.** Sprinting gives about 4%, strafing 16%, cover cuts hits by about a third.
- **Lethality is the open issue.** The run produced roughly 60 hits on V in 82 s from a handful of Maelstrom. Without the shared hit timer, Phase 1b (durability and armor, §7.1) is required before this is playable outside test mode.
- **Test god mode:** the game accepts `Immortal` for V but not `Invulnerable`.

## 12b. Aim point and durability base (2026-10-05)

**Aim point replaces the hit roll.** In vanilla an NPC fires a real projectile at a point about 0.15 m below V's head slot, plus an offset returned by `TargetShootComponent.HandleBeingShot` (`AIWeapon` fire path: `projectileParams.hitPlaneOffset`). The projectile's own collision with V decides the hit. SDPCombat wraps `HandleBeingShot` for enrolled shooters and returns a sampled aim error. The bullet then physically goes where the shooter's error put it:

| Component | Model |
|---|---|
| Lag (directional) | The aim point trails V by V's sideways speed × reaction × (1 − tracking). A shooter who lags misses behind V; one with good tracking leads |
| Misjudged lead | Gaussian, σ = 0.35 × V's sideways speed × reaction. A moving V jinks unpredictably; Kerenzikov (short reaction time) shrinks it |
| Spread | Gaussian, σ = √(weapon² + shooter² + (1.5 × shooter speed)²) mrad × distance, scaled up by smoke and ×6 when the shooter is blinded |
| Recoil | Accumulated climb: 0.6 × recoil upward, ±0.3 × recoil sideways |
| Aim | Centre of mass (0.35 m lower, 0.25 m when V crouches) while V is fully visible; head and shoulders while V is behind cover |
| Excluded | Guided smart rounds and wall-piercing tech shots keep vanilla handling |

**Shooter aim error under combat stress** (re-tuned 2026-10-05 by offline simulation; the earlier 8/7/4/2.5/2 mrad described calm marksmen):

| Tier | Aim error |
|---|---:|
| Untrained | 18 mrad |
| Poor discipline | 14 |
| Trained | 7 |
| Elite | 4 |
| Mechanical | 3 |

A smartlink multiplies aim error by 0.6.

**Simulated hit rates** at 25 m:

| Shooter | V still | V strafing | V sprinting | V behind cover |
|---|---:|---:|---:|---:|
| Scav | 32% | 17% | 7% | 12% |
| Maelstrom | 43% | 24% | 11% | 19% |
| Arasaka | 82% | 52% | 28% | 52% |
| Elite | 98% | 70% | 40% | 80% |
| MaxTac (Kerenzikov + smartlink) | 100% | 97% | 79% | 93% |

**Durability base (`SDPDurability.reds`).** `@wrapMethod(DamageSystem) ProcessArmor` owns armour for ranged bullet hits between V and enrolled NPCs, in both directions:

| Step | Rule |
|---|---|
| Protection | P = 8 × a / (1 + a), where a = Armor × the game's armour effectiveness (× V's `ArmorEffectivenessMultiplier`). This uses the same stat as vanilla, so V's build still matters |
| Penetration chance | 1 / (1 + e^(−1.6 × (caliber − P))) |
| Caliber ratings | Pistol/SMG 2, revolver 3.5, shotgun 1.5, rifle/LMG 4, precision 5, HMG 6, sniper 6.5; tech weapons +1.5, plus 4 × the weapon's armour-ignore value |
| Stopped round | Blunt damage: 0.20 of the hit, or 0.30 on the head |
| Hit zones, NPC → V | From the shooter's sampled aim point: head ×2.5, torso ×1.0, legs ×0.6 |
| Hit zones, V → NPC | Vanilla localized damage, unchanged |

`ProcessOneShotProtection`, vanilla's cap on how much of V's health one NPC hit can take, is **removed for enrolled shooters** (default off since 2026-10-05). `SetOneShotProtection(true)` restores it, for comparison only. `SetIncomingScale(x)` is a temporary calibration knob.

**What protection levels mean.** P = 8 × the share of damage vanilla armour would have removed, so P 4 is armour vanilla rated at 50%.

| P | Lore picture |
|---:|---|
| 0 | Street clothes |
| 1–2 | Armoured jacket or light subdermal plating |
| 3–4 | Security vest plus subdermal plating |
| 5–6 | Military plating |
| 7+ | Borg or heavy plating |

**Chance that a round penetrates:**

| Caliber | P 0 | P 1 | P 2 | P 3 | P 4 | P 5 | P 6 | P 7 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Shotgun pellet (1.5) | 92% | 69% | 31% | 8% | 2% | 0% | 0% | 0% |
| Pistol / SMG (2) | 96% | 83% | 50% | 17% | 4% | 1% | 0% | 0% |
| Revolver (3.5) | 100% | 98% | 92% | 69% | 31% | 8% | 2% | 0% |
| Rifle / LMG (4) | 100% | 99% | 96% | 83% | 50% | 17% | 4% | 1% |
| Precision rifle (5) | 100% | 100% | 99% | 96% | 83% | 50% | 17% | 4% |
| HMG (6) | 100% | 100% | 100% | 99% | 96% | 83% | 50% | 17% |
| Sniper (6.5) | 100% | 100% | 100% | 100% | 98% | 92% | 69% | 31% |

**Not modelled in the base:**
- Separate head armour; the whole body uses one Armor value.
- Armour wear.
- Melee, explosions, damage over time and quickhacks, which keep vanilla armour.

**Not changed yet:** vanilla level-scaled health and weapon damage. That is the next durability step.

**Telemetry.** `Report()` now also prints the sampled aim zones and the physical hits per direction (penetrated count, mean damage as % of max HP, zone counts). Comparing sampled on-body aim points with physical damage events validates the offset model. `Status()` prints V's max HP, Armor and protection level.

## 12c. Weapon handling, armour, visibility and tooling (2026-10-05/06)

### Where an enemy's gun numbers come from

A gun in an NPC's hands runs on the item's reduced NPC stat package, which carries only fire rate and the AI aim fudge values. `SDPWeaponStats` takes each stat from that package when it is set there. Otherwise it evaluates the gun's own definition with the game's evaluator (`RPGManager.CalculateStatModifiers`):
- the weapon record's `statModifiers` and its `statModifierGroups`, recursively
- every installed mod or attachment part: the part's own modifiers plus its on-attach stats. Receivers and magazines are skipped, because they are the gun's base parts.

| Number | Source |
|---|---|
| Fire rate | The NPC package (the game's real value) |
| Spread (aimed, else hip); crouch, moving and maximum spread; spread reset | Gun and mods |
| Recoil kick, direction, angle, alternate, hold, recovery, drift | Gun and mods; kick × the shooter's recoil control |
| Sway | Gun and mods × the shooter's steadiness |
| Aim-in time | Gun and mods ÷ the shooter's skill |
| Effective and maximum range, damage falloff curves | Gun and mods |
| Calibre (armour penetration) | Weapon class table, plus tech and armour-ignore |
| Damage per hit | **Not the gun:** the game's level-scaled NPC damage (decided 2026-10-06), then armour, falloff and the zone rules |

Tier already changes handling through the gun's own curves: two unmodded Ajaxes logged spread 1.75 vs 1.85 mrad and kick 10.5 vs 11.1 mrad.

**How the stats are applied:**
- **Spread:** σ = 0.5 × spread (degrees → mrad). Sustained fire widens the cone 1/8 of the way from default to maximum (4× default) per shot. After the gun's reset time (0.2 s) it shrinks at the reset speed. This growth rule is built into the engine for V, so the 1/8 is an estimate.
- **Recoil:** each shot displaces the muzzle along the gun's recoil direction, randomised within ± half the angle and mirrored on alternating guns. **Drift** (confirmed in game: bursts zig-zag) adds a random sideways kick of 20–90% of the kick. It grows with the accumulated climb until the climb reaches `RecoilMagForFullDrift` (3°). The kick holds for the hold time, then settles at kick ÷ recovery time × skill.
- **Recoil control by shooter tier:** untrained 0.60, poorly disciplined 0.50, trained 0.36, elite 0.28, mechanical 0.20 of the raw kick. Elite matches V's build: her Ajax kicks 0.13–0.20° against the raw 0.48–0.72°.
- **Sway** (larger reading confirmed in game): the sights swing a full step of 1–1.5° to alternating sides, each swing taking about 5 s, around a centre that wanders within the gun's 0.15–0.4°. Scaled by steadiness: untrained 1.0, poorly disciplined 0.85, trained 0.6, elite 0.45, mechanical 0.05, with smartlink ×0.7. It blends in over the gun's start-blend time.
- **Range:** scatter goes from ×1 at effective range to ×2 at maximum. Trained shooters hold fire beyond maximum range. NPC rounds now use the gun's own falloff curves too; vanilla applies them to V's shots only.

**Damage by gun, tier and mods: moved to the weapons and crafting design.**
- **Why it moved:** that work will define each gun's damage table (base per model, tier multiplier, mod effects) for V and enemies alike, and enemy loadouts can be randomised from it.
- **What was tried:** `Inventory.CreateItemData` returns item data with every stat at zero. Adding modifiers to it was the prime suspect for the 00:40 crash, so that path was removed.
- **Interim:** keep the game's scaled numbers. `SetIncomingScale` remains available as a temporary dial.

### Visibility, cover and blind fire

**6-point line of sight.**
- **The test:** at each sampled shot, rays run from the muzzle to V's head, both shoulders, chest, pelvis and knees, measured from her actual head slot. Each stops 0.35 m short so V's own capsule doesn't block it. They test against the World Static and World Dynamic presets.
- **Exposure weights:** head 0.12, chest 0.25, each shoulder 0.14, pelvis 0.20, knees 0.15.
- **Aim point:** the visible centre of mass, else the head, then the side shoulder, then the knees. With nothing visible, the shot goes to the game's point and hits the cover as suppression.
- **Hit check:** only visible parts count.
- **Pauses:** trained shooters don't pause once less than half of V is visible.
- **Run result:** shooters saw all of V on 84% of shots, part of her on about 14%, and nothing on 2%.

**Shots that skipped the model (fixed).** `AIWeapon.Fire` runs the aim step (`HandleBeingShot`) only when:
- the shoot action has no `aimingDelay`. Otherwise it aims at V's position from a moment ago, with zero error.
- the shooter's senses see V (`IsAgentVisible`). Otherwise it fires at the believed position, also with zero error.

These shots landed at the default aim point just below V's head slot. Measured, they made up 70% of the hits on V.

**The fix:**
- **Aiming delay:** removed for enrolled shooters, because the model has its own reaction lag.
- **Blind shots:** get a scatter of √((shooter σ × distance)² + (0.6 m + 3% of distance)²).
- **Smart rounds:** keep the game's guidance.
- **Result:** shots that bypass the model fell from 70% of hits to about 12%. Fatal head hits fell from 617 to 5, all from shots aimed at the head.

**Hit part on V.**
- **Why not from the engine:** V's collision is a single capsule, and her hit shapes carry no body-part data. A height test against her head slot misclassified shoulder hits as head hits.
- **The rule:** the part comes from the shot's own aim sample. A sampled hit outside the outline is a graze, using the 0.6 limb rule and never fatal. A hit from a shot the model didn't sample counts as torso. Height is logged for diagnostics only.

### Armour as its own object (decided 2026-10-05)

Health and weapon damage stay vanilla; armour decides whether a round reaches the body.

| Rule | Value |
|---|---|
| Armour piece | Rating P (0–7), integrity (1 = intact), covered body parts |
| Effective P | P × (0.5 + 0.5 × integrity) |
| Round gets through | Full damage; piece −1% integrity (halved 2026-10-06) |
| Round stopped | Blunt trauma 20% (head 30%); piece −2.5% × calibre² ÷ P |
| Integrity 0 | Piece broken, protects nothing |
| Head hit that gets through (or no head armour) | Fatal, for V and NPCs alike |
| Limb or graze on V | ×0.6 |
| Self-repair | Subdermal plating only. V: only while the game's combat state is off, full in 90 s, checked every 2 s. NPCs: from 60 s after their last hit, full in 90 s. Worn gear never repairs. An in-fight repair tool is planned |

**Who wears what:**

| Who | Pieces |
|---|---|
| V | Subdermal armour from her Armor stat (P 4.2 now), covering the whole body including the head |
| Scavs, civilians | Jacket P 0.5 (torso, arms) |
| Gangs | Armoured jacket P 1 (torso, arms) |
| Maelstrom | Subdermal plating P 2 (everything) |
| 6th Street, Barghest, NCPD | Vest P 3 (torso) |
| Corporations | Vest and plating P 4 (torso), limb plating P 2 |
| Heavy archetype | Plate P 6, limb plates P 4, helmet P 5 |
| MaxTac | Plate P 6, borg plating P 5 (everything), helmet P 6 |
| Mechs, drones | Hull P 7 |

- **Rarity:** weaker enemy classes −1 P, elite and officer +1 P.
- **Helmets:** an armoured head hit shape on an NPC without head armour becomes a helmet of P ≥ 3.

**Armour bars (`SDPArmorBar.reds`).** These show integrity, steel blue, turning amber below 40%:
- **V:** a thin bar under the HUD health bar, added to the HUD's bar layout. It refreshes when V is hit and every 2 s while repairing.
- **Enemies:** a thin bar under the nameplate health bar, showing the piece covering the torso. It's only shown for enemies the model handles that wear something.

### Run results (2026-10-05/06)

| Shooter (all of V's movement mixed) | Aim point on V's body |
|---|---|
| Poorly disciplined | 37% |
| Trained (police, corps) | 60% |
| Mechanical | 68% |

- **Estimate:** the Monte Carlo estimate now matches the measured rates within about 2 points.
- **Climb at the moment of firing, after the recoil-control change:** poorly disciplined median 9 mrad (90th percentile 32); trained median 5.7 mrad (90th percentile 16).
- **Enrolment:** every hostile human is now handled by default; `SetAllHostiles(false)` limits it to the test factions.

### Test tooling

| Command | Purpose |
|---|---|
| `SetTestGodMode(true)` | Zeroes damage to V at `DealDamages`, after logging. The game refuses Invulnerable, and Immortal still lets V be downed |
| `print(SDPC:LastReport())` then `error('flush')` | Writes the report to `scripting.log`; `gamelog.log` only flushes on exit |
| `print(SDPC:ProbeWeapon())` | Every spread, recoil, sway, damage, tier and level stat on V's held gun |
| `RepairVArmor()` | Restores V's plating |
| `SetWeaponDamage` | Present but off |

Report contents:
- predicted against struck part, with hit heights
- the game's aim point against V's real position
- hits from shots the model didn't sample, and blind shots
- delays removed, armour stopped and broken, fatal head hits
- the damage check per gun

### Fix in the main mod (2026-10-06)

`SDP_EncounterLevelName` in `EncounterXP.reds` was a global function, but the overlay calls it as `data:SDP_EncounterLevelName(i)`. The encounter log had failed at the end of every encounter since the 1 October commit. It is now an `@addMethod(PlayerDevelopmentData)`.

## 13. Open questions

1. **Threat-tracking data:** which presets use `RealPosition`, and whether combat accuracy degrades gracefully with last-known-position tracking (Phase 0, then 3).
2. **Group coefficient:** the native `GetBasicGroupCoefficient` is opaque. Replacing `ShouldBeHit` bypasses it entirely, so only telemetry is needed.
3. **Tag carrier:** confirm that a cloned status effect with an infinite duration can be applied and removed per actor from redscript without side effects (UI icons, the save system).
4. **Performance:** the slot sampler uses navmesh raycasts. Run it on events (attack request, position change > 1 m), not per frame, and measure.
5. **Reworking the backend plan:** backend §4's fixed "two melee reservations, one hostile upload" becomes the §5 physical and doctrine limits. Its other rules stand.

Sources: vanilla script decompile of `prototype.redscripts` (redscript-cli v1.0.0-preview.22); staged Combat Revolution 1.4.3, ENC PL-Beta-1.8.8, Combat Evolved 4.16.8, Harder Gunfights 0.1, Time Dilation Overhaul 2.35, Trace Position Overhaul 2.1.3; [CR](https://www.nexusmods.com/cyberpunk2077/mods/20225), [ENC](https://www.nexusmods.com/cyberpunk2077/mods/8467), [CE](https://www.nexusmods.com/cyberpunk2077/mods/29125), [Harder Gunfights](https://www.nexusmods.com/cyberpunk2077/mods/14544), [redscript](https://github.com/jac3km4/redscript).
