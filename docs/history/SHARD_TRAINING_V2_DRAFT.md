# Historical training v2 proposal (superseded)

The implemented subset is documented in
[the current training guide](../../design/SHARD_TRAINING_V2.md).
The following is a preserved proposal, not a list of verified features.

## Why

v1 gives every shard 6 separate training methods ("sources"), each worth a flat
2 or 1 XP per event, unlocked one by one by grade. That is hard to balance (the
shotgun pays per pellet), hard to fulfil (Adrenaline s2), and does not scale.

The base game trains skills differently: a few **channels** that pay XP in
proportion to *how much* happened (share of an enemy's health you took, damage
you absorbed, RAM you spent), scaled by enemy level, with limiters against
farming. v2 copies that for shards.

## Model

- Each shard has **2-3 channels** taken straight from what its perks do.
- **Channel XP = rate x magnitude x multipliers**, with fractions carried over.
  - *Damage magnitude* (like native): share of the target's max Health dealt, x
    target level factor, x rarity (weak 0.5 ... boss 2). A shotgun blast pays
    the same whether 1 or 12 pellets hit.
  - *Time magnitude*: seconds in a qualifying state (checked every 0.5 s).
  - *Resource magnitude*: % of max Health lost/absorbed, RAM spent, etc.
  - *Event magnitude*: 1 per event (dash, finisher, item use), with a cooldown.
- **Perks (grades) only change numbers**: a grade either unlocks a channel or
  multiplier, or raises one (for example "+10% channel XP per grade past
  unlock"). No new method lists per grade.
- **Limiters**: per-channel XP cap per second and per target (like the game's
  "ExpHarvested" limiters).
- Grade thresholds (150 XP at Tier 1 ... 300 at Tier 5++) stay; channel rates
  are tuned from the encounter logs (target: Tier 1 in about 5 fights of the
  shard's playstyle).
- Every channel and multiplier is logged, so the encounter log shows where XP
  came from.

## Channels per shard

Grades: 1 = Tier 1, 2 = Tier 1+, 3 = Tier 2 ... 11 = Tier 5++.

| Skill | Shard | Channels (magnitude) | Multipliers / unlocks from perks |
|---|---|---|---|
| Solo | **Adrenaline** | **Endurance**: seconds in combat below max Health (Painkiller); **Punishment**: % max Health lost to hits you survive | Moving/sprinting x1.5 (g3 Speed Junkie); under 50% Health x2 (g3 Comeback Kid); x hostiles within 20 m, max 4 (g7 Army of One) |
| | | **Adrenaline**: Health item / Blood Pump use in combat (event) + % max Health of Adrenaline absorbed by hits (g5 Adrenaline Rush 3) | Absorbed Adrenaline x2 (g9); kill while Adrenaline is up = bonus event (g11 Pain to Gain) |
| Solo | **Obliteration** | **Carnage**: shotgun/LMG damage share | Close range <8 m x1.5 (g3); low Stamina x1.25 (g4); target already wounded up to x2 (g5); Obliterate kill bonus event (g5); dismemberment bonus (g7) |
| Solo | **Quake** | **Impact**: blunt/fist damage share; **Bulwark**: damage blocked with a blunt weapon | Knockdown bonus event (g2); Quake slam: x enemies hit (g5); Strong attack x1.25 (g7); *new:* Savage Sling finisher/throw event (g11) |
| Shinobi | **Air Dash** | **Mobility**: dashes/dodges in combat (event, 1 s cooldown); *new:* slides, vaults and climbs in combat (Power Slide / Parkour!, g3-g4) | Air dash x1.5 (g5); dash toward an enemy or a hit within 2 s x2 (g7); kill within 2 s of a dash bonus (g10) |
| Shinobi | **Sharpshooter** | **Suppression**: AR/SMG damage share | Consecutive hits on the same target up to x1.5 (g5 stacks); range >=25 m x1.25 (g7); headshot/weakspot x1.1 |
| Shinobi | **Blade Runner** | **Steel**: blade damage share; **Deflection**: bullets deflected (event) (g2) | Finisher bonus event (g5); Strong-attack leap x1.25 (g7); Bleeding target x1.25 (g11) |
| Engineer | **Chrome** | **Chrome**: cyberarm damage share; **Overdrive**: seconds with Sandevistan/Berserk/Optical Camo/*Kerenzikov* active in combat | Projectile Launch System hits x1.5 (g7); Health spent above Capacity (g11 Edgerunner) |
| Engineer | **Pyromania** | **Blast**: explosion damage share; **Supply**: grenade thrown / Health item used in combat (event) | x enemies hit per explosion, max 4 (g5 stacks); range >=15 m x1.25 (g7) |
| Engineer | **Bolt** | **Charge**: Tech-weapon damage share, x charge level (full charge x1.5) | Timed Bolt shot x1.5 (g5); Armor-ignoring hit x1.25 (g7); arc to extra enemies (g11) |
| Netrunner | **Overclock** | **Payload**: quickhack damage share; **Upload**: RAM spent on quickhacks | Health spent via Overclock x2 (g5); layered effects on target x1.25 (g7) |
| Netrunner | **Hack Queue** | **Queue**: RAM of quickhacks queued behind another (2nd, 3rd, 4th slot x1 / x1.5 / x2) | Device/camera/Access Point hacks and *Breach Protocol* (g2-g3); counter-hacking an enemy netrunner event (g8); Monowire damage share (g9 Siphon); final queue slot bonus (g11) |
| Netrunner | **Smart Lock** | **Tracking**: Smart-weapon damage share | Locked target x1.25 (g3); range >=25 m x1.25 (g7); multi-target lock hits (g11) |
| Headhunter | **Ninjutsu** | **Shadow**: seconds crouched/crouch-sprinting within 20 m of unaware hostiles; **Silent**: stealth damage share (native 0.7) | In cover x1.25 (g3); crouch-sprint x1.5 (g5); *new:* Optical Camo from crouch-sprint/slide (g10); takedown/stealth kill bonus (g11) |
| Headhunter | **Juggler** | **Throw**: thrown knife/axe damage share; *new:* **Killer Instinct**: silenced-gun and knife damage on unaware targets | Headshot/weakspot x1.5 (g3); Poisoned target x1.25 (g3); retrieved throw event (g8); finisher bonus (g9) |
| Headhunter | **Deadeye** | **Precision**: pistol/revolver/sniper/precision-rifle damage share (*new:* always, not only in Focus) | In Focus x1.25 (g1); headshot/weakspot x1.5 (g2); Deadeye mode x1.5 (g5); range >=25 m x1.25 (g6); weapon swap in combat event (g7); airborne grenade shot event (g4) |
| - | **Vehicle** | **Road**: vehicle-weapon damage share | Drifting/airborne x1.5 |

## Review of the channel list (2026-10-01)

Gaps found and filled (marked *new* above): Deadeye had no XP for pistols,
revolvers and snipers outside Focus; Air Dash ignored slides, vaults and climbs
(native Shinobi pays for them); Juggler had nothing for its Killer Instinct
side (silenced guns and knives on unaware targets); Hack Queue ignored
Breach Protocol and counter-hacks; Chrome ignored Kerenzikov; Ninjutsu ignored
its Optical Camo perk; Quake ignored its Savage Sling finisher.

Every combat weapon class now feeds exactly one shard (shotgun/LMG/HMG
Obliteration; blunt/fists Quake; AR/SMG Sharpshooter; blades Blade Runner;
cyberarms Chrome; explosives Pyromania; Tech Bolt; quickhacks Overclock; Smart
Smart Lock; Monowire Hack Queue; thrown Juggler; precision guns Deadeye;
vehicle weapons Vehicle). Non-combat play (crafting, exploration) trains no
shard, by design.

Numbers (rates, grade thresholds, limiters, boss handling) are in
`SHARD_XP_MODEL.md`. Three shards train at once (processor slots).

## Rollout

1. Build the shared engine (damage-share and time/resource channels, multipliers,
   limiters, carry-over, logging).
2. Pilot **Adrenaline** and **Obliteration**; one test run; tune the rates.
3. Convert the other 14 shards; regenerate `TRAINING_METHODS.md` from the new
   channel definitions.
