// Shared character-owned progression for the other fourteen skill families
// and the single-grade vehicle chip. Item/package IDs live in the catalog.
module SkillDrivenProgression

// Families 1-14 have 11 grades; 15 (Vehicle) and 16-23 (Cyberware-EX
// Expansion shards) have one grade. Slot 0 elsewhere is Deadeye.
public func SDP_FamilyCount() -> Int32 { return 23; }
public func SDP_FamilyMaxGrade(family: Int32) -> Int32 { return family >= 15 ? 1 : 11; }
public func SDP_FamilyIsExpansion(family: Int32) -> Bool { return family >= 16 && family <= 23; }

public func SDP_FamilyThreshold(family: Int32, grade: Int32) -> Int32 {
  if SDP_ChannelFamily(family) { return SDP_ChannelThreshold(family, grade); };  // training v2 (ShardChannels.reds)
  return SDP_TrainingFamilyThreshold(family, grade);
}

public func SDP_FamilyGradeLabel(grade: Int32) -> String {
  if grade == 1 { return "Tier 1"; };
  if grade == 2 { return "Tier 1+"; };
  if grade == 3 { return "Tier 2"; };
  if grade == 4 { return "Tier 2+"; };
  if grade == 5 { return "Tier 3"; };
  if grade == 6 { return "Tier 3+"; };
  if grade == 7 { return "Tier 4"; };
  if grade == 8 { return "Tier 4+"; };
  if grade == 9 { return "Tier 5"; };
  if grade == 10 { return "Tier 5+"; };
  if grade == 11 { return "Tier 5++"; };
  return "Unknown tier";
}

public func SDP_FamilyCustomPackage(family: Int32, grade: Int32) -> TweakDBID {
  if family == 7 && grade == 3 { return t"SkillDrivenProgression.SDPChromeLuckyDay"; };
  if family == 7 && grade == 7 { return t"SkillDrivenProgression.SDPChromeCalibration"; };
  if family == 12 && grade == 4 { return t"SkillDrivenProgression.SDPSmartLockAccuracy"; };
  if family == 12 && grade == 10 { return t"SkillDrivenProgression.SDPSmartLockSpeed"; };
  return t"None";
}

@addField(PlayerDevelopmentData)
public persistent let m_sdpFamilyMastery: array<Int32>;

@addField(PlayerDevelopmentData)
public persistent let m_sdpFamilyXP: array<Int32>;

@addField(PlayerDevelopmentData)
public persistent let m_sdpFamilyUseXP: array<Int32>;

// Save compatibility with the earlier fractional-award scheme.
@addField(PlayerDevelopmentData)
public persistent let m_sdpFamilyPriorXPHalfCarry: array<Int32>;

// Retained for compatibility with saves made before use-only attunement.
@addField(PlayerDevelopmentData)
public persistent let m_sdpFamilySkillShareCursor: array<Int32>;

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyEnsureData() -> Void {
  while ArraySize(this.m_sdpFamilyMastery) < SDP_FamilyCount() { ArrayPush(this.m_sdpFamilyMastery, 0); };
  while ArraySize(this.m_sdpFamilyXP) < SDP_FamilyCount() * 11 { ArrayPush(this.m_sdpFamilyXP, 0); };
  while ArraySize(this.m_sdpFamilyUseXP) < SDP_FamilyCount() * 11 { ArrayPush(this.m_sdpFamilyUseXP, 0); };
  while ArraySize(this.m_sdpFamilySkillShareCursor) < 5 { ArrayPush(this.m_sdpFamilySkillShareCursor, 0); };
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyMasteredGrade(family: Int32) -> Int32 {
  if family < 1 || family > ArraySize(this.m_sdpFamilyMastery) { return 0; };
  return this.m_sdpFamilyMastery[family - 1];
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyXP(family: Int32, grade: Int32) -> Int32 {
  if family < 1 || family > SDP_FamilyCount() || grade < 1 || grade > 11 { return 0; };
  let index: Int32 = (family - 1) * 11 + grade - 1;
  if index >= ArraySize(this.m_sdpFamilyXP) { return 0; };
  return this.m_sdpFamilyXP[index];
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyUseXP(family: Int32, grade: Int32) -> Int32 {
  if family < 1 || family > SDP_FamilyCount() || grade < 1 || grade > 11 { return 0; };
  let index: Int32 = (family - 1) * 11 + grade - 1;
  if index >= ArraySize(this.m_sdpFamilyUseXP) { return 0; };
  return this.m_sdpFamilyUseXP[index];
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilySlottedGrade(family: Int32) -> Int32 {
  if family < 1 || family > SDP_FamilyCount() || !IsDefined(this.m_owner) { return 0; };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return 0; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let itemData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) { return 0; };
  let slot: Int32 = 0;
  while slot < 3 {
    let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
    if itemData.HasPartInSlot(slotID) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slotID);
      let itemID: TweakDBID = ItemID.GetTDBID(InnerItemData.GetItemID(part));
      if SDP_FamilyItemFamily(itemID) == family { return SDP_FamilyItemGrade(itemID); };
    };
    slot += 1;
  };
  return 0;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyActiveGrade(family: Int32) -> Int32 {
  let mastered: Int32 = this.SDP_FamilyMasteredGrade(family);
  let slotted: Int32 = this.SDP_FamilySlottedGrade(family);
  if slotted == mastered + 1 { return slotted; };
  return mastered;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyTrainingGrade(family: Int32) -> Int32 {
  let grade: Int32 = this.SDP_FamilySlottedGrade(family);
  if grade != this.SDP_FamilyMasteredGrade(family) + 1
    || SDP_FamilyThreshold(family, grade) <= 0 { return 0; };
  return grade;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyAddXP(family: Int32, amount: Int32, useXP: Bool) -> Int32 {
  let grade: Int32 = this.SDP_FamilyTrainingGrade(family);
  if grade <= 0 || amount <= 0 { return 0; };
  this.SDP_FamilyEnsureData();
  let index: Int32 = (family - 1) * 11 + grade - 1;
  let before: Int32 = this.m_sdpFamilyXP[index];
  let maximum: Int32 = SDP_FamilyThreshold(family, grade);
  if before >= maximum { return 0; };
  this.m_sdpFamilyXP[index] = Min(maximum, before + amount);
  let awarded: Int32 = this.m_sdpFamilyXP[index] - before;
  if useXP { this.m_sdpFamilyUseXP[index] += awarded; };
  return awarded;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyAwardUse(family: Int32, source: Int32) -> Int32 {
  if SDP_ChannelFamily(family) { return 0; };  // v2 channels pay instead; v1 triggers are still measured
  let grade: Int32 = this.SDP_FamilyTrainingGrade(family);
  if grade <= 0 || this.SDP_FamilyXP(family, grade) >= SDP_FamilyThreshold(family, grade) { return 0; };
  let baseXP: Int32 = SDP_TrainingFamilyAward(family, source, grade);
  if baseXP <= 0 { return 0; };
  let awarded: Int32 = this.SDP_FamilyAddXP(
    family, this.SDP_TuningScaledXP(family, baseXP), true
  );
  this.SDP_TuningLogAward(family, grade, source, baseXP, awarded,
    this.SDP_FamilyXP(family, grade), SDP_FamilyThreshold(family, grade));
  return awarded;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ClampShardXPToUseOnlyCaps() -> Void {
  this.SDP_OrderEnsureDeadeyeXP();
  this.SDP_FamilyEnsureData();
  let grade: Int32 = 1;
  while grade <= 11 {
    this.m_sdpOrderDeadeyeXP[grade - 1] = Min(
      this.m_sdpOrderDeadeyeXP[grade - 1], SDP_OrderDeadeyeThreshold(grade)
    );
    grade += 1;
  };
  let family: Int32 = 1;
  while family <= SDP_FamilyCount() {
    grade = 1;
    while grade <= SDP_FamilyMaxGrade(family) {
      let index: Int32 = (family - 1) * 11 + grade - 1;
      this.m_sdpFamilyXP[index] = Min(
        this.m_sdpFamilyXP[index], SDP_FamilyThreshold(family, grade)
      );
      grade += 1;
    };
    family += 1;
  };
  this.m_sdpDeadeyeTier1PlusXP = Min(
    this.m_sdpDeadeyeTier1PlusXP, this.SDP_DeadeyeTier1PlusThreshold()
  );
  this.m_sdpPrototypeDeadeyeXP = Min(
    this.m_sdpPrototypeDeadeyeXP, this.SDP_PrototypeDeadeyeThreshold()
  );
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyReconcilePackages() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  let packages: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(this.m_owner.GetGame());
  let appliedIDs: array<TweakDBID>;
  packages.GetAppliedPackages(this.m_owner, appliedIDs);
  let family: Int32 = 1;
  while family <= SDP_FamilyCount() {
    let active: Int32 = this.SDP_FamilyActiveGrade(family);
    let grade: Int32 = 1;
    while grade <= SDP_FamilyMaxGrade(family) {
      let effect: Int32 = 1;
      while effect <= SDP_FamilyEffectCount(family, grade) {
        let packageID: TweakDBID = SDP_FamilyEffectPackage(family, grade, effect);
        if NotEquals(packageID, t"None") {
          let applied: Bool = ArrayContains(appliedIDs, packageID);
          let desired: Bool = grade <= active
            && !ArrayContains(appliedIDs, SDP_ShardPackageSource(packageID));
          if desired && !applied {
            packages.ApplyPackage(this.m_owner, this.m_owner, packageID);
          } else {
            if !desired && applied { packages.RemovePackage(this.m_owner, packageID); };
          };
        };
        effect += 1;
      };
      let customID: TweakDBID = SDP_FamilyCustomPackage(family, grade);
      if NotEquals(customID, t"None") {
        let customApplied: Bool = ArrayContains(appliedIDs, customID);
        if grade <= active && !customApplied {
          packages.ApplyPackage(this.m_owner, this.m_owner, customID);
        } else {
          if grade > active && customApplied { packages.RemovePackage(this.m_owner, customID); };
        };
      };
      grade += 1;
    };
    family += 1;
  };
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) {
    player.SDP_BoltUpdateWeapon(this.SDP_FamilyActiveGrade(9) >= 9);
  };
  this.SDP_QueueChromeRefresh();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyGrantShard(family: Int32, grade: Int32) -> Bool {
  if !IsDefined(this.m_owner) || SDP_FamilyThreshold(family, grade) <= 0 { return false; };
  let itemID: TweakDBID = SDP_FamilyItemID(family, grade);
  if Equals(itemID, t"None") { return false; };
  return GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GiveItemByTDBID(this.m_owner, itemID, 1);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilySlotShard(family: Int32, grade: Int32, slot: Int32) -> Bool {
  if !IsDefined(this.m_owner) || slot < 0 || slot >= 3
    || grade != this.SDP_FamilyMasteredGrade(family) + 1
    || this.SDP_FamilySlottedGrade(family) > 0 { return false; };
  let itemID: TweakDBID = SDP_FamilyItemID(family, grade);
  if Equals(itemID, t"None") { return false; };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return false; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let processorData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
  if !IsDefined(processorData) || processorData.HasPartInSlot(slotID) { return false; };
  let items: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, items);
  let i: Int32 = 0;
  while i < ArraySize(items) {
    if IsDefined(items[i]) && Equals(ItemID.GetTDBID(items[i].GetID()), itemID) {
      if !ts.AddPart(this.m_owner, processor, items[i].GetID(), slotID) { return false; };
      this.SDP_FamilyReconcilePackages();
      return true;
    };
    i += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyRecord(family: Int32) -> Bool {
  let grade: Int32 = this.SDP_FamilyTrainingGrade(family);
  if grade <= 0 || this.SDP_FamilyXP(family, grade) < SDP_FamilyThreshold(family, grade) { return false; };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return false; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let itemData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) { return false; };
  let slot: Int32 = 0;
  while slot < 3 {
    let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
    if itemData.HasPartInSlot(slotID) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slotID);
      if Equals(ItemID.GetTDBID(InnerItemData.GetItemID(part)), SDP_FamilyItemID(family, grade)) {
        let removed: ItemID = ts.RemovePart(this.m_owner, processor, slotID);
        if !ItemID.IsValid(removed) { return false; };
        if !ts.GiveItem(this.m_owner, removed, 1) {
          ts.AddPart(this.m_owner, processor, removed, slotID);
          return false;
        };
        this.SDP_FamilyEnsureData();
        this.m_sdpFamilyMastery[family - 1] = grade;
        this.SDP_FamilyReconcilePackages();
        return true;
      };
    };
    slot += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_FamilyUpgrade(family: Int32, grade: Int32) -> Bool {
  if !IsDefined(this.m_owner) || family < 1 || family > 14
    || grade != this.SDP_FamilyMasteredGrade(family) + 1
    || grade < 2 || grade > 11 { return false; };
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) && player.IsInCombat() { return false; };
  let oldItem: TweakDBID = SDP_FamilyItemID(family, grade - 1);
  let newItem: TweakDBID = SDP_FamilyItemID(family, grade);
  let material: TweakDBID = SDP_OrderDeadeyeUpgradeMaterial(grade);
  let cost: Int32 = SDP_OrderDeadeyeUpgradeCost(grade);
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  if ts.GetItemQuantityWithDuplicates(this.m_owner, ItemID.CreateQuery(material)) < cost { return false; };
  let items: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, items);
  let baseShard: ItemID = ItemID.None();
  let i: Int32 = 0;
  while i < ArraySize(items) {
    if IsDefined(items[i]) && Equals(ItemID.GetTDBID(items[i].GetID()), oldItem) {
      baseShard = items[i].GetID();
      break;
    };
    i += 1;
  };
  if !ItemID.IsValid(baseShard) || !ts.RemoveItem(this.m_owner, baseShard, 1) { return false; };
  if !ts.RemoveItemByTDBID(this.m_owner, material, cost, true) {
    ts.GiveItemByTDBID(this.m_owner, oldItem, 1);
    return false;
  };
  if !ts.GiveItemByTDBID(this.m_owner, newItem, 1) {
    ts.GiveItemByTDBID(this.m_owner, oldItem, 1);
    ts.GiveItemByTDBID(this.m_owner, material, cost);
    return false;
  };
  return true;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_FamilyStatus(family: Int32) -> String {
  if family < 1 || family > SDP_FamilyCount() { return "Unknown family"; };
  let grade: Int32 = this.SDP_FamilyTrainingGrade(family);
  if grade == 0 { grade = Min(11, Max(1, this.SDP_FamilyMasteredGrade(family))); };
  return SDP_FamilyName(family) + " mastered=" + IntToString(this.SDP_FamilyMasteredGrade(family))
    + " slotted=" + IntToString(this.SDP_FamilySlottedGrade(family))
    + " grade=" + IntToString(grade)
    + " XP=" + IntToString(this.SDP_FamilyXP(family, grade))
    + "/" + IntToString(SDP_FamilyThreshold(family, grade))
    + " useXP=" + IntToString(this.SDP_FamilyUseXP(family, grade));
}
