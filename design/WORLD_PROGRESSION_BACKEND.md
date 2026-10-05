# SDP Combat: our backend, assembled from selected features

Status: preferred implementation direction, 2026-10-01. Replaces the external-
backend selection in [World Progression Lite](WORLD_PROGRESSION_LITE.md). This is
an architecture and delivery plan, not implemented runtime code. No mods have
been enabled or modified.

Own enemy definitions, combat decisions, progression and configuration in a
separate opt-in `SDPCombat` module. Reuse native Cyberpunk actions, selected
permitted mod components and unmodified optional dependencies. The installed
overhauls become feature sources and benchmarks; none is the required AI backend.

The [source comparison](COMBAT_OVERHAUL_COMPARISON.md),
[integration audit](WORLD_PROGRESSION_SOURCE_AUDIT.md) and
[research register](WORLD_PROGRESSION_MOD_RESEARCH.md) are the evidence base.
The original [large world design](WORLD_PROGRESSION_PLAN.md) remains a backlog,
not the first-release scope.

## 1. Feature selection

"Best" is a hypothesis to validate by feature, not a reason to import everything.

| Feature | Reference/source | Our implementation decision |
| --- | --- | --- |
| Distinct faction specialists | ENC archetype and ability-group assignments | Adapt a small, dependency-complete set where provenance permits; own the resulting faction/role records |
| Flank with covering fire | CE runtime squad coordination | Implement our own bounded role scheduler using native movement/shooting actions |
| Suppression and morale | CE pressure, pinning and flee concepts | Implement independently; suppression first, morale later; preserve enemy-type immunity to fear |
| Useful pursuit and repositioning | CR role/range-aware action conditions | Selectively adapt suitable conditions; retain attack/pursuit concurrency limits |
| Melee variety and anti-kiting | ENC/CR action and ability work | Reuse compatible native actions and selected permitted adaptations, with telegraphs and cooldowns |
| Enemy Sandy abilities | ENC and Time Dilation Enhanced tier/action graphs | Extract only resolved components or create equivalent records under our namespace; own hardware contest and activation policy |
| Weapon identity | Selected Gunsensical records | Curated weapon/handling changes after dependency and attribution checks; keep perk/economy changes out of the initial package |
| Reinforcement vehicles and routing | Reinforcements System | Optional unmodified dispatcher with our limit adapter; no new vehicle-spawn engine |
| Notoriety | Native reputation; optional TWR later | Keep earned reputation independent; one dispatch owner and separately tested retaliation |

Do not import global zero firing delays, unlimited melee/pursuit, every ability
on every elite, flat replacement player HP, or an entire overhaul's startup
routine. Select the behavior that helps a role and author its limits centrally.

### Reuse boundaries

ENC and CR permit credited modification/use on their author pages, with conditions;
trace inherited ENC/SDO and other contributions per component. CE requires author
permission for modification/assets: use its observed behavior as a reference and
write our own implementation unless permission is obtained. Renaming its classes
would not make copied code original. Keep RS/TWR as external dependencies rather
than vendoring restricted implementations. Sources:
[ENC](https://www.nexusmods.com/cyberpunk2077/mods/8467),
[CR](https://www.nexusmods.com/cyberpunk2077/mods/20225),
[CE](https://www.nexusmods.com/cyberpunk2077/mods/29125).

For each adopted component, record upstream version/file/hash, relevant author
terms, attribution, all referenced records/resources, changes and acceptance
tests. The existing source manifest fingerprints inspected files; it does not
certify an extraction's complete dependency closure. Restricted or unresolved
components get an original/native implementation path, so permission is not a
project-wide blocker. This plan does not authorize contacting authors.

## 2. Single ownership architecture

```text
SDP skills/mastery/equipment -> progression policy -> encounter configuration
                                                     |
faction + role + hardware definitions -> eligible NPC registry
                                                     |
perception/events -> squad decisions -> action requests -> native game actions
                         |                  |
                   shared limits      time coordinator
                         |
                  optional dispatch adapter

All owned changes -> telemetry, cleanup and versioned save state
```

| Component | Owns | Boundary |
| --- | --- | --- |
| Definition loader | Faction, role, hardware and encounter-policy data | No NPC mutation or global stat rewriting |
| Actor registry | Eligibility, assigned profile, owned modifiers/abilities and lifecycle | No enrollment of corpses, companions, neutrals or quest-controlled actors |
| Squad coordinator | Role assignment, suppression state, reservations, cooldowns and action priority | Native AI executes movement, animation, cover and weapon use |
| Combat tuning | Selected NPC/weapon modifiers and firing policy | Player health, attributes and perk ownership remain with SDP/native systems |
| Time coordinator | Source recognition, hardware comparison, competing slowdown requests and restoration | Exactly one owner of our time hooks; honor pause/cinematic/native priorities |
| Progression policy | Difficulty recommendation, allowed hardware profiles and specialist access rules | No rewritten Street Cred, no weighted Level as world power |
| Dispatch adapter | Admission/count limits and wave attribution | Optional RS handles vehicles/rosters; no second spawner |

All records belong under `SDPCombat.*`. Patch shared native selectors only where
necessary, with explicit eligibility gates and native fallback. Every modified
record/method appears in an ownership inventory. This is not a blanket replacement
of native behavior trees. Frameworks such as redscript, TweakXL and Codeware may
remain dependencies; full ENC/CR/CE/TDO packages stay disabled in this profile.

## 3. Author roles first, then vary their hardware

Start with three roles across two factions:

| Role | Shared job | Maelstrom prototype | Arasaka prototype |
| --- | --- | --- | --- |
| Assault | Hold useful range, fire, cover another unit's move | Aggressive, heavier chrome, fewer stealth options | Disciplined cover and coordinated fire |
| Rusher | Close distance or displace a stationary player | Durable approach with Berserk candidate | Reflexware-assisted approach with a visible activation cue |
| Runner | Maintain upload opportunities and support allies | Disruption-oriented loadout | Defensive/support-oriented loadout |

These are proposed authored profiles, not claims about exact upstream defaults.
Use existing compatible NPC skeletons, weapons and actions. A capability check
must precede granting an ability; a valid record ID does not prove its animation
or behavior works on that actor.

Each role specifies engagement range, cover preference, legal actions, attack
cadence, allowed hardware, vulnerabilities and upgrade slots. Each faction biases
those choices. Equipment quality and threat change bounded profile fields rather
than replacing the enemy's identity.

For the first slice, use fixed loadouts. Later add deterministic variation within
authored slots: one primary OS, compatible support chrome and a fixed budget.
No independent random roll can accidentally grant both Sandy and Berserk unless
an explicitly authored exceptional profile permits it. Preserve assignments
across streaming/save reload where identity can be resolved reliably; do not
reroll live opponents to match a newly equipped player weapon.

## 4. Tactical rules we own

Use a single per-encounter scheduler instead of independent scripts all issuing
commands. Initial test limits: one flanking maneuver, two melee attack reservations
and one hostile upload at a time. Limits include relevant native activity where
observable; simply limiting our own requests does not bound native attacks.

Decision order: scripted/native safety restrictions, disable/stun state,
defensive recovery, existing action completion, coordinated maneuver, ordinary
role action. Reservations expire and release on failure, cancellation, death,
unload and combat end. A generation token invalidates stale callbacks.

Flanking requires a current sighting or shared last-known position with age and
confidence. Do not continuously read exact player coordinates through walls.
Validate reachable positions and height changes; if navigation fails, return to
native cover/pursuit rather than repeatedly forcing a move. Covering fire trades
accuracy for pressure and consumes an actual firing opportunity.

Suppression initially uses qualified shot/stimulus events, distance/aim proximity
and visibility/occlusion checks where available. It is an approximation, so do
not label it simulated bullet trajectories. Pressure decays, pinning is brief,
and a recovery cooldown prevents indefinite locks. Bosses/mechanical actors have
explicit eligibility rules. Morale and surrender/flee interactions come after
suppression works; preserve quest immortality, nonlethal state and native fear
restrictions.

Avoid per-frame scans of the whole world. Coalesce events, evaluate only enrolled
combat actors and stagger any necessary updates. Measure update cost before
expanding squad size; no performance guarantee follows from a chosen tick rate.

## 5. Time and equipment remain core goals

Owning the backend removes the need to make our hardware contest write into ENC's
settings. Own a small set of tier-specific time-action records, a hardware-rating
interface and one coordinator. Reuse existing action mechanics where they work.

Scanner compares deck/optics processing capability against active enemy reflexware;
Sandy compares active devices; Kerenzikov gets an explicit policy. Skills refine
effectiveness without deleting hardware differences. Use a bounded table first,
then calibrate inferior/equal/superior cases. Do not equate raw engine overrides
with observed speed. Test attack cadence, projectiles, animation and cooldown
clocks as well as movement. Native individual-time cleanup can affect other
effects, so source arbitration and restoration are mandatory.

No per-NPC time controller is assumed necessary up front. Prototype tier action
records and transitions; add actor-specific handling only if the measured native
path requires it. Inherited condition names must resolve without donor mods or
archives, including scanner activation. Do not ship unresolved ENC record names.

Equipment access stays tied to relevant mastery and upgrade routes, separate
from difficulty. Early experiments keep the existing native Level/PowerLevel as
a controlled compatibility baseline. Audit specific vendor/loot/equip consumers
before redirecting them. A specialist must eventually access appropriate endgame
gear without training unrelated skills; the first backend prototype alone does
not solve that issue. New quality enums and custom equipment tiers are deferred.

## 6. Small delivery slices

| Slice | Concrete result | Acceptance |
| --- | --- | --- |
| 0. Ownership skeleton | Separate opt-in module, eligibility registry, record manifest, telemetry and native fallbacks | Loads with all donor overhauls disabled; no NPC changes outside the test selection |
| 1. Six role profiles | Two factions x three roles, fixed compatible loadouts; one selected behavior adaptation per role | Distinct jobs, functioning abilities, no duplicated stats or overwritten player progression |
| 2. Coordinated fight | One flanker plus covering fire; suppression and bounded action reservations | Reachable moves, last-known-position behavior, graceful failure and complete reservation cleanup |
| 3. Contested hardware | Three hardware grades tested in scanner/Sandy modes | Inferior/equal/superior ordering, working attacks and restored time on every exit |
| 4. World connection | Per-save difficulty presets, one specialist weapon/OS access route, guarded optional RS dispatch | No mid-fight rescaling, two-dispatch test bound, no reputation manipulation, specialist access demonstrated |
| 5. Expansion | More factions/roles, selected weapons, measured reward controls and optional morale | Benchmark gates continue passing; every new feature has a reason and an owner |

The first playable backend is slices 0-2; the first demonstration of the original
hardware-contest goal includes slice 3. Extract dependencies per feature, not
entire donor modules just because a useful function sits inside one.

Use identical test encounters with native behavior as baseline and separate ENC,
CE and CR profiles as benchmarks. First measure their default lethality, then
approximately normalize survival/kill times to compare decisions rather than
damage alone. A feature stays only if its contribution is visible: completed
flanks, useful support, counterable pressure, meaningful hardware differences.

Test specialist, hybrid, all-mastered and purchased-perk saves. Include failed
navigation, simultaneous attacks, stealth exit, nonlethal defeat, death, streaming,
save/load, pause/cinematics and mod disable. Log actor/dispatch counts, kill and
survival times, time ratios, XP by channel and frame time. Fix behavior before
raising HP to hide a weak decision system.

Retain the lite reward principle: bound dispatch first, measure all XP channels,
and adjust only reliably attributed reinforcement rewards if farming remains.
Persistent encounter allowance must survive save/reload and not reset on briefly
leaving combat. Do not rebuild a general encounter economy for the first release.

## 7. Scope and honest cost

This is more work than configuring ENC, because we now own lifecycle, scheduling,
compatibility and testing. The savings come from reusing the native action engine
and selected existing work, not from assuming arbitrary pieces are plug-compatible.

Do not bring back eight authored world bands, a universal power simulator,
hundreds of new item records, a custom spawner or a full replacement behavior tree
as prerequisites. The stable contracts above let the backend grow after the
small combat slice proves worthwhile. The previous lite plan remains useful as
a source of constraints and integration findings, not the active architecture.
