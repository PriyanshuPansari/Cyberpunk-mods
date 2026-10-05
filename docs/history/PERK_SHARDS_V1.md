# Historical perk-shard design draft (superseded)

See [the current architecture](../../PERK_SHARDS.md) and
[player guide](../../README.md). Rules below are historical proposals.

The [15-family roster](../../design/SHARD_ROSTER.md),
[180-record ledger](../../design/perk-ledger.csv), and
[grade orders](../../design/SHARD_GRADE_ORDERS.md) are the design catalog.
They include installed-game perk IDs, rank packages, and proposed effect
allocation. Effect audits are still pending.
The [Deadeye grade order](../../design/DEADEYE_ORDER.md) is implemented. The old
two-grade prototype converts on save load; effect verification remains pending.

## Goal

Replace manual Primary perk spending with trainable skill shards. A shard
temporarily grants a defined set of perk effects while installed in a neural
processor. Qualifying use actions train that shard; skill experience remains
separate from shard attunement.
Once trained, its data can be recorded permanently, allowing the physical
shard to be swapped or replaced with an upgraded version.

Relic perks remain outside this system. The existing five skill-derived
attributes, Skill Rank, compatibility level, and Cyberware Capacity continue
to operate as they do now.

## Processor and shard roles

- Processor: one equipped cyberware item with multiple shard slots. Its model
  determines slot count and any specialization or training-speed bonus.
- Physical shard: an item assigned to a slot. It identifies a perk family
  and tier and enables training while slotted. The item does not own XP.
- Training progress: saved on the character under the shard family and tier.
  Replacing a shard with another copy of the same family and tier resumes
  the same progress. Different tiers have separate progress.
- Burned-in data: a completed tier permanently recorded on the character,
  independent of the physical shard and of processor swaps. Recording frees
  the shard slot. A higher burned-in tier supersedes the lower tier's
  effects without duplicating them.
- Only one copy of a perk package may be active, even if it appears on a
  physical shard, recorded data, or an old save's purchased perk.

Only one processor can be equipped. It can hold multiple shards at once.
Every burned-in effect remains active simultaneously, including when no
processor is installed. Processor slots limit how many unmastered shards
can be trained and used at once; they do not limit character mastery.

## Training

While a shard is installed, training receives two sources:

1. Experience earned in its linked skill, such as Headhunter for Deadeye.
2. Qualifying actions performed with its effect, such as damage or kills
   under Deadeye's actual conditions.

Action training remains available after a skill reaches level 60. It should
be awarded by meaningful events, with bounded values and deduplication for
multi-hit or damage-over-time events. Merely leaving a shard installed does
not train it.

Training progress belongs to the character's family-and-tier entry and
persists in saves. Recording requires that entry to reach its training
threshold and a separate burn-in action; it never spends a Primary perk
point. A different physical copy of the same shard can continue training
from that saved progress. Once recorded, the character owns that tier even
if the shard or processor is removed.

The save model is `masteredTier[family]` plus
`trainingXP[family, tier]`. The processor stores only its current physical
slot assignments. Thus replacing a Tier 1+ shard does not reset Tier 1+
training, and removing it exposes the already-mastered Tier 1 effect.

## Effects and upgrade rules

- Each shard tier declares exactly which vanilla `NewPerk` gameplay logic
  packages and custom packages it grants. The familiar perk name and theme
  come from the original tree; side effects and higher tiers can extend it.
- Apply packages through the game package system and remove only packages
  owned by this mod. Keep acquired effects separate from the vanilla
  purchased-perk state so perk refunds and point accounting stay correct.
- On any equipment, processor, save-load, or mastery change, reconcile the
  desired active package set with the packages actually applied. This makes
  transitions idempotent and prevents duplicate bonuses.
- Burned-in tiers stay in the desired active package set even without a
  processor. Temporary effects require their shard to be slotted.
- An upgraded shard in training may coexist with its recorded lower tier,
  but the highest active tier of a family determines effects. Recording the
  upgrade raises the character's mastered tier. Removing that shard before
  recording its upgrade falls back to the previously mastered tier.
- A perk that depends on script-side `IsNewPerkBought` checks needs a
  dedicated adapter; its gameplay package alone may be insufficient.

## First vertical slice: Deadeye

The installed game's CET inventory lists 180 records across the five
non-Relic perk trees (Body 33, Reflexes 37, Tech 34, Intelligence 38,
Cool 38), plus 13 Espionage/Relic records. Some entries may be obsolete;
the inventory is a planning count, not a promise that every record becomes
a separate shard. Deadeye is `NewPerks.Cool_Left_Milestone_3` and links to
Headhunter.

1. One processor and one Headhunter shard family.
2. Installing the shard grants the original Deadeye effect without a perk
   point or a visible purchase in the vanilla tree.
3. Qualifying Deadeye use trains the shard.
4. At the threshold, burning in Deadeye Tier 1 makes that tier character-owned
   and frees the physical shard slot.
5. Installing a Tier 1+ Deadeye shard gives its stronger effect while slotted.
   Removing it before burn-in restores Tier 1 and preserves the unfinished
   Tier 1+ progress on the character. Another Tier 1+ shard resumes there.
6. Burning in Tier 1+ raises the character's mastered tier. Changing the
   shard or processor, then loading a save, must preserve exactly one active
   version of the Deadeye effect.

After this slice works, represent other perk families as data and add custom
side effects only where the original packages do not cover the design.

## Compatibility and migration

- This system replaces Neuralware's processor and chip system. Do not edit
  Neuralware's files or reuse its assets. Use independent records,
  localization, save fields, and package ownership. Handle saves that have
  Neuralware items equipped when that mod is disabled.
- Existing purchased vanilla perks must be inventoried before disabling
  purchases. An old save's perks must not be silently deleted or duplicated.
- Relic perk purchases and effects remain untouched.
- Primary perk points are already blocked by the current mod. Old unspent
  points on existing saves require an explicit migration rule.

## Verification for the first slice

- Installing/removing the shard changes only its intended effects.
- Qualifying use advances training; skill XP and nonqualifying use do not.
- Recording frees the training slot, persists across save/load, and keeps
  one copy of the effect active even without a processor.
- Swapping processors and upgrading a family neither duplicates nor loses
  packages unexpectedly. An unmastered Tier 1+ shard restores mastered
  Tier 1 on removal, while keeping character-owned Tier 1+ progress.
- A different copy of the same family and tier resumes that progress.
- The UI shows processor capacity, current shard, training progress,
  recorded tier, and the actual active effects.

## Expansion plan (September 2026)

The new Deadeye Focus Tier 1 processor, physical shard, character-owned XP,
and burn-in are the first playable grade. Focus Tier 1+ now has its processor
upgrade, separate XP counter, two vanilla effect packages, and burn-in ready
for an in-game check. A data-driven version of the same rules is still needed
for every shard family. The
processor remains one default-equipped item with three training bays and a
separate Relic bay. The Relic keeps its native progression.

### Tier and mastery rules

- Follow the cyberware quality ladder: Tier 1, Tier 1+, Tier 2, Tier 2+,
  Tier 3, Tier 3+, Tier 4, Tier 4+, Tier 5, Tier 5+, and Tier 5++.
  These are eleven sequential mastery steps per family. The exact effects
  and XP thresholds for later steps need a package-by-package audit and
  balance pass; the tier structure is a proposal.
- Each step has a physical item, a component cost for an upgrade in the
  processor menu,
  a character-owned XP counter, and a character-owned recorded flag. XP is
  shared between copies of the same family and step. Upgrading an item never
  moves or resets XP.
- A character may train the next step after recording the previous one.
  The player can upgrade the physical shard directly from the processor
  shard menu, anywhere outside combat. The action consumes components of the
  *result* grade and changes it to the next step, like a cyberware upgrade.
  There are no crafting recipes. An equipped shard must be safely detached
  and reattached in its new form without losing a processor slot or its
  character-owned XP. Already-recorded effects survive upgrading, selling,
  or losing an item.
- Burn-in frees the training bay and returns the physical shard to inventory
  for upgrading. `RemovePart` returns an item ID that must be given back to
  the player. Old saves missing the Tier 1 shard receive one replacement.
- Each step supplies an effect delta. The active set contains all recorded
  lower deltas and the installed higher delta. Removing the higher shard
  keeps the lower recorded effects; recording it keeps its delta without a
  processor. Reconciliation must remove only mod-owned packages and must
  never stack two copies of one effect.
- The existing Deadeye Tier 1 save fields must migrate into the generic
  family/step data when that system replaces the prototype.

### Items, upgrades, inventory, and shops

1. The Focus/Deadeye chain and old-item conversion are implemented. Check
   the individual effects and recorded-grade behavior in game before treating
   the chain as verified.
2. Represent family and step in data. Generate item records, processor upgrade mappings,
   localization, icon assignment, training rules, and effect lists from the
   same catalog; avoid hand-writing 165 near-identical item scripts. Do not
   use the game's native `nextUpgradeItem` link for these shards: it allowed
   the Record button to promote the prototype shard unintentionally.
3. Add a `SkillDrivenProgression.Shard` item tag **and** a visible Shards
   inventory filter. The tag alone will not create a tab. Show family, grade,
   installed state, current XP/threshold, and recorded status. Keep the Relic
   in its dedicated bay rather than treating it as a purchasable skill shard.
4. Sell **base shards only** at shops. Higher steps come from upgrading
   that same shard in the processor menu, never from a recipe or vendor stock.
   Stock progression should use the linked skill or Skill Rank, never the
   obsolete native level as the design source.
5. Use existing game crafting-component grades for processor-menu upgrades. Define
   a cost curve after comparing vanilla component supply and cyberware
   upgrade costs; do not hard-code prices before that economy audit. Consume
   components only after the upgrade can be completed.

### Shard families

The installed CET inventory lists 180 non-Relic perk records. Organize them
into 15 core families, one for each of the three broad branches of each skill.
These are design families, not a promise that every listed perk package works
when copied: each record still needs an effect audit. The grade-order documents
specify the proposed first and later effects. Deadeye Tier 1 keeps its
existing tested bonus until the new order is implemented and saves migrate.

| Linked skill | Family | Branch effects | Action training |
| --- | --- | --- | --- |
| Solo | Adrenaline | Painkiller, Adrenaline Rush, Pain to Gain, recovery and survival perks | Recover health or withstand damage in combat |
| Solo | Obliteration | Die! Die! Die!, Spontaneous Obliteration, Rip and Tear, Onslaught | Shotgun and LMG damage, close-range finishers |
| Solo | Quake | Wrecking Ball, Quake, Savage Sling, blunt side perks | Blunt hits, knockdowns, blunt finishers |
| Shinobi | Air Dash | Slippery, Dash, Air Dash, Tailwind, movement side perks | Effective dashes and airborne combat actions |
| Shinobi | Sharpshooter | Ready, Rested, Reloaded, Sharpshooter, Salt in the Wound, Submachine Fun | Assault-rifle and SMG hits under relevant conditions |
| Shinobi | Blade Runner | Lead and Steel, Bladerunner finisher, Slaughterhouse | Blade deflections, hits, finishers |
| Engineer | Chrome | All Things Cyber, License to Chrome, Edgerunner, Chipware Connoisseur | Cyberware-triggered effects and meaningful combat use |
| Engineer | Pyromania | Health Freak, Pyromania, Doomlauncher, Ticking Time Bomb | Explosive damage and combat healing |
| Engineer | Bolt | Bolt, Chain Lightning, tech-weapon side perks and three proposed custom grades | Charged tech shots and Bolt hits |
| Netrunner | Overclock | Optimization, Embedded Exploit, Overclock, Spillover | Quickhack effects, RAM use, Overclock combat |
| Netrunner | Hack Queue | Eye in the Sky, Hack Queue, Queue Acceleration, Queue Mastery | Successful queued quickhacks and queue chains |
| Netrunner | Smart Lock | Acquisition Specialist, Target Lock Transfer, Smart Synergy | Smart-weapon lock transfers and hits |
| Headhunter | Deadeye | Focus, Deadeye, Nerves of Tungsten-Steel, Run 'N' Gun | Damaging hostile hits during Focus; later grades add precision hits and reloads |
| Headhunter | Ninjutsu | Feline Footwork, Ninjutsu, Vanishing Act, stealth side perks | Undetected movement and stealth takedowns |
| Headhunter | Juggler | Scorpion Sting, Juggler, Style Over Substance, throwable-weapon perks | Knife hits, poison follow-ups, retrieval chains |

### Usage XP design

Usage XP is awarded only while the matching physical shard is installed and
training. Linked skills progress independently and do not grant shard XP.
Recording a step stops XP for that step; upgrading starts a separate counter
for the next step. A source newly available at that step grants +2 XP, and
an earlier source grants +1 XP. Deadeye Focus Tier 1 begins with damaging
ranged hits during Focus; Tier 1+ adds headshots, weakspots, and completed
reloads after aimed neutralizations. Each attack/target pair is counted once; damage
over time, zero damage, friendly targets, and targets that do not award XP
give nothing. Repeated real hits on one enemy may each award XP.

For other families, use the same +2/+1 source credits and family thresholds
from `design/shard-training.json`. Award once per actual action and target, not
once per damage callback or animation frame. A cooldown alone must not
erase legitimate rapid attacks. Noncombat actions require a meaningful
result: Air Dash trains from a dash followed by an attack or avoided hit,
Ninjutsu from stealth neutralizations, Chrome from cyberarm damage, and Hack
Queue from damaging hacks while at least two are queued. Passive time,
repeated menu actions, empty dashes, and repeatedly toggling cyberware award
no XP. The current implemented sources for every family are listed in
`design/shard-training.json`; earlier speculative usage awards in this draft
were superseded by that catalog.

The first ledger assigns vehicle and cross-branch perks (Fury Road, Road
Warrior, Stuntjock, and Carhacker) as side effects and excludes the obsolete
Cool record. It maps **every** non-Relic perk record to one family or a
documented exclusion/review category. The next audit assigns each effect
and rank to a step and checks packages, `IsNewPerkBought` calls, native
behavior, and duplicate modifiers. That audited ledger is the definition of
"all shards covered," rather than merely creating 15 item names.

### Completion order

1. Deadeye Tier 1+ and generic mastery migration.
2. Processor-menu shard upgrading and component economy.
3. Record-level perk ledger and generated 15-family roster.
4. Shards inventory filter and complete processor tooltip/actions.
5. Base-shard vendor stock and skill-specific action training.
6. Balance and compatibility pass for saves with vanilla perk purchases.
