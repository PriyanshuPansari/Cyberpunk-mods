// SDPCombat Phase 1: time between an NPC's shots from recoil recovery and intent (realism pass, section 3).
//   recoil r grows by the weapon's own kick + spread bloom each shot and decays at the weapon's settle rate
//   scaled by the shooter's recoil control (SDPWeaponStats.RecoveryRate).
//   first shot of a burst: the weapon's AimInTime (scaled by skill) + reaction, unless it is still raised.
//   aimed fire  : wait until r <= r_ok, where r_ok follows V's apparent size
//                 (trained shooters demand 0.5 x V's angular half-size, untrained accept the full size)
//   suppression : trained shooters firing at V when less than half of her is visible do not wait (the "zero pause" case)
//   out of range: past the weapon's MaximumRange trained shooters hold fire (1 s re-check); others keep shooting
// The engine still enforces the weapon's own cycle time and burst-mode timing.
module SDPCombat

@wrapMethod(AISubActionShootWithWeapon_Record_Implementation)
public final static func QueueNextShot(weapon: wref<WeaponObject>, requestedTriggerMode: gamedataTriggerMode, const duration: Float) -> Void {
  let npc: ref<NPCPuppet>;
  if IsDefined(weapon) { npc = weapon.GetOwner() as NPCPuppet; };
  if !IsDefined(npc) {
    wrappedMethod(weapon, requestedTriggerMode, duration);
    return;
  };
  let system = SDPCombatSystem.Get(npc.GetGame());
  if !SDPHitModel.Handles(system, npc) {
    wrappedMethod(weapon, requestedTriggerMode, duration);
    return;
  };

  let profile = SDPProfiles.Get(npc);
  let now = SDPHitModel.Now(npc.GetGame());
  let wp = SDPWeaponStats.Get(npc, weapon);
  let rate = SDPWeaponStats.RecoveryRate(profile, wp);
  SDPWeaponStats.AddShot(npc, wp, profile, rate, now);
  SDPWeaponStats.GrowSpread(npc, wp, now);
  let recoil = SDPWeaponStats.Residual(npc, rate, now);

  let pause: Float = 0.0;
  let acceptableLog: Float = -1.0;
  let exposureLog: Float = -1.0;
  let suppressLog = false;
  let holdLog = false;
  let player = GameInstance.GetPlayerSystem(npc.GetGame()).GetLocalPlayerMainGameObject();
  if IsDefined(player) {
    let dist = MaxF(1.0, Vector4.Distance(npc.GetWorldPosition(), player.GetWorldPosition()));
    // share of V visible at this shooter's last shot (6-point test); fall back to the game's two-point check
    let exposure = 1.0;
    if now - npc.m_sdpcExposureTime < 1.0 {
      exposure = npc.m_sdpcExposure;
    } else {
      if IsDefined(npc.GetSourceShootComponent()) && !npc.GetSourceShootComponent().CanSeeSecondaryPointOfTarget(player) { exposure = 0.45; };
    };
    let alpha = 1000.0 * 0.25 * MaxF(0.12, exposure) / dist;
    let suppress = exposure < 0.5 && profile.tier >= 2;
    exposureLog = exposure;
    suppressLog = suppress;
    if !suppress {
      let acceptable = profile.tier <= 1 ? MaxF(1.5, alpha) : MaxF(1.5, 0.5 * alpha);
      acceptableLog = acceptable;
      pause = MaxF(0.0, (recoil - acceptable) / rate);
    };
    if profile.tier >= 2 && SDPWeaponStats.OutOfRange(wp, dist) {
      pause = MaxF(pause, 1.0);
      holdLog = true;
      system.RecordOutOfRangeHold();
    };
  };
  AIWeapon.QueueNextShot(weapon, requestedTriggerMode, duration, pause);
  system.RecordPause(profile.tier, pause);
  if system.LogShots() {
    FTLog(s"[SDPCombat] pause [\(system.Segment())] \(SDPProfiles.TierName(profile.tier)) recoil=\(recoil) acceptable=\(acceptableLog) exp=\(exposureLog) suppress=\(suppressLog) outOfRangeHold=\(holdLog) pause=\(pause)");
  };
}

// First shot of a burst: bring the weapon up (AimInTime, faster with training) and react.
// If this NPC fired within the last 1.5 s the weapon is still up: only re-acquisition (reaction) applies.
@wrapMethod(AISubActionShootWithWeapon_Record_Implementation)
public final static func QueueFirstShot(weapon: wref<WeaponObject>) -> Void {
  let npc: ref<NPCPuppet>;
  if IsDefined(weapon) { npc = weapon.GetOwner() as NPCPuppet; };
  if !IsDefined(npc) {
    wrappedMethod(weapon);
    return;
  };
  let system = SDPCombatSystem.Get(npc.GetGame());
  if !SDPHitModel.Handles(system, npc) {
    wrappedMethod(weapon);
    return;
  };
  let profile = SDPProfiles.Get(npc);
  let wp = SDPWeaponStats.Get(npc, weapon);
  let now = SDPHitModel.Now(npc.GetGame());
  let raised = npc.m_sdpcRecoilTime > 0.0 && now - npc.m_sdpcRecoilTime < 1.5;
  let skill = MaxF(0.3, profile.recovery / 10.0);
  let delay = raised ? profile.reaction : wp.aimIn / skill + profile.reaction;
  if !raised { SDPWeaponStats.StartAim(npc, wp, now + delay); };
  delay = ClampF(delay, 0.05, 2.5);
  weapon.GetAIBlackboard().SetFloat(GetAllBlackboardDefs().AIShooting.nextShotTimeStamp, delay);
  system.RecordFirstShot(raised, delay);
  if system.LogShots() {
    FTLog(s"[SDPCombat] first shot [\(system.Segment())] \(SDPProfiles.TierName(profile.tier)) raised=\(raised) delay=\(delay)s aimIn=\(wp.aimIn)");
  };
}
