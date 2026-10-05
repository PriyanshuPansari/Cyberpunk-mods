// Result-based use XP for shard families. These awards remain available when
// a linked skill reaches its native level cap.
module SkillDrivenProgression

public func SDP_FamilyPreferUseSource(family: Int32, grade: Int32, best: Int32, candidate: Int32) -> Int32 {
  let candidateGrade: Int32 = SDP_TrainingFamilySourceGrade(family, candidate);
  if candidateGrade == 0 || candidateGrade > grade { return best; };
  let bestGrade: Int32 = SDP_TrainingFamilySourceGrade(family, best);
  return candidateGrade > bestGrade ? candidate : best;
}

// Encounter measurement: every condition that is met counts as a trigger for
// its source, whatever the shard's grade; then picks the source as before.
@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyMeasure(family: Int32, grade: Int32, best: Int32, candidate: Int32) -> Int32 {
  this.SDP_EncounterAddTrigger(family, candidate);
  return SDP_FamilyPreferUseSource(family, grade, best, candidate);
}

@addField(PlayerDevelopmentData)
public let m_sdpFamilyLastAttack: ref<AttackData>;

@addField(PlayerDevelopmentData)
public let m_sdpFamilyLastTarget: EntityID;

@addField(PlayerDevelopmentData)
public let m_sdpFamilyLastAttackTime: Float;

@addField(PlayerDevelopmentData)
public let m_sdpFamilyDashHitUntil: Float;

@addField(PlayerDevelopmentData)
public let m_sdpFamilyDashWasAirborne: Bool;

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyNoteDash(airborne: Bool) -> Void {
  if !IsDefined(this.m_owner) { return; };
  this.SDP_ChannelOnDash(airborne);
  this.m_sdpFamilyDashWasAirborne = airborne;
  this.m_sdpFamilyDashHitUntil = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_owner.GetGame())) + 2.00;
  // Dashing in combat is enough for the base award; a hit within 2 s can
  // still earn the higher precision/kill/critical sources below.
  // TODO(refine): anti-farming (cooldown, needs a hostile nearby/aware, per-encounter falloff).
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) && player.IsInCombat() {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(4);
    let source: Int32 = 1;
    if !airborne { this.SDP_EncounterAddTrigger(4, 1); };
    if airborne { source = this.SDP_FamilyMeasure(4, grade, source, 2); };
    this.SDP_FamilyAwardUse(4, source);
  };
}

@wrapMethod(DodgeEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
    if IsDefined(data) { data.SDP_FamilyNoteDash(false); };
  };
}

@wrapMethod(DodgeAirEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
    if IsDefined(data) { data.SDP_FamilyNoteDash(true); };
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyOnDamagingHit(evt: ref<gameTargetDamageEvent>) -> Void {
  if !IsDefined(this.m_owner) || !IsDefined(evt) || evt.damage <= 0.00
    || !IsDefined(evt.attackData) || !IsDefined(evt.target)
    || evt.attackData.HasFlag(hitFlag.DamageOverTime) { return; };
  let target: ref<ScriptedPuppet> = evt.target as ScriptedPuppet;
  if !IsDefined(target) || !target.AwardsExperience() { return; };
  let targetID: EntityID = evt.target.GetEntityID();
  let attackTime: Float = evt.attackData.GetAttackTime();
  if this.m_sdpFamilyLastAttack == evt.attackData
    && this.m_sdpFamilyLastTarget == targetID
    && this.m_sdpFamilyLastAttackTime == attackTime { return; };
  this.m_sdpFamilyLastAttack = evt.attackData;
  this.m_sdpFamilyLastTarget = targetID;
  this.m_sdpFamilyLastAttackTime = attackTime;

  let weapon: ref<WeaponObject> = evt.attackData.GetWeapon();
  let itemType: gamedataItemType = gamedataItemType.Invalid;
  let evolution: gamedataWeaponEvolution = gamedataWeaponEvolution.None;
  if IsDefined(weapon) {
    itemType = WeaponObject.GetWeaponType(weapon.GetItemID());
    evolution = RPGManager.GetWeaponEvolution(weapon.GetItemID());
  };
  let attackType: gamedataAttackType = evt.attackData.GetAttackType();
  let neutralization: Bool = evt.attackData.HasFlag(hitFlag.WasKillingBlow)
    || evt.attackData.HasFlag(hitFlag.Defeated);
  let precision: Bool = evt.attackData.HasFlag(hitFlag.Headshot)
    || evt.attackData.HasFlag(hitFlag.WeakspotHit);
  let critical: Bool = evt.attackData.HasFlag(hitFlag.CriticalHit);
  let stealth: Bool = evt.attackData.HasFlag(hitFlag.StealthHit);
  let distance: Float = Vector4.Distance(this.m_owner.GetWorldPosition(), evt.target.GetWorldPosition());

  // Obliteration: actual shotgun/LMG damage, with a close kill bonus.
  if Equals(itemType, gamedataItemType.Wea_Shotgun)
    || Equals(itemType, gamedataItemType.Wea_ShotgunDual)
    || Equals(itemType, gamedataItemType.Wea_LightMachineGun) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(2);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(2, 1);
    if neutralization && distance <= 8.00 { source = this.SDP_FamilyMeasure(2, grade, source, 2); };
    if precision { source = this.SDP_FamilyMeasure(2, grade, source, 3); };
    if critical { source = this.SDP_FamilyMeasure(2, grade, source, 4); };
    if distance <= 5.00 { source = this.SDP_FamilyMeasure(2, grade, source, 5); };
    if neutralization && distance <= 5.00 { source = this.SDP_FamilyMeasure(2, grade, source, 6); };
    this.SDP_FamilyAwardUse(2, source);
  };

  // Quake and Blade Runner are separated by weapon evolution.
  if Equals(evolution, gamedataWeaponEvolution.Blunt) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(3);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(3, 1);
    if evt.attackData.HasFlag(hitFlag.ForceKnockdown) { source = this.SDP_FamilyMeasure(3, grade, source, 2); };
    if neutralization { source = this.SDP_FamilyMeasure(3, grade, source, 3); };
    if critical { source = this.SDP_FamilyMeasure(3, grade, source, 4); };
    if critical && neutralization { source = this.SDP_FamilyMeasure(3, grade, source, 5); };
    if neutralization && distance <= 5.00 { source = this.SDP_FamilyMeasure(3, grade, source, 6); };
    this.SDP_FamilyAwardUse(3, source);
  };
  if Equals(evolution, gamedataWeaponEvolution.Blade) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(6);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(6, 1);
    if neutralization { source = this.SDP_FamilyMeasure(6, grade, source, 2); };
    if critical { source = this.SDP_FamilyMeasure(6, grade, source, 3); };
    if stealth { source = this.SDP_FamilyMeasure(6, grade, source, 4); };
    if critical && neutralization { source = this.SDP_FamilyMeasure(6, grade, source, 5); };
    if neutralization && distance <= 5.00 { source = this.SDP_FamilyMeasure(6, grade, source, 6); };
    this.SDP_FamilyAwardUse(6, source);
  };

  let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_owner.GetGame()));
  if now <= this.m_sdpFamilyDashHitUntil {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(4);
    // Base sources (1 ground, 2 air) are paid on the dash itself; only the
    // hit-dependent bonus sources are awarded here.
    let source: Int32 = 0;
    if this.m_sdpFamilyDashWasAirborne {
      if precision { source = this.SDP_FamilyMeasure(4, grade, source, 4); };
      if neutralization { source = this.SDP_FamilyMeasure(4, grade, source, 5); };
      if critical { source = this.SDP_FamilyMeasure(4, grade, source, 6); };
    } else {
      if precision { source = this.SDP_FamilyMeasure(4, grade, source, 3); };
    };
    if source > 0 { this.SDP_FamilyAwardUse(4, source); };
    this.m_sdpFamilyDashHitUntil = 0.00;
  };
  if Equals(itemType, gamedataItemType.Wea_AssaultRifle)
    || Equals(itemType, gamedataItemType.Wea_SubmachineGun) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(5);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(5, 1);
    if precision { source = this.SDP_FamilyMeasure(5, grade, source, 2); };
    if critical { source = this.SDP_FamilyMeasure(5, grade, source, 3); };
    if distance >= 25.00 { source = this.SDP_FamilyMeasure(5, grade, source, 4); };
    if precision && neutralization { source = this.SDP_FamilyMeasure(5, grade, source, 5); };
    if critical && precision { source = this.SDP_FamilyMeasure(5, grade, source, 6); };
    this.SDP_FamilyAwardUse(5, source);
  };

  if Equals(itemType, gamedataItemType.Cyb_Launcher)
    || Equals(itemType, gamedataItemType.Cyb_MantisBlades)
    || Equals(itemType, gamedataItemType.Cyb_NanoWires)
    || Equals(itemType, gamedataItemType.Cyb_StrongArms) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(7);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(7, 1);
    if neutralization { source = this.SDP_FamilyMeasure(7, grade, source, 2); };
    if critical { source = this.SDP_FamilyMeasure(7, grade, source, 3); };
    if Equals(itemType, gamedataItemType.Cyb_Launcher) {
      source = this.SDP_FamilyMeasure(7, grade, source, 4);
    };
    if evt.damage >= 100.00 { source = this.SDP_FamilyMeasure(7, grade, source, 5); };
    if critical && neutralization { source = this.SDP_FamilyMeasure(7, grade, source, 6); };
    this.SDP_FamilyAwardUse(7, source);
  };
  if Equals(attackType, gamedataAttackType.Explosion) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(8);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(8, 1);
    if neutralization { source = this.SDP_FamilyMeasure(8, grade, source, 2); };
    if evt.damage >= 100.00 { source = this.SDP_FamilyMeasure(8, grade, source, 3); };
    if distance >= 15.00 { source = this.SDP_FamilyMeasure(8, grade, source, 4); };
    if evt.damage >= 200.00 { source = this.SDP_FamilyMeasure(8, grade, source, 5); };
    if neutralization && evt.damage >= 100.00 { source = this.SDP_FamilyMeasure(8, grade, source, 6); };
    this.SDP_FamilyAwardUse(8, source);
  };
  if Equals(evolution, gamedataWeaponEvolution.Tech)
    && evt.attackData.HasFlag(hitFlag.WeaponFullyCharged) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(9);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(9, 1);
    if precision { source = this.SDP_FamilyMeasure(9, grade, source, 2); };
    if critical { source = this.SDP_FamilyMeasure(9, grade, source, 3); };
    if neutralization { source = this.SDP_FamilyMeasure(9, grade, source, 4); };
    if distance >= 25.00 { source = this.SDP_FamilyMeasure(9, grade, source, 5); };
    if critical && precision { source = this.SDP_FamilyMeasure(9, grade, source, 6); };
    this.SDP_FamilyAwardUse(9, source);
    if this.SDP_FamilyActiveGrade(9) >= 4 {
      GameInstance.GetStatPoolsSystem(this.m_owner.GetGame()).RequestChangingStatPoolValue(
        Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Stamina,
        2.00, this.m_owner, false, false
      );
    };
    if neutralization && this.SDP_FamilyActiveGrade(9) >= 10 {
      GameInstance.GetStatPoolsSystem(this.m_owner.GetGame()).RequestChangingStatPoolValue(
        Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Stamina,
        5.00, this.m_owner, false, false
      );
    };
  };

  if Equals(attackType, gamedataAttackType.Hack)
    || evt.attackData.HasFlag(hitFlag.QuickHack) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(10);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(10, 1);
    if evt.damage >= 50.00 { source = this.SDP_FamilyMeasure(10, grade, source, 2); };
    if neutralization { source = this.SDP_FamilyMeasure(10, grade, source, 3); };
    if evt.damage >= 100.00 { source = this.SDP_FamilyMeasure(10, grade, source, 4); };
    if evt.damage >= 150.00 { source = this.SDP_FamilyMeasure(10, grade, source, 5); };
    if neutralization && evt.damage >= 100.00 { source = this.SDP_FamilyMeasure(10, grade, source, 6); };
    this.SDP_FamilyAwardUse(10, source);
    let queued: Float = GameInstance.GetStatsSystem(this.m_owner.GetGame()).GetStatValue(
      Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatType.QuickHackQueueCount
    );
    // Hack Queue: the queue-length sources (1, 2, 4) are paid when the hack
    // is queued (see PutActionInQuickhackQueue below); only the result
    // sources (kill, heavy damage) are awarded on the hit.
    if queued >= 1.00 {
      grade = this.SDP_FamilyTrainingGrade(11);
      source = 0;
      if neutralization { source = this.SDP_FamilyMeasure(11, grade, source, 3); };
      if evt.damage >= 100.00 { source = this.SDP_FamilyMeasure(11, grade, source, 5); };
      if neutralization && queued >= 3.00 { source = this.SDP_FamilyMeasure(11, grade, source, 6); };
      if source > 0 { this.SDP_FamilyAwardUse(11, source); };
    };
  };
  if Equals(evolution, gamedataWeaponEvolution.Smart) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(12);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(12, 1);
    if precision { source = this.SDP_FamilyMeasure(12, grade, source, 2); };
    if critical { source = this.SDP_FamilyMeasure(12, grade, source, 3); };
    if distance >= 25.00 { source = this.SDP_FamilyMeasure(12, grade, source, 4); };
    if neutralization { source = this.SDP_FamilyMeasure(12, grade, source, 5); };
    if neutralization && precision { source = this.SDP_FamilyMeasure(12, grade, source, 6); };
    this.SDP_FamilyAwardUse(12, source);
    if neutralization && this.SDP_FamilyActiveGrade(12) >= 8 {
      GameInstance.GetStatPoolsSystem(this.m_owner.GetGame()).RequestChangingStatPoolValue(
        Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Stamina,
        5.00, this.m_owner, false, false
      );
    };
  };
  if stealth {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(13);
    let source: Int32 = 0;
    if neutralization { source = this.SDP_FamilyMeasure(13, grade, source, 1); };
    source = this.SDP_FamilyMeasure(13, grade, source, 2);
    if precision { source = this.SDP_FamilyMeasure(13, grade, source, 3); };
    if neutralization && IsDefined(weapon) && weapon.IsRanged() {
      source = this.SDP_FamilyMeasure(13, grade, source, 4);
    };
    if neutralization && distance >= 25.00 { source = this.SDP_FamilyMeasure(13, grade, source, 5); };
    if neutralization && critical { source = this.SDP_FamilyMeasure(13, grade, source, 6); };
    if source > 0 { this.SDP_FamilyAwardUse(13, source); };
  };
  if Equals(attackType, gamedataAttackType.Thrown)
    && (Equals(itemType, gamedataItemType.Wea_Knife)
      || Equals(itemType, gamedataItemType.Wea_Axe)) {
    let grade: Int32 = this.SDP_FamilyTrainingGrade(14);
    let source: Int32 = 1;
    this.SDP_EncounterAddTrigger(14, 1);
    if neutralization { source = this.SDP_FamilyMeasure(14, grade, source, 2); };
    if precision { source = this.SDP_FamilyMeasure(14, grade, source, 3); };
    if stealth { source = this.SDP_FamilyMeasure(14, grade, source, 4); };
    if critical { source = this.SDP_FamilyMeasure(14, grade, source, 5); };
    if neutralization && precision { source = this.SDP_FamilyMeasure(14, grade, source, 6); };
    this.SDP_FamilyAwardUse(14, source);
  };
  if evt.attackData.HasFlag(hitFlag.VehicleDamage)
    || Equals(itemType, gamedataItemType.Wea_VehiclePowerWeapon)
    || Equals(itemType, gamedataItemType.Wea_VehicleMissileLauncher) {
    this.SDP_EncounterAddTrigger(15, 1);
    this.SDP_FamilyAwardUse(15, 1);
  };
}

@wrapMethod(ScriptedPuppet)
protected cb func OnDamageReceived(evt: ref<gameDamageReceivedEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  if this.IsPlayer() && IsDefined(evt) && evt.totalDamageReceived >= 20.00 {
    let player: ref<PlayerPuppet> = this as PlayerPuppet;
    if IsDefined(player) && player.IsInCombat() {
      let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
      let health: Float = pools.GetStatPoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatPoolType.Health, true);
      if health > 0.00 {
        let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
        if IsDefined(data) {
          let grade: Int32 = data.SDP_FamilyTrainingGrade(1);
          let source: Int32 = 1;
          data.SDP_EncounterAddTrigger(1, 1);
          if health < 50.00 { source = data.SDP_FamilyMeasure(1, grade, source, 2); };
          if evt.totalDamageReceived >= 40.00 { source = data.SDP_FamilyMeasure(1, grade, source, 3); };
          if health < 50.00 && evt.totalDamageReceived >= 40.00 {
            source = data.SDP_FamilyMeasure(1, grade, source, 4);
          };
          if evt.totalDamageReceived >= 60.00 { source = data.SDP_FamilyMeasure(1, grade, source, 5); };
          if health < 30.00 { source = data.SDP_FamilyMeasure(1, grade, source, 6); };
          data.SDP_FamilyAwardUse(1, source);
        };
      };
    };
  };
  return result;
}

// Hack Queue use XP: queueing a quickhack behind one that is already
// uploading (two hacks on the same enemy) is enough; no damage required.
// TODO(refine): anti-farming (once per target per N seconds, per-encounter falloff).
@wrapMethod(QuickHackableQueueHelper)
public final static func PutActionInQuickhackQueue(
  action: ref<ScriptableDeviceAction>,
  gameplayRoleComponent: ref<GameplayRoleComponent>,
  gameInstance: GameInstance,
  qhIndicatorSlotName: CName,
  requesterObject: ref<GameObject>
) -> Bool {
  let queued: Bool = wrappedMethod(action, gameplayRoleComponent, gameInstance, qhIndicatorSlotName, requesterObject);
  if !queued || !IsDefined(action) || !IsDefined(requesterObject) { return queued; };
  let player: ref<PlayerPuppet> = action.GetExecutor() as PlayerPuppet;
  let target: ref<ScriptedPuppet> = requesterObject as ScriptedPuppet;
  if !IsDefined(player) || !IsDefined(target) || !target.AwardsExperience() { return queued; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if !IsDefined(data) { return queued; };
  let hacks: Int32 = 2;
  let uploading: ref<ScriptableDeviceAction> = requesterObject.GetCurrentlyUploadingAction();
  if IsDefined(uploading) && IsDefined(uploading.m_deviceActionQueue) {
    hacks = uploading.m_deviceActionQueue.GetQueueSize() + 1;
  };
  let grade: Int32 = data.SDP_FamilyTrainingGrade(11);
  let source: Int32 = 1;
  data.SDP_EncounterAddTrigger(11, 1);
  if hacks >= 3 { source = data.SDP_FamilyMeasure(11, grade, source, 2); };
  if hacks >= 4 { source = data.SDP_FamilyMeasure(11, grade, source, 4); };
  data.SDP_FamilyAwardUse(11, source);
  data.SDP_ChannelOnHackQueued(Cast<Float>(action.GetCost()), hacks);
  return queued;
}
