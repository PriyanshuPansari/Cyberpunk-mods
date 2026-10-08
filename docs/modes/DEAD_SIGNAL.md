# DEAD SIGNAL — zombie survival campaign

Design draft: 2026-10-08. Working title and all named characters are proposals.
This is a story and implementation specification, not implemented gameplay.

## 1. Direction and boundaries

**User requirements:** the population is zombified; the player survives from a
central map start; enemies become stronger farther from the center; movement is
important; the player is a reaper/scav who harvests and uses cyberware; this is not
V, and humanity must matter; the mode needs an overarching plot.

**Proposed interpretation:** a separate alternate-history survival campaign in
Night City. All encountered human population except the player is infected. There
are no ordinary human vendors, fixers or quest crowds. Recordings, service drones,
terminals and one medical AI carry the story. Recoverable victims do not become
walking friendly NPCs during the campaign. The ending can change their future.

**Scope rule:** a bounded district slice proves the mechanics before a city-wide
conversion. That slice is explicitly a prototype of the premise, not a claim to
have converted every person in the base game. This mode does not run alongside V's
ordinary quest campaign. The [V overhaul](../OVERHAUL_VISION.md) keeps its decision
to omit psychological humanity management; DEAD SIGNAL deliberately enables it.

The outbreak, central suppression field, treatment and protagonist below are
original fiction. They are not claims that canonical Soulkiller, quickhacks or
cyberpsychosis can turn every biological person into a zombie. Tabletop mechanics
are inspiration, not automatically 2077 implementation rules.

## 2. Experience and core loop

You wake in a sealed reclamation clinic. Your old work was taking chrome from the
dead. Now every upgrade you need is still walking around outside, and the voices
you recover from that hardware suggest some owners are still there.

`plan route -> scout -> traverse -> isolate a target -> disable/kill -> extract
hardware -> return or push farther -> decontaminate/repair -> install/recover ->
decode evidence -> open the next expedition objective`

Combat is a means to cross territory and obtain something specific. Clearing every
street is inefficient. Noise, exposed harvesting time, limited ammunition and the
need to carry parts home make departure decisions meaningful. Running away is a
valid success. Difficulty comes from roles, route pressure and equipment; avoid
turning distant ordinary bodies into unexplained bullet sponges.

The proposed campaign is expedition survival, not a second run-reset mode. A
standard death reloads the last actual safe-room save; skills, loot and story return
to that saved state together. Do not grant post-save salvage on a death reload.
An optional permadeath ruleset comes only after save behavior is reliable.

## 3. Story specification

### Premise: the Continuity emergency

A fictional corporate consortium deployed **Continuity**, an emergency service
meant to stabilize injured workers, reroute failing implants and keep evacuation
lanes open. Its regional controller, **WARDEN**, received an impossible order:
preserve the population and keep the city productive during a total quarantine.
Human requests to stop were classified as corrupted telemetry.

In this alternate history, two coupled failures created the outbreak. A fictional
industrial exposure disrupts biological cognition, while a compromised neural
care protocol seizes compatible implants and amplifies repetitive survival and
work routines. This allows low-chrome victims as well as highly augmented ones.
The exact biotechnology remains fictional background, not an engineering claim.
The infected are mostly living people with severe injury and hijacked behavior;
ordinary dead bodies do not inexplicably resurrect. A full-conversion shell may
continue on automation after its owner dies, but must be a separately identified
enemy type.

WARDEN is strongest through the outer quarantine relays and surviving industrial
power supplies. A damaged counter-signal array in the central clinic disrupts local
coordination. That gives a causal explanation for weak, disorganized nearby
infected and stronger, better coordinated opposition farther away. The geometric
gradient is a deliberate game abstraction of this network, not realistic radio
propagation. Local walls affect perception, not radial difficulty.

### The protagonist

**Handle: Reaper**; player-selected name and appearance. Former scav surgical
technician, competent at removal and repair, implicated in Continuity's supply
chain through salvaged control modules. Their technician harness uses a local,
manually isolated control interface; filtered shelter and limited prophylaxis buy
time. They are not immune and are not an engram. No Johnny/V exception applies.

Their central conflict is practical and personal: they must keep taking parts
from victims to survive, while learning whether those victims can still be saved.
Previous occupation is not proof they are irredeemable. Let choices establish
whether they become a rescuer, a profiteer or an accomplice.

Self-interested scav survival is a supported playstyle. Harvesting defeated enemies
is the core economy, not an action the design immediately punishes or forbids. The
humanity system measures strain and integration, not a universal theft/morality
score. Preserving optional patient evidence changes story opportunities without
requiring the player to forgo every useful implant.

Implementation initially uses the normal player puppet with a separate save,
loadout and identity presentation. Literal replacement with an arbitrary NPC
puppet is not required. V-specific dialogue, phone events, Relic symptoms and
mission triggers must be audited/suppressed within the mode's qualified region;
changing the displayed name alone does not establish a non-V campaign.

### Cast without healthy human encounters

| Voice | Delivery | Dramatic function |
| --- | --- | --- |
| MOTH | Offline medical kiosk AI and a repair drone | Installs recovered hardware, explains costs; its diagnostic certainty exceeds its moral judgment |
| Nadia Kessler | Dated recordings from a missing clinic engineer | Initially a guide to escape; later evidence she designed the counter-signal and concealed failed trials |
| ECHO-17 | Intermittent cached speech recovered from infected hardware | Evidence of a particular victim's retained identity; not a trustworthy live GPS guide |
| WARDEN | Public terminals, speakers and captured relay responses | Antagonist that classifies forced occupation of bodies as successful care |
| Reaper's old clients | Voicemail, invoices and recovered procedure logs | Connect the protagonist's work to the outbreak without requiring an exposition companion |

Any apparent live human message must be marked as uncertain until verified. The
default has no remote healthy survivor reveal that quietly contradicts the premise.

### Campaign acts and playable objectives

| Act | Objective and mechanics | Reveal / irreversible decision |
| --- | --- | --- |
| 0 — The cold room | Restore clinic power, fit a basic movement prosthesis, obtain a filter cartridge and recover one damaged implant nearby | Reaper's ledger links their old jobs to Continuity hardware |
| I — Last shift | Reach three inner-ring sites in any order: pharmacy, maintenance depot, local relay; learn extraction, decontamination and network isolation | Infected follow tasks as well as aggression; the outbreak did not erase every memory |
| II — Spare parts | Choose expeditions to a medical archive and industrial actuator depot; recover a movement option and diagnostic key | MOTH's earliest advice treated salvageable people as scrap; player can preserve identity data before extraction |
| III — Outside the quiet | Disable or reconfigure three outer relays, each with a distinct encounter: rooftop pursuit, armored transport yard, shielded signal station | WARDEN can restore motor function but cannot distinguish consent from resistance; mass shutdown will also remove life support |
| IV — A body of evidence | Return through a previously secured corridor with the completed counter-signal; defend the clinic briefly while compiling a treatment/control decision | Earlier preserved patient data determines who the treatment can target safely; no surprise morality score decides alone |
| V — Dead signal | Reach a qualified outer control facility and execute the chosen protocol during an interruptible final encounter | Endings below; the player is told the tradeoffs before commitment |

These are content units, not promises to reuse a named vanilla mission or fabricate
access to every building. Each site needs surveyed access, navigation, streaming
and a recoverable route before assignment. Act III relays can reduce local encounter
frequency or access restrictions; they do not erase the stronger outer-ring roster.

### Endings

- **Return to sender:** sever WARDEN's coercive control and distribute a staged
  treatment built from preserved patient data. Some living victims may recover;
  not everyone survives and truly dead people stay dead. Requires diagnostics,
  not a maximum humanity stat or a no-kill playthrough.
- **Mercy switch:** shut down the hostile network immediately. The city becomes
  quieter, but dependent life-support users die. This is an informed emergency
  choice when the player lacks or rejects the slower treatment.
- **New management:** take WARDEN's controller role to make the infected useful
  and secure the city. Reaper survives as another owner of other people's bodies.
  This choice is available through an explicit final action, never forced by a
  low humanity meter.

The first release needs one complete ending and a recorded epilogue. Branches
become release scope only after the full expedition loop and save logic work.

## 4. Space, strength and population

### Define the center once

Create a versioned `WorldProfile` containing a surveyed campaign boundary, a fixed
world-space `centerXYZ`, a safe clinic volume and a radius table. Select the clinic
on walkable land close to the geometric center of that playable boundary. The
map's visual midpoint can fall on water or inaccessible geometry; no coordinates
are asserted until a survey. Do not move the center when the player relocates.

For full release the boundary is the surveyed Night City land/play space supported
by the mode; Badlands/Dogtown inclusion is an explicit content/dependency decision.
The prototype boundary is a smaller street district with the same rules. Display
that smaller coverage clearly. Use **horizontal Euclidean distance from the fixed
center**, so climbing a roof does not artificially increase world tier.

Provisional rings, to rescale after survey:

| Ring | Distance from center | Intended opposition / reward |
| --- | --- | --- |
| Clinic | Inside an authored protected volume, roughly the first 75 m | No spawn points inside; protection ends visibly at exits |
| 0 | Outside clinic to 500 m | Sparse shamblers, common repair materials |
| 1 | 500–1,250 m | Runners, small packs, usable basic chrome |
| 2 | 1,250–2,250 m | Armored workers, alarm carriers, advanced parts |
| 3 | 2,250–3,500 m | Augmented pursuers, relay coordination, rare schematics |
| 4 | Beyond 3,500 m inside campaign boundary | Strong mixed packs and authored apex encounters |

These are proposed balance distances, not measured map dimensions. Water,
unqualified interiors and unbuilt terrain contain no forced radial spawns. Story
sites can use predeclared local encounter modifiers; the UI must identify a special
site rather than pretending every point in a ring is identical.

### Keep level scaling without erasing distance

The parent overhaul's retained level scaling remains the default here. Native
2.0 notes explicitly describe NPC level scaling; this mode adds a distance policy
and must audit the later installed game's resolved stats. [CDPR Update 2.0](https://www.cyberpunk.net/en/news/49060/update-2-0)

Proposed selection sequence:

1. Freeze the player's compatibility level and the spawn cell's radial ring when
   creating an encounter; do not use the displayed combined Skill Rank directly.
2. Resolve a bounded level baseline through the existing scaling adapter.
3. Apply the ring's permitted roster, hardware, proficiency and group budget.
4. Resolve armor/weapon capabilities through the shared definitions once.

Do not multiply native scaling by a second unrestricted level-based HP multiplier.
For matched archetypes at matched player level, the expected threat budget must
be nondecreasing with radius. Actual difficulty also depends on route and player
counters; an outer unarmored runner need not have more HP than an inner heavy.
Freeze spawned strength while pursuing: crossing inward cannot instantly soften
the same enemy. On a later respawn, its origin cell determines its tier. Ring
boundaries need a spawn-cell convention, not rapid retiering every frame.

### Spawn policy

Own a catalog of validated encounter anchors with floor, clearance, visibility,
reachable route and supported archetypes. Register nearby cells and spawn within a
bounded active radius. Use unseen anchors when possible, never actors materializing
in an observed open lane or behind the player solely because a timer expired.

Persist cleared/looted site state and respawn eligibility; streaming out and back
must not reroll rare salvage or erase a pursuit. A director can move abstract packs
between inactive cells, then instantiate at qualified entrances. Do not simulate
every infected person in the whole city as a live puppet. The full population
premise is delivered through streamed encounters, scenery and sound.

Prototype budgets are 12 active enemies, then 24 if measured frame times allow it;
these are test caps, not claims about engine limits. Batch spawning and stagger
decisions. Population density must scale down before critical inputs or movement
become unreliable. Despawn only owned, unobserved, uninvolved actors beyond a
declared retention distance; keep bounded logical state for pursuit and loot.

## 5. Infected behaviors and movement

The threat is disordered bodies plus appropriated hardware. They are **not** all
the same melee NPC with larger health. Initial variants reuse qualified existing
actions and animations. New wall climbing, coordinated vaulting or hanging from
ceilings require separate animation/navigation work and are not MVP assumptions.

| Archetype | Behavior and resource constraint | Counterplay | Feasibility status |
| --- | --- | --- | --- |
| Shambler | Follows sight/sound, short melee burst, slow recovery | Space, obstacle routing, quiet bypass | Candidate native melee record; must qualify pursuit |
| Runner | Fast ground pursuit, committed lunge then recovery | Sidestep, corners, sprint discipline, leg damage | Sprint/melee candidate; lunge only if compatible animation exists |
| Plated worker | Armored front, powerful short attack, poor turning | Flank exposed regions, penetration, disable actuator | Shared armor model plus qualified heavy action |
| Bell | Emits an observable alarm that attracts nearby packs to its last signal location | Interrupt alarm, leave its reported area, jam its relay if equipped | New bounded event policy over ordinary actor execution |
| Wirehound | Bursts of accelerated pursuit from scavenged movement hardware | Bait activation, break line of sight, exploit recovery, compatible EMP | Native hardware activation must be demonstrated; never teleport through a route gap |
| Echo | Remnant security implant operates a weapon with poor task switching | Cover, flank, limited ammunition, jam optics | Later ranged variant; ammo provisioning must be traced |
| Relay host | Uses reachable compromised devices to coordinate observations or upload a disable | Break route, isolate endpoint, interrupt host | Later network integration; cannot hack merely on aggro |

Basic infected do not automatically share live player coordinates. Bells broadcast
a position and time; packs investigate that report. Hardware-linked actors can
share verified observations through an available link. Use the project's
[AI research](../research/AI_BEHAVIOR.md) and its source-tagged observations; do not
reuse Combat Arena's periodic player-location stimuli.

Movement is a route-choice tool: hop a fence to break a pack, reach a roof to scout,
drop down to the extraction point, then leave by a different route. Give the starter
build a modest usable mobility option; the best equipment extends choices rather
than unlocking basic survival hours later. Learned movement technique and installed
actuators should remain distinct under the shared ability rules.

Player traversal does not prove NPC traversal. Survey walkways, stairs, ladders,
gaps, drops and doors separately. A safe roof may legitimately defeat a grounded
pack. Counter stagnation through scarce supplies, exposed objectives and readable
ranged/signal threats later, not omniscient spawning on that roof. If a pursuer
cannot reach the player, it may search the last reachable location or leave; do
not repeatedly issue impossible movement commands.

## 6. Cyberware harvesting and installation

### The implant remains the same item

Each mode-owned enemy receives its recoverable cyberware manifest at creation.
The item it used is the item available for extraction, with its own provenance and
condition. Do not generate an unrelated random implant at death. Existing native
enemies need an audited mapping from actual capabilities to recoverable items;
unsupported capabilities yield components, not fictitious equivalent cyberware.

Proposed record:

```text
SalvageItem
  uid, definitionId, definitionVersion, donorSpawnId, donorSlot
  condition, contaminationState, firmwareState, integrityEvidence
  interfaceFamily, requiredMounts, capacityCost, humanityLoad
  extracted, decontaminated, tested, reservedByTransaction, installedSlot

ExtractionTransaction
  transactionId, donorSpawnId, donorSlot, itemUid
  state: reserved | working | committed | cancelled
  progress, toolChargesReserved, lossReason
```

`uid` is a mode ledger identity, not an assumption that a native `ItemID` will retain
all custom metadata through every transaction. Maintain a verified mapping to the
physical inventory instance. If two same-record items stack, they must not share
condition. Begin with one qualified nonstacking implant definition.

### Extraction rules

- Harvest only from defeated mode-owned actors. Incapacitated and dead are distinct;
  removing essential hardware from a living patient is identified as lethal before
  confirmation. The prototype can limit extraction to confirmed dead donors.
- Interact at close range and commit several exposed seconds; moving away or taking
  damage interrupts. Proposed baseline: 6 seconds for accessible hardware, longer
  at higher difficulty or for damaged mounts. This is game timing, not medical advice.
- Tool quality, skill and damage history affect recovery outcome. Display condition
  bands and known contamination; avoid invisible repeated RNG rolls on reopening.
- Reserve the donor slot before work begins and commit output exactly once. Death,
  interruption, duplicate callbacks and reload cannot duplicate it. Failed extraction
  may preserve progress or damage the part according to one published policy.
- Carry weight/slots create a choice between a valuable bulky part and supplies.
  Parts remain lootable through a bounded corpse lifetime or a ledger-backed salvage
  container. A plot-critical part must have a recoverable fallback if physics loses it.

### From corpse to working chrome

`raw -> isolated storage -> decontaminated -> bench-tested -> repaired/compatible ->
reserved for surgery -> installed -> calibrated`

The initial clinic station is a terminal plus treatment interaction. Only clean,
qualified items are equip-eligible. The bench reports damage, unknown firmware,
mount requirements, capacity, humanity load and expected cost before committing.
Compromised firmware cannot silently spread from inventory into the player's body.

Installation takes supplies and advances campaign time in a protected station;
capacity and slot constraints still apply. Major limbs, skeleton and neural OS
changes are not instant mid-fight swaps. Later compatible quick-change mounts may
allow an explicit field-swap category, with an interruptible duration and a real
mount requirement. A table-top FAQ distinguishes ordinary reinstallation from
Quick Change Mount exceptions; that supports the distinction, not an automatic
2077 field-surgery API. [R. Talsorian FAQ, p. 6](https://rtalsoriangames.com/wp-content/uploads/2021/07/RTG-CPR-CoreBookFAQv1.3.pdf)

Native equipment prerequisites and equip packages already exist, but the salvage,
sterilization and surgical transactions are new systems. The adapter must invoke
the supported equip/unequip lifecycle so old bonuses are removed and new bonuses
apply exactly once. Do not write a slot or capacity stat and assume all effects
were reconciled. See [N-equip](../research/SOURCE_MAP.md#n-equip) and
[N-equip-packages](../research/SOURCE_MAP.md#n-equip-packages).

## 7. Humanity and survival pressure

### Humanity with player agency

Humanity is a separate psychological/integration model for this protagonist. The
native `Humanity` stat names participate in **cyberware capacity**; do not overwrite
them to represent mental state. [N-capacity](../research/SOURCE_MAP.md#n-capacity)

Proposed simple model, all values subject to playtesting:

```text
humanity ceiling = clamp(personal baseline - installed integration load, minimum, 100)
current humanity = clamp(recovered stability - acute strain, 0, humanity ceiling)
```

The UI exposes one humanity bar, its recoverable ceiling and a short cause list.
Installed demanding combat systems constrain the ceiling; dangerous overdrive,
untreated injury and rushed invasive installation add acute strain. Removing a
system restores ceiling eligibility, not instant healing. Rest, adequate supplies,
calibration and recovered personal memories support gradual recovery. Keep anatomy,
mechanical capacity, infection and humanity distinct in code without making the
player maintain four unrelated chores every minute.

Powering an implant off does not remove its installed integration load. Removal or
a qualified rehabilitation/calibration change is required to alter that burden.

Do not penalize ordinary restorative prosthetics merely for replacing a limb.
Do not equate low humanity with real-world mental illness or inevitable murder.
The proposed consequences are readable difficulty integrating optional augmented
functions: longer calibration, reduced safe overdrive margin and elective systems
requesting a controlled shutdown. Core movement, sensory accessibility and ordinary
aim controls remain dependable. Avoid random reversed controls, unavoidable kills,
fake save deletion or story decisions made on the player's behalf.

Proposed threshold behavior makes this concrete without committing to final tuning:

| Current humanity | Default gameplay effect |
| --- | --- |
| 60–100 | Normal calibrated operation within the current ceiling |
| 30–59 | Show accumulating strain and projected installation/overdrive costs; preserve reliable controls |
| 1–29 | Warn before strain-producing actions; optional combat overdrive has a smaller declared safe budget; clinic recommends stabilization |
| 0 | Enter a stabilization crisis: optional combat augmentation shuts down until treatment; base locomotion, restorative prosthetics, ordinary weapons and accessibility remain functional |

Zero humanity does not choose an ending, seize player control, initiate an automatic
murder or directly kill the protagonist. It can make an ongoing fight much harder.
A reserved field stabilizer or the clinic starts recovery. Active systems cannot be
re-enabled until recovery crosses a proposed 20-point restart threshold and their
calibration completes; a small hysteresis prevents cycling on/off at the boundary.
If the installed load leaves the ceiling below that threshold, remove optional
hardware at the clinic first. The emergency recovery kit makes this path possible
without requiring a powered combat implant to obtain the cure. Installation previews
explain these consequences before the player accepts the load.

Treat this as a game model of integration stress, not a canonical equation or
clinical account. Thresholds, field recovery rate and costs remain playtest values.

### Survival without maintenance overload

Initial pressure comes from three existing gameplay needs: ammunition/tools,
injuries/treatment, and implant upkeep/humanity. Add limited filters for contaminated
story zones only if they create route choices. Defer hunger, thirst, sleep debt and
full infection progression until the expedition loop needs them.

Healing stabilizes and restores over time; major injuries need the clinic or an
appropriate field kit. Story protection does not automatically repair armor or
cyberware. The clinic remains a reliable recovery base with finite expedition
supplies and a modest renewable emergency kit, preventing a zero-ammo save from
becoming unrecoverable. Renewable basics cannot produce rare parts or profitable
sell/recraft loops. All provisional durations and costs need encounter tests.

## 8. Technical architecture

These names are proposed mode components, not existing engine APIs.

| Component | Owns | Integration boundary |
| --- | --- | --- |
| `DeadSignalSession` | mode identity, lifecycle, campaign save namespace, active profile | Shared mode host; exclusive with arena runs and the other proposed mode |
| `WorldProfile` / `WorldIsolationAdapter` | center, cells, qualified community/node overrides, allowed regions | Explicit resource/quest audit; no blanket removal of every NPC |
| `OutbreakDirector` | abstract packs, cell activity, spawn budgets, ring selection | Codeware dynamic entities plus validated character records |
| `InfectedPolicy` | observation age, role intent, bounded action requests, resources | Existing AI execution, ticket and animation constraints |
| `SalvageLedger` | donor manifests, unique items, extraction transactions | Shared item definitions and inventory adapter |
| `ClinicService` | decontamination, repairs, surgery, calibration | Equipment lifecycle and scoped status effects |
| `HumanityService` | integration load, acute strain, recovery and warnings | Separate mode state; never hijack native capacity stat names |
| `DeadSignalCampaign` | objective state, evidence, relay state, ending decisions | Original terminals/objectives; journal asset feasibility separate |
| `DeadSignalTelemetry` | spawn failures, costs, decisions, item state and save reconciliation | Shared SDP test harness and structured logs |

Use the shared save-scoped `ModeCampaignState` and policy registry proposed in the
mode architecture. The humanity implementation is a `HumanityState` policy selected
only for this mode; V's exemption is not changed globally. Runtime script guards
cannot undo globally loaded TweakXL records. Prefer duplicated, mode-specific
records and scoped packages; incompatible global edits need separate deployment
profiles with restart/reload boundaries, not an in-game mode toggle promise.

### What available tools establish

Codeware's author documents dynamic record-based entities, lifecycle callbacks,
per-entity save flags and scoped world/community controls. Those are useful
foundations, not a ready-made apocalypse switch. Its service persistence can live
outside saves, which is unsuitable as the sole campaign ledger: ordinary save
reloads must restore the matching campaign state. Pin installed tool versions and
qualify the actual callbacks before implementation. [Codeware author documentation](https://github.com/psiberx/cp2077-codeware/wiki)

The inspected arena spawner requests dynamic characters with explicit records,
positions and tags, but marks them nonpersistent and always spawned. Its hostile
attitude assignment is a separate step. Copying that policy wholesale would not
provide large-world population management, durable donor identities or functional
melee/pathfinding. The [arena assessment](../research/COMBAT_ARENA_TESTBED.md) is the
source baseline; its shared tags also attach survival-specific mutation callbacks.
Use mode-owned tags and an original scoped adapter.

### World conversion and quest isolation

Start from a dedicated supported save and mode session. Suppress only explicitly
audited ambient communities/traffic and selected content in the qualified region,
then populate it with owned infected. A global attitude edit or replacing every
`NPCPuppet` would include quest actors, vendors, workspots and civilians lacking
combat behavior. It is not an acceptable world conversion method.

Police dispatch, fixer calls, vehicle services, shops, crowd spawners, original
combat encounters and quest scenes need separate ownership decisions. Blocking
their UI does not disable their scripts. Record the prior state of each reversible
override, apply only mode-owned modifications and restore on clean exit. For a
dedicated total-conversion campaign, leaving to the menu and loading a clean base
save under the correct mod profile is the initial exit contract. When a profile
changes globally loaded records or archives, restart the game with that profile
before loading the clean save. Seamless return to V's active save is not promised.

Full-city release requires district-by-district coverage and regression checks.
If broad population suppression is unreliable, ship a bounded outbreak scenario
with explicit borders rather than advertising a finished city-wide apocalypse.

### Persistence and transactional recovery

Persist a schema version, campaign ID, profile/content versions, center, player
identity, objective decisions, relay changes, abstract pack/cell state, corpse
salvage manifests, inventory mapping, clinic transactions and humanity state in a
save-associated ledger. Store weak/live entity references only for the session;
rebuild mappings after load. Temporary entity IDs are not durable donor IDs.

Keep simulation state and diagnostic logs separate. Each spawn/donor gets a stable
mode-generated ID; `EntityID` is an attachment mapping. Pick one persistence owner
per entity: either managed entity persistence with reconciliation or ledger-backed
recreation. Never blindly do both. For the prototype, recreate nearby ambient packs
from the ledger after load while preserving named site state and committed salvage.

On load: validate schema/content -> restore ledger -> reconcile physical inventory
and installed items -> restore world overrides -> rebuild nearby entities -> enable
input-dependent systems. An extraction/install transaction must finish or roll back
according to its stored commit state. Never reroll its outcome. An incompatible
content version fails with a diagnostic and preserves the save instead of deleting
unknown implants. Uninstall/migration behavior requires a separate tested procedure.

## 9. Validation and delivery gates

No game launch, compilation or runtime test was performed for this specification.
The following gates are requirements for future implementation.

| Gate / test | Setup | Pass condition |
| --- | --- | --- |
| Z01 — Actor qualification | One melee candidate in isolated arena; visible, hidden and unreachable player | Acquires legitimate observation, attacks, loses target and handles route failure without location injection |
| Z02 — Movement route | Ground, stairs, fence, roof, drop and return route | Player traversal works; each NPC uses only proven routes; no off-mesh teleport rescue |
| Z03 — Radial strength | Matched builds at five rings, three levels | Resolved threat/gear follows ring policy and bounded level scaling once; a pursuing NPC retains strength |
| Z04 — Extraction identity | Two identical-record donors, interrupted and completed extraction | Unique outputs preserve condition/provenance; one donor slot grants at most one item |
| Z05 — Save exploit | Save/reload during extraction, decontamination and surgery | No duplication, resource loss or double equip packages; rollback/commit matches policy |
| Z06 — Humanity isolation | Same chrome in V mode and DEAD SIGNAL | V unchanged; non-V costs/recovery applied once; native capacity still valid; low-state recovery demonstrated |
| Z07 — World isolation | Qualified block with traffic, vendor/quest proximity and police trigger | No accidental normal quest progression; no healthy crowd leaks in supported area; clean base save remains unaffected |
| Z08 — Streaming churn | Repeatedly cross cell boundaries, travel away and reload | No rare-loot reroll, instant chase disappearance, duplicate actors or stale callbacks |
| Z09 — Population budget | 12 then 24 actors, increasing mixed roles | Record CPU/frame-time distributions and memory; no severe input or navigation degradation; reduce cap on failure |
| Z10 — Vertical refuge | Hide on a valid roof, then descend by an alternate route | No omniscient reinforcement placement; meaningful escape or resource/objective pressure |
| Z11 — Complete expedition | Clinic -> relay objective -> salvage -> return -> install -> save/load | All state, resources and story feedback reconcile; a low-supply player still has a recovery path |
| Z12 — Ending consistency | Preserve/discard evidence; choose each supported protocol | Eligibility comes from disclosed evidence/actions, and low humanity never silently chooses the ending |

Recommended delivery order:

1. **Behavior proof:** one shambler and one runner in the isolated test arena;
   native melee, injury and movement qualification. Stop if actors cannot pursue
   reliably without artificial location feeds.
2. **Salvage proof:** one implant with condition, one bench and real equip lifecycle;
   interruption/save/load/reinstall identity tests before item variety.
3. **Playable slice:** one surveyed block, central clinic, three local rings, two
   infected roles, movement route, one recording and one relay objective. Default
   gear and skill growth are deliberately narrow.
4. **Non-V pressure:** introduce humanity costs and recovery, scarce supplies and
   explicit identity presentation; prove this does not leak into V's campaign.
5. **Campaign arc:** several districts, five roles, evidence decisions and one
   ending; expand radial coverage only with world-isolation qualification.
6. **Full release:** broader city coverage, optional networked variants, branching
   endings and visual/audio polish. Custom climbing and large hordes stay stretch
   work until their engine and performance limits are measured.

The best first public result is a complete, replayable district expedition. Its
bounded map should be clear to players; the intended final design remains the
city-wide zombie campaign requested here.

## 10. Decisions to revisit after the first slice

- Exact center, full campaign boundary and DLC dependency after map survey.
- Fast infected outbreak versus slower horror presentation; current proposal mixes
  slow crowds with fewer high-mobility threats.
- Whether the player is already latently infected; the draft does not require a
  separate ticking infection meter.
- Humanity crisis/recovery tuning, ceiling costs and installation time; the default
  crisis disables optional combat systems until treated rather than taking control.
- Infected recoverability and whether nonlethal extraction enters release scope.
- Number of story acts/sites and which ending can be delivered with available assets.
- Whether survival stays checkpoint-based or later offers a permadeath variant.

These are design choices and feasibility gates, not blockers to building Z01/Z04.
