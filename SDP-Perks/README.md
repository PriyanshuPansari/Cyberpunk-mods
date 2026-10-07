> **SDP Perks.** Since 2026-10-06 SkillDrivenProgression is split into separate repos (see SDP-Core's README). This
> repo is the perk system: the neural processor, perk shards, Deadeye, shard training, the encounter XP log and
> overlay, and the shard tree. It keeps the original folder names (`r6/scripts/SkillDrivenProgression`,
> `r6/tweaks/SkillDrivenProgression`, CET mod `SkillDrivenProgression`) so the generators and existing settings keep
> working. Requires **SDP-Core**. The sections below on skills, milestones, cigarettes, capacity/passive/scanner
> sliders and crafting describe parts that now live in SDP-Skills, SDP-Patches and SDP-QuickhackCrafting.
>
> **Do not deploy the new parts alongside the old all-in-one `SkillDrivenProgression` Vortex mod.** Both define the
> same functions, so redscript would fail to compile. Disable the old mod first (see SDP-Core's README, "Switching over").

# SkillDrivenProgression

Cyberpunk 2077 progression through five skills and trainable physical perk
shards. This is the current player guide. The flat +2/+1 shard-XP model and
two-grade Deadeye prototype are retired.

## Install and update

Requires **redscript, TweakXL, ArchiveXL, and Cyber Engine Tweaks**. CET adds
the processor socket and provides configuration/logging. **Native Settings UI**
is optional for sliders; default values work without it. Disable Skillful
Attributes and Neuralware while using this mod.

For this local Vortex setup, run `tools/Sync-ToVortex.ps1`, then **Deploy Mods**
and restart the game. Vortex deploys its staging copy, not this source folder.
The sync script also installs the bundled Custom Quickslots cigarette patch
when Custom Quickslots is present; reapply after updating it.

## Skills, attributes and world level

The five native skills retain their ordinary XP sources. Ordinary character
XP no longer raises level. Manual attribute allocation and new Attribute/Primary
point awards are disabled; Relic points remain available. Existing purchased
perks are preserved; an equivalent active vanilla package suppresses the shard's
private copy. Existing unspent Primary points are not migrated or cleared.

| Skill | Derived attribute | Base passive |
| --- | --- | --- |
| Solo | Body | Health |
| Shinobi | Reflexes | Critical chance |
| Engineer | Technical Ability | Armor |
| Netrunner | Intelligence | RAM |
| Headhunter | Cool | Critical damage |

Let `S` be the sum of all five skill levels (each normally 1-60).

- **Skill Rank**, shown in the level UI: `S - 4` (1-296).
- **Compatibility level**: `1 + floor((S - 5) / 5)`, capped by the installed
  game's level limit. Used by systems reading the Level stat.
- **PowerLevel**: `S / 5`, continuously updated through stat modifiers. Used
  by systems such as health and world/item scaling; separate from Level.
- **Attribute**: `3 + 17 * (linked skill - 1) / 59` (3-20).
- **Skill contribution to Cyberware Capacity**: `1.00 * S` by default (S = sum of the five skill levels).
  Other capacity sources and cyberware costs remain in effect.

The Skill Rank bar shows total skill levels gained out of 295, not next-level
XP. Attributes remain for dialogue and requirements. The generated stat patch
redirects attribute-reading modifiers to matching skill-derived proxies.
English cyberware attunement text names the linked skill.

These implemented formulas favor breadth. The [SDP Combat backend plan](design/WORLD_PROGRESSION_BACKEND.md)
is the preferred next step: our own combat rules using native actions and selected
existing mod components, with separate specialist equipment access. Earlier lite
and full-world plans are references; the new backend is not implemented yet.

## Processor and shard loop

The zero-capacity starter Neural Processor equips once per character. It has
three training bays and one Relic bay. The Relic representation does not change
native Relic progression. Select the processor and press R3 / the game's
`install_quickhack` action to open its modification inventory.

1. Buy a base shard from a netrunner vendor and install it.
2. Earn XP through its training channels. Only the next unrecorded grade trains;
   ordinary skill XP never feeds shard XP.
3. At the threshold, select the installed shard and **Record** it. Its effects
   become permanent, the bay is freed, and the shard returns to inventory.
4. Select the recorded physical shard and **Upgrade** it with components,
   outside combat. Install the next grade and repeat.

Fifteen skill families have eleven grades (Tier 1 to Tier 5++). Vehicle has one.
Only base shards are sold. XP and mastery belong to the character; replacement
copies resume progress. Removing an unfinished grade retains XP and restores
recorded lower effects. Recorded effects work without a processor.

Result grades 2-11 cost 20, 30, 40, ... 110 components of the result tier.
There are no shard crafting recipes.

Chrome Tier 3 uses a script adapter for License to Chrome's Skeleton boost.
It upgrades equipped Skeleton cyberware through native side upgrades. Losing
temporary access restores matching originals and unequips the extra Skeleton
slot. Purchased vanilla License to Chrome rank 3 keeps that access.

## Current shard training: channels (v2)

Training pays for damage, qualifying time, resources, and specific events.
Damage uses enemy health share, PowerLevel and rarity. All channels use the
player's `XPbonusMultiplier`. Grades unlock channels or change multipliers;
**there is no flat +2/+1 rule**.

| Grade | Tier | XP to record |
| --- | --- | ---: |
| 1 | 1 | 60 |
| 2 | 1+ | 110 |
| 3 | 2 | 150 |
| 4 | 2+ | 210 |
| 5 | 3 | 300 |
| 6 | 3+ | 430 |
| 7 | 4 | 610 |
| 8 | 4+ | 870 |
| 9 | 5 | 1260 |
| 10 | 5+ | 1830 |
| 11 | 5++ | 2730 |

Vehicle needs 150 XP. [Training methods](TRAINING_METHODS.md) lists channels
and grade unlocks; [ALL_SHARDS.md](ALL_SHARDS.md) lists family IDs and commands.

Time/event/resource channels share a per-family budget of 28 base XP times
the player's XP multiplier per 10 simulation seconds. Damage channels instead
track up to 100% health share per target/family in a bounded session cache.
Ninjutsu Shadow trains before combat near qualifying watchers; one spot pays
for five seconds, and moving over three metres resets it.

## Settings and logs

The **Skill Driven Progression** Native Settings tab has separate 0-500%
shard-XP sliders for all sixteen families. Scaling applies **after the base
limiter**, to every channel. Fractional channel XP carries across actions and
saves. At 0%, awards pause without clearing XP or fractional carry. These
sliders do not scale native skill XP.

Five passive sliders adjust only the built-in bonuses in the first table.
Capacity changes the per-skill-level contribution. Scanner sliders set time
scale at Netrunner levels 1 and 60 with interpolation between; lower values
slow time more. CET saves settings in its mod's `settings.json`.

Enable **Show XP overlay** or bind CET's **Toggle XP overlay**. It shows
skill/shard totals for the current or last encounter and recent shard awards.
Channel award lines show actual integer XP and progress; fractional-only awards
do not produce a line.

Encounters remain open for 60 seconds after combat ends. CET writes
`encounters.log` and `encounters.csv` under the game's
`bin/x64/plugins/cyber_engine_tweaks/mods/SkillDrivenProgression/`.
Channel triggers use source IDs 11 onward. Old v1 triggers remain diagnostic
counters, not extra XP. [XP model](design/SHARD_XP_MODEL.md) fight counts are
planning assumptions, not verified playthrough guarantees.

## Skill milestones

Level 35 doubles the level-15 total. These follow skill levels automatically;
they grant no perk points, shard XP or slots.

| Skill | Level 15 | Level 35 total |
| --- | --- | --- |
| Solo | +5% combat stamina regeneration | +10% |
| Shinobi | -5% sprint/dash stamina cost | -10% |
| Engineer | -5% cyberware cooldowns | -10% |
| Netrunner | -5% quickhack upload time | -10% |
| Headhunter | -5% aiming weapon sway | -10% |

## Cigarettes

Use Custom Quickslots' **Consumable Animations → Cigarettes** slot with the
bundled patch; the mod adds no key binding of its own. Smoking is blocked
in combat. New characters receive five Yeheyuan and five Morley once. These
are misc items, not health-booster-slot items.

Smoking grants five minutes of **Composure**: +10% native skill XP and 15%
less recoil kick/base spread on the equipped weapon. Smoking again refreshes
the timer. Consumable Animations is optional for animation; with it installed,
matching vanilla cigarettes also count. Disable Dark Future to avoid overlap.

## Maintenance and reference

- [Developer reference](ALL_SHARDS.md): family IDs, CET commands, generators.
- [Architecture and saves](PERK_SHARDS.md): ownership and persistence rules.
- [Regression checklist](docs/REGRESSION_CHECKS.md): automated and in-game checks.
- [Component crafting prototype](docs/PROTOTYPE_CRAFTING.md): opt-in two-rule quickhack programs, spreading and weapon behaviors; setup and gameplay checks.
- [Quickhack primitives and lab](design/QUICKHACK_PRIMITIVES.md): build-4 native spreading, component inspection, core reconstruction and ordered tests.
- [Training implementation](design/SHARD_TRAINING_V2.md): active sources and limitations.
- [SDP Combat backend](design/WORLD_PROGRESSION_BACKEND.md): preferred implementation plan combining selected features.
- [World progression lite](design/WORLD_PROGRESSION_LITE.md): superseded external-backend proposal and integration constraints.
- [Local implementation audit](design/WORLD_PROGRESSION_SOURCE_AUDIT.md): verified integration points and limitations.
- [Long-term world design](design/WORLD_PROGRESSION_PLAN.md): deferred threat, AI and equipment systems.
- [Mod research](design/WORLD_PROGRESSION_MOD_RESEARCH.md): feature candidates, permissions and integration choices.
- Historical prototype notes: [virtual](PROTOTYPE_TEST.md), [physical](PHYSICAL_PROTOTYPE.md).

Regenerate affected outputs before syncing. Localization changes require
`tools/BuildArchive.ps1` with WolvenKit CLI 8.17.x. `GenerateSkillLinks.ps1`
rebuilds attribute links from a fresh `SDPFIND` inventory in CET's scripting log.

`Launch-LatestSave.cmd` starts the latest complete save; close the game first.
It reads saves without editing them. In Vortex use `C:\Windows\System32\cmd.exe`
as Target, `/c Launch-LatestSave.cmd` as Command Line, and this source folder
as Start In. Leave Run in Shell and Run Detached off.

## Shard tree (CET)

Bind CET's **Toggle shard tree** hotkey. A window lists every shard family by
skill tab (Solo, Shinobi, Engineer, Netrunner, Headhunter with their levels,
and General for Vehicle and Expansion chips), one button per grade:
green = recorded, amber = slotted and training (with XP), blue-grey = next
grade to slot, dark = later. Hover a grade (CET overlay open) for what it
grants.
