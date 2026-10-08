# Validation and implementation backlog

Status: 2026-10-08. The source research is complete at the scope described in the
[index](README.md). Tests below are specified, **not run**, unless explicitly noted.
No gameplay changes are part of this documentation pass.

## 1. Immediate findings to resolve before balancing

| Priority | Finding and evidence | Concrete next action |
| --- | --- | --- |
| P1 | Armor mutation is reachable from projected damage; no projection guard in the current wrapper | Separate preview estimate from real-hit commit; test armor integrity while scanning without firing |
| P1 | NPC limb crippling evaluates damage before armor | Feed injury decisions resolved post-protection damage; test identical limb shots with/without protection |
| P1 | Incoming hacks share native gates/pool/HUD and player hacker identity | Prove native serialization first; implement independent sessions before increasing simultaneous uploads |
| P1 | Current custom hack executor requires player instigator and NPC target | Extract shared semantics and test an NPC adapter independently |
| P2 | Aim-sample/player-hit attribution uses a recent shooter timestamp | Test bursts, multi-projectiles and delayed impacts; use stronger shot correlation if needed |
| P2 | Live player position/velocity still influences some tactical choices | Trace hidden-movement decisions; substitute observation data where those reads inform tactics |
| P2 | Suppression uses a player-camera firing corridor | Measure occluded/nearby fire; define the desired projectile or impact-based approximation |
| P2 | Current armor selects one best covering piece | Decide whether to retain that abstraction or specify actual layering before balancing multiple armor slots |
| P2 | Old comments/notes describe mechanics that have changed | Treat executable paths and this qualified research as evidence; update implementation docs alongside future fixes |

These priorities are implementation planning judgments. The projection and injury
ordering findings are verified code-path concerns; their practical incidence and
severity have not been measured in this pass.

## 2. Baseline capture

Use the proposed [Combat Arena testbed](COMBAT_ARENA_TESTBED.md) for controlled
combat cases after its isolated controller is qualified. The normal arena loop
alters health, death handling, spawn selection and AI stimuli; its Gauntlet settings
alone do not provide a neutral benchmark. Keep existing security sites for network,
camera and mission integration. The controller is planned, not implemented.

Record game executable version, compiled-script provenance, enabled mods and their
versions, load order/configuration, actor and weapon records, difficulty, progression,
cyberware, equipped programs and save/scenario identity. Keep vanilla-compatible and
modified captures distinct. A staged mod directory is not proof of deployment.

Refresh the resolved records/curves for player Level/PowerLevel, NPC health/damage,
armor effectiveness, difficulty, item tier, hacking costs, tickets, action conditions,
resource refills and cyberware activation. Record overrides rather than assuming
values from an old inline record still describe the effective game.

## 3. Focused experiments

| ID | Setup | Observe | Pass criterion / question answered |
| --- | --- | --- | --- |
| D01 | Aim/scan at an armored target repeatedly; fire no shots | Integrity, random-roll/telemetry counts, preview damage | Preview never mutates armor, injury or supply state |
| D02 | Fixed gun, range and limb hit; vary armor | Damage before/after protection and injury decision | Injury uses damage actually passing protection |
| D03 | Burst, shotgun and slow projectile against V | Shot identity, stored aim sample, impact time and assigned part | No unrelated recent shot supplies the hit location |
| D04 | Bullet, melee, grenade, DoT and vehicle hits | Selected damage owner and fallback | Explicit intended coverage; no double armor or skipped quest protection |
| H01 | Injure, stabilize, heal, treat, save/load | HP, injury flags, modifiers and supplies | HP recovery does not silently cure injury; state and costs persist correctly |
| H02 | Use item, biomonitor and medical cyberware under recharge-trigger perks | Every charge/supply writer | No alternate path manufactures supplies under finite-resource rules |
| S01 | Specialist and broad builds with matched combat equipment | Level, PowerLevel, actual stats, ICE/RAM and opposition | Unrelated skill gain has understood, calibrated scaling effects |
| P01 | New save and existing purchased/recorded/unfinished shard states | Packages, rank queries, rewards and slot entitlement | Exactly one intended effect; migration preserves legitimate progress |
| A01 | Enemy sees V, loses sight, then V changes position/velocity behind cover | Threat source/age, aim point and action choice | No unexplained tactical update from hidden movement |
| A02 | Two squad members; only one sees V; break their proposed comms link | Threat propagation and timing | Sharing follows the chosen communication model |
| A03 | One/two/four shooters with fixed weapons/range | Requests, pattern waits, TBH state, misses, impacts | Distinguishes action cadence from hit gating and actual damage |
| A04 | Two squads versus one; melee/pursuit/peek pressure | Ticket owner, condition, cooldown, grant/release | Establishes effective admission scope; no leaked reservations |
| A05 | Grenadier with declared stock; interrupt one throw; place ally in blast area | Provisioning, reservation, launch, remaining stock, ally damage | Successful throws consume once; cancellations release; safety and damage agree |
| A06 | Ranged NPC fires/reloads repeatedly | Magazine and reserve counters, refill writers | Establish whether and where native reserve ammunition replenishes |
| A07 | Near fire, distant fire, solid occluder, suppression from each side | Stimulus, trajectory/impact proxy, pressure and pin response | Suppression matches the specified approximation and exemptions |
| A08 | Pin one enemy while another can flank; remove safe route | Cover reservation, role decision, movement success | Coordinated intent or sensible fallback, not repeated failed commands |
| C01 | Eligible/unequipped/disabled cyberware actors | Ability, condition, activation, budget and recovery | Hardware assignment results in appropriate observable use |
| N01 | One then two then four hostile runners | BeingHacked, retry events, pool writes, HUD, result attribution | Establish native serialization; later sessions cannot overwrite each other |
| N02 | Interrupt runner, proxy or route during upload and after delivery | Session state, cost, effect, cleanup and trace | Matches explicit route-loss/payload-persistence rules |
| N03 | Camera-only permission, personnel permission, revoked permission | Menu eligibility and execution via every adapter | UI and authoritative checks agree; no stale-menu/custom-hack bypass |
| N04 | Repeat Overheat and mixed control hacks from different sources | Stack count, refresh, duration, damage and reactions | Intended composition without accidental multiplication or permanent lock |
| N05 | Target/network without an access point; quest/tutorial interaction | Entry options and exception reason | Clear supported route or scoped authored exception; no universal unlock |
| R01 | Manually tag enemy, lose sight; reacquire via camera | Marker position/source/age; outlines and scanner | Stale contact stops tracking; live camera updates only when observed |
| R02 | Camera sees a neutral/hostile actor; feed lost or destroyed | Sensor-list filters, FOV/occlusion and contacts | Recon follows visible coverage, not only native hostility filters |
| R03 | Remote control interrupted by hit, quest or device loss | Input, camera, HUD and controlled-object cleanup | Player control reliably returns; no lingering markers/listeners |
| W01 | Craft, upgrade, stash, drop/pickup, save/load, salvage custom gun | Identity, parts, stats, ingredients and proceeds | Stable signature weapon; no duplicated items/materials |

Use fixed reference loadouts and repeat stochastic tests enough to report a
distribution. Do not choose arbitrary universal TTK or reaction-time targets before
observing the baseline. Include low-chrome, specialist and heavily augmented builds.

## 4. Representative encounter

Choose a small existing non-critical combat site after checking its native security
relationships and navigation. Use existing geometry and actors before adding spawns.

Test composition: two ordinary shooters, one protected specialist, one grenadier and
one runner, plus a camera and at least one usable network entry. Exact numbers are a
prototype configuration, not a final balance commitment.

The player must be able to discover threats, gain limited access, interrupt a route,
use armor/cover, and treat a consequential injury. Enemies must demonstrate at least
one coordinated move and one sensible fallback. Include a run where camera/comms
access is denied, and a run where a grenadier exhausts stock.

Completion means the combined behaviors and counterplay are observable and stable,
not merely that the player died quickly or a script compiled.

## 5. Delivery sequence

1. Capture effective configuration, qualify the arena test controller, and resolve
   D01/D02 before damage balancing; retain a real-site baseline for integration.
2. Audit progression consumers and a small ability sample; decide migration contracts.
3. Establish contact/access interfaces and native hack serialization telemetry.
4. Implement one route and one defensive runner with existing serialized uploads.
5. Add finite grenade policy and an information-aware squad decision.
6. Add injury/treatment persistence and basic HUD explanations to the same encounter.
7. Prove independent NPC hack sessions and the shared program adapter.
8. Expand cyberware, weapons, shards and encounter coverage using measured results.

## 6. Remaining research boundaries

- Extract and trace selected behavior assets for the chosen archetypes.
- Capture full resolved TweakDB graphs/curves, including inverted prerequisites,
  action overrides, equipment provisioning and native evaluator inputs.
- Inspect Better Netrunning's actual package before choosing reuse versus an adapter.
- Verify native target hit-shape data for V and robust projectile-to-sample correlation.
- Audit medicine/regen writers and persistent save behavior.
- Prototype mobile drone movement/control separately from camera feeds.
- Re-check external integration dependencies and permissions if code is adopted or
  a distributable release is planned; the current research does not copy new donor code.

The absence of these runtime/asset checks is explicitly tracked. It does not change
the source-backed conclusions above or justify treating unknown native behavior as fact.
