// Convert an older save's bought vanilla perks into recorded shard grades.
// Shards record in order, so a family is credited up to the highest grade
// whose vanilla perks are all bought with every lower grade also bought
// ("strict"). "Generous" credits the highest grade with any of its perks
// bought. Grades never go down. Run from the CET console (CET_PERK_SYNC.md):
//   mode 0 = preview only, 1 = record (strict), 2 = record (generous).
// SDP_RefundVanillaPerks() then sells the vanilla perks (Relic perks kept),
// so only the processor grants them from then on.
module SkillDrivenProgression

// Vanilla purchase level, without the shard ranks IsNewPerkBought adds.
@addMethod(PlayerDevelopmentData)
public final const func SDP_VanillaPerkLevel(perkType: gamedataNewPerkType) -> Int32 {
  let i: Int32;
  let j: Int32;
  if this.FindNewPerk(perkType, i, j) { return this.m_attributesData[i].unlockedPerks[j].currLevel; };
  return 0;
}

public func SDP_SyncFamilyMax(family: Int32) -> Int32 {
  return family == 0 ? 11 : SDP_FamilyMaxGrade(family);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_SyncTarget(family: Int32, generous: Bool) -> Int32 {
  let target: Int32 = 0;
  let grade: Int32 = 1;
  let gap: Bool = false;
  while grade <= SDP_SyncFamilyMax(family) {
    let status: Int32 = this.SDP_SyncGradeStatus(family, grade);
    if generous {
      if status == 1 || status == 2 { target = grade; };
    } else {
      if status == 0 || status == 1 { gap = true; };
      if status == 2 && !gap { target = grade; };
    };
    grade += 1;
  };
  return target;
}

@addMethod(PlayerDevelopmentData)
private final const func SDP_SyncStatusText(family: Int32) -> String {
  let text: String = "";
  let grade: Int32 = 1;
  while grade <= SDP_SyncFamilyMax(family) {
    let status: Int32 = this.SDP_SyncGradeStatus(family, grade);
    text += status == 2 ? "#" : (status == 1 ? "+" : (status == 3 ? "." : "-"));
    grade += 1;
  };
  return text;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_SyncVanillaPerks(mode: Int32) -> String {
  let generous: Bool = mode == 2;
  let report: String = mode == 0 ? "Preview (nothing changed)" : (generous ? "Recorded (generous)" : "Recorded (strict)");
  report += "\n  grades: # all perks bought, + some, - none, . no vanilla perks";
  this.SDP_FamilyEnsureData();
  let family: Int32 = 0;
  while family <= SDP_FamilyCount() {
    let strict: Int32 = this.SDP_SyncTarget(family, false);
    let loose: Int32 = this.SDP_SyncTarget(family, true);
    let current: Int32 = this.SDP_RecordedGrade(family);
    if strict > 0 || loose > 0 || current > 0 {
      let target: Int32 = generous ? loose : strict;
      let line: String = "\n  " + SDP_RecordedFamilyName(family) + " [" + this.SDP_SyncStatusText(family) + "] recorded "
        + IntToString(current) + ", strict " + IntToString(strict) + ", generous " + IntToString(loose);
      if mode > 0 && target > current {
        if family == 0 {
          this.m_sdpOrderDeadeyeMasteredGrade = target;
        } else {
          this.m_sdpFamilyMastery[family - 1] = target;
        };
        line += "  -> now " + IntToString(target);
      };
      report += line;
    };
    family += 1;
  };
  if mode > 0 {
    this.SDP_FamilyReconcilePackages();
    this.SDP_PrototypeReconcileDeadeye();
  };
  return report;
}

// Sells every bought vanilla perk except Relic (Espionage) perks. Perk points
// are not returned (perk points are disabled in this mod).
@addMethod(PlayerDevelopmentData)
public final func SDP_RefundVanillaPerks() -> String {
  let sold: Int32 = 0;
  let perkIndex: Int32 = 0;
  while perkIndex < EnumInt(gamedataNewPerkType.Count) {
    let perkType: gamedataNewPerkType = IntEnum<gamedataNewPerkType>(perkIndex);
    let name: String = EnumValueToString("gamedataNewPerkType", Cast<Int64>(perkIndex));
    if !StrBeginsWith(name, "Espionage") {
      let level: Int32;
      while this.ForceSellNewPerk(perkType, level) {
        sold += 1;
        let evt: ref<NewPerkSoldEvent> = new NewPerkSoldEvent();
        evt.perkType = perkType;
        evt.perkLevelSold = level;
        GameInstance.GetUISystem(this.m_owner.GetGame()).QueueEvent(evt);
        this.m_owner.QueueEvent(evt);
      };
    };
    perkIndex += 1;
  };
  this.SDP_FamilyReconcilePackages();
  this.SDP_PrototypeReconcileDeadeye();
  return "Sold " + IntToString(sold) + " vanilla perk levels (Relic perks kept).";
}
