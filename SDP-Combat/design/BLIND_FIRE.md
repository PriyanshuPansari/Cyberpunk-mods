# Blindness: remembered aim, no live tracking

Implemented in `SDPBlindFire.reds`, `SDPHitModel.reds` and `SDPCadence.reds`.

For an enrolled NPC firing at the player while it has the `Blind` tag:

- Remember the aim position from its last sighted shot at the player.
- Freeze that world-space point for the blind interval. If no sighted shot was
  observed, use the NPC's facing at blindness onset (or first handled blind shot).
- Send the native firing path a static point and no entity target, tracking
  override, target prediction, history/live position provider or caller aim offset.
- Route this call through explicit-point shooting so its fallback cannot shoot
  along an AI-facing direction that continues to track the player.
- Keep weapon/shooter spread, recoil, sway and combat-state modifiers, without
  the previous automatic sixfold Blind spread penalty.
- Calculate cadence distance from the frozen point and treat target exposure as
  unavailable. Do not query live player exposure for blind cadence.
- Invalidate previous hit-zone/exposure estimates rather than attaching a stale
  sighted-shot prediction to blind fire.

Sighted fire keeps the existing model. Final removal of the Blind tag releases
the frozen state; overlapping Blind statuses retain it. Memory is nonpersistent
and cleared on NPC detach. Native and workbench Blind statuses both use this
behavior, without a required dependency on the crafting mod.

This changes the shooting path for SDP-Combat's enrolled NPCs toward the player,
including smart and tech shots during blindness. Bosses, non-enrolled enemies,
NPC-versus-NPC and other attack paths retain their existing behavior. It does
not clear the entire AI threat list, freeze locomotion/turning, disable hearing,
or cancel projectiles already launched. An NPC may visibly turn toward the
player even though these shots use a frozen point. Native effects can still
carry their own stat penalties, animations and weapon interruptions.

The remembered position is the last **sighted shot**, not a continuous visual
memory simulation. Weapon spread means shots can hit the player if they remain
near, or cross, that location. Engine projectile behavior needs in-game validation.

## Verification

The optional SDP-QuickhackCrafting trace bridge checks for the feature module
`SDPCombat.BlindAim`. Its snapshots show `combatAim=frozen`, `point`, and
`pointSource`. `module_unavailable` indicates the new combat module is absent;
`not_frozen` alone does not distinguish a sighted NPC from an unenrolled NPC.
Combat logs emit `BLIND_AIM_FREEZE` and `BLIND_AIM_RELEASE`; enabling
`SDPCombatSystem.SetLogShots(true)` also emits `BLIND_FIRE` per handled request.

1. Use an ordinary enrolled enemy with SDP-Combat enabled. Start the existing
   optics recording and allow several unblinded shots so it has sighted memory.
2. Upload an 8-second Optics core and move sideways in the open.
3. During blindness, `combatAim=frozen` must retain identical point coordinates
   while the player's logged distance changes. Watch whether bullets remain
   around the old position rather than following the player.
4. At final expiry, expect `combatAim=not_frozen` and normal tracking to resume.
5. Repeat with overlapping native/workbench blindness and with a second NPC to
   check independent memory. Repeat on an enemy blinded before its first shot;
   the source should be `initial_facing`.
6. Repeat with smart and tech weapons; new shots must not guide toward the moving
   player. Already airborne projectiles and other firing paths are outside this
   patch. Check save reload and disabling SDP-Combat restore normal routing.

Compilation verifies API compatibility, not these runtime assertions. Test
cover separately from the initial unobstructed trial.
