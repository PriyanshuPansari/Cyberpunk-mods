# Native quickhacks: compact design reference

Start here; load only the family JSON needed for exact conditions and formulas. The full compact JSON is a lookup archive, not required context for every design.

Source: 77 programs, 18 families; 11,529 record occurrences reduced to 1,771 unique IDs.

## Interpretation limits

- Snapshot: SDP native quickhack dump | build 13 | full (Codeware: every field of every record) / Player level 49 | Intelligence 20 | max RAM 41 | 77 programs.
- RAM/upload/duration/spread below are the workbench extractor’s snapshot values. Computed modifier/attack values use the player as both source and target; they are not measured damage against an enemy.
- “Recreated part” and “Not recreated” describe the importer’s current coverage. They do not establish that a primitive exactly reproduces native behavior.
- Native status tags, prerequisites, scripted effector classes and AI behavior matter. This dump contains record data, not the implementation of those classes.
- Same-title T5 variants stay separate by item ID. Do not merge their values. The original traversal stops at depth >12 and only expands selected record classes.

## Suggested primitive boundaries

This is a design proposal, not a claim that these custom features already exist:

1. Trigger: upload completion, hit, headshot, reload, or status change; carry source and target identities.
2. Conditions: target type, combat state, tags/status stacks, distance, immunity and resource thresholds.
3. Payload: sensory blindness, accuracy modifier, weapon malfunction, damage burst/pulses, movement restriction, cyberware suppression, AI command or information reveal. Keep these independently selectable.
4. Timing: upload, duration, pulse interval, cooldown, charges and removal rules.
5. Propagation: which payload transfers, eligible recipients, radius, delay, hop/target budget and reinfection policy.
6. Presentation: animation, icon and VFX/SFX. A blind animation alone is not evidence that shooting or tracking stopped.

Rebuild a native tier from its own action → effect → status → package → effector/modifier chain. Preserve application conditions and recipients before experimenting with cross-family combinations.

## Program catalog

Timings are seconds. “++” below means the item ID contains `PlusPlus`; the source title itself does not distinguish it.

| Program | Item ID (after `Items.`) | Snapshot |
|---|---|---|
| Bait T1 | `WhistleLvl0Program` | 2 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Bait T2 | `WhistleLvl1Program` | 3 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Bait T3 | `WhistleLvl2Program` | 3 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Bait T4 | `WhistleLvl3Program` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Bait T5 | `WhistleLvl4Program` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 0s; spread 0 within 0m |
| Bait T5 ++ | `WhistleLvl4PlusPlusProgram` | 3 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 0s; spread 0 within 0m |
| Blackwall Gateway T4 | `BlackWallProgramLvl3` | 12 RAM; upload 9s (constant part 9s); cooldown 0s; duration 0s; spread 0 within 0m |
| Contagion T2 | `ContagionProgram` | 5 RAM; upload 3s (constant part 3s); cooldown 0s; duration 6s; spread 0 within 0m |
| Contagion T3 | `ContagionLvl2Program` | 6 RAM; upload 3s (constant part 3s); cooldown 0s; duration 7s; spread 0 within 0m |
| Contagion T4 | `ContagionLvl3Program` | 9 RAM; upload 2s (constant part 2s); cooldown 0s; duration 8s; spread 0 within 0m |
| Contagion T5 | `ContagionLvl4Program` | 12 RAM; upload 2s (constant part 2s); cooldown 0s; duration 8s; spread 0 within 0m |
| Contagion T5 ++ | `ContagionLvl4PlusPlusProgram` | 12 RAM; upload 2s (constant part 2s); cooldown 0s; duration 8s; spread 0 within 0m |
| Cripple Movement T2 | `LocomotionMalfunctionProgram` | 3 RAM; upload 5s (constant part 5s); cooldown 0s; duration 13.8s; spread 0 within 0m |
| Cripple Movement T3 | `LocomotionMalfunctionLvl2Program` | 4 RAM; upload 5s (constant part 5s); cooldown 0s; duration 13.8s; spread 0 within 0m |
| Cripple Movement T4 | `LocomotionMalfunctionLvl3Program` | 6 RAM; upload 5s (constant part 5s); cooldown 0s; duration 13.8s; spread 0 within 0m |
| Cripple Movement T5 | `LocomotionMalfunctionLvl4Program` | 6 RAM; upload 5s (constant part 5s); cooldown 0s; duration 13.8s; spread 0 within 0m |
| Cyberpsychosis T4 | `MadnessLvl3Program` | 22 RAM; upload 1.5s (constant part 1.5s); cooldown 0s; duration 20s; spread 0 within 0m |
| Cyberpsychosis T5 | `MadnessLvl4Program` | 22 RAM; upload 1.5s (constant part 1.5s); cooldown 0s; duration 60s; spread 0 within 0m |
| Cyberpsychosis T5 ++ | `MadnessLvl4PlusPlusProgram` | 22 RAM; upload 1.5s (constant part 1.5s); cooldown 0s; duration 60s; spread 0 within 0m |
| Cyberware Malfunction T2 | `DisableCyberwareProgram` | 3 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 10s; spread 0 within 0m |
| Cyberware Malfunction T3 | `DisableCyberwareLvl2Program` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 10s; spread 0 within 0m |
| Cyberware Malfunction T4 | `DisableCyberwareLvl3Program` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 10s; spread 0 within 0m |
| Cyberware Malfunction T5 ++ | `DisableCyberwareLvl4PlusPlusProgram` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 10s; spread 0 within 0m |
| Cyberware Malfunction T5 | `DisableCyberwareLvl4Program` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 10s; spread 0 within 0m |
| Detonate Grenade T4 | `GrenadeExplodeLvl3Program` | 24 RAM; upload 1s (constant part 1s); cooldown 0s; duration 15s; spread 0 within 0m |
| Detonate Grenade T5 ++ | `GrenadeExplodeLvl4PlusPlusProgram` | 24 RAM; upload 1s (constant part 1s); cooldown 0s; duration 1s; spread 0 within 0m |
| Detonate Grenade T5 | `GrenadeExplodeLvl4Program` | 24 RAM; upload 1s (constant part 1s); cooldown 0s; duration 1s; spread 0 within 0m |
| Memory Wipe T3 | `MemoryWipeLvl2Program` | 8 RAM; upload 12.5s (constant part 12.5s); cooldown 0s; duration 9.2s; spread 0 within 0m |
| Memory Wipe T4 | `MemoryWipeLvl3Program` | 10 RAM; upload 12.5s (constant part 12.5s); cooldown 0s; duration 9.2s; spread 0 within 0m |
| Memory Wipe T5 ++ | `MemoryWipeLvl4PlusPlusProgram` | 32 RAM; upload 3s (constant part 3s); cooldown 0s; duration 9.2s; spread 0 within 0m |
| Memory Wipe T5 | `MemoryWipeLvl4Program` | 32 RAM; upload 21s (constant part 21s); cooldown 0s; duration 9.2s; spread 0 within 0m |
| Overheat T1 | `OverheatProgram` | 3 RAM; upload 2s (constant part 2s); cooldown 0s; duration 5s; spread 0 within 0m |
| Overheat T2 | `OverheatLvl1Program` | 4 RAM; upload 2s (constant part 2s); cooldown 0s; duration 5s; spread 0 within 0m |
| Overheat T3 | `OverheatLvl2Program` | 6 RAM; upload 2s (constant part 2s); cooldown 0s; duration 5s; spread 0 within 0m |
| Overheat T4 | `OverheatLvl3Program` | 7 RAM; upload 2s (constant part 2s); cooldown 0s; duration 5s; spread 0 within 0m |
| Overheat T5 ++ | `OverheatLvl4PlusPlusProgram` | 9 RAM; upload 2s (constant part 2s); cooldown 0s; duration 5s; spread 0 within 0m |
| Overheat T5 | `OverheatLvl4Program` | 9 RAM; upload 2s (constant part 2s); cooldown 0s; duration 5s; spread 0 within 0m |
| Ping T1 | `q001_netrunner_software_shard` | 4 RAM; upload 1s (constant part 1s); cooldown 0s; duration 9.2s; spread 0 within 0m |
| Ping T3 | `PingLvl2Program` | 5 RAM; upload 1s (constant part 1s); cooldown 0s; duration 13.8s; spread 0 within 0m |
| Ping T5 ++ | `PingLvl4PlusPlusProgram` | 4 RAM; upload 1s (constant part 1s); cooldown 0s; duration 34.5s; spread 0 within 0m |
| Ping T5 | `PingLvl4Program` | 7 RAM; upload 1s (constant part 1s); cooldown 0s; duration 18.4s; spread 0 within 0m |
| Reboot Optics T1 | `BlindProgram` | 2 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 8s; spread 0 within 0m |
| Reboot Optics T2 | `BlindLvl1Program` | 2 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 15s; spread 0 within 0m |
| Reboot Optics T3 | `BlindLvl2Program` | 5 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 15s; spread 0 within 0m |
| Reboot Optics T4 | `BlindLvl3Program` | 7 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 15s; spread 0 within 0m |
| Reboot Optics T5 ++ | `BlindLvl4PlusPlusProgram` | 7 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 15s; spread 1 within 10m |
| Request Backup T2 | `CommsCallInLvl1Program` | 3 RAM; upload 2s (constant part 2s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Request Backup T3 | `CommsCallInLvl2Program` | 3 RAM; upload 2s (constant part 2s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Request Backup T4 | `CommsCallInLvl3Program` | 4 RAM; upload 2s (constant part 2s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Request Backup T5 | `CommsCallInLvl4Program` | 6 RAM; upload 2s (constant part 2s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Request Backup T5 ++ | `CommsCallInLvl4PlusPlusProgram` | 3 RAM; upload 2s (constant part 2s); cooldown 0s; duration 17.25s; spread 0 within 0m |
| Short Circuit T1 | `EMPOverloadProgram` | 3 RAM; upload 1.5s (constant part 1.5s); cooldown 0s; duration 0.1s; spread 0 within 0m |
| Short Circuit T2 | `EMPOverloadLvl1Program` | 4 RAM; upload 1.5s (constant part 1.5s); cooldown 0s; duration 0.1s; spread 0 within 0m |
| Short Circuit T3 | `EMPOverloadLvl2Program` | 5 RAM; upload 1s (constant part 1s); cooldown 0s; duration 0.1s; spread 0 within 0m |
| Short Circuit T4 | `EMPOverloadLvl3Program` | 7 RAM; upload 1s (constant part 1s); cooldown 0s; duration 3s; spread 0 within 0m |
| Short Circuit T5 | `EMPOverloadLvl4Program` | 10 RAM; upload 0.5s (constant part 0.5s); cooldown 0s; duration 3s; spread 0 within 0m |
| Short Circuit T5 ++ | `EMPOverloadLvl4PlusPlusProgram` | 10 RAM; upload 0.5s (constant part 0.5s); cooldown 0s; duration 3s; spread 0 within 0m |
| Sonic Shock T2 | `CommsNoiseProgram` | 3 RAM; upload 1s (constant part 1s); cooldown 0s; duration 23s; spread 0 within 0m |
| Sonic Shock T3 | `CommsNoiseLvl2Program` | 4 RAM; upload 1s (constant part 1s); cooldown 0s; duration 23s; spread 0 within 0m |
| Sonic Shock T4 | `CommsNoiseLvl3Program` | 5 RAM; upload 1s (constant part 1s); cooldown 0s; duration 23s; spread 0 within 0m |
| Sonic Shock T5 ++ | `CommsNoiseLvl4PlusPlusProgram` | 2 RAM; upload 2s (constant part 2s); cooldown 0s; duration 23s; spread 0 within 0m |
| Sonic Shock T5 | `CommsNoiseLvl4Program` | 6 RAM; upload 2s (constant part 2s); cooldown 0s; duration 23s; spread 0 within 0m |
| Suicide T4 | `SuicideLvl3Program` | 24 RAM; upload 1s (constant part 1s); cooldown 0s; duration 15s; spread 0 within 0m |
| Suicide T5 | `SuicideLvl4Program` | 24 RAM; upload 1s (constant part 1s); cooldown 0s; duration 15s; spread 0 within 0m |
| Suicide T5 ++ | `SuicideLvl4PlusPlusProgram` | 24 RAM; upload 1s (constant part 1s); cooldown 0s; duration 15s; spread 0 within 0m |
| Synapse Burnout T3 | `BrainMeltLvl2Program` | 10 RAM; upload 3s (constant part 3s); cooldown 0s; duration 5s; spread 0 within 0m |
| Synapse Burnout T4 | `BrainMeltLvl3Program` | 14 RAM; upload 3s (constant part 3s); cooldown 0s; duration 5s; spread 0 within 0m |
| Synapse Burnout T5 ++ | `BrainMeltLvl4PlusPlusProgram` | 16 RAM; upload 3s (constant part 3s); cooldown 0s; duration 5s; spread 0 within 0m |
| Synapse Burnout T5 | `BrainMeltLvl4Program` | 16 RAM; upload 3s (constant part 3s); cooldown 0s; duration 5s; spread 0 within 0m |
| System Collapse T4 | `SystemCollapseLvl3Program` | 28 RAM; upload 1s (constant part 1s); cooldown 0s; duration 8.82s; spread 0 within 0m |
| System Collapse T5 | `SystemCollapseLvl4Program` | 28 RAM; upload 1s (constant part 1s); cooldown 0s; duration 8.82s; spread 0 within 0m |
| System Collapse T5 ++ | `SystemCollapseLvl4PlusPlusProgram` | 28 RAM; upload 1s (constant part 1s); cooldown 0s; duration 8.82s; spread 0 within 0m |
| Weapon Glitch T2 | `WeaponMalfunctionProgram` | 3 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 14s; spread 0 within 0m |
| Weapon Glitch T3 | `WeaponMalfunctionLvl2Program` | 4 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 14s; spread 0 within 0m |
| Weapon Glitch T4 | `WeaponMalfunctionLvl3Program` | 6 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 14s; spread 0 within 0m |
| Weapon Glitch T5 | `WeaponMalfunctionLvl4Program` | 6 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 14s; spread 0 within 0m |
| Weapon Glitch T5 ++ | `WeaponMalfunctionLvl4PlusPlusProgram` | 6 RAM; upload 0.3s (constant part 0.3s); cooldown 0s; duration 14s; spread 0 within 0m |

## Family components and importer coverage

Native start/completion entries below resolve direct action effects to their status or effector IDs, with recipients. They are an index, not a full effect chain; recipient and prerequisite details remain in the JSON.

### Bait

Exact records: [families/bait.json](families/bait.json)

- Native startEffects: `BaseStatusEffect.WhistleCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WhistleLvl0 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WhistleLvl1 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WhistleLvl2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WhistleLvl3 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.WhistleLvl4Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.WhistleLvl4PlusPlusHack_inline3 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): none reported
- Importer gaps: `ApplyLegendaryWhistleEffector`; `ApplyStatGroupEffector`; `RefreshPingEffector`; `WhistleLvl0`; `WhistleLvl1`; `WhistleLvl2`; `WhistleLvl3`

### Blackwall Gateway

Exact records: [families/blackwall-gateway.json](families/blackwall-gateway.json)

- Native startEffects: `BaseStatusEffect.BlackWallUploadActive (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.BlackwallCooldown (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.BlackwallHack_FactHelper (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.HauntedQuickHackBlackwallUpload (recipient=ObjectActionReference.Target)`; `Effectors.RemoveReduceNextUltimateHackCostReductionSE (recipient=ObjectActionReference.Instigator)`; `QuickHack.BaseBlackWallHack_inline6 (recipient=ObjectActionReference.Target)`; `QuickHack.BlackWallHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.RewardPlayerWithCrimeScoreEffector (recipient=ObjectActionReference.Target)`; `QuickHack.BaseBlackWallHack_inline10 (recipient=ObjectActionReference.Instigator)`; `QuickHack.BlackWallHack_inline13 (recipient=ObjectActionReference.Target)`; `QuickHack.BlackWallHack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.BlackWallHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): none reported
- Importer gaps: `ApplyStatGroupEffector`; `ApplyStatusEffectEffector`; `RefreshPingEffector`; `RewardPlayerWithCrimeScoreEffector`; `SpreadEffector`

### Contagion

Exact records: [families/contagion.json](families/contagion.json)

- Native startEffects: `BaseStatusEffect.ContagionCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.BaseContagionHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.ContagionPoison (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.ContagionPoisonLvl2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.ContagionPoisonLvl3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.ContagionPoisonLvl4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.ContagionPoisonLvl4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionHack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl2Hack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl3Hack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl4Hack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.ContagionLvl4PlusPlusHack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 7 (chemical damage pulses) for 6s, amount 3.25, interval 0.25s, from ContagionPoison, native look ready; payload 7 (chemical damage pulses) for 7s, amount 5.82, interval 0.25s, from ContagionPoisonLvl2, native look ready; payload 7 (chemical damage pulses) for 8s, amount 7, interval 0.25s, from ContagionPoisonLvl3, native look ready; payload 7 (chemical damage pulses) for 8s, amount 9.4, interval 0.25s, from ContagionPoisonLvl4, native look ready; payload 7 (chemical damage pulses) for 8s, amount 9.4, interval 0.25s, from ContagionPoisonLvl4PlusPlus, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `SpreadEffector`

### Cripple Movement

Exact records: [families/cripple-movement.json](families/cripple-movement.json)

- Native startEffects: `QuickHack.LocomotionMalfunctionHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl2Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl3Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl4Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.LocomotionMalfunction (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.LocomotionMalfunctionLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.LocomotionMalfunctionLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.LocomotionMalfunctionLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.NotifyPoliceEffector (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl2Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl3Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.LocomotionMalfunctionLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 9 (immobilization) for 13.8s, amount 0, interval 1s, from LocomotionMalfunction, native look ready; payload 9 (immobilization) for 13.8s, amount 0, interval 1s, from LocomotionMalfunctionLevel2, native look ready; payload 9 (immobilization) for 13.8s, amount 0, interval 1s, from LocomotionMalfunctionLevel3, native look ready; payload 9 (immobilization) for 13.8s, amount 0, interval 1s, from LocomotionMalfunctionLevel4, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `NotifyPoliceEffector`; `RefreshPingEffector`; `SpreadEffector`

### Cyberpsychosis

Exact records: [families/cyberpsychosis.json](families/cyberpsychosis.json)

- Native startEffects: `BaseStatusEffect.MadnessCooldown (recipient=ObjectActionReference.Instigator)`; `Effectors.RemoveReduceNextUltimateHackCostReductionSE (recipient=ObjectActionReference.Instigator)`; `QuickHack.MadnessHackBase_inline6 (recipient=ObjectActionReference.Target)`; `QuickHack.MadnessLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.MadnessLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.MadnessLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.Madness (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.MandessLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.MandessLevel4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.RewardPlayerWithCrimeScoreEffector (recipient=ObjectActionReference.Target)`; `QuickHack.MadnessLvl3Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.MadnessLvl4Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.MadnessLvl4PlusPlusHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): none reported
- Importer gaps: `ApplyStatGroupEffector`; `Madness`; `MandessLevel4`; `MandessLevel4PlusPlus`; `RefreshPingEffector`; `RewardPlayerWithCrimeScoreEffector`; `SpreadEffector`

### Cyberware Malfunction

Exact records: [families/cyberware-malfunction.json](families/cyberware-malfunction.json)

- Native startEffects: `QuickHack.CyberwareMalfunctionHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl2Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl3Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl4Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl4PlusPlusHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.CyberwareMalfunctionLvl1 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CyberwareMalfunctionLvl2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CyberwareMalfunctionLvl3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CyberwareMalfunctionLvl4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CyberwareMalfunctionLvl4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.ApplyDisableCWOnCyberwareMalfunctionEffector (recipient=ObjectActionReference.Target)`; `Effectors.ApplyDoTOnCyberwareMalfunctionEffector (recipient=ObjectActionReference.Target)`; `Effectors.NotifyPoliceEffector (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl2Hack_inline8 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl3Hack_inline9 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl4Hack_inline9 (recipient=ObjectActionReference.Target)`; `QuickHack.CyberwareMalfunctionLvl4PlusPlusHack_inline9 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 12 (cyberware malfunction) for 10s, amount 0, interval 1s, from CyberwareMalfunctionLvl1, native look ready; payload 12 (cyberware malfunction) for 10s, amount 0, interval 1s, from CyberwareMalfunctionLvl2, native look ready; payload 12 (cyberware malfunction) for 10s, amount 0, interval 1s, from CyberwareMalfunctionLvl3, native look ready; payload 12 (cyberware malfunction) for 10s, amount 0, interval 1s, from CyberwareMalfunctionLvl4, native look ready; payload 12 (cyberware malfunction) for 10s, amount 0, interval 1s, from CyberwareMalfunctionLvl4PlusPlus, native look ready; payload 3 (electrical damage pulses) for 10s, amount 1021, interval 0s, from CyberwareMalfunctionLvl4, native look ready; payload 3 (electrical damage pulses) for 10s, amount 1021, interval 0s, from CyberwareMalfunctionLvl4PlusPlus, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `ApplyStatusEffectEffector`; `NotifyPoliceEffector`; `RefreshPingEffector`; `SpreadEffector`

### Detonate Grenade

Exact records: [families/detonate-grenade.json](families/detonate-grenade.json)

- Native startEffects: `BaseStatusEffect.GrenadeCooldown (recipient=ObjectActionReference.Instigator)`; `Effectors.RemoveReduceNextUltimateHackCostReductionSE (recipient=ObjectActionReference.Instigator)`; `QuickHack.GrenadeHackBase_inline6 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl3Hack_inline4 (recipient=ObjectActionReference.Instigator)`; `QuickHack.GrenadeLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl4Hack_inline4 (recipient=ObjectActionReference.Instigator)`; `QuickHack.GrenadeLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl4PlusPlusHack_inline4 (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.SuicideWithGrenade (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.SuicideWithGrenadeDummy (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.RewardPlayerWithCrimeScoreEffector (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl3Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl4Hack_inline9 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl4PlusPlusHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.GrenadeLvl4PlusPlusHack_inline9 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 1 (blindness) for 15s, amount 0, interval 1s, from SuicideWithGrenade, native look ready; payload 1 (blindness) for 1s, amount 0, interval 1s, from SuicideWithGrenadeDummy, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `GrenadeLvl4HackEffector`; `RefreshPingEffector`; `RewardPlayerWithCrimeScoreEffector`; `SpreadEffector`

### Memory Wipe

Exact records: [families/memory-wipe.json](families/memory-wipe.json)

- Native startEffects: `BaseStatusEffect.MemoryWipeCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`; `QuickHack.QHF_MemoryWipeSpreadInitEffector.effectorToTrigger$AEA580E2 (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Start_MemoryWipeSpreadEffector2.effectorToTrigger$8B0BEBF6 (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Start_MemoryWipeSpreadEffector3.effectorToTrigger$1533F849 (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Start_MemoryWipeSpreadEffector4.effectorToTrigger$C376E390 (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Start_MemoryWipeSpreadEffector4PlusPlus.effectorToTrigger$B1D4B1D0 (recipient=ObjectActionReference.Target)`
- Native completionEffects: `BaseStatusEffect.MemoryWipeLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.MemoryWipeLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.MemoryWipeLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Completion_MemoryWipeSpreadEffector2.effectorToTrigger$8F134FA7 (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Completion_MemoryWipeSpreadEffector3.effectorToTrigger$9548517C (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Completion_MemoryWipeSpreadEffector4.effectorToTrigger$0830520D (recipient=ObjectActionReference.Target)`; `QuickHack.QHF_Completion_MemoryWipeSpreadEffector4PlusPlus.effectorToTrigger$783CAA2D (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 1 (blindness) for 9.2s, amount 0, interval 1s, from MemoryWipeLevel2, native look ready; payload 1 (blindness) for 9.2s, amount 0, interval 1s, from MemoryWipeLevel3, native look ready; payload 1 (blindness) for 9.2s, amount 0, interval 1s, from MemoryWipeLevel4, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `SpreadEffector`

### Overheat

Exact records: [families/overheat.json](families/overheat.json)

- Native startEffects: `BaseStatusEffect.OverheatCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.BaseOverheatHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`; `QuickHack.OverheatHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl1Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`
- Native completionEffects: `BaseStatusEffect.Overheat (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverheatLevel1 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverheatLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverheatLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverheatLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverheatLevel4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl1Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl2Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl3Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl4Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverheatLvl4PlusPlusHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 2 (thermal damage pulses) for 5s, amount 15.62, interval 0.25s, from OverheatLevel2, native look ready; payload 2 (thermal damage pulses) for 5s, amount 23, interval 0.25s, from OverheatLevel3, native look ready; payload 2 (thermal damage pulses) for 5s, amount 29.88, interval 0.25s, from OverheatLevel4, native look ready; payload 2 (thermal damage pulses) for 5s, amount 29.88, interval 0.25s, from OverheatLevel4PlusPlus, native look ready; payload 2 (thermal damage pulses) for 5s, amount 7.15, interval 0.25s, from Overheat, native look ready; payload 2 (thermal damage pulses) for 5s, amount 9.15, interval 0.25s, from OverheatLevel1, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `SpreadEffector`

### Ping

Exact records: [families/ping.json](families/ping.json)

- Native startEffects: `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.Ping (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.PingLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.PingLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.PingLevel4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): none reported
- Importer gaps: `ApplyStatGroupEffector`; `Ping`; `PingLevel2`; `PingLevel4`; `PingLevel4PlusPlus`; `RefreshPingEffector`

### Reboot Optics

Exact records: [families/reboot-optics.json](families/reboot-optics.json)

- Native startEffects: `BaseStatusEffect.RebootOpticsCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.BlindHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl1Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl1Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl2Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl3Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl4Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.ModerateBlind (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackBlind (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackBlindLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackBlindLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackBlindLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackBlindLvl1 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.ShortBlind (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.NotifyPoliceEffector (recipient=ObjectActionReference.Target)`; `QuickHack.BlindHack_inline8 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl1Hack_inline8 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl2Hack_inline8 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl3Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl4Hack_inline10 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl4Hack_inline12 (recipient=ObjectActionReference.Target)`; `QuickHack.BlindLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 1 (blindness) for 15s, amount 0, interval 1s, from QuickHackBlindLevel3, native look ready; payload 1 (blindness) for 15s, amount 0, interval 1s, from QuickHackBlindLevel4, native look ready; payload 1 (blindness) for 2s, amount 0, interval 1s, from ShortBlind, native look ready; payload 1 (blindness) for 4s, amount 0, interval 1s, from ModerateBlind, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `NotifyPoliceEffector`; `RefreshPingEffector`; `SpreadEffector`; `second blindness effect (QuickHackBlind)`; `second blindness effect (QuickHackBlindLevel2)`; `second blindness effect (QuickHackBlindLvl1)`

### Request Backup

Exact records: [families/request-backup.json](families/request-backup.json)

- Native startEffects: `BaseStatusEffect.CallInCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.CommsCallInLvl1 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CommsCallInLvl2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CommsCallInLvl3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CommsCallInLvl4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): none reported
- Importer gaps: `ApplyStatGroupEffector`; `CommsCallInLvl1`; `CommsCallInLvl2`; `CommsCallInLvl3`; `CommsCallInLvl4`; `RefreshPingEffector`

### Short Circuit

Exact records: [families/short-circuit.json](families/short-circuit.json)

- Native startEffects: `BaseStatusEffect.OverloadCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`; `QuickHack.OverloadBaseHack_inline6 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl1Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl2Hack_inline2 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl3Hack_inline2 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl4Hack_inline2 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl4PlusPlusHack_inline2 (recipient=ObjectActionReference.Target)`
- Native completionEffects: `BaseStatusEffect.Overload (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverloadEMP (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverloadLevel1 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverloadLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverloadLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverloadLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.OverloadLevel4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadControlQuickhackExtension_inline0 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadDestroyBreach_inline0 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadDestroyWeakpoint_inline0 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl1Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl2Hack_inline6 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl3Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.OverloadLvl4PlusPlusHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 3 (electrical damage pulses) for 0.1s, amount 100, interval 0s, from OverloadLevel1, native look ready; payload 3 (electrical damage pulses) for 0.1s, amount 136, interval 0s, from OverloadLevel2, native look ready; payload 3 (electrical damage pulses) for 0.1s, amount 150, interval 0s, from OverloadLevel3, native look ready; payload 3 (electrical damage pulses) for 0.1s, amount 260, interval 0s, from OverloadLevel4, native look ready; payload 3 (electrical damage pulses) for 0.1s, amount 260, interval 0s, from OverloadLevel4PlusPlus, native look ready; payload 3 (electrical damage pulses) for 0.1s, amount 78, interval 0s, from Overload, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `ApplyStatusEffectEffector`; `DestroyBreachEffector`; `ModifyStatusEffectDurationEffector`; `RefreshPingEffector`; `SpreadEffector`; `second electrical damage pulses effect (OverloadEMP)`

### Sonic Shock

Exact records: [families/sonic-shock.json](families/sonic-shock.json)

- Native startEffects: `BaseStatusEffect.CommsNoiseCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.BaseCommsNoiseHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl4Hack_inline2 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl4PlusPlusHack_inline4 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.CommsNoise (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CommsNoiseLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CommsNoiseLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.CommsNoiseLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl2Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl3Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl4Hack_inline6 (recipient=ObjectActionReference.Target)`; `QuickHack.CommsNoiseLvl4PlusPlusHack_inline8 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 11 (deafness and comms jam) for 23s, amount 0, interval 1s, from CommsNoise, native look ready; payload 11 (deafness and comms jam) for 23s, amount 0, interval 1s, from CommsNoiseLevel2, native look ready; payload 11 (deafness and comms jam) for 23s, amount 0, interval 1s, from CommsNoiseLevel3, native look ready; payload 11 (deafness and comms jam) for 23s, amount 0, interval 1s, from CommsNoiseLevel4, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `SpreadEffector`

### Suicide

Exact records: [families/suicide.json](families/suicide.json)

- Native startEffects: `BaseStatusEffect.SuicideCooldown (recipient=ObjectActionReference.Instigator)`; `Effectors.RemoveReduceNextUltimateHackCostReductionSE (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`; `QuickHack.SuicideHackBase_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.SuicideHackBase_inline9 (recipient=ObjectActionReference.Instigator)`; `QuickHack.SuicideLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.SuicideLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.SuicideLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`
- Native completionEffects: `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.SuicideWithWeapon (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.RewardPlayerWithCrimeScoreEffector (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.SuicideLvl3Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.SuicideLvl4Hack_inline5 (recipient=ObjectActionReference.Instigator)`; `QuickHack.SuicideLvl4Hack_inline9 (recipient=ObjectActionReference.Target)`; `QuickHack.SuicideLvl4PlusPlusHack_inline5 (recipient=ObjectActionReference.Instigator)`; `QuickHack.SuicideLvl4PlusPlusHack_inline9 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 1 (blindness) for 15s, amount 0, interval 1s, from SuicideWithWeapon, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `RewardPlayerWithCrimeScoreEffector`; `SpreadEffector`; `second blindness effect (SuicideWithWeapon)`

### Synapse Burnout

Exact records: [families/synapse-burnout.json](families/synapse-burnout.json)

- Native startEffects: `BaseStatusEffect.BrainMeltCooldown (recipient=ObjectActionReference.Instigator)`; `QuickHack.BrainMeltBaseHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl4Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl4PlusPlusHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`
- Native completionEffects: `BaseStatusEffect.BrainMeltLevel2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.BrainMeltLevel3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.BrainMeltLevel4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.BrainMeltLevel4PlusPlus (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl2Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl3Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.BrainMeltLvl4PlusPlusHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 8 (physical damage pulses) for 5s, amount 122, interval 0s, from BrainMeltLevel2, native look ready; payload 8 (physical damage pulses) for 5s, amount 167.03, interval 0s, from BrainMeltLevel3, native look ready; payload 8 (physical damage pulses) for 5s, amount 188.45, interval 0s, from BrainMeltLevel4, native look ready; payload 8 (physical damage pulses) for 5s, amount 188.45, interval 0s, from BrainMeltLevel4PlusPlus, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `SpreadEffector`

### System Collapse

Exact records: [families/system-collapse.json](families/system-collapse.json)

- Native startEffects: `BaseStatusEffect.SystemCollapseCooldown (recipient=ObjectActionReference.Instigator)`; `Effectors.RemoveReduceNextUltimateHackCostReductionSE (recipient=ObjectActionReference.Instigator)`; `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`; `QuickHack.SystemCollapseHackBase_inline10 (recipient=ObjectActionReference.Instigator)`; `QuickHack.SystemCollapseHackBase_inline8 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`
- Native completionEffects: `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.SystemCollapse (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `Effectors.RewardPlayerWithCrimeScoreEffector (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl3Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl4Hack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl4PlusPlusHack_inline5 (recipient=ObjectActionReference.Target)`; `QuickHack.SystemCollapseLvl4PlusPlusHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 1 (blindness) for 8.82s, amount 0, interval 1s, from SystemCollapse, native look ready; payload 8 (physical damage pulses) for 8.82s, amount 1481.80, interval 0s, from SystemCollapse, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `RefreshPingEffector`; `RewardPlayerWithCrimeScoreEffector`; `SpreadEffector`; `SystemCollapseModifyRevealBarEffector`

### Weapon Glitch

Exact records: [families/weapon-glitch.json](families/weapon-glitch.json)

- Native startEffects: `QuickHack.ModifyHackUploadTimeOnMechanicals (recipient=none)`; `QuickHack.WeaponMalfunctionHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionHack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl2Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl2Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl3Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl3Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl4Hack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl4Hack_inline3 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl4PlusPlusHack_inline1 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl4PlusPlusHack_inline3 (recipient=ObjectActionReference.Target)`
- Native completionEffects: `BaseStatusEffect.QuickHackUploaded (recipient=ObjectActionReference.Instigator)`; `BaseStatusEffect.WasQuickHacked (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WeaponMalfunction (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WeaponMalfunctionLvl2 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WeaponMalfunctionLvl3 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WeaponMalfunctionLvl4 (recipient=ObjectActionReference.Target)`; `BaseStatusEffect.WeaponMalfunctionLvl4PlusPlus (recipient=ObjectActionReference.Target)`; `Effectors.NotifyPoliceEffector (recipient=ObjectActionReference.Target)`; `QuickHack.QuickHack_inline3 (recipient=none)`; `QuickHack.QuickHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionHack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl2Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl3Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl4Hack_inline7 (recipient=ObjectActionReference.Target)`; `QuickHack.WeaponMalfunctionLvl4PlusPlusHack_inline7 (recipient=ObjectActionReference.Target)`
- Importer extracted payloads (tier values may differ): payload 10 (weapon jam) for 14s, amount 0, interval 1s, from WeaponMalfunction, native look ready; payload 10 (weapon jam) for 14s, amount 0, interval 1s, from WeaponMalfunctionLvl2, native look ready; payload 10 (weapon jam) for 14s, amount 0, interval 1s, from WeaponMalfunctionLvl3, native look ready; payload 10 (weapon jam) for 14s, amount 0, interval 1s, from WeaponMalfunctionLvl4, native look ready; payload 10 (weapon jam) for 14s, amount 0, interval 1s, from WeaponMalfunctionLvl4PlusPlus, native look ready
- Importer gaps: `ApplyStatGroupEffector`; `NotifyPoliceEffector`; `RefreshPingEffector`; `SpreadEffector`
