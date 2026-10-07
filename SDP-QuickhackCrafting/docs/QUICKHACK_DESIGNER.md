# Quickhack Designer (Build 10)

Design quickhacks from the mod's primitives in a CET window, compile them into
program chips, install the chips in your cyberdeck, and use them from the
game's own scanner quickhack wheel. They have a RAM cost, upload time and
cooldown, just like native quickhacks.

Build 10 replaces the Build 9 workbench window. The sandbox and native lab
tools are still available on the window's **Lab** tab.

## Install

Deploy the whole `SDP-QuickhackCrafting` folder, then restart the game.

- `r6/scripts/SDPQuickhackCrafting/*.reds`, including the new `CustomPrograms.reds`
  and `CustomProgramRecords.reds`.
- `r6/tweaks/SDPQuickhackCrafting/*.yaml`, including the new `CustomPrograms.yaml`.
- `bin/x64/plugins/cyber_engine_tweaks/mods/SDPQuickhackCrafting/*.lua`, including the
  new `designer.lua` and `quickhack_designs.lua`.

You need redscript, CET and TweakXL. The chip actions are finished at load by
a TweakXL **scriptable tweak** (`SDPQHProgramTweak`), so TweakXL must be a
version that runs `ScriptableTweak` classes. `tools/Sync-ToVortex.ps1` copies
these folders. It does not overwrite your design library.

The CET binding **Quickhack designer: toggle window** keeps the old binding ID,
so an existing workbench hotkey still works. Open the CET overlay to use the mouse.

## Workflow

1. **Designer tab.** The library on the left starts with the starter designs
   (the lab presets that use only designed primitives). Your old saved
   blueprint (`prototype-recipe.json`), if any, is imported once as "(imported)".
   Pick a design or click **New**, then edit it on the right:
   - **Primary rule**: trigger, effect, condition, duration, and for damage
     effects the damage and pulse interval.
   - **Secondary rule** (optional): the same controls.
   - **Program**: lifetime (15/30/60 s) and spread on upload (0-3 nearby enemies).

   The readout shows complexity, RAM, upload time, cooldown, compile cost and a
   plain-language description. Edits save automatically to
   `quickhack-designs.json` in the CET mod folder. This file is shared by all
   your saves.
2. **Compile into a program slot.** Click **A**, **B**, **C** or **D** under
   the readout. Compiling costs quickhack components (see below) and stores
   the design in the current save. You can recompile a slot at any time; the
   chip runs whatever is compiled into it.
3. **Program slots tab.** Click **Fabricate chip** for the slot. It costs 10
   uncommon quickhack components, and the chip lands in your inventory.
   The tab shows each slot's design, RAM, upload time, cooldown, and whether
   the chip is installed.
4. **Install the chip** in your cyberdeck from the inventory's cyberdeck screen,
   like any quickhack. Inventory and tooltips show it as
   "Program A: *design name*" with the design's description.
5. **Use it.** Scan an enemy. The chip appears in the quickhack wheel under
   the design's name and description, with the design's RAM cost, upload time,
   cooldown and lifetime. When the upload completes, the design installs on
   the target and its rules fire on their triggers. If it spreads, it also
   installs on up to N nearby enemies within 8 m (not civilians or quest
   actors), and each copy runs its own on-upload rules and charges.

A blank slot's chip shows as locked in the wheel with "Blank program". Clearing
a slot leaves the chip installed but inactive until you recompile it.

**Test in Lab sandbox** copies the selected design into the Lab's free test
recipe. Use it to try a design without components or a chip.

## Design reference

| Part | Choices |
| --- | --- |
| Trigger | Opponent starts reloading; your ranged hit; your ranged headshot; on upload; 3 s after upload |
| Effect | Blindness; stun; movement restriction (speed x0.2); thermal, electrical, chemical or physical damage pulses |
| Condition | Always; only if already blinded; only if already burning |
| Duration | 2, 4 or 8 s |
| Damage pulses | 10, 25 or 50 base damage, every 2, 1 or 0.5 s |
| Program | Lifetime 15/30/60 s; 3 charges per rule; spread on upload to 0-3 enemies |

Rule semantics are unchanged from the lab (see [PROTOTYPE_CRAFTING.md](PROTOTYPE_CRAFTING.md)
and [QUICKHACK_BUILD5_TEST.md](QUICKHACK_BUILD5_TEST.md)):

- Each rule has a 2-second cooldown.
- Conditions are sampled before an event's effects.
- The same effect refreshes rather than stacks.
- Hit and headshot rules count only your direct ranged damage.

Native reference statuses (learned from equipped hacks in the Lab) cannot be
compiled into programs. Programs use the mod's own primitives only.

## Cost model

Every number comes from integer **points**. `quickhack_designs.lua` and
`CustomPrograms.reds` (`SDPQHDesign`) compute them the same way; change both together.

- **Complexity** (budget 12) is the lab's existing price per rule: trigger
  (reload 2, hit 3, headshot/upload/delay 1) plus effect (blindness or stun 2,
  others 3) plus 1 for a condition.
- **Parameter points** per rule: duration 2/4/8 s costs 0/1/2. Damage effects
  also add damage 10/25/50 at 0/1/2 and interval 2/1/0.5 s at 0/1/2.
- **Program points**: 2 per spread target, plus lifetime 15/30/60 s at 0/1/2.

| Derived | Formula | Starter "Optics core" (5 points) |
| --- | --- | --- |
| RAM | 1 + ceil(points / 2) | 4 |
| Upload time | 0.3 s + 0.1 s per point | 0.8 s |
| Cooldown | 4 s + 2 s per point | 14 s |
| Compile cost | points uncommon components, plus floor((points - 13) / 2) rare above 14 points | 5 uncommon |
| Chip | 10 uncommon components, once per chip | |

The game still applies its own modifiers on top: level-difference RAM scaling,
RAM-cost and upload-time perks and cyberdeck bonuses, and cooldown reductions.
These numbers are a first balance pass, not tuned yet.

**Free mode** (Program slots tab) skips component costs for testing. It
remembers nothing and is off each time CET starts.

## What is stored where

| Data | Location | Scope |
| --- | --- | --- |
| Design library | `quickhack-designs.json` in the CET mod folder | All saves on this machine |
| Compiled slots (numbers only) | Persistent field on the player's development data | Each save |
| Chips | Your inventory or cyberdeck | Each save |
| Slot display names | TweakDB string flats, refreshed each second by CET | Session |

A save does not store design names. CET finds the slot's design in your
library by its signature (`4.1.0.2.2.2|0|2|0` style) and shows its name. If
the design is no longer in your library, the chip is called "Custom program X";
its rules and costs are unaffected.

## How the native integration works

- `CustomPrograms.yaml` defines four actions (`SkillDrivenProgression.CustomHack1-4`),
  four chips (`SkillDrivenProgression.CustomProgram1-4`), their completion
  signal statuses and the per-slot RAM/upload/cooldown constants. The actions
  and chips start as clones of Reboot Optics (`QuickHack.BlindHack`, `Items.BlindProgram`).
- `CustomProgramRecords.reds` runs at TweakDB load and reads Optics' live
  layout. It gives each action its own:
  - cooldown status and "not on cooldown" prerequisite,
  - RAM cost and upload-time constants (perk and cyberdeck modifiers are kept),
  - completion that keeps the generic "was quickhacked" bookkeeping and signals
    the slot instead of blinding.

  It also drops Optics' "target already blinded" refusals, gives each action a
  private interaction record, and makes each chip carry its own action.
- `CustomPrograms.reds`:
  - offers the four actions to every NPC that already exposes puppet quickhacks
    (`ScriptedPuppetPS.GetAllChoices`),
  - writes the slot's name, description and lifetime into the wheel entries
    (`ScriptedPuppet.TranslateChoicesIntoQuickSlotCommands`),
  - installs the design when the completion signal lands on the target
    (`NPCPuppet.OnStatusEffectApplied`),
  - renames the chips in inventory and tooltips.
- Compiling sets the slot's constants with `TweakDBManager.SetFlat`. A loaded
  save reapplies its slots the first time the wheel, CET or the designer asks.

**Check program records** (Program slots tab) reports per slot whether the
scriptable tweak produced its signal, cooldown, RAM cost, upload time and chip
action. Run it once after deploying. Every slot should read `ok`.

## Known limits

- Some native surfaces still show Reboot Optics' text and icon, because the
  chips have no localization archive yet:
  - the scanner wheel icon,
  - the cyberdeck tooltip's program list,
  - the item-received toast,
  - some upload labels.

  The wheel title and description, inventory names and tooltips use the design.
- Chips are a single tier. They do not scale with item quality or the Optics tier ladder.
- Programs live only for the session, like lab programs. Saving and loading
  drops running programs, but not compiled slots or chips.
- **Disable and clear** on the Lab tab also clears running chip programs.
- Effects are the mod's primitives. They are not tier-exact copies of native
  quickhacks, and AI reactions and damage still need in-game measurement.

## In-game acceptance checks (not yet run)

1. Deploy, restart, open the designer. **Check program records** reads `ok`
   for A-D. The Lua and backend builds both read 10.
2. Compile Optics core into A in free mode, fabricate chip A and install it.
   The wheel shows "Optics core" with 4 RAM (before game modifiers), its
   description and a 30 s duration. Upload it on an ordinary enemy: they are
   blinded for 4 s and the HUD reports the program running.
3. Check the cooldown. After an upload, chip A shows its own cooldown, and
   Reboot Optics, if installed, is unaffected. The reverse holds too.
4. Blind a target with Reboot Optics, then upload chip A on it. It is not refused.
5. Recompile A with a heavier design. The wheel, RAM cost and upload time
   change without reinstalling the chip.
6. Spread: a design with spread 2 near a group installs on up to two more
   enemies, never on civilians.
7. Turn free mode off and compile with too few components. The game refuses
   and your components are unchanged. With enough, the right amounts are removed.
8. Save, load and restart the game. Slot names come back from the library,
   costs are reapplied before the first scan, and chips stay installed.
   Deleting the design from the library renames the chip "Custom program A".
9. Clear slot A. The chip shows as a locked "Blank program A" in the wheel.
10. Lab sandbox regression: the Build 9 lab checks in [PROTOTYPE_CRAFTING.md](PROTOTYPE_CRAFTING.md)
    still pass on the Lab tab.

## Developer checks

- `python tools/TestPrototypeCrafting.py` runs the real Lua (design model,
  designer window, lab) under LuaJIT with a mocked ImGui and backend. It also
  evaluates the redscript cost formulas and checks that they match the Lua ones.
- Build 10's redscript was linted with redscript 1.0 against declaration stubs
  (`tools/MakeScriptStubs.py`) generated from the decompiled 2.31 scripts, plus
  TweakXL's scripts. The result was 0 errors and 0 warnings in the mod's files.
  Injected mistakes were caught: a wrong hook signature, an unknown member and a
  type mismatch. A clean lint proves names, signatures and types; it does not
  prove gameplay. With the game installed, also compile against the real
  `final.redscripts` and redscript 0.5.31 as before.
