# Combat AI and archetype comparison

Decision update: the [SDP Combat plan](WORLD_PROGRESSION_BACKEND.md) now selects
features for our own backend. The backend-choice recommendation below records
the earlier comparison; donor mods will serve as separate benchmarks instead.

2026-10-01. Compared local staged ENC PL-Beta-1.8.8 hotfix, Combat Revolution
1.4.3 and Combat Evolved 4.16.8. This is a selective source-level comparison,
not a measured gameplay or performance ranking. All remain disabled for this work.
The [lite plan](WORLD_PROGRESSION_LITE.md) and [integration audit](WORLD_PROGRESSION_SOURCE_AUDIT.md)
cover compatibility separately.

## Assessment

**Combat Evolved is the strongest candidate for explicit reactive squad behavior;
ENC is the strongest candidate for deliberately authored enemy variety; Combat
Revolution emphasizes relentless action and pressure.** These are judgments from
the inspected implementations, not proof that one consistently plays better.

The previous ENC recommendation prioritized a small integration surface. A deeper
AI comparison justifies an ENC-versus-CE gameplay trial before locking the backend.
Do not combine the complete mods to obtain both sets of strengths.

| Dimension | Enemies of Night City | Combat Revolution | Combat Evolved |
| --- | --- | --- | --- |
| Main architecture | Extensive TweakDB action/condition changes and authored character/archetype assignments | Broad native action, ability and timing edits through YAML and CET | Runtime per-NPC state and reaction logic, plus native-action/data changes |
| Tactical identity | Cover preferences, reckless behavior, role-specific movement and abilities | More pursuit, faster attacks, more simultaneous threats, broader ability use | Suppression/pinning, flanking, covering fire, failing-cover response, morale/flee/re-engagement |
| Squad coordination | Native squad/cover conditions and support behaviors are retuned | Concurrency restrictions are relaxed; aggressive action selection | Explicit same-faction ally selection and a covering-fire state during flanking |
| Shooting | Archetype equipment/patterns, smart-weapon tuning and behavior changes | Includes global zeroing of pattern delays | Range/weapon/skill-dependent cadence and accuracy, movement/camo/impairment modifiers |
| Melee | Authored chrome/movesets, defensive abilities and special enemies | Strong pursuit/combos; melee and pursuit ticket limits removed in inspected data | Archetype handling, faction style and optional melee swarm/charge behavior; swarm defaults on locally |
| Archetype approach | Named and configured faction specialists with specific loadouts | Reworks existing generic/fast/heavy/runner/etc. archetype tiers | Broad role classification plus faction profiles, with separate weighted chrome assignment |
| Cyberware distribution | Predetermined ability groups attached to selected archetypes/characters | Expanded ability lists on shared archetype groups | Spawn-time selection weighted by role and faction, gated by tier and faction limits |
| Netrunners | Broad hack loadouts and dedicated cover-action graphs | Highly capable high-tier runners with mobility, sensing, defense and support/offensive hacks | Role-specific stats/resistance, faction doctrine and shared tactical systems; inspected code gives less evidence of an ENC-sized bespoke runner action catalogue |
| Strongest fit for SDP | Enemies with distinct strengths that invite different mastered abilities | Testing very powerful builds under sustained action pressure | Making suppression, movement, cover and fear remain relevant as player power grows |

## ENC: authored encounter pieces

Concrete examples from local CET `Enemies of NC/Modules`:

- `EnemyVariety.lua:470` gives AnimalsTechjock Berserk, a techie role, heavy
  subdermal armor, bleed immunity and a tactical ability group. This is a designed
  combination, not simply a generic enemy with extra health.
- `Base.lua:518-525` builds cover-preference, harassment and Sandy dash-shoot
  groups. `Base.lua:3296` assigns a Tyger ranged archetype a particular combination
  of Sandy, Kerenzikov, armor, damage/resistance and cover-oriented abilities.
- `Base.lua:680-690` defines extensive runner ability groups;
  `Base.lua:860-863` changes their cover behavior graph, including hacking,
  reloading, shooting and healing choices.
- `Base.lua:873-883` conditions reckless cover exits on nearby squadmates and
  target visibility. `Base.lua:12573-12597` adds different cover-exit approaches,
  including a Sandy sprint, while excluding runners from those movement cases.

This is genuine behavior work as well as content. It would be inaccurate to
describe ENC as only stats and cyberware. However, the inspected text does not
establish a CE-like general runtime suppression/morale coordinator.

The author's roster also includes specialized faction enemies and substantial
boss/moveset changes. Its long description explicitly warns that parts are old,
so current local records take precedence over treating every historical feature
as verified. [ENC author page](https://www.nexusmods.com/cyberpunk2077/mods/8467).

Tradeoff: authored units can preserve distinct weaknesses, but broad changes to
immunities, perception, hacking and bosses need balance tests. A named archetype
is not automatically a new AI controller; much of the differentiation is which
existing/custom actions its ability groups make available.

## Combat Revolution: remove hesitation and expand action use

Local `r6/tweaks/Combat` and CET `Combat/Modules` show concrete pressure increases:

- `EnemyAI/Chasing/Tickets.Chasing.yaml` removes the pursuit ticket ceiling and
  sets the CatchUp cooldown to 0.01. Other remaining conditions still decide
  eligibility; this does not mean every actor always chases.
- `EnemyAI/Melee/MeleeTicket.yaml` removes melee ticket ceilings and cooldown
  entries. Larger squads can therefore produce much more simultaneous pressure.
- `Modules/No Shooting Delay.lua` enumerates pattern-delay records and writes
  delay zero. This is different from choosing tactically appropriate burst rests.
- `Modules/Consumable.lua` allows healing below 50% health in more situations,
  including cover and pursuit-related cases; the configured regeneration is 12
  per second over a duration value of 5. Verify effective health recovery in-game.
- `EnemyAI/Chasing/CatchUpSprintCondition.yaml` adds role-aware range logic for
  snipers. Thus the mod also changes decisions, not only speed.

The archetype model is mainly expanded native classes: generic/fast/heavy melee
and ranged, shotgunner, sniper, techie, netrunner and android, across tiers. Do
not equate a count of edited tier records with that many unique tactical roles.

Example: `EnemyAbility/ArchetypeData.NetrunnerT3_inline4.yaml` combines offensive
and support hacks with Sandy, charge jump, dodge, passive regeneration, stims,
wall sensing, thermovision and a reinforcement-call ability. This can create a
versatile threat, but may reduce clear role weaknesses. That is a balance risk,
not proof that every enemy receives this loadout.

The author also describes faster melee combinations and anti-kiting knife attacks;
the melee knife implementation credits ENC. [Combat Revolution author page](https://www.nexusmods.com/cyberpunk2077/mods/20225).

Fit: a candidate for aggressive endgame combat, with concurrency, healing and
firing pressure tuned first. Unrestricted action counts combined with added
reinforcements can overwhelm through simultaneity without requiring coordinated
decisions. I would not select it first when the goal is specifically smarter
squad tactics.

## Combat Evolved: stateful reactions and squad maneuvers

Local `r6/scripts/CombatEvolved` provides explicit mechanisms:

- `GBP_Hooks.reds:406-409` triggers individual/squad flank logic from hits.
  `GBP.reds:321-369` examines nearby same-faction allies, requests flanks and can
  put a covered ally into a four-second suppressing state. It is not a strict
  one-flanker/one-suppressor scheduler; multiple allies can pass the flank test.
- `GBP_Flank.reds` uses faction chance, cooldowns, combat state and player speed.
  Pinned, fleeing or already maneuvering enemies do not flank. It chooses a side
  position rather than only increasing forward movement speed.
- `GBP_Maneuver.reds` first signals native combat interruption, checks whether the
  NPC moved/changed cover, then issues a nav-enabled movement command if needed.
  Delayed watchdogs handle failure. It supplements native AI rather than replacing
  the entire behavior tree.
- `GBP_Suppression.reds` converts player gunshot stimuli near the aim line into
  decaying pressure, then temporary pinning and morale effects. It approximates
  near-miss fire geometrically; it is not a full bullet-trajectory simulation.
- `GBP_Shooting.reds:88-140` varies burst delays with weapon range and NPC skill.
  Suppressors use longer bursts and shorter pauses. Accuracy code considers
  range, movement, cover, camo and impairments. Smart weapons have a separate path.
- `GBP_Intent.reds` changes shot quality for panic, pinning, suppression,
  repositioning and anchoring. Morale/flee/re-engagement code provides additional
  responses to pressure and casualties.

Faction distinctions are executable parameters, not just names. In
`GBP_Profiles.reds`, Militech has a 0.44 flank chance for eligible rarity >= 1 and
0.82 suppressor chance; the Voodoo Boys profile uses 0.24 for eligible rarity >= 2
and 0.40. These are chances after gating conditions, not overall observed rates.
Tyger profiles also assign cover preference to certain roles and harassment to
melee roles.

Archetype/stat classification uses equipment and records: shotgun, SMG, rifle,
sniper/precision, runner, heavy ranged and melee classes, with fallback logic.
Chrome matching separately combines archetype-category affinity, faction weights,
minimum tier and faction tier limits, then samples without replacement.
`GBP_ChromeDist_Factions.reds` gives Scavs a lower maximum tier and fewer default
rolls than heavily equipped factions. Density is a useful future progression
control, but affects new assignments and requires save/streaming tests.

This aligns with the author's emphasis on faction behavior and coordination.
[Combat Evolved author page](https://www.nexusmods.com/cyberpunk2077/mods/29125).

Limits worth testing:

- The flank helper called BelievedPlayerPos returns the player's actual position;
  that helper is not a last-seen-position memory system. Do not infer general
  wall vision from this alone, but test flanking after line of sight is lost.
- Computed flank positions retain NPC height and depend on navigation succeeding.
  Test interiors, vertical encounters and stuck-NPC recovery.
- The chrome sampler does not itself enforce exclusive OS combinations; actual
  generated combinations and usable animations/actions need inspection.
- Config defaults enable unlimited melee tickets. Tactical features do not by
  themselves guarantee limited simultaneous attacks.
- HP, armor and damage pipelines are substantial parts of CE. Its optional player
  HP override must stay off with SDP; combat integration is broader than enabling
  only a flanking module. Runtime callbacks imply profiling work, not proof of
  worse performance.

## Other researched mods and the backend decision

Enemy Rarity Fixes Improved mainly changes classification/equipment and includes
a time-method replacement; it is not a substitute for a full tactical layer.
Time Dilation Enhanced/TDO address reflexware behavior, while shooting-delay mods
address pressure. Reinforcements and TWR change who joins a fight or remembers
the player. None alone replaces the three broad overhauls compared here.

For SDP, run two clean profiles: ENC for authored enemy identity, CE for reactive
tactics. Benchmark the same cover fight, mixed runner/melee/ranged squad, melee
group and elite Sandy encounter on specialist and all-mastered saves. First use
each backend's defaults and record lethality; then normalize rough kill/survival
times before comparing tactical quality. Keep extra spawners and shooting mods
off for that comparison.

Observe flank completion, cover changes after pressure, ally covering fire,
suppression response, runner uptime, usable cyberware, simultaneous attackers,
stuck actors and frame time. No in-game results are claimed here. Keep ENC as the
current lite baseline until this comparison establishes a reason to replace it;
CE deserves the first competing trial on AI merit.
