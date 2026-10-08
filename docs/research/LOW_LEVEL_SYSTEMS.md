# Low-level design and implementation research

Scope: static inspection of the source snapshots identified in
[SOURCE_MAP.md](SOURCE_MAP.md). Native behavior, current SDP behavior and proposed
interfaces are explicitly separated. Proposed names below are not existing APIs.

## 1. Implementation layers and what can be established

| Layer | What it owns or exposes | Research / modification route |
| --- | --- | --- |
| TweakDB records | Character/item/action definitions, modifiers, prerequisites, packages and references | Read resolved records; change scoped records with TweakXL or deliberate CET operations |
| redscript | Gameplay orchestration, action subclasses, UI controllers, callbacks | Read decompiled implementations; candidate wrap/replace hooks must compile against the installed bundle |
| Native engine | Many record evaluators, sensing, navigation, animation and stat internals | Use exposed interfaces; trace inputs/outputs where implementations are absent |
| Archive resources | Behavior graphs, animations, entity templates, UI resources | Inspect referenced resources with WolvenKit; records alone do not define every action |
| Mod runtime/save state | Custom ledgers, listeners, caches and session state | Explicit ownership, lifecycle, persistence and migration |

`native`/`importonly` declarations expose a signature rather than an implementation.
For example, `AICondition.ActivationCheck` delegates to the native tweak action
system, and `AIActionTarget.Get` delegates target evaluation. A decompiled wrapper
does not reveal how every subcondition or position provider is evaluated.
[N-ai-condition](SOURCE_MAP.md#n-ai-condition), [N-ai-target](SOURCE_MAP.md#n-ai-target).

Tool author references: [redscript](https://github.com/jac3km4/redscript),
[TweakXL](https://github.com/psiberx/cp2077-tweak-xl),
[Codeware](https://github.com/psiberx/cp2077-codeware),
[WolvenKit](https://github.com/WolvenKit/WolvenKit).

## 2. Progression, perks and skill rewards

### Native path — SOURCE

`PlayerDevelopmentData` owns proficiency XP/levels and purchased perk ranks.
`ProcessProficiencyPassiveBonus` selects the level-indexed passive reward's
`EffectorToTrigger` and applies it through `EffectorSystem`.
`RestoreProficiencyPassiveBonuses` reapplies earned rewards on restoration but
excludes development-point effectors. Replacing reward records must therefore
consider both acquisition and restore paths. [N-rewards](SOURCE_MAP.md#n-rewards).

`BuyNewPerk` validates or force-buys a rank, increments the purchase ledger,
activates the perk, processes extra rank effects and spends Primary or Espionage
points. `HandleAddingPerkLevel` specifically powers up skeleton cyberware for the
relevant Tech milestone's third rank. Removing a package alone would not remove
all of that perk's behavior. [N-perks](SOURCE_MAP.md#n-perks).

### Current modifications — SOURCE

- `SkillTotalLevel.reds` intercepts XP/level updates and derives compatibility Level.
- `SkillDrivenPowerLevel.yaml` independently installs five combined modifiers,
  each contributing 0.2 times a skill to PowerLevel.
- `DisableAttributePoints.reds` intercepts point awards and attribute purchase/reset.
- `SkillMilestones.reds` changes reward descriptions and implements its replacement
  stats; it is not merely a UI patch.
- `ShardPerkCompatibility.reds` calls reconciliation after native activation and
  deactivation. A native purchase and its private shard copy must not both apply.

[M-level](SOURCE_MAP.md#m-level), [M-milestones](SOURCE_MAP.md#m-milestones),
[M-perk-compat](SOURCE_MAP.md#m-perk-compat).

### Proposed audit record

```text
AbilityDefinition
  stableId, semanticVersion
  nativePerkIds, nativePackageIds, scriptRankQueries
  mechanism: technique | hardware | software | consumable
  requiredCapabilities, trainingRequirements
  grantedModifiers, effects, resourceCosts
  replacementDecision, migrationRule, removalRule
```

Trace every source package, direct `IsNewPerkBought` branch, stat consumer and UI
label before migrating an ability. Test new saves and saves with existing native
purchases, recorded mastery, installed unfinished shards and refunded perks.

## 3. Scaling and stat dependencies

The confirmed native ICE helper is:

```text
ICE = target.HackingResistance
    + 0.5 * (target.PowerLevel - player.Level)
```

It is a helper value, not a complete simulated firewall. The RAM cost path separately
reads action costs and modifiers, then applies a `puppet_dynamic_scaling` power-level
difference curve; ultimate hacks receive another extra-cost addition in that branch.
Perks can further change costs. [N-ice](SOURCE_MAP.md#n-ice),
[N-hack-cost](SOURCE_MAP.md#n-hack-cost).

Consequently, changing Level while retaining PowerLevel, or vice versa, can affect
hacking as well as visible enemy strength. Native armor effectiveness is obtained
through `StatsDataSystem.GetArmorEffectivenessValue`; its implementation is native.
Comments describing its curve are not sufficient to certify current effective values.

Proposed scaling work: inventory every consumer of Level/PowerLevel; assign it to
compatibility, player stats, encounter selection, item generation, requirements or
economy. Capture resolved curves and effective actor stats for fixed test builds.
Retain level scaling while preventing multiple independent modifiers from rewarding
or penalizing the same progression change twice.

## 4. Cyberware and equipment

`EquipmentSystemPlayerData.CheckEquipPrereqs` reads item and variant prerequisites
and evaluates them with `RPGManager.CheckPrereq`. Slot `OnInsertion` and item
`OnEquip` lists supply gameplay packages. [N-equip](SOURCE_MAP.md#n-equip),
[N-equip-packages](SOURCE_MAP.md#n-equip-packages).

Capacity code reads `HumanityAvailable` and `HumanityOverallocated`; SDP's capacity
YAML writes `BaseStats.Humanity`. These names are used for capacity accounting.
Do not remove these fields because the design excludes a psychological humanity meter.
[N-capacity](SOURCE_MAP.md#n-capacity).

The Cyberware-EX customization supplies extra areas/slots through `UserConfig`.
Its requirements use sentinel levels 116–123 interpreted by shard expansion code.
Keep that integration explicit when redesigning shards; deleting a shard family
without migrating its slot entitlement can strand equipped items.

Proposed shared hardware definitions should reference separate player equip packages
and NPC abilities/actions. Activation policy belongs beside the NPC adapter: trigger,
resource reserve, cooldown, interference, animation readiness and interruption.
Do not assume NPCs have a player-equivalent equipment UI or capacity inventory.

## 5. Weapons and crafting

Native `CraftingSystem.CraftItem` obtains recipe ingredients and costs, processes
inventory components and creates/configures an item. `UpgradeItem` is a separate
path. Existing item parts/slot packages can express some component effects, while
novel geometry or animation would require assets. [N-crafting](SOURCE_MAP.md#n-crafting),
[N-upgrade](SOURCE_MAP.md#n-upgrade).

Proposed first implementation: an allowlisted receiver/weapon family, supported
part slots, explicit material transactions and a versioned specification attached
to a stable owned item identity. Derive effective stats once and invalidate that
cache on modification/equip. Avoid globally rewriting a base weapon record for
one custom gun, which would also change other instances sharing the record.

Required proof: crafting, save/load, drop/pickup, stash, upgrade and salvage preserve
identity and parts without duplication or material gain loops. A full arbitrary
weapon assembler is not established by the native recipe API.

## 6. Damage and armor

### Verified native order — SOURCE

```text
ProcessPipeline
  PreProcess
    ConvertDPSToHitDamage / CalculateDamageVariants / flags and validity
    ModifyHitData
      reduction / localized damage / instant kill / dodge / evasion / mitigation
  Process
    special damage paths
    CalculateSourceModifiers
    CalculateTargetModifiers -> ProcessArmor
    source-vs-target / global / device / vehicle / quickhack modifiers
    ProcessOneShotProtection
    DealDamages only when projectionPipeline == false
  ProcessHitReaction
  PostProcess
```

This condenses inspected calls; it is not a complete enumeration of every branch.
`ProcessProjectionPipeline` also invokes `PreProcess` and `Process`, but populates
damage preview data instead of dealing real health damage.
[N-damage](SOURCE_MAP.md#n-damage), [N-preprocess](SOURCE_MAP.md#n-preprocess),
[N-process](SOURCE_MAP.md#n-process), [N-target-mods](SOURCE_MAP.md#n-target-mods).

### Native armor calculation — SOURCE

In the inspected `ProcessArmor` path:

1. Skip DoT and attacks without a weapon; return if penetration is at least 1.
2. Read Armor; for qualifying player hits, an armored hit shape can substitute a
   higher HitShapeArmor value.
3. Apply the relevant Overheat armor-melt adjustment and fractional penetration.
4. Get armor effectiveness; apply the extra player multiplier for player targets.
5. For nonnegative effective armor A, multiply damage by `1 / (1 + A*E)`.
6. Each positive damage channel has a minimum resulting value of 1 in this function.

The negative-armor branch differs. Other pipeline stages still modify the result;
this formula must not be presented as total final damage. [N-armor](SOURCE_MAP.md#n-armor).

### Current SDP — SOURCE

`SDPDurability.Direction` enrolls eligible ranged, non-DoT, non-AOE interactions
between V and selected NPCs. The armor wrapper delegates everything else to vanilla.
The selected armor piece is the highest effective intact piece covering the part;
the implementation is not cumulative layered armor.

`Apply` performs a logistic penetration roll, changes integrity, records telemetry
and adjusts damage. Player hit parts may use the shooter's recent sampled zone;
unavailable exact player hit-shape information must remain an explicit approximation.
The source currently correlates a sample with the shooter using a 0.75-second window,
so burst/projectile attribution deserves a separate test.
[M-durability](SOURCE_MAP.md#m-durability), [M-armor-kit](SOURCE_MAP.md#m-armor-kit).

Two issues must precede balance work:

- **Projection side effects:** this wrapper has no projection guard before integrity
  mutation/random sampling. The native projection path reaches armor. A scanner
  damage preview may therefore mutate state when eligibility conditions match.
  This is a source-level risk, not a reproduced gameplay result.
- **Injury ordering:** CE's limb hook evaluates computed damage inside
  `ProcessLocalizedDamage`, before the armor stage. It cannot presently represent
  injury determined from final damage passing through armor.

[M-armor-hook](SOURCE_MAP.md#m-armor-hook), [M-limbs](SOURCE_MAP.md#m-limbs).

Proposed split: a side-effect-free protection estimate for UI; a real-hit resolution
that commits integrity and injury once; injury decisions consume resolved damage and
coverage. Preserve native invulnerability/quest protections and clearly scope fatal
penetration rules before expanding them to bosses or authored encounters.

## 7. Injury persistence and consumable healing

Native charge handling uses `HealingItemsCharges`, `GrenadesCharges` and
`ProjectileLauncherCharges` pools. UI listeners calculate/show available charges
and recharge feedback. Inventory quantity and available use charges are not the
same value. [N-charges](SOURCE_MAP.md#n-charges),
[N-charge-listeners](SOURCE_MAP.md#n-charge-listeners).

Current NPC crippling stores limb flags and invokes disarm/movement/incapacitation
responses. It is not a demonstrated persistent treatment system for V and NPCs.

Proposed player state:

```text
InjuryState
  schemaVersion
  limb / biological-or-hardware
  severity, bleedingRate, stabilized, treatmentProgress
  ownedModifierIds, treatmentType
```

Persist durable injury facts, not object references or active callback handles.
Rebuild transient modifiers/listeners after load; remove only owned modifiers.
Choose simulation-time versus elapsed-world-time behavior explicitly. Reserve and
consume medical supplies only at documented treatment commit points; handle
interruption, death, equipment changes and reload without double consumption.

NPC supply accounting can initially be encounter-scoped. Player supplies need
save-persistent accounting. Audit biomonitor/blood-pump and perk refill paths before
disabling charge regeneration, otherwise an alternate writer may bypass the rule.

## 8. Player quickhacks and custom-program integration

### Native semantic chain — SOURCE/DATA

```text
Installed program / available target actions
  -> action eligibility and menu translation
  -> cost / queue / upload handling
  -> action start and completion effects
  -> status effects or effectors on target/instigator
  -> packages, stat modifiers, attacks, reactions and cleanup
```

`BaseScriptableAction.GetCost` is not simply the program's displayed base RAM.
`ProcessStatusEffects` and `ProcessEffectors` select recipients and pass instigator/
proxy identities. Reusing a package without preserving those identities can change
the mechanics. [N-hack-cost](SOURCE_MAP.md#n-hack-cost),
[N-hack-effects](SOURCE_MAP.md#n-hack-effects), [N-queue](SOURCE_MAP.md#n-queue).

The stored Overheat example resolves action records into a Burning status, a
continuous thermal attack, stackable duration modifier and conditional AI reaction.
Use the native-dump explanation tool for each family; do not infer all hacks from it.

### Current custom path — SOURCE

`CustomPrograms.reds` extends puppet quickhack choices, refreshes custom records
before menu translation and decorates resulting commands. A status tagged
`SDPCustomHack` triggers `SDPQH_Execute` only when its instigator is the player.
The handler is on `NPCPuppet`. [M-custom-hacks](SOURCE_MAP.md#m-custom-hacks).

`DesignLibrary.reds` stores design parameters and encoded names as persistent fields
on `PlayerDevelopmentData`. It is a player design library, not an NPC program store.
[M-hack-save](SOURCE_MAP.md#m-hack-save).

Proposed refactor: immutable `ProgramSpec` semantics plus `PlayerProgramAdapter`
and `NPCProgramAdapter`. Each resolves its own resources and legal targets while
sharing effect definitions and stacking rules. The existing Build 14 comparison
meter can test native/recreated behavior; it does not certify enemy execution.

## 9. Access, routes, ICE and trace

Native access points expose breach booleans and propagate updates/actions to connected
devices. These are useful topology hints, but they do not directly provide our
desired permission system. Native trace/reveal actions, proxy links and ICE helper
values should not be conflated into one state. [N-access](SOURCE_MAP.md#n-access).

Proposed state contracts:

```text
Endpoint: stableId, owner, subsystem, exposedInterfaces, online, securityProfile
AccessGrant: principalId, endpointOrSubnet, scopes, routeId, issuedAt, expiresAt
Route: orderedEndpoints, lastValidatedAt, state, lossReason
HackSession: sessionId, actorId, targetId, programVersion, routeId,
             phase, reservedResources, uploadProgress, traceProgress
```

`HackSession` phases: discovering, connecting, authorized, uploading, executing,
interrupted, completed. Discovery does not grant connectivity; connectivity does
not grant every scope. Revalidate on both upload start and completion, and whenever
a route endpoint goes offline. Define whether an already delivered payload continues
after disconnection; route loss should not universally undo every completed effect.

Gate both the menu and authoritative action execution. Otherwise queued actions,
custom programs, camera-control actions or a stale menu can bypass access checks.
Preserve explicit tutorial/quest exceptions rather than opening all unknown networks.
Do not globally treat an unconnected target as either completely immune or unprotected:
local wireless/physical entry must have an explicit policy.

## 10. Enemy uploads: why concurrency needs redesign

Verified chain:

```text
AISubActionQuickHack.Hack
  -> HackTargetEvent(target, netrunner, action record)
  -> ScriptedPuppet.OnHackTargetEvent
  -> AIQuickHackAction.ProcessRPGAction
  -> target QuickHackUpload pool / upload listener
  -> action result effects and interruption/cleanup
```

`OnHackTargetEvent` checks `AIQuickHackStatusEffect.BeingHacked`; ordinary attempts
in the blocked branch are delayed by two seconds. `AIQuickHackAction.StartUpload`
resets the target's QuickHackUpload stat/pool, registers a listener and initializes
regeneration. The player listener writes one `UI_HUDProgressBar` and requests a save
lock. PlayerPuppet additionally stores `m_attackingNetrunnerID`.
[N-incoming-hack](SOURCE_MAP.md#n-incoming-hack), [N-ai-upload](SOURCE_MAP.md#n-ai-upload),
[N-upload-listener](SOURCE_MAP.md#n-upload-listener), [N-player-hacker](SOURCE_MAP.md#n-player-hacker).

When upload scaling is enabled, the inspected regeneration rate is:

```text
progressPerSecond = 100 / (1.02^distance * activationTime * target.NPCUploadTime)
```

That describes this pool's progress rate; scheduling and interruptions can change
elapsed completion time. Revealing-position actions can disable this scaling.

Recommended prototype: retain native serialization initially while validating routes
and counters. Then add independent sessions and an aggregated threat UI. Do not reset
a shared native pool for each simultaneous session. Only raise action admission
after session completion, interruption and resource ownership are proven independent.

## 11. HUD and reconnaissance

Native `TagObject` invokes the scanning controller, forced reveal, UI refresh,
HUD notification and blackboard registration. Hiding a minimap icon alone leaves
other reveal surfaces active. [N-tag](SOURCE_MAP.md#n-tag).

The minimap controller's single-player condition includes `hasBeenSeen`, dead actors,
companions, past detection, highlighting and tagging, with earlier quest/prevention
branches. Preserve noncombat navigation and quest handling while adding the desired
tactical gate. [N-minimap](SOURCE_MAP.md#n-minimap).

Proposed `Contact` contract:

```text
targetId, observerId, sourceType, observedPosition, observedAt,
confidence, identityKnown, liveOrStale, expiresAt, requiredGrantId
```

Do not use a target-attached live marker to depict a remembered position. A stale
contact needs a marker anchored to the stored position, or it will silently track
the actor. Revoke camera-derived live updates when the feed/access ends.

SensorDevice exposes current targets, but target lists can reflect hostility/security
filters rather than all people geometrically visible in the camera image. A camera
recon adapter must validate field of view, range and occlusion for the desired targets.
[N-sensor](SOURCE_MAP.md#n-sensor).

TakeOverControlSystem has controlled-object state, input/chain locks and quest-related
constraints. Start with supported camera control. A mobile drone additionally needs
entity lifecycle, movement/collision, input ownership, camera return, recall and
save/load handling. [N-control](SOURCE_MAP.md#n-control).

## 12. Ownership and integration

| Concern | Existing owner | Proposed addition |
| --- | --- | --- |
| Rank/attributes/PowerLevel | SDP-Skills | Consumer audit and calibrated scaling policy |
| Shard XP/mastery/native perk reconciliation | SDP-Perks | Ability provenance and migration |
| Aim/cadence/eligible bullet armor | SDP-Combat | Correct damage commit and observation inputs |
| CE-derived movement/morale | SDP-Combat/SDPCE | Unified role coordination with authored-control guards |
| Custom hack semantics/library | SDP-QuickhackCrafting | Actor-independent specifications and NPC adapter |
| Access and contacts | No complete current owner | Shared access/contact services |
| Slots | Cyberware-EX plus SDP customization | Explicit entitlement migration |
| Persistent injuries and finite supplies | No complete current owner | Versioned state and treatment/resource services |

Avoid multiple mods independently replacing the same armor, shot, stat or dispatch
policy. A shared service can live in a small new dependency or an expanded Core;
that packaging choice is open because Combat and QuickhackCrafting currently aim
to work without SDP-Core. Do not silently introduce a new hard dependency.
