# World progression beyond the vanilla perk budget

Status: long-term design/backlog, 2026-10-01. The source-audited
[SDP Combat backend plan](WORLD_PROGRESSION_BACKEND.md) is now the preferred
delivery plan, combining native actions and selected mod components under our
ownership. The larger world systems below are deferred until a small combat slice
demonstrates their need. No gameplay changes are enabled by this document.
Supersedes the [specialist level-mapping proposal](SPECIALIST_BALANCE.md).
The [README](../README.md) remains the guide to implemented behavior.
See the [mod research and reuse register](WORLD_PROGRESSION_MOD_RESEARCH.md)
for sources, permissions, local evidence, and integration choices.

## 1. Design decision

Build a world that can challenge the expanded character, rather than compressing
that character into vanilla level 1-60. Five skills at 60, attributes at 20, and
many permanently mastered shard families create a different ceiling from an
ordinary level-60 build. Skill Rank 296 is a progress counter, not a useful enemy
level or a claim that the character is 4.9 times stronger.

The new progression has three independent tracks:

| Track | What advances it | What it controls |
| --- | --- | --- |
| Character mastery | Skills, recorded shards, usable equipment | Actual player capabilities; never a requirement to train unrelated skills |
| Equipment development | Relevant mastery, components, suppliers and recovered technology | Access to better weapons and cyberware, including specialist endgame equipment |
| World threat | Location, encounter purpose, faction resources and persistent notoriety | Squad composition, equipment grade, tactics and bounded backup |

These tracks interact without moving in lockstep. Winning an elite contract can
unlock equipment and attract better-funded opposition. Changing a gun must not
instantly upgrade every enemy. Ordinary thugs should eventually be easy; the
upper ceiling lives in elite locations, dangerous contracts and faction responses.

## 2. Separate engine compatibility from our progression

Keep native Level within the supported range as a compatibility value. Introduce
our own data-driven threat bands and equipment grades without extending the
engine's Quality enum or assuming its curves work above 60.

The current implementation has TWO scaling inputs to unwind:

- `SkillTotalLevel.reds` derives compatibility Level from the average skill.
- `SkillDrivenPowerLevel.yaml` independently derives PowerLevel from that average.
  Its documented consumers include health, item quality and armor effectiveness.

Audit actual consumers in the installed game before replacing either. Classify
each as UI/quest compatibility, player health, enemy stats, item generation,
requirements, vendor availability, native skill XP, shard XP or economy. Assign
an explicit replacement or deliberately retain native behavior; do not redirect
every consumer to a new giant level number.

Build a capability ledger with offense (burst and sustained), survivability,
control/hacking, mobility and time advantage. Read the effective union of native
perks, recorded shard effects and temporary training effects, counting equivalent
packages once. Use equipment and synergy tags as inputs. A perk count alone is
insufficient: healing loops and kill-trigger chains can outweigh several bonuses.

Use this ledger for test-build classification and selecting eligible high-risk
content. Do not use observed DPS or deaths to invisibly resize enemy HP mid-fight.
Calibrate against fixed reference builds; assess conditional perks separately
instead of pretending to calculate one exact universal power score.

## 3. World threat with room above the old endgame

Start with eight authorable bands. These are content bands, not equal HP steps:

| Band | Encounter identity | Main source of difficulty |
| --- | --- | --- |
| 1: Street | Poorly equipped opportunists | Numbers and positioning; little chrome |
| 2: Trained | Organized local crews | Cover, basic roles and limited implants |
| 3: Professional | Security and established gang teams | Mixed weapons, a specialist, reliable backup calls |
| 4: Veteran | Experienced faction squads | Role coordination, better armor and cyberware |
| 5: Elite | High-value guards and hunters | Strong equipment, support roles and time resistance |
| 6: Strike team | Deliberate assault/defense units | Synergistic specialists, multiple attack routes |
| 7: Apex | Top faction assets | Strong counters with exploitable weaknesses and scarce resources |
| 8: Exceptional | Bespoke endgame operations | Multi-objective fights and advanced combinations of established mechanics |

Bands 6-8 provide expansion space; their relationship to vanilla endgame must be
measured, not asserted from the names. Additional bands can be authored later.

Each location/mission supplies a permitted band range and encounter budget.
Faction resources and persistent heat choose a template within that range.
Selection happens at encounter creation and remains stable through that fight.
Heat rises through attributed hostile actions and consequential victories, with
cooldown/decay and a visible warning before a major response. Mere skill gains
do not alert a faction. Initial implementation excludes scripted quest encounters.

Budget model: `sum(role cost + equipment cost + cyberware cost) + coordination
surcharge <= encounter budget`. A cheap crowd, a small elite team and a mixed
squad spend that budget differently. Costs are measured in playtests, not inferred
from rarity. Keep enemy rarity, threat band, equipment grade and squad role
separate so one designation does not multiply health, damage and rewards twice.

## 4. Equipment progression that supports specialists

A specialist should unlock their next equipment grade through their relevant
mastery and access to materials or suppliers. Broad training is not a gate.
Cross-discipline builds gain options and combinations, rather than exclusive
access to the highest quality of every weapon.

Define custom equipment grades as data attached to records, mapped to supported
native quality/UI where needed. Eleven shard grades do not automatically imply
eleven native cyberware quality values. Start with existing equipment tiers and
two experimental endgame grades; expand only if each adds a meaningful choice.

Separate base weapon identity from grade growth. Tune damage, penetration,
handling, reload/heat, charge time, ammo efficiency and smart-lock behavior.
Preserve reasons to choose power, tech and smart weapons. Better guns can
penetrate advanced protection or operate more reliably without every upgrade
being a large multiplicative DPS increase. Preserve iconic identities.

Audit shared player/NPC weapon records: changing one shared damage value can buff
both sides. Own base weapon tuning in one module and NPC accuracy/fire discipline
in another; log the final damage path to catch native scaling applied a second
time. Decide whether each grade changes both player and NPC equipment explicitly.

Benchmark combined health, mitigation, healing, cooldown reductions and on-kill
refreshes. Fix unintended unbounded loops and overlapping multiplier application
before compensating with enemy damage. Intentional mastery remains valuable.
Advanced enemy armor should have bypasses, breakable protection or vulnerable
states instead of universal huge health pools.

## 5. AI and cyberware distribution

Assign cyberware by faction resources, role, threat band and compatible NPC
archetype. Installing a record alone does not guarantee an actor has the required
animation, action or behavior. Validate that compatibility before assigning it.
Save the chosen loadout or a deterministic seed; streaming must not reroll enemies.

Initial faction hypotheses: chrome-heavy Maelstrom teams and better-coordinated
corporate security. Prototype only these two, then author individual faction
profiles. Do not give every high-band enemy a deck, Sandy and Berserk together.
OS combinations require an explicit exceptional archetype and readable cues.

Roles: suppressor, flanker, rusher, marksman, netrunner and support. Give each
cover/line-of-sight rules, movement preferences and ability priorities. Squad
coordination limits simultaneous rushes, grenades and hostile uploads. More
enemies must not mean all attacks land at once. Start with two melee attackers
and one hostile upload at a time, then test encounter-specific limits.

Cyberware should change behavior: reflexware enables repositioning and evasion;
armor supports a deliberate advance; a runner protects or disrupts; healing has
a limited budget and vulnerable activation. Perception still needs sight,
sound, shared reports or a visible scanning ability. Counters must be distributed
by faction doctrine, not secretly selected to negate the equipped player build.

## 6. Contested scanning and time dilation

This is an early technical prototype because it determines whether the intended
combat ceiling is practical. Existing `ScannerDilation.reds` sets both scanner
global/player flats from Netrunner skill, defaulting from 0.99 to 0.03. It does
not currently contest equipped hardware against an enemy.

Introduce a hardware comparison interface:

| Slow-time source | Player rating | Enemy rating |
| --- | --- | --- |
| Scanner with cyberdeck | Deck processing grade, bounded Netrunner contribution | Active reflexware grade |
| Scanner without cyberdeck | Optics/scanner baseline, bounded skill contribution | Active reflexware grade |
| Player Sandevistan | Active Sandy grade and its effective speed | Active enemy Sandy grade |
| Kerenzikov/other effects | An explicit source-specific adapter | Compatible active reflexware |

Custom grades belong to our model. Compare normalized hardware ratings, not raw
RAM against an unrelated Sandy stat. Skills can refine efficiency but must not
erase every hardware difference. Dual-OS support selects the active source rather
than summing both devices. Unsupported slow-time sources initially retain native
behavior and produce a diagnostic, rather than being guessed from one boolean.

**Scanner prototype:** let `g` be global time scale and `delta` be enemy rating
minus scanner rating. Give an enemy with active reflexware a resistance fraction
`r(delta)`. Desired observed speed is `v = g + (1-g)*r`, measured against that
enemy's ordinary movement speed. Initial test values:

| Rating difference | Resistance r | Observed speed at g=0.03 |
| --- | ---: | ---: |
| -2 or lower | 0.10 | 0.127 |
| -1 | 0.25 | 0.2725 |
| 0 | 0.45 | 0.4665 |
| +1 | 0.70 | 0.709 |
| +2 or higher | 1.00 | 1.00 |

Interpolate intermediate ratings. Without active reflexware, `r=0`: the actor
follows global slowdown. These are proposed tuning values, not verified engine
multipliers. At normal time (`g=1`) the scanner rule provides no speed bonus.

**Sandy prototype:** compare observed enemy speed to the player's effective Sandy
movement rate, aiming for equal hardware to move comparably, inferior hardware
to retain a disadvantage and superior hardware to retain an advantage. Calibrate
this separately from scanning: scanner UI/camera time and player locomotion are
not interchangeable clocks. Test bullets, melee, animations and reaction timing
as well as travel speed; a running NPC with frozen attacks is not the feature.

Reflexware has activation cues, finite uptime and a cooldown. EMP and Cyberware
Malfunction can interrupt appropriate devices; elite resistance shortens or
contests the disable rather than making every elite permanently immune. A scan
reveals relevant hardware so players can understand why an enemy keeps moving.
Prototype an optional finite combat-focus budget to prevent indefinite safe
scanning; keep ordinary identification available when the slowdown budget ends.

Implementation constraints observed in local native scripts:

- Individual dilation supports `ignoreGlobalDilation` and `useRealTime`, and AI
  Sandy actions already inspect a player-dilation override. Measure composition
  before setting a multiplier; `desired/global` is only valid if the actual path
  multiplies those clocks. Tiny global scales need bounded values.
- Native individual-dilation removal is not reason-keyed. A new owner must avoid
  erasing hit reactions, scripted sequences or another active effect.
- Use one coordinator with explicit source priority, actor eligibility and
  restoration on scanner exit, OS end, death, unload and save/load. Honor native
  pause/cinematic states. Never rewrite shared tier flats per NPC.
- Define and test activation/cooldown time in real combat seconds (paused with
  the game), independent of slowdown; do not infer timer behavior from the flag's
  name. Toggle-spamming scanning must not renew an enemy's uptime or reset cooldown.

## 7. More enemies, with encounter and performance budgets

Start with bounded reinforcements, then add authored squad members where navigation
and missions tolerate them. Initial backup profile: interruptible caller, clear
arrival route, cooldown, at most two waves and an encounter-wide actor cap.
Exact actor limits follow CPU/frame-time measurements; initially compare baseline,
25% more and 50% more combatants in controlled open areas.

Do not spawn endlessly for more heat, refill a cleared room behind the player, or
spawn within immediate sight without a believable arrival. Cancel pending waves
when the encounter is no longer eligible. Restricted interiors, tutorials,
escorts, boss arenas and quest-owned squads stay excluded until individually
validated. Ambient traffic/population changes are a separate optional project.

Prefer an adapter to the locally staged Reinforcements System for the first
experiment. It must consume our allowed roster/budget, or retain ownership of
dispatch with its own bounded configuration. If that interface cannot be made
reliable, implement a small independent encounter spawner; do not run both.

## 8. Prevent reward and progression feedback loops

Current shard damage XP uses health share, enemy PowerLevel and rarity; other
channels also use level-related multipliers. More enemies and raised stats can
accelerate training, loot and money enough to invalidate the new difficulty.

Give each encounter a reward budget based on authored threat and objectives,
separate from its health multiplier and raw headcount. Allocate it among eligible
actors/actions. Reward completed threat and useful training, not repeated healing,
respawning, re-enrollment or farmed infinite backup. Keep native skill XP and
shard XP as separate reward channels with separate pacing targets.

Do not erase legitimate training on tough enemies: pay the allocated damage XP
progressively, with participation and existing per-family limits, and preserve
fractional carry/settings. Budget normal loot, components and rare equipment
separately. An elite firearm reward need not require broad skill training to use.

Set shard mastery pacing targets from measured minutes of eligible activity for
specialists and hybrids. Refit the existing XP model after the new encounters
work; do not extrapolate its old player-level assumptions into the new world.

## 9. Ownership and compatibility

| Subsystem | Proposed owner | Overlap to resolve before enabling |
| --- | --- | --- |
| Player mastery and compatibility values | SkillDrivenProgression | Other attribute/level replacements |
| Threat, loadouts and NPC stats | New world module | ENC, Combat Revolution, Combat Evolved, rarity overhauls |
| AI and shooting behavior | New role module or one selected external owner | No Shooting Delay, Immersive Shooting AI, broad AI overhauls |
| Global/individual time coordination | New time module | Existing ScannerDilation, ENC time module, TDO, Time Dilation Enhanced |
| Weapon records and grades | New weapon module | Gunsensical and other weapon patches |
| Backup dispatch | Reinforcements adapter OR independent dispatcher | Native prevention and other reinforcement mods |

Integrate small features where permissions and dependency boundaries allow it.
Do not stack entire overhauls and try to correct whichever patch loads last.
Keep optional modules switchable before loading a test save. Detect known
conflicting owners and explain the specific overlap in diagnostics.

## 10. Implementation sequence and acceptance gates

| Phase | Deliverable | Exit gate |
| --- | --- | --- |
| 0. Baseline and audit | Exact game/framework versions, enabled mod inventory, selected archive hashes; Level/PowerLevel consumer map; encounter telemetry | Repeatable baseline fights; owner map and save backup/test profile established |
| 1. Threat foundation | Versioned faction/role/grade/encounter data; stable assignment; equipment-access and reward adapters | Specialist can obtain its next grade without unrelated skills; no double stat or XP scaling; save/load stable |
| 2. Time prototype | Scanner and Sandy quality contests with three enemy hardware grades | Measured inferior/equal/superior behavior; attacks and cooldowns work; every exit restores time correctly |
| 3. Combat slice | Two factions, three initial roles (rusher, suppressor, runner), one weapon from each firearm class | Distinct tactics/loadouts; viable melee, firearm, stealth and netrunner solutions; ordinary enemies remain readable |
| 4. Equipment and defenses | Expand weapon identities and two experimental endgame grades; audit perk synergies | Matched-grade time-to-kill and survival targets met without immunity/regen loops or unavoidable instant kills |
| 5. Squad size and response | Heat adapter, interruptible calls, bounded waves and explicit exclusions | Predictable arrivals; no runaway rewards; performance gate passes; no quest-owned spawns changed |
| 6. Upper-band content | Strike/apex/exceptional encounters, full faction profiles and settings | Specialist and all-mastered builds have meaningful challenges and weaknesses; endgame rewards support continuing play |

The first playable milestone is the three-role, two-faction slice with contested
time and one reinforcement encounter. Do not postpone the riskiest clock/AI
questions until after authoring hundreds of balance records.

Test early specialist, late specialist, two-skill hybrid, broad midgame, all-skills
max with few mastered shards, and all-skills/all-shards mastered. Include one
overlapping purchased-native-perk save. Use fixed equipment sets, seeds and
difficulty; record at least ten repetitions per representative combat benchmark.

Metrics: kill time, death/near-death rate, damage-source distribution, successful
uploads, time spent unable to act, cyberware uptime, actual dilation ratios,
training XP/minute, loot/minute and active actor count. Log p95 frame time; the
initial performance gate is no more than 10% regression from a matched baseline
scene on the test machine. This is a target to validate, not a compatibility claim.

Set numerical kill-time targets after baseline captures. Preserve a spread:
matched basic enemies fall quickly to a clean specialist attack, heavies demand
focused execution, and elites use additional mechanics. Difficulty should reward
movement, interruption and equipment decisions, not only sustained damage output.

Lifecycle regression gates: save/reload in and after combat, streaming away/back,
death/respawn, defeated/corpse handling, companion/neutral actors, quest transitions,
scanner during each OS effect, EMP during dilation, mod disable, and pending wave
cleanup. Never refill a surviving enemy's health or reactivate a corpse merely
because the actor was enrolled again. Re-run the existing shard regression checks.

Persist a schema version and stable world decisions, not transient handles or
active time multipliers. Migration preserves mastery and equipment and does not
retroactively turn the player's current encounter into an apex fight. Rollback
restores owned modifiers and cancels callbacks; once custom items are introduced,
document a supported removal procedure rather than claiming arbitrary uninstall
is safe. Keep new world gameplay opt-in until these gates pass.
