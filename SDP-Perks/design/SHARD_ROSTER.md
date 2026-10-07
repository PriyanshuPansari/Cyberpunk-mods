# Skill shard roster: first pass

This is the design inventory for the 15 skill-linked non-Relic shard families. It is based
on the installed game's September 28, 2026 CET dump, not on a remembered perk
list. [perk-ledger.csv](perk-ledger.csv) assigns every one of the 180 non-Relic
`NewPerks` records to a family or an explicit exclusion/review category and
records the package ID for each vanilla rank. The game has 13 additional
Espionage/Relic records; they remain with the Relic and are not in this ledger.

The assignment is **provisional**. The ledger describes where a vanilla perk
belongs thematically. It does not assert that cloning its package is enough
to reproduce it. Many perks also depend on script-side purchased-perk checks,
special equipment slots, or other records.
The [grade orders](SHARD_GRADE_ORDERS.md) and the separate
[Deadeye order](DEADEYE_ORDER.md) assign effects to every skill-shard grade.
The vehicle family is a separate single-tier chip. Its current use XP comes
from damaging hostiles with vehicle weapons.

## Shared design

- Fifteen base shards exist, one per family. Vendors sell base shards only.
  Upgrades consume components in the processor menu outside combat; they do
  not need a ripperdoc or a crafting recipe.
- Each family has one character-owned mastery chain through Tier 1, 1+, 2,
  2+, 3, 3+, 4, 4+, 5, 5+, and 5++. The physical shard can be replaced or
  upgraded without moving its XP. A tier can train only after the preceding
  tier has been recorded. Recording is a separate action and frees its bay.
- The grade-order documents define the proposed Tier 1 effect and every later
  delta for each family. They may intentionally place an ability before its
  vanilla passive ranks, as the Deadeye design does. Saves using the old
  two-grade Deadeye prototype convert once to the new chain on load.
- Each tier grants a **delta** of effects. The desired active set is the union
  of every recorded delta and the currently installed unrecorded delta. A
  delta is applied once, regardless of copies owned. Removing an unrecorded
  shard removes its delta and keeps all recorded deltas. This matches the
  Deadeye prototype's two separate packages and avoids double bonuses.
- Grades through Tier 5++ distribute the family's support milestones, side
  perks, bridges, and capstones as proposed in the grade-order documents.
  Exact gameplay delivery still requires the effect and prerequisite audit.
- The three processor bays train at most three families simultaneously. All
  recorded effects remain active with no processor equipped. A family may
  occupy only one training bay at a time, including duplicate item copies.
- Character-owned XP trains only the installed next grade; skill XP is separate.
  Current channels and thresholds are centralized in
  [TRAINING_METHODS.md](../TRAINING_METHODS.md) and [README.md](../README.md).
  XP clamps to the current grade, without spilling into later grades.

## Fifteen base shards

The Tier 1 column reflects the current effect order. Names in the late-effect column identify effects to audit,
not an assurance that their packages work in isolation.

| Linked skill | Family | Proposed Tier 1 | Later signature/capstone |
| --- | --- | --- | --- |
| Solo | Adrenaline | Painkiller (`Body_Central_Milestone_1`) | Adrenaline Rush, Pain to Gain |
| Solo | Obliteration | Die! Die! Die! rank 1 (`Body_Left_Milestone_2`) | Obliterate, Rip and Tear, Onslaught |
| Solo | Quake | Wrecking Ball rank 1 (`Body_Right_Milestone_2`) | Quake, Savage Sling |
| Shinobi | Air Dash | Slippery (`Reflexes_Central_Milestone_1`) | Air Dash, Tailwind |
| Shinobi | Sharpshooter | Ready, Rested, Reloaded rank 1 (`Reflexes_Left_Milestone_2`) | Sharpshooter, Salt in the Wound |
| Shinobi | Blade Runner | Lead and Steel rank 1 (`Reflexes_Right_Milestone_2`) | Bladerunner finisher, Slaughterhouse |
| Engineer | Chrome | All Things Cyber rank 1 (`Tech_Central_Milestone_2`) | License to Chrome, Edgerunner |
| Engineer | Pyromania | Glutton for War (`Tech_Left_Milestone_1`) | Pyromania, Ticking Time Bomb |
| Engineer | Bolt | Bolt rank 1 (`Tech_Right_Milestone_3`) | Bolt shots, Chain Lightning |
| Netrunner | Overclock | Optimization (`Intelligence_Central_Milestone_1`) | Overclock, Spillover |
| Netrunner | Hack Queue | Hack Queue rank 2 (`Intelligence_Left_Milestone_2`) | Queue Acceleration, Queue Mastery |
| Netrunner | Smart Lock | Acquisition Specialist rank 1 (`Intelligence_Right_Milestone_2`) | Target Lock Transfer, Targeting Prism |
| Headhunter | Deadeye | Focus mode (`Cool_Left_Milestone_2` rank 2) in the proposed order | Deadeye mode, Run 'N' Gun, Nerves of Tungsten-Steel |
| Headhunter | Ninjutsu | Feline Footwork (`Cool_Central_Milestone_1`) | Ninjutsu, Vanishing Act, Creeping Death |
| Headhunter | Juggler | Killer Instinct (`Cool_Right_Milestone_1`) | Juggler, Style Over Substance |

`NewPerks.` prefixes are omitted in the table. The ledger carries full IDs
and exact rank package IDs. Ability and prerequisite checks must be audited
as part of the ongoing effect audit.

## XP implementation

The active channel contract is [SHARD_TRAINING_V2.md](SHARD_TRAINING_V2.md).
The old flat event awards and result-only proposals are superseded. Runtime
channels include combat locomotion, qualifying time, resource costs and damage.

## Mapping and exceptions

- Road Warrior, Fury Road, Stuntjock, Carhacker, and Gearhead belong to a
  separate single-tier vehicle chip, outside the fifteen skill-linked chains.
  Vehicle damage trains it; its single grade requires 150 XP.
- `Cool_Right_Perk_3_3` displays `!OBSOLETE` and is excluded. The
  `Intelligence_Left_Perk_3_1` display name is `Queue Hack_Root`; keep it in
  the ledger as an internal dependency review, not a purchasable side perk.
- Seventeen records have at least one rank with no readable `DataPackage`
  ID in the CET dump. Thirty-one records appear in direct
  `IsNewPerkBought(gamedataNewPerkType.X)` checks in the decompiled scripts
  (48 direct call sites). Both sets need adapters or effect-specific handling
  before we claim the original perk is present. The direct call count is a
  lower bound because some scripts pass a variable rather than a literal.
- Structural perks require special care. Examples: Built Different and
  Ambidextrous affect cyberware layout; Chipware Connoisseur affects
  cyberware upgrades; Ninjutsu, Focus, and several quickhack perks include
  script behavior outside their readable package. A shard tooltip must
  describe the effect the mod actually grants, not just copy the vanilla
  perk name.

## Remaining effect audit

All fifteen families, vendor items, package mappings, and use XP listeners
are implemented. Individual perk effects still need a normal-play audit,
especially equipment-slot changes, upgrade choices, and effects with
script-side prerequisites. Current training descriptions are in
`shard-channels.json`; gameplay testing must establish actual progression pace.

The official [Update 2.0 notes](https://www.cyberpunk.net/en/news/49060/update-2-0)
describe the redesigned perk trees and marquee abilities. The exact IDs,
names, level counts, and package inventory here come from the installed
game's CET and decompiled script data.
