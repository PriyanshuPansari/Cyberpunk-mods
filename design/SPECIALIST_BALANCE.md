# Specialist-friendly world progression (superseded proposal)

Superseded on 2026-10-01 by the [world progression plan](WORLD_PROGRESSION_PLAN.md).
The new direction expands world threat, equipment and combat systems to support
the mod's larger mastery ceiling. It does not fit that ceiling back into vanilla
level 1-60. The comparisons below are retained as historical analysis only.

No gameplay formula has been changed by this proposal. Current behavior is
documented in [README](../README.md).

## Problem

World progression currently averages five skills. A character at
`60, 1, 1, 1, 1` has compatibility level 12 and PowerLevel 12.8 despite mastery
of their main skill. This also keeps their level-based XP multiplier low, so
shard mastery can take longer than the XP model's assumed trajectory.

Changing only `SkillTotalLevel.reds` is insufficient: the independent
`SkillDrivenPowerLevel.yaml` also derives PowerLevel from all five skills.

## Options

Sort the skill levels descending as `a >= b >= c >= d >= e`. Values below
are integer world levels before the installed game's maximum-level cap.

| Skill levels | Current average | Highest skill | Top-two average | Weighted top three |
| --- | ---: | ---: | ---: | ---: |
| 1, 1, 1, 1, 1 | 1 | 1 | 1 | 1 |
| 20, 1, 1, 1, 1 | 4 | 20 | 10 | 14 |
| 40, 20, 10, 1, 1 | 14 | 40 | 30 | 33 |
| 60, 1, 1, 1, 1 | 12 | 60 | 30 | 42 |
| 60, 30, 15, 1, 1 | 21 | 60 | 45 | 49 |
| 60, 60, 1, 1, 1 | 24 | 60 | 60 | 54 |
| 60, 60, 60, 1, 1 | 36 | 60 | 60 | 60 |
| 20, 20, 20, 20, 20 | 20 | 20 | 20 | 20 |
| 60, 60, 60, 60, 60 | 60 | 60 | 60 | 60 |

- **Highest skill:** `a`. Strongest support for pure specialists, but one
  easily farmed skill determines all world scaling and other skills add no level.
- **Top-two average:** `(a+b)/2`. Suits two-skill builds; still pushes pure
  specialists to adopt a second skill, which can make the original problem recur.
- **Weighted top three (previous proposal):** `0.70*a + 0.20*b + 0.10*c`.
  The main skill does most of the work, a second helps, and a third closes the
  remaining gap. The two least-used skills are optional for world level.

Under that previous proposal, use the fractional value as PowerLevel and its floor
as compatibility level, both capped consistently. Compute the weighted value
from integer tenths (`(7*a + 2*b + c)/10`) to avoid rounding below boundaries.
Keep Skill Rank as total skill progress, with both concepts explained in UI.

## Tradeoffs to test

Higher world level also changes health, enemy scaling and the XP multiplier;
this is not a loot-only boost. Verify a specialist can handle the resulting
encounters before raising the main-skill weight above 70%.

Keep attributes tied to their matching skill. For the first balance trial,
keep the current direct-skill Capacity contribution too, making breadth useful
for cyberware budget even when it is no longer needed for equipment tiers.
That means the 60/1/1/1/1 specialist still contributes only 38.4 Capacity from
skills. If this prevents viable builds, test a separate capacity formula:
`0.6*S` blended with `3*weightedPowerLevel`, rather than silently changing it
alongside world level. Both agree at all-equal skills but differ for specialists.

An alternative scope is to raise only vendor/loot access using the strongest
skill while retaining current enemy scaling. That requires auditing individual
level/PowerLevel consumers; a single Level-stat change cannot safely isolate loot.

## Trial and acceptance criteria

Compare a precision specialist, Tech shotgun hybrid, netrunner and broad build
at early, middle and late skill distributions. Record world level, enemy time
to kill, incoming damage, item tiers, capacity and shard XP per combat minute.
Use the same equipment and difficulty when comparing formulas.

Check monotonicity on every skill increase, exact 1/60 endpoints, stable
save/load values, and that changing which skill is strongest causes no drop.
Re-fit the shard-XP model using actual resulting levels; its present player-level
trajectory is an assumption. Existing saves need an explicit migration note
because the proposed formula can raise world level immediately.
