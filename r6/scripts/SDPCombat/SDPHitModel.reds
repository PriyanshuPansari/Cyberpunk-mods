// SDPCombat Phase 1: where an enrolled NPC's bullet actually goes (realism pass, section 4).
// The game asks TargetShootComponent.HandleBeingShot for an offset from its aim point near V's head,
// then fires a real projectile at aimPoint + offset; the projectile's own collision decides the hit.
// For enrolled shooters we return a sampled aim error instead of vanilla's hit-timer offset:
//   - lag:    the shooter aims where V was reaction x (1 - tracking) seconds ago (directional, not random)
//   - spread: Gaussian weapon (from the weapon's own spread stats) + skill + own-movement error, scaled by smoke / blindness
//   - recoil: accumulated muzzle displacement along the weapon's own recoil direction, plus bloom
//   - sway:   the weapon's own sway path, scaled by the shooter's steadiness
//   - aim:    6 lines of sight from the muzzle to V (head, shoulders, chest, pelvis, knees): aim at the visible
//             centre of mass, else the head, a shoulder or the knees; nothing visible = fire into the cover
// Everyone else (companions, NPC-vs-NPC, non-enrolled factions, bosses, smart/tech-pierce shots) stays vanilla.
// Estimate() re-samples the same shot 32 times for the expected on-body rate (telemetry).
module SDPCombat

public abstract class SDPHitModel {

  // Phase 1 enrollment: enabled, not a boss, and either a test faction or allHostiles.
  public static func Handles(system: ref<SDPCombatSystem>, npc: ref<NPCPuppet>) -> Bool {
    if !IsDefined(system) || !system.IsEnabled() || !IsDefined(npc) { return false; };
    if npc.IsBoss() { return false; };
    if system.AllHostiles() { return npc.IsHostile(); };
    return SDPProfiles.IsPhaseOneFaction(SDPProfiles.Get(npc).affiliation);
  }

  public static func PlayerState(target: ref<GameObject>) -> String {
    let player = target as PlayerPuppet;
    if !IsDefined(player) { return "?"; };
    return EnumValueToString("gamePSMLocomotionStates", Cast<Int64>(EnumInt(PlayerPuppet.GetCurrentLocomotionState(player))));
  }

  // Clear line from the muzzle to a point on V (stops 0.35 m short so V's own body does not block it).
  public static func Clear(game: GameInstance, from: Vector4, to: Vector4) -> Bool {
    let d = to - from;
    let len = Vector4.Length(d);
    if len < 0.6 { return true; };
    let end = from + d * ((len - 0.35) / len);
    let tr: TraceResult;
    let sq = GameInstance.GetSpatialQueriesSystem(game);
    if sq.SyncRaycastByCollisionPreset(from, end, n"World Static", tr) { return false; };
    if sq.SyncRaycastByCollisionPreset(from, end, n"World Dynamic", tr) { return false; };
    return true;
  }

  // 6-point visibility of V from the muzzle; fills the context and picks the aim point.
  //   exposure weights: head 0.12, chest 0.25, each shoulder 0.14, pelvis 0.20, knees 0.15
  //   aim: centre of mass if chest or pelvis is visible, else head, else a shoulder, else knees,
  //        else (nothing visible) the game's point: suppressive fire into the cover
  public static func Visibility(ctx: ref<SDPShotContext>, game: GameInstance, muzzle: Vector4, target: ref<GameObject>,
                                shootAtPoint: Vector4, right: Vector4) -> Void {
    let head: Vector4;
    let feet = target.GetWorldPosition();
    if !AIActionHelper.GetTargetSlotPosition(target, n"Head", head) { head = feet; head.Z += 1.6; };
    let h = MaxF(0.6, head.Z - feet.Z);
    ctx.h = h;
    ctx.gpZ = shootAtPoint.Z - feet.Z;
    let toGp = shootAtPoint - head;
    ctx.gpX = Vector4.Dot(toGp, right);

    let chest = feet; chest.Z += 0.78 * h;
    let pelvis = feet; pelvis.Z += 0.55 * h;
    let knees = feet; knees.Z += 0.28 * h;
    let shoulderR = chest + right * 0.22; shoulderR.Z += 0.07 * h;
    let shoulderL = chest - right * 0.22; shoulderL.Z += 0.07 * h;

    ctx.visHead = SDPHitModel.Clear(game, muzzle, head);
    ctx.visChest = SDPHitModel.Clear(game, muzzle, chest);
    ctx.visShoulderL = SDPHitModel.Clear(game, muzzle, shoulderL);
    ctx.visShoulderR = SDPHitModel.Clear(game, muzzle, shoulderR);
    ctx.visPelvis = SDPHitModel.Clear(game, muzzle, pelvis);
    ctx.visKnees = SDPHitModel.Clear(game, muzzle, knees);
    let e = 0.0;
    if ctx.visHead { e += 0.12; };
    if ctx.visChest { e += 0.25; };
    if ctx.visShoulderL { e += 0.14; };
    if ctx.visShoulderR { e += 0.14; };
    if ctx.visPelvis { e += 0.20; };
    if ctx.visKnees { e += 0.15; };
    ctx.exposure = e;

    let aim = shootAtPoint;
    if ctx.visChest && ctx.visPelvis {
      aim = chest * 0.6 + pelvis * 0.4;
    } else {
      if ctx.visChest { aim = chest; } else {
        if ctx.visPelvis { aim = pelvis; } else {
          if ctx.visHead { aim = head; aim.Z -= 0.05; } else {
            if ctx.visShoulderR && !ctx.visShoulderL { aim = shoulderR; } else {
              if ctx.visShoulderL && !ctx.visShoulderR { aim = shoulderL; } else {
                if ctx.visShoulderL && ctx.visShoulderR { aim = chest; } else {
                  if ctx.visKnees { aim = knees; };
                };
              };
            };
          };
        };
      };
    };
    let d = aim - shootAtPoint;
    ctx.aimR = Vector4.Dot(d, right);
    ctx.aimZ = d.Z;
  }

  public static func Now(game: GameInstance) -> Float {
    return EngineTime.ToFloat(GameInstance.GetSimTime(game));
  }

  // Estimate = share of 32 samples of the same shot model (same context, fresh random parts) that land on V's outline.
  public static func Estimate(ctx: ref<SDPShotContext>) -> Float {
    let n = 32;
    let on = 0;
    let i = 0;
    while i < n {
      let offR: Float;
      let offZ: Float;
      SDPAim.Sample(ctx, offR, offZ);
      if SDPAim.ZoneVis(ctx, offR, offZ) > 0 { on += 1; };
      i += 1;
    };
    return Cast<Float>(on) / Cast<Float>(n);
  }
}

// Everything about one shot that is fixed at the moment of firing; Sample() adds the random parts.
public class SDPShotContext {
  public let dist: Float;
  public let lateral: Float;     // V's sideways speed, m/s
  public let exposure: Float;
  public let crouched: Bool;
  public let shotgun: Bool;
  public let aimR: Float;        // chosen aim point relative to the game's aim point (metres, sideways / up)
  public let aimZ: Float;
  // V's body as the shooter sees it (6-point line-of-sight test)
  public let h: Float;           // V's feet-to-head-slot height
  public let gpZ: Float;         // game aim point height above V's feet
  public let gpX: Float;         // game aim point sideways offset from V's centre line
  public let visHead: Bool;
  public let visChest: Bool;
  public let visShoulderL: Bool;
  public let visShoulderR: Bool;
  public let visPelvis: Bool;
  public let visKnees: Bool;
  public let leadR: Float;       // directional lag, metres
  public let leadZ: Float;
  public let jinkR: Float;       // misjudged-lead sigma, metres
  public let jinkZ: Float;
  public let sigmaM: Float;      // spread sigma, metres
  public let driftR: Float;      // recoil + sway displacement, metres
  public let driftZ: Float;
}

public abstract class SDPAim {

  public static func Sample(ctx: ref<SDPShotContext>, out offR: Float, out offZ: Float) -> Void {
    offR = ctx.aimR + ctx.leadR + SDPAim.Gaussian() * ctx.jinkR + SDPAim.Gaussian() * ctx.sigmaM + ctx.driftR;
    offZ = ctx.aimZ + ctx.leadZ + SDPAim.Gaussian() * ctx.jinkZ + SDPAim.Gaussian() * ctx.sigmaM + ctx.driftZ;
    if ctx.shotgun {
      // pellet pattern centre; the spread of the pattern itself is the weapon's own
      offR = ctx.aimR + (offR - ctx.aimR) * 0.6;
      offZ = ctx.aimZ + (offZ - ctx.aimZ) * 0.6;
    };
  }

  // Zone of a sampled point on V's body, counting only the parts the shooter can see.
  //   heights as a fraction of V's feet-to-head-slot height: head 0.88-1.06, chest/shoulders 0.66-0.88,
  //   pelvis 0.45-0.66, legs 0.05-0.45.  Returns 0 miss/covered, 1 head, 2 torso, 3 legs.
  public static func ZoneVis(ctx: ref<SDPShotContext>, offR: Float, offZ: Float) -> Int32 {
    if ctx.h < 0.5 { return SDPAim.Zone(offR, offZ, ctx.exposure, ctx.crouched); };
    let rel = (ctx.gpZ + offZ) / ctx.h;
    let x = ctx.gpX + offR;
    let ax = AbsF(x);
    if rel >= 0.88 && rel <= 1.06 && ax <= 0.12 { return ctx.visHead ? 1 : 0; };
    if rel >= 0.66 && rel < 0.88 && ax <= 0.25 {
      if ax <= 0.12 { return ctx.visChest || (x > 0.0 ? ctx.visShoulderR : ctx.visShoulderL) ? 2 : 0; };
      return (x > 0.0 ? ctx.visShoulderR : ctx.visShoulderL) ? 2 : 0;
    };
    if rel >= 0.45 && rel < 0.66 && ax <= 0.20 { return ctx.visPelvis ? 2 : 0; };
    if rel >= 0.05 && rel < 0.45 && ax <= 0.18 { return ctx.visKnees ? 3 : 0; };
    return 0;
  }

  public static func Gaussian() -> Float {
    let u1 = MaxF(RandF(), 0.000001);
    let u2 = RandF();
    return SqrtF(-2.0 * LogF(u1)) * CosF(6.2831853 * u2);
  }

  // Zone of a point relative to the game's aim point (about 0.15 m below V's head slot).
  //   returns 0 miss, 1 head, 2 torso, 3 legs
  public static func Zone(offR: Float, offZ: Float, exposure: Float, crouched: Bool) -> Int32 {
    let x = AbsF(offR);
    let torsoLow = crouched ? -0.45 : -0.60;
    let legLow = crouched ? -1.00 : -1.50;
    if offZ >= 0.0 && offZ <= 0.30 && x <= 0.12 { return 1; };
    if exposure < 1.0 {
      // behind cover only head and shoulders are exposed
      if offZ < 0.0 && offZ >= -0.20 && x <= 0.25 { return 2; };
      return 0;
    };
    if offZ < 0.0 && offZ >= torsoLow && x <= 0.25 { return 2; };
    if offZ < torsoLow && offZ >= legLow && x <= 0.18 { return 3; };
    return 0;
  }
}

@wrapMethod(TargetShootComponent)
public final func HandleBeingShot(weaponOwner: wref<GameObject>, weapon: wref<WeaponObject>, shootAtPoint: Vector4, maxSpread: Float, coefficientMultiplier: Float, out miss: Bool) -> Vector4 {
  let target = this.GetGameObject();
  let shooter = weaponOwner as NPCPuppet;
  if !IsDefined(target) || !target.IsPlayer() || !IsDefined(shooter) || !IsDefined(weapon) {
    return wrappedMethod(weaponOwner, weapon, shootAtPoint, maxSpread, coefficientMultiplier, miss);
  };
  let system = SDPCombatSystem.Get(target.GetGame());
  if !SDPHitModel.Handles(system, shooter) || !IsDefined(weaponOwner.GetSourceShootComponent()) {
    return wrappedMethod(weaponOwner, weapon, shootAtPoint, maxSpread, coefficientMultiplier, miss);
  };
  // Guided smart rounds and wall-piercing tech shots keep vanilla handling in this phase.
  if Equals(weapon.GetWeaponRecord().Evolution().Type(), gamedataWeaponEvolution.Smart)
    || RPGManager.IsTechPierceEnabled(weaponOwner.GetGame(), weaponOwner, weapon.GetItemID()) {
    return wrappedMethod(weaponOwner, weapon, shootAtPoint, maxSpread, coefficientMultiplier, miss);
  };

  let profile = SDPProfiles.Get(shooter);
  let itemType = RPGManager.GetItemType(weapon.GetItemID());
  let muzzle = weapon.GetWorldPosition();
  let dist = MaxF(1.0, Vector4.Distance(muzzle, shootAtPoint));
  let fwd = Vector4.Normalize(shootAtPoint - muzzle);
  let worldUp: Vector4;
  worldUp.Z = 1.0;
  let right = Vector4.Normalize(Vector4.Cross(fwd, worldUp));

  let ctx = new SDPShotContext();
  SDPHitModel.Visibility(ctx, shooter.GetGame(), muzzle, target, shootAtPoint, right);
  let exposure = ctx.exposure;
  shooter.m_sdpcExposure = exposure;
  shooter.m_sdpcExposureTime = SDPHitModel.Now(shooter.GetGame());
  let visionBlock = this.GetVisionBlockersCoefficient(weaponOwner, target);
  let state = SDPHitModel.PlayerState(target);
  let crouched = StrContains(state, "Crouch");

  // 1. lag: aim lands where V was, reduced by how well this shooter tracks / leads
  let lag = profile.reaction * (1.0 - profile.tracking);
  if Equals(weapon.GetWeaponRecord().Evolution().Type(), gamedataWeaponEvolution.Smart) && profile.smartLink { lag *= 0.2; };
  let vel: Vector4;
  let targetPuppet = target as gamePuppet;
  if IsDefined(targetPuppet) { vel = targetPuppet.GetVelocity(); };
  let lateralV = Vector4.Dot(vel, right);
  let leadR = -lateralV * lag;
  let leadZ = -vel.Z * lag;
  // misjudged lead: a moving target jinks unpredictably; faster reactions (Kerenzikov) shrink it
  let jinkR = 0.35 * AbsF(lateralV) * profile.reaction;
  let jinkZ = 0.35 * AbsF(vel.Z) * profile.reaction;

  // 2. spread from the weapon's own handling stats (mrad -> metres at the target)
  let wp = SDPWeaponStats.Get(shooter, weapon);
  let sw = SDPWeaponStats.ShotSigma(shooter, wp, dist);
  let move = SDPWeaponStats.MovingSigma(shooter, wp);
  let now = SDPHitModel.Now(shooter.GetGame());
  let rate = SDPWeaponStats.RecoveryRate(profile, wp);
  let recoilX: Float;
  let recoilY: Float;
  let bloom: Float;
  SDPWeaponStats.RecoilAt(shooter, rate, now, recoilX, recoilY, bloom);
  let sigma = SqrtF(sw * sw + profile.sigmaShooter * profile.sigmaShooter + move * move + bloom * bloom) * MaxF(1.0, visionBlock);
  if StatusEffectSystem.ObjectHasStatusEffectWithTag(shooter, n"Blind") { sigma *= 6.0; };
  // Combat Evolved states (pinned, suppressing, panicking, repositioning, in cover, crippled arm): see SDPCEBridge
  let ceState = SDPCEBridge.State(shooter);
  let ceCrippled = SDPCEBridge.ArmCrippled(shooter);
  sigma *= SDPCEBridge.SpreadMult(shooter);
  system.RecordCEState(ceState, ceCrippled);
  let sigmaM = sigma * dist / 1000.0;

  // 3. recoil displacement (weapon's own direction) and sway (weapon's own path), mrad -> metres
  let swayX: Float;
  let swayY: Float;
  SDPWeaponStats.Sway(shooter, wp, profile, now, swayX, swayY);
  let driftR = (recoilX + swayX) * dist / 1000.0;
  let driftZ = (recoilY + swayY) * dist / 1000.0;

  // 4. aim point: centre of mass when V is fully visible, otherwise whatever is exposed
  ctx.dist = dist;
  ctx.lateral = AbsF(lateralV);
  ctx.crouched = crouched;
  ctx.shotgun = SDPProfiles.IsShotgun(itemType);
  ctx.leadR = leadR;
  ctx.leadZ = leadZ;
  ctx.jinkR = jinkR;
  ctx.jinkZ = jinkZ;
  ctx.sigmaM = sigmaM;
  ctx.driftR = driftR;
  ctx.driftZ = driftZ;
  let offR: Float;
  let offZ: Float;
  SDPAim.Sample(ctx, offR, offZ);

  // diagnostic: how far the game's aim point already is from V's real body, sideways (belief lag)
  let beliefErr = Vector4.Dot(shootAtPoint - target.GetWorldPosition(), right);

  let zone = SDPAim.ZoneVis(ctx, offR, offZ);
  miss = zone == 0;
  shooter.m_sdpcLastZone = zone;
  shooter.m_sdpcLastZoneTime = SDPHitModel.Now(shooter.GetGame());

  let latOut = ctx.lateral;
  let p = SDPHitModel.Estimate(ctx);
  system.RecordAimedShot(profile.tier, latOut, exposure, p, zone > 0);
  system.RecordAimZone(zone);
  system.RecordBeliefError(latOut, beliefErr);
  if system.LogShots() {
    FTLog(s"[SDPCombat] shot [\(system.Segment())] \(SDPProfiles.TierName(profile.tier)) wpn=\(EnumValueToString("gamedataItemType", Cast<Int64>(EnumInt(itemType)))) d=\(dist) lat=\(latOut) exp=\(exposure) vis=\(ctx.visHead ? "H" : "-")\(ctx.visShoulderL ? "L" : "-")\(ctx.visChest ? "C" : "-")\(ctx.visShoulderR ? "R" : "-")\(ctx.visPelvis ? "P" : "-")\(ctx.visKnees ? "K" : "-") aim=\(ctx.aimR)/\(ctx.aimZ) lead=\(leadR) recoil=\(recoilX)/\(recoilY) bloom=\(bloom) sway=\(swayX)/\(swayY) beliefErr=\(beliefErr) offR=\(offR) offZ=\(offZ) zone=\(zone) p=\(p) V=\(state)");
  };
  let offset: Vector4;
  offset.X = right.X * offR;
  offset.Y = right.Y * offR;
  offset.Z = right.Z * offR + offZ;
  return offset;
}

// Vanilla's AIWeapon.Fire skips HandleBeingShot when the shoot action has an aimingDelay: it aims at V's position
// that many seconds ago (its built-in reaction lag) with no offset, straight at the point just under V's head slot.
// For enrolled shooters the lag is modelled in HandleBeingShot, so the delay is removed and every shot is sampled.
@wrapMethod(AIWeapon)
public final static func Fire(weaponOwner: wref<GameObject>, weapon: wref<WeaponObject>, const timeStamp: Float, tbhCoefficient: Float,
                              requestedTriggerMode: gamedataTriggerMode, opt targetPosition: Vector4, opt target: ref<GameObject>,
                              opt rangedAttack: TweakDBID, opt maxSpreadOverride: Float, opt aimingDelay: Float, opt offset: Vector4,
                              opt shouldTrackTarget: Bool, opt predictionTime: Float, opt posProviderOverride: ref<IPositionProvider>,
                              opt muzzleOffset: Vector4, opt weaponCustomEvent: CName) -> Void {
  let delay = aimingDelay;
  let off = offset;
  if IsDefined(target) && target.IsPlayer() {
    let npc = weaponOwner as NPCPuppet;
    if IsDefined(npc) {
      let system = SDPCombatSystem.Get(npc.GetGame());
      if SDPHitModel.Handles(system, npc) {
        if delay > 0.0 {
          delay = 0.0;
          system.RecordAimingDelayRemoved();
        };
        // Vanilla only runs the aim step (HandleBeingShot) when the shooter's senses see V; otherwise it fires at
        // the believed position with no error at all. Firing at where V was last seen gets a wide scatter:
        // the shooter's own error plus 0.6 m + 3% of the distance (no sight picture to correct against).
        if !shouldTrackTarget && IsDefined(npc.GetSensesComponent()) && !npc.GetSensesComponent().IsAgentVisible(target) {
          let profile = SDPProfiles.Get(npc);
          let dist = Vector4.Distance(npc.GetWorldPosition(), target.GetWorldPosition());
          let a = profile.sigmaShooter * dist / 1000.0;
          let b = 0.6 + 0.03 * dist;
          let s = SqrtF(a * a + b * b);
          off.X += SDPAim.Gaussian() * s;
          off.Y += SDPAim.Gaussian() * s;
          off.Z += SDPAim.Gaussian() * 0.6 * s;
          system.RecordBlindShot();
        };
      };
    };
  };
  wrappedMethod(weaponOwner, weapon, timeStamp, tbhCoefficient, requestedTriggerMode, targetPosition, target, rangedAttack,
                maxSpreadOverride, delay, off, shouldTrackTarget, predictionTime, posProviderOverride, muzzleOffset, weaponCustomEvent);
}
