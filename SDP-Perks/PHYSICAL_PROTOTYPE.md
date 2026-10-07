# Neural processor and Deadeye shard: historical first physical slice

The two-grade shard described below is retired. Existing saves convert its
recorded grades, partial XP, and shard copies to the current Focus/Deadeye
chain on load. The old packages no longer activate.

This slice adds a separate processor socket to the Eyes cyberware area, one
starter processor item with three training-shard slots, a dedicated Relic bay,
and one Deadeye Tier 1 shard. The starter costs no cyberware capacity and is
granted and equipped automatically once per character on new and existing saves.
If the player later removes it, the mod does not grant another copy.
After the game marks the Relic as acquired, an inert representation is placed
in the Relic bay. The game's quest item and Relic abilities are unaffected.
The shard uses the tested Deadeye package. Its XP and burn-in state remain on
the character; replacing the physical shard copy does not reset training.
Once a physical processor is equipped, the save switches from the old virtual
processor controls to physical item state. An already recorded Deadeye remains
recorded and active. The old virtual fields are retained only for save
compatibility.

The extra socket is appended at game startup by the mod's CET script. Keep
Neuralware disabled, deploy the Vortex mod, and restart the game. Test on a
separate save. The UI uses the native cyberware/attachment screen.

Select the equipped Neural Processor in the cyberware screen and press R3 to
open its shard inventory. The same action works from the regular inventory's
processor tile. It uses the game's cyberware modification screen, with three
training bays and a separate Relic bay. The mod currently supplies one shard
family for this menu. To give the character a Deadeye shard for the prototype,
run `d:SDP_PhysicalGrantDeadeyeShard()` in CET once. Slot and remove the shard
through the inventory screen; the character's Deadeye XP persists.
Hover the Deadeye shard in the processor inventory to see its current
character-owned Attunement XP out of 150 and whether it is ready to record.
The Deadeye shard and Relic module use the game's own Relic chip image from
the Heist UI atlas. Their names and effects remain separate.

Deadeye Tier 1 earns attunement from qualifying damaging ranged hits:
+2 for a headshot and +2 for a weakspot, including
both on the same hit. At 150 XP, highlight the installed shard and use the
**Record Deadeye Tier 1** action. The effect then belongs to the character,
the bay is freed, and the physical shard returns to inventory. Old saves
where burn-in lost that item receive one replacement when loaded.

Highlight the returned shard in the processor's available list and use
**Upgrade to Tier 1+**. This can be done from the processor menu outside
combat without a ripperdoc. It costs 20 Tier 1 components. Install the new
Tier 1+ shard to gain its added effect temporarily. Its separate 0/80 XP
counter gains +1 XP from each earlier qualifying-hit source. The
record action at 80 XP makes that added effect permanent. Removing Tier 1+
before recording leaves the already recorded Tier 1 effect active.

The processor icon uses an existing base-game icon also used by one of
Neuralware's processors. Neuralware's original assets are not bundled.

After loading, allow a few seconds for the automatic equipment request. Run
each CET line separately.

```lua
d=PlayerDevelopmentSystem.GetInstance(Game.GetPlayer()):GetDevelopmentData(Game.GetPlayer()); print(d:SDP_PrototypeStatus())
print(TweakDB:GetRecord('SkillDrivenProgression.NeuralProcessor'), TweakDB:GetRecord('SkillDrivenProgression.DeadeyeTier1Shard'), TweakDB:GetRecord('SkillDrivenProgression.RelicModule'))
print('processor', d:SDP_PrototypeStatus())
print('shard granted', d:SDP_PhysicalGrantDeadeyeShard())
print('slotted', d:SDP_PhysicalSlotDeadeye(0), d:SDP_PrototypeStatus())
print('unslotted', d:SDP_PhysicalUnslotDeadeye(), d:SDP_PrototypeStatus())
print('reslotted', d:SDP_PhysicalSlotDeadeye(1), d:SDP_PrototypeStatus())
```

Expected: without a grant/equip command, status includes
`mode=physical processor=true`. `relic=true` appears on saves after Relic
acquisition and remains false before that point.
Slotting shows `slots=1,0,0`, `active=true`, `package=true`. Unslotting
removes the temporary effect unless Deadeye was already recorded. Reslotting
shows `slots=0,1,0` and retains the same DeadeyeXP. Qualifying hits continue
to train it. At 150 XP, run:

```lua
print('recorded', d:SDP_PrototypeBurnDeadeye(), d:SDP_PrototypeStatus())
```

Expected: all shard slots are empty, `burned=true`, `active=true`, and
`package=true`. Removing the processor after recording keeps the effect.
If the test save already recorded Deadeye, the shard cannot be slotted again;
use a save from before recording to check temporary slotting and training.

This slice does not yet supply shop stock, custom implant screen art, or
other shard families. The processor actions still need an in-game UI check.
