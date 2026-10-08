# Combat Arena as an SDP testing environment

Assessment date: 2026-10-08. **Recommended as a candidate location and spawning
foundation for an SDP test mode. The normal survival loop is not a controlled
benchmark.** This is a source audit and implementation plan; no arena session,
compiler test or gameplay modification was performed.

The [Combat Arena author page](https://www.nexusmods.com/cyberpunk2077/mods/27580?tab=description)
describes wave combat, configurable Gauntlet runs, equipment purchases and support
crew. Those features make quick combat trials convenient. Its published permissions
allow modifications with credit; an SDP extension should credit whisperOfIndigo
and depend on the original mod rather than redistribute its package.

## What was actually inspected

The local package contains seven redscript files, one TweakXL file, one input file
and an archive. **All ten files match their counterparts in the Steam game directory
byte for byte.** This establishes deployed file identity, not successful compilation,
dependency compatibility or live activation.

The package folder says version `1`, the webpage header says `0.9`, its changelog
contains version `1`, and the local `ArenaSystem.BUILD()` returns `47` ([S1]). Use
the [SHA-256 manifest](combat-arena-evidence.json) to identify this audited package
instead of treating those version labels as interchangeable. The archive was
fingerprinted, not unpacked; navigation, cover and security assets remain unverified.

## Useful foundations and confounding behavior

All findings below are **SOURCE**, except the explicitly identified author comment
and runtime questions. The linked methods are implementation details, not a promised
stable public extension API.

| Area | Inspected behavior | Consequence for our tests |
| --- | --- | --- |
| Spawning | `CreateAt` accepts a character record, position, tags and jitter. Dynamic entities are marked nonpersistent. Ordinary enemy helpers add ±1.5 m XY jitter; yaw is random even when jitter is zero. It returns true after requesting creation, without waiting for attachment ([S2]). | Reuse the approach, but control orientation and position; wait for the actual entity and validate its record, equipment and resolved stats before starting a measurement. |
| Cleanup | `DespawnAll` deletes entities carrying the shared `CombatArena` tag ([S3]). | Test-owned tags and entity IDs avoid deleting survival participants or triggering its listeners. |
| Encounter selection | Gauntlet controls wave counts, duration and boss distribution. The director randomly selects grunt/heavy records and shuffled positions; the final wave always adds Smasher ([S4]). | Gauntlet alone cannot specify a fixed actor roster and repeatable placement. Add named scenario presets. |
| Enemy health | `ScaledEnemyHealth = min(2, 0.65 + earned/4000) * enemyHealthMult * difficultyMultiplier`; Gauntlet sets only the last multiplier to 1. Normal difficulty uses 1.20. The attach callback writes a multiplied **current health pool**, not an explicit maximum-health stat modifier ([S5], [S6]). | Selecting Gauntlet and HP multiplier 1 does not remove scaling: initial requested factor is 0.65. Bypass this writer. Measure actual current/max HP because native clamping may affect the result. Do not describe 2.10 as proven 2.10× effective maximum HP. |
| Player survival | `StartRun` heals V and enables engine immortality regardless of the initial God Mode setting. The fight tick treats low HP as defeat; a player death wrapper also intercepts death during state 2 ([S7], [S8]). | Ordinary arena defeats are not measurements of native lethal-hit/death behavior. Test mode needs an explicit lethal or nonlethal policy, with no automatic heal during a measured window. |
| AI knowledge | Every three seconds the fight loop sends synthetic gunshot/combat-call stimuli from V's current position. It also periodically assigns patrol moves ([S9], [S10]). | Disable these for perception, stealth, lost-target and squad-information tests. Otherwise the harness itself supplies location information. |
| Background movement | An attach callback schedules a recurring patrol task. Outside combat, it sometimes chooses V's current position; in combat it defers and retries ([S6], [S11]). | Stopping the main wave timer is insufficient. Prevent these callbacks from attaching to test actors; check that no old callbacks survive a reset. |
| Faction relationships | Attach and upkeep routines impose a hostile attitude group and hostility toward V ([S6], [S10]). | Verify squad/security membership independently. Hostility is not proof of a shared squad, shared tickets, security network or friendly-fire policy. |
| Netrunners | The inspected ordinary heavy pool contains no designated runner; an author comment says the previous runner and quest drone spawned without fighting and were replaced ([S12]). | Runner compatibility is an early qualification task. The comment is historical testimony, not proof that every runner record fails. |
| Equipment and economy | Entry removes V's weapons into ID/quantity arrays, takes a buy-in and teleports to a random point; exit strips arena guns, gives weapons back and heals ([S13], [S14]). | Avoid this entry/exit path for custom-weapon preservation and fixed-loadout benchmarks. It is not a snapshot of SDP armor integrity, injuries, progression, hack state or all item properties. |

## Proposed design: SDP-TestLab

Keep this a development tool with two complementary environments:

1. **Arena laboratory:** fixed actors and conditions for armor, damage, weapons,
   cyberware, supplies, hack effects and isolated AI cases.
2. **Existing encounter site:** validated native cameras, access points, security
   relationships, squad placement and navigation for networking, recon and mission
   integration. A spawned camera or runner is not automatically wired into these.

Use a separate controller and test-owned entities in the arena location, leaving
the survival director idle. Reuse selected location/UI/teleport infrastructure where
safe. Do not enter through `CompleteEntry` or start through `StartRun`, because that
would activate inventory, money, health and AI changes. Do not reuse the
`CombatArena`/`CombatArenaAlly` tags: they register mutation callbacks. A small
original spawner using the same Codeware mechanism is likely cleaner than wrapping
every private survival-loop function. This is an architectural proposal, not an
implemented or compiled adapter.

The controller should own the following lifecycle:

`prepare -> request spawns -> verify readiness -> arm -> run -> collect -> reset`

- **Scenario specification:** scenario ID/revision, environment, actor records,
  positions/facing, equipment, cyberware, squad and attitude relationships, initial
  awareness, supplies, player build and stop conditions. Unknown records/positions
  must fail setup visibly rather than silently substitute random choices.
- **Readiness checks:** attached entities, correct resolved gear/stats, valid floor
  placement, usable routes/cover where needed, and runner action eligibility. Allow
  a bounded readiness timeout and record why an actor failed.
- **Controlled start:** close test UI, verify normal time scale, then start the
  measured window. No shops, automatic wave escalation, forced search stimuli,
  surprise reinforcements or optional crew unless the scenario explicitly needs them.
- **Level scaling stays:** fix V's level and record resolved NPC level/PowerLevel
  for each comparison. Later repeat the same scenario at low, middle and high levels.
  Removing the arena's earnings multiplier does not remove the game's level scaling.
- **Reset contract:** restore or reload a declared baseline for HP, RAM, armor
  integrity, injuries, ammo, consumables, cooldowns, effects, AI knowledge and hack
  sessions. Despawning actors alone is not a reset. Begin with a dedicated test save
  and reload between runs until restoration has been demonstrated for each subsystem.
- **Isolation:** mutually exclude an active survival run; generation IDs invalidate
  old delayed callbacks. Abort/cleanup restores input, time scale and test-owned
  immortality/other modifiers, and removes only test entities and listeners.
- **Repeatability:** fix roster, start conditions and harness randomness. This does
  not make native AI, physics or timing deterministic. Repeat stochastic trials and
  report distributions, failed setups and exclusions.

## First scenario set

These presets map to the existing [validation backlog](VALIDATION_BACKLOG.md).
Distances and compositions are proposed test inputs, not final balance targets.
Exact spawn coordinates and actor records are selected only after in-game qualification.

| Preset | Controlled setup | Measurement / purpose | Backlog |
| --- | --- | --- | --- |
| Armor preview | One armored target; repeated scan/aim with no shots | Armor integrity and mutation counters must remain unchanged | D01 |
| Armor and injuries | Same gun, target and aimed limb; unarmored/protected variants at a measured 10 m | Pre/post-protection damage, integrity and injury decision | D02, D04 |
| Shooter pressure | One, two, then four shooters with matched weapons and fixed starts | Shot cadence, accuracy, hit attribution and incoming damage | D03, A03 |
| Lost target | Enemy observes V; V moves behind opaque cover and changes direction | Last observation, aim/search point, reacquisition and unauthorized position updates | A01 |
| Squad and grenades | Verified squad with one grenadier, declared stock and an ally near the target area | Ticket grants, throw cancellation/consumption, blast safety and friendly damage | A04, A05 |
| Chrome activation | Qualified actor with eligible, unequipped and disabled cyberware variants | Hardware availability versus actual use, interruption and recovery | C01 |
| Runner baseline | First qualify one runner; then use one/two/four with the same program | Upload gates, retries, source attribution, interrupts, effects and HUD conflicts | N01, N04 |
| Sustained encounter | Fixed mixed squad, fixed V build and finite supplies | Fight outcome, resource use, coordinated behavior and actionable counterplay | A06–A08, H02 |
| Network and recon site | Existing validated security site with a camera, runner and access point | Permission boundaries, route loss, camera observations and stale contacts | N02, N03, N05, R01–R03 |

Keep save/load injury tests (H01), progression migration (P01) and custom weapon
identity/crafting tests (W01) outside the arena entry/exit mechanism. Add low-chrome
and heavily augmented build comparisons after baseline scenarios work.

## Instrumentation and results

Extend the project's existing combat/quickhack diagnostics with a shared run ID.
Start with structured log events and an offline result parser; a report UI can follow.
Do not treat native HUD bars or the arena's alive-count scoring as a damage meter.

Each run needs a manifest: executable version, mod/source hashes, active overrides,
scenario revision, save/build identity, player difficulty/level/equipment, resolved
NPC stats, starting resources, random choices and validity status. Each event should
record time, source/target entity IDs, event/correlation ID and relevant before/after
values. Separate projected damage from committed hits.

Measure TTK only after defining the start event (first committed hit or combat
start), and distinguish death from incapacitation or a test-controller stop. Log
upload start/complete/cancel, grenade provision/reserve/launch, cyberware activation,
and observable AI action/ticket/perception events where hooks allow them. Mark
unavailable native internals as unknown rather than inventing a cause.

Compare the same validated scenario and equipment before/after one change. Keep
the game difficulty fixed. Include multiple trials for stochastic behavior and
report medians/ranges rather than relying on one impressive fight.

## Build order and acceptance gates

1. **Qualify the location and installed mod:** confirm dependency/compiler state,
   floor/navigation/cover, original entry/exit behavior on a test save, and one known
   shooter. Record logs and effective game/mod versions.
2. **Minimal isolated controller:** one fixed actor, fixed start, restart, cleanup
   and log identity. Verify no arena HP writer, forced-location stimulus or inventory
   transaction ran. Validate repeated setup and abort/save-load cleanup.
3. **Armor and shooter presets:** D01/D02 first; then cadence and incoming-hit
   attribution. Resolve the already identified armor preview/injury-order issues
   before using these results to tune balance.
4. **AI and runner qualification:** occlusion, squads, finite grenades and chrome;
   validate one runner before increasing concurrency. Inspect failed actions and
   record prerequisites rather than assuming spawn success means functional AI.
5. **Network integration site and wider regressions:** permissions, camera feeds,
   custom program execution, progression and persistence. Arena success alone does
   not establish mission compatibility.

This adds a testing foundation early in the overhaul plan. The existing survival
mode remains useful for exploratory play, while controlled measurements use the
isolated controller. Implementation and runtime verification remain future work.

## Local source anchors

Line links refer to the deployed files fingerprinted in the companion manifest.

[S1]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:171>
[S2]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/arena_spawner.reds:248>
[S3]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/arena_spawner.reds:321>
[S4]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:652>
[S5]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:579>
[S6]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/arena_spawner.reds:1098>
[S7]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:550>
[S8]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/arena_spawner.reds:949>
[S9]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:1460>
[S10]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/arena_spawner.reds:527>
[S11]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/arena_spawner.reds:1174>
[S12]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Data.reds:188>
[S13]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:355>
[S14]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/r6/scripts/CombatArena/Arena.reds:1154>
