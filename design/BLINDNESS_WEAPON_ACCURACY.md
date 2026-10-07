# Separating blindness, weapon interruption and accuracy

Investigation: 2026-10-06. These findings use the local decompiled game scripts,
the installed mod sources, and the runtime recording starting at 03:01:07.
Runtime values describe this modded installation, not a guaranteed vanilla loadout.

Follow-up implementation: SDP-Combat's `SDPCombat.BlindAim` feature now freezes
enrolled NPC firing toward a remembered player position while Blind is active,
removing its old sixfold spread multiplier. The crafting trace optionally reports
the frozen point. See `SDP-Combat/design/BLIND_FIRE.md` for scope and test steps.
The original investigation below describes the pre-change combat implementation;
independent weapon-interruption and accuracy primitives remain future work.

## Primitive boundaries

| Primitive | Owns | Does not implicitly own |
|---|---|---|
| Sensory blindness | Reduced vision and changes to target information; timed sensory restoration | Accuracy stat, additional random shot spread, weapon jam, movement penalties |
| Weapon interruption | Defined interruption of firing/weapon operation; recovery after its own duration | Sight loss, aim degradation, smart guidance penalty |
| Accuracy penalty | A separately specified reduction in shooting effectiveness | Sight loss, forced weapon animation, inability to fire |

This is the intended separation. Build 9 corrects the diagnostics and removes an
unnecessary sensory override; it does **not** claim all three independent
gameplay primitives are implemented. The current Optics core has a private
status with the native `Blind` tag and no stat package. With SDP-Combat active,
that tag still introduces extra spread. Therefore it is not yet an isolated
sensory-only test across the complete mod stack.

## What blindness actually changes

In `NPCPuppet.OnStatusEffectApplied` (local vanilla-decompiled.reds:120451), a
`Blind` tag requests the secondary preset `Senses.Blind`. It also removes the
security-system-backed minimum tracking accuracy/persistence for the player via
`SwitchTargetPlayerTrackedAccuracy(..., false)`. The adjacent
`SetThreatBeliefAccuracy(this, 0)` literally targets `this`; do not describe it as
proof that the player's tracked position was erased.

Detection/reaction code also checks `ScriptedPuppet.IsBlinded`, which tests the
tag. The installed Quickhack_Fixes adds a blind check to reaction visibility.
These are different operations from `SenseComponent.IsAgentVisible`.

The event trace proves the secondary slot changed to `Senses.Blind` and actual
sense shapes changed from 12 to 1. On removal they returned to the main combat
preset and 12 shapes. `GetCurrentPreset()` continued to return `Senses.Default`
through these transitions: it was an unsuitable measurement of this override.
Build 9 uses the recorded secondary/main slots and logs actual shape count too.
Slot state is still not a universal query of all native internal state.

The Build 7/8 custom `OpticsSenses` override and its half-second retry loop were
based on that mistaken getter interpretation. They are removed. The private
status now relies on the native Blind-tag apply/removal lifecycle again.

Blindness is not a universal firing prohibition. `AIWeapon.Fire` can use live
targeting when visibility or its tracking override allows it, or fire forward
when it cannot use that targeting path. Continued firing does not establish
unchanged perception. One remaining sense shape does not establish its range
or function; trace v4 now reads the recorded preset's shape/curve definitions.

## Native status packages are not primitives

The 03:01:07 recording contains native status IDs and no
`CUSTOM_PRIMITIVE_REQUEST`. It cannot be treated as a clean private Optics-only
run, nor does it prove what caused every applied native status.

`BaseStatusEffect.ShortBlind` lasted about 2 seconds and carried these modifiers:

| Stat | Operation |
|---|---|
| Accuracy | multiply by 0.01 |
| MaxSpeed, JumpHeight | each multiply by 0.5 |
| HasCybereye, Evasion, CanUseCovers, CanSprint | each multiply by 0 |

Its package is `BaseStatusEffect.Blind_inline3`; the Accuracy modifier is
`BaseStatusEffect.Blind_inline7`. Reusing the whole status would import all of
these behaviors, not just sensory blindness.

`BaseStatusEffect.QuickHackBlind` remained for about 16 seconds while the
`Blind` tag itself disappeared after ShortBlind expired. A 0.4 Accuracy multiplier
appeared/disappeared with the longer status. Its package contains
`BaseStatusEffect.VisionDebuff_inline3`, an `ApplyStatGroupEffector`. The old
trace did not follow its nested group, so the exact record-level source of 0.4
remains to be confirmed by trace v4; the timing and arithmetic support it.

`BaseStatusEffect.WeaponMalfunction` appeared separately at 3.234375 seconds,
with roughly 28 seconds remaining. Its inspected package supplies:

- Accuracy multiplier **0.35**, `WeaponMalfunction_inline9`.
- SmartGunHitProbabilityMultiplier additive **-0.7**, `WeaponMalfunction_inline10`.
- Two VFX effectors and AI data `WeaponMalfunction_inline2`.

The smart stat change is an additive change to a named engine stat, not proof of
a 70-percentage-point reduction in observed hits. Likewise, the status duration
does not prove that the weapon is blocked for that entire duration.

The script path sends status-effect signals to the NPC behavior system. It has
repeat/reapply machinery, smart-target-related prolonging, and tier-specific
branches. `WeaponJammedAction`'s 5-second default field alone does not establish
actual runtime jam duration. Relevant behavior-graph execution is not fully
exposed in the decompiled script.

`JamWeapon` and `WeaponJam` are distinct tags. The shooting subaction checks
`WeaponJam` to disable its normal smart target-tracking override, with special
attack exceptions. This is not a generic block on all shots. Player-only
`StatusEffectPlayerData.JamWeapon` and the Minotaur's weapon-disable handler must
not be generalized to ordinary human NPC firing.

## Accuracy and the two shooting models

Vanilla `TargetShootComponent.ShouldBeHit` (vanilla-decompiled.reds:165027)
calculates an Accuracy coefficient of `1 / Accuracy`. It combines this with
distance, visibility, cover, group and other coefficients to decide whether
enough time has elapsed since the last hit. The caller uses the result to
produce an aim offset. Accuracy is **not a direct percentage hit chance**.

For paths that use that model, an Accuracy multiplier of 0.4 multiplies the
Accuracy contribution to the hit interval by 2.5; 0.35 by about 2.86; and 0.01
by 100. This is not a promise about observed damage rate: aim, occlusion,
projectile collision, target history and alternate firing paths still matter.

The recorded baseline Accuracy was 9. The principal phases were:

| Trace time | Effects contributing | Accuracy |
|---|---|---:|
| Before 3.03125 | Baseline | 9 |
| 3.03125–3.234375 | ShortBlind and longer optics penalty | 9 × .01 × .4 = .036 |
| 3.234375–5.046875 | Above plus WeaponMalfunction | 9 × .01 × .4 × .35 = .0126 |
| 5.046875–19.03125 | Longer optics penalty and WeaponMalfunction | 9 × .4 × .35 = 1.26 |
| After 19.03125 | WeaponMalfunction | 9 × .35 = 3.15 |

Brief hit-reaction penalties (`HitReactionTBHIncrease`, multiplier .000001) also
occurred. They must be excluded when interpreting those phase values.

In **SDP-Combat**, enrolled ordinary NPC shots toward the player take a different
`HandleBeingShot` path. It samples aim error from weapon handling, movement,
recoil, sway and shooter skill, bypassing vanilla's Accuracy timer. Its explicit
`Blind` check multiplies spread sigma by **6**, independently of the Accuracy
stat. Non-enrolled shooters, smart shots and tech-piercing shots have fallback
paths. No SDP-Combat behavior was changed by this investigation.

Consequently, an Accuracy-stat-only primitive will not automatically produce the
same penalty in both models. A future independent aim primitive needs an
explicit optional SDP-Combat integration. Removing Blind's spread coupling
also belongs in SDP-Combat, while preserving native blind behavior outside the
custom sensory-only status. Neither mod should gain a mandatory dependency on
the other.

## Measurements and next controlled tests

Build 9 / trace v4 adds nested stat groups, status tags/type/AI behavior and
resend-delay records; both jam tags in samples; `AI_SIGNAL_REQUEST`; and
`SHOT_BOOKKEEPING` after the native firing path reaches its shot accounting.
Reference-record blocks inspect four relevant records without applying them.
They are explicitly distinct from `ACTIVE_STATUS`.

`FIRE_CALL` is a request, `SHOT_BOOKKEEPING` is a later script milestone, and
`DAMAGE_RECEIVED` is attributed positive damage. None is a direct bullet hit-rate
measurement. Signal submission does not establish that AI chose the behavior.

First measure with SDP-Combat disabled, then repeat with it enabled. Keep the
same ordinary enemy, weapon, distance, difficulty and movement pattern. Begin
with an unobstructed baseline, apply one effect and let it expire. Test cover
as a separate phase. The user's pillar/car observations mean prior visibility
loss cannot be attributed solely to blindness.

For the first v4 run, the existing native recipe/reference path can inspect
native effects; it still imports their full bundles. Do not label that a
jam-only or accuracy-only experiment. The next implementation step is authored
private sensory, firing-interruption and aim-penalty leaves with independently
owned duration/cleanup, after measuring the remaining native AI behavior.

Validation: LuaJIT workbench tests pass; redscript compilation passes standalone
and with SDP-Combat plus installed plugin scripts. A wider split-mod compilation
snapshot failed on missing DVCore/RedLogger-related symbols in ChromePlating and
ThreadLocker (and excludes CombatArena's known standalone-compiler incompatibility).
It is not a full-installation pass. Runtime behavior after these changes remains
to be checked in game.
