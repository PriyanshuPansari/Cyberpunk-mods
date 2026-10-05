# Quickhack-first implementation and test sequence

**Build 5 update:** independent status records, typed damage pulses, duration and
pulse parameters, movement restriction and active-effect propagation are now
implemented. See [the current implementation and acceptance test](../docs/QUICKHACK_BUILD5_TEST.md).
No complete native quickhack status is inherited by these custom payloads.

The sections below record the Build 4 baseline, 2026-10-05. Weapon expansion is deferred. This document distinguishes
implemented status-level composition from the later, finer breakdown of damage,
AI and action semantics. No build-4 gameplay results have been claimed yet.

The intended final system recreates quickhacks from our own primitives. Native
quickhacks and native status leaves are temporary references and comparison
fixtures, not a required player-facing dependency of future crafted hacks.
Do not expand native compatibility in place of extracting independently reusable
damage, duration, sensory, movement, AI, targeting and propagation components.

Spread diagnostics now distinguish requests from observed recipient statuses.
A delayed receipt checks registration after native handlers run and reports
duration verification separately. No immediate duration-setter failure rolls
back an otherwise visible effect. A guarded expiry callback caps copied-instance
lifetime without deleting a later recast. Zero-request reports include nearby,
already-affected and excluded counts; a cap of three unique requests applies
even when the native API returns false. These diagnostics do not prove AI or
damage parity and should not hold up the independent-primitive implementation.

## 1. Spread existing quickhacks

Implemented a separate **Spread existing quickhack** action/hotkey. The earlier
**Propagate installed program** action continues to copy our event programs.
Enable the workbench, apply a normal quickhack in the scanner, keep that target
selected, then use **Quickhack lab: spread existing native quickhack**.

The operator chooses the player's most recently applied *supported active status*
on that NPC. It does not replay a completed instantaneous attack or guess from
the selected recipe. Start acceptance testing with Reboot Optics and Overheat.
Family recognition also covers known movement-disruption, weapon-jam,
cyberware-malfunction and communication-disruption tags. Tag recognition is a
capability filter, not a claim that all tiers/modded variants have been tested.

- Native record ID and stack count are retained; up to three eligible neighbours
  within eight metres receive it. Source must be within 30 metres of the player.
- Remaining duration is copied, with a guarded correction after native
  on-application handlers. A newer recast is not overwritten by that correction.
- Targets already carrying the same family are skipped. No existing effect is
  removed/replaced to make room.
- A live source status gets one successful spread. Copies cannot be spread by
  this operator. A zero-recipient attempt does not consume the source's spread.
- Refreshing a live status does not reset the spread budget. Expiry followed by
  a new instance does; the ledger tracks initial application timestamps.
- Up to 64 live ledger entries; state is session-only. This bounds our dispatches,
  not independent secondary effects from native statuses or other mods.
- Instant/ultimate effects, Contagion's own spread machinery, Memory Wipe's squad
  behavior and unsupported families are deliberately not replayed by this first
  operator. Short Circuit's already-completed damage cannot be copied as a timed
  status. These need distinct attack/action primitives.

This copies the active status, not its original queue entry, RAM transaction,
upload animation or trace action. Native status reactions and proc packages can
still execute. Those interactions belong in acceptance testing.

## 2. Break down the installed quickhacks

**Inspect equipped hack**, **Previous hack** and **Next hack** read the actual
equipped actions from `RPGManager.GetPlayerQuickHackList`. This reflects the
installed tier and mods rather than a hand-written list of assumed record IDs.

The report expands:

```text
native action
  start effects (count; not reconstructed)
  completion effect -> recipient
    status leaf -> tags / duration record / AI record
      gameplay package -> effectors / stat modifiers
    direct effector (reported as unsupported by the status compiler)
```

The first reusable unit is a **native status leaf**: its native packages, AI data,
duration and tags stay attached. This preserves an original status's behavior
while changing its trigger/condition. It is an intermediate granularity, not
yet an independent editor for every attack tick, damage coefficient or AI task.

The deeper primitive vocabulary to extract and validate is:

| Native behavior | Primitive responsibilities | Build-4 boundary |
| --- | --- | --- |
| Reboot Optics | Sight disruption, duration, awareness response, tier bonuses | Native status leaf + generic blind primitive |
| Overheat | Thermal tick attack, period, duration, armor/tier interaction | Native status leaf + generic burning primitive |
| Weapon Glitch | Jam, duration, reapply/smart-lock behavior, tier proc | Tagged status leaf; direct effectors must be handled separately |
| Cripple Movement | Movement restrictions, duration, vulnerability/tier effects | Tagged status leaf where completion graph qualifies |
| Cyberware Malfunction | Ability suppression, stack accumulation, threshold proc | Tagged status leaf; stack interactions need explicit tests |
| Sonic Shock | Hearing/comms suppression, awareness changes, combination conditions | Tagged status leaf; native combo side effects remain attached |
| Short Circuit | Electrical burst, target-specific multipliers, residual effects | Generic shock is an experiment, not an exact reconstruction |
| Contagion | Chemical ticks, infection propagation, jump budget, combination reaction | Needs explicit damage and propagation nodes |
| Memory Wipe | Awareness/trace operations, squad scope, combination reaction | Needs action-state and squad nodes |
| Ping / lure / reinforcement-request actions | Network reveal, destination, AI request, scope | Audit graph first; requires network/AI nodes |
| Ultimate and special actions | Forced actions, target constraints, payoff, secondary effects | Audit graph first; no arbitrary instant-effect replay |

Actual installed names, tiers and graphs are authoritative. Unsupported actions
remain inspectable. No original quickhack is globally patched or replaced.

## 3. Add experimental primitives

Authoring supports two rules, each with trigger, payload and condition:

| Layer | Current choices |
| --- | --- |
| Trigger | Opponent reload; your ranged hit; your ranged headshot; on upload; after 3 simulation seconds |
| Generic payload | Blindness; thermal burning; electrical shock; stun |
| Native payload | A learned supported native status leaf |
| Condition | Always; already blinded; already burning |
| Operators | Copy an event program; copy an existing native status |

Generic effects last four seconds. Native leaves keep their native durations.
On-upload and delayed rules each execute once per installation/rearm; only event
rules can naturally spend all three charges. Timers use simulation time with
roughly 0.1-second polling. Copies of event programs retain pending timer state;
an already-fired on-upload/delayed event is not replayed by program propagation.

New experiment presets are **Delayed Flash** (three-second delay -> blindness
and stun), **Burning Trap** (on-upload burning -> headshot while burning -> stun),
and **Reload Shock** (opponent reload -> shock; your headshot -> blindness).
Existing Empty Chamber and its spread remain available.

**Learn first status -> primary/secondary** extracts the first supported target
status from the inspected action into that rule. Inspect Optics, learn its status
into the primary rule, then inspect Overheat and learn its status into the
secondary rule. Change each trigger and condition independently. This deliberately
extracts one component and does not claim to reconstruct the source's other effects.

## 4. Rebuild original completion effects, then compare

In the lab inspect an equipped hack and select **Rebuild selected native core**.
The compiler creates an on-upload recipe from its target-status leaves. The
generated recipe can be saved and its triggers/conditions edited like any other.

It accepts only a complete completion list of one or two supported target-status
leaves. Any unsupported status, direct effector, non-target recipient, or larger
completion graph refuses the rebuild. This prevents a superficially successful
but silently partial completion recipe.

This is **completion-status parity**, not full quickhack parity. Start effects,
RAM, trace, upload timing, queue behavior and whole-action callbacks are not
reconstructed. Generic **Optics core**, **Thermal core** and **Shock core** presets
are simple demonstrations, not tier-exact originals. Full original rebuilding
requires the deeper primitive work listed above and comparisons below.

Acceptance sequence, one hack/tier at a time:

1. Use the native hack on a fresh eligible enemy. Immediately use **Quickhack lab:
   inspect target's active quickhacks**. Save a comparison snapshot.
2. Inspect that equipped hack and rebuild its core. Use the workbench upload on
   a comparable fresh enemy, at the same player stats and difficulty.
3. Capture and save another target snapshot. Compare record IDs, stacks, total
   duration and remaining lifetime after accounting for observation delay.
4. Observe the actual AI response and damage over time. Equal records are useful
   structural evidence, not proof of equal damage, behavior or whole-action parity.
5. Record differences in upload/trace/cost separately as known omissions. Mark
   a tier accepted only after its intended effects are observed.

Snapshots append to `quickhack-lab-report.txt` in the CET mod directory. Logs are
manual samples; no pass/fail result is fabricated from successful API dispatch.

## 5. Test new quickhacks after the originals

First change just the trigger on a rebuilt Optics leaf to opponent reload, then
test the exact native blindness status after a reload. Next pair that learned
leaf with thermal damage on headshot. Finally test Delayed Flash and Burning Trap.

Check source/recipient expiry, depleted charges, failed conditions, immunity,
duplicate targets, death/unload, disable/reset and save/load. For native spread,
also test already-affected neighbours, a copied source, zero neighbours, two
different hacks on the source, and expiry followed by a new cast.

Automated checks cover Lua authoring, rejection of malformed/missing native
components, reconstruction bridge paths, save/load, reports and version mismatch.
The complete redscript set is compiled against installed mods. Runtime/native
spread, status timing, AI behavior and damage still require the in-game steps.
