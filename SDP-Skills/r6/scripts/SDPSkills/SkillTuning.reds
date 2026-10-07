// Runtime tuning for the skill side, fed by the SDPSkills CET mod (Native Settings):
// the five skills' base passives and Cyberware Capacity per skill level.
module SkillDrivenProgression

@addField(PlayerDevelopmentData)
public let m_sdpTuningPassiveScales: array<Float>;

@addField(PlayerDevelopmentData)
public let m_sdpTuningPassiveMods: array<ref<gameStatModifierData>>;

@addField(PlayerDevelopmentData)
public let m_sdpTuningCapacityPerSkill: Float;

@addField(PlayerDevelopmentData)
public let m_sdpTuningCapacityInitialized: Bool;

@addField(PlayerDevelopmentData)
public let m_sdpTuningCapacityMod: ref<gameStatModifierData>;

@addMethod(PlayerDevelopmentData)
public final func SDP_SkillTuningEnsureData() -> Void {
  while ArraySize(this.m_sdpTuningPassiveScales) < 5 { ArrayPush(this.m_sdpTuningPassiveScales, 1.00); };
  if ArraySize(this.m_sdpTuningPassiveMods) < 5 { ArrayResize(this.m_sdpTuningPassiveMods, 5); };
  if !this.m_sdpTuningCapacityInitialized {
    this.m_sdpTuningCapacityPerSkill = 1.00;
    this.m_sdpTuningCapacityInitialized = true;
  };
}

public func SDP_TuningPassiveRecord(index: Int32) -> TweakDBID {
  if index == 0 { return t"Attribute.BodyPassive"; };
  if index == 1 { return t"Attribute.ReflexesPassive"; };
  if index == 2 { return t"Attribute.TechAbilityPassive"; };
  if index == 3 { return t"Attribute.IntelligencePassive"; };
  if index == 4 { return t"Attribute.CoolPassive"; };
  return t"None";
}

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningSetPassiveScale(index: Int32, scale: Float) -> Void {
  if index < 0 || index >= 5 { return; };
  this.SDP_SkillTuningEnsureData();
  scale = ClampF(scale, 0.00, 5.00);
  if AbsF(this.m_sdpTuningPassiveScales[index] - scale) < 0.0001 { return; };
  this.m_sdpTuningPassiveScales[index] = scale;
  this.SDP_TuningRefreshPassives();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningSetCapacityPerSkill(value: Float) -> Void {
  this.SDP_SkillTuningEnsureData();
  value = ClampF(value, 0.00, 3.00);
  if AbsF(this.m_sdpTuningCapacityPerSkill - value) < 0.0001 { return; };
  this.m_sdpTuningCapacityPerSkill = value;
  this.SDP_TuningRefreshCapacity();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningRefreshPassives() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  this.SDP_SkillTuningEnsureData();
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_owner.GetGame());
  let statsID: StatsObjectID = Cast<StatsObjectID>(this.m_owner.GetEntityID());
  let index: Int32 = 0;
  while index < 5 {
    if IsDefined(this.m_sdpTuningPassiveMods[index]) {
      stats.RemoveModifier(statsID, this.m_sdpTuningPassiveMods[index]);
      this.m_sdpTuningPassiveMods[index] = null;
    };
    let record: ref<StatModifier_Record> = TweakDBInterface.GetStatModifierRecord(SDP_TuningPassiveRecord(index));
    if IsDefined(record) && Equals(record.ModifierType(), n"Additive") {
      let amount: Float = RPGManager.CalculateStatModifier(
        record, this.m_owner.GetGame(), this.m_owner, statsID
      ) * (this.m_sdpTuningPassiveScales[index] - 1.00);
      if AbsF(amount) > 0.0001 {
        let modifier: ref<gameStatModifierData> = RPGManager.CreateStatModifier(
          record.StatType().StatType(), gameStatModifierType.Additive, amount
        );
        if stats.AddModifier(statsID, modifier) {
          this.m_sdpTuningPassiveMods[index] = modifier;
        };
      };
    };
    index += 1;
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningRefreshCapacity() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  this.SDP_SkillTuningEnsureData();
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_owner.GetGame());
  let statsID: StatsObjectID = Cast<StatsObjectID>(this.m_owner.GetEntityID());
  if IsDefined(this.m_sdpTuningCapacityMod) {
    stats.RemoveModifier(statsID, this.m_sdpTuningCapacityMod);
    this.m_sdpTuningCapacityMod = null;
  };
  let totalLevels: Int32 = this.GetProficiencyLevel(gamedataProficiencyType.StrengthSkill)
    + this.GetProficiencyLevel(gamedataProficiencyType.ReflexesSkill)
    + this.GetProficiencyLevel(gamedataProficiencyType.TechnicalAbilitySkill)
    + this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill)
    + this.GetProficiencyLevel(gamedataProficiencyType.CoolSkill);
  let adjustment: Float = (this.m_sdpTuningCapacityPerSkill - 1.00) * Cast<Float>(totalLevels);
  if AbsF(adjustment) > 0.0001 {
    let modifier: ref<gameStatModifierData> = RPGManager.CreateStatModifier(
      gamedataStatType.Humanity, gameStatModifierType.Additive, adjustment
    );
    if stats.AddModifier(statsID, modifier) {
      this.m_sdpTuningCapacityMod = modifier;
    };
  };
}
