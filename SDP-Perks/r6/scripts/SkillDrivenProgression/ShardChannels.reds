module SkillDrivenProgression

// Shard training v2 (design/SHARD_TRAINING_V2.md, design/SHARD_XP_MODEL.md).
// Every shard earns XP from a few "channels" sized like native skill XP:
// damage (share of an enemy's Health x enemy level curve x rarity), time in a
// state, resources lost/absorbed/spent, and a few events. Everything is
// multiplied by the game's own player-level XP multiplier (XPbonusMultiplier).
// Grades (perks) only unlock or raise multipliers. Fractions carry over.
// Slot/family 0 is Deadeye (order storage); 1-15 are the other families.

// ---- Tuning ------------------------------------------------------------------

public func SDP_ChannelFamily(family: Int32) -> Bool { return family >= 0 && family <= SDP_FamilyCount(); }

// Native damage XP x this = shard XP (0.1 share x the typical 0.5 gun rate).
public func SDP_ChannelDamageShare() -> Float { return 0.05; }
public func SDP_ChannelTimeRate() -> Float { return 0.70; }      // XP per second at x1
public func SDP_ChannelHealthBarXP() -> Float { return 20.00; }  // XP per max-Health bar lost/absorbed/blocked
public func SDP_ChannelEventXP() -> Float { return 12.00; }      // XP per event at x1
public func SDP_ChannelMoveXP() -> Float { return 4.90; }        // XP per dash/dodge/slide/vault/climb
public func SDP_ChannelRamXP() -> Float { return 3.80; }         // XP per RAM of a queued quickhack
public func SDP_ChannelUploadXP() -> Float { return 3.00; }      // XP per RAM spent on a quickhack upload
public func SDP_ChannelWindowCap() -> Float { return 28.00; }    // time/event XP per 10 s window at x1

public func SDP_ChannelThreshold(family: Int32, grade: Int32) -> Int32 {
  if family >= 15 { return grade == 1 ? 150 : 0; };  // Vehicle and Expansion shards: one grade
  if grade == 1 { return 60; };
  if grade == 2 { return 110; };
  if grade == 3 { return 150; };
  if grade == 4 { return 210; };
  if grade == 5 { return 300; };
  if grade == 6 { return 430; };
  if grade == 7 { return 610; };
  if grade == 8 { return 870; };
  if grade == 9 { return 1260; };
  if grade == 10 { return 1830; };
  if grade == 11 { return 2730; };
  return 0;
}

// Channel ids start at 11 so encounter triggers don't mix with v1 sources 1-6.
// Short names: shown in the overlay, award lines and the encounter log.
public func SDP_ChannelName(family: Int32, channel: Int32) -> String {
  if family == 0 {
    if channel == 11 { return "Precision"; };
    if channel == 12 { return "Quick Draw"; };
    if channel == 13 { return "Pull!"; };
  };
  if family == 1 {
    if channel == 11 { return "Endurance"; };
    if channel == 12 { return "Punishment"; };
    if channel == 13 { return "Healing"; };
    if channel == 14 { return "Adrenaline"; };
    if channel == 15 { return "Pain to Gain"; };
  };
  if family == 2 {
    if channel == 11 { return "Carnage"; };
    if channel == 12 { return "Obliterate"; };
  };
  if family == 3 {
    if channel == 11 { return "Impact"; };
    if channel == 12 { return "Knockdown"; };
    if channel == 13 { return "Bulwark"; };
  };
  if family == 4 {
    if channel == 11 { return "Mobility"; };
    if channel == 12 { return "Air dash"; };
    if channel == 13 { return "Dash hit"; };
    if channel == 14 { return "Dash kill"; };
  };
  if family == 5 { if channel == 11 { return "Suppression"; }; };
  if family == 6 {
    if channel == 11 { return "Steel"; };
    if channel == 12 { return "Deflection"; };
    if channel == 13 { return "Finisher"; };
  };
  if family == 7 {
    if channel == 11 { return "Chrome"; };
    if channel == 12 { return "Overdrive"; };
  };
  if family == 8 {
    if channel == 11 { return "Blast"; };
    if channel == 12 { return "Supply"; };
  };
  if family == 9 { if channel == 11 { return "Charge"; }; };
  if family == 10 {
    if channel == 11 { return "Payload"; };
    if channel == 12 { return "Upload"; };
  };
  if family == 11 {
    if channel == 11 { return "Queue"; };
    if channel == 12 { return "Device hack"; };
    if channel == 13 { return "Monowire"; };
  };
  if family == 12 { if channel == 11 { return "Tracking"; }; };
  if family == 13 {
    if channel == 11 { return "Shadow"; };
    if channel == 12 { return "Silent"; };
    if channel == 13 { return "Stealth kill"; };
  };
  if family == 14 {
    if channel == 11 { return "Throw"; };
    if channel == 12 { return "Killer Instinct"; };
  };
  if family == 15 { if channel == 11 { return "Road"; }; };
  if family >= 16 && family <= 23 { if channel == 11 { return "System use"; }; };
  return "";
}

// ---- State -------------------------------------------------------------------

@addField(PlayerDevelopmentData) private persistent let m_sdpChanCarry: array<Float>;
@addField(PlayerDevelopmentData) private let m_sdpChanWindowStart: array<Float>;
@addField(PlayerDevelopmentData) private let m_sdpChanWindowXP: array<Float>;
@addField(PlayerDevelopmentData) private let m_sdpChanTargets: array<EntityID>;
@addField(PlayerDevelopmentData) private let m_sdpChanTargetFamily: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpChanTargetDealt: array<Float>;
@addField(PlayerDevelopmentData) private let m_sdpChanItemReady: Float;
// Last time each body system's cyberware was "in use" (Expansion shards).
@addField(PlayerDevelopmentData) private let m_sdpChanLastHack: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanLastArm: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanLastGun: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanLastMove: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanLastHeal: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanDashUntil: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanDashHitPaid: Bool;
@addField(PlayerDevelopmentData) private let m_sdpChanStreakTarget: EntityID;
@addField(PlayerDevelopmentData) private let m_sdpChanStreakCount: Int32;
@addField(PlayerDevelopmentData) private let m_sdpChanStreakTime: Float;
@addField(PlayerDevelopmentData) private let m_sdpChanShadowAnchor: Vector4;
@addField(PlayerDevelopmentData) private let m_sdpChanShadowStill: Float;

@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelEnsure() -> Void {
  while ArraySize(this.m_sdpChanCarry) < SDP_FamilyCount() + 1 { ArrayPush(this.m_sdpChanCarry, 0.00); };
  while ArraySize(this.m_sdpChanWindowStart) < SDP_FamilyCount() + 1 { ArrayPush(this.m_sdpChanWindowStart, -100.00); };
  while ArraySize(this.m_sdpChanWindowXP) < SDP_FamilyCount() + 1 { ArrayPush(this.m_sdpChanWindowXP, 0.00); };
}

@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelNow() -> Float {
  if !IsDefined(this.m_owner) { return 0.00; };
  return EngineTime.ToFloat(GameInstance.GetSimTime(this.m_owner.GetGame()));
}

// The game's own skill XP multiplier for the player's level (x0.48 early ... x1.8 at 50+).
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelXPMult() -> Float {
  if !IsDefined(this.m_owner) { return 1.00; };
  let value: Float = GameInstance.GetStatsSystem(this.m_owner.GetGame()).GetStatValue(
    Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatType.XPbonusMultiplier
  );
  return value > 0.00 ? value : 1.00;
}

// ---- Storage bridge (Deadeye keeps its own arrays) -----------------------------

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelGrade(family: Int32) -> Int32 {
  if family == 0 { return this.SDP_OrderDeadeyeTrainingGrade(); };
  return this.SDP_FamilyTrainingGrade(family);
}

@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelProgress(family: Int32, grade: Int32) -> Int32 {
  if family == 0 { return this.SDP_OrderDeadeyeXP(grade); };
  return this.SDP_FamilyXP(family, grade);
}

public func SDP_ChannelShardName(family: Int32) -> String {
  return family == 0 ? "Deadeye" : SDP_FamilyName(family);
}

// Adds channel XP to the shard being trained. windowed = time/event/resource
// channels, limited per 10 s window; damage channels are limited per target.
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelAward(family: Int32, channel: Int32, xp: Float, windowed: Bool) -> Int32 {
  this.SDP_EncounterAddTrigger(family, channel);
  if family < 0 || family > SDP_FamilyCount() || xp <= 0.00 { return 0; };
  let grade: Int32 = this.SDP_ChannelGrade(family);
  if grade <= 0 { return 0; };
  this.SDP_ChannelEnsure();
  this.SDP_TuningEnsureData();
  let scale: Float = this.m_sdpTuningXPScales[family];
  // A disabled family preserves its fractional progress and limiter budget.
  if scale <= 0.00 { return 0; };
  let amount: Float = xp;
  if windowed {
    let now: Float = this.SDP_ChannelNow();
    if now - this.m_sdpChanWindowStart[family] >= 10.00 || now < this.m_sdpChanWindowStart[family] {
      this.m_sdpChanWindowStart[family] = now;
      this.m_sdpChanWindowXP[family] = 0.00;
    };
    let room: Float = SDP_ChannelWindowCap() * this.SDP_ChannelXPMult() - this.m_sdpChanWindowXP[family];
    if room <= 0.00 { return 0; };
    amount = MinF(amount, room);
    this.m_sdpChanWindowXP[family] += amount;
  };
  // Limit the base channel first, then scale both damage and capped channels.
  // This keeps 500% useful even when an event channel reaches its base cap.
  let total: Float = this.m_sdpChanCarry[family] + amount * scale;
  let whole: Int32 = FloorF(total + 0.00001);
  this.m_sdpChanCarry[family] = total - Cast<Float>(whole);
  if whole <= 0 { return 0; };
  let awarded: Int32 = family == 0
    ? this.SDP_OrderAddDeadeyeXP(whole, true)
    : this.SDP_FamilyAddXP(family, whole, true);
  if awarded > 0 {
    let line: String = SDP_ChannelShardName(family) + " " + SDP_FamilyGradeLabel(grade) + "  "
      + SDP_ChannelName(family, channel) + "  +" + IntToString(awarded) + " XP  "
      + IntToString(this.SDP_ChannelProgress(family, grade)) + "/" + IntToString(SDP_ChannelThreshold(family, grade));
    ArrayPush(this.m_sdpTuningAwardLines, line);
    if ArraySize(this.m_sdpTuningAwardLines) > 24 { ArrayErase(this.m_sdpTuningAwardLines, 0); };
    this.m_sdpTuningAwardSequence += 1;
    this.SDP_EncounterAddShard(family, awarded);
    this.SDP_EncounterAddChannelXP(family, channel, awarded);
  };
  return awarded;
}

// An event channel that pays from grade `unlock`; before that it is only counted.
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelEvent(family: Int32, channel: Int32, unlock: Int32, scale: Float) -> Void {
  if this.SDP_ChannelGrade(family) >= unlock {
    this.SDP_ChannelAward(family, channel, SDP_ChannelEventXP() * scale * this.SDP_ChannelXPMult(), true);
  } else {
    this.SDP_EncounterAddTrigger(family, channel);
  };
}

// Share (0-100) of this enemy's Health that still pays this family: each enemy
// pays each shard for at most 100% of its Health, however it is healed.
@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelTargetShare(target: EntityID, family: Int32, percent: Float) -> Float {
  let index: Int32 = ArraySize(this.m_sdpChanTargets) - 1;
  while index >= 0 {
    if this.m_sdpChanTargetFamily[index] == family && this.m_sdpChanTargets[index] == target {
      let allowed: Float = MaxF(0.00, MinF(percent, 100.00 - this.m_sdpChanTargetDealt[index]));
      this.m_sdpChanTargetDealt[index] += allowed;
      return allowed;
    };
    index -= 1;
  };
  ArrayPush(this.m_sdpChanTargets, target);
  ArrayPush(this.m_sdpChanTargetFamily, family);
  ArrayPush(this.m_sdpChanTargetDealt, MinF(percent, 100.00));
  if ArraySize(this.m_sdpChanTargets) > 160 {
    ArrayErase(this.m_sdpChanTargets, 0);
    ArrayErase(this.m_sdpChanTargetFamily, 0);
    ArrayErase(this.m_sdpChanTargetDealt, 0);
  };
  return MinF(percent, 100.00);
}

@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelDamage(family: Int32, channel: Int32, target: EntityID, percent: Float, unitXP: Float, mult: Float) -> Void {
  let share: Float = this.SDP_ChannelTargetShare(target, family, percent);
  if share <= 0.00 { return; };
  this.SDP_ChannelAward(family, channel, unitXP * share * mult, false);
}

public func SDP_ChannelIsObliterationWeapon(type: gamedataItemType) -> Bool {
  return Equals(type, gamedataItemType.Wea_Shotgun)
    || Equals(type, gamedataItemType.Wea_ShotgunDual)
    || Equals(type, gamedataItemType.Wea_LightMachineGun)
    || Equals(type, gamedataItemType.Wea_HeavyMachineGun);
}

public func SDP_ChannelIsPrecisionWeapon(type: gamedataItemType) -> Bool {
  return Equals(type, gamedataItemType.Wea_Handgun)
    || Equals(type, gamedataItemType.Wea_Revolver)
    || Equals(type, gamedataItemType.Wea_SniperRifle)
    || Equals(type, gamedataItemType.Wea_PrecisionRifle);
}

public func SDP_ChannelIsBluntWeapon(type: gamedataItemType, evolution: gamedataWeaponEvolution) -> Bool {
  return Equals(evolution, gamedataWeaponEvolution.Blunt)
    || Equals(type, gamedataItemType.Wea_Hammer)
    || Equals(type, gamedataItemType.Wea_OneHandedClub)
    || Equals(type, gamedataItemType.Wea_TwoHandedClub)
    || Equals(type, gamedataItemType.Wea_Fists);
}

public func SDP_ChannelIsKnife(type: gamedataItemType) -> Bool {
  return Equals(type, gamedataItemType.Wea_Knife) || Equals(type, gamedataItemType.Wea_Axe);
}

// ---- Damage channels (same inputs as native damage XP) -------------------------

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnDamage(hitEvent: ref<gameHitEvent>, target: ref<NPCPuppet>, percent: Float) -> Void {
  if !IsDefined(this.m_owner) { return; };
  let attack: ref<AttackData> = hitEvent.attackData;
  let game: GameInstance = this.m_owner.GetGame();
  let targetID: EntityID = target.GetEntityID();
  let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
  let power: Float = GameInstance.GetStatsSystem(game).GetStatValue(
    Cast<StatsObjectID>(targetID), gamedataStatType.PowerLevel
  );
  let curve: Float = GameInstance.GetStatsDataSystem(game).GetValueFromCurve(
    n"activity_to_proficiency_xp", power, n"damage_to_skill_xp"
  );
  if curve <= 0.00 { curve = 1.00; };
  let rarity: Float = RPGManager.GetRarityMultiplier(target, n"power_level_to_dmg_xp_mult");
  if rarity <= 0.00 { rarity = 1.00; };
  let precision: Bool = attack.HasFlag(hitFlag.Headshot) || attack.HasFlag(hitFlag.WeakspotHit);
  // XP per 1% of the target's Health, native-sized; precision/finisher x1.1 like native.
  let unit: Float = curve * rarity * SDP_ChannelDamageShare() * this.SDP_ChannelXPMult();
  if precision || attack.HasFlag(hitFlag.FinisherTriggered) { unit *= 1.10; };

  let distance: Float = Vector4.Distance(this.m_owner.GetWorldPosition(), target.GetWorldPosition());
  let attackType: gamedataAttackType = attack.GetAttackType();
  let weapon: ref<WeaponObject> = attack.GetWeapon();
  let type: gamedataItemType = gamedataItemType.Invalid;
  let evolution: gamedataWeaponEvolution = gamedataWeaponEvolution.None;
  let smart: Bool = false;
  let tech: Bool = false;
  if IsDefined(weapon) {
    type = WeaponObject.GetWeaponType(weapon.GetItemID());
    evolution = RPGManager.GetWeaponEvolution(weapon.GetItemID());
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
    if IsDefined(record) {
      smart = record.TagsContains(n"SmartWeapon");
      tech = record.TagsContains(n"TechWeapon");
    };
  };
  if Equals(type, gamedataItemType.Cyb_StrongArms) || Equals(type, gamedataItemType.Cyb_MantisBlades)
    || Equals(type, gamedataItemType.Cyb_NanoWires) || Equals(type, gamedataItemType.Cyb_Launcher) {
    this.m_sdpChanLastArm = this.SDP_ChannelNow();
  } else {
    if IsDefined(weapon) && weapon.IsRanged() { this.m_sdpChanLastGun = this.SDP_ChannelNow(); };
  };
  let thrown: Bool = Equals(attackType, gamedataAttackType.Thrown);
  let strong: Bool = Equals(attackType, gamedataAttackType.StrongMelee);
  let explosion: Bool = Equals(attackType, gamedataAttackType.Explosion)
    || IsDefined(attack.GetSource() as BaseGrenade)
    || IsDefined(attack.GetSource() as ProjectileLauncherRound);
  let hack: Bool = Equals(attackType, gamedataAttackType.Hack) || attack.HasFlag(hitFlag.QuickHack);
  let stealth: Bool = attack.HasFlag(hitFlag.StealthHit);
  let grade: Int32;
  let mult: Float;

  // Obliteration: shotgun/LMG/HMG.
  if SDP_ChannelIsObliterationWeapon(type) && !explosion {
    grade = this.SDP_ChannelGrade(2);
    mult = 1.00;
    if grade >= 3 && distance <= 8.00 { mult *= 1.50; };
    if grade >= 4 && pools.GetStatPoolValue(
        Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Stamina, true) < 50.00 {
      mult *= 1.25;
    };
    if grade >= 5 {
      let healthBefore: Float = MinF(100.00,
        pools.GetStatPoolValue(Cast<StatsObjectID>(targetID), gamedataStatPoolType.Health, true) + percent);
      mult *= 1.00 + (1.00 - MaxF(0.00, healthBefore) / 100.00);
    };
    this.SDP_ChannelDamage(2, 11, targetID, percent, unit, mult);
  };
  // Quake: blunt weapons and fists.
  if SDP_ChannelIsBluntWeapon(type, evolution) && !thrown {
    grade = this.SDP_ChannelGrade(3);
    mult = 1.00;
    if grade >= 7 && strong { mult *= 1.25; };
    this.SDP_ChannelDamage(3, 11, targetID, percent, unit, mult);
  };
  // Sharpshooter: assault rifles and SMGs; sustained fire on one target.
  if Equals(type, gamedataItemType.Wea_AssaultRifle) || Equals(type, gamedataItemType.Wea_SubmachineGun)
    || Equals(type, gamedataItemType.Wea_Rifle) {
    grade = this.SDP_ChannelGrade(5);
    let now: Float = this.SDP_ChannelNow();
    if this.m_sdpChanStreakTarget == targetID && now - this.m_sdpChanStreakTime <= 2.00 {
      this.m_sdpChanStreakCount += 1;
    } else {
      this.m_sdpChanStreakTarget = targetID;
      this.m_sdpChanStreakCount = 0;
    };
    this.m_sdpChanStreakTime = now;
    mult = 1.00;
    if grade >= 5 { mult *= 1.00 + 0.05 * Cast<Float>(Min(this.m_sdpChanStreakCount, 10)); };
    if grade >= 7 && distance >= 25.00 { mult *= 1.25; };
    this.SDP_ChannelDamage(5, 11, targetID, percent, unit, mult);
  };
  // Blade Runner: blades (not knives/axes, which are Juggler's).
  if Equals(evolution, gamedataWeaponEvolution.Blade) && !thrown && !SDP_ChannelIsKnife(type)
    && !Equals(type, gamedataItemType.Cyb_MantisBlades) {
    grade = this.SDP_ChannelGrade(6);
    mult = 1.00;
    if grade >= 7 && strong { mult *= 1.25; };
    if grade >= 11 && StatusEffectSystem.ObjectHasStatusEffectOfType(target, gamedataStatusEffectType.Bleeding) {
      mult *= 1.25;
    };
    this.SDP_ChannelDamage(6, 11, targetID, percent, unit, mult);
  };
  // Chrome: Gorilla Arms, Mantis Blades, Projectile Launch System.
  if Equals(type, gamedataItemType.Cyb_StrongArms) || Equals(type, gamedataItemType.Cyb_MantisBlades)
    || Equals(type, gamedataItemType.Cyb_Launcher) {
    grade = this.SDP_ChannelGrade(7);
    mult = 1.00;
    if grade >= 7 && Equals(type, gamedataItemType.Cyb_Launcher) { mult *= 1.50; };
    this.SDP_ChannelDamage(7, 11, targetID, percent, unit, mult);
  };
  // Pyromania: explosions (grenades, launcher rounds, explosive attacks).
  if explosion {
    grade = this.SDP_ChannelGrade(8);
    mult = 1.00;
    if grade >= 7 && distance >= 15.00 { mult *= 1.25; };
    this.SDP_ChannelDamage(8, 11, targetID, percent, unit, mult);
  };
  // Bolt: Tech weapons, more for charged and timed shots.
  if (tech || Equals(evolution, gamedataWeaponEvolution.Tech)) && !explosion {
    grade = this.SDP_ChannelGrade(9);
    mult = 1.00;
    if attack.HasFlag(hitFlag.WeaponFullyCharged) { mult *= 1.50; };
    if grade >= 5 && attack.HasFlag(hitFlag.PerfectlyCharged) { mult *= 1.50; };
    this.SDP_ChannelDamage(9, 11, targetID, percent, unit, mult);
  };
  // Overclock: quickhack damage.
  if hack {
    grade = this.SDP_ChannelGrade(10);
    mult = 1.00;
    if grade >= 5 && StatusEffectSystem.ObjectHasStatusEffect(this.m_owner,
        t"BaseStatusEffect.Intelligence_Central_Milestone_3_Overclock_Buff") {
      mult *= 2.00;
    };
    this.SDP_ChannelDamage(10, 11, targetID, percent, unit, mult);
  };
  // Hack Queue: Monowire (Siphon, g9).
  if Equals(type, gamedataItemType.Cyb_NanoWires) {
    if this.SDP_ChannelGrade(11) >= 9 { this.SDP_ChannelDamage(11, 13, targetID, percent, unit, 1.00); }
    else { this.SDP_EncounterAddTrigger(11, 13); };
  };
  // Smart Lock: Smart weapons.
  if smart || Equals(evolution, gamedataWeaponEvolution.Smart) {
    grade = this.SDP_ChannelGrade(12);
    mult = 1.00;
    if grade >= 7 && distance >= 25.00 { mult *= 1.25; };
    this.SDP_ChannelDamage(12, 11, targetID, percent, unit, mult);
  };
  // Ninjutsu: stealth damage (native x0.7).
  if stealth {
    this.SDP_ChannelDamage(13, 12, targetID, percent, unit, 0.70);
  };
  // Juggler: thrown knives/axes; Killer Instinct = knife/axe melee and ranged stealth hits.
  if SDP_ChannelIsKnife(type) && thrown {
    grade = this.SDP_ChannelGrade(14);
    mult = 1.00;
    if grade >= 3 && precision { mult *= 1.50; };
    if grade >= 3 && StatusEffectSystem.ObjectHasStatusEffectOfType(target, gamedataStatusEffectType.Poisoned) {
      mult *= 1.25;
    };
    this.SDP_ChannelDamage(14, 11, targetID, percent, unit, mult);
  } else {
    if SDP_ChannelIsKnife(type) || (stealth && IsDefined(weapon) && weapon.IsRanged()) {
      this.SDP_ChannelDamage(14, 12, targetID, percent, unit, 0.50);
    };
  };
  // Deadeye: precision guns, more in Focus / Deadeye, precise and at range.
  if SDP_ChannelIsPrecisionWeapon(type) {
    grade = this.SDP_ChannelGrade(0);
    mult = 1.00;
    if StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"FocusedCoolPerkSE") { mult *= 1.25; };
    if grade >= 2 && precision { mult *= 1.50; };
    if grade >= 5 && StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"DeadeyeSE") { mult *= 1.50; };
    if grade >= 6 && distance >= 25.00 { mult *= 1.25; };
    this.SDP_ChannelDamage(0, 11, targetID, percent, unit, mult);
  };
  // Vehicle: vehicle weapons.
  if attack.HasFlag(hitFlag.VehicleDamage)
    || Equals(type, gamedataItemType.Wea_VehiclePowerWeapon)
    || Equals(type, gamedataItemType.Wea_VehicleMissileLauncher) {
    this.SDP_ChannelDamage(15, 11, targetID, percent, unit, 1.00);
  };
}

// Kill/flag events, from OnDamageDealt (gameTargetDamageEvent carries the flags).
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnDamageDealt(evt: ref<gameTargetDamageEvent>) -> Void {
  if !IsDefined(this.m_owner) || !IsDefined(evt) || !IsDefined(evt.attackData) || !IsDefined(evt.target) || evt.damage <= 0.00 { return; };
  let target: ref<ScriptedPuppet> = evt.target as ScriptedPuppet;
  if !IsDefined(target) || !target.AwardsExperience() { return; };
  let attack: ref<AttackData> = evt.attackData;
  let kill: Bool = attack.HasFlag(hitFlag.WasKillingBlow) || attack.HasFlag(hitFlag.Defeated);
  let weapon: ref<WeaponObject> = attack.GetWeapon();
  let type: gamedataItemType = gamedataItemType.Invalid;
  let evolution: gamedataWeaponEvolution = gamedataWeaponEvolution.None;
  if IsDefined(weapon) {
    type = WeaponObject.GetWeaponType(weapon.GetItemID());
    evolution = RPGManager.GetWeaponEvolution(weapon.GetItemID());
  };
  let now: Float = this.SDP_ChannelNow();

  // Air Dash: first hit within 2 s of a dash (g7), a kill within 2 s (g10).
  if now <= this.m_sdpChanDashUntil {
    if !this.m_sdpChanDashHitPaid {
      this.m_sdpChanDashHitPaid = true;
      this.SDP_ChannelEvent(4, 13, 7, 0.40);
    };
    if kill { this.SDP_ChannelEvent(4, 14, 10, 1.00); };
  };
  // Quake: knockdown with a blunt weapon (g2).
  if attack.HasFlag(hitFlag.ForceKnockdown) && SDP_ChannelIsBluntWeapon(type, evolution) {
    this.SDP_ChannelEvent(3, 12, 2, 0.50);
  };
  // Blade Runner: blade finisher (g5).
  if attack.HasFlag(hitFlag.FinisherTriggered) && Equals(evolution, gamedataWeaponEvolution.Blade) {
    this.SDP_ChannelEvent(6, 13, 5, 1.00);
  };
  if !kill { return; };
  // Adrenaline, Pain to Gain: a kill while Adrenaline (the yellow bar) is up (g11).
  let adrenaline: Float = GameInstance.GetStatPoolsSystem(this.m_owner.GetGame()).GetStatPoolValue(
    Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Overshield, false
  );
  if adrenaline > 0.00 { this.SDP_ChannelEvent(1, 15, 11, 1.00); };
  // Obliteration: a shotgun/LMG/HMG kill that dismembers (g5).
  if SDP_ChannelIsObliterationWeapon(type) && attack.HasFlag(hitFlag.ForceDismember) {
    this.SDP_ChannelEvent(2, 12, 5, 1.00);
  };
  // Ninjutsu: stealth kill (g11).
  if attack.HasFlag(hitFlag.StealthHit) { this.SDP_ChannelEvent(13, 13, 11, 1.00); };
}

// ---- Time channels (0.5 s player loop) ------------------------------------------

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelTick(seconds: Float) -> Void {
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if !IsDefined(player) { return; };
  let game: GameInstance = player.GetGame();
  let id: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
  let blackboard: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  let locomotion: gamePSMLocomotionStates = gamePSMLocomotionStates.Default;
  let zone: gamePSMZones = gamePSMZones.Default;
  if IsDefined(blackboard) {
    locomotion = IntEnum<gamePSMLocomotionStates>(blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion));
    zone = IntEnum<gamePSMZones>(blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Zones));
  };
  let rate: Float = SDP_ChannelTimeRate() * seconds * this.SDP_ChannelXPMult();
  let crouched: Bool = Equals(locomotion, gamePSMLocomotionStates.Crouch)
    || Equals(locomotion, gamePSMLocomotionStates.CrouchSprint)
    || Equals(locomotion, gamePSMLocomotionStates.CrouchDodge);

  // Ninjutsu, Shadow: sneaking (crouched, before combat) with enemies or
  // cameras within 20 m. Staying on one spot pays for 5 s at most; moving
  // more than 3 m starts a new spot.
  if !player.IsInCombat() {
    if crouched && this.SDP_ChannelWatchersNearby(player) {
      let here: Vector4 = player.GetWorldPosition();
      if Vector4.Distance(here, this.m_sdpChanShadowAnchor) > 3.00 {
        this.m_sdpChanShadowAnchor = here;
        this.m_sdpChanShadowStill = 0.00;
      } else {
        this.m_sdpChanShadowStill += seconds;
      };
      if this.m_sdpChanShadowStill <= 5.00 {
        let mult: Float = 1.00;
        if this.SDP_ChannelGrade(13) >= 5 && Equals(locomotion, gamePSMLocomotionStates.CrouchSprint) { mult *= 1.50; };
        this.SDP_ChannelAward(13, 11, rate * mult, true);
      } else {
        this.SDP_EncounterAddTrigger(13, 11);
      };
    };
    return;
  };

  // Chrome, Overdrive: combat time with Sandevistan/Berserk/Optical Camo/Kerenzikov active.
  if StatusEffectSystem.ObjectHasStatusEffectOfType(player, gamedataStatusEffectType.Sandevistan)
    || StatusEffectSystem.ObjectHasStatusEffectOfType(player, gamedataStatusEffectType.Berserk)
    || StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"CamoActiveOnPlayer")
    || Equals(locomotion, gamePSMLocomotionStates.Kereznikov) {
    this.SDP_ChannelAward(7, 12, rate, true);
  };

  this.SDP_ChannelExpansionTick(player, locomotion, rate);

  // Adrenaline, Endurance: combat time below full Health.
  let health: Float = GameInstance.GetStatPoolsSystem(game).GetStatPoolValue(id, gamedataStatPoolType.Health, true);
  if health >= 99.50 || health <= 0.00 { return; };
  let grade: Int32 = this.SDP_ChannelGrade(1);
  let mult: Float = 1.00;
  if grade >= 3 && Vector4.Length(player.GetVelocity()) > 2.00 { mult *= 1.50; };  // Speed Junkie
  if grade >= 3 && health < 50.00 { mult *= 2.00; };                                  // Comeback Kid
  if grade >= 7 {                                                                     // Army of One
    let threats: array<TrackedLocation> = player.GetTargetTrackerComponent().GetHostileThreats(false);
    let nearby: Int32 = 0;
    let i: Int32 = 0;
    while i < ArraySize(threats) {
      let enemy: ref<GameObject> = threats[i].entity as GameObject;
      if IsDefined(enemy)
        && Vector4.Distance(player.GetWorldPosition(), enemy.GetWorldPosition()) <= 20.00 {
        nearby += 1;
      };
      i += 1;
    };
    mult *= Cast<Float>(Max(1, Min(nearby, 4)));
  };
  this.SDP_ChannelAward(1, 11, rate * mult, true);
}

// Enemies (hostile NPCs, or any non-friendly NPC in a restricted/hostile zone)
// or cameras/turrets within 20 m of the player.
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelWatchersNearby(player: ref<PlayerPuppet>) -> Bool {
  let query: TargetSearchQuery;
  query.testedSet = TargetingSet.Complete;
  query.maxDistance = 20.00;
  query.filterObjectByDistance = true;
  query.includeSecondaryTargets = false;
  query.ignoreInstigator = true;
  let parts: array<TS_TargetPartInfo>;
  GameInstance.GetTargetingSystem(player.GetGame()).GetTargetParts(player, query, parts);
  let blackboard: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
  let zone: gamePSMZones = gamePSMZones.Default;
  if IsDefined(blackboard) {
    zone = IntEnum<gamePSMZones>(blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Zones));
  };
  let hostileZone: Bool = Equals(zone, gamePSMZones.Restricted) || Equals(zone, gamePSMZones.Dangerous);
  let i: Int32 = 0;
  while i < ArraySize(parts) {
    let component: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(component) {
      let object: ref<GameObject> = component.GetEntity() as GameObject;
      if IsDefined(object) && Vector4.Distance(player.GetWorldPosition(), object.GetWorldPosition()) <= 20.00 {
        if IsDefined(object as SurveillanceCamera) || IsDefined(object as SecurityTurret) { return true; };
        let npc: ref<NPCPuppet> = object as NPCPuppet;
        if IsDefined(npc) && !npc.IsDead() && !ScriptedPuppet.IsDefeated(npc) {
          let attitude: EAIAttitude = GameObject.GetAttitudeBetween(npc, player);
          if Equals(attitude, EAIAttitude.AIA_Hostile) { return true; };
          if hostileZone && !Equals(attitude, EAIAttitude.AIA_Friendly) { return true; };
        };
      };
    };
    i += 1;
  };
  return false;
}

// Expansion shards (16-23), "System use": combat time with cyberware in that
// body system equipped (half rate for one item, full for two or more), x2
// while the system is in use.
@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelExpansionTick(player: ref<PlayerPuppet>, locomotion: gamePSMLocomotionStates, rate: Float) -> Void {
  let now: Float = this.SDP_ChannelNow();
  let family: Int32 = 16;
  while family <= 23 {
    let count: Int32 = this.SDP_ExpansionEquippedCount(family);
    if count > 0 {
      let inUse: Bool = false;
      if family == 16 {
        inUse = StatusEffectSystem.ObjectHasStatusEffectOfType(player, gamedataStatusEffectType.Sandevistan)
          || StatusEffectSystem.ObjectHasStatusEffectOfType(player, gamedataStatusEffectType.Berserk)
          || StatusEffectSystem.ObjectHasStatusEffect(player, t"BaseStatusEffect.Intelligence_Central_Milestone_3_Overclock_Buff");
      };
      if family == 17 { inUse = now - this.m_sdpChanLastHack <= 5.00; };
      if family == 18 { inUse = now - this.m_sdpChanLastHeal <= 10.00; };
      if family == 19 { inUse = Equals(locomotion, gamePSMLocomotionStates.Kereznikov); };
      if family == 20 { inUse = StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"CamoActiveOnPlayer"); };
      if family == 21 { inUse = now - this.m_sdpChanLastArm <= 5.00; };
      if family == 22 { inUse = now - this.m_sdpChanLastGun <= 5.00; };
      if family == 23 { inUse = now - this.m_sdpChanLastMove <= 5.00; };
      let xp: Float = rate * Cast<Float>(Min(count, 2)) / 2.00;
      if inUse { xp *= 2.00; };
      this.SDP_ChannelAward(family, 11, xp, true);
    };
    family += 1;
  };
}

// ---- Resource and event channels --------------------------------------------------

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnHealthLost(percent: Float) -> Void {
  if percent <= 0.00 { return; };
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if !IsDefined(player) || !player.IsInCombat() { return; };
  this.SDP_ChannelAward(1, 12, percent / 100.00 * SDP_ChannelHealthBarXP() * this.SDP_ChannelXPMult(), true);
}

@addMethod(PlayerDevelopmentData)
private final func SDP_ChannelMaxHealth() -> Float {
  if !IsDefined(this.m_owner) { return 0.00; };
  return GameInstance.GetStatPoolsSystem(this.m_owner.GetGame()).GetStatPoolMaxPointValue(
    Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Health
  );
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnAdrenalineAbsorbed(points: Float) -> Void {
  if points <= 0.00 { return; };
  let grade: Int32 = this.SDP_ChannelGrade(1);
  if grade < 5 { this.SDP_EncounterAddTrigger(1, 14); return; };
  let maxHealth: Float = this.SDP_ChannelMaxHealth();
  if maxHealth <= 0.00 { return; };
  let xp: Float = points / maxHealth * SDP_ChannelHealthBarXP() * this.SDP_ChannelXPMult();
  if grade >= 9 { xp *= 2.00; };
  this.SDP_ChannelAward(1, 14, xp, true);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnHealingUsed() -> Void {
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if !IsDefined(player) || !player.IsInCombat() { return; };
  let now: Float = this.SDP_ChannelNow();
  if now < this.m_sdpChanItemReady { return; };
  this.m_sdpChanItemReady = now + 15.00;
  this.m_sdpChanLastHeal = now;
  this.SDP_ChannelEvent(1, 13, 5, 1.00);   // Adrenaline (Adrenaline Rush 3)
  this.SDP_ChannelEvent(8, 12, 1, 1.00);   // Pyromania, Supply (Glutton for War)
}

// Dash, dodge, slide, vault, climb: the game's own locomotion XP call.
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnMovement() -> Void {
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if !IsDefined(player) || !player.IsInCombat() { return; };
  this.m_sdpChanLastMove = this.SDP_ChannelNow();
  this.SDP_ChannelAward(4, 11, SDP_ChannelMoveXP() * this.SDP_ChannelXPMult(), true);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnDash(airborne: Bool) -> Void {
  this.m_sdpChanDashUntil = this.SDP_ChannelNow() + 2.00;
  this.m_sdpChanDashHitPaid = false;
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if airborne && IsDefined(player) && player.IsInCombat() {
    if this.SDP_ChannelGrade(4) >= 5 {
      this.SDP_ChannelAward(4, 12, SDP_ChannelMoveXP() * 0.50 * this.SDP_ChannelXPMult(), true);
    } else {
      this.SDP_EncounterAddTrigger(4, 12);
    };
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnDeflect(hitEvent: ref<gameHitEvent>) -> Void {
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if !IsDefined(player) || !IsDefined(hitEvent) { return; };
  let item: ref<WeaponObject> = GameInstance.GetTransactionSystem(player.GetGame())
    .GetItemInSlot(player, t"AttachmentSlots.WeaponRight") as WeaponObject;
  if !IsDefined(item) { return; };
  if item.IsBlade() { this.SDP_ChannelEvent(6, 12, 2, 0.50); return; };
  if item.IsBlunt() {
    let maxHealth: Float = this.SDP_ChannelMaxHealth();
    let blocked: Float = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    if maxHealth > 0.00 && blocked > 0.00 {
      this.SDP_ChannelAward(3, 13, MinF(1.00, blocked / maxHealth) * SDP_ChannelHealthBarXP() * this.SDP_ChannelXPMult(), true);
    };
  };
}

// A quickhack placed in a queue behind one already uploading.
@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnHackQueued(ram: Float, hacks: Int32) -> Void {
  let slot: Float = hacks >= 4 ? 2.00 : (hacks == 3 ? 1.50 : 1.00);
  this.SDP_ChannelAward(11, 11, MaxF(1.00, ram) * SDP_ChannelRamXP() * slot * this.SDP_ChannelXPMult(), true);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ChannelOnQuickhackUpload(cost: Float, category: gamedataHackCategory) -> Void {
  if Equals(category, gamedataHackCategory.NotAHack) { return; };
  this.m_sdpChanLastHack = this.SDP_ChannelNow();
  if Equals(category, gamedataHackCategory.DeviceHack) || Equals(category, gamedataHackCategory.BreachingHack) {
    this.SDP_ChannelEvent(11, 12, 3, 0.50);   // Hack Queue: Eye in the Sky / Access Points
    return;
  };
  let mult: Float = 1.00;
  if this.SDP_ChannelGrade(10) >= 5 && StatusEffectSystem.ObjectHasStatusEffect(this.m_owner,
      t"BaseStatusEffect.Intelligence_Central_Milestone_3_Overclock_Buff") {
    mult *= 2.00;
  };
  this.SDP_ChannelAward(10, 12, MaxF(1.00, cost) * SDP_ChannelUploadXP() * mult * this.SDP_ChannelXPMult(), true);
}

// ---- Hooks -------------------------------------------------------------------

// Native damage XP: called once per Health drain with the % of the target's
// Health removed, so shotgun pellets add up to the shot instead of each paying.
@wrapMethod(RPGManager)
public final static func AwardExperienceFromDamage(hitEvent: ref<gameHitEvent>, damagePercentage: Float) {
  wrappedMethod(hitEvent, damagePercentage);
  if !IsDefined(hitEvent) || !IsDefined(hitEvent.attackData) || damagePercentage <= 0.00 { return; };
  let player: ref<PlayerPuppet> = hitEvent.attackData.GetInstigator() as PlayerPuppet;
  let target: ref<NPCPuppet> = hitEvent.target as NPCPuppet;
  if !IsDefined(player) || !IsDefined(target) || !target.IsActive() || !target.AwardsExperience() { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_ChannelOnDamage(hitEvent, target, damagePercentage); };
}

// Health the player loses to a hit they survive (Adrenaline: Punishment).
@wrapMethod(StatPoolsManager)
public final static func DrainStatPool(hitEvent: ref<gameHitEvent>, statPoolType: gamedataStatPoolType, value: Float) {
  let lost: Float = 0.00;
  let player: ref<PlayerPuppet>;
  if IsDefined(hitEvent) && Equals(statPoolType, gamedataStatPoolType.Health) {
    player = hitEvent.target as PlayerPuppet;
    if IsDefined(player) {
      let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(player.GetGame());
      let id: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
      let current: Float = pools.GetStatPoolValue(id, gamedataStatPoolType.Health, true);
      let points: Float = pools.ToPoints(id, gamedataStatPoolType.Health, current);
      if points > 0.00 {
        lost = MinF(current, value * current / points);
        if current - lost <= 0.00 { lost = 0.00; };  // did not survive
      };
    };
  };
  wrappedMethod(hitEvent, statPoolType, value);
  if lost > 0.00 {
    let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
    if IsDefined(data) { data.SDP_ChannelOnHealthLost(lost); };
  };
}

// Adrenaline is the Overshield pool; the game reports what it absorbs here.
@wrapMethod(RPGManager)
public final static func AwardExperienceFromResourceSpent(player: wref<PlayerPuppet>, value: Float, type: gamedataStatPoolType, opt hitEvent: ref<gameHitEvent>) {
  wrappedMethod(player, value, type, hitEvent);
  if !IsDefined(player) || !Equals(type, gamedataStatPoolType.Overshield) || !IsDefined(hitEvent) { return; };
  if !IsDefined(hitEvent.attackData) || !IsDefined(hitEvent.attackData.GetInstigator())
    || hitEvent.attackData.GetInstigator().IsPlayer() { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_ChannelOnAdrenalineAbsorbed(value); };
}

@wrapMethod(RPGManager)
public final static func AwardExperienceFromLocomotion(player: wref<PlayerPuppet>, amount: Float) {
  wrappedMethod(player, amount);
  if !IsDefined(player) { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_ChannelOnMovement(); };
}

@wrapMethod(RPGManager)
public final static func AwardExperienceFromDeflect(hitEvent: ref<gameHitEvent>) {
  wrappedMethod(hitEvent);
  if !IsDefined(hitEvent) { return; };
  let player: ref<PlayerPuppet> = hitEvent.target as PlayerPuppet;
  if !IsDefined(player) { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_ChannelOnDeflect(hitEvent); };
}

@wrapMethod(RPGManager)
public final static func AwardExperienceFromQuickhack(player: wref<PlayerPuppet>, cost: Float, target: EntityID, category: gamedataHackCategory) {
  wrappedMethod(player, cost, target, category);
  if !IsDefined(player) { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_ChannelOnQuickhackUpload(cost, category); };
}

@wrapMethod(UseHealChargeAction)
public func CompleteAction(gameInstance: GameInstance) {
  wrappedMethod(gameInstance);
  let player: ref<PlayerPuppet> = GetPlayer(gameInstance);
  if !IsDefined(player) { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_ChannelOnHealingUsed(); };
}

@wrapMethod(UseAction)
public func StartAction(gameInstance: GameInstance) {
  wrappedMethod(gameInstance);
  let id: TweakDBID = this.m_objectActionID;
  if Equals(id, t"CyberwareAction.UseBloodPumpCommon") || Equals(id, t"CyberwareAction.UseBloodPumpUncommon")
    || Equals(id, t"CyberwareAction.UseBloodPumpRare") || Equals(id, t"CyberwareAction.UseBloodPumpEpic")
    || Equals(id, t"CyberwareAction.UseBloodPumpLegendary") {
    let player: ref<PlayerPuppet> = this.m_executor as PlayerPuppet;
    if !IsDefined(player) { return; };
    let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
    if IsDefined(data) { data.SDP_ChannelOnHealingUsed(); };
  };
}
