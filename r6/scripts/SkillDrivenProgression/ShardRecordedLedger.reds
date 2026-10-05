// The processor tooltip is the in-game index of permanent shard data.
// The full ledger is also available in CET with d:SDP_RecordedLedger().
module SkillDrivenProgression

@addMethod(PlayerDevelopmentData)
public final const func SDP_RecordedGrade(family: Int32) -> Int32 {
  if family == 0 { return this.m_sdpOrderDeadeyeMasteredGrade; };
  return this.SDP_FamilyMasteredGrade(family);
}

public func SDP_RecordedFamilyName(family: Int32) -> String {
  if family == 0 { return "Deadeye"; };
  return SDP_FamilyName(family);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_RecordedLedger() -> String {
  let result: String = "RECORDED SHARD DATA";
  let family: Int32 = 0;
  while family <= SDP_FamilyCount() {
    let mastered: Int32 = this.SDP_RecordedGrade(family);
    if mastered > 0 {
      result += "\n" + SDP_RecordedFamilyName(family) + " " + SDP_FamilyGradeLabel(mastered);
      let grade: Int32 = 1;
      while grade <= mastered {
        result += "\n  " + SDP_FamilyGradeLabel(grade) + ": "
          + SDP_RecordedEffectDescription(family, grade);
        grade += 1;
      };
    };
    family += 1;
  };
  return result;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_RecordedProcessorSummary() -> String {
  let result: String = "\n\nRECORDED DATA";
  let found: Bool = false;
  let family: Int32 = 0;
  while family <= SDP_FamilyCount() {
    let mastered: Int32 = this.SDP_RecordedGrade(family);
    if mastered > 0 {
      found = true;
      result += "\n" + SDP_RecordedFamilyName(family) + " " + SDP_FamilyGradeLabel(mastered) + ": ";
      let grade: Int32 = 1;
      while grade <= mastered {
        if grade > 1 { result += ", "; };
        result += SDP_RecordedEffectTitle(family, grade);
        grade += 1;
      };
    };
    family += 1;
  };
  if !found { result += "\nNo grades recorded yet."; };
  return result;
}

public func SDP_ProcessorLedgerDescription(description: String, opt owner: ref<GameObject>) -> String {
  let previous: Int32 = StrFindFirst(description, "\n\nRECORDED DATA");
  if previous >= 0 { description = StrLeft(description, previous); };
  let data: ref<PlayerDevelopmentData> = SDP_GetDeadeyeProgressData(owner);
  if !IsDefined(data) { return description; };
  return description + data.SDP_RecordedProcessorSummary();
}
