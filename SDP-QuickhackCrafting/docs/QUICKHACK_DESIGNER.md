# Quickhack Designer (Build 11)

Design quickhacks from the mod's primitives, compile them into program chips,
install the chips in your cyberdeck, and use them from the game's own scanner
quickhack wheel. They have a RAM cost, upload time and cooldown, just like
native quickhacks.

There are two editors for the same designs:

- **Native menu:** a **Quickhack Designer** tab in the game's Crafting menu,
  next to Crafting and Upgrading. It needs Codeware.
- **CET window:** the overlay window from Build 10. It also holds the free
  sandbox and native lab tools on its **Lab** tab.

Since Build 11, designs are stored in your save, like crafting recipes. Both
editors edit that same library. A new save starts with the starter designs.

## Install

Deploy the whole `SDP-QuickhackCrafting` folder, then restart the game.

- `r6/scripts/SDPQuickhackCrafting/*.reds`, including `DesignLibrary.reds` and
  `DesignerUI.reds` (new in Build 11), and `CustomPrograms.reds` and
  `CustomProgramRecords.reds`.
- `r6/tweaks/SDPQuickhackCrafting/*.yaml`, including `CustomPrograms.yaml`.
- `bin/x64/plugins/cyber_engine_tweaks/mods/SDPQuickhackCrafting/*.lua`.

You need redscript, CET and TweakXL. The chip actions are finished at load by
a TweakXL **scriptable tweak** (`SDPQHProgramTweak`), so TweakXL must be a
version that runs `ScriptableTweak` classes.

The native menu also needs **Codeware**. Without Codeware the scripts still
compile: the Crafting tab does not appear, and the CET window does everything.
`tools/Sync-ToVortex.ps1` copies the folders. It does not overwrite
`quickhack-designs.json`.

CET bindings:

- **Quickhack designer: toggle window** opens the CET window. It keeps the old
  binding ID, so an existing workbench hotkey still works.
- **Quickhack designer: open in-game menu** opens the native designer as a
  popup, anywhere in the game. It needs Codeware.

## Native menu (Crafting > Quickhack Designer)

Open the Crafting menu and pick the **Quickhack Designer** tab with the mouse
or the tab keys. The screen has three columns:

- **Designs:** your library, 10 per page. **New**, **Copy**, **Delete** and
  **Add starter designs** (re-adds any starter you deleted).
- **Design:** the name field, then rows for the primary rule, the secondary
  rule and the program. Each row has **<** and **>** to step through its
  choices: trigger, effect, condition, duration, damage and pulse (damage
  effects only), second rule on/off, lifetime and spread.
- **Readout and program slots:** complexity bar, RAM, upload, cooldown,
  compile cost, your component counts, and the design's description (or why
  it can't be compiled). Each slot A-D shows its compiled design and chip
  status, with **Compile**, **Make chip** and **Clear**. There is also a
  **Free mode** toggle for testing.

Every change is saved immediately. The popup from the CET binding shows the
same panel scaled down, with **Close** (or Esc).

Controls are mouse-driven; gamepad navigation reaches the tab but not the
buttons inside it. While the name field has focus, the Crafting menu's tab
keys are ignored, so typing Q or E does not switch tabs. Other hub hotkeys
may still react to keys typed into the name. If that gets in the way, rename
designs in the CET window.

## CET window

1. **Designer tab:** the same library as the native menu, with dropdowns
   instead of steppers. Edits are sent to the save half a second after you
   stop changing them. Changes made in the native menu appear within a second.
   - **Export to file** writes the library to `quickhack-designs.json` in the
     CET mod folder.
   - **Import N from file** adds that file's designs to the current save. Use
     it to carry designs to another save, or to import a Build 10 library or
     a Build 9 `prototype-recipe.json`.
2. **Compile into a program slot:** click **A**, **B**, **C** or **D** under
   the readout.
3. **Program slots tab:** **Fabricate chip**, **Clear slot**, slot status,
   free mode and **Check program records**.

## Playing with chips

1. **Compile** a design into a slot. This costs quickhack components (see
   below) and stores the design and its name in the slot. You can recompile a
   slot at any time; the chip runs whatever is compiled into it.
2. **Make a chip** for the slot (10 uncommon quickhack components). It lands
   in your inventory.
3. **Install the chip** in your cyberdeck from the inventory's cyberdeck
   screen, like any quickhack. Inventory and tooltips show it as
   "Program A: *design name*" with the design's description.
4. **Use it.** Scan an enemy. The chip appears in the quickhack wheel under
   the design's name and description, with the design's RAM cost, upload time,
   cooldown and lifetime. When the upload completes, the design installs on
   the target and its rules fire on their triggers. If it spreads, it also
   installs on up to N nearby enemies within 8 m (not civilians or quest
   actors), and each copy runs its own on-upload rules and charges.

A blank slot's chip shows as locked in the wheel with "Blank program". Clearing
a slot leaves the chip installed but inactive until you recompile it.

**Test in Lab sandbox** (CET) copies the selected design into the Lab's free
test recipe. Use it to try a design without components or a chip.

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

**Free mode** skips component costs for testing. It is a toggle in each editor
and is off each time the menu or CET starts.

## What is stored where

| Data | Location | Scope |
| --- | --- | --- |
| Design library (up to 48) | Persistent fields on the player's development data | Each save |
| Compiled slots and their names | Persistent fields on the player's development data | Each save |
| Chips | Your inventory or cyberdeck | Each save |
| Export file | `quickhack-designs.json` in the CET mod folder | Written and read only on request |
| Chip display names | TweakDB string flats, refreshed from the save | Session |

Redscript cannot save strings, so names are stored as character codes. Saved
names use letters, digits, spaces and `.,:;!?'-_+*/()&#%@<>=`; any other
character is saved as `?`. Names are up to 48 characters. A Build 10 save
keeps its compiled slots, but those slots have no names, so their chips read
"Custom program X" until you recompile them.

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
- `DesignLibrary.reds`: the save's design library (`SDPQHSpec`, one value
  layout shared with the slots), its names, starter seeding, and the library
  API that both editors call.
- `DesignerUI.reds` (Codeware only): the native panel, the third Crafting tab
  (`CraftingMainGameController.RegisterTabButtons` / `SelectTab`), and the
  in-game popup.
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
- The native menu is laid out for the 4K menu canvas, and its position in
  the Crafting screen was chosen without seeing the screen. It may overlap
  Crafting-screen decorations until it is adjusted in game: change the root
  margin in `SDPQHDesignerPanel.OnCreate`.
- Effects are the mod's primitives. They are not tier-exact copies of native
  quickhacks, and AI reactions and damage still need in-game measurement.

## In-game acceptance checks (not yet run)

1. Deploy, restart, open the CET window. **Check program records** reads `ok`
   for A-D, and the window reads build 11.
2. Native menu: open Crafting. A third **Quickhack Designer** tab appears.
   Switching to it hides the crafting/upgrading lists and shows the three
   columns; switching back restores them. Q/E (or the bumpers) cycle all
   three tabs. Note any overlap with Crafting-screen decorations.
3. In the native menu, select Optics core, then step through every row with
   **<** and **>**. Damage and pulse rows appear only for damage effects; the
   secondary rows only when the second rule is on. Complexity, RAM, upload,
   cooldown and the description update; an over-budget design shows why it
   can't be compiled.
4. Rename a design in the name field. Typing Q or E does not switch tabs.
   The list shows the new name. In the CET window the same name and edits
   appear within a second, and CET edits appear in the native menu on its
   next refresh.
5. Compile Optics core into A in free mode, **Make chip** for A and install
   it. The wheel shows "Optics core" with 4 RAM (before game modifiers), its
   description and a 30 s duration. Upload it on an ordinary enemy: they are
   blinded for 4 s and the HUD reports the program running.
6. Check the cooldown. After an upload, chip A shows its own cooldown, and
   Reboot Optics, if installed, is unaffected. The reverse holds too.
7. Blind a target with Reboot Optics, then upload chip A on it. It is not refused.
8. Recompile A with a heavier design. The wheel, RAM cost and upload time
   change without reinstalling the chip.
9. Spread: a design with spread 2 near a group installs on up to two more
   enemies, never on civilians.
10. Turn free mode off and compile with too few components. The game refuses
    and your components are unchanged. With enough, the right amounts are removed.
11. Save, load and restart the game. The library, design names, slot names
    and chips all come back, and costs are reapplied before the first scan. A
    different save shows its own library in both editors.
12. **Export to file** in one save, then **Import** in another. The designs
    appear in the second save's library.
13. Bind **Quickhack designer: open in-game menu**. The popup shows the
    panel scaled to fit, and the cursor works. **Close** and Esc close it, and
    time returns to normal.
14. Without Codeware: the scripts compile, the Crafting menu has its normal
    two tabs, and the CET window still edits, compiles and makes chips.
15. Clear slot A. The chip shows as a locked "Blank program A" in the wheel.
16. Lab sandbox regression: the Build 9 lab checks in [PROTOTYPE_CRAFTING.md](PROTOTYPE_CRAFTING.md)
    still pass on the Lab tab.

## Developer checks

- `python tools/TestPrototypeCrafting.py` runs the real Lua (design model,
  CET window mirroring a mocked save library, lab) under LuaJIT with a mocked
  ImGui and backend. It also checks that the redscript cost formulas and
  starter designs match the Lua ones.
- The redscript was linted with redscript 1.0 against declaration stubs
  (`tools/MakeScriptStubs.py`) generated from the decompiled 2.31 scripts,
  plus TweakXL's and Codeware's scripts. Both variants were linted: with
  Codeware (native menu compiled) and without it. Each had 0 errors and
  0 warnings in the mod's files.
  - Injected mistakes were caught: a wrong hook signature, an unknown member,
    a type mismatch, and an unknown method in the Codeware-only menu code.
  - The lint also caught a real problem: redscript cannot save strings. That
    is why names are stored as character codes.

  A clean lint proves names, signatures and types; it does not prove
  gameplay or layout. With the game installed, also compile against the real
  `final.redscripts` and your redscript version as before.
