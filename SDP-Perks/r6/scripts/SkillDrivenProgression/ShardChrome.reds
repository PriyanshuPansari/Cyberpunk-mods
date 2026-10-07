module SkillDrivenProgression

// License to Chrome 3 has a scripted purchase side effect, not a rank GLP.
// Coalesce refreshes until queued equipment changes have settled. Keep using
// the native side-upgrade path so quality and rolled stats are preserved.
public class SDPChromeRefresh extends DelayCallback {
  public let m_data: wref<PlayerDevelopmentData>;

  public func Call() -> Void {
    if IsDefined(this.m_data) { this.m_data.SDP_RefreshChrome(); };
  }
}

@addField(PlayerDevelopmentData)
private let m_sdpChromeRefreshQueued: Bool;

// Once we have managed Chrome, also repair leftover boosted items after load
// or a late equipment request. Purchased vanilla Chrome still takes priority.
@addField(PlayerDevelopmentData)
private persistent let m_sdpChromeManaged: Bool;

@addMethod(PlayerDevelopmentData)
public final const func SDP_QueueChromeRefresh() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled()
    || this.m_sdpChromeRefreshQueued { return; };
  this.m_sdpChromeRefreshQueued = true;
  let callback: ref<SDPChromeRefresh> = new SDPChromeRefresh();
  callback.m_data = this;
  GameInstance.GetDelaySystem(this.m_owner.GetGame()).DelayCallback(callback, 0.10, false);
}

// Match the actual side-upgrade link AND rolled stats, rather than selecting
// another item of the same cyberware type/quality from the player's inventory.
@addMethod(PlayerDevelopmentData)
private final func SDP_ChromeOriginal(boosted: ItemID) -> ItemID {
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let boostedData: wref<gameItemData> = ts.GetItemData(this.m_owner, boosted);
  if !IsDefined(boostedData) { return ItemID.None(); };
  let boostedPart: InnerItemData;
  boostedData.GetItemPart(boostedPart, t"AttachmentSlots.StatsShardSlot");
  let boostedStats: ItemID = InnerItemData.GetItemID(boostedPart);
  if !ItemID.IsValid(boostedStats) { return ItemID.None(); };
  let items: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, items);
  for item in items {
    let side: ref<Item_Record>;
    if IsDefined(item) && RPGManager.CyberwareHasSideUpgrade(item.GetID(), side)
      && Equals(side.GetID(), ItemID.GetTDBID(boosted)) {
      let part: InnerItemData;
      item.GetItemPart(part, t"AttachmentSlots.StatsShardSlot");
      let stats: ItemID = InnerItemData.GetItemID(part);
      if ItemID.IsValid(stats) && Equals(ItemID.GetTDBID(stats), ItemID.GetTDBID(boostedStats))
        && ItemID.GetRngSeed(stats) == ItemID.GetRngSeed(boostedStats) {
        return item.GetID();
      };
    };
  };
  return ItemID.None();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_RefreshChrome() -> Void {
  this.m_sdpChromeRefreshQueued = false;
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  let equipment: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.m_owner);
  if !IsDefined(equipment) { return; };
  let active: Bool = this.IsNewPerkBought(gamedataNewPerkType.Tech_Central_Milestone_3) >= 3;
  if active { this.m_sdpChromeManaged = true; };
  if !this.m_sdpChromeManaged { return; };
  let slot: Int32 = 0;
  while slot < Min(3, equipment.GetNumberOfSlots(gamedataEquipmentArea.MusculoskeletalSystemCW, true)) {
    let item: ItemID = equipment.GetItemInEquipSlot(gamedataEquipmentArea.MusculoskeletalSystemCW, slot);
    if ItemID.IsValid(item) {
      let side: ref<Item_Record>;
      let baseItem: Bool = RPGManager.CyberwareHasSideUpgrade(item, side);
      if active {
        if baseItem {
          PowerUpCyberwareEffector.PowerUpCyberwareInSlot(this.m_owner, gamedataEquipmentArea.MusculoskeletalSystemCW, slot);
        };
      } else {
        if slot >= 2 {
          EquipmentSystem.RequestUnequipItem(this.m_owner, gamedataEquipmentArea.MusculoskeletalSystemCW, slot);
        } else {
          if !baseItem {
            let original: ItemID = this.SDP_ChromeOriginal(item);
            if ItemID.IsValid(original) {
              let request: ref<ReplaceEquipmentRequest> = new ReplaceEquipmentRequest();
              request.owner = this.m_owner;
              request.slotIndex = slot;
              request.itemID = original;
              request.addToInventory = false;
              request.removeOldItem = false;
              request.transferInstalledParts = true;
              EquipmentSystem.GetInstance(this.m_owner).QueueRequest(request);
            };
          };
        };
      };
    };
    slot += 1;
  };
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnReplaceEquipmentRequest(request: ref<ReplaceEquipmentRequest>) -> Void {
  wrappedMethod(request);
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this.m_owner);
  if IsDefined(data) { data.SDP_QueueChromeRefresh(); };
}
