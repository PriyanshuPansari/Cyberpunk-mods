# Component crafting: first playable prototype

Implemented 2026-10-05. Opt-in combat experiment, not the final crafting economy.
The source compiles against the installed vanilla game bundle and TweakXL scripts.
LuaJIT tests validate component selection and the workbench bridge. In-game
animation, damage, AI response and coexistence with other combat mods remain
unverified until the acceptance cases below are played.

## Launch

Build 5 adds [independent quickhack primitives and configurable damage pulses](QUICKHACK_BUILD5_TEST.md).
The [quickhack lab](../design/QUICKHACK_PRIMITIVES.md) retains native-status
spreading and component inspection as comparison tools.
It retains the Lua/backend version check, observed reload/hit counts and the
selected target's registered blindness/burning states. Both the workbench label
and backend status should show Build 5. Old runtime code requires a full restart.
If deployment appears ineffective, compare the game files with Vortex staging;
changing staging files alone does not confirm that the deployed copies updated.

Sync the project with `tools/Sync-ToVortex.ps1`, **Deploy Mods** in Vortex, and
restart Cyberpunk. No archive rebuild is needed for this prototype. Deploy
`PrototypeCrafting.reds`, `PrototypeCrafting.yaml`, `prototype.lua`,
`prototype_recipes.lua`, `QuickhackLab.reds`, `QuickhackPrimitives.reds` and the updated CET `init.lua` together.

In CET Bindings assign:

- **Prototype: toggle crafting workbench**
- **Prototype: upload selected recipe to aimed enemy**
- **Prototype: propagate aimed enemy's program**
- **Prototype: rearm aimed enemy's program for testing**
- **Quickhack lab: spread existing native quickhack**
- **Quickhack lab: inspect target's active quickhacks**

Open the workbench and the CET overlay. Select **Enable / reset session**.
Choose a preset or click the trigger, payload and condition buttons to cycle
components. The secondary rule can be switched off. Use **Save recipe** and
**Load recipe** to keep one authored blueprint in `prototype-recipe.json` in
the CET mod directory. This blueprint is shared locally across saves; loading
it does not install anything on a character.

Close the CET overlay, open the game scanner and highlight the intended enemy,
then use upload/propagate. Scanner mode uses the actual scanned selection;
outside scanner mode the workbench uses line-of-sight targeting.
Every hotkey action shows its result on the game HUD, even with the workbench
closed. Rejections identify missing selection, friendly/civilian actors,
boss/quest restrictions and other eligibility failures. Repeated uploads on
the same installed host report remaining seconds and charges rather than refreshing it.
For an explicit repeat test, **Rearm selected program (test)** or its hotkey
restores the selected active program to 30 seconds and three charges per rule,
resetting its cooldowns. Its recipe and existing spread permission stay unchanged;
copies still cannot spread. An expired program must be uploaded again.

Keep the workbench visible during an Empty Chamber test. Installation should
increase Programs; the programmed enemy's reload should increase Reloads detected;
matching rules increase Effect dispatches. When targeting that enemy, blind/burn
shows whether the engine currently registers those private statuses. Registration
does not prove the visual reaction or damage amount. Counters are cumulative
for the session and only include events on programmed or bound-weapon targets.
The workbench remains visible but does not accept mouse input while CET is closed.

## First experiments

### Empty Chamber: enemy reload -> blindness -> headshot heat

1. Choose **Empty Chamber**, aim at a living hostile human NPC within 30 metres,
   and use the upload hotkey. The returned message must confirm installation.
2. Let **that opponent** begin reloading. Their program dispatches blindness.
3. Headshot them while blinded. The second rule dispatches thermal burning.
4. Aim at the original host and use propagate. Up to three other eligible enemies
   within eight metres receive the same program, with its remaining lifetime,
   charges and cooldowns. Each copy responds to its own host's reload.

Propagation copies the program already installed on the source, even if the
workbench selection has since changed. It does not copy arbitrary vanilla or
third-party quickhacks through this button; build 4 has a separate **Spread existing
quickhack** action for supported native statuses. The source can propagate once;
copies cannot propagate. A zero-recipient attempt does not spend this ability.
Target discovery uses the native targeting query, not a global NPC scan.

### Blackout Gun: a two-stage iconic-style behavior

1. Choose **Blackout Gun**, hold a ranged weapon, and click **Assemble on held gun**.
2. Headshot a valid enemy: the primary rule dispatches blindness.
3. Land another headshot while they remain blinded: the second rule dispatches heat.
4. Switch weapons: the prototype rules must not follow a different weapon instance.
   Switch back: the original weapon retains the binding for this session.

This uses the held weapon as a chassis. It does not create an inventory item,
change its displayed name/rarity, replace its original abilities, or recreate a
specific vanilla iconic yet. Exactly one weapon instance can be bound; assembling
on another replaces the binding. Recipe edits do not mutate previously installed
programs or the bound weapon; explicitly upload/build to apply a new recipe.

**Heat Response** reverses the interaction: a ranged hit burns, then a headshot
against the already-burning target blinds. **Reload Blackout** is the simple
single-rule reload/blindness test.

## Rules and boundaries

| Component | Available choices |
| --- | --- |
| Trigger | Opponent starts reloading; your ranged hit; your ranged headshot |
| Payload | Blindness; thermal burning |
| Condition | Always; already blinded; already burning |
| Operator | Copy the installed program to up to three nearby targets |

Rules share a complexity budget of 12. Direct hits cost more than headshot
triggers. Duplicate rules and malformed component IDs are rejected by both the
Lua authoring layer and redscript. Opponent-reload rules require an uploaded
program; weapon bindings support hit/headshot rules.

- A program lives for 30 simulation seconds, with three charges per rule and
  a two-second cooldown per rule/host. A host has only one program at a time.
- Weapon rules have unlimited charges, with the same cooldown. At most 16 program
  hosts and 16 recent weapon targets are tracked. Weapon targets expire after
  30 seconds without a qualifying hit; a full table admits no new target until
  a slot expires or becomes ineligible.
- Headshots also qualify as hits; weakspot hits alone do not count as headshots.
  Events within 0.1 seconds on the same host are coalesced, including shotgun
  pellets. The first damage callback determines the event during that window.
- Both rules and both program/weapon evaluations see conditions before their
  effects are dispatched. A hit cannot satisfy its own newly-created condition.
- Only player-instigated, positive direct ranged weapon damage is eligible.
  DoT flags, quickhack flags and non-ranged attack types are excluded. A reentry
  guard also blocks synchronous recursive dispatch.
- Dead, defeated, friendly, civilian/crowd, non-enemy, boss and quest-tagged targets are excluded.
  XP rewards do not determine prototype eligibility; eligible enemies that award
  no XP can receive programs, propagate them and trigger their installed rules.
  Neutral combatants that the game classifies as enemies are eligible before combat.
  Native status-effect immunity remains in force. A dispatch counter records
  requests, not proof of successful blindness or damage.
- Payloads clone native `BaseStatusEffect.Blind` and `BaseStatusEffect.Burning`
  under private IDs with four-second durations. These are effect primitives,
  not full tiered Reboot Optics/Overheat actions. Native payload damage scaling
  is inherited and needs in-game measurement.
- Everything starts disabled. Attach/detach resets runtime programs and bindings.
  Save/load does not preserve live installations. Disable/reset clears all
  runtime state; existing short-lived status effects expire naturally.

This sandbox intentionally charges no crafting materials or RAM. It does not
integrate native upload queues, trace, deck slots, item tooltips, persistent weapon
recipes, blueprint discovery, dismantling, or a full iconic-component catalog.

## Acceptance checks in the game

1. With the workbench disabled, ordinary shooting, NPC reloads and shard XP behave
   as before. Confirm no new status effects or automatic weapon binding.
2. Upload Reload Blackout. Player reloads do nothing. The programmed enemy's
   reload start dispatches blindness; other enemies' reloads do nothing.
3. Upload Empty Chamber. Bodyshots do not dispatch its thermal rule. An unblinded
   headshot does not burn. A headshot during blindness does; the target must
   survive the damage event for the effect to apply.
4. Repeated events inside two seconds cannot consume additional charges. After
   three successful triggers, that program rule stops. The other rule has its
   own charge count. No rule fires after the 30-second installation expires.
5. Change the selected recipe, then propagate an existing host. Copies retain the
   original recipe and remaining lifetime/charges, do not refresh a target already
   programmed, and cannot themselves propagate. Verify no more than three copies.
6. Bind Blackout Gun. Validate blindness then heat, weapon switching, two copies
   of the same weapon model, shotgun pellet handling, and no DoT-trigger loop.
   Existing iconic abilities should continue working independently.
7. Verify civilians, friendlies, dead/defeated targets, bosses and quest-tagged
   actors are refused. Test status-immune enemies separately: requests may be
   counted without a visible effect.
8. Disable, save/load, die/reload, and return to the main menu. No program or
   weapon behavior resumes automatically. Save/load a blueprint and explicitly
   enable/build it again. Check CET/redscript logs for errors.
9. Check original shard tree/XP overlays and progression settings still work.
10. With the workbench closed, press upload at empty space, a civilian and an
    eligible enemy highlighted in the scanner. Verify visible, distinct feedback
    on each press. Test a neutral gang enemy before combat, a repeat upload on
    the installed target, and an upload after its 30-second expiry. Exit scanner
    mode and look elsewhere: upload must not reuse the old scanned selection.
11. Rearm an active original program twice, then a propagated copy. Verify time,
    charges and cooldowns reset, the recipe stays the same, and the copy still
    cannot propagate. Rearming an expired/absent program must tell you to upload.

## Developer checks and ownership

`python tools/TestPrototypeCrafting.py` executes the actual Lua files under
LuaJIT, using a mocked game/UI bridge. Install its test dependency with
`python -m pip install --target .stage/prototype-test-deps lupa`.
`python tools/VerifyProgression.py` checks the existing progression data/docs.
Compile all project redscript plus TweakXL's installed `Scripts` directory against
the installed vanilla `r6/cache/final.redscripts`; output only to `.stage`.
The CLI compilation checks types/hooks, not gameplay or TweakXL record contents.

`SDPPrototypeRuntime` owns program state, compatibility, rule evaluation and
limits. The only combat hooks wrap `AISubActionReloadWeapon_Record_Implementation.Activate`
and `RPGManager.AwardExperienceFromDamage`, calling the original methods first.
Player attach/detach wrappers clear transient state. The workbench uses the
existing single CET draw/update/overlay handlers rather than registering competing
handlers. Only explicit button/hotkey actions enable, upload, propagate or bind.

The next implementation gate is completing the in-game cases above, then adding
actual inventory outputs, per-item persistence, costs and native quickhack actions.
