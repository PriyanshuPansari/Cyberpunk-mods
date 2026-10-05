# Shard architecture and save behavior

The [README](README.md) is the current player guide. Training channels and
thresholds are described in [TRAINING_METHODS.md](TRAINING_METHODS.md).
The [original design draft](docs/history/PERK_SHARDS_V1.md) is historical.

## Ownership

A physical shard identifies a family/grade and occupies a processor bay.
The character owns per-grade XP and the highest sequentially recorded grade.
Only the next grade trains while physically installed. Effects accumulate
through recorded grades and the installed next grade; removing that grade
falls back to recorded effects. Recording returns the item and frees the bay.

Deadeye retains its own saved arrays for compatibility. Fourteen other
families plus Vehicle use the generic family arrays. Old virtual and
two-grade Deadeye fields remain for one-time migration.

## Package reconciliation

The mod applies private package clones instead of purchasing vanilla perks.
Generated provenance in `ShardPackageSources.generated.reds` maps every
clone to its original vanilla package. When that source package is already
active, reconciliation removes/suppresses the private clone. Existing vanilla
purchases and Relic data remain intact; no automatic respec is performed.

Native perk activation/deactivation triggers reconciliation, so refunding a
vanilla rank restores its shard copy only if the shard effect remains active.
Recording, equipment changes and save restoration also reconcile effects.
Custom effects without a vanilla source retain their separate ownership.

`IsNewPerkBought` returns the maximum of the purchased rank and shard-enabled
rank for script prerequisites. It does not itself apply packages. Package-free
behavior therefore needs explicit adapters where a purchase normally performs
a side effect.

## Chrome

License to Chrome rank 3 is one such scripted side effect. `ShardChrome.reds`
coalesces equipment refreshes and invokes native Skeleton side upgrades for
equipped base items. Recording retains access; removing an unrecorded shard
restores originals matched by side-upgrade link, stat record and random seed.
The third Skeleton slot unequips when access is lost. Purchased vanilla rank 3
keeps access even without the shard.

The native path keeps original items; the adapter does not delete originals
or invent replacements when matching fails. Existing modified saves without
the original require separate compatibility testing.

## XP and settings

The active channel implementation is `ShardChannels.reds`. The old flat-action
award functions are disabled for all current families, but some hooks still
measure v1 triggers or implement custom effects.

A channel applies its base limiter, then the family's configured XP scale,
then converts to whole XP with persistent fractional carry. The storage bridge
routes family 0 to Deadeye and 1-15 to generic storage. A 0% scale leaves both
carry and window budget untouched. Whole awards clamp to the current grade's
threshold; excess does not spill into the next grade.

Save restoration clamps existing progress to current caps; it does not
proportionally rescale progress when thresholds change. Already recorded
grades stay recorded. The damage target cache and time-window state are
session state; they are not persistent anti-farming guarantees.

## Implementation references

- [ALL_SHARDS.md](ALL_SHARDS.md): generator inputs, commands and family IDs.
- [Training v2](design/SHARD_TRAINING_V2.md): implementation versus proposals.
- [Regression checks](docs/REGRESSION_CHECKS.md): gameplay acceptance cases.
