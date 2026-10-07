# Immediate baseline: Enemies of Night City (configured)

Status: 2026-10-01. The world-progression backend in
[WORLD_PROGRESSION_BACKEND.md](WORLD_PROGRESSION_BACKEND.md) is the long-term
plan; until it exists, enemy difficulty comes from ENC with its own settings.
SDP only measures and adapts around it.

## Current state (checked in the game folder)

ENC is **installed in Vortex but not deployed**: the game folder only has empty
`Enemies of NC` / `r6/scripts/ENC` folders, and CET logs
`Ignoring mod which does not contain init.lua! (... Enemies of NC)` on every
launch. The same is true of Reinforcements System, More Levels, INT based
scanner dilation, They Will Remember, Skillful Attributes and ReflexIsCool;
Harder Gunfights and No Shooting Delay also have no `init.lua` deployed.
So none of the overlaps listed in WORLD_PROGRESSION_LITE.md are active today.

## Setting up the baseline

1. **Version:** the staged copy is `PL-Beta-1.8.8 Hotfix` (file date July 2024).
   The author page lists a later PL-Beta-1.8.8 update (2025-03-31). Download the
   latest file for the installed game patch before enabling.
2. **Enable in Vortex** and deploy. Expect in `scripting.log`:
   `Enemies of Night City loaded`, and no "Ignoring mod" line for it.
3. **Keep off for the baseline** (as the combat comparison recommends): other
   enemy/AI overhauls, Reinforcements System, Harder Gunfights / No Shooting
   Delay, INT based scanner dilation, More Levels.
4. **Settings:** start from ENC defaults (enemy tier/elite/boss HP and damage
   x1, Sandy0-3 dilation 1.5/2/2.5/3, faction hack resistance). Record any
   change you make in the table below so logs can be compared.

| ENC setting | Value used | Why |
|---|---|---|
| (defaults) | | baseline |

## How ENC meets SDP

| ENC change | Effect on SDP | Handling |
|---|---|---|
| Promotes many NPCs to Elite or Boss rarity | Rarity multiplies native skill XP and shard damage XP (Elite x2, Boss x10) | Encounter log now records kills by rarity; if a promoted "boss" pays like a story boss, cap shard rarity at x2-x3 for non-story NPCs |
| Higher enemy HP (bosses, cyberpsychos) | Shard damage XP is % of Health, so HP multipliers do not inflate XP | none |
| Enemy Sandevistans resist slow-time (Sandy-vs-Sandy override) | Separate from SDP's scanner dilation (`ScannerDilation.reds`) | no conflict; scanner contest stays a backend goal |
| Faction hack resistance, Breach Protocol changes | Slower uploads -> Overclock/Hack Queue channel XP per fight changes | watch Upload/Queue XP per encounter |
| Enemy cyberware, abilities, combat stims | Longer/harder fights -> more time-channel XP (Adrenaline, Chrome) | window caps already bound these |

## What to log in baseline fights

The encounter log already records per fight: combat time, native skill XP and
events, shard XP by channel, channel triggers and (new) **kills by rarity**.
Play a handful of fights with and without ENC on the same save and compare:
kills by rarity, XP per minute per skill and per shard channel, and deaths.
Those numbers set the shard pacing correction (if any) and become the benchmark
the SDPCombat backend has to beat.

## Status (2026-10-01)

Installed: ENC, Night City Alive, Reinforcements System, Cyberware-EX (Expansion
shards). Plan: play a normal run and review the encounter log periodically
instead of A/B testing in blocks. Check kills by rarity first (Boss-rarity
payouts from ENC promotions).
