// Character level is a compatibility value derived from all five skills.
// Skill Rank starts at 1 and reaches 296: one rank for each combined skill
// level gained after the five skills' starting levels. Each five ranks
// advance the game's compatibility level by one. Character XP is ignored.
module SkillDrivenProgression

@addMethod(PlayerDevelopmentData)
public final const func SDP_GetSkillTotal() -> Int32 {
  return Max(1, this.GetProficiencyLevel(gamedataProficiencyType.StrengthSkill))
    + Max(1, this.GetProficiencyLevel(gamedataProficiencyType.ReflexesSkill))
    + Max(1, this.GetProficiencyLevel(gamedataProficiencyType.TechnicalAbilitySkill))
    + Max(1, this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill))
    + Max(1, this.GetProficiencyLevel(gamedataProficiencyType.CoolSkill));
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_GetSkillRank() -> Int32 {
  return this.SDP_GetSkillTotal() - 4;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_GetSkillDrivenLevel() -> Int32 {
  let maxLevel: Int32 = RPGManager.GetProficiencyRecord(gamedataProficiencyType.Level).MaxLevel();
  return Min(maxLevel, 1 + (this.SDP_GetSkillRank() - 1) / 5);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_RecalculateSkillDrivenLevel() -> Void {
  let index: Int32 = this.GetProficiencyIndexByType(gamedataProficiencyType.Level);
  if index < 0 {
    return;
  };

  let target: Int32 = this.SDP_GetSkillDrivenLevel();
  if this.m_proficiencies[index].currentLevel == target {
    return;
  };

  // Update the saved proficiency and Level stat together. The Level stat is
  // what vanilla loot, vendor, enemy, and other level checks read. Cyberware
  // capacity uses the skill levels directly through SkillDrivenCapacity.yaml.
  // Direct assignment also lets an existing save move down to its skill level
  // without replaying old level-up rewards or passive effectors.
  this.m_proficiencies[index].currentLevel = target;
  this.m_proficiencies[index].currentExp = 0;
  this.m_proficiencies[index].maxLevel = RPGManager.GetProficiencyRecord(gamedataProficiencyType.Level).MaxLevel();
  this.m_proficiencies[index].isAtMaxLevel = target >= this.m_proficiencies[index].maxLevel;
  this.m_proficiencies[index].expToLevel = this.GetRemainingExpForLevelUp(gamedataProficiencyType.Level);
  this.SetProficiencyStat(gamedataProficiencyType.Level, target);
  this.UpdateUIBB();
}

@wrapMethod(PlayerDevelopmentData)
public final const func AddExperience(amount: Int32, type: gamedataProficiencyType, telemetryGainReason: telemetryLevelGainReason, opt isDebug: Bool) -> Void {
  if Equals(type, gamedataProficiencyType.Level) && IsDefined(this.m_owner) && this.m_owner.IsPlayerControlled() {
    return;
  };
  wrappedMethod(amount, type, telemetryGainReason, isDebug);
}

@wrapMethod(PlayerDevelopmentData)
public final const func SetLevel(type: gamedataProficiencyType, lvl: Int32, telemetryGainReason: telemetryLevelGainReason, opt isDebug: Bool) -> Void {
  if Equals(type, gamedataProficiencyType.Level) && IsDefined(this.m_owner) && this.m_owner.IsPlayerControlled() {
    this.SDP_RecalculateSkillDrivenLevel();
    return;
  };
  wrappedMethod(type, lvl, telemetryGainReason, isDebug);
}
