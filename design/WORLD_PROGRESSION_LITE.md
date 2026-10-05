# World progression lite: existing systems, a small progression adapter

Status: source-audited reference, 2026-10-01. **Backend selection is superseded by
the [SDP Combat plan](WORLD_PROGRESSION_BACKEND.md)**: we will own the backend and
adapt selected features. The external-stack proposal below is retained for its
integration findings, not as the active recommendation.
No runtime changes or mod activation have been performed. The user reports
the candidate mods are installed but disabled; Vortex staging files do not prove
deployment or runtime state.

Keep the counterproposal's smaller scope while preserving the original goal:
combat needs room above the vanilla perk budget. The [source audit](WORLD_PROGRESSION_SOURCE_AUDIT.md)
records implementation evidence; the [research register](WORLD_PROGRESSION_MOD_RESEARCH.md)
records author sources and reuse terms. The [initial counterproposal](../docs/history/WORLD_PROGRESSION_LITE_INITIAL.md)
is preserved, and the [larger design](WORLD_PROGRESSION_PLAN.md) becomes a backlog.

## 1. Corrections to the counterproposal

| Initial assumption | Revised decision |
| --- | --- |
| All named mods are deployed | Treat them as disabled candidates; verify a separate test profile |
| Weighted Level/PowerLevel solves world progression | Keep compatibility values separate. Extra combat headroom comes from existing enemy systems and their configurable strength |
| Eight World Tiers from weighted skills plus every 20 recorded grades | Four combat presets with a transparent recommendation; shard counts are not measured power |
| Write ENC settings from another CET mod | Target verified TweakDB output records after initialization; no public ENC preset API was found |
| Low heat guarantees two waves | Heat selects strength. Guard actual dispatches; the call-limit check has an off-by-one and bypass paths |
| Give Street Cred a progression floor | Preserve earned reputation; it affects other systems and is not a difficulty slider |
| ENC already implements the requested quality contest | It provides enemy-tier overrides; player hardware comparison and scanner activation still need a prototype |
| Harder Gunfights and No Shooting Delay are equivalent | They affect different shooting mechanisms; start with neither |
| Gunsensical only changes weapon stats | Its perks, NPC damage, economy and shooting changes need exclusions or reconciliation |

## 2. Supported starting stack

Begin with **SkillDrivenProgression + ENC**. Add a guarded Reinforcements System
next. Weapons and notoriety enter in separate passes so failures have an
identifiable cause. Framework requirements still apply: ENC's local UI module
calls Native Settings directly, making that UI required for this profile.

| Responsibility | Starting owner | Boundary |
| --- | --- | --- |
| AI, faction chrome, archetypes and baseline enemy stats | ENC, pinned local PL-Beta-1.8.8 hotfix | Combat Revolution and Combat Evolved are alternative backends, not additions |
| Enemy Sandy actions and tiers | ENC's action/record graph | Keep Time Dilation Enhanced, TDO and Enemy Rarity Fixes Improved off in this profile |
| Scanner slowdown | SDP ScannerDilation | Separate INT scanner mod off; hardware contest is the extension below |
| Backup calls, vehicles and bounty response | Reinforcements System 1.2.1 plus a small limit adapter | TWR's reinforcement module stays off |
| Weapon improvement | Audited Gunsensical Reloaded records | Full package off until perk/economy/shooting conflicts are resolved |
| Additional gunfire pressure | None initially | Harder Gunfights is the first optional trial; the staged No Shooting Delay package needs repair |
| Persistent faction memory | They Will Remember, optional later | Its reinforcements and quest reinforcements off; retaliation separately evaluated |
| Native progression, attributes and capacity | SDP | More Levels and Skillful Attributes off; audit ReflexIsCool and other competing owners |

ENC is selected because its existing behaviors and named scalar records permit
a small adapter. This does not establish that it has the best AI. Combat Evolved
is a credible separate trial with spawn-time faction/archetype chrome matching;
verify its framework dependencies and keep its optional player-HP override off.
Do not combine its chrome/stat owner with ENC.

The deeper [AI and archetype comparison](COMBAT_OVERHAUL_COMPARISON.md) identifies
CE as the first competing backend to trial for reactive squad tactics, while ENC
remains the authored-enemy baseline. Source inspection alone does not settle which
plays better with SDP.

## 3. Progression without another level compression formula

Use existing character data, avoiding a new capability simulator:

- **Depth:** highest recorded grade among the 15 multi-grade shard families.
- **Breadth:** number of those families recorded to grade 8 or higher.
- **Hardware:** equipped weapon and OS tiers, initially logged for calibration.

Exclude Vehicle's single grade. Count permanent mastery, not inventory copies or
unfinished training. Existing purchased perks can make this underestimate strength;
show that limitation and allow manual selection. Native skills remain diagnostic
context, not a weighted definition of world power.

Prototype recommendation, explicitly a heuristic:

| Preset | Milestone |
| --- | --- |
| Foundation | Before grade 4 mastery |
| Developed | Highest recorded grade >= 4 |
| Mastered | Highest recorded grade >= 8 |
| Expanded | Highest grade = 11 AND at least 3 families >= 8 |

Choose the highest satisfied row. This recommends difficulty; it never gates
equipment, vendors, quests or XP. A specialist may choose Expanded. Tune thresholds
against specialist, hybrid, all-mastered and high-skill/low-shard saves.

First release uses manual selection with the recommendation. Opt-in automatic
selection follows calibration and applies on save load, never mid-fight. Store
selection per character, not only in a global CET configuration. A bounded extra-
strength slider can extend the same presets without inventing new native levels.

### Specialist equipment remains a separate required item

Leave Level/PowerLevel unchanged for the initial combat-stack experiment. That
is a temporary baseline, not the final equipment solution. Do not reintroduce
weighted top-three mapping under another name.

Audit vendor, loot, upgrade and equip prerequisites using Level/PowerLevel. Patch
only relevant equipment-access paths to matching skill/mastery milestones or
guaranteed upgrade routes, starting with one weapon and one OS. Keep player
health, enemy PowerLevel and XP unchanged in that experiment. Respect native
quality limits and installed item data. A specialist-at-60 save must demonstrate
endgame access before claiming this problem solved. Lite needs no custom quality
enum or new tier set; unsupported consumers remain documented as incomplete.

## 4. ENC integration contract

Start with these **experimental factors relative to a captured ENC baseline**:

| Scalar group | Foundation | Developed | Mastered | Expanded |
| --- | ---: | ---: | ---: | ---: |
| T1/T2/T3 HP and damage | 1.00 | 1.00 | 1.00 | 1.00 |
| EliteHP | 1.00 | 1.15 | 1.35 | 1.60 |
| EliteDmg | 1.00 | 1.05 | 1.10 | 1.15 |
| BossHP/BossDmg, named bosses, MaxTac | Baseline | Baseline | Baseline | Baseline |

Only two dynamic combat scalars initially. ENC supplies behavior and cyberware.
Named bosses and MaxTac need separate tests because their health, regeneration,
damage caps and special attacks use additional records. Do not multiply tier,
rarity and named-boss factors independently. Ordinary enemies are unchanged by
this adapter but still follow ENC/native scaling; becoming easy is not guaranteed.

1. Check the supported source fingerprint and required records after ENC's CET
   initialization. A folder or `GetMod` result alone is insufficient. Missing or
   unsupported records leave the adapter inactive with a useful diagnostic.
2. Capture `EliteHP.value` and `EliteDmg.value` once after initialization. Apply
   absolute `baseline * factor`, never repeatedly multiply the current value.
   Restore baseline before applying another character's selection.
3. Do not edit ENC JSON or re-execute Base.lua. Its initialization appends to
   record lists without deduplication and is not an idempotent preset refresh.
4. ENC Native Settings callbacks can overwrite these fields. Declare managed
   fields owned by SDP while the adapter is active; detect drift and stop with a
   diagnostic instead of fighting another writer every frame. Manual ENC changes
   become a new baseline after restart.
5. Start with restart/load-only preset changes. Verify refresh of existing NPC
   stat groups and use fresh encounters for benchmarks. Never refill HP to force
   recalculation. Fall back to restart-only if save-load refresh is unreliable.

Validate ENC's baseline too: it changes hacking, perception, bosses and loot.
Select Breach Protocol behavior deliberately and test it against hacker shard
channels and other hacking mods. Do not assume every inherited feature has an
independent switch.

## 5. Hardware contest using existing enemy actions

ENC creates four `SandyVSandyTierNExtraDilation` records selected by enemy
abilities. Its settings write fixed overrides, not player deck comparisons.
Time Dilation Enhanced's inspected YAML activates for Sandy/Kerenzikov, not an
explicit scanner condition. TDO compares enemy speed with active player Sandy
speed, but also owns scanner charge and a broad player-OS redesign.

Prototype a **four-value table adapter**, without a per-NPC tick system:

- Resolve active player source on equipment/mode changes: deck/scanner, Sandy or
  Kerenzikov; define fallbacks for no deck and dual OS.
- For each ENC enemy tier bucket, select a bounded override from a player-hardware
  tier x enemy-tier table. Normalize the actual hardware representation against
  ENC tier meanings; their numbers are not inherently comparable.
- Write the four output flats only on relevant transitions. ENC/native actions
  retain ownership of activation, animation and restoration. Restore baseline
  values on exit/load/change of character.
- Trace the resolved `SandyVSandyOROR` activation condition first. It is referenced
  by the inspected Lua but its definition was not located in the text files.
  Scanner support may need a small condition/action patch; never respond blindly
  to every slowdown, pause or cutscene.

Pass gate: inferior/equal/superior hardware gives the intended ordering in scanner
and Sandy modes, including attacks and clean exit. Test simultaneous NPC tiers,
non-Sandy enemies, EMP, repeated toggles and save/load. Actual multipliers require
measurement; do not interpret a raw override as an observed speed percentage.

If current actions do not refresh overrides or support scanner activation, retain
verified enemy-tier behavior and mark the scanner contest incomplete. Do not
silently expand this into a new time manager. Evaluate a separate TDO-backed
profile instead, explicitly relinquishing SDP scanner ownership.

## 6. Bounded reinforcements without changing reputation

Use RS's dispatcher, calls, faction rosters and vehicles. Keep Street Cred and
bounty earned. Proposed starting configuration:

| RS setting | Test value |
| --- | ---: |
| initialHeat | 1 |
| minimumGraceTime / maximumGraceTime | 20 / 75 seconds |
| baseCallDuration | 20 seconds |
| callsLimit | 2, with the adapter below |
| reinforcementNotification | true |
| rapidResponseEnabled, artilleryEnabled, ttCoverageEnabled | false initially |
| carCalls | false initially |

These settings alone do not guarantee two waves. The local attempt method checks
`callsLimit < callsPerformed`: equality allows another attempt. Biomon and tick
paths can call the handler directly, and its counters are per faction.

Use a separate dependency-gated redscript adapter. Public non-abstract
`HandleReinforcementCall` and `PrepareToSpawnVehicles` are candidate hooks;
compile a minimal probe against this exact module first. Guard successful calls
and dispatches, allowing two total across participating factions per combat
episode. Reserve allowance before dispatch and reconcile failure; interrupted
calls do not consume it. Denied calls must not still add bounty/heat or schedule
arrivals. Trace overrides and AV/special paths; exclude unguarded paths initially.

Share a small episode state with telemetry: combat starts it, re-entry within
the existing 60-second encounter tail retains it, and quiet exit with no pending
arrival closes it. Save/reload must not reset the allowance. Persist versioned
counters, not transient actor handles. If episode/arrival observation proves
unreliable, use a conservative persistent rolling limit and label its semantics.
Do not claim an exact encounter bound without demonstrating it.

A call may spawn several vehicles and NPCs: dispatch count is not an actor cap.
Measure arrivals and frame time. TWR's `enableReinforcements` and
`questReinforcements` remain false. Add its memory later after separately checking
retaliation/spawn settings. No new dispatcher or authored encounter system.

## 7. Selected weapons and measured rewards

Build a Gunsensical allowlist for one power, one tech and one smart weapon. Trace
shared records and dependencies before extracting a file; directories are not
dependency boundaries. Start with handling, range, lock behavior and reviewed
weapon damage. Initially exclude `perks`, `PerkChanges.reds`, `encounter_balancing`,
`prices`, `npc_damage` and `shooting_patterns`. Its finisher script tests native
perk purchase state, and `.tweak` files change packages our shards can clone.

Avoid stacking full Gunsensical, ENC and a shooting mod before calibration.
Harder Gunfights alters time-between-hit allowances and intentional misses; No
Shooting Delay changes firing-pattern pauses. Distinct records can still compound
lethality. The latter's staged init requires a missing `Modules/main.lua`, so
repair and verify that package before considering it. No standalone Immersive
Shooting AI staging copy was found; retain it as a research alternative.

Measure rewards before imposing a new cap. Bounded dispatch is the first farming
control. Log each family's damage/time/event/resource XP, native skill XP,
duration and loot. A damage-only cap cannot constrain all training, and the
60-second encounter tail can merge legitimate fights.

If farming persists, add a finite persistent reinforcement reward allowance or
diminishing awards for reliably identified dispatch actors. Do not infer that
identity from faction/rarity or impose an arbitrary "three fights" cap on all
encounters. If attribution is unreliable, defer reward changes and retain dispatch
limits. Preserve family sliders, fractional carry and earned XP. The selected
combat preset must not automatically boost XP and pay for increased difficulty
twice.

## 8. Delivery and acceptance

| Milestone | Our work | Gate |
| --- | --- | --- |
| A. Reproducible profile | Source/dependency manifest, conflict list and telemetry | SDP + ENC compile and repeat baseline encounters |
| B. Four presets | Two-record adapter, per-save selection and recommendation | No compounding, cross-save leakage, HP refill or settings write contest |
| C. Backup | RS configuration and dispatch guard | Two total successful dispatches across factions, failure/bypass paths and reloads |
| D. Hardware contest | Four-tier table and minimal activation patch | Quality ordering, usable attacks and clean restoration; unsupported modes explicit |
| E. Equipment access and weapons | One specialist weapon/OS access route and three audited weapons | Endgame access with unrelated skills at 1; shard effects remain correct |
| F. Calibration | Reward measurements, more weapons, optional TWR/pressure mod | Viable specialist/hybrid/all-mastered play and acceptable performance |

C and D are bounded integration experiments, not guaranteed settings-only edits.
When an adapter would require a replacement subsystem, evaluate another existing
backend. Custom item grades, authored district bands, capability simulation,
new AI roles and our own spawner stay outside lite.

Compare fixed encounters and equipment on specialist, hybrid and all-mastered
saves, plus high-skill/low-mastery and purchased-perk saves. Include melee,
firearms, stealth and netrunning. Log effective NPC HP/damage, kill time, incoming
damage, time ratios, dispatch/actor counts, XP/minute and p95 frame time. Retain
the existing shard regression checks. Start with a matched-scene performance
target within 10% of baseline frame time; dense scenes and bosses need separate
checks. Numeric combat targets follow captures, not guessed level equivalents.

Publish a pinned supported stack and unsupported modes. Default to unmodified
dependencies and original adapters. Extract code/data only with recorded
permission/provenance and required attribution. No third-party source edits,
activation or redistribution occur as part of this planning revision.
