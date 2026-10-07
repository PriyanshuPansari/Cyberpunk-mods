# Current shard training: channels v2

This describes the implemented system. The original proposal is preserved in
[history](../docs/history/SHARD_TRAINING_V2_DRAFT.md). The
[README](../README.md) owns player-facing instructions and the threshold table.

## Sources of truth

- `r6/scripts/SkillDrivenProgression/ShardChannels.reds`: runtime channel rates,
  conditions, limiters and thresholds.
- `design/shard-channels.json`: matching descriptions and thresholds used for
  tooltips and the generated [training reference](../TRAINING_METHODS.md).
- `tools/ShardXPModel.py`: planning model using captured native curves/fights;
  its outputs are estimates, not runtime code.
- `design/shard-training.json`: retired v1 actions, retained for old source
  IDs/diagnostics. It no longer controls current XP awards.

Runtime thresholds and the JSON mirror must agree; `VerifyProgression.py`
checks them. Editing the model does not automatically change gameplay.

## Implemented channels

See [TRAINING_METHODS.md](../TRAINING_METHODS.md) for every family and unlock.
Damage scales with target health share, target PowerLevel/rarity and the player
XP multiplier. Other channels pay for qualifying time, resources or events.
Grades unlock channels or raise multipliers rather than introducing flat +2/+1
source awards. Multiple installed families can qualify from the same action;
for example a Tech shotgun can train both Bolt and Obliteration.

Time/event/resource channels share a per-family 10-second base budget. Damage
uses a bounded target/family cache. The configured family multiplier applies
after these base limits, followed by persistent fractional carry and the
current grade's storage cap. At 0%, XP pauses without clearing carry.

Ninjutsu Shadow is the time-channel exception to combat-only training:
crouching before combat must have a qualifying NPC, camera or turret within
20 metres. One spot pays for five seconds; moving more than three metres
resets that timer. A zone alone is insufficient. Cameras/turrets currently
qualify without checking their power or attitude.

## Known boundaries

Per-target damage bookkeeping is session-local and bounded to 160 entries;
it is not a lifetime target cap. Kill/flag events use their current callbacks
and the shared window cap. Full per-action deduplication across every damage
callback still needs gameplay auditing.

The draft's additional ideas (Savage Sling-specific XP, counter-hack events,
grenade-throw Supply XP, poison tick/retrieval events, lock-transfer bonuses,
and other unimplemented multipliers) are not promised by the current guide.
The generated reference follows the implemented channel descriptions.

Existing v1 source counters remain in logs for comparison and custom-effect
hooks still run, but the v1 award path returns zero. Skill XP is independent.
