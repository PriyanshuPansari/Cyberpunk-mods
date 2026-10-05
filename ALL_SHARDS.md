# Shard developer reference

For current gameplay, thresholds and settings, start with [README.md](README.md).
This file owns family IDs, diagnostic commands and the generation workflow.

The processor has three training bays and one Relic bay. The Deadeye grade
chain, fourteen other eleven-grade families, and one single-grade Vehicle chip
are represented by physical items. Base shards are stocked by netrunner vendors;
higher grades are created from the preceding shard in the processor menu with
components. A completed grade is recorded from the same menu. XP, use XP, and
recorded grades belong to the character, so another copy of a shard resumes
the same progress. Recorded packages remain applied after removing the shard
or processor.

The source of truth for effects is `design/SHARD_GRADE_ORDERS.md`, compiled
into `design/other-shard-catalog.json` by `tools/BuildOtherShardCatalog.py`.
`tools/GenerateOtherShardAssets.py` produces item, vendor, package, and
redscript lookup files. Edit the grade orders and ledger, then regenerate;
the generated files should not be edited by hand.

Runtime XP is implemented in `ShardChannels.reds`; matching descriptions and
thresholds are in `design/shard-channels.json`. The old `shard-training.json`
is retained for v1 diagnostics, not active awards. Regenerate
`tools/GenerateTrainingMethods.py` and `tools/GenerateProcessorText.py` after
changing channel descriptions. Regenerate `tools/GenerateRecordedLedger.py`
after changing effects. Family asset generation also produces clone provenance
for vanilla-perk deduplication. Run `tools/VerifyProgression.py` to check inputs
and outputs agree, and rebuild the archive after localization changes.

The shard tooltip lists current training channels and the bar shows
character-owned XP. Hover over the processor for recorded grades/perk names.
For full effect descriptions in CET:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print(d:SDP_RecordedLedger())
```

## Family numbers for CET

| ID | Family | Linked skill | Qualifying use XP |
| --- | --- | --- | --- |
| 1 | Adrenaline | Solo | Wounded combat time, health lost, later healing/Adrenaline events |
| 2 | Obliteration | Solo | Shotgun or LMG damage; close neutralization |
| 3 | Quake | Solo | Blunt damage; knockdown |
| 4 | Air Dash | Shinobi | Combat locomotion; later air dashes and post-dash hits/kills |
| 5 | Sharpshooter | Shinobi | Assault rifle or SMG damage; precision hit |
| 6 | Blade Runner | Shinobi | Blade damage; neutralization at later grades |
| 7 | Chrome | Engineer | Cyberarm damage and combat time with qualifying cyberware active |
| 8 | Pyromania | Engineer | Explosion damage and combat healing-item use |
| 9 | Bolt | Engineer | Tech damage; full-charge and timed-Bolt multipliers |
| 10 | Overclock | Netrunner | Quickhack damage and upload RAM cost |
| 11 | Hack Queue | Netrunner | Queued-hack RAM; later device hacks and Monowire damage |
| 12 | Smart Lock | Netrunner | Smart weapon damage; precision hit |
| 13 | Ninjutsu | Headhunter | Crouched time near watchers, stealth damage, later stealth kills |
| 14 | Juggler | Headhunter | Thrown knives/axes; knife/axe melee and ranged stealth hits |
| 15 | Vehicle | None | Vehicle weapon damage |

Deadeye uses ID **0** for channel/settings APIs and separate `SDP_Order...`
storage/item methods; it is not a valid ID for `SDP_FamilyGrantShard`.
It trains from precision-weapon damage, later airborne-grenade shots and
combat weapon swaps. See [TRAINING_METHODS.md](TRAINING_METHODS.md) for exact
grade unlocks for all families. Skill XP does not train shards. One unrecorded
grade per family trains while installed; recorded effects consume no bay.

For a temporary test shard, run this CET command with the desired family ID:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print(d:SDP_FamilyGrantShard(1,1), d:SDP_FamilyStatus(1))
```

Replace `1` with any ID in the table. Slot the item in the processor from
inventory. For a status check, call `d:SDP_FamilyStatus(id)` using a fresh
`d` binding as above. The tooltip and processor menu show the character's
current grade XP. The console can grant a later grade only for inspection;
it cannot skip the recorded-grade sequence required for training.

On a disposable test save, empty all three processor shard bays and paste
these **two separate lines** into CET. The first advances the fourteen other
families and Vehicle; the second advances Deadeye. Each grade is granted,
slotted, filled with XP, and recorded in order. Components are skipped because
upgrades were checked separately. A failure stops at the family and grade
named in its error.

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); for f=1,15 do for g=d:SDP_FamilyMasteredGrade(f)+1,(f==15 and 1 or 11) do assert(d:SDP_FamilyGrantShard(f,g),"grant "..f..":"..g); assert(d:SDP_FamilySlotShard(f,g,0),"slot "..f..":"..g); d:SDP_FamilyAddXP(f,6000,false); assert(d:SDP_FamilyRecord(f),"record "..f..":"..g) end; print(d:SDP_FamilyStatus(f)) end
```

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); for g=d:SDP_OrderDeadeyeActiveGrade()+1,11 do assert(d:SDP_OrderGrantDeadeyeShard(g),"grant Deadeye "..g); assert(d:SDP_OrderSlotDeadeye(g,0),"slot Deadeye "..g); d:SDP_OrderAddDeadeyeXP(6000,false); assert(d:SDP_OrderRecordDeadeye(),"record Deadeye "..g) end; print(d:SDP_OrderDeadeyeStatus())
```

Finished effects remain active after recording frees the processor bay.
Physical test shards remain in inventory. Both lines can resume after a
failure because they start at the next unrecorded grade.

## Effect audit still needed during play

Package copies cover every readable vanilla rank package in the grade orders.
The redscript perk-rank adapter supplies direct vanilla script checks for
package-free ranks, including movement, quickhack queue, and cyberware-slot
prerequisites. Custom packages supply Lucky Day's crafting-material chance
and Smart Lock's passive accuracy and lock-speed fallbacks. Result hooks
supply Smart neutralization Stamina recovery and Bolt's charged-hit Stamina
refund; a weapon-local modifier supplies Bolt's Tier 5 headshot bonus.
Chrome's scripted Skeleton upgrades now have an explicit lifecycle adapter.
Individual effects, cyberware slots and upgrade choices still require gameplay
checks; compilation alone is not a complete effect audit. Follow
[the regression checklist](docs/REGRESSION_CHECKS.md).
