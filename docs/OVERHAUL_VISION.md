# Cyberpunk combat overhaul: design direction

Recorded: 2026-10-08. This records the planning discussion, not implemented behavior.
The companion [research index](research/README.md) maps the design to game systems
and implementation evidence. Module READMEs describe the existing implementation.

The [alternate mode plans](modes/README.md) extend selected systems into separate
engram and zombie campaigns. This document's V-specific humanity policy applies to
the original overhaul; the non-V zombie protagonist has a distinct humanity model.

## 1. Intended experience

Combat should be difficult, visibly dangerous, and plausible within Cyberpunk's
fiction. Preparation, information, training, equipment and tactical decisions
should explain success. V should grow into an exceptional mercenary whose own
weapons and software can become future iconics.

V and NPCs follow the same causal rules, with different training, resources,
hardware and circumstances. Shared rules do not require identical software
implementations or identical loadouts. V's unusual augmentation tolerance is an
intentional exception in capability, not permission for unexplained effects.

No-cyberware play should be very hard and restrictive. Its difficulty should emerge
from missing capabilities rather than an arbitrary failure condition. External
armor, reconnaissance and preparation remain useful. Fewer exposed implants may
legitimately reduce vulnerability to certain hacks.

## 2. Decisions and proposal status

### Explicit user direction

- Keep level scaling.
- Skills should represent learned abilities; redesign the perk-to-shard translation.
- Remove effects with no credible mechanism, such as neutralization resetting a
  healing cooldown. Reconsider hierarchical shard dependencies.
- Redesign skill progression rewards and balance attribute-to-skill mapping.
- Increase cyberware variety and slots, using Cyberware-EX integration where useful.
- Give enemies appropriate cyberware and the ability to use it effectively.
- Build detailed weapon crafting so V can develop signature weapons.
- Make netrunning substantially deeper, with network access and diverse custom hacks.
- Make enemy netrunners dangerous enough to demand ongoing attention.
- Improve enemy decisions, with differences reflecting their roles and capabilities.
- Make armor consequential for V and enemies.
- Add reconnaissance: cameras, drones, and potentially a Flathead-like tool.
- Gate tactical HUD information behind equipment and acquired information. A camera
  feed can reveal enemies that camera sees; the map must not reveal everyone.
- Do not make humanity/cyberpsychosis management a player requirement. V's engram
  and unusual tolerance support the chosen design premise.

### Proposed defaults from the discussion; numbers and exact rules remain open

- Healing takes time and consumes supplies; significant injuries persist until
  treated. The user raised persistent limb injuries as a question, not a finalized
  severity/treatment specification.
- Scale within faction, role and location bounds; prefer justified equipment and
  proficiency improvements over large unexplained health increases.
- Keep compatibility level, skill rank and actual combat capability distinct.
- Freeze an encounter's selected strength during that encounter.
- Make observations expire into last-known positions when a sensor loses contact.
- Let physical compatibility, power/heat and cost constrain cyberware where they
  produce meaningful choices; do not automatically add every proposed meter.
- Scope network access by subsystem and permission, and allow defenders to revoke it.
- Require hostile netrunners to establish access to V; aggro alone is insufficient.
- Model grenade supplies and friendly-fire decisions before relaxing concurrency.
- Add suppression, morale, communication and bounded reinforcement consequences.
- Use one representative encounter to validate interactions before broad expansion.

## 3. Ability classification

Every ability must declare its mechanism, prerequisites, cost, failure conditions,
observable feedback, and counterplay. Classify it before assigning its reward source.

| Source | Appropriate benefits | Design constraint |
| --- | --- | --- |
| Learned skill | Handling, technique, precision, tactical execution | Practice improves execution; it does not manufacture energy or medicine |
| Training shard | Instruction and a route to mastering a technique | Downloading instructions and mastering them are distinct; training rules need redesign |
| Cyberware | Superhuman movement, sensing, interfaces, medical automation | Hardware provides the function and must carry any relevant resource cost |
| Software | Exploits, control logic, analysis and deception | Requires a reachable compatible target and adequate permissions/resources |
| Consumable | Medicine, ammunition, grenades, temporary chemical enhancement | Finite supply and a credible delivery mechanism |

Moving an unexplained kill-trigger bonus into a cyberware description does not
automatically justify it. Audit the underlying cause and resource flow.

## 4. The eleven primary systems

| System | Direction | Current home / intended ownership |
| --- | --- | --- |
| Attributes | Derived from skills; retain dialogue and requirement compatibility | SDP-Skills |
| Perks and perk points | Audit each effect; retain, rewrite, relocate or remove; migrate existing saves deliberately | SDP-Perks |
| Skills and rewards | Practice-driven mastery; plausible milestones; avoid forcing unrelated training for specialization | SDP-Skills with SDP-Perks integration |
| Player cyberware | More meaningful combinations and slots; exceptional V tolerance | Shared hardware definitions; SDP-Patches integration |
| Guns and crafting | Build identity through components, handling, ammunition and tradeoffs | New weapon-crafting scope; combat consumes its effective stats |
| Enemy cyberware | Faction/role loadouts with actual activation policies and counters | SDP-Combat and shared hardware catalog |
| Enemy netrunners | Stock-program users, trained specialists and rare expert defenders | Shared network policy with dedicated NPC execution adapters |
| Enemy AI | Perceive, communicate, decide and execute according to available information | SDP-Combat; preserve authored quest control |
| Armor | Coverage, penetration, integrity and meaningful protection | SDP-Combat; integrate injuries and healing |
| Quickhacks | Broad toolset and custom programs with access, resource and compatibility constraints | SDP-QuickhackCrafting plus network policy |
| Reconnaissance | Cameras, sensors, observation and potentially drones | Shared observation model feeding HUD and network discovery |

These are domains, not a commitment to eleven separately deployed mods.

## 5. Scaling and progression

Faction, role and encounter purpose define allowed capabilities. Player progression
can adjust challenge within those bounds. A later-game ganger remains dangerous,
but durability and specialist abilities should have identifiable causes.

Do not treat the current displayed Skill Rank of up to 296 as a native enemy level.
The existing implementation separately derives Level and PowerLevel; audit their
consumers before changing either. Broadening a weak skill should not produce a
disproportionate increase in opposition relative to the capability gained.

The earlier world-progression backlog favored stronger separation from player
level. Where that conflicts with this document, the explicit decision to retain
level scaling takes precedence. Bounded scaling details are still a proposal.

## 6. Information and reconnaissance

| Source | Information supplied |
| --- | --- |
| Navigation/map hardware | Geography, routes and stored observations |
| Direct observation/manual tag | Identity if known and observed position |
| Compromised camera | Targets actually visible through an authorized camera feed |
| Drone/specialized optics | Detections supported by that device's sensors |
| Personnel-network access | Only identities/telemetry exposed by acquired permissions |
| Tracking exploit | Continuing tracking while its prerequisites remain satisfied |

Each contact needs a source, timestamp, confidence and access requirement. Loss of
visibility changes a live contact to a last-known location. A manual tag alone must
not grant permanent tracking through walls. Enemy information should have equivalent
limits, with explicit sharing through comms or security systems.

A navigation implant does not necessarily prohibit an external map. Accessibility
and mission-navigation needs should be evaluated separately from tactical reveals.

## 7. Damage, injuries, healing and armor

Proposed sequence: hit location and coverage -> penetration/protection -> resulting
damage -> severity-qualified injury -> stabilization -> recovery -> definitive treatment.

- Stabilization stops immediate deterioration.
- Health recovery occurs over time with appropriate medicine or hardware.
- Treatment removes the underlying injury and its lasting penalty.
- Significant biological injuries and damaged cybernetic limbs can require different
  supplies. Do not inflict a lasting injury on every minor hit.
- Field treatment must be practical; severe injuries can justify specialist care.
- Medical cyberware may automate treatment, control bleeding or compensate for an
  impairment, with explicit limits and resources.
- NPC injuries must affect their capabilities and decisions if the corresponding
  state can be implemented reliably.

The current mod already contains armor-piece and NPC limb-reaction work. Audit and
extend it rather than assuming persistent injuries or player treatment already exist.

## 8. Netrunning

Proposed lifecycle: discover -> establish route -> obtain scoped access -> execute
against defenses -> maintain/lose access -> respond to tracing or counter-intrusion.

Camera access, personnel access and turret control are different permissions.
V is not automatically enrolled in an enemy network. Defenders must find a valid
route to exposed player systems too. Physical connections, compromised endpoints
and supported wireless attacks provide distinct entry methods.

Keep RAM, upload time, detection/trace and defensive ICE separate. Define how
multiple uploads and repeated effects interact; four Overheats must not acquire
unexamined multiplicative damage simply because four NPCs entered combat.

Common stock-program users can be numerous, with limited scope and resources.
Expert runners should win through positioning, access, defense, routing, custom
software and coordinated support. Writing every program oneself is not the sole
definition of expertise.

The Better Netrunning reference already distinguishes root, personnel, surveillance
and defense systems. Improvement must add meaningful interactions and enemy parity,
not reduce its existing design to one universal unlock.

## 9. AI, logistics and counterplay

Enemies should act from sightings, sounds, shared reports and established network
information. Different roles produce different decisions: covering an ally, flanking,
denying an exit, healing, falling back, protecting a runner or calling backup.

Grenades require supply, a valid throw, and tolerable risk to allies. Ammunition,
healing resources and reinforcement availability should follow explicit budgets.
Removing an engine ticket limit alone is not a complete replacement policy.

Create consistent interaction rules for smoke/sensors, EMP/shielding, penetration/
armor, suppression/cover, jamming/comms and hacking/network isolation. Do not assume
one counter disables every piece of equipment in its category.

NPC skill and equipment must also be legible: behavior, animations, visible armor,
sensor feedback and interruptible preparation communicate the threat.

## 10. Supporting systems

- Economy: shared prices, supply and salvage rules for weapons, medicine, cyberware,
  ammunition and programs; prevent one crafting loop trivializing the others.
- Consequences: police, faction heat and reinforcements; one dispatch owner and
  bounded escalation. Detailed notoriety simulation remains later scope.
- Persistence: versioned saves, migration, cleanup and predictable reload behavior.
- Compatibility: one owner per contested hook/stat, explicit integration with ENC,
  Cyberware-EX and other installed systems.
- Diagnostics: explain damage, protection, action selection, failed access, resources
  and observed contacts; collect baseline and modified runs separately.

## 11. Delivery order and acceptance

1. Research the native architecture and current overrides; build an evidence map.
2. Audit ability provenance and settle the initial shared rules and test builds.
3. Validate one combat encounter with armor, injuries/healing, finite grenades and
   differentiated enemy decisions. Include low-chrome and augmented reference builds.
4. Extend that encounter with cameras, scoped network access and one defending runner.
   Both sides must have observable access failures and interruption opportunities.
5. Expand cyberware and enemy roles only after the combined encounter is convincing.
6. Redesign progression, shards and crafting against demonstrated capabilities.
7. Expand factions/missions and calibrate scaling, economy and compatibility.

Current quickhack recreations remain reference behavior and reusable building blocks.
Do not expand the catalog indefinitely before testing the complete combat/network loop.
Prototype basic HUD feedback alongside the network so the player can understand it;
full drone control is a separate feasibility milestone.

## 12. Source and lore boundaries

- [Pondsmith on V and cyberpsychosis](https://www.reddit.com/r/LowSodiumCyberpunk/comments/xklzsx/comment/ipffmf4/):
  Johnny is described as probably providing a psychological buffer. Absolute immunity
  is not established by that statement. Omitting player cyberpsychosis is our design choice.
- [Better Netrunning](https://www.nexusmods.com/cyberpunk2077/mods/2302): external design
  reference; compatibility and exact implementation must be inspected separately.
- Engineering budgets, access rules and treatment behavior in this document are
  proposed game mechanics, not automatically canonical lore facts.

Open specifications include scaling curves, injury thresholds/treatment duration,
cyberware budgets, shard roster/dependencies, hack stacking, access persistence,
wireless entry rules and how much drone control the engine can support.
