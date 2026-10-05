// Scanner focus time scale follows Netrunner skill directly.
// 1.0 is normal speed; smaller values produce stronger slowdown.
module SkillDrivenProgression

@addField(PlayerDevelopmentData)
public let m_sdpScannerLevelOneScale: Float;

@addField(PlayerDevelopmentData)
public let m_sdpScannerMaxLevelScale: Float;

@addField(PlayerDevelopmentData)
public let m_sdpScannerSettingsInitialized: Bool;

public func SDP_ScannerDilationForSkill(skillLevel: Int32) -> Float {
  let maxLevel: Int32 = RPGManager.GetProficiencyRecord(gamedataProficiencyType.IntelligenceSkill).MaxLevel();
  if maxLevel <= 1 { return 0.99; };
  let progress: Float = ClampF(
    Cast<Float>(skillLevel - 1) / Cast<Float>(maxLevel - 1), 0.00, 1.00
  );
  let curved: Float = progress * progress * (3.00 - 2.00 * progress);
  return 0.99 - 0.96 * curved;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_SetScannerDilationEndpoints(first: Float, last: Float) -> Void {
  this.m_sdpScannerLevelOneScale = ClampF(first, 0.01, 1.00);
  this.m_sdpScannerMaxLevelScale = ClampF(last, 0.01, 1.00);
  this.m_sdpScannerSettingsInitialized = true;
  this.SDP_UpdateScannerDilation();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_UpdateScannerDilation() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  if !this.m_sdpScannerSettingsInitialized {
    this.m_sdpScannerLevelOneScale = 0.99;
    this.m_sdpScannerMaxLevelScale = 0.03;
    this.m_sdpScannerSettingsInitialized = true;
  };
  let level: Int32 = this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill);
  let maxLevel: Int32 = RPGManager.GetProficiencyRecord(gamedataProficiencyType.IntelligenceSkill).MaxLevel();
  let progress: Float = maxLevel <= 1 ? 0.00
    : ClampF(Cast<Float>(level - 1) / Cast<Float>(maxLevel - 1), 0.00, 1.00);
  let curved: Float = progress * progress * (3.00 - 2.00 * progress);
  let scale: Float = this.m_sdpScannerLevelOneScale
    + (this.m_sdpScannerMaxLevelScale - this.m_sdpScannerLevelOneScale) * curved;
  TweakDBManager.SetFlat(t"timeSystem.focusModeTimeDilation.timeDilation", scale);
  TweakDBManager.SetFlat(t"timeSystem.focusModeTimeDilation.playerTimeDilation", scale);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_CurrentScannerDilation() -> Float {
  let level: Int32 = this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill);
  if !this.m_sdpScannerSettingsInitialized { return SDP_ScannerDilationForSkill(level); };
  let maxLevel: Int32 = RPGManager.GetProficiencyRecord(gamedataProficiencyType.IntelligenceSkill).MaxLevel();
  if maxLevel <= 1 { return this.m_sdpScannerLevelOneScale; };
  let progress: Float = ClampF(Cast<Float>(level - 1) / Cast<Float>(maxLevel - 1), 0.00, 1.00);
  let curved: Float = progress * progress * (3.00 - 2.00 * progress);
  return this.m_sdpScannerLevelOneScale
    + (this.m_sdpScannerMaxLevelScale - this.m_sdpScannerLevelOneScale) * curved;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_ScannerDilationStatus() -> String {
  let level: Int32 = this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill);
  return "Netrunner=" + IntToString(level)
    + " scannerScale=" + FloatToString(this.SDP_CurrentScannerDilation());
}

// Self-contained since the SDP split: refresh on load, on a new game and when Netrunner levels up.
@wrapMethod(PlayerDevelopmentData)
public final func OnRestored(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);
  this.SDP_UpdateScannerDilation();
}

@wrapMethod(PlayerDevelopmentData)
public final func RefreshDevelopmentSystemOnNewGameStarted() -> Void {
  wrappedMethod();
  this.SDP_UpdateScannerDilation();
}

@wrapMethod(PlayerDevelopmentData)
public final const func ModifyProficiencyLevel(type: gamedataProficiencyType, opt isDebug: Bool, opt levelIncrease: Int32) -> Void {
  wrappedMethod(type, isDebug, levelIncrease);
  if Equals(type, gamedataProficiencyType.IntelligenceSkill) && IsDefined(this.m_owner) && this.m_owner.IsPlayerControlled() {
    this.SDP_UpdateScannerDilation();
  };
}
