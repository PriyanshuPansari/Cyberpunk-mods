# Optics runtime recording (Build 9 / trace v4)

## Current behavior and correction

With the new optional `SDPCombat.BlindAim` feature installed, snapshots also show
`combatAim=frozen point=... pointSource=last_sighted_shot/initial_facing`.
During an 8-second Optics test, move sideways in the open: the coordinates should
stay fixed until blindness ends. This patch freezes firing aim; other AI systems
can still turn/move the NPC. SDP-Combat removes its previous sixfold Blind spread
penalty for this implementation. Without that feature, the trace reports
`combatAim=module_unavailable` and retains standalone operation.

Build 8's event recording proved `Senses.Blind` was being applied: the secondary
preset slot changed and actual sense shapes dropped from 12 to 1. The ordinary
`GetCurrentPreset()` getter remained `Senses.Default`. Earlier conclusions below
that this getter proved the override failed were incorrect.

Build 9 removes the custom `OpticsSenses` preset/retry loop, restores the native
Blind-tag lifecycle and reports the recorded secondary/main preset slots with
actual shape count. A slot value is not proof of all native internal state.

The trace additionally reports:

- Nested `ApplyStatGroupEffector` groups and modifiers (recursion limited to 4).
- Status tags/type, AI behavior, priority and resend-delay modifiers.
- `jamWeaponTag` and `weaponJamTag` separately in snapshots.
- `AI_SIGNAL_REQUEST`: requested status behavior, not confirmed AI execution.
- `SHOT_BOOKKEEPING`: the native firing path reached its final accounting hook;
  this excludes early returns, but is not a projectile collision confirmation.
- `REFERENCE_RECORD_BEGIN/END`: read-only inspection of private Optics,
  ShortBlind, QuickHackBlind and WeaponMalfunction, one per drain. These are
  record definitions, not proof of applied effects. Use `ACTIVE_STATUS` for that.

The complete findings and controlled test plan are in
[Blindness, weapon interruption and accuracy](../design/BLINDNESS_WEAPON_ACCURACY.md).
Older SDP-Combat builds add spread for the Blind tag. The new blind-aim feature
uses a remembered position instead. SDP-Combat still bypasses vanilla Accuracy
hit timing for the ordinary shots it handles.

After switching from the all-in-one mod to the split mods in Vortex, deploy
**SDP-QuickhackCrafting** and restart the game. Do not enable both layouts.
The updated log is at
`bin/x64/plugins/cyber_engine_tweaks/mods/SDPQuickhackCrafting/optics-runtime.log`.
The old `SkillDrivenProgression` folder may retain historical logs.

Use the same **Quickhack lab: record aimed enemy for 30 seconds** binding.
Record an unobstructed baseline, then one effect and expiry. Treat cover as a
separate test. The previous pillar/car runs do not isolate sensory occlusion.

Validation: LuaJIT tests pass; the quickhack scripts compile standalone and with
SDP-Combat. The broader installed-mod snapshot fails on missing dependencies in
ChromePlating/ThreadLocker and excludes CombatArena's known standalone compiler
incompatibility. Full in-game compilation and v4 measurements remain pending.

## Historical notes (superseded where corrected above)

## Build 8 / trace v3: preset call lifecycle

Build 7's recording showed repeated native acceptance while later samples still
reported Senses.Default. Build 8 adds diagnostics without changing that behavior:

- OPTICS_CALL_BEFORE, OPTICS_NATIVE_RETURN_TRUE/FALSE and
  OPTICS_SECONDARY_ASSIGNED capture the immediate result of UsePreset.
- PRESET_EVENT_BEFORE/AFTER_MAIN/SECONDARY/RESET identify ordinary preset events.
- HACK_PRESET_BEFORE/AFTER and SENSE_INITIALIZE_BEFORE/AFTER cover the other
  script-visible preset/initialization paths.
- Each records requested/current/main/secondary IDs, actual sense-shape count and
  player visibility. These distinguish an unchanged native getter immediately
  after acceptance from a later script-event reset. Native internal changes are
  not directly hooked; lack of an event does not rule those out.

Only the recorded NPC emits these details. Restart and verify Build 8 / trace v3,
record before uploading Optics, and let the effect expire. This is additional
instrumentation, not a verified sensory fix. LuaJIT checks and compilation pass
with the same CombatArena exclusion noted below.

## Build 7 attempted sensory fix (removed in Build 9)

The October 6 trace confirmed our private Blind tag applied for four seconds,
while the measured preset remained Senses.Default. Accuracy was unchanged during
that interval. Separate HitReactionTBHIncrease status events supplied a 0.000001
Accuracy multiplier for about 0.3 seconds outside the optics interval. This does
not identify the sources of the longer October 5 penalties.

Build 7 introduces SkillDrivenProgression.OpticsSenses, based on the normal
sensory record with detection shapes/curves cleared and detection factor zero.
While the private status is registered, the runtime directly applies this preset
through the engine's native UsePreset operation and secondary-preset slot. It
checks every 0.5 simulation seconds, doing nothing if that preset is already
active. It does not recreate a dispelled status. The normal Blind removal handler
resets the secondary preset when the status expires or the workbench clears it.

The trace logs OPTICS_PRESET_ACCEPTED/REJECTED, and the workbench shows
`optics preset=active` or `NOT active`. Test with an eight-second Optics core:
verify the custom preset appears, visibility/targeting changes, and the original
main preset returns after expiry and after Disable/reset. Repeat with propagation.
Preset acceptance alone is not proof of the native visibility result; all these
gameplay checks remain pending. Smart tracking and forward firing can still occur.

The installed SDPCombat hit model separately multiplies shot scatter by six for
the Blind tag. Thus unchanged Accuracy does not prove unchanged shot accuracy.
No SDPCombat source or balancing was changed by this fix.

Build 7 LuaJIT tests pass; script compilation passes with the previously documented
CombatArena exclusion. Runtime records require TweakXL loading on game restart.

Restart after deployment. In CET Bindings assign **Quickhack lab: record aimed
enemy for 30 seconds**. Enable the workbench, choose Optics core and set 8s.
Select an ordinary enemy in the scanner and press the recording hotkey once.
The target stays fixed even after you look away. Recording ends after 30 game
simulation seconds; scanner slowdown and pauses can extend real elapsed time.

Let that enemy fight you for about five seconds without uploading. Then upload
Optics core, move sideways during the effect, and keep fighting after it expires.
Avoid other enemies, smart weapons, cover changes and return fire in the first
test so there are fewer competing explanations. Recording doesn't change combat.

Results append to `optics-runtime.log` in the game's
`bin/x64/plugins/cyber_engine_tweaks/mods/SkillDrivenProgression` folder. The workbench
reports completion. Each session starts with its timestamp and the selected NPC
identity. Loading another save ends the recording rather than selecting a new NPC.

- `SAMPLE`: approximately every 0.25 simulation seconds; blind tag, NPC visibility
  of player, continuous line-of-sight reading, visible-threat belief accuracy,
  Accuracy stat and distance. A -1 reading means unavailable, not zero.
- `FIRE_CALL`: entry to AIWeapon.Fire for the selected shooter, plus whether its
  target is the player, the actual tracking-override argument and aiming delay.
  This is a firing request, not proof that a projectile spawned or of the final
  native aim direction. Early exits and alternate firing paths are possible.
- `DAMAGE_RECEIVED`: positive damage received by the player attributed to that NPC,
  with attack type. Damage includes all recorded resource loss reported by the
  engine, not necessarily HP alone. Filter out non-ranged attacks for shooting tests.
- `END dropped=N`: completion and number of omitted records if the bounded queue
  filled. Sampling is not a substitute for per-shot events; damage events cannot
  be paired one-to-one with firing calls (pellets, travel time and bursts).

Compare `visible`, `trackingOverride`, `continuousLOS` and `accuracyStat` before,
during and after `blind=yes`. Visibility retained during blindness and a tracking
override are different explanations for continued aimed shooting. This trace
does not expose the native hit/miss decision.

## Trace v2: source attribution

The start notification now includes `trace v2`. The same recording also logs:

- `CUSTOM_PRIMITIVE_REQUEST`: the exact private record requested by our runtime.
- `STATUS_APPLIED` / `STATUS_REMOVED`: status events on this particular NPC.
- `AUDIT`, `ACCURACY_MOD`: the current Accuracy modifier operations and values.
- `ACTIVE_STATUS`, `PACKAGE_STAT`, `PACKAGE_EFFECTOR`, `EFFECTOR_APPLIES`: live
  status IDs, remaining times, stat record values and status-producing effectors.
- `SENSE_PRESET`, `SENSE_SHAPE`, `SENSE_CURVE`: the actual current sensory preset
  and its detection settings. These are refreshed when the preset changes.

Detailed snapshots occur at startup and when Accuracy, preset or active status
membership changes; they do not run on every shot. Modifier details expose type
and value, not a source pointer. Package records and status timings can identify
matching sources, but modifiers created elsewhere still need further tracing.
Queue limit is 512 records between drains; `END dropped` reports any omissions.

Compilation of v2 passes with the installed plugins and mods except CombatArena:
the standalone compiler rejects that mod's temporary-value expressions. No
CombatArena files were changed; full game compilation remains to be checked on restart.

Validation: compiled against installed scripts; LuaJIT tests cover starting,
duplicate-start rejection, file output and completion. Live readings need an
in-game run. The original thermal/propagation test was reported working by the user.
