// SDPCombat: enemy aim built from the weapon's own handling stats (the same stats that drive V's
// crosshair and recoil). Read once per NPC per weapon; every raw value is logged once per weapon
// record per session so units and mappings can be checked against real data.
//
// Derived values (angles in mrad, 1 degree = 17.453 mrad):
//   sigma     = 0.5 x base spread      (ADS default > ADS min > hip default > hip min)
//   bloom     = 0.5 x spread change per shot (ADS if present)
//   kick      = mean recoil kick per shot (ADS if present)
//   settle    = recoil recovery time (ADS if present), else kick / recovery speed
//   aimIn     = time to bring the weapon up (AimInTime)
//   crouch    = spread multiplier when fired crouched / from low cover (stored as a change: -0.25 -> x0.75)
//   hold      = RecoilHoldDuration: the kick holds this long before the muzzle starts returning
//   first shot= SpreadZeroOnFirstShot: no weapon spread on the first shot after SpreadResetTimeThreshold
//   ADS       = aimed recoil values only when RecoilUseDifferentStatsInADS is set (otherwise hip values)
//   moving    = extra spread between FastSpeedMin and FastSpeedMax of the shooter's speed
//   recoil    = each shot pushes the muzzle `kick` along RecoilDir (0 = straight up, assumed + = right),
//               randomised within +/- RecoilAngle / 2, mirrored every other shot if RecoilAlternateDir;
//               the displacement returns to centre at the settle rate
//   sway      = the sights swing side to side, a full SwaySideMinimum..MaximumAngleDistance per swing (confirmed in game:
//               the larger reading), heading within SwaySideBottom..TopAngleLimit, each swing taking SwayTraversalTime,
//               around a centre that wanders within SwayCenterMaximumAngleOffset; starts SwayStartDelay after the weapon
//               comes up, blends in over SwayStartBlendTime; scaled by the shooter's steadiness
//   drift     = RecoilDriftRandomRange: a random sideways kick each shot (zig-zag, confirmed in game), full strength once
//               the climb reaches RecoilMagForFullDrift
//   range     = spread grows from x1 at EffectiveRange to x2 at MaximumRange (and on beyond it);
//               disciplined shooters hold fire past MaximumRange (SDPCadence);
//               bullet damage follows the weapon's own range curves for NPC shots too (vanilla: V's shots only)
//   reductions= RecoilKick/Dir/AngleReduction scale those values when they are fractions (0..1)
//   growth    = sustained fire widens the cone 1/8 of the way to maximum spread per shot; it resets after
//               SpreadResetTimeThreshold at SpreadResetSpeed (the growth rule itself is in the engine, not in a stat)
// Source: an NPC-held weapon runs on the item's reduced NPC stat package (npcRPGData), which carries almost no
// handling stats, so each stat comes from the NPC package when it is set there, otherwise from the weapon record's
// own modifiers (statModifiers + statModifierGroups, recursively) evaluated by the game's own evaluator:
// the handling V's copy of the same gun has.
// A value that is missing or zero falls back to the weapon-class table in SDPProfiles (sway: none).
module SDPCombat

public class SDPWeaponProfile {
  public let record: TweakDBID;
  public let itemID: ItemID;
  public let itemType: gamedataItemType;
  public let fromStats: Bool;
  // derived
  public let sigma: Float;
  public let bloom: Float;
  public let kick: Float;
  public let settle: Float;
  public let aimIn: Float;
  public let crouchMult: Float;
  public let fastMin: Float;
  public let fastMax: Float;
  public let fastMinAdd: Float;
  public let fastMaxAdd: Float;
  public let effRange: Float;
  public let maxRange: Float;
  public let recoilDir: Float;      // degrees
  public let recoilAngle: Float;    // degrees
  public let alternate: Bool;
  public let swayMin: Float;        // degrees
  public let swayMax: Float;
  public let swayTop: Float;        // degrees of heading above horizontal
  public let swayBottom: Float;
  public let swayCenterMax: Float;  // degrees
  public let swayTraversal: Float;  // seconds per step
  public let swayDelay: Float;
  public let swayBlend: Float;
  public let swayReset: Bool;
  public let falloffDisabled: Bool;
  public let driftMin: Float;          // sideways wander per shot, as a fraction of the kick
  public let driftMax: Float;
  public let driftFull: Float;         // accumulated recoil (degrees) at which the wander is at full strength
  public let spreadDefDeg: Float;      // aimed default spread, degrees
  public let spreadMaxDeg: Float;      // aimed maximum spread, degrees
  public let resetSpeed: Float;        // SpreadResetSpeed, degrees per second
  public let hold: Float;              // seconds the kick holds before recovery starts
  public let zeroFirstShot: Bool;      // first shot after a pause has no weapon spread
  public let resetTime: Float;         // pause after which the next shot counts as a first shot
}

@addField(NPCPuppet) public let m_sdpcWeapon: ref<SDPWeaponProfile>;

public class SDPStatSource {
  public let game: GameInstance;
  public let owner: wref<GameObject>;
  public let weaponID: StatsObjectID;
  public let ownerID: StatsObjectID;
  public let mods: array<wref<StatModifier_Record>>;
  public let groups: array<TweakDBID>;
  public let fromRecord: Int32;
  public let fromRuntime: Int32;
  public let partNames: String;      // installed mod parts whose stats were added
  public let partMods: Int32;        // stat modifiers contributed by those parts

  public static func Make(npc: ref<NPCPuppet>, weapon: wref<WeaponObject>) -> ref<SDPStatSource> {
    let src = new SDPStatSource();
    src.game = weapon.GetGame();
    src.owner = npc;
    src.weaponID = Cast<StatsObjectID>(weapon.GetEntityID());
    src.ownerID = Cast<StatsObjectID>(npc.GetEntityID());
    let record = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
    if IsDefined(record) {
      let direct: array<wref<StatModifier_Record>>;
      record.StatModifiers(direct);
      for m in direct { ArrayPush(src.mods, m); };
      let groups: array<wref<StatModifierGroup_Record>>;
      record.StatModifierGroups(groups);
      for g in groups { src.AddGroup(g, 0); };
    };
    // installed mods / attachments (muzzles, scopes, weapon mods): their own stat modifiers and on-attach stats,
    // the same effects the mod has on V's gun. Receivers and magazines are the gun's base parts and are skipped.
    let data = weapon.GetItemData();
    if IsDefined(data) {
      let parts: array<InnerItemData>;
      data.GetItemParts(parts);
      for p in parts {
        let pr = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(InnerItemData.GetItemID(p)));
        if IsDefined(pr) && SDPStatSource.IsModPart(pr) {
          let before = ArraySize(src.mods);
          let pm: array<wref<StatModifier_Record>>;
          pr.StatModifiers(pm);
          for m in pm { ArrayPush(src.mods, m); };
          let pg: array<wref<StatModifierGroup_Record>>;
          pr.StatModifierGroups(pg);
          for g in pg { src.AddGroup(g, 0); };
          let packages: array<wref<GameplayLogicPackage_Record>>;
          pr.OnAttach(packages);
          for pk in packages {
            let ps: array<wref<StatModifier_Record>>;
            pk.Stats(ps);
            for m in ps { ArrayPush(src.mods, m); };
          };
          let added = ArraySize(src.mods) - before;
          if added > 0 {
            src.partMods += added;
            src.partNames += s" \(TDBID.ToStringDEBUG(pr.GetID()))(\(added))";
          };
        };
      };
    };
    return src;
  }

  public static func IsModPart(pr: ref<Item_Record>) -> Bool {
    if !IsDefined(pr.ItemType()) { return false; };
    let t = pr.ItemType().Type();
    if Equals(t, gamedataItemType.Prt_Receiver) || Equals(t, gamedataItemType.Prt_Magazine) { return false; };
    return StrBeginsWith(EnumValueToString("gamedataItemType", Cast<Int64>(EnumInt(t))), "Prt_");
  }

  public final func AddGroup(g: wref<StatModifierGroup_Record>, depth: Int32) -> Void {
    if !IsDefined(g) || depth > 8 { return; };
    let gid = g.GetID();
    if ArrayContains(this.groups, gid) { return; };
    ArrayPush(this.groups, gid);
    let list: array<wref<StatModifier_Record>>;
    g.StatModifiers(list);
    for m in list { ArrayPush(this.mods, m); };
    let related: array<wref<StatModifierGroup_Record>>;
    g.RelatedModifierGroups(related);
    for r in related { this.AddGroup(r, depth + 1); };
  }

  // The stat as the weapon record defines it (V's version of the gun), ignoring the NPC package.
  public final func RecordOnly(t: gamedataStatType) -> Float {
    let matching: array<wref<StatModifier_Record>>;
    for m in this.mods {
      if IsDefined(m) && IsDefined(m.StatType()) && Equals(m.StatType().StatType(), t) { ArrayPush(matching, m); };
    };
    if ArraySize(matching) == 0 { return 0.0; };
    return RPGManager.CalculateStatModifiers(matching, this.game, this.owner, this.weaponID, this.ownerID, this.weaponID);
  }

  public final func Runtime(t: gamedataStatType) -> Float {
    return GameInstance.GetStatsSystem(this.game).GetStatValue(this.weaponID, t);
  }

  // The stat as the NPC weapon has it; if the NPC package leaves it at 0, as the weapon record defines it.
  public final func V(t: gamedataStatType) -> Float {
    let runtime = GameInstance.GetStatsSystem(this.game).GetStatValue(this.weaponID, t);
    if runtime != 0.0 {
      this.fromRuntime += 1;
      return runtime;
    };
    let matching: array<wref<StatModifier_Record>>;
    for m in this.mods {
      if IsDefined(m) && IsDefined(m.StatType()) && Equals(m.StatType().StatType(), t) { ArrayPush(matching, m); };
    };
    if ArraySize(matching) == 0 { return 0.0; };
    this.fromRecord += 1;
    return RPGManager.CalculateStatModifiers(matching, this.game, this.owner, this.weaponID, this.ownerID, this.weaponID);
  }
}

public abstract class SDPWeaponStats {

  public static func Deg() -> Float { return 17.453; }

  public static func FirstPositive(a: Float, b: Float, c: Float, d: Float) -> Float {
    if a > 0.0 { return a; };
    if b > 0.0 { return b; };
    if c > 0.0 { return c; };
    if d > 0.0 { return d; };
    return 0.0;
  }

  public static func Get(npc: ref<NPCPuppet>, weapon: wref<WeaponObject>) -> ref<SDPWeaponProfile> {
    let record = ItemID.GetTDBID(weapon.GetItemID());
    if IsDefined(npc.m_sdpcWeapon) && npc.m_sdpcWeapon.record == record && npc.m_sdpcWeapon.itemID == weapon.GetItemID() { return npc.m_sdpcWeapon; };

    let src = SDPStatSource.Make(npc, weapon);
    let w = new SDPWeaponProfile();
    w.record = record;
    w.itemID = weapon.GetItemID();
    w.itemType = RPGManager.GetItemType(weapon.GetItemID());

    let spreadDefault = src.V(gamedataStatType.SpreadDefaultX);
    let spreadMin = src.V(gamedataStatType.SpreadMinX);
    let spreadMax = src.V(gamedataStatType.SpreadMaxX);
    let adsDefault = src.V(gamedataStatType.SpreadAdsDefaultX);
    let adsMin = src.V(gamedataStatType.SpreadAdsMinX);
    let adsMax = src.V(gamedataStatType.SpreadAdsMaxX);
    let change = src.V(gamedataStatType.SpreadChangePerShot);
    let adsChange = src.V(gamedataStatType.SpreadAdsChangePerShot);
    let kickMin = src.V(gamedataStatType.RecoilKickMin);
    let kickMax = src.V(gamedataStatType.RecoilKickMax);
    let kickMinAds = src.V(gamedataStatType.RecoilKickMinADS);
    let kickMaxAds = src.V(gamedataStatType.RecoilKickMaxADS);
    let recSpeed = src.V(gamedataStatType.RecoilRecoverySpeed);
    let recSpeedAds = src.V(gamedataStatType.RecoilRecoverySpeedADS);
    let recTime = src.V(gamedataStatType.RecoilRecoveryTime);
    let recTimeAds = src.V(gamedataStatType.RecoilRecoveryTimeADS);
    let aimIn = src.V(gamedataStatType.AimInTime);
    let crouch = src.V(gamedataStatType.SpreadCrouchDefaultMult);
    let fastMin = src.V(gamedataStatType.SpreadFastSpeedMin);
    let fastMax = src.V(gamedataStatType.SpreadFastSpeedMax);
    let fastMinAdd = src.V(gamedataStatType.SpreadFastSpeedMinAdd);
    let fastMaxAdd = src.V(gamedataStatType.SpreadFastSpeedMaxAdd);
    let effRange = src.V(gamedataStatType.EffectiveRange);
    let maxRange = src.V(gamedataStatType.MaximumRange);
    let cycle = src.V(gamedataStatType.CycleTime);
    let spreadMaxAI = src.V(gamedataStatType.SpreadMaxAI);
    let offsetAI = src.V(gamedataStatType.ShootingOffsetAI);
    let swaySide = src.V(gamedataStatType.SwaySideMaximumAngleDistance);
    let swayBottom = src.V(gamedataStatType.SwaySideBottomAngleLimit);
    let recoilDir = src.V(gamedataStatType.RecoilDir);
    let recoilAngle = src.V(gamedataStatType.RecoilAngle);
    let recoilDirAds = src.V(gamedataStatType.RecoilDirADS);
    let recoilAngleAds = src.V(gamedataStatType.RecoilAngleADS);
    let altDir = src.V(gamedataStatType.RecoilAlternateDir);
    let altDirAds = src.V(gamedataStatType.RecoilAlternateDirADS);
    let kickRed = src.V(gamedataStatType.RecoilKickReduction);
    let dirRed = src.V(gamedataStatType.RecoilDirReduction);
    let angleRed = src.V(gamedataStatType.RecoilAngleReduction);
    let driftMin = src.V(gamedataStatType.RecoilDriftRandomRangeMin);
    let driftMax = src.V(gamedataStatType.RecoilDriftRandomRangeMax);
    let recoilMaxLen = src.V(gamedataStatType.RecoilMaxLength);
    let recoilDelay = src.V(gamedataStatType.RecoilDelay);
    let recoilHold = src.V(gamedataStatType.RecoilHoldDuration);
    let allowSway = src.V(gamedataStatType.RecoilAllowSway);
    let swayMin = src.V(gamedataStatType.SwaySideMinimumAngleDistance);
    let swayTop = src.V(gamedataStatType.SwaySideTopAngleLimit);
    let swayCenter = src.V(gamedataStatType.SwayCenterMaximumAngleOffset);
    let swayTraversal = src.V(gamedataStatType.SwayTraversalTime);
    let swayDelay = src.V(gamedataStatType.SwayStartDelay);
    let swayBlend = src.V(gamedataStatType.SwayStartBlendTime);
    let swayReset = src.V(gamedataStatType.SwayResetOnAimStart);
    let swayInit = src.V(gamedataStatType.SwayInitialOffsetRandomFactor);
    let swayCurveMin = src.V(gamedataStatType.SwayCurvatureMinimumFactor);
    let swayCurveMax = src.V(gamedataStatType.SwayCurvatureMaximumFactor);
    let swayStepMin = src.V(gamedataStatType.SwaySideStepChangeMinimumFactor);
    let swayStepMax = src.V(gamedataStatType.SwaySideStepChangeMaximumFactor);

    let spreadDeg = SDPWeaponStats.FirstPositive(adsDefault, adsMin, spreadDefault, spreadMin);
    let diffAds = src.V(gamedataStatType.RecoilUseDifferentStatsInADS);
    let spreadInAds = src.V(gamedataStatType.SpreadUseInAds);
    let zeroFirst = src.V(gamedataStatType.SpreadZeroOnFirstShot);
    let resetSpeed = src.V(gamedataStatType.SpreadResetSpeed);
    let resetTime = src.V(gamedataStatType.SpreadResetTimeThreshold);
    let crouchMax = src.V(gamedataStatType.SpreadCrouchMaxMult);
    let holdAds = src.V(gamedataStatType.RecoilHoldDurationADS);
    let magDrift = src.V(gamedataStatType.RecoilMagForFullDrift);
    let scaleMax = src.V(gamedataStatType.RecoilScaleMax);
    let scaleTime = src.V(gamedataStatType.RecoilScaleTime);
    let recoilTime = src.V(gamedataStatType.RecoilTime);
    let recoilSpeed = src.V(gamedataStatType.RecoilSpeed);
    let recoilBonus = src.V(gamedataStatType.RecoilPercentBonus);
    let useAds = diffAds > 0.0 && kickMinAds + kickMaxAds > 0.0;
    let kickDeg = useAds ? 0.5 * (kickMinAds + kickMaxAds) : 0.5 * (kickMin + kickMax);
    if kickRed > 0.0 && kickRed < 1.0 { kickDeg *= 1.0 - kickRed; };
    let changeDeg = adsChange > 0.0 ? adsChange : change;

    w.fromStats = spreadDeg > 0.0 && kickDeg > 0.0;
    w.sigma = spreadDeg > 0.0 ? ClampF(0.5 * spreadDeg * SDPWeaponStats.Deg(), 0.2, 60.0) : SDPProfiles.WeaponSigma(w.itemType);
    w.kick = kickDeg > 0.0 ? ClampF(kickDeg * SDPWeaponStats.Deg(), 0.2, 80.0) : SDPProfiles.WeaponKick(w.itemType);
    w.bloom = ClampF(0.5 * changeDeg * SDPWeaponStats.Deg(), 0.0, 30.0);
    let settle = recTimeAds > 0.0 ? recTimeAds : recTime;
    let speed = recSpeedAds > 0.0 ? recSpeedAds : recSpeed;
    if settle <= 0.0 && speed > 0.0 { settle = kickDeg / speed; };
    w.settle = settle > 0.0 ? ClampF(settle, 0.05, 2.0) : 0.25;
    w.aimIn = aimIn > 0.0 ? ClampF(aimIn, 0.05, 2.0) : 0.25;
    // stored as a change (-0.25 = 25% less spread) when <= 0, as a factor when > 0
    w.crouchMult = crouch > 0.0 ? ClampF(crouch, 0.2, 2.0) : ClampF(1.0 + crouch, 0.2, 1.0);
    w.fastMin = fastMin;
    w.fastMax = fastMax;
    w.fastMinAdd = fastMinAdd;
    w.fastMaxAdd = fastMaxAdd;
    w.effRange = effRange;
    w.maxRange = maxRange;
    w.recoilDir = useAds ? recoilDirAds : recoilDir;
    w.recoilAngle = AbsF(useAds ? recoilAngleAds : recoilAngle);
    w.alternate = (useAds ? altDirAds : altDir) > 0.0;
    if dirRed > 0.0 && dirRed < 1.0 { w.recoilDir *= 1.0 - dirRed; };
    if angleRed > 0.0 && angleRed < 1.0 { w.recoilAngle *= 1.0 - angleRed; };
    w.swayMin = MaxF(0.0, swayMin);
    w.swayMax = MaxF(w.swayMin, swaySide);
    w.swayTop = swayTop;
    w.swayBottom = swayBottom;
    w.swayCenterMax = swayCenter;
    w.swayTraversal = swayTraversal > 0.05 ? swayTraversal : 1.0;
    w.swayDelay = MaxF(0.0, swayDelay);
    w.swayBlend = MaxF(0.0, swayBlend);
    w.swayReset = swayReset > 0.0;
    w.falloffDisabled = src.V(gamedataStatType.DamageFalloffDisabled) > 0.0;
    w.driftMin = MaxF(0.0, driftMin);
    w.driftMax = MaxF(w.driftMin, driftMax);
    w.driftFull = magDrift;
    w.spreadDefDeg = spreadDeg > 0.0 ? spreadDeg : w.sigma / (0.5 * SDPWeaponStats.Deg());
    let maxDeg = adsMax > 0.0 ? adsMax : spreadMax;
    w.spreadMaxDeg = maxDeg > w.spreadDefDeg ? maxDeg : w.spreadDefDeg;
    w.resetSpeed = resetSpeed > 0.0 ? resetSpeed : 2.0;
    w.hold = ClampF(useAds && holdAds > 0.0 ? holdAds : recoilHold, 0.0, 0.5);
    w.zeroFirstShot = zeroFirst > 0.0;
    w.resetTime = resetTime > 0.0 ? resetTime : 0.5;
    npc.m_sdpcWeapon = w;

    let system = SDPCombatSystem.Get(weapon.GetGame());
    if IsDefined(system) && system.FirstTimeWeaponKey(TDBID.ToStringDEBUG(record) + src.partNames) {
      FTLog(s"[SDPCombat] weapon \(TDBID.ToStringDEBUG(record)) type=\(EnumValueToString("gamedataItemType", Cast<Int64>(EnumInt(w.itemType)))) fromStats=\(w.fromStats) recordModifiers=\(ArraySize(src.mods)) groups=\(ArraySize(src.groups)) statsFromRecord=\(src.fromRecord) fromNpcPackage=\(src.fromRuntime) mods:\(src.partNames) (\(src.partMods) modifiers)");
      FTLog(s"[SDPCombat]   spread hip def/min/max=\(spreadDefault)/\(spreadMin)/\(spreadMax) ads def/min/max=\(adsDefault)/\(adsMin)/\(adsMax) perShot hip/ads=\(change)/\(adsChange) crouchMult=\(crouch)");
      FTLog(s"[SDPCombat]   recoil kick hip=\(kickMin)-\(kickMax) ads=\(kickMinAds)-\(kickMaxAds) recovery speed hip/ads=\(recSpeed)/\(recSpeedAds) time hip/ads=\(recTime)/\(recTimeAds) dir=\(recoilDir) angle=\(recoilAngle)");
      FTLog(s"[SDPCombat]   moving spread speed=\(fastMin)-\(fastMax) add=\(fastMinAdd)-\(fastMaxAdd) aimIn=\(aimIn) cycle=\(cycle) range eff/max=\(effRange)/\(maxRange) AI spreadMax/offset=\(spreadMaxAI)/\(offsetAI) sway side/bottom=\(swaySide)/\(swayBottom)");
      FTLog(s"[SDPCombat]   recoil dir hip/ads=\(recoilDir)/\(recoilDirAds) angle hip/ads=\(recoilAngle)/\(recoilAngleAds) alternate hip/ads=\(altDir)/\(altDirAds) reductions kick/dir/angle=\(kickRed)/\(dirRed)/\(angleRed) drift=\(driftMin)-\(driftMax) maxLen=\(recoilMaxLen) delay=\(recoilDelay) hold=\(recoilHold) allowSway=\(allowSway)");
      FTLog(s"[SDPCombat]   sway step=\(swayMin)-\(swaySide) heading top/bottom=\(swayTop)/\(swayBottom) centreMax=\(swayCenter) traversal=\(swayTraversal) delay=\(swayDelay) blend=\(swayBlend) reset=\(swayReset) initRand=\(swayInit) curvature=\(swayCurveMin)-\(swayCurveMax) stepChange=\(swayStepMin)-\(swayStepMax)");
      FTLog(s"[SDPCombat]   more: useDifferentAdsRecoil=\(diffAds) spreadInAds=\(spreadInAds) zeroFirstShot=\(zeroFirst) spreadReset speed/time=\(resetSpeed)/\(resetTime) crouchMaxMult=\(crouchMax) holdAds=\(holdAds) magForFullDrift=\(magDrift) scale max/time=\(scaleMax)/\(scaleTime) recoil time/speed=\(recoilTime)/\(recoilSpeed) recoilBonus=\(recoilBonus)");
      FTLog(s"[SDPCombat]   derived sigma=\(w.sigma) bloom=\(w.bloom) kick=\(w.kick) settle=\(w.settle)s aimIn=\(w.aimIn)s crouchMult=\(w.crouchMult) hold=\(w.hold)s zeroFirstShot=\(w.zeroFirstShot) recoilDir=\(w.recoilDir) recoilAngle=\(w.recoilAngle) alternate=\(w.alternate) sway=\(w.swayMin)-\(w.swayMax) range=\(w.effRange)/\(w.maxRange)");
    };
    return w;
  }

  // Spread for this shot (mrad), from the weapon's stats and the shooter's state.
  public static func ShotSigma(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>, dist: Float) -> Float {
    let sigma = w.sigma;
    let nowS = EngineTime.ToFloat(GameInstance.GetSimTime(npc.GetGame()));
    let cur = SDPWeaponStats.SpreadNow(npc, w, nowS);
    if cur > w.spreadDefDeg && w.spreadDefDeg > 0.0 { sigma *= cur / w.spreadDefDeg; };
    if w.zeroFirstShot {
      let now = EngineTime.ToFloat(GameInstance.GetSimTime(npc.GetGame()));
      if npc.m_sdpcRecoilTime <= 0.0 || now - npc.m_sdpcRecoilTime > w.resetTime { sigma = 0.0; };
    };
    if Equals(AICoverHelper.GetCurrentCoverStance(npc), n"Low") { sigma *= w.crouchMult; };
    if w.effRange > 0.0 && dist > w.effRange {
      if w.maxRange > w.effRange {
        sigma *= 1.0 + (dist - w.effRange) / (w.maxRange - w.effRange);
      } else {
        sigma *= 1.0 + 0.5 * (dist / w.effRange - 1.0);
      };
    };
    return sigma;
  }

  // Extra spread from the shooter's own movement (mrad).
  public static func MovingSigma(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>) -> Float {
    let speed = Vector4.Length(npc.GetVelocity());
    if w.fastMax > w.fastMin && (w.fastMinAdd > 0.0 || w.fastMaxAdd > 0.0) {
      if speed <= w.fastMin { return 0.0; };
      let t = ClampF((speed - w.fastMin) / (w.fastMax - w.fastMin), 0.0, 1.0);
      return 0.5 * LerpF(t, w.fastMinAdd, w.fastMaxAdd) * SDPWeaponStats.Deg();
    };
    return 1.5 * speed;
  }

  // Muzzle recovery rate (mrad/s): the weapon settles its own kick in `settle` seconds;
  // training, cyberarms and smartlink stabilisation scale that (profile.recovery 10 = trained = x1).
  public static func RecoveryRate(p: ref<SDPShooterProfile>, w: ref<SDPWeaponProfile>) -> Float {
    let skill = p.recovery / 10.0;
    return MaxF(0.5, (w.kick * p.kickMult + w.bloom) / w.settle * skill);
  }

  public static func OutOfRange(w: ref<SDPWeaponProfile>, dist: Float) -> Bool {
    return w.maxRange > 0.0 && dist > w.maxRange;
  }

  // Recoil state at `now`: the muzzle displacement returns towards centre at `rate` mrad/s, bloom shrinks at the same rate.
  public static func RecoilAt(npc: ref<NPCPuppet>, rate: Float, now: Float, out x: Float, out y: Float, out bloom: Float) -> Void {
    let w = npc.m_sdpcWeapon;
    let hold = IsDefined(w) ? w.hold : 0.0;
    let dt = MaxF(0.0, now - npc.m_sdpcRecoilTime - hold);
    let mag = SqrtF(npc.m_sdpcRecoilX * npc.m_sdpcRecoilX + npc.m_sdpcRecoilY * npc.m_sdpcRecoilY);
    let k = mag > 0.0 ? MaxF(0.0, mag - rate * dt) / mag : 0.0;
    x = npc.m_sdpcRecoilX * k;
    y = npc.m_sdpcRecoilY * k;
    bloom = MaxF(0.0, npc.m_sdpcBloom - rate * dt);
  }

  // Total residual error (mrad) the shooter is waiting out.
  public static func Residual(npc: ref<NPCPuppet>, rate: Float, now: Float) -> Float {
    let x: Float;
    let y: Float;
    let bloom: Float;
    SDPWeaponStats.RecoilAt(npc, rate, now, x, y, bloom);
    return SqrtF(x * x + y * y) + bloom;
  }

  // A shot was fired: push the muzzle along the weapon's recoil direction and grow the bloom.
  public static func AddShot(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>, p: ref<SDPShooterProfile>, rate: Float, now: Float) -> Void {
    let kick = w.kick * p.kickMult;
    let x: Float;
    let y: Float;
    let bloom: Float;
    SDPWeaponStats.RecoilAt(npc, rate, now, x, y, bloom);
    let dir = w.recoilDir;
    if w.alternate && npc.m_sdpcShotCount % 2 == 1 { dir = -dir; };
    let theta = (dir + RandRangeF(-0.5 * w.recoilAngle, 0.5 * w.recoilAngle)) * 0.0174533;
    // drift: a random sideways kick (zig-zag), a fraction driftMin..driftMax of the kick, growing with the climb
    // already built up until it reaches RecoilMagForFullDrift
    let built = SqrtF(x * x + y * y);
    let driftScale = w.driftFull > 0.0 ? ClampF(built / (w.driftFull * SDPWeaponStats.Deg()), 0.0, 1.0) : 1.0;
    let drift = kick * RandRangeF(w.driftMin, w.driftMax) * driftScale * (RandF() < 0.5 ? -1.0 : 1.0);
    npc.m_sdpcRecoilX = x + kick * SinF(theta) + drift * CosF(theta);
    npc.m_sdpcRecoilY = y + kick * CosF(theta) - drift * SinF(theta);
    npc.m_sdpcBloom = bloom + w.bloom;
    npc.m_sdpcRecoilTime = now;
    npc.m_sdpcShotCount += 1;
  }

  // The weapon has just been brought up.
  public static func StartAim(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>, now: Float) -> Void {
    npc.m_sdpcAimStart = now;
    if w.swayReset {
      npc.m_sdpcSwayFromX = 0.0;
      npc.m_sdpcSwayFromY = 0.0;
      npc.m_sdpcSwayToX = 0.0;
      npc.m_sdpcSwayToY = 0.0;
      npc.m_sdpcSwayT0 = now;
    };
  }

  // Current sway displacement (mrad) of this shooter's aim point.
  public static func Sway(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>, p: ref<SDPShooterProfile>, now: Float, out x: Float, out y: Float) -> Void {
    x = 0.0;
    y = 0.0;
    if w.swayMax <= 0.0 { return; };
    if now - npc.m_sdpcSwayT0 >= w.swayTraversal {
      // next step of the sway path
      npc.m_sdpcSwayFromX = npc.m_sdpcSwayToX;
      npc.m_sdpcSwayFromY = npc.m_sdpcSwayToY;
      // the sights swing a full step (SwaySideMinimum..MaximumAngleDistance) to the other side of a centre that
      // itself wanders within SwayCenterMaximumAngleOffset; the swing heads within the top/bottom angle limits
      let step = RandRangeF(w.swayMin, w.swayMax);
      let side = npc.m_sdpcSwayToX > 0.0 ? -1.0 : 1.0;
      let heading = RandRangeF(-w.swayBottom, w.swayTop) * 0.0174533;
      let cx = w.swayCenterMax > 0.0 ? RandRangeF(-w.swayCenterMax, w.swayCenterMax) : 0.0;
      let cy = w.swayCenterMax > 0.0 ? RandRangeF(-w.swayCenterMax, w.swayCenterMax) : 0.0;
      let toX = cx + side * 0.5 * step * CosF(heading);
      let toY = cy + 0.5 * step * SinF(heading);
      npc.m_sdpcSwayToX = toX;
      npc.m_sdpcSwayToY = toY;
      npc.m_sdpcSwayT0 = now;
    };
    let f = ClampF((now - npc.m_sdpcSwayT0) / w.swayTraversal, 0.0, 1.0);
    let held = now - npc.m_sdpcAimStart;
    let ramp = 1.0;
    if held < w.swayDelay {
      ramp = 0.0;
    } else {
      if w.swayBlend > 0.0 { ramp = ClampF((held - w.swayDelay) / w.swayBlend, 0.0, 1.0); };
    };
    let scale = ramp * p.steadiness * SDPWeaponStats.Deg();
    x = LerpF(f, npc.m_sdpcSwayFromX, npc.m_sdpcSwayToX) * scale;
    y = LerpF(f, npc.m_sdpcSwayFromY, npc.m_sdpcSwayToY) * scale;
  }

  // Damage multiplier from the weapon's own range curves, exactly as vanilla applies it to V's shots.
  public static func RangeDamageMod(attackData: ref<AttackData>, hitPosition: Vector4) -> Float {
    let weapon = attackData.GetWeapon();
    let npc = attackData.GetInstigator() as NPCPuppet;
    if !IsDefined(weapon) || !IsDefined(npc) { return 1.0; };
    let w = SDPWeaponStats.Get(npc, weapon);
    let record = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
    if !IsDefined(record) || w.effRange <= 0.0 { return 1.0; };
    let d = Vector4.Length(attackData.GetAttackPosition() - hitPosition);
    if d < w.effRange {
      if IsNameValid(record.EffectiveRangeCurve()) { return DamageSystem.GetDamageModFromCurve(record.EffectiveRangeCurve(), d); };
      return 1.0;
    };
    if IsNameValid(record.EffectiveRangeFalloffCurve()) && !w.falloffDisabled {
      return DamageSystem.GetDamageModFromCurve(record.EffectiveRangeFalloffCurve(), d - w.effRange);
    };
    return 1.0;
  }

  // Sustained-fire spread growth (built into the engine for V): each shot widens the cone by 1/8 of the way from
  // default to maximum spread; after SpreadResetTimeThreshold without firing it shrinks at SpreadResetSpeed deg/s.
  public static func GrowSpread(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>, now: Float) -> Void {
    let current = SDPWeaponStats.SpreadNow(npc, w, now);
    let step = (w.spreadMaxDeg - w.spreadDefDeg) / 8.0;
    npc.m_sdpcSpread = MinF(w.spreadMaxDeg, current + MaxF(0.0, step));
    npc.m_sdpcSpreadTime = now;
  }

  public static func SpreadNow(npc: ref<NPCPuppet>, w: ref<SDPWeaponProfile>, now: Float) -> Float {
    if npc.m_sdpcSpread < w.spreadDefDeg || npc.m_sdpcSpreadTime <= 0.0 { return w.spreadDefDeg; };
    let idle = now - npc.m_sdpcSpreadTime - w.resetTime;
    if idle <= 0.0 { return npc.m_sdpcSpread; };
    return MaxF(w.spreadDefDeg, npc.m_sdpcSpread - w.resetSpeed * idle);
  }
}

// V's version of a gun: what this exact weapon (record, tier, installed mods) does in V's hands.
public class SDPVVersion {
  public let damage: Float;      // EffectiveDamagePerHit
  public let kickMin: Float;
  public let kickMax: Float;
  public let quality: Float;
  public let mods: Int32;
  public let enemyQuality: Float;
}

// (SDPVVersions.Build removed 2026-10-06: Inventory.CreateItemData returned item data with no stats.)
