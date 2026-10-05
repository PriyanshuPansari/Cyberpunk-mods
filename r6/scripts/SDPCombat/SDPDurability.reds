// SDPCombat: per-round armour and hit zones. Armour pieces, integrity and wear live in SDPArmor.reds (section 12c);
// the Protection() helper below is the old single-value model, kept for Status().
// SDPCombat Phase 1b (base): per-round armour penetration and hit zones.
// Owns armour for ranged hits between V and enrolled NPCs, in both directions (one rulebook):
//   protection  P   = 8 x R, where R = a / (1 + a) and a = Armor x the game's armour effectiveness
//                     (the same Armor stat and effectiveness the vanilla build uses, so V's chrome/clothing still matter)
//   penetration pPen = 1 / (1 + exp(-1.6 x (caliber rating - P)))
//   penetrated  -> full damage;  stopped -> blunt fraction (0.20 body, 0.30 head)
//   NPC -> V:   zone from the shooter's sampled aim point: head x2.5, torso x1.0, legs x0.6
//   V -> NPC:   head/limb multipliers stay vanilla (localized damage already applies them)
//   range:      NPC rounds lose damage with distance on the weapon's own curves, as V's already do
// Vanilla level-scaled health and weapon damage are unchanged in this base step.
module SDPCombat

public abstract class SDPDurability {

  public static func IsRangedBullet(hitEvent: ref<gameHitEvent>) -> Bool {
    let attackType = hitEvent.attackData.GetAttackType();
    return AttackData.IsRangedOnly(attackType) && !AttackData.IsDoT(hitEvent.attackData)
      && !AttackData.IsAreaOfEffect(attackType) && IsDefined(hitEvent.attackData.GetWeapon());
  }

  // 1 = enrolled NPC shooting V, 2 = V shooting an enrolled NPC, 0 = not ours
  public static func Direction(system: ref<SDPCombatSystem>, hitEvent: ref<gameHitEvent>) -> Int32 {
    if !IsDefined(system) || !system.IsEnabled() || !system.DurabilityEnabled() { return 0; };
    if !IsDefined(hitEvent.target) || !SDPDurability.IsRangedBullet(hitEvent) { return 0; };
    let instigator = hitEvent.attackData.GetInstigator();
    if !IsDefined(instigator) { return 0; };
    let npcShooter = instigator as NPCPuppet;
    if hitEvent.target.IsPlayer() && IsDefined(npcShooter) && SDPHitModel.Handles(system, npcShooter) { return 1; };
    let npcTarget = hitEvent.target as NPCPuppet;
    if instigator.IsPlayer() && IsDefined(npcTarget) && SDPHitModel.Handles(system, npcTarget) { return 2; };
    return 0;
  }

  // 0 unknown, 1 head, 2 torso, 3 legs, 4 arms (from the struck hit shape's reaction zone)
  public static func ActualPart(hitEvent: ref<gameHitEvent>) -> Int32 {
    let shapes = hitEvent.hitRepresentationResult.hitShapes;
    if ArraySize(shapes) == 0 { return 0; };
    let data = DamageSystemHelper.GetHitShapeUserDataBase(shapes[0]);
    if !IsDefined(data) { return 0; };
    let z = data.m_hitReactionZone;
    if Equals(z, EHitReactionZone.Head) { return 1; };
    if Equals(z, EHitReactionZone.ChestLeft) || Equals(z, EHitReactionZone.ChestRight) || Equals(z, EHitReactionZone.Abdomen) { return 2; };
    if Equals(z, EHitReactionZone.LegLeft) || Equals(z, EHitReactionZone.LegRight) { return 3; };
    if Equals(z, EHitReactionZone.ArmLeft) || Equals(z, EHitReactionZone.ArmRight)
      || Equals(z, EHitReactionZone.HandLeft) || Equals(z, EHitReactionZone.HandRight) { return 4; };
    return 0;
  }

  // head: top 10% of the feet-to-head-slot height and above; torso: upper half; legs: below
  public static func PartByHeight(target: ref<GameObject>, hit: Vector4) -> Int32 {
    let head: Vector4;
    if !AIActionHelper.GetTargetSlotPosition(target, n"Head", head) { return 0; };
    let feet = target.GetWorldPosition();
    let h = head.Z - feet.Z;
    if h < 0.5 { return 0; };
    let rel = (hit.Z - feet.Z) / h;
    if rel >= 0.90 { return 1; };
    if rel >= 0.50 { return 2; };
    return 3;
  }

  public static func Protection(hitEvent: ref<gameHitEvent>, out armorPoints: Float) -> Float {
    let target = hitEvent.target;
    let game = target.GetGame();
    let stats = GameInstance.GetStatsSystem(game);
    let id = Cast<StatsObjectID>(target.GetEntityID());
    let isPlayer = target.IsPlayer();
    armorPoints = stats.GetStatValue(id, gamedataStatType.Armor);
    // armoured hit shapes (helmets, plating) as in vanilla, for V's shots at NPCs
    let hitShapes = hitEvent.hitRepresentationResult.hitShapes;
    if hitEvent.attackData.GetInstigator().IsPlayer() && ArraySize(hitShapes) > 0 {
      let userData = DamageSystemHelper.GetHitShapeUserDataBase(hitShapes[0]);
      if IsDefined(userData) && DamageSystemHelper.IsHitShapeArmored(userData.m_hitShapeType) {
        armorPoints = MaxF(armorPoints, stats.GetStatValue(id, gamedataStatType.HitShapeArmor));
      };
    };
    let effectiveness = GameInstance.GetStatsDataSystem(game).GetArmorEffectivenessValue(isPlayer);
    if isPlayer { effectiveness *= stats.GetStatValue(id, gamedataStatType.ArmorEffectivenessMultiplier); };
    let a = MaxF(0.0, armorPoints * effectiveness);
    return 8.0 * a / (1.0 + a);
  }

  public static func Apply(system: ref<SDPCombatSystem>, hitEvent: ref<gameHitEvent>, direction: Int32) -> Void {
    let weapon = hitEvent.attackData.GetWeapon();
    let game = hitEvent.target.GetGame();
    let now = SDPHitModel.Now(game);
    let caliber = SDPCaliber.Penetration(weapon);

    // body part: what the engine says was struck; otherwise the shooter's sampled zone / headshot flag
    let actual = SDPDurability.ActualPart(hitEvent);
    let predicted = 0;
    let part = actual;
    if direction == 1 {
      // V's hit shapes carry no body-part data and her collision is one capsule, so the part comes from the shot's own
      // aim sample: a hit outside the sampled outline is a graze (limb rule, never fatal); a hit from a shot that was not
      // sampled (smart rounds, blind fire) counts as torso. Height is kept for the diagnostic only.
      let shooter = hitEvent.attackData.GetInstigator() as NPCPuppet;
      let sampled = IsDefined(shooter) && now - shooter.m_sdpcLastZoneTime < 0.75;
      if sampled { predicted = shooter.m_sdpcLastZone; };
      if actual == 0 { actual = SDPDurability.PartByHeight(hitEvent.target, hitEvent.hitPosition); };
      part = sampled ? (predicted > 0 ? predicted : 4) : 2;
      if !sampled { system.RecordUnsampledHit(); };
      // diagnostic: struck part against the zone the aim sample predicted
      let feet = hitEvent.target.GetWorldPosition();
      let height = hitEvent.hitPosition.Z - feet.Z;
      system.RecordPredictedVsActual(predicted, actual, height);
      if system.LogShots() {
        let headSlot: Vector4;
        let headH = AIActionHelper.GetTargetSlotPosition(hitEvent.target, n"Head", headSlot) ? headSlot.Z - feet.Z : -1.0;
        FTLog(s"[SDPCombat] hit part [\(system.Segment())] predicted=\(predicted) actual=\(actual) height=\(height)m headSlot=\(headH)m");
      };
    } else {
      if part == 0 { part = hitEvent.attackData.HasFlag(hitFlag.Headshot) ? 1 : 2; };
    };

    // armour
    let kit: ref<SDPArmorKit>;
    if direction == 1 {
      kit = system.VArmor(hitEvent.target, now);
    } else {
      kit = SDPArmor.ForNPC(hitEvent.target as NPCPuppet);
      if !kit.counted { kit.counted = true; system.NoteKit(kit.label); };
      kit.Update(now);
      SDPArmor.CheckHelmet(kit, hitEvent);
    };
    let piece = kit.Covering(part);
    let effP = 0.0;
    let pPen = 1.0;
    let penetrated = true;
    let broke = false;
    let pieceName = "none";
    if IsDefined(piece) {
      pieceName = piece.name;
      effP = SDPArmor.EffectiveRating(piece);
      pPen = 1.0 / (1.0 + ExpF(-1.6 * (caliber - effP)));
      penetrated = RandF() < pPen;
      let before = piece.integrity;
      piece.integrity = MaxF(0.0, piece.integrity - (penetrated ? 0.01 : SDPArmor.Wear(caliber, piece.rating)));
      broke = before > 0.0 && piece.integrity <= 0.0;
    };
    kit.lastHit = now;
    if direction == 1 { system.UpdateVArmorBar(); };

    // damage: vanilla numbers; armour decides how much reaches the body
    let fatal = part == 1 && penetrated;
    let mult = 1.0;
    if !penetrated { mult = part == 1 ? 0.30 : 0.20; };
    if direction == 1 && penetrated && (part == 3 || part == 4) { mult *= 0.6; };   // limbs (V has no vanilla localisation)
    let rangeMod = 1.0;
    if direction == 1 {
      rangeMod = SDPWeaponStats.RangeDamageMod(hitEvent.attackData, hitEvent.hitPosition);
      mult *= rangeMod * system.IncomingScale();
    };
    let before = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    // enemy damage = what this exact gun (record, tier, mods) does in V's hands, not the level-scaled NPC number
    let weaponFactor = 1.0;
    if direction == 1 && system.WeaponDamage() && before > 0.0 {
      let vv = system.VVersion(weapon);
      if IsDefined(vv) && vv.damage > 0.0 {
        weaponFactor = vv.damage / before;
        mult *= weaponFactor;
      };
    };
    let pools = GameInstance.GetStatPoolsSystem(game);
    let targetID = Cast<StatsObjectID>(hitEvent.target.GetEntityID());
    if fatal && before > 0.0 {
      let current = pools.GetStatPoolValue(targetID, gamedataStatPoolType.Health, false);
      mult = MaxF(mult, (current + 1.0) / before);
    };
    hitEvent.attackComputed.MultAttackValue(mult);
    let after = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);

    let maxHealth = pools.GetStatPoolMaxPointValue(targetID, gamedataStatPoolType.Health);
    let pctOfMax = maxHealth > 0.0 ? 100.0 * after / maxHealth : 0.0;
    system.RecordHit(direction, part, penetrated, pctOfMax);
    system.RecordArmor(direction, IsDefined(piece), penetrated, broke, fatal);
    system.RecordWeaponDamage(direction, weapon, before);
    if system.LogShots() {
      FTLog(s"[SDPCombat] hit [\(system.Segment())] dir=\(direction == 1 ? "NPC->V" : "V->NPC") part=\(part) armour=\(pieceName) P=\(effP) calibre=\(caliber) pPen=\(pPen) pen=\(penetrated) broke=\(broke) fatal=\(fatal) range=\(rangeMod) gunFactor=\(weaponFactor) dmg \(before)->\(after) (\(pctOfMax)% of max HP) \(kit.Describe())");
    };
  }

}

@wrapMethod(DamageSystem)
public final func ProcessArmor(hitEvent: ref<gameHitEvent>) -> Void {
  let system = SDPCombatSystem.Get(hitEvent.target.GetGame());
  let direction = SDPDurability.Direction(system, hitEvent);
  if direction == 0 {
    wrappedMethod(hitEvent);
    return;
  };
  SDPDurability.Apply(system, hitEvent, direction);
}

// Vanilla caps how much of V's health one NPC hit can take. With per-round armour this becomes a switch
// Off by default: per-round armour replaces it. SetOneShotProtection(true) restores the vanilla cap for comparison.
@wrapMethod(DamageSystem)
private final func ProcessOneShotProtection(hitEvent: ref<gameHitEvent>) -> Void {
  let system = SDPCombatSystem.Get(hitEvent.target.GetGame());
  if !system.OneShotProtection() && SDPDurability.Direction(system, hitEvent) == 1 {
    return;
  };
  wrappedMethod(hitEvent);
}

// Test god mode: every hit on V (bullets, melee, explosions, burning/bleeding ticks, falls) runs the whole
// pipeline, so telemetry sees the real damage, and is zeroed only at the last step before health changes.
// The game refuses Invulnerable for V and Immortal still lets her be downed, so this is the reliable switch.
@wrapMethod(DamageSystem)
private final func DealDamages(hitEvent: ref<gameHitEvent>) -> Void {
  if IsDefined(hitEvent.target) && hitEvent.target.IsPlayer() {
    let system = SDPCombatSystem.Get(hitEvent.target.GetGame());
    if IsDefined(system) && system.TestGodMode() {
      system.RecordAbsorbed(hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health));
      let values = hitEvent.attackComputed.GetAttackValues();
      let i = 0;
      while i < ArraySize(values) {
        values[i] = 0.0;
        i += 1;
      };
      hitEvent.attackComputed.SetAttackValues(values);
    };
  };
  wrappedMethod(hitEvent);
}
