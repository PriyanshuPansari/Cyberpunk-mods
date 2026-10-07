// Standalone Expansion shards (families 16-23, design/expansion-shards.json):
// one per body system, single grade. While slotted (or once recorded) they
// unlock that system's extra Cyberware-EX slots (CyberwareExSlots.reds). The
// Hands shard also stands in for Ambidextrous, the vanilla extra Hands slot,
// which no longer comes from the Chrome shard.
module SkillDrivenProgression

public func SDP_ExpansionArea(family: Int32) -> gamedataEquipmentArea {
  if family == 16 { return gamedataEquipmentArea.SystemReplacementCW; };
  if family == 17 { return gamedataEquipmentArea.FrontalCortexCW; };
  if family == 18 { return gamedataEquipmentArea.CardiovascularSystemCW; };
  if family == 19 { return gamedataEquipmentArea.NervousSystemCW; };
  if family == 20 { return gamedataEquipmentArea.IntegumentarySystemCW; };
  if family == 21 { return gamedataEquipmentArea.ArmsCW; };
  if family == 22 { return gamedataEquipmentArea.HandsCW; };
  if family == 23 { return gamedataEquipmentArea.LegsCW; };
  return gamedataEquipmentArea.Invalid;
}

// Slot requirement sentinel: level 100 + family (see CyberwareExSlots.reds).
// PlayerIsNewPerkBoughtPrereq.IsFulfilled can't be wrapped (it overrides a
// native method, so the compiler can't match its signature); the two places
// that check slot prereqs are wrapped instead.

// Expansion family a slot prereq stands for, or 0 for any other prereq.
public func SDP_ExpansionSlotFamily(prereq: ref<IPrereq>) -> Int32 {
  let perk: ref<PlayerIsNewPerkBoughtPrereq> = prereq as PlayerIsNewPerkBoughtPrereq;
  if !IsDefined(perk) || perk.m_level < 100 || perk.m_level >= 200 { return 0; };
  if !SDP_FamilyIsExpansion(perk.m_level - 100) { return 0; };
  return perk.m_level - 100;
}

public func SDP_ExpansionSlotUnlocked(owner: wref<GameObject>, family: Int32) -> Bool {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(owner);
  return IsDefined(data) && data.SDP_FamilyActiveGrade(family) >= 1;
}

@wrapMethod(EquipmentSystemPlayerData)
private final const func IsSlotLocked(slot: SEquipSlot, out visibleWhenLocked: Bool) -> Bool {
  let family: Int32 = SDP_ExpansionSlotFamily(slot.unlockPrereq);
  if family > 0 {
    visibleWhenLocked = slot.visibleWhenLocked;
    let perk: ref<PlayerIsNewPerkBoughtPrereq> = slot.unlockPrereq as PlayerIsNewPerkBoughtPrereq;
    let unlocked: Bool = SDP_ExpansionSlotUnlocked(this.m_owner, family);
    return perk.m_invert ? unlocked : !unlocked;
  };
  return wrappedMethod(slot, visibleWhenLocked);
}

// On load the game drops items from slots whose prereq fails; keep the ones in
// Expansion slots that the shards unlock.
@wrapMethod(EquipmentSystemPlayerData)
private final func InitializeEquipSlotsFromRecords(slotRecords: array<wref<EquipSlot_Record>>, out equipSlots: array<SEquipSlot>) -> Void {
  let previous: array<ItemID>;
  let i: Int32 = 0;
  while i < ArraySize(equipSlots) {
    ArrayPush(previous, equipSlots[i].itemID);
    i += 1;
  };
  wrappedMethod(slotRecords, equipSlots);
  i = 0;
  while i < ArraySize(equipSlots) && i < ArraySize(previous) {
    if !ItemID.IsValid(equipSlots[i].itemID) && ItemID.IsValid(previous[i]) {
      let family: Int32 = SDP_ExpansionSlotFamily(equipSlots[i].unlockPrereq);
      if family > 0 && SDP_ExpansionSlotUnlocked(this.m_owner, family) {
        equipSlots[i].itemID = previous[i];
      };
    };
    i += 1;
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ExpansionEquippedCount(family: Int32) -> Int32 {
  let area: gamedataEquipmentArea = SDP_ExpansionArea(family);
  if !IsDefined(this.m_owner) || Equals(area, gamedataEquipmentArea.Invalid) { return 0; };
  let equipment: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.m_owner);
  if !IsDefined(equipment) { return 0; };
  let count: Int32 = 0;
  let slot: Int32 = 0;
  while slot < equipment.GetNumberOfSlots(area, true) {
    if ItemID.IsValid(equipment.GetItemInEquipSlot(area, slot)) { count += 1; };
    slot += 1;
  };
  return count;
}

// ---- Removal lock ------------------------------------------------------------------
// An unrecorded Expansion chip can't be taken out of the processor while
// cyberware sits in one of the slots it unlocks (unequip that cyberware first).
// A recorded chip unlocks its slots permanently, so it can always be removed.

@addMethod(EquipmentSystemPlayerData)
public final func SDP_ExpansionSlotsInUse(family: Int32) -> Bool {
  let area: gamedataEquipmentArea = SDP_ExpansionArea(family);
  if Equals(area, gamedataEquipmentArea.Invalid) { return false; };
  let index: Int32 = this.GetEquipAreaIndex(area);
  if index < 0 { return false; };
  let slots: array<SEquipSlot> = this.m_equipment.equipAreas[index].equipSlots;
  let i: Int32 = 0;
  while i < ArraySize(slots) {
    if ItemID.IsValid(slots[i].itemID) {
      let prereq: ref<PlayerIsNewPerkBoughtPrereq> = slots[i].unlockPrereq as PlayerIsNewPerkBoughtPrereq;
      if IsDefined(prereq) {
        if prereq.m_level == 100 + family { return true; };
        // Hands also gates the vanilla Ambidextrous slot.
        if family == 22 && Equals(prereq.m_perkType, gamedataNewPerkType.Tech_Central_Perk_3_2) { return true; };
      };
    };
    i += 1;
  };
  return false;
}

// Family of the Expansion chip in `slotID` of `itemID` that must stay installed, or 0.
public func SDP_ExpansionLockedPart(obj: ref<GameObject>, itemID: ItemID, slotID: TweakDBID) -> Int32 {
  let player: ref<PlayerPuppet> = obj as PlayerPuppet;
  if !IsDefined(player) { return 0; };
  let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(obj.GetGame()).GetItemData(obj, itemID);
  if !IsDefined(itemData) || !itemData.HasPartInSlot(slotID) { return 0; };
  let part: InnerItemData;
  itemData.GetItemPart(part, slotID);
  let family: Int32 = SDP_FamilyItemFamily(ItemID.GetTDBID(InnerItemData.GetItemID(part)));
  if !SDP_FamilyIsExpansion(family) { return 0; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if !IsDefined(data) || data.SDP_RecordedGrade(family) >= 1 { return 0; };
  let equipment: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(player);
  if !IsDefined(equipment) || !equipment.SDP_ExpansionSlotsInUse(family) { return 0; };
  return family;
}

public func SDP_ExpansionLockWarning(obj: ref<GameObject>, family: Int32) -> Void {
  let message: SimpleScreenMessage;
  message.isShown = true;
  message.duration = 4.00;
  message.message = SDP_FamilyName(family) + ": unequip the cyberware in its extra slots before removing this chip.";
  GameInstance.GetBlackboardSystem(obj.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications)
    .SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(message), true);
}

@wrapMethod(ItemModificationSystem)
private const final func RemoveItemPart(obj: ref<GameObject>, itemID: ItemID, slotID: TweakDBID, shouldUpdateEntity: Bool) -> ItemID {
  let family: Int32 = SDP_ExpansionLockedPart(obj, itemID, slotID);
  if family > 0 {
    SDP_ExpansionLockWarning(obj, family);
    return ItemID.None();
  };
  return wrappedMethod(obj, itemID, slotID, shouldUpdateEntity);
}

@wrapMethod(ItemModificationSystem)
private final func SwapItemPart(obj: ref<GameObject>, itemID: ItemID, partItemID: ItemID, slotID: TweakDBID) -> Bool {
  let family: Int32 = SDP_ExpansionLockedPart(obj, itemID, slotID);
  if family > 0 {
    SDP_ExpansionLockWarning(obj, family);
    return false;
  };
  return wrappedMethod(obj, itemID, partItemID, slotID);
}

// Installing a different chip into an occupied slot force-replaces the old one.
@wrapMethod(ItemModificationSystem)
private final func InstallItemPart(obj: ref<GameObject>, itemID: ItemID, partItemID: ItemID, opt slotID: TweakDBID) -> Bool {
  let target: TweakDBID = slotID;
  if !IsDefined(TweakDBInterface.GetAttachmentSlotRecord(target)) {
    target = EquipmentSystem.GetPlacementSlot(partItemID);
  };
  let family: Int32 = SDP_ExpansionLockedPart(obj, itemID, target);
  if family > 0 {
    SDP_ExpansionLockWarning(obj, family);
    return false;
  };
  return wrappedMethod(obj, itemID, partItemID, slotID);
}

// ---- Diagnostics (CET) -------------------------------------------------------------
// d:SDP_ExpansionDebug(21) -> recorded/slotted/active grade, XP, and every slot
// of that body area: item, which shard gates it, and whether it's locked.
@addMethod(EquipmentSystemPlayerData)
public final func SDP_ExpansionSlotDebug(family: Int32) -> String {
  let area: gamedataEquipmentArea = SDP_ExpansionArea(family);
  let index: Int32 = this.GetEquipAreaIndex(area);
  if index < 0 { return " no area"; };
  let slots: array<SEquipSlot> = this.m_equipment.equipAreas[index].equipSlots;
  let text: String = "";
  let i: Int32 = 0;
  while i < ArraySize(slots) {
    let visible: Bool;
    let gate: String = "none";
    let perk: ref<PlayerIsNewPerkBoughtPrereq> = slots[i].unlockPrereq as PlayerIsNewPerkBoughtPrereq;
    if IsDefined(perk) {
      gate = EnumValueToString("gamedataNewPerkType", Cast<Int64>(EnumInt(perk.m_perkType))) + "/" + IntToString(perk.m_level);
    } else {
      if IsDefined(slots[i].unlockPrereq) { gate = "other prereq"; };
    };
    text += "\n  slot " + IntToString(i) + ": " + (ItemID.IsValid(slots[i].itemID) ? TDBID.ToStringDEBUG(ItemID.GetTDBID(slots[i].itemID)) : "empty")
      + ", gate " + gate + ", locked " + (this.IsSlotLocked(area, i, visible) ? "yes" : "no");
    i += 1;
  };
  return text;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ExpansionDebug(family: Int32) -> String {
  let text: String = SDP_FamilyName(family) + ": recorded " + IntToString(this.SDP_FamilyMasteredGrade(family))
    + ", slotted " + IntToString(this.SDP_FamilySlottedGrade(family))
    + ", active " + IntToString(this.SDP_FamilyActiveGrade(family))
    + ", XP " + IntToString(this.SDP_FamilyXP(family, 1)) + "/" + IntToString(SDP_FamilyThreshold(family, 1));
  let equipment: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.m_owner);
  if IsDefined(equipment) { text += equipment.SDP_ExpansionSlotDebug(family); };
  return text;
}
