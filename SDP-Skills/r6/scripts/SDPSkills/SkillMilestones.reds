module SkillDrivenProgression

// Skill milestones: levels 15 and 35 give a small permanent bonus tied to the
// skill instead of a perk point (perk points stay disabled). Level 35 doubles
// the level 15 bonus. Everything is derived from the current skill level, so
// existing characters get it automatically, and nothing is saved.
//
//   Skill       Level 15                                  Level 35 total
//   Solo        +5% stamina regeneration during combat    +10%
//   Shinobi     -5% sprint and dash stamina cost          -10%
//   Engineer    -5% cyberware cooldowns                   -10%
//   Netrunner   -5% quickhack upload time                 -10%
//   Headhunter  -5% weapon sway while aiming              -10%

public func SDP_MilestoneTier(level: Int32) -> Int32 {
  if level >= 35 { return 2; };
  if level >= 15 { return 1; };
  return 0;
}

public func SDP_MilestoneSkillTier(player: wref<GameObject>, type: gamedataProficiencyType) -> Int32 {
  if !IsDefined(player) { return 0; };
  let development: ref<PlayerDevelopmentSystem> = PlayerDevelopmentSystem.GetInstance(player);
  if !IsDefined(development) { return 0; };
  let data: ref<PlayerDevelopmentData> = development.GetDevelopmentData(player);
  if !IsDefined(data) { return 0; };
  return SDP_MilestoneTier(data.GetProficiencyLevel(type));
}

public func SDP_MilestoneText(type: gamedataProficiencyType, level: Int32) -> String {
  let pct: String = level >= 35 ? "10%" : "5%";
  let tail: String = level >= 35 ? " (replaces the level 15 bonus)" : "";
  if Equals(type, gamedataProficiencyType.StrengthSkill) { return "+" + pct + " stamina regeneration during combat" + tail; };
  if Equals(type, gamedataProficiencyType.ReflexesSkill) { return "-" + pct + " sprint and dash stamina cost" + tail; };
  if Equals(type, gamedataProficiencyType.TechnicalAbilitySkill) { return "-" + pct + " cyberware cooldowns" + tail; };
  if Equals(type, gamedataProficiencyType.IntelligenceSkill) { return "-" + pct + " quickhack upload time" + tail; };
  if Equals(type, gamedataProficiencyType.CoolSkill) { return "-" + pct + " weapon sway while aiming" + tail; };
  return "";
}

// ---- Progression screen: replace "+1 Perk Point" at 15 and 35 -------------

@wrapMethod(PlayerDevelopmentDataManager)
public final func GetPassiveBonusDisplayData(proficiencyRecord: ref<Proficiency_Record>) -> array<ref<LevelRewardDisplayData>> {
  let rewards: array<ref<LevelRewardDisplayData>> = wrappedMethod(proficiencyRecord);
  if !IsDefined(proficiencyRecord) { return rewards; };
  let type: gamedataProficiencyType = proficiencyRecord.Type();
  for reward in rewards {
    if IsDefined(reward) && (reward.level == 15 || reward.level == 35) {
      let text: String = SDP_MilestoneText(type, reward.level);
      if StrLen(text) > 0 {
        reward.description = text;
        reward.locPackage = new UILocalizationDataPackage();
      };
    };
  };
  return rewards;
}

// ---- Shinobi: sprint and dash stamina cost --------------------------------

public func SDP_ShinobiCostScale() -> Float {
  let tier: Int32 = SDP_MilestoneSkillTier(GetPlayer(GetGameInstance()), gamedataProficiencyType.ReflexesSkill);
  return 1.00 - 0.05 * Cast<Float>(tier);
}

@wrapMethod(PlayerStaminaHelpers)
public final static func GetSprintStaminaCost() -> Float {
  return wrappedMethod() * SDP_ShinobiCostScale();
}

@wrapMethod(PlayerStaminaHelpers)
public final static func GetDodgeStaminaCost() -> Float {
  return wrappedMethod() * SDP_ShinobiCostScale();
}

@wrapMethod(PlayerStaminaHelpers)
public final static func GetAirDodgeStaminaCost() -> Float {
  return wrappedMethod() * SDP_ShinobiCostScale();
}

// ---- Solo, Engineer, Netrunner: player stats; Headhunter: weapon sway -----

@addField(PlayerPuppet) private let m_sdpSoloMod: ref<gameStatModifierData>;
@addField(PlayerPuppet) private let m_sdpSoloKey: Int32;
@addField(PlayerPuppet) private let m_sdpEngineerMod: ref<gameStatModifierData>;
@addField(PlayerPuppet) private let m_sdpEngineerTier: Int32;
@addField(PlayerPuppet) private let m_sdpNetrunnerMod: ref<gameStatModifierData>;
@addField(PlayerPuppet) private let m_sdpNetrunnerTier: Int32;
@addField(PlayerPuppet) private let m_sdpSwayWeapon: EntityID;
@addField(PlayerPuppet) private let m_sdpSwayTier: Int32;
@addField(PlayerPuppet) private let m_sdpSwayMods: array<ref<gameStatModifierData>>;

// Swaps one player stat modifier; returns the new one (or null for none).
@addMethod(PlayerPuppet)
private final func SDP_SwapPlayerModifier(old: ref<gameStatModifierData>, statType: gamedataStatType,
  modType: gameStatModifierType, value: Float, apply: Bool) -> ref<gameStatModifierData> {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  let id: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());
  if IsDefined(old) { stats.RemoveModifier(id, old); };
  if !apply { return null; };
  let modifier: ref<gameStatModifierData> = RPGManager.CreateStatModifier(statType, modType, value);
  if stats.AddModifier(id, modifier) { return modifier; };
  return null;
}

// Called twice a second from the SDP Core loop (SkillsLifecycle.reds registers it).
@addMethod(PlayerPuppet)
public final func SDP_MilestoneTick() -> Void {
  // Solo: key = tier while in combat, 0 otherwise.
  let soloKey: Int32 = this.IsInCombat()
    ? SDP_MilestoneSkillTier(this, gamedataProficiencyType.StrengthSkill) : 0;
  if soloKey != this.m_sdpSoloKey {
    this.m_sdpSoloKey = soloKey;
    this.m_sdpSoloMod = this.SDP_SwapPlayerModifier(this.m_sdpSoloMod,
      gamedataStatType.StaminaRegenRate, gameStatModifierType.Multiplier,
      1.00 + 0.05 * Cast<Float>(soloKey), soloKey > 0);
  };

  let engineer: Int32 = SDP_MilestoneSkillTier(this, gamedataProficiencyType.TechnicalAbilitySkill);
  if engineer != this.m_sdpEngineerTier {
    this.m_sdpEngineerTier = engineer;
    this.m_sdpEngineerMod = this.SDP_SwapPlayerModifier(this.m_sdpEngineerMod,
      gamedataStatType.CyberwareCooldownReduction, gameStatModifierType.Additive,
      0.05 * Cast<Float>(engineer), engineer > 0);
  };

  let netrunner: Int32 = SDP_MilestoneSkillTier(this, gamedataProficiencyType.IntelligenceSkill);
  if netrunner != this.m_sdpNetrunnerTier {
    this.m_sdpNetrunnerTier = netrunner;
    this.m_sdpNetrunnerMod = this.SDP_SwapPlayerModifier(this.m_sdpNetrunnerMod,
      gamedataStatType.QuickHackUploadTimeDecrease, gameStatModifierType.Additive,
      0.05 * Cast<Float>(netrunner), netrunner > 0);
  };

  // Headhunter: sway modifiers follow the equipped weapon.
  let headhunter: Int32 = SDP_MilestoneSkillTier(this, gamedataProficiencyType.CoolSkill);
  let weaponID: EntityID;
  if headhunter > 0 {
    let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(this);
    if IsDefined(weapon) { weaponID = weapon.GetEntityID(); };
  };
  if weaponID != this.m_sdpSwayWeapon || headhunter != this.m_sdpSwayTier {
    this.SDP_ClearSway();
    this.m_sdpSwayTier = headhunter;
    if EntityID.IsDefined(weaponID) {
      this.m_sdpSwayWeapon = weaponID;
      let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
      let target: StatsObjectID = Cast<StatsObjectID>(weaponID);
      let scale: Float = 1.00 - 0.05 * Cast<Float>(headhunter);
      let swayStats: array<gamedataStatType> = [
        gamedataStatType.SwaySideMaximumAngleDistance,
        gamedataStatType.SwaySideMinimumAngleDistance,
        gamedataStatType.SwayCenterMaximumAngleOffset
      ];
      for statType in swayStats {
        let modifier: ref<gameStatModifierData> = RPGManager.CreateStatModifier(
          statType, gameStatModifierType.Multiplier, scale
        );
        if stats.AddModifier(target, modifier) { ArrayPush(this.m_sdpSwayMods, modifier); };
      };
    };
  };
}

@addMethod(PlayerPuppet)
public final func SDP_ClearSway() -> Void {
  if EntityID.IsDefined(this.m_sdpSwayWeapon) {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
    let target: StatsObjectID = Cast<StatsObjectID>(this.m_sdpSwayWeapon);
    for modifier in this.m_sdpSwayMods { stats.RemoveModifier(target, modifier); };
  };
  ArrayClear(this.m_sdpSwayMods);
  let none: EntityID;
  this.m_sdpSwayWeapon = none;
}

@addMethod(PlayerPuppet)
public final func SDP_ClearMilestones() -> Void {
  this.m_sdpSoloMod = this.SDP_SwapPlayerModifier(this.m_sdpSoloMod,
    gamedataStatType.StaminaRegenRate, gameStatModifierType.Multiplier, 1.00, false);
  this.m_sdpEngineerMod = this.SDP_SwapPlayerModifier(this.m_sdpEngineerMod,
    gamedataStatType.CyberwareCooldownReduction, gameStatModifierType.Additive, 0.00, false);
  this.m_sdpNetrunnerMod = this.SDP_SwapPlayerModifier(this.m_sdpNetrunnerMod,
    gamedataStatType.QuickHackUploadTimeDecrease, gameStatModifierType.Additive, 0.00, false);
  this.m_sdpSoloKey = 0;
  this.m_sdpEngineerTier = 0;
  this.m_sdpNetrunnerTier = 0;
  this.m_sdpSwayTier = 0;
  this.SDP_ClearSway();
}
