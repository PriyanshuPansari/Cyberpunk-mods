# Deadeye shard: effect order

This is the implemented eleven-grade Headhunter shard. Each grade adds the listed
effect to every lower grade already recorded on the character. An unrecorded
grade works only while its shard is slotted. All eleven grades are implemented.
On load, the old two-grade prototype's recorded progress and items convert to
the current chain; its former packages are removed to prevent duplicate effects.

| Grade | New effects | Vanilla records and ranks |
| --- | --- | --- |
| Tier 1 | **Focus mode**: aim at full Stamina to enter Focus; shooting during it costs no Stamina. | `Cool_Left_Milestone_2` rank 2 |
| Tier 1+ | **Focus precision bonus** and **Rinse and Reload**. The first adds headshot and weakspot damage; the second rewards aimed neutralizations with faster reloading. | `Cool_Left_Milestone_2` rank 1; `Cool_Left_Perk_2_2` |
| Tier 2 | **Deep Breath** and **No Sweat**. Focus slows time and its ending Stamina cost decreases with neutralizations during Focus. | `Cool_Inbetween_Left_2`; `Cool_Left_Perk_2_4` |
| Tier 2+ | **Head to Head** and **Pull!**. A ranged neutralization refreshes Focus; shooting airborne grenades during Focus becomes more effective. | `Cool_Left_Perk_2_1`; `Cool_Left_Perk_2_3` |
| Tier 3 | **Deadeye mode**: while Stamina is high enough, precision damage rises and bullet spread is removed. | `Cool_Left_Milestone_3` rank 3 |
| Tier 3+ | **Deadeye precision bonus** and **Long Shot**. Adds the separate headshot/weakspot bonus and removes damage falloff during Deadeye. | `Cool_Left_Milestone_3` rank 1; `Cool_Left_Perk_3_3` |
| Tier 4 | **Quick Draw** and **California Reaper**. Weapon swaps restore Stamina in combat; precision neutralizations restore Stamina. | `Cool_Left_Perk_3_1`; `Cool_Left_Perk_3_4` |
| Tier 4+ | **High Noon**: a precision neutralization during Deadeye primes a faster, slowed-time reload. | `Cool_Left_Perk_3_2` |
| Tier 5 | **Deadeye shooting efficiency**: shooting costs less Stamina, making Deadeye easier to sustain. | `Cool_Left_Milestone_3` rank 2 |
| Tier 5+ | **Run 'N' Gun**: hip-fire uses no Stamina and Focus allows faster movement. | `Cool_Master_Perk_2` |
| Tier 5++ | **Nerves of Tungsten-Steel**: precision hits during Deadeye always crit and deal more damage at range. | `Cool_Master_Perk_1` |

This assigns all **16 non-vehicle vanilla rank effects** to eleven grades.
Five grades grant a pair of effects. Road Warrior belongs to a separate
Vehicle chip, which has one grade requiring 150 XP.

## Training XP

Deadeye uses v2 channels: precision-weapon damage from grade 1, with Focus,
precision-hit, Deadeye and range multipliers at the listed unlocks; later
grades add airborne-grenade shots and combat weapon swaps. Reloads no longer
award training XP. The current conditions are in
[TRAINING_METHODS.md](../TRAINING_METHODS.md), and thresholds are centralized in
[README.md](../README.md) (60 XP at Tier 1, 2730 at Tier 5++).

The old per-source CET breakdown remains a historical diagnostic; the channel
overlay/log shows current awards. Component upgrade costs remain 20 through
110. Grade effects below are independent of these XP conditions.

## Why this order

- A useful, reliable precision bonus arrives at Tier 1+, while Focus-specific
  benefits come only after Focus exists. Focus duration renewal waits until
  Tier 2+ because it can keep the mode active through a kill streak.
- Deadeye itself is the Tier 3 landmark. Its range and damage bonuses follow;
  the Stamina tools arrive before the later reload and shooting-efficiency
  grades. Each grade has a reason to upgrade even if a niche event never
  happens.
- Nerves of Tungsten-Steel has the strongest offensive payoff, so it is the
  final grade. Run 'N' Gun remains valuable at Tier 5+ for both hip-fire and
  Focus movement.

## Implementation and migration notes

- The order intentionally separates vanilla milestone ranks. Focus rank 2
  appears before rank 1, and Deadeye rank 3 before ranks 1 and 2. Implement
  effect deltas independently; do not use the game's normal perk purchase
  sequence. Focus and Deep Breath have script-side perk checks that need
  adapters, beyond copying their readable packages.
- The proposed +10% Focus bonus, +10% Deadeye bonus, and -25% shooting Stamina
  cost must be confirmed from live TweakDB values before writing numeric
  tooltips. The localized descriptions use parameters rather than literal
  values.
- Existing prototype mastery and partial XP now map to the first two grades
  of this chain on save load. The prototype's old packages are removed and its
  items converted. This intentionally changes the exact early effects on
  prototype test saves: recorded prototype Tier 1 becomes recorded Focus,
  and prototype Tier 1+ becomes recorded Focus Precision/Rinse and Reload.
- Audit the Focus, Deadeye, and side-perk activation checks and package
  ownership. Returning a vanilla milestone rank for an early mode unlock
  must not grant the later passive bonuses early or show false perk purchases.
