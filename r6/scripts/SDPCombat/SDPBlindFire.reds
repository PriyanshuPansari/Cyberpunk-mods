module SDPCombat.BlindAim

import SDPCombat.*

// Transient per-NPC memory. Only sighted shots observe the player; blind shots
// never read the player's position, pose, velocity or a live position provider.
public class SDPBlindAimMemory {
  public let seen: Bool;
  public let point: Vector4;
  public let frozen: Bool;
  public let frozenPoint: Vector4;
  public let fromSight: Bool;
}

@addField(NPCPuppet)
public let m_sdpcBlindAim: ref<SDPBlindAimMemory>;

@addField(NPCPuppet)
public let m_sdpcFrozenFireCall: Bool;

public abstract class SDPBlindFire {
  public static func Memory(npc: ref<NPCPuppet>) -> ref<SDPBlindAimMemory> {
    if !IsDefined(npc.m_sdpcBlindAim) { npc.m_sdpcBlindAim = new SDPBlindAimMemory(); };
    return npc.m_sdpcBlindAim;
  }

  public static func Observe(npc: ref<NPCPuppet>, target: ref<GameObject>) -> Void {
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(npc, n"Blind") { return; };
    let memory = SDPBlindFire.Memory(npc);
    memory.frozen = false;
    if !IsDefined(npc.GetSensesComponent()) || !npc.GetSensesComponent().IsAgentVisible(target) { return; };
    let point: Vector4;
    if !AIActionHelper.GetTargetSlotPosition(target, n"Head", point) {
      point = target.GetWorldPosition();
      point.Z += 1.6;
    };
    point.Z -= 0.15;
    memory.point = point;
    memory.seen = true;
  }

  public static func Freeze(npc: ref<NPCPuppet>) -> Vector4 {
    let memory = SDPBlindFire.Memory(npc);
    if !memory.frozen {
      memory.fromSight = memory.seen;
      if memory.seen {
        memory.frozenPoint = memory.point;
      } else {
        // No prior sighted shot: remember this facing direction once, rather
        // than discovering V through the live target supplied by the AI.
        memory.frozenPoint = npc.GetWorldPosition() + npc.GetWorldForward() * 15.0;
        memory.frozenPoint.Z += 1.4;
      };
      memory.frozen = true;
      FTLog(s"[SDPCombat] BLIND_AIM_FREEZE npc=\(EntityID.ToDebugStringDecimal(npc.GetEntityID())) source=\(memory.fromSight ? "last_sighted_shot" : "initial_facing") point=\(memory.frozenPoint)");
    };
    return memory.frozenPoint;
  }

  public static func Release(npc: ref<NPCPuppet>) -> Void {
    if IsDefined(npc.m_sdpcBlindAim) && npc.m_sdpcBlindAim.frozen {
      npc.m_sdpcBlindAim.frozen = false;
      FTLog(s"[SDPCombat] BLIND_AIM_RELEASE npc=\(EntityID.ToDebugStringDecimal(npc.GetEntityID()))");
    };
  }

  // Ordinary weapon/shooter handling around the remembered point. No Blind
  // multiplier, live-target movement, exposure queries or hit-zone prediction.
  public static func Offset(npc: ref<NPCPuppet>, weapon: ref<WeaponObject>, point: Vector4) -> Vector4 {
    let profile = SDPProfiles.Get(npc);
    let wp = SDPWeaponStats.Get(npc, weapon);
    let now = SDPHitModel.Now(npc.GetGame());
    let delta = point - weapon.GetWorldPosition();
    let dist = MaxF(1.0, Vector4.Length(delta));
    let up: Vector4;
    up.Z = 1.0;
    let right = Vector4.Normalize(Vector4.Cross(Vector4.Normalize(delta), up));
    if Vector4.IsZero(right) { right.X = 1.0; };
    let recoilX: Float;
    let recoilY: Float;
    let bloom: Float;
    SDPWeaponStats.RecoilAt(npc, SDPWeaponStats.RecoveryRate(profile, wp), now, recoilX, recoilY, bloom);
    let sw = SDPWeaponStats.ShotSigma(npc, wp, dist);
    let move = SDPWeaponStats.MovingSigma(npc, wp);
    let sigma = SqrtF(sw * sw + profile.sigmaShooter * profile.sigmaShooter + move * move + bloom * bloom);
    sigma *= SDPCEBridge.SpreadMult(npc);
    let swayX: Float;
    let swayY: Float;
    SDPWeaponStats.Sway(npc, wp, profile, now, swayX, swayY);
    let side = (SDPAim.Gaussian() * sigma + recoilX + swayX) * dist / 1000.0;
    let vertical = (SDPAim.Gaussian() * sigma + recoilY + swayY) * dist / 1000.0;
    let result = right * side;
    result.Z += vertical;
    return result;
  }
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  if IsDefined(evt) && IsDefined(evt.staticData) {
    let tags: array<CName> = evt.staticData.GameplayTags();
    if ArrayContains(tags, n"Blind") && SDPHitModel.Handles(SDPCombatSystem.Get(this.GetGame()), this) { SDPBlindFire.Freeze(this); };
  };
  return wrappedMethod(evt);
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectRemoved(evt: ref<RemoveStatusEffect>) -> Bool {
  let result = wrappedMethod(evt);
  // Overlapping native/private blind effects retain the same frozen point.
  if !StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"Blind") { SDPBlindFire.Release(this); };
  return result;
}

@wrapMethod(NPCPuppet)
protected cb func OnDetach() -> Bool {
  this.m_sdpcBlindAim = null;
  this.m_sdpcFrozenFireCall = false;
  return wrappedMethod();
}

// Native Fire can otherwise fall back to ShootForwards when its position-validity
// check rejects the remembered point. NPC facing may still follow the AI target,
// so that fallback would defeat the frozen aim. Scope the explicit-point route
// to our synchronous Fire call only; do not alter ordinary target selection.
@wrapMethod(AIActionHelper)
public final static func ShouldShootDirectlyAtTarget(weaponOwner: wref<GameObject>, weapon: wref<WeaponObject>, targetPosition: Vector4) -> Bool {
  let npc = weaponOwner as NPCPuppet;
  if IsDefined(npc) && npc.m_sdpcFrozenFireCall { return true; };
  return wrappedMethod(weaponOwner, weapon, targetPosition);
}
