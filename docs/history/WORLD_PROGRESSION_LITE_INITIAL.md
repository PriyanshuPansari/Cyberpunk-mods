> Historical counterproposal, preserved before the source-audited revision. Its deployment and integration claims are superseded by [the current lite plan](../../design/WORLD_PROGRESSION_LITE.md).

# World progression, lite: combine installed mods, connect to our progression

Status: proposal, 2026-10-01. A scoped alternative to
[WORLD_PROGRESSION_PLAN.md](../../design/WORLD_PROGRESSION_PLAN.md), built from the mods in
[WORLD_PROGRESSION_MOD_RESEARCH.md](../../design/WORLD_PROGRESSION_MOD_RESEARCH.md) that are
**already installed and deployed**. Nothing here is implemented yet.

## Review of the full plan

The full plan is sound in its warnings (don't extend Level past 60, don't double
scale, bound reinforcements, don't let more enemies inflate XP), but as a build
plan it is too ambitious for a solo mod:

| Full-plan piece | Why it is heavy |
|---|---|
| 8 authored threat bands, encounter budgets, role costs | Needs per-location/per-mission authoring and playtest-measured costs |
| Custom equipment grades above native quality | New item records and UI for every weapon class; touches shared player/NPC records |
| Capability ledger of every perk/shard/effect | A second balance model to maintain beside ours |
| Contested scanner/Sandy time dilation per NPC | Individual time dilation is fragile (not reason-keyed, save/load, cinematics); months of edge cases |
| AI roles (suppressor/flanker/rusher/...) and squad coordination | AI behaviour trees are the hardest area to mod; the mods that do it are large projects in themselves |
| Own reinforcement dispatcher / reward budgets per encounter | Duplicates Reinforcements System |

Most of these already exist in mods deployed in this game. The lite version
**uses them as they are** and adds only the glue that makes them follow *our*
progression instead of the vanilla level.

## What each mod contributes (all currently deployed)

| Need | Mod (owner) | What we use | What we don't touch |
|---|---|---|---|
| Tougher, more varied enemies | **Enemies of Night City** | Faction cyberware and abilities, enemy Sandevistan tiers (Sandy0-3 dilation), faction hack resistance, elite/boss upgrades, per-tier HP/damage settings | Its internals; only its Native Settings values |
| Enemies resisting slow-time | ENC `TimeDilation` module | Sandy-vs-Sandy override multipliers = a working "contested time" for enemy Sandevistans | No per-NPC dilation of our own |
| Backup and escalation | **Reinforcements System** | Faction heat, turf, interruptible calls, strong reinforcements, bounties; grace time already shrinks with Street Cred and bounty | Its dispatcher (we can't wrap its classes; settings only) |
| Enemy gunfire pressure | **Harder Gunfights** *or* **No Shooting Delay** (both deployed, both edit NPC firing cadence) | Pick one owner | - |
| Persistent notoriety | **They Will Remember** | Faction memory/hostility after you attack them | - |
| Scanner slow-time | **our `ScannerDilation.reds`** | Netrunner-skill-based scanner dilation | Remove *INT based scanner dillation* (deployed, sets the same values) |
| Level cap | **More Levels** (deployed, max level 79) | Nothing: our level is derived from skills, and native curves stop at 60 | Set its max level to 60 or disable |

## How it connects to our system

```
 SkillDrivenProgression                       World (existing mods)
 ----------------------                       ---------------------
 5 skills --+                                  ENC: cyberware, Sandy tiers, elites
            +--> World Tier (1-8) --------+    (Native Settings preset per tier)
 recorded --+    SDP_WorldTier()          |
 shard grades                             +--> PowerLevel / Level  --> vanilla enemy
                                          |    (specialist-friendly     scaling, loot
                                          |     formula, capped 60)     quality, Health
                                          |
                                          +--> Street Cred floor  ---> Reinforcements:
                                          |    (optional)               grace time, heat
                                          |
 shard channels <--- encounter reward guard (per-encounter damage-XP cap, reinforcement
 (ShardChannels)      waves and farmed backups can't inflate training)
```

### 1. One progression number: World Tier

`SDP_WorldTier()` (1-8) from what the character can actually do, not the skill
average: `top-three weighted skill level` (the "weighted top three" column of
[SPECIALIST_BALANCE.md](../../design/SPECIALIST_BALANCE.md): 60,1,1,1,1 -> 42; 60,60,60,1,1 -> 60)
plus `+1 tier per 20 recorded shard grades`, capped at 8. Shown in the overlay
and logged per encounter.

### 2. Vanilla enemy scaling follows it

Vanilla 2.x enemies already scale to the player's PowerLevel. Switch
`SkillDrivenPowerLevel.yaml` and `SkillTotalLevel.reds` from the five-skill
average to the same weighted-top-three value (cap 60). A pure specialist then
meets enemies of their real strength instead of level 12, and the level-based
skill/shard XP multiplier stops punishing specialists. This is the single
biggest "better scaling" change and is fully ours.

### 3. ENC presets per World Tier

ENC exposes HP/damage multipliers for enemy tiers T1-T3, elites, bosses and
Sandy dilation in its settings. Ship a small table (Tier 1-8 -> values) and apply
it at game load from our CET mod through ENC's own settings keys (or document
it for manual use if ENC doesn't read them at runtime). Higher tiers make elites
and bosses tougher and enemy Sandevistans more resistant; ordinary thugs are
left alone, matching the full plan's "ordinary thugs eventually easy" goal.

### 4. Reinforcements follow notoriety

Reinforcements System already scales grace time and initial heat with Street
Cred and bounty. We only tune its settings (max two waves' worth of heat,
cooldowns) and, optionally, give Street Cred a floor from World Tier so a
feared specialist draws backup sooner. No code changes to the mod.

### 5. Reward guard (ours)

Shard damage XP already caps each enemy at 100% of its Health per shard. Add a
per-encounter cap on damage-channel XP (about 3 focused fights' worth) so
reinforcement waves and farmed backup can't speed-run shard training, and log
enemies killed by rarity plus World Tier per encounter for calibration.

## Phases

| Phase | Work | Size |
|---|---|---|
| 0. Conflicts | Choose Harder Gunfights *or* No Shooting Delay; remove INT scanner dilation; set More Levels max to 60 (or disable); check Skillful Attributes / ReflexIsCool against our skill-to-attribute system | Settings / Vortex toggles |
| 1. World Tier + scaling | `SDP_WorldTier()`, specialist PowerLevel/Level formula, overlay + log fields | Small: one reds file, one yaml |
| 2. World presets | ENC tier table applied on load; Reinforcements settings table | Small: CET + a doc table |
| 3. Reward guard + logging | Per-encounter damage-XP cap; kills by rarity; tier in `encounters.csv` | Small |
| Later (optional) | Pieces of the full plan that prove necessary after playing: e.g. contested scanner time, custom endgame gear | Only on evidence |

Acceptance: a pure specialist meets enemies at their real strength; elites and
bosses stay dangerous at high tiers while street thugs don't; backup arrives
but is bounded; shard XP per encounter stays within the model's pacing; no two
installed mods own the same values.

## Decisions needed

1. Shooting owner: Harder Gunfights or No Shooting Delay?
2. More Levels: cap at 60 or disable?
3. World Tier formula: weighted top three (proposed), top two, or highest skill?
