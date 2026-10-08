# Engine feasibility and shared foundations for alternate game modes

Research date: 2026-10-08. This is an implementation proposal supported by inspected
source and tool-author documentation. No mode code, archive resources, saves or
game configuration were changed, and no gameplay spike was run.

The two modes should share tooling and combat adapters, while keeping separate
campaign state, progression policy and world directors. Their first playable
versions should retain the normal player puppet, use qualified fixed locations,
and spawn a bounded number of owned actors. Arbitrary NPC possession, moving
complete navigable buildings and universal city conversion remain separate
research tasks, not dependencies of the first playable version.

## 1. Evidence and compatibility boundary

**SOURCE** means an inspected implementation or exposed declaration. **DOC** means
tool-author documentation. **PROPOSAL** means our intended implementation.
**RUNTIME UNKNOWN** means the behavior has not been demonstrated on this setup.

- The existing [source inventory](../research/SOURCE_MAP.md) fingerprints the
  decompiled game snapshot and SDP sources. It is not a fresh extraction for this
  proposal. The prior audit identified the installed executable as 2.31.
- The [installed Codeware log][L10] dated 2026-10-08 02:51 records initialization of
  **Codeware 1.20.5**. Its installed declarations include the APIs cited below.
  This proves recent initialization, not compatibility of either proposed mode.
- The [Codeware author README](https://github.com/psiberx/cp2077-codeware) lists
  game 2.31 compatibility; its wiki header identifies an older documentation
  version. The [TweakXL README](https://github.com/psiberx/cp2077-tweak-xl) currently
  lists 2.3, so its README alone must not be used to certify the complete local
  dependency stack. Record actual plugin/compiler logs when running the spikes.
- Combat Arena's installed files were audited in the
  [testbed assessment](../research/COMBAT_ARENA_TESTBED.md). Its location, archive
  navigation and dependency state still require a live qualification session.

## 2. Foundations we can reasonably build on

| Foundation | Evidence | Architectural use and limit |
| --- | --- | --- |
| Script hooks and custom state | redscript compiles gameplay scripts; SDP already stores persistent fields on player development and quickhack data | Mode state, progression adapters and event handling. A compiler success does not prove lifecycle correctness. [D1], [L1] |
| Character spawning | Installed `DynamicEntitySpec` exposes record, transform, appearance, tags and persistence options; `DynamicEntitySystem` exposes readiness, lookup and deletion | Own the spawns, confirm actual attachment and functional AI. A requested entity ID is not a ready combatant. [L2] |
| Entity lifecycle | Author documentation describes session and entity callbacks | Register once, detach correctly, invalidate delayed work by generation. Never retain game-object references across sessions. [D2] |
| Scoped records | TweakXL supports declarative record edits and scripted changes | Clone mode-specific actor/action/item records. Avoid globally turning all base characters into zombies. [D3] |
| Static scene content | Installed static entity APIs and world-state node/variant controls | Authored doors, props and scene variants. These APIs do not establish runtime navigation generation. [L3], [L4] |
| Resource authoring | ArchiveXL expands resources; WolvenKit edits/packages game assets | New visual identities, weapon assets and room dressing. Collision, navigation, cover, animations and streaming need separate qualification. [D4], [D5] |
| Equipment changes | Native queued equip/unequip paths; existing SDP Chrome refresh after equipment requests | Swap a curated body loadout through native equipment ownership. Validate that all effects finish updating. [L5], [L6] |
| Remote control | Native `LocalPlayerControlExistingObject`; an inspected camera class uses it | A real control handoff exists. It is not evidence that arbitrary NPCs have the player's movement, inventory or saving behavior. [L7], [L8] |

## 3. Player identity and the body-swap boundary

**Recommended MVP: represent bodies as player-compatible profiles.** Keep the
player's gameplay object and change an explicit loadout, body statistics and
supported visual preset. A profile contains an ID/revision, allowed cyberware
slots, equipped implants, locomotion capabilities, armor/injury state and visual
preset. The engram's learned skill ledger is separate from the body's hardware.

Enemy hardware is not necessarily a directly equippable player item. Define a
curated mapping from each qualified enemy archetype to a playable body profile.
The UI must describe that profile honestly; do not imply every spawned NPC can be
inhabited with its exact skeleton, weapons and behavior.

One native helper, `ForceEquipItemOnPlayer`, explicitly requires `PlayerPuppet`
([L5]). `PlayerSystem.OnLocalPlayerChanged` also changes the HUD's replacer flag
according to the controlled record ([L7]). These are concrete reasons to keep
arbitrary NPC possession experimental. They do not prove it is impossible.

The body-switch transaction should have these proposed stages:

1. Validate the selected defeated actor, its unconsumed claim ID, eligibility
   deadline, profile compatibility and safe landing position.
2. Enter one transition state. Reject duplicate requests and freeze only the
   inputs/time or exposure policy explicitly chosen by the mode design.
3. Record a recovery checkpoint; remove the old profile's owned effects, cancel
   incompatible active cyberware/quickhack tasks and reconcile equipment slots.
4. Apply the new profile using queued equipment operations; wait for resolved
   equipment, stats, movement and visuals to match the expected manifest.
5. Commit the target claim and profile ID once; resume play. On failure restore
   the checkpoint or return to a known safe hub with an explicit recovery result.

Do not assume step 3–5 is an atomic engine operation. Save requests arriving
during a transition must observe a coherent old or new checkpoint. Scope any
temporary save/input restriction narrowly and release it on every error path.

The zombie protagonist can be a different fictional person while still using
`PlayerPuppet` technically. A custom face/body, voice, HUD text, journal, apartments,
phone contacts and V-specific quest behavior are separate content tasks. A new
character name does not remove those dependencies. Start with a self-contained
mode UI and controlled campaign entry, then audit visible V references.

## 4. Rooms, gates and the physical structure

The selected direction is a **physical structure reached through gates**, with
fixed authored combat cells and controlled transitions where engine feasibility
requires them. Room selection and enemy composition can be procedural without
procedurally constructing the room's traversable geometry.

| Approach | Feasibility finding | Decision |
| --- | --- | --- |
| Move complete occupied buildings | Static transforms exist, but no inspected source establishes synchronized moving collision, navmesh, cover, occlusion, streaming and attached AI | Research only; do not promise seamless moving buildings |
| Fixed authored cells with gate transitions | Teleportation and actor spawning exist in the arena source; each destination still needs loaded floor, camera and navigation checks | Recommended first implementation |
| Reuse qualified existing spaces | Cuts asset work and reuses authored traversal | Prototype only after excluding quest triggers and validating reset; not every existing interior is independent |
| Dedicated custom sectors/cells | Asset tools support world edits; custom navigation and streaming remain work | Later production location after one cell passes qualification |
| Moving skyline/room-shell visuals | A cosmetic layer can communicate reconfiguration without moving combat floors | Optional later effect; still test collision and visibility |

Represent a run as a seeded directed room graph referencing a finite catalog.
Each catalog entry declares its anchor, bounds, allowed entrances/exits, spawn
points, traversal requirements, cover checks and escape/reset positions. A gate
transition closes the old encounter, releases its actors and callbacks, chooses
the next catalog entry, verifies destination readiness, moves the player, then
starts the next encounter. A fixed delay alone is not proof streaming is ready.

If no reliable world-ready signal can be established, use validated destination
probes with a bounded timeout and a safe hub fallback. Never release the player
over unloaded geometry. Native AI/physics are not made deterministic merely by
seeding our room and roster choices.

## 5. City population, zombie AI and movement

"Everyone is a zombie" is the intended world presentation. Implement it with a
qualified population replacement policy and a bounded local simulation, not a
simultaneously active zombie for every resident across the whole map.

The installed `WorldStateSystem` exposes controls for named communities and
population spawners ([L4]). This is a useful starting point for suppressing
ordinary population in owned zones; it is not a global quest-safe switch for
traffic, police, vendors, gigs and scene actors. Initially qualify one district
slice, enumerate the affected sources, and allow only tested overrides. Use a
separate playthrough/mod profile for the conversion.

Proposed population director:

- Divide the playable region into authored cells with validated ground and
  rooftop spawn points. Keep compact population/loot/site ledgers for unloaded
  cells; materialize only nearby actors under a measured budget.
- Use separate spawn and despawn distances with hysteresis. Avoid visible
  materialization, invalid floors, sealed spaces and untested quest interiors.
  Chase actors must not vanish while visible or attacking.
- Keep far-away progression as abstract cell state. Temporary entity IDs cannot
  identify long-lived salvage claims after a reload; persist stable mode IDs.
- Set difficulty from distance to the starting anchor, with explicit district,
  story and level-scaling adjustments. Snapshot an enemy's resolved tier on
  creation; do not repeatedly buff/debuff it as it crosses a radius boundary.
- Treat the radius as a transparent difficulty rule, while qualifying actual
  land routes. A geometric center can fall in water or inaccessible space; use
  a surveyed central spawn anchor, then declare the usable play bounds.

An actor with a hostile attitude is not automatically an effective zombie.
Create a small, qualified set of melee/rush archetypes first. Observe target
acquisition, lost-target search, melee reach, path failures, hit reactions and
crowd congestion. Noise and last observation should drive pursuit; the arena's
repeated injection of the player's live position must not become the default
survival AI ([L9]).

Player movement must be tested alongside enemy routes. Double jumps and dashes
can expose roofs no native melee actor can reach. Resolve this with authored
approach routes, climbing-capable archetypes only where demonstrated, and
telegraphed ranged/area threats. Do not promise universal infected parkour or
silently teleport enemies behind the player. Repeated-route tests should cover
stairs, narrow doors, fences, drops, vehicles and vertical escape points.

## 6. Cyberware salvage, humanity and generated weapons

**Salvage:** map a defeated actor's declared hardware to a harvest claim. Mark a
claim consumed exactly once, even if harvesting is interrupted or the corpse
streams out. Store model, quality, condition, contamination and ownership in a
mode ledger; item creation is an output of that transaction. Installation then
validates the player body's slot, capacity, dependencies and required treatment.
Use native items initially; arbitrary combinations of procedural item stats need
the existing [weapon persistence qualification](../research/VALIDATION_BACKLOG.md).

**Humanity:** this mode needs its own persistent psychological/identity state
because its protagonist is not V. Do not repurpose or erase native `Humanity`
stats blindly: the prior source audit found that name in cyberware-capacity paths.
Keep mechanical load/capacity, psychological stress and infection as distinct
variables, even if the UI presents a compact summary. Effects and recovery must
be mode-owned and reversible; values must not leak into the base overhaul or the
engram mode. This is a proposed fiction/gameplay model, not a clinical simulation.

**Run weapons:** seed a bounded recipe generator over validated weapon chassis,
attachments and modifiers. Persist the recipe and stable item identity; avoid
unbounded creation of shared TweakDB records that could change earlier items or
accumulate across runs. A new weapon each run can initially be a new build using
existing visual parts. Bespoke geometry and animations are a separate asset tier.

## 7. Persistence, quest isolation and restoration

The author docs distinguish save-associated scriptable systems from persistent
services that survive across sessions independently of game saves. Put each
mode's campaign ledger in save-associated state. Use service persistence only
for deliberately account-wide preferences or opt-in meta progression, keyed by
mode and campaign; otherwise loading another save could inherit progress. [D2]

Suggested save records: schema version, mode/campaign ID, seed and generator
revision, run/attempt ID, committed room/cell, body profile, skill ledger, item
recipes, consumed claims, story flags, world override ledger and the last stable
transition checkpoint. Persist data, not live references, callbacks or temporary
entity IDs. Reconstruct runtime controllers after session readiness.

These are logical schemas, not a guarantee that arbitrary strings or object graphs
can be serialized unchanged. The inspected quickhack library encodes names as
integer character codes and stores persistent numeric arrays on player development
data ([L11]); qualify supported field types, round trips and schema migration for
each mode record. Codeware can provide stable IDs for entities with persistent
state; temporary IDs cannot cross sessions. Our separate mode IDs still own claims
and survive deliberate entity recreation.

Engram death should commit the skill gains and end the attempt **within the mode
session**, then initialize another body at the hub. Loading a pre-run save would
also roll back save-scoped meta skills unless a separate commit scheme existed.
Ordinary save/load should resume a committed mode checkpoint. Decide explicitly
whether an interrupted encounter resumes exactly or restarts with its reward
claims preserved; neither policy should permit duplication.

Start both prototypes with a dedicated named manual save and documented mod
profile. The mod must never overwrite a user's existing save to create its entry
point. Menu launch/new-game integration and wholesale quest removal are later
features; no supported automatic isolated save-slot API was qualified here.
Separate saves alone do not isolate global record/archive overrides, so those
must be scoped or enabled only in the mode's mod profile.

Cleanup must restore mode-owned input locks, time scale, immortality, weather,
equipment effects and world toggles; remove only mode-tagged actors; and reject
stale delayed callbacks. Restoration of a normal campaign after a full city
conversion is not promised. Loading the original baseline with the appropriate
mod profile is the initial rollback boundary.

## 8. Shared qualification spikes

All thresholds below are proposed acceptance gates, not reported test results.

| ID | Spike | Pass condition | Failure response |
| --- | --- | --- | --- |
| F01 | Isolated actor lifecycle in a qualified arena space | Twenty spawn/kill/reset cycles; no remaining owned actors, callbacks, tags or external mutations | Fix lifecycle before either director |
| F02 | Three body profiles, including different operating systems/arms/legs | Ten complete cycles; equipment/stats/UI agree, abilities activate correctly, no retained effects or duplicated items | Restrict the profile catalog to supported combinations |
| F03 | Literal NPC possession experiment | Control, camera, movement, weapon use, cyberware, damage, HUD, return control and reload all work for each whitelisted rig | Retain player-profile representation; no release dependency |
| F04 | Two fixed cells and one gate | Twenty transitions including combat abort/load; floor and routes ready before release; no stranded player or old-room AI | Keep the proven room or change the transition scheme |
| F05 | Persistent mode ledger and claim transactions | Death/restart, reload, interrupted swap/harvest and loading another campaign preserve intended progress without duplication or contamination | Remain on dedicated test saves; repair ownership/checkpoints |
| F06 | Population replacement in one street slice | No ordinary residents/police/traffic reappearing from enumerated sources during repeated visits; excluded quests unaffected outside scope | Reduce playable footprint and enumerate missing sources |
| F07 | Horde budget and traversal | Record frame-time distribution, active/queued AI, navigation failures and memory across stepped actor counts and a 30-minute route; no growing population/queue after return | Set caps below the failing level; fix routes before increasing counts |
| F08 | Cyberware harvesting | One claim yields at most one item across corpse destruction, streaming, cancellation and reload; condition/identity survives equip/unequip | Keep salvage as abstract components until identity is reliable |
| F09 | Non-V presentation | No unintended V-specific UI/dialogue or quest triggers in the supported loop; appearance works in first person, inventory and photo mode | Declare remaining presentation limits and restrict story scope |

F01/F02/F04/F05 unlock the engram vertical slice. F01/F05/F06/F07/F08 unlock the
zombie district slice. Both use the existing testbed and combat diagnostics.
Broad city coverage or a larger room catalog follows qualification, not the
other way around. No calendar estimate is defensible before these spikes.

## References

External sources were checked on 2026-10-08. These are tool-author sources; their
capabilities are foundations, not evidence that our proposed modes already work.

[D1]: https://github.com/jac3km4/redscript
[D2]: https://github.com/psiberx/cp2077-codeware/wiki
[D3]: https://github.com/psiberx/cp2077-tweak-xl
[D4]: https://github.com/psiberx/cp2077-archive-xl
[D5]: https://github.com/WolvenKit/WolvenKit
[L1]: ../../SDP-QuickhackCrafting/r6/scripts/SDPQuickhackCrafting/DesignLibrary.reds
[L2]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/red4ext/plugins/Codeware/Scripts/Codeware.Global.reds:43419>
[L3]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/red4ext/plugins/Codeware/Scripts/Codeware.Global.reds:43511>
[L4]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/red4ext/plugins/Codeware/Scripts/Codeware.Global.reds:43617>
[L5]: <C:/Users/incre/Documents/New project/vanilla-decompiled.reds:36949>
[L6]: ../../SDP-Perks/r6/scripts/SkillDrivenProgression/ShardChrome.reds
[L7]: <C:/Users/incre/Documents/New project/vanilla-decompiled.reds:47720>
[L8]: <C:/Users/incre/Documents/New project/vanilla-decompiled.reds:465541>
[L9]: ../research/COMBAT_ARENA_TESTBED.md
[L10]: <C:/Program Files (x86)/Steam/steamapps/common/Cyberpunk 2077/red4ext/plugins/Codeware/Codeware-2026-10-08-02-51-38.log:1>
[L11]: <C:/Users/incre/Documents/New project/SDP-QuickhackCrafting/r6/scripts/SDPQuickhackCrafting/DesignLibrary.reds:169>
