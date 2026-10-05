// SkillDrivenProgression: skills are the source of all five attributes.
// Attributes remain available for perk and attribute checks. Their five
// passive stat bonuses are sourced directly from the matching skills by
// SkillPassives.yaml, so changing an attribute alone cannot change a passive.
module SkillDrivenProgression

public func SDP_ComputeAttributeLevel(skillLevel: Int32, maxSkillLevel: Int32) -> Float {
  let firstAttribute: Float = SDP_StartingAttributeLevel();
  let lastAttribute: Float = SDP_MaxAttributeLevel();
  if maxSkillLevel <= 1 {
    return firstAttribute;
  };

  let boundedSkill: Int32 = skillLevel;
  if boundedSkill < 1 {
    boundedSkill = 1;
  };
  if boundedSkill > maxSkillLevel {
    boundedSkill = maxSkillLevel;
  };

  // At skill 1 the attribute is 3; at skill 60 it is 20. With a max of 60,
  // each intervening skill level adds 17 / 59 attribute points. The skill
  // passives use the same progression, independently of this stored value.
  let progress: Float = Cast<Float>(boundedSkill - 1) / Cast<Float>(maxSkillLevel - 1);
  return firstAttribute + (lastAttribute - firstAttribute) * progress;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_RecalculateAttribute(profType: gamedataProficiencyType, statType: gamedataStatType) -> Void {
  let skillLevel: Int32 = this.GetProficiencyLevel(profType);
  let maxSkillLevel: Int32 = RPGManager.GetProficiencyRecord(profType).MaxLevel();
  let targetLevel: Float = SDP_ComputeAttributeLevel(skillLevel, maxSkillLevel);
  if AbsF(this.GetAttributeValue(statType) - targetLevel) > 0.0001 {
    this.SetAttribute(statType, targetLevel);
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_RecalculateAllAttributes() -> Void {
  if this.m_owner.IsPlayerControlled() {
    this.SDP_RecalculateAttribute(gamedataProficiencyType.ReflexesSkill, gamedataStatType.Reflexes);
    this.SDP_RecalculateAttribute(gamedataProficiencyType.TechnicalAbilitySkill, gamedataStatType.TechnicalAbility);
    this.SDP_RecalculateAttribute(gamedataProficiencyType.CoolSkill, gamedataStatType.Cool);
    this.SDP_RecalculateAttribute(gamedataProficiencyType.IntelligenceSkill, gamedataStatType.Intelligence);
    this.SDP_RecalculateAttribute(gamedataProficiencyType.StrengthSkill, gamedataStatType.Strength);
  };
}

@wrapMethod(PlayerDevelopmentData)
public final func OnRestored(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);
  this.SDP_ClearAttributePoints();
  this.SDP_RecalculateAllAttributes();
  this.SDP_RecalculateSkillDrivenLevel();
  this.SDP_TuningRefreshPassives();
  this.SDP_TuningRefreshCapacity();
}

@wrapMethod(PlayerDevelopmentData)
public final const func ModifyProficiencyLevel(type: gamedataProficiencyType, opt isDebug: Bool, opt levelIncrease: Int32) -> Void {
  wrappedMethod(type, isDebug, levelIncrease);
  if !this.m_owner.IsPlayerControlled() {
    return;
  };

  let statType: gamedataStatType;
  switch type {
    case gamedataProficiencyType.ReflexesSkill:
      statType = gamedataStatType.Reflexes;
      break;
    case gamedataProficiencyType.TechnicalAbilitySkill:
      statType = gamedataStatType.TechnicalAbility;
      break;
    case gamedataProficiencyType.CoolSkill:
      statType = gamedataStatType.Cool;
      break;
    case gamedataProficiencyType.IntelligenceSkill:
      statType = gamedataStatType.Intelligence;
      break;
    case gamedataProficiencyType.StrengthSkill:
      statType = gamedataStatType.Strength;
      break;
    default:
      return;
  };
  this.SDP_RecalculateAttribute(type, statType);
  this.SDP_RecalculateSkillDrivenLevel();
  this.SDP_TuningRefreshPassives();
  this.SDP_TuningRefreshCapacity();
}
