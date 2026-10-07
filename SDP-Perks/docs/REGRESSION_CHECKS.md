# Progression regression checks

The review fixes require both source validation and gameplay checks. Passing
redscript lint does not verify native equipment requests or stat behavior.

## Automated

Run `python tools/VerifyProgression.py` from the project root. It checks clone
provenance against generator inputs, runtime/documentation threshold consistency,
and the specialist comparison table. Regenerate family assets, training docs,
and processor localization before rerunning if those inputs change.

Lint the mod's scripts with `redscript-cli lint`, the installed vanilla
`r6/cache/final.redscripts` as the bundle, and TweakXL's `Scripts` directory as
an additional source. The vanilla bundle alone lacks `TweakDBManager`.

## In-game: XP settings

On an unrecorded installed grade, compare identical direct channel awards:

```lua
local d=PlayerDevelopmentSystem.GetData(Game.GetPlayer()); d:SDP_TuningSetXPScale(1,0); print(d:SDP_ChannelAward(1,11,1,false))
```

Use a family actually installed (0 = Deadeye; 1-15 = developer reference IDs).
At 0% repeated calls must award nothing. With a fresh zero carry, 50% of 1 XP
must award 0 then 1; 100% awards 1; 500% awards 5, unless the grade reaches its
cap. Repeat with `windowed=true` and verify the configured scale multiplies
the base capped budget. Save between fractional awards and check carry survives.
Restore the chosen setting through Native Settings afterward.

Also verify real damage, timed, resource and event actions at 0%, 50%, 100%
and 500%; skill XP should be unaffected by the shard setting.

## In-game: existing purchased perks

Use an existing save with a stat-based perk overlapping a shard (for example
Adrenaline Rush rank 1). Compare the stat and applied GLPs before slotting,
after slotting, after recording, and after reload. There must be one source
of that bonus: the vanilla GLP, with the corresponding private clone absent.

Refund the purchased rank while its shard is active/mastered: the private
clone must take over. Remove an unrecorded shard: the clone must disappear;
the purchased perk must survive when it still exists. Test Deadeye separately,
including a save from the old mod with both packages already present. Check
Relic purchases/refunds still behave normally.

## In-game: Chrome

1. With Chrome recorded through grade 4 and no vanilla License to Chrome 3,
   equip two Skeleton cyberwares with known quality and rolled stats.
2. Install Chrome grade 5. After queued equipment updates, verify both native
   boosted versions and the third slot. Reconcile repeatedly: no extra boost
   or item copies should accumulate.
3. Equip a third Skeleton item, then remove the unrecorded shard. Slots 0/1
   should restore their exact original rolls; slot 2 should unequip. Re-slot
   the shard and check it works again.
4. Record grade 5, remove the processor and reload: boosted versions must stay.
5. Repeat with purchased vanilla rank 3: removing the shard must retain access.
6. Change/upgrade Skeleton items while Chrome is active; verify replacement
   callbacks converge, and rapid processor changes do not leave a stale boost.

If an original item is missing or does not match the boosted item's stats,
the adapter does not manufacture a guessed replacement. Include such modified
saves in compatibility testing; ordinary native upgrades retain their originals.

## Scope

Also smoke-test a new game, legacy Deadeye migration, all three processor bays,
record/upgrade actions and other installed mods. This checklist is not a record
that the in-game cases have already passed.
