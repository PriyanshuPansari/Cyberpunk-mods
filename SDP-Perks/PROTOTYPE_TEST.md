# Deadeye perk-shard prototype (historical test notes)

The current physical shard progression is documented in `ALL_SHARDS.md`.
Skill XP no longer trains any shard; only qualifying use actions do.

This first slice tests the save state and perk effect before creating physical
processor and shard items. The processor has three virtual slots controlled
through CET. Shard ID `1` is Deadeye Tier 1; `0` is an empty slot. The
attunement threshold is 150 prototype XP. Damaging ranged headshots and
weakspot hits on enemies
that award experience add 2 prototype XP per matching hit flag (4 when both
match). Damage-over-time ticks and repeated events from the same attack on
one target do not add training. `hitXP` in the status shows this combat-use
portion separately. `SDP_PrototypeAddUseXP` remains available as a manual
diagnostic hook.

Disable Neuralware in Vortex for this test and deploy SkillDrivenProgression.
Restart the game so redscript and TweakXL load the prototype. Use a save that
has not bought Deadeye through the vanilla tree, and do not save over a main
save while testing.

Run the following in CET one line at a time. If output is delayed in
`scripting.log`, run `error('flush')` as a separate command.

```lua
d=PlayerDevelopmentSystem.GetInstance(Game.GetPlayer()):GetDevelopmentData(Game.GetPlayer()); print(d:SDP_PrototypeStatus(), d:IsNewPerkBought(gamedataNewPerkType.Cool_Left_Milestone_3))
print(TweakDB:GetRecord('SkillDrivenProgression.DeadeyePrototypeTier1'))
d:SDP_PrototypeEquipProcessor(true); print(d:SDP_PrototypeSlotDeadeye(0), d:SDP_PrototypeStatus(), d:IsNewPerkBought(gamedataNewPerkType.Cool_Left_Milestone_3))
print(d:SDP_PrototypeAddUseXP(60), d:SDP_PrototypeStatus())
print(d:SDP_PrototypeUnslot(0), d:SDP_PrototypeStatus(), d:IsNewPerkBought(gamedataNewPerkType.Cool_Left_Milestone_3))
print(d:SDP_PrototypeSlotDeadeye(1), d:SDP_PrototypeStatus())
print(d:SDP_PrototypeAddUseXP(90), d:SDP_PrototypeStatus())
print(d:SDP_PrototypeBurnDeadeye(), d:SDP_PrototypeStatus())
d:SDP_PrototypeEquipProcessor(false); print(d:SDP_PrototypeStatus(), d:IsNewPerkBought(gamedataNewPerkType.Cool_Left_Milestone_3))
```

Expected: XP remains 60 after the shard is removed, and the different
copy in slot 1 resumes from 60. Burn-in succeeds at 150 XP, empties the
slot, and keeps Deadeye active after the processor is removed. The
`IsNewPerkBought` value is 0 before slotting, 1 while slotted, 0 when an
unmastered shard is removed, and 1 after burn-in. The prototype's private
Deadeye package record must exist. The status line's `package` value should
match `active` at each step; this checks that the gameplay effect package is
actually applied, rather than merely showing the perk as bought.

Save and reload this test save once to confirm
that XP, slot assignment, and burn-in persist. To check combat-use XP, record
`hitXP`, land a damaging ranged headshot or weakspot hit on a live enemy, and
check `hitXP` again. A body shot should leave `hitXP` unchanged. For now the
prototype does not expose inventory items, a ripperdoc slot, or upgraded tiers.
