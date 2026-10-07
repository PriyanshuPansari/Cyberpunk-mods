# Historical v1: use-only shard progression

This flat-action balance document is retired. Current channels and thresholds
are in [../README.md](../README.md) and [SHARD_TRAINING_V2.md](SHARD_TRAINING_V2.md).
The following preserves the old model for save-history reference only.

Skill XP never enters shard attunement. A shard earns XP only from the actions
listed in its tooltip while it is the next unrecorded grade and is slotted.
XP and recorded effects remain on the character after removing the shard.
Already earned XP on existing saves is kept up to each new cap; a shard that
was above the new cap is immediately ready to record.

`shard-training.json` is the tuning source for action awards and thresholds.
`tools/GenerateShardTraining.py` produces the redscript values, and
`tools/GenerateProcessorText.py` produces the matching tooltip text.

## Pace

| Grade | Qualifying events targeted | XP with new source | XP with older sources only |
| --- | ---: | ---: | ---: |
| Tier 1 | 75 | 150 | — |
| Tier 1+ | 80 | 160 | 80 |
| Tier 2 | 85 | 170 | 85 |
| Tier 2+ | 90 | 180 | 90 |
| Tier 3 | 95 | 190 | 95 |
| Tier 3+ | 100 | 200 | 100 |
| Tier 4 | 110 | 220 | 110 |
| Tier 4+ | 120 | 240 | 120 |
| Tier 5 | 130 | 260 | 130 |
| Tier 5+ | 140 | 280 | 140 |
| Tier 5++ | 150 | 300 | 150 |

A source introduced at the current grade gives **2 XP**. A source introduced
at an earlier grade gives **1 XP**. Each grade needs twice its target action
count in XP when the family has a new source at that grade. If a family has
only older sources, its cap is the target action count. A qualifying event
awards at most once per shard family. A current-grade source takes priority
when the same event satisfies multiple sources. One event may train different
families. The Vehicle chip is one grade and needs 150 XP.

## Play observations for tuning

The table gives an exact count only when every trigger is a current-grade
source. During normal play, track
the family, grade, starting and ending XP, and what actions earned it. Pay
special attention to Deadeye's overlapping sources and families without a new
source at each grade. The global XP values and action targets are in
`shard-training.json`.
