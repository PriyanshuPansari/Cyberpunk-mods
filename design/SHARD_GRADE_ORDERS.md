# Proposed grade order for the fifteen skill shards

Each table is an **effect delta**: recording a grade keeps its effects when
the physical shard or processor is removed. Every family has eleven grades:
Tier 1, 1+, 2, 2+, 3, 3+, 4, 4+, 5, 5+, and 5++. A number after a perk name
means that specific vanilla rank. Names and exact `NewPerks` IDs are in the
[perk ledger](perk-ledger.csv). [Deadeye](DEADEYE_ORDER.md) has its own
detailed table; the fourteen other skill chains are below.

These design orders are mapped into deployed shard packages and perk-rank
adapters. Individual effects still need gameplay verification, especially
those with script checks or equipment-layout changes. Numerical strengths
and component costs need a later balance pass. Each grade should feel useful to its intended
build; upgrades do not increase every branch's damage by the same amount.

## Solo

### Adrenaline

Start with survival, unlock Adrenaline Rush at Tier 3, then improve its
duration, damage, control resistance, and kill reward. Bloodlust belongs here
because its effect explicitly requires Adrenaline Rush.

| Grade | New effects |
| --- | --- |
| Tier 1 | Painkiller: slow Health regeneration in combat. |
| Tier 1+ | Adrenaline Rush 1: more maximum Health. |
| Tier 2 | Speed Junkie + Comeback Kid: stronger regeneration while moving or wounded. |
| Tier 2+ | Adrenaline Rush 2: boost all Health regeneration sources. |
| Tier 3 | Adrenaline Rush 3: Blood Pump and Health Items can grant Adrenaline. |
| Tier 3+ | Dorph-head: mitigation after Blood Pump or a Health Item. |
| Tier 4 | Army of One: regeneration improves near enemies. |
| Tier 4+ | Calm Mind + Bloodlust: delay Adrenaline decay and gain Adrenaline from nearby dismemberments. |
| Tier 5 | Juggernaut: move faster and deal more damage during Adrenaline Rush. |
| Tier 5+ | Unstoppable Force: ignore movement penalties and non-damaging status effects during Adrenaline Rush. |
| Tier 5++ | Pain to Gain: neutralizations during Adrenaline Rush recharge Health Items. |

### Obliteration

Build the low-Stamina shotgun/LMG style before unlocking Obliterate. Give
shotgun and LMG users their separate capstones together at the last grade.

| Grade | New effects |
| --- | --- |
| Tier 1 | Die! Die! Die! 1: Stamina regeneration. |
| Tier 1+ | Die! Die! Die! 2: handling improves as Stamina falls. |
| Tier 2 | Bullet Ballet + Like a Feather: mobile firing and weapon movement. |
| Tier 2+ | Spontaneous Obliteration 1: Crit Chance rises as Stamina falls. |
| Tier 3 | Spontaneous Obliteration 3: unlock Obliterate on weakened enemies. |
| Tier 3+ | Spontaneous Obliteration 2 + Don't Stop Me Now: close-range damage and defense at low Stamina. |
| Tier 4 | Rush of Blood: faster reload after dismemberment. |
| Tier 4+ | Skullcracker: stronger Quick Melee at low Stamina. |
| Tier 5 | Dread: ranged attacks reduce enemy Armor; dismemberment spreads it. |
| Tier 5+ | Close-quarters Carnage: more ranged Obliterate chance up close. |
| Tier 5++ | Rip and Tear + Onslaught: shotgun/Quick Melee damage loop or LMG ammo refill on neutralization. |

### Quake

Enable the blunt charge first, Quake itself at Tier 3, and its midair and
multi-target rewards later. Two early Stamina-cost ranks may overlap; the
packages must be checked for intended stacking.

| Grade | New effects |
| --- | --- |
| Tier 1 | Wrecking Ball 1: lower blunt-attack Stamina cost. |
| Tier 1+ | Wrecking Ball 2: sprint-block charge that can knock enemies down. |
| Tier 2 | Fly Swatter + Kinetic Absorption: ranged blocking defense and Stamina/damage from blocks. |
| Tier 2+ | Clapback: stronger knockdown and stun counterattacks. |
| Tier 3 | Quake 3: ground or midair slam. |
| Tier 3+ | Quake 1 + Quake 2: lower blunt Stamina cost and faster blunt attacks. |
| Tier 4 | Breakthrough: strong attacks lower enemy Armor. |
| Tier 4+ | Aftershock: regain Stamina per enemy hit by Quake. |
| Tier 5 | Epicenter: midair Quake scales with fall speed and distance. |
| Tier 5+ | Ripple Effect: gain Health per enemy hit by Quake. |
| Tier 5++ | Finisher: Savage Sling: finish or throw a weakened enemy. |

## Shinobi

### Air Dash

Dash arrives at Tier 1+ and Air Dash at Tier 3. Mobility and survivability
build before the final stamina-free Air Dash loop.

| Grade | New effects |
| --- | --- |
| Tier 1 | Slippery: faster movement makes you harder to hit. |
| Tier 1+ | Dash 2: unlock Dash. |
| Tier 2 | Dash 1 + Power Slide: cheaper Dash/dodge and longer slides. |
| Tier 2+ | Muscle Memory + Parkour!: reload while moving and vault or climb faster. |
| Tier 3 | Air Dash 3: unlock midair Dash. |
| Tier 3+ | Air Dash 1 + Air Dash 2: cheaper and faster Dashes. |
| Tier 4 | Can't Touch This + Mean Streak: mitigation during Dash and longer Dashes toward enemies. |
| Tier 4+ | Steady Grip + Multitasker: fire during Dash and other movement actions. |
| Tier 5 | Aerial Acrobat + Aerodynamic: midair control and mitigation. |
| Tier 5+ | Mad Dash: Stamina after a neutralization while Dashing. |
| Tier 5++ | Tailwind: Air Dashes cost no Stamina and restore it. |

### Sharpshooter

The family covers assault rifles and SMGs. Sharpshooter stacks start at Tier
3; its stack-scaling bonuses follow. The two capstones split across the last
two grades, with the general consecutive-hit reward last.

| Grade | New effects |
| --- | --- |
| Tier 1 | Ready, Rested, Reloaded 1: cheaper AR/SMG shooting. |
| Tier 1+ | Ready, Rested, Reloaded 2: faster reload at high Stamina. |
| Tier 2 | Spice of Life + Mind Over Matter: faster swaps, less spread, less aimed recoil. |
| Tier 2+ | Sharpshooter 1: faster aim. |
| Tier 3 | Sharpshooter 3: successful shots build Sharpshooter stacks. |
| Tier 3+ | Sharpshooter 2 + Practice Makes Perfect: handling and Crit bonuses as stacks build. |
| Tier 4 | Tunnel Vision + Gundancer: effective range, mobile aiming, and vault shooting. |
| Tier 4+ | Spray and Pray + Air Kerenzikov: cheaper hip-fire and a midair Kerenzikov option. |
| Tier 5 | Shoot to Chill: Armor penetration per Sharpshooter stack. |
| Tier 5+ | Submachine Fun: SMG swaps auto-reload and briefly improve fire rate. |
| Tier 5++ | Salt in the Wound: consecutive shots on the same target trigger bonus damage. |

### Blade Runner

Projectile block comes first, its deflection upgrades second, and the Blade
Finisher at Tier 3. Every later finisher bonus therefore has its prerequisite.

| Grade | New effects |
| --- | --- |
| Tier 1 | Lead and Steel 1: cheaper blade attacks. |
| Tier 1+ | Lead and Steel 2: block projectiles with a Blade. |
| Tier 2 | Bullet Deflect + Seeing Double: aimed deflections and stronger counterattacks. |
| Tier 2+ | Bullet Time: enhanced deflections while time is slowed. |
| Tier 3 | Finisher: Bladerunner 3: unlock Blade Finisher. |
| Tier 3+ | Finisher: Bladerunner 1 + 2: cheaper and faster Blade attacks. |
| Tier 4 | Flash and Thunderclap: leap toward enemies on Strong Attacks. |
| Tier 4+ | Opportunist: more enemies become susceptible to Finishers. |
| Tier 5 | Going the Distance: longer Finisher reach. |
| Tier 5+ | Flash of Steel: speed after a Finisher. |
| Tier 5++ | Slaughterhouse: attacks and deflections apply Bleeding to set up Finishers. |

## Engineer

### Chrome

This chain changes capacity and cyberware slots, so each structural perk
needs a dedicated adapter. Renaissance Punk must use **skill levels**, not
old attribute thresholds; its exact replacement threshold and Capacity
amount remain to be balanced. Edgerunner stays the final risk/reward grade.

| Grade | New effects |
| --- | --- |
| Tier 1 | All Things Cyber 1: stronger cyberware stat modifiers. |
| Tier 1+ | All Things Cyber 2: lower Capacity cost for Integumentary and Skeleton cyberware. |
| Tier 2 | Driver Update + Lucky Day: extra cyberware modifier and more looted components. |
| Tier 2+ | License to Chrome 1: further cyberware stat modifiers. |
| Tier 3 | License to Chrome 3: additional Skeleton slot and Skeleton stat boost. |
| Tier 3+ | License to Chrome 2 + Extended Warranty: Armor and longer cyberware effects. |
| Tier 4 | Ambidextrous: additional Hands slot. |
| Tier 4+ | Built Different: unlock and support Cellular Adapter. |
| Tier 5 | Renaissance Punk + Chipware Connoisseur: skill-derived Capacity and cyberware upgrade choices. |
| Tier 5+ | Chrome Constitution + Cyborg: rewards for filled cyberware slots. |
| Tier 5++ | Edgerunner: exceed Capacity at a Health cost. |

### Pyromania

Build Health Item and grenade supply first, activate Pyromania on explosion
hits at Tier 3, then add defenses and grenade/Projectile Launch System loops.
The final EMP depends on activating Operating System cyberware or Overclock.

| Grade | New effects |
| --- | --- |
| Tier 1 | Glutton for War: extra Health Item charge and recharge. |
| Tier 1+ | Health Freak 1 + First Aid: faster item and grenade recharge. |
| Tier 2 | Health Freak 2 + Transfusion: recharge on neutralization and stronger final Health Item charge. |
| Tier 2+ | Demolitions Surplus + Coming in Hot: more grenade supply and recharge. |
| Tier 3 | Pyromania 3: explosion hits build Pyromania movement/damage stacks. |
| Tier 3+ | Pyromania 1 + 2: recharge and explosion-radius bonuses. |
| Tier 4 | Friendlier Fire + Doomlauncher: resist your own explosions; grenade perks also help Projectile Launch System. |
| Tier 4+ | Borrowed Time + Field Medic: emergency item recovery and faster combat use. |
| Tier 5 | Heat Shield + Burn This City: stack-based mitigation and grenade replenishment. |
| Tier 5+ | Flash Sale: greater Flash, Smoke, and Recon grenade supply. |
| Tier 5++ | Ticking Time Bomb: delayed EMP on Operating System or Overclock activation. |

### Bolt

The Tech-weapon branch has only **eight** non-vehicle vanilla rank effects.
Three grades below are proposed custom effects, not existing perks. Gearhead
is assigned to the separate vehicle shard. Custom values need live balancing.

| Grade | New effects |
| --- | --- |
| Tier 1 | Bolt 1: faster Tech-weapon charging. |
| Tier 1+ | Bolt 2: more charged-shot damage. |
| Tier 2 | In Charge: holding full charge no longer auto-fires. |
| Tier 2+ | **Custom:** damaging fully charged Tech shots restore 2 Stamina. |
| Tier 3 | Bolt 3: unlock timed Bolt shots. |
| Tier 3+ | Internal Clock: wider timing window for a Bolt. |
| Tier 4 | Shock Value: Bolt shots ignore Armor. |
| Tier 4+ | Lightning Storm: repeated Bolts accelerate charging. |
| Tier 5 | **Custom:** Tech weapons gain 5% headshot damage while this grade is active. |
| Tier 5+ | **Custom:** a fully charged Tech-shot neutralization restores 5 Stamina. |
| Tier 5++ | Chain Lightning: Bolt deals Electrical damage and arcs to nearby enemies. |

## Netrunner

### Overclock

Make ordinary quickhacking better before enabling Health-for-RAM Overclock
at Tier 3. Health recovery and high-risk damage then develop together.

| Grade | New effects |
| --- | --- |
| Tier 1 | Optimization: RAM recovery. |
| Tier 1+ | Embedded Exploit 1 + Encryption: RAM recovery and lower traceability. |
| Tier 2 | Embedded Exploit 2 + Proximate Propagation: damage on prepared targets and cheaper close-range hacks. |
| Tier 2+ | ICEpick + Subordination: prepared Combat hacks cost less; Control hacks last longer. |
| Tier 3 | Overclock 3: spend Health to quickhack without enough RAM. |
| Tier 3+ | Overclock 1 + 2: RAM recovery and quickhack damage. |
| Tier 4 | Speculation + System Overwhelm: RAM refund on Combat-hack neutralizations and damage from layered effects. |
| Tier 4+ | Shadowrunner + Blood Daemon: Takedowns reduce trace; queued hacks on an Overclock victim restore Health. |
| Tier 5 | Race Against Mind + Power Surge: low-Health damage and Health on Overclock activation. |
| Tier 5+ | Sublimation: RAM recovery also regenerates Health during Overclock. |
| Tier 5++ | Spillover: hacks can spread during Overclock. |

### Hack Queue

Unlock the queue first, then its RAM economy, size, and upload speed. The
internal `Queue Hack_Root` record is excluded pending an effect audit; all
sixteen other non-vehicle rank effects fit exactly.

| Grade | New effects |
| --- | --- |
| Tier 1 | Hack Queue 2: unlock ordered quickhack queues. |
| Tier 1+ | Hack Queue 1 + Eye in the Sky: Max RAM and camera/Access Point utility. |
| Tier 2 | Data Recycler + Feedback Loop: refund unused queued hacks and recover RAM while queuing. |
| Tier 2+ | Queue Prioritization: faster upload at the start of a populated queue. |
| Tier 3 | Queue Acceleration 3: larger, faster late queue. |
| Tier 3+ | Queue Acceleration 1 + 2: Max RAM and cheaper device/vehicle hacks. |
| Tier 4 | Warning: Explosion Hazard + ForceKill Cypher: device explosion and Access Point bonuses. |
| Tier 4+ | Copy-Paste + Counter-a-hack: counter hostile netrunners and spread a counterhack. |
| Tier 5 | Siphon: Monowire attacks restore RAM. |
| Tier 5+ | Finisher: Live Wire: Monowire Finisher improves with queued hacks. |
| Tier 5++ | Queue Mastery: larger queue and a powerful final-slot reward. |

### Smart Lock

The first four grades support any Smart-weapon user. Some later vanilla perks
require a cyberdeck or Overclock; their grades need a modest standalone
fallback so upgrading still matters without those systems. The fallback
effects are proposals and need their own implementation and balance pass.

| Grade | New effects |
| --- | --- |
| Tier 1 | Acquisition Specialist 1: larger Smart-weapon targeting area. |
| Tier 1+ | Acquisition Specialist 2: keep locks on reload and lock faster. |
| Tier 2 | No Escape: shooting a target can renew a fading lock. |
| Tier 2+ | Precision Subroutines: accuracy scales with Max RAM; **custom fallback:** small flat accuracy bonus without a cyberdeck. |
| Tier 3 | Target Lock Transfer 2: keep head/weakspot lock between aiming and hip-fire. |
| Tier 3+ | Target Lock Transfer 1: further enlarge the target area. |
| Tier 4 | Target Lock Transfer 3: keep locks when swapping Smart weapons. |
| Tier 4+ | Recirculation: RAM after Smart-weapon neutralization; **custom:** Smart-weapon neutralizations also restore 5 Stamina. |
| Tier 5 | Terminal Velocity: Smart-weapon neutralizations improve projectile speed and range. |
| Tier 5+ | Smart Synergy: instant lock and bonus damage during Overclock; **custom:** a small passive lock-speed bonus. |
| Tier 5++ | Targeting Prism: lock multiple targets while aiming. |

## Headhunter

### Ninjutsu

Unlike Focus, its two passive ranks naturally precede the Tier 3 ability.
Vanishing Act requires Optical Camo; the final grade works from stealth even
when Optical Camo is absent.

| Grade | New effects |
| --- | --- |
| Tier 1 | Feline Footwork: faster, safer crouched movement. |
| Tier 1+ | Ninjutsu 1: crouch movement speed. |
| Tier 2 | Unexposed: mitigation while aiming from cover. |
| Tier 2+ | Ninjutsu 2: mitigation while crouched. |
| Tier 3 | Ninjutsu 3: unlock crouch-sprinting. |
| Tier 3+ | Small Target: mitigation while crouched and still. |
| Tier 4 | Blind Spot: crouched mitigation delays detection. |
| Tier 4+ | Serpentine: mitigation while crouch-sprinting. |
| Tier 5 | Shinobi Sprint: cheaper crouch-sprinting in combat. |
| Tier 5+ | Vanishing Act: Optical Camo activates while crouch-sprinting or sliding. |
| Tier 5++ | Creeping Death: stealth neutralizations restore Health/Stamina and grant speed. |

### Juggler

Poison and throwable recovery arrive early, the Juggler reset at Tier 3,
then finishers and guaranteed thrown Crits close the chain. The three
records with unreadable packages need script or effect adapters.

| Grade | New effects |
| --- | --- |
| Tier 1 | Killer Instinct: stronger knives, axes, and silenced guns outside combat. |
| Tier 1+ | Scorpion Sting 1 + Gag Order: faster throwable recovery and delayed group detection. |
| Tier 2 | Scorpion Sting 2 + Corrosion: precision throws apply Poison, including to machines. |
| Tier 2+ | Neurotoxin + Accelerated Toxin Absorption: control Poisoned enemies and cash out Poison with a hit. |
| Tier 3 | Juggler 3: qualifying thrown neutralizations reset throwable cooldowns. |
| Tier 3+ | Juggler 1 + 2: faster recovery and more precision damage. |
| Tier 4 | Parasite + Quick Getaway: thrown precision hits heal; stealth neutralizations grant speed. |
| Tier 4+ | Pay It Forward + Sleight of Hand: reward retrieved throws and Juggler activation. |
| Tier 5 | Finisher: Act of Mercy: Throwable Weapon Finisher. |
| Tier 5+ | Pounce: longer Finisher reach after a thrown hit. |
| Tier 5++ | Style Over Substance: guaranteed thrown Crits during skilled movement. |

## Vehicle shard boundary

Road Warrior, Fury Road, Stuntjock, Carhacker, and Gearhead belong to **one
single-tier vehicle chip**, outside the fifteen eleven-grade skill chains.
The chip will train from qualifying vehicle use and keep all five effects
after recording. Equipment-specific parts, such as Carhacker's cyberdeck
quickhacks, activate only when their equipment is present. The `linked_skill`
field in the ledger still records each vehicle perk's original tree; it is
not the vehicle chip's XP rule. Its exact vehicle-use XP events and threshold
remain to be designed before implementation.

## Implementation gates

1. Audit each grade's readable package, script checks, conditional equipment,
   and actual UI text before enabling it. For ranks deliberately out of
   vanilla order, grant only the listed delta and preserve old-save mastery.
2. Implement structural effects directly: cyberware slots, cyberware upgrade
   choices, crouch-sprinting, Dash/Air Dash, Focus, Overclock, queues, and
   finishers cannot be assumed to work from a copied modifier package alone.
3. Resolve the excluded internal queue record. Confirm whether repeated Stamina/cyberware stat packages
   stack as intended.
4. Tune custom Bolt and Smart Lock fallbacks and the use XP/component
   curve after the effects exist. Do not display numeric tooltips for values
   that have not been measured or configured.
