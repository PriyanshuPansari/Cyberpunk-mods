// Runtime tuning for shard training, fed by the SkillDrivenProgression CET mod (Native Settings).
// The carry preserves fractional awards when the player selects a scale below 100 percent.
module SkillDrivenProgression

@addField(PlayerDevelopmentData)
public let m_sdpTuningXPScales: array<Float>;

@addField(PlayerDevelopmentData)
public persistent let m_sdpTuningXPCarry: array<Float>;

@addField(PlayerDevelopmentData)
public let m_sdpTuningAwardLines: array<String>;

@addField(PlayerDevelopmentData)
public let m_sdpTuningAwardSequence: Int32;

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningEnsureData() -> Void {
  while ArraySize(this.m_sdpTuningXPScales) < SDP_FamilyCount() + 1 { ArrayPush(this.m_sdpTuningXPScales, 1.00); };
  while ArraySize(this.m_sdpTuningXPCarry) < SDP_FamilyCount() + 1 { ArrayPush(this.m_sdpTuningXPCarry, 0.00); };
}

// Slot 0 is Deadeye; slots 1 through 15 are the other shard families.
@addMethod(PlayerDevelopmentData)
public final func SDP_TuningSetXPScale(slot: Int32, scale: Float) -> Void {
  if slot < 0 || slot > SDP_FamilyCount() { return; };
  this.SDP_TuningEnsureData();
  this.m_sdpTuningXPScales[slot] = ClampF(scale, 0.00, 5.00);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningScaledXP(slot: Int32, baseXP: Int32) -> Int32 {
  if slot < 0 || slot > SDP_FamilyCount() || baseXP <= 0 { return 0; };
  this.SDP_TuningEnsureData();
  let total: Float = Cast<Float>(baseXP) * this.m_sdpTuningXPScales[slot]
    + this.m_sdpTuningXPCarry[slot];
  let whole: Int32 = FloorF(total + 0.00001);
  this.m_sdpTuningXPCarry[slot] = total - Cast<Float>(whole);
  return whole;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_TuningLogAward(
  slot: Int32, grade: Int32, source: Int32, baseXP: Int32,
  awarded: Int32, progress: Int32, maximum: Int32
) -> Void {
  let family: String = slot == 0 ? "Deadeye" : SDP_FamilyName(slot);
  let action: String = slot == 0
    ? SDP_OrderDeadeyeUseSourceName(source)
    : SDP_TrainingFamilySourceName(slot, source);
  let line: String = family + " " + SDP_FamilyGradeLabel(grade)
    + "  " + action + "  +" + IntToString(awarded)
    + " XP (base " + IntToString(baseXP) + ")  "
    + IntToString(progress) + "/" + IntToString(maximum);
  ArrayPush(this.m_sdpTuningAwardLines, line);
  if ArraySize(this.m_sdpTuningAwardLines) > 24 { ArrayErase(this.m_sdpTuningAwardLines, 0); };
  this.m_sdpTuningAwardSequence += 1;
  this.SDP_EncounterAddShard(slot, awarded);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_TuningAwardSequence() -> Int32 {
  return this.m_sdpTuningAwardSequence;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_TuningAwardCount() -> Int32 {
  return ArraySize(this.m_sdpTuningAwardLines);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_TuningAwardLine(index: Int32) -> String {
  if index < 0 || index >= ArraySize(this.m_sdpTuningAwardLines) { return ""; };
  return this.m_sdpTuningAwardLines[index];
}
