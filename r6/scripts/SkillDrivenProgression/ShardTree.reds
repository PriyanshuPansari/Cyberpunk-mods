// Data for the CET shard tree window (init.lua): per family and grade, what it
// grants and whether it is recorded, slotted (training) or still ahead.
module SkillDrivenProgression

// 0..4 = Solo, Shinobi, Engineer, Netrunner, Headhunter; 5 = general (Vehicle,
// Expansion chips). Deadeye (family 0) is a Headhunter shard.
@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeFamilyGroup(family: Int32) -> Int32 {
  if family == 0 { return 4; };
  let index: Int32 = SDP_EncounterSkillIndex(SDP_FamilySkill(family));
  return index >= 0 ? index : 5;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeFamilyName(family: Int32) -> String { return SDP_RecordedFamilyName(family); }

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeMaxGrade(family: Int32) -> Int32 { return family == 0 ? 11 : SDP_FamilyMaxGrade(family); }

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeGradeLabel(grade: Int32) -> String { return SDP_FamilyGradeLabel(grade); }

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeGradeTitle(family: Int32, grade: Int32) -> String { return SDP_RecordedEffectTitle(family, grade); }

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeGradeDescription(family: Int32, grade: Int32) -> String { return SDP_RecordedEffectDescription(family, grade); }

// Grade currently in the processor for this family (0 if none).
@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeSlottedGrade(family: Int32) -> Int32 {
  return family == 0 ? this.SDP_OrderDeadeyeSlottedGrade() : this.SDP_FamilySlottedGrade(family);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeGradeXP(family: Int32, grade: Int32) -> Int32 {
  return family == 0 ? this.SDP_OrderDeadeyeXP(grade) : this.SDP_FamilyXP(family, grade);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeGradeThreshold(family: Int32, grade: Int32) -> Int32 {
  return family == 0 ? SDP_OrderDeadeyeThreshold(grade) : SDP_FamilyThreshold(family, grade);
}

// Skill level by group index 0..4.
@addMethod(PlayerDevelopmentData)
public final const func SDP_TreeSkillLevel(index: Int32) -> Int32 {
  if index == 0 { return this.GetProficiencyLevel(gamedataProficiencyType.StrengthSkill); };
  if index == 1 { return this.GetProficiencyLevel(gamedataProficiencyType.ReflexesSkill); };
  if index == 2 { return this.GetProficiencyLevel(gamedataProficiencyType.TechnicalAbilitySkill); };
  if index == 3 { return this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill); };
  if index == 4 { return this.GetProficiencyLevel(gamedataProficiencyType.CoolSkill); };
  return this.GetProficiencyLevel(gamedataProficiencyType.Level);
}
