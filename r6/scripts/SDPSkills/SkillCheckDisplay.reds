// Show skill checks in skill terms instead of attribute terms.
// Doors/terminals ("Body 9") and dialogue blue-lines now read e.g. "Solo 22":
// the linked skill's name and the skill level at which the (skill-derived)
// attribute reaches the vanilla requirement. PASS/FAIL is untouched - checks
// still evaluate the attribute stat, which is a pure function of the skill,
// so the displayed skill threshold is exactly where the check flips.
// Display-only: the ActionSkillCheck's stored description (which vanilla
// feeds back into TrySetRequiredLevel) is never modified; only copies are.
module SkillDrivenProgression

// Smallest skill level whose derived attribute meets `attributeValue`.
public func SDP_SkillForAttribute(prof: gamedataProficiencyType, attributeValue: Int32) -> Int32 {
  let maxSkill: Int32 = RPGManager.GetProficiencyRecord(prof).MaxLevel();
  let s: Int32 = 1;
  while s <= maxSkill {
    if SDP_ComputeAttributeLevel(s, maxSkill) >= Cast<Float>(attributeValue) - 0.0001 {
      return s;
    };
    s += 1;
  };
  return maxSkill;
}

public func SDP_PlayerSkillLevel(prof: gamedataProficiencyType) -> Int32 {
  let player: ref<GameObject> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject();
  if !IsDefined(player) {
    return 0;
  };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if !IsDefined(data) {
    return 0;
  };
  return data.GetProficiencyLevel(prof);
}

// Skill-check bonus stats (e.g. Gorilla Arms -> StrengthSkillcheckBonus) are in
// attribute points; express them in skill levels on the same scale
// (one attribute point = 59/17 ~ 3.47 skill levels).
public func SDP_SkillcheckBonusInSkillLevels(prof: gamedataProficiencyType) -> Int32 {
  let bonusStat: gamedataStatType;
  switch prof {
    case gamedataProficiencyType.StrengthSkill:
      bonusStat = gamedataStatType.StrengthSkillcheckBonus;
      break;
    case gamedataProficiencyType.IntelligenceSkill:
      bonusStat = gamedataStatType.IntelligenceSkillcheckBonus;
      break;
    case gamedataProficiencyType.TechnicalAbilitySkill:
      bonusStat = gamedataStatType.TechnicalAbilitySkillcheckBonus;
      break;
    default:
      return 0;
  };
  let player: ref<GameObject> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject();
  if !IsDefined(player) {
    return 0;
  };
  let bonus: Float = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), bonusStat);
  if bonus <= 0.0 {
    return 0;
  };
  let maxSkill: Int32 = RPGManager.GetProficiencyRecord(prof).MaxLevel();
  let perPoint: Float = Cast<Float>(maxSkill - 1) / (SDP_MaxAttributeLevel() - SDP_StartingAttributeLevel());
  return RoundF(bonus * perPoint);
}

// Skill level shown as "yours" on a check: skill + converted check bonus.
public func SDP_EffectiveCheckSkill(prof: gamedataProficiencyType) -> Int32 {
  return SDP_PlayerSkillLevel(prof) + SDP_SkillcheckBonusInSkillLevels(prof);
}

public func SDP_SkillNameKey(prof: gamedataProficiencyType) -> String {
  return RPGManager.GetProficiencyRecord(prof).Loc_name_key();
}

public func SDP_ProfForDeviceSkill(skill: EDeviceChallengeSkill) -> gamedataProficiencyType {
  if Equals(skill, EDeviceChallengeSkill.Hacking) {
    return gamedataProficiencyType.IntelligenceSkill;
  };
  if Equals(skill, EDeviceChallengeSkill.Engineering) {
    return gamedataProficiencyType.TechnicalAbilitySkill;
  };
  return gamedataProficiencyType.StrengthSkill;
}

public func SDP_ProfForBuild(build: gamedataPlayerBuild) -> gamedataProficiencyType {
  switch build {
    case gamedataPlayerBuild.Netrunner:
      return gamedataProficiencyType.IntelligenceSkill;
    case gamedataPlayerBuild.Techie:
      return gamedataProficiencyType.TechnicalAbilitySkill;
    case gamedataPlayerBuild.Reflexes:
      return gamedataProficiencyType.ReflexesSkill;
    case gamedataPlayerBuild.Cool:
      return gamedataProficiencyType.CoolSkill;
    default:
      return gamedataProficiencyType.StrengthSkill;
  };
}

// Keep the shown numbers consistent with the real pass/fail result (the
// vanilla check truncates attribute and bonus separately, so the converted
// estimate can be off by one level at the edge).
public func SDP_ConsistentPlayerSkill(playerSkill: Int32, requiredSkill: Int32, passed: Bool) -> Int32 {
  if passed && playerSkill < requiredSkill {
    return requiredSkill;
  };
  if !passed && playerSkill >= requiredSkill {
    return requiredSkill - 1;
  };
  return playerSkill;
}

public func SDP_ToSkillTerms(info: UIInteractionSkillCheck) -> UIInteractionSkillCheck {
  if !info.isValid {
    return info;
  };
  let prof: gamedataProficiencyType = SDP_ProfForDeviceSkill(info.skillCheck);
  info.requiredSkill = SDP_SkillForAttribute(prof, info.requiredSkill);
  info.playerSkill = SDP_ConsistentPlayerSkill(SDP_EffectiveCheckSkill(prof), info.requiredSkill, info.isPassed);
  info.skillName = SDP_SkillNameKey(prof);
  return info;
}

// ---- Doors / terminals / containers -------------------------------------

@wrapMethod(ActionSkillCheck)
public final const func GetSkillcheckInfo() -> UIInteractionSkillCheck {
  return SDP_ToSkillTerms(wrappedMethod());
}

// Scanner panel feed (display only).
@wrapMethod(ScriptableDeviceComponentPS)
public final func CreateSkillcheckInfo(const context: script_ref<GetActionsContext>) -> array<UIInteractionSkillCheck> {
  let infos: array<UIInteractionSkillCheck> = wrappedMethod(context);
  let i: Int32 = 0;
  while i < ArraySize(infos) {
    infos[i] = SDP_ToSkillTerms(infos[i]);
    i += 1;
  };
  return infos;
}

// Interaction prompt: vanilla hard-codes the attribute name per check type;
// re-set the same text with the linked skill's name.
@wrapMethod(interactionItemLogicController)
public final func SetData(data: script_ref<InteractionChoiceData>, opt skillCheck: UIInteractionSkillCheck, opt isItemBroken: Bool) -> Void {
  wrappedMethod(data, skillCheck, isItemBroken);
  if skillCheck.isValid {
    let params: ref<inkTextParams> = new inkTextParams();
    params.AddLocalizedString("NAME", SDP_SkillNameKey(SDP_ProfForDeviceSkill(skillCheck.skillCheck)));
    params.AddNumber("REQUIRED_SKILL", skillCheck.requiredSkill);
    if skillCheck.isPassed {
      inkTextRef.SetLocalizedTextScript(this.m_skillCheckText, "LocKey#49423", params);
    } else {
      params.AddNumber("PLAYER_SKILL", skillCheck.playerSkill);
      inkTextRef.SetLocalizedTextScript(this.m_skillCheckText, "LocKey#49421", params);
    };
  };
}

// ---- Dialogue blue-lines ---------------------------------------------------

@wrapMethod(CaptionImageIconsLogicController)
public final func SetSkillCheck(argData: ref<BuildBluelinePart>) -> Void {
  wrappedMethod(argData);
  if !IsDefined(argData) || !IsDefined(argData.m_record) {
    return;
  };
  let prof: gamedataProficiencyType = SDP_ProfForBuild(argData.m_record.Type());
  let required: Int32 = SDP_SkillForAttribute(prof, argData.m_rhsValue);
  let player: Int32 = SDP_ConsistentPlayerSkill(SDP_EffectiveCheckSkill(prof), required, argData.passed);
  let name: String = GetLocalizedText(SDP_SkillNameKey(prof));
  if argData.passed {
    inkTextRef.SetText(this.m_CheckText, name + " " + IntToString(required));
  } else {
    inkTextRef.SetText(this.m_CheckText, name + " " + IntToString(player) + " / " + IntToString(required));
  };
}
