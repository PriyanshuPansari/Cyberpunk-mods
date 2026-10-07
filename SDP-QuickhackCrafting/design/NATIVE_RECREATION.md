# Recreating native quickhacks faithfully (Build 14)

Build 13 rebuilt every native quickhack from our primitives and gave each
recreation a "native look". The native dump (`design/native-dump/`) shows what
that look left out: the animations, effects and mechanics that native statuses
carry in their packages, the second status most hacks apply, stacking, and a
few importer mistakes. Build 14 fixes these from the dump data.

This document records what the dump showed, what Build 14 changes, which
native bugs the recreations avoid, and what is still not recreated. Everything
here comes from reading the dump and the decompiled 2.31 scripts. None of it
has been checked in game yet: see the Build 14 checks in
[QUICKHACK_DESIGNER.md](../docs/QUICKHACK_DESIGNER.md#in-game-acceptance-checks-not-yet-run).

`python tools/ExplainNativeQuickhack.py "Overheat T3"` prints what a native
program does to its target. Add `--recreation` to see what Build 14 rebuilds
from it, or use `--recreation --all --markdown` for the table at the end.

## What the dump showed

### 1. The behavior is in the packages, and the look dropped them

A native status has a type and AI data (the NPC's reaction and animation),
VFX and SFX. Everything else is in its gameplay packages. Build 13's look
record replaced those packages with our primitive's, so a recreation lost:

| Lost with the packages | Examples |
| --- | --- |
| Animations | Cripple Movement limps: its package overrides the animation wrapper with `woundedLocomotion_l_leg`. |
| Effects started by effectors | Short Circuit's sparks and electrocution sounds (`PlayVFXEffector`, `PlaySFXEffector`), Weapon Glitch's gun effect, Sonic Shock's head effect, Synapse Burnout's two VFX. |
| Stat mechanics | Reboot Optics: accuracy x0.01, speed and jump x0.5, no sprint, no cover, no evasion, no cybereye. Weapon Glitch: accuracy x0.35, smart-gun hit chance -0.7. Sonic Shock: no reinforcements, detection x0.5. Cripple Movement: speed and jump x0.2, no legs, double jump, charge jump, Sandevistan or Kerenzikov. Cyberware Malfunction: 28 cyberware stats set to 0. |
| Other effectors | EMP: cloaking removed, drone stat groups. Synapse Burnout: android head dismemberment and blindness. Cyberware Malfunction: cyberware statuses removed, damage-taken bonus. |

Build 13 also added our mechanics tags to the look. The `SDPJam` tag blocks
every shot, but the native Weapon Glitch does not: the NPC plays a jam
reaction (status type `Jam` and its AI data) and then shoots with worse
accuracy.

### 2. Most hacks apply more than one status

- Reboot Optics T1-T3 apply a short `Blind` status (2 s or 4 s) that makes the
  NPC stumble and ruins its aim, plus a long `QuickHackBlind` status (8 s or
  15 s) with the blinded effects. Its stat group is gated by `IsPlayerPrereq`,
  which the earlier blindness trace shows applies to NPCs too: the prerequisite
  is very likely inverted, through a flat the Build 13 dump could not see (see 8).
  Build 13 recreated only the short status.
- Short Circuit T4 and T5 add `OverloadEMP`: 3 s of electrical damage every
  0.2 s, with the EMP reaction. Build 13 listed it as "second electrical
  damage pulses effect".
- Cyberware Malfunction T3 and up apply further statuses depending on the
  stacks already on the target (see 4).

### 3. Some statuses are their own AI behavior

Suicide, System Collapse, Detonate Grenade, Cyberpsychosis, Memory Wipe,
Request Backup, Bait and Ping each apply a status whose type plays the whole
behavior. Several carry a `Blind` tag, so Build 13 called Suicide, Detonate
Grenade, Memory Wipe and System Collapse "blindness" and left the rest native
only.

### 4. Conditional effects

Cyberware Malfunction is a stack ladder. Each upload adds a stack (up to 8);
with 2 stacks on the target, the next upload disables its cyberware for good;
with 3 or more, it also applies a damage-over-time status; at 8 stacks the
status itself triggers an EMP explosion. Build 13 ignored these conditions:
its T5 recreation dealt the 1021-damage explosion as plain damage on every
upload.

Short Circuit T3+ destroys weakspots and the tracked breach when the target
also malfunctions (two status checks).

### 5. Stacking and duration

Native statuses stack and keep a dynamic duration: Overheat stacks twice and
each stack adds 3 s, Contagion stacks twice and each stack ticks its own
damage, Cyberware Malfunction stacks eight times. Intelligence perks extend
quickhack durations. Build 13 forced one stack and trimmed every status to its
base duration.

### 6. Spread

Upload spread is prepared by a `SpreadInitEffector` in the action's **start**
effects. A count of 0 means "only on a successful Overclock roll"; -1 means the
player's spread stats. Build 13 read spread only from completion effects, so
it missed the real spread and read Reboot Optics T5++'s spread on death
(`BlindHackSpreadOnDeath`) as upload spread.

### 7. Effects every quickhack runs, and its costs

Every native quickhack's completion also applies the hacked-enemy armor
reduction (a stat group read from the player's `HackedEnemyArmorReduction`)
and refreshes Ping on the squad. Control hacks notify the police, and
ultimates report a crime. The chip kept only the "was quickhacked"
bookkeeping.

Costs are per category: `TargetResistanceControl`, `Damage`, `Covert` or
`Ultimate`, plus category discounts, plus a separate cost record per tier. The
chip used Reboot Optics' control-hack modifiers for everything, which is why
Build 13 warned that RAM could differ "by a point or two".

Native attacks carry hit flags the game and perks react to: `Nonlethal`,
`ForceNoCrit`, `DisableNPCHitReaction`, `MechanicalDamageBonus`,
`NonEliteDamageBonus`, `DamageBasedOnMissingMemoryBonus`. Our pulses had only
`QuickHack` and `DamageOverTime`.

### 8. What the Build 13 dump could not see

Effector records such as `PlayVFXEffector` are the generic `Effector` type,
and scripted prerequisites such as `IsPlayerPrereq` the generic `IPrereq`
type. Their data are loose flats that the class's `Initialize` reads by name
(`vfxName`, `activationSFXName`, `attackPositionSlotName`,
`playerAsInstigator`, `invert`, `rarity`...). Reflection over the record class
cannot list them, so the dump has the effect classes but not their names.
Build 14's dump lists them (`LooseFlats.reds`, generated from the decompiled
scripts by `tools/MakeLooseFlats.py`).

## What Build 14 does

| Native | Build 14 recreation |
| --- | --- |
| Status, its AI, VFX, SFX, UI, immunities, tags | Kept in the look record. Nothing of ours is added except the `SDPPrimitive` and `SDPLook` tags. |
| Packages: stats, animation overrides, effect and sound effectors, other effectors | Kept. Only the unconditional damage effectors our pulses replace, and spread effectors, are removed; a package that loses one is copied (`<package>.SDPLook`). Conditional effectors stay with their native condition. |
| Duration, stacking, dynamic duration, perk extensions | Kept: the look lasts as long as its native status. Our pulses run while it is on the target (up to 600 s). |
| Each status the hack applies | One part per status. The first part made from a status wears its look; a second part from the same status (damage on a control status) runs as our plain primitive, so packages never apply twice. Parts beyond the first two run alongside them on upload. |
| A status that is its own behavior | A native-behavior part (payload 13, recreations only). |
| Damage effectors | Our pulses, with the native amount and interval. A pulse uses a copy of the native attack without its damage values (`<attack>.SDPLook`): native damage type, attack type and hit flags. A stackable damage package hits once per stack. |
| Conditional completion effects | Checked per target at upload by `SDPQHConditions` (stat checks on the target or player, status and tag checks where our look counts as its native status, AND/OR groups), before or after the upload's statuses as in the native completion order. |
| Completion effectors with no status | Run by the chip from script, as their game classes do (`SDPQHPorts`): police notice, crime score, duration change (Short Circuit extends the target's control hacks), System Collapse's trace reveal bar, breach destruction. |
| Immunity | A part whose native status the target is immune to is skipped, pulses included. |
| Upload spread | Read from the start effects, with the Overclock roll at upload. |
| Category, costs, target checks, icon | Set per slot when a recreation is compiled: the native hack category and gameplay category, the native cost records (our RAM constant replaces only the first record's constant), the native target checks (the wheel refuses "immune" or "needs a ranged weapon" targets as the native does), and the native wheel icon. A design gets Reboot Optics' again. |
| Armor reduction, ping refresh | Every chip keeps these generic completion effects. |

Build 14 recreations still use our timing for what we replace (pulse clock,
amount, triggers, spread) and the meter still tells our hits from native ones,
now by the `SDPPrimitive` source on our hit flags.

## Native bugs

The user's dump was taken with **Quickhack Fixes** ([Nexus 18290](https://www.nexusmods.com/cyberpunk2077/mods/18290))
installed (the `QHF_` records). Its page could not be read from here, so this
list uses the fixes visible in its changelog excerpts, plus **Quickhack Damage
Fix** ([Nexus 9695](https://www.nexusmods.com/cyberpunk2077/mods/9695)).

| Native bug | In a Build 14 recreation |
| --- | --- |
| The stat-screen quickhack damage bonus applies only to attacks whose record reads it (Synapse Burnout T4/T5). | **Fixed.** Every recreated damage attack that does not read `BonusQuickHackDamage` gets it (the summary lists "Native bugs fixed"). |
| Short Circuit, Synapse Burnout and Overheat double their effects when they spread (Spillover, Raven). | **Avoided by construction.** Our spread installs the program once on each recipient. |
| Contagion T5 and Iconic apply a different status on each bounce. | **Avoided by construction.** Every recipient runs the same parts. |
| Cyberware Malfunction T3+ does not disable cyberware for good after 2 stacks. | **Follows the records.** With Quickhack Fixes the condition is "2 stacks", and the recreation checks it per target. |
| Memory Wipe cannot spread. | **Follows the records.** The recreation spreads when the action has an upload `SpreadInitEffector` (Quickhack Fixes adds one). |
| Sonic Shock's System Collapse combo against targets in vehicles; Memory Wipe T4+ trace prevention without Hack Queue. | Not recreated: combos and trace rules belong to the native actions. |

## Still not recreated

- **Blackwall Gateway T4**: its two statuses were not expanded in the dump,
  and its conditions use `NPCRarityPrereq`, which needs the loose flats. A
  Build 14 dump will show them.
- **Detonate Grenade T5**: `GrenadeLvl4HackEffector` swaps the NPC's grenade
  through its inventory and attachment slots; porting that blind is too risky.
  The suicide-with-grenade behavior itself is recreated.
- **Bait T5**: re-uploading on a lured target out of combat turns it away
  (`WhistleLvl4_TurnAway`). The recreation always applies `WhistleLvl4`.
- **Reboot Optics T5++**: spread to a nearby enemy when the target dies.
- **Upload-phase statuses** on the target (Blackwall's haunted upload effect):
  the chip acts on upload completion only.
- **Spread recipients** get the parts, police notice and crime score, but not
  the chip's generic effects (armor reduction, "was quickhacked").
- **Native checks by record ID**: the native game's own prerequisites that look
  for a native status by ID (a native Short Circuit checking for Cyberware
  Malfunction) do not see our look records. Tag checks do.
- **Perk bonuses tied to attack record IDs** rather than hit flags.
- **Pulse timing**: our first pulse lands on application; a native damage over
  time may wait one interval.
- **Attack roots**: damage is computed as the program tooltip computes it, with
  you as root and target. System Collapse's damage depends on the root's power
  level (`TriggerAttackOnOwnerEffect` uses the NPC as instigator unless its
  `playerAsInstigator` flat says otherwise); a Build 14 dump shows that flat.

## Next data to send

Run **Dump all to file** again with Build 14 and send the new
`native-quickhacks-dump.txt`. It lists the loose flats (effect names, sound
names, `invert`, `rarity`, `playerAsInstigator`...) and each recreation's
parts, chip-run effectors and fixed bugs. Compress it as before with
`tools/CompressNativeDump.py`. With it: meter lines from a few
native-versus-recreation tests (Overheat T3, Reboot Optics T1, Short Circuit
T5, Cyberware Malfunction T4 uploaded four times).

## Coverage preview

Generated by `python tools/ExplainNativeQuickhack.py --recreation --all --markdown`
from the Build 13 dump. "?" marks an attack the dump did not expand (the
in-game importer reads it). "Native behavior" parts are the status's own AI
behavior. Conditions read "only when"; a long `with ... OR ...` is the Short
Circuit weakspot combo.

| Program | Recreated parts (look) | Not recreated |
|---|---|---|
| Bait T1 | native behavior for 17.25s (look WhistleLvl0) | - |
| Bait T2 | native behavior for 17.25s (look WhistleLvl1) | - |
| Bait T3 | native behavior for 17.25s (look WhistleLvl2) | - |
| Bait T4 | native behavior for 17.25s (look WhistleLvl3) | - |
| Bait T5 | native behavior with no time limit (look WhistleLvl4) | WhistleLvl4_TurnAway (re-uploading on a lured target out of combat turns it away) |
| Bait T5 ++ | native behavior with no time limit (look WhistleLvl4) | WhistleLvl4_TurnAway (re-uploading on a lured target out of combat turns it away) |
| Blackwall Gateway T4 | none | BaseBlackWallHackEffect (only when NPCRarityPrereq AND NPCRarityPrereq AND IsExo = 0)<br>BossBlackWallHack (only when NPCRarityPrereq OR NPCRarityPrereq OR IsExo = 1) |
| Contagion T2 | chemical damage pulses for 6s, 3.25 every 0.25s per stack (look ContagionPoison) | - |
| Contagion T3 | chemical damage pulses for 7s, 5.82 every 0.25s per stack (look ContagionPoisonLvl2) | - |
| Contagion T4 | chemical damage pulses for 8s, 7 every 0.25s per stack (look ContagionPoisonLvl3) | - |
| Contagion T5 | chemical damage pulses for 8s, 9.4 every 0.25s per stack (look ContagionPoisonLvl4) | - |
| Contagion T5 ++ | chemical damage pulses for 8s, 9.4 every 0.25s per stack (look ContagionPoisonLvl4PlusPlus) | - |
| Cripple Movement T2 | immobilization for 13.8s (look LocomotionMalfunction) | - |
| Cripple Movement T3 | immobilization for 13.8s (look LocomotionMalfunctionLevel2) | - |
| Cripple Movement T4 | immobilization for 13.8s (look LocomotionMalfunctionLevel3) | - |
| Cripple Movement T5 | immobilization for 13.8s (look LocomotionMalfunctionLevel4) | - |
| Cyberpsychosis T4 | native behavior for 20s (look Madness) | - |
| Cyberpsychosis T5 | native behavior for 60s (look MandessLevel4) | - |
| Cyberpsychosis T5 ++ | native behavior for 60s (look MandessLevel4PlusPlus) | - |
| Cyberware Malfunction T2 | cyberware malfunction for 10s (look CyberwareMalfunctionLvl1) | - |
| Cyberware Malfunction T3 | only when CyberwareMalfunctionStacks = 2 (before the upload's statuses): cyberware malfunction with no time limit (look DisableCyberwareAndCyberwareStatusEffects)<br>cyberware malfunction for 10s (look CyberwareMalfunctionLvl2) | - |
| Cyberware Malfunction T4 | only when CyberwareMalfunctionStacks = 2 (before the upload's statuses): cyberware malfunction with no time limit (look DisableCyberwareAndCyberwareStatusEffects)<br>only when CyberwareMalfunctionStacks >= 3 (before the upload's statuses): electrical damage pulses for 4s, 16.3 every 0.5s per stack (look CyberwareMalfunctionDamageOverTime)<br>cyberware malfunction for 10s (look CyberwareMalfunctionLvl3) | - |
| Cyberware Malfunction T5 ++ | only when CyberwareMalfunctionStacks = 2 (before the upload's statuses): cyberware malfunction with no time limit (look DisableCyberwareAndCyberwareStatusEffects)<br>only when CyberwareMalfunctionStacks >= 3 (before the upload's statuses): electrical damage pulses for 4s, 16.3 every 0.5s per stack (look CyberwareMalfunctionDamageOverTime)<br>cyberware malfunction for 10s (look CyberwareMalfunctionLvl4PlusPlus) | - |
| Cyberware Malfunction T5 | only when CyberwareMalfunctionStacks = 2 (before the upload's statuses): cyberware malfunction with no time limit (look DisableCyberwareAndCyberwareStatusEffects)<br>only when CyberwareMalfunctionStacks >= 3 (before the upload's statuses): electrical damage pulses for 4s, 16.3 every 0.5s per stack (look CyberwareMalfunctionDamageOverTime)<br>cyberware malfunction for 10s (look CyberwareMalfunctionLvl4) | - |
| Detonate Grenade T4 | native behavior for 15s (look SuicideWithGrenade) | - |
| Detonate Grenade T5 ++ | native behavior for 1s (look SuicideWithGrenadeDummy) | GrenadeLvl4HackEffector |
| Detonate Grenade T5 | native behavior for 1s (look SuicideWithGrenadeDummy) | GrenadeLvl4HackEffector |
| Memory Wipe T3 | native behavior for 9.2s (look MemoryWipeLevel2) | - |
| Memory Wipe T4 | native behavior for 9.2s (look MemoryWipeLevel3) | - |
| Memory Wipe T5 ++ | native behavior for 9.2s (look MemoryWipeLevel4) | - |
| Memory Wipe T5 | native behavior for 9.2s (look MemoryWipeLevel4) | - |
| Overheat T1 | thermal damage pulses for 5s, 7.15 every 0.25s (look Overheat) | - |
| Overheat T2 | thermal damage pulses for 5s, 9.15 every 0.25s (look OverheatLevel1) | - |
| Overheat T3 | thermal damage pulses for 5s, 15.62 every 0.25s (look OverheatLevel2) | - |
| Overheat T4 | thermal damage pulses for 5s, 23 every 0.25s (look OverheatLevel3) | - |
| Overheat T5 ++ | thermal damage pulses for 5s, 29.88 every 0.25s (look OverheatLevel4PlusPlus) | - |
| Overheat T5 | thermal damage pulses for 5s, 29.88 every 0.25s (look OverheatLevel4) | - |
| Ping T1 | native behavior for 9.2s (look Ping) | - |
| Ping T3 | native behavior for 13.8s (look PingLevel2) | - |
| Ping T5 ++ | native behavior for 34.5s (look PingLevel4PlusPlus) | - |
| Ping T5 | native behavior for 18.4s (look PingLevel4) | - |
| Reboot Optics T1 | blindness for 2s (look ShortBlind)<br>blindness for 8s (look QuickHackBlind) | - |
| Reboot Optics T2 | blindness for 4s (look ModerateBlind)<br>blindness for 15s (look QuickHackBlindLvl1) | - |
| Reboot Optics T3 | blindness for 4s (look ModerateBlind)<br>blindness for 15s (look QuickHackBlindLevel2) | - |
| Reboot Optics T4 | blindness for 15s (look QuickHackBlindLevel3) | - |
| Reboot Optics T5 ++ | blindness for 15s (look QuickHackBlindLevel4) | spread on completion (BlindHackSpreadOnDeath) |
| Request Backup T2 | native behavior for 17.25s (look CommsCallInLvl1) | - |
| Request Backup T3 | native behavior for 17.25s (look CommsCallInLvl2) | - |
| Request Backup T4 | native behavior for 17.25s (look CommsCallInLvl3) | - |
| Request Backup T5 | native behavior for 17.25s (look CommsCallInLvl4) | - |
| Request Backup T5 ++ | native behavior for 17.25s (look CommsCallInLvl4) | - |
| Short Circuit T1 | 78 electrical damage in one hit (look Overload) | - |
| Short Circuit T2 | 100 electrical damage in one hit (look OverloadLevel1) | - |
| Short Circuit T3 | 136 electrical damage in one hit (look OverloadLevel2)<br>only when with Overload OR with OverloadLevel1 OR with OverloadLevel2 OR with OverloadLevel3 OR with OverloadLevel4 OR with OverloadLevel4PlusPlus AND with CyberwareMalfunction OR with CyberwareMalfunctionLvl1 OR with CyberwareMalfunctionLvl2 OR with CyberwareMalfunctionLvl3 OR with CyberwareMalfunctionLvl4 OR with CyberwareMalfunctionLvl4PlusPlus (after the upload's statuses): native behavior for 0.1s (look WeakspotDestructionStatusEffect) | - |
| Short Circuit T4 | 150 electrical damage in one hit (look OverloadLevel3)<br>electrical damage pulses for 3s, 4.8 every 0.2s (look OverloadEMP)<br>only when with Overload OR with OverloadLevel1 OR with OverloadLevel2 OR with OverloadLevel3 OR with OverloadLevel4 OR with OverloadLevel4PlusPlus AND with CyberwareMalfunction OR with CyberwareMalfunctionLvl1 OR with CyberwareMalfunctionLvl2 OR with CyberwareMalfunctionLvl3 OR with CyberwareMalfunctionLvl4 OR with CyberwareMalfunctionLvl4PlusPlus (after the upload's statuses): native behavior for 0.1s (look WeakspotDestructionStatusEffect) | - |
| Short Circuit T5 | 260 electrical damage in one hit (look OverloadLevel4)<br>electrical damage pulses for 3s, 4.8 every 0.2s (look OverloadEMP)<br>only when with Overload OR with OverloadLevel1 OR with OverloadLevel2 OR with OverloadLevel3 OR with OverloadLevel4 OR with OverloadLevel4PlusPlus AND with CyberwareMalfunction OR with CyberwareMalfunctionLvl1 OR with CyberwareMalfunctionLvl2 OR with CyberwareMalfunctionLvl3 OR with CyberwareMalfunctionLvl4 OR with CyberwareMalfunctionLvl4PlusPlus (after the upload's statuses): native behavior for 0.1s (look WeakspotDestructionStatusEffect) | - |
| Short Circuit T5 ++ | ? electrical damage in one hit (look OverloadLevel4PlusPlus)<br>electrical damage pulses for 3s, 4.8 every 0.2s (look OverloadEMP)<br>only when with Overload OR with OverloadLevel1 OR with OverloadLevel2 OR with OverloadLevel3 OR with OverloadLevel4 OR with OverloadLevel4PlusPlus AND with CyberwareMalfunction OR with CyberwareMalfunctionLvl1 OR with CyberwareMalfunctionLvl2 OR with CyberwareMalfunctionLvl3 OR with CyberwareMalfunctionLvl4 OR with CyberwareMalfunctionLvl4PlusPlus (after the upload's statuses): native behavior for 0.1s (look WeakspotDestructionStatusEffect) | - |
| Sonic Shock T2 | deafness and comms jam for 23s (look CommsNoise) | - |
| Sonic Shock T3 | deafness and comms jam for 23s (look CommsNoiseLevel2) | - |
| Sonic Shock T4 | deafness and comms jam for 23s (look CommsNoiseLevel3) | - |
| Sonic Shock T5 ++ | deafness and comms jam for 23s (look CommsNoiseLevel4) | - |
| Sonic Shock T5 | deafness and comms jam for 23s (look CommsNoiseLevel4) | - |
| Suicide T4 | native behavior for 15s (look SuicideWithWeapon) | - |
| Suicide T5 | native behavior for 15s (look SuicideWithWeapon) | - |
| Suicide T5 ++ | native behavior for 15s (look SuicideWithWeapon) | - |
| Synapse Burnout T3 | 122 physical damage in one hit (look BrainMeltLevel2) | - |
| Synapse Burnout T4 | 167.03 physical damage in one hit (look BrainMeltLevel3) | - |
| Synapse Burnout T5 ++ | 188.45 physical damage in one hit (look BrainMeltLevel4PlusPlus) | - |
| Synapse Burnout T5 | 188.45 physical damage in one hit (look BrainMeltLevel4) | - |
| System Collapse T4 | 1481.8 physical damage in one hit (look SystemCollapse) | - |
| System Collapse T5 | 1481.8 physical damage in one hit (look SystemCollapse) | - |
| System Collapse T5 ++ | 1481.8 physical damage in one hit (look SystemCollapse) | - |
| Weapon Glitch T2 | weapon jam for 14s (look WeaponMalfunction) | - |
| Weapon Glitch T3 | weapon jam for 14s (look WeaponMalfunctionLvl2) | - |
| Weapon Glitch T4 | weapon jam for 14s (look WeaponMalfunctionLvl3) | - |
| Weapon Glitch T5 | weapon jam for 14s (look WeaponMalfunctionLvl4) | - |
| Weapon Glitch T5 ++ | weapon jam for 14s (look WeaponMalfunctionLvl4PlusPlus) | - |
