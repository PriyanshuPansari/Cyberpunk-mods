# Deadeye Focus shard CET commands

Paste each command as one line in the Cyber Engine Tweaks console. These
commands affect the current character. Grant commands add another physical
copy each time they run.

## Tier 1+: get the shard and fill attunement

First, record Focus Tier 1. Then grant the Tier 1+ shard:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Tier 1+ shard granted:",d:SDP_OrderGrantDeadeyeTier1PlusShard())
```

Equip it in the neural processor menu. Alternatively, if processor bay 1 is
empty, slot it with CET:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Tier 1+ slotted:",d:SDP_OrderSlotDeadeye(2,0))
```

Fill the **currently slotted, unrecorded grade's** attunement. Tier 1+ caps at
110 XP in training v2. The second argument, `false`, keeps this grant out of the use-XP
counter:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("XP added:",d:SDP_OrderAddDeadeyeXP(999999,false)); print(d:SDP_OrderDeadeyeStatus())
```

After its current-grade progress reaches `110/110`, highlight the equipped shard and
press Square to record it. The equivalent CET command is:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Recorded:",d:SDP_OrderRecordDeadeye()); print(d:SDP_OrderDeadeyeStatus())
```

## If Focus Tier 1 is not recorded yet

Grant Tier 1, equip it, fill its attunement with the same XP command above,
and record it before trying to slot Tier 1+:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Tier 1 shard granted:",d:SDP_OrderGrantDeadeyeTier1Shard())
```

If processor bay 1 is empty, CET can slot Tier 1 with:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Tier 1 slotted:",d:SDP_OrderSlotDeadeye(1,0))
```

Tier 1 caps at 60 XP in training v2. Recording it returns the physical shard
to inventory. You can upgrade that copy to Tier 1+ in the processor menu for
20 Tier 1 components instead of granting Tier 1+ directly.

## Read progress

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print(d:SDP_OrderDeadeyeStatus()); print(d:SDP_OrderDeadeyeUseBreakdown())
```

The breakdown is a historical v1 diagnostic. Current channel XP is shown in
the encounter overlay/log and the total status, not the old source counters.
Attunement stops increasing when the grade is full or recorded.

## Tier 2: Deep Breath and No Sweat

Record Tier 1+ first. Upgrade its inventory shard through the processor menu
for 30 Tier 2 components, or grant a Tier 2 copy for this test:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Tier 2 shard granted:",d:SDP_OrderGrantDeadeyeTier2Shard())
```

Equip it in an empty processor bay. For bay 1, the CET equivalent is:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Tier 2 slotted:",d:SDP_OrderSlotDeadeye(3,0)); print(d:SDP_OrderDeadeyeStatus())
```

Tier 2 uses precision-weapon damage with Focus and precision-hit multipliers.
Reloads do not award channel XP. The following old breakdown call is retained
only for inspecting historical counters:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print(d:SDP_OrderDeadeyeStatus()); print(d:SDP_OrderDeadeyeTier2UseBreakdown())
```

The same XP fill and record commands above apply to Tier 2, whose target is
150 XP. See [the current training reference](TRAINING_METHODS.md) for channels.

## Later grades

The remaining grades use the same grant, slot, fill, and record sequence.
The preceding grade must be recorded before a shard can train. To test a
grade, substitute its number in both commands below:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Granted:",d:SDP_OrderGrantDeadeyeShard(4))
```

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print("Slotted:",d:SDP_OrderSlotDeadeye(4,0)); print(d:SDP_OrderDeadeyeGradeStatus(4))
```

Use grade **4** for Tier 2+, **5** for Tier 3, **6** for Tier 3+, **7** for
Tier 4, **8** for Tier 4+, **9** for Tier 5, **10** for Tier 5+, and **11** for
Tier 5++. The processor menu can upgrade the previous recorded shard using
components instead of a grant command.

To inspect the active grade (source counters in this output are historical):

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); local g=d:SDP_OrderDeadeyeTrainingGrade(); print(d:SDP_OrderDeadeyeGradeStatus(g))
```

`signatureXP` counts XP from the new use sources for that grade. `useXP`
includes all inherited use sources. Tier 2+ adds a Focus neutralization and
shooting down an airborne grenade during Focus; Tier 3 is a damaging precision hit during Deadeye; Tier 3+
is a Deadeye hit at 25 m or more; Tier 4 is a combat weapon swap or Deadeye
precision neutralization; Tier 4+ is a completed reload after an aimed
Deadeye precision neutralization; Tier 5 is a damaging Deadeye hit; Tier 5+
is a damaging hip-fire hit; Tier 5++ is a critical Deadeye precision hit.

For a detailed breakdown of the currently training grade, use:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print(d:SDP_OrderDeadeyeDetailedXP(d:SDP_OrderDeadeyeTrainingGrade()))
```

This prints each use source separately, plus `non-use` XP (shared Headhunter
or a console grant). XP earned before per-source counters were added appears
as `earlier signature` and `earlier inherited`; those past awards cannot be
split further. Future awards appear under their exact method.

## Recorded effects

Hover over the neural processor for a compact list of recorded grades and
perk names. For a complete description of every recorded effect, run:

```lua
local p=Game.GetPlayer(); local d=PlayerDevelopmentSystem.GetInstance(p):GetDevelopmentData(p); print(d:SDP_RecordedLedger())
```
