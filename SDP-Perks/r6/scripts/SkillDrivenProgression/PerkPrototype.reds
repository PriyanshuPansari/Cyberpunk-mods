// Character-owned training and mastery for the first Deadeye shard.
// Old virtual-slot saves remain readable; physical processor use takes over
// once the new processor is equipped.
module SkillDrivenProgression

@addField(PlayerDevelopmentData)
public persistent let m_sdpPrototypeProcessorEquipped: Bool;

@addField(PlayerDevelopmentData)
public persistent let m_sdpPrototypeShardSlots: array<Int32>;

@addField(PlayerDevelopmentData)
public persistent let m_sdpPrototypeDeadeyeXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpPrototypeDeadeyeHitXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpPrototypeDeadeyeBurned: Bool;

@addField(PlayerDevelopmentData)
public persistent let m_sdpDeadeyeTier1PlusXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpDeadeyeTier1PlusHitXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpDeadeyeTier1PlusBurned: Bool;

// One-time conversion of the retired two-grade prototype into the current chain.
@addField(PlayerDevelopmentData)
public persistent let m_sdpLegacyDeadeyeMigrated: Bool;

// Old burn-in code removed the physical shard without returning it. Repair
// those saves once, while leaving deliberately sold shards alone afterward.
@addField(PlayerDevelopmentData)
public persistent let m_sdpDeadeyeUpgradeProvisioned: Bool;

@addField(PlayerDevelopmentData)
public persistent let m_sdpPrototypePhysicalMode: Bool;

// The starter processor is granted once per character, including old saves.
@addField(PlayerDevelopmentData)
public persistent let m_sdpStarterProcessorProvisioned: Bool;

// Transient duplicate guard for repeated damage events from one attack.
@addField(PlayerDevelopmentData)
public let m_sdpPrototypeLastDeadeyeAttack: ref<AttackData>;

@addField(PlayerDevelopmentData)
public let m_sdpPrototypeLastDeadeyeTarget: EntityID;

@addField(PlayerDevelopmentData)
public let m_sdpPrototypeLastDeadeyeAttackTime: Float;

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeDeadeyeThreshold() -> Int32 {
  return 150;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_DeadeyeTier1PlusThreshold() -> Int32 {
  return 80;
}

public func SDP_DeadeyeShardTier(itemID: TweakDBID) -> Int32 {
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeTier1Shard") { return 1; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeTier1PlusShard") { return 2; };
  return 0;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeEnsureSlots() -> Void {
  while ArraySize(this.m_sdpPrototypeShardSlots) < 3 {
    ArrayPush(this.m_sdpPrototypeShardSlots, 0);
  };
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeHasDeadeyeSlotted() -> Bool {
  if this.m_sdpPrototypePhysicalMode {
    return this.SDP_PrototypePhysicalDeadeyeSlot() >= 0;
  };
  let i: Int32 = 0;
  while i < ArraySize(this.m_sdpPrototypeShardSlots) {
    if this.m_sdpPrototypeShardSlots[i] == 1 {
      return true;
    };
    i += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeDeadeyeActive() -> Bool {
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeDeadeyeTraining() -> Bool {
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_DeadeyeTier1PlusActive() -> Bool {
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_DeadeyeTier1PlusTraining() -> Bool {
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypePhysicalProcessorID() -> ItemID {
  if !IsDefined(this.m_owner) {
    return ItemID.None();
  };
  let equipment: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.m_owner);
  if !IsDefined(equipment) {
    return ItemID.None();
  };
  let slot: Int32 = 0;
  while slot < equipment.GetNumberOfSlots(gamedataEquipmentArea.EyesCW, true) {
    let item: ItemID = equipment.GetItemInEquipSlot(gamedataEquipmentArea.EyesCW, slot);
    if ItemID.IsValid(item)
      && Equals(ItemID.GetTDBID(item), t"SkillDrivenProgression.NeuralProcessor") {
      return item;
    };
    slot += 1;
  };
  return ItemID.None();
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_ProcessorEquipSlotIndex() -> Int32 {
  let area: ref<EquipmentArea_Record> = TweakDBInterface.GetEquipmentAreaRecord(t"EquipmentArea.EyesCW");
  if !IsDefined(area) { return -1; };
  let index: Int32 = 0;
  while index < area.GetEquipSlotsCount() {
    if Equals(area.GetEquipSlotsItem(index).GetID(), t"SkillDrivenProgression.ProcessorEquipSlot") {
      return index;
    };
    index += 1;
  };
  return -1;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeProcessorPresent() -> Bool {
  if this.m_sdpPrototypePhysicalMode {
    return ItemID.IsValid(this.SDP_PrototypePhysicalProcessorID());
  };
  return this.m_sdpPrototypeProcessorEquipped;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeShardSlotID(index: Int32) -> TweakDBID {
  if index == 0 { return t"SkillDrivenProgression.ShardSlot1"; };
  if index == 1 { return t"SkillDrivenProgression.ShardSlot2"; };
  return t"SkillDrivenProgression.ShardSlot3";
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypePhysicalDeadeyeSlot() -> Int32 {
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) {
    return -1;
  };
  let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) {
    return -1;
  };
  let slot: Int32 = 0;
  while slot < 3 {
    let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
    if itemData.HasPartInSlot(slotID) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slotID);
      if SDP_DeadeyeShardTier(ItemID.GetTDBID(InnerItemData.GetItemID(part))) > 0 {
        return slot;
      };
    };
    slot += 1;
  };
  return -1;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypePhysicalDeadeyeTier() -> Int32 {
  let slot: Int32 = this.SDP_PrototypePhysicalDeadeyeSlot();
  if slot < 0 { return 0; };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) { return 0; };
  let part: InnerItemData;
  itemData.GetItemPart(part, this.SDP_PrototypeShardSlotID(slot));
  return SDP_DeadeyeShardTier(ItemID.GetTDBID(InnerItemData.GetItemID(part)));
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeRefreshPhysical() -> Void {
  if ItemID.IsValid(this.SDP_PrototypePhysicalProcessorID()) {
    this.m_sdpPrototypePhysicalMode = true;
    this.m_sdpStarterProcessorProvisioned = true;
  };
  if this.m_sdpPrototypePhysicalMode {
    this.SDP_PrototypeReconcileDeadeye();
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EnsureStarterProcessor() -> Bool {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() {
    return false;
  };
  if ItemID.IsValid(this.SDP_PrototypePhysicalProcessorID()) {
    this.SDP_PrototypeRefreshPhysical();
    this.SDP_EnsureRelicModule();
    return true;
  };
  if this.m_sdpStarterProcessorProvisioned { return true; };
  let slot: Int32 = this.SDP_ProcessorEquipSlotIndex();
  let data: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.m_owner);
  if !IsDefined(data)
    || slot < 0
    || slot >= data.GetNumberOfSlots(gamedataEquipmentArea.EyesCW, true)
    || ItemID.IsValid(data.GetItemInEquipSlot(gamedataEquipmentArea.EyesCW, slot)) {
    return false;
  };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let inventory: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, inventory);
  let item: ItemID = ItemID.None();
  let i: Int32 = 0;
  while i < ArraySize(inventory) {
    if IsDefined(inventory[i])
      && Equals(ItemID.GetTDBID(inventory[i].GetID()), t"SkillDrivenProgression.NeuralProcessor") {
      item = inventory[i].GetID();
      break;
    };
    i += 1;
  };
  if !ItemID.IsValid(item) {
    if !ts.GiveItemByTDBID(this.m_owner, t"SkillDrivenProgression.NeuralProcessor", 1) {
      return false;
    };
    ArrayClear(inventory);
    ts.GetItemList(this.m_owner, inventory);
    i = 0;
    while i < ArraySize(inventory) {
      if IsDefined(inventory[i])
        && Equals(ItemID.GetTDBID(inventory[i].GetID()), t"SkillDrivenProgression.NeuralProcessor") {
        item = inventory[i].GetID();
        break;
      };
      i += 1;
    };
  };
  if !ItemID.IsValid(item) { return false; };
  let request: ref<EquipRequest> = new EquipRequest();
  request.owner = this.m_owner;
  request.itemID = item;
  request.slotIndex = slot;
  request.addToInventory = false;
  GameInstance.GetScriptableSystemsContainer(this.m_owner.GetGame()).Get(n"EquipmentSystem").QueueRequest(request);
  return true;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_RelicModulePresent() -> Bool {
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return false; };
  let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GetItemData(this.m_owner, processor);
  return IsDefined(itemData) && itemData.HasPartInSlot(t"SkillDrivenProgression.RelicSlot");
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EnsureRelicModule() -> Bool {
  if !IsDefined(this.m_owner)
    || GameInstance.GetQuestsSystem(this.m_owner.GetGame()).GetFact(n"q005_johnny_chip_acquired") < 1 {
    return false;
  };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return false; };
  if this.SDP_RelicModulePresent() { return true; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let inventory: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, inventory);
  let item: ItemID = ItemID.None();
  let i: Int32 = 0;
  while i < ArraySize(inventory) {
    if IsDefined(inventory[i])
      && Equals(ItemID.GetTDBID(inventory[i].GetID()), t"SkillDrivenProgression.RelicModule") {
      item = inventory[i].GetID();
      break;
    };
    i += 1;
  };
  if !ItemID.IsValid(item) {
    if !ts.GiveItemByTDBID(this.m_owner, t"SkillDrivenProgression.RelicModule", 1) {
      return false;
    };
    ArrayClear(inventory);
    ts.GetItemList(this.m_owner, inventory);
    i = 0;
    while i < ArraySize(inventory) {
      if IsDefined(inventory[i])
        && Equals(ItemID.GetTDBID(inventory[i].GetID()), t"SkillDrivenProgression.RelicModule") {
        item = inventory[i].GetID();
        break;
      };
      i += 1;
    };
  };
  if !ItemID.IsValid(item) { return false; };
  return ts.AddPart(this.m_owner, processor, item, t"SkillDrivenProgression.RelicSlot");
}

// CET entry points for the physical-item slice. The inventory items are real;
// these helpers avoid relying on unfinished processor UI during testing.
@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalGrantItems() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let processor: Bool = ts.GiveItemByTDBID(this.m_owner, t"SkillDrivenProgression.NeuralProcessor", 1);
  let shard: Bool = ts.GiveItemByTDBID(this.m_owner, SDP_OrderDeadeyeItemID(1), 1);
  return processor && shard;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalGrantDeadeyeShard() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  return GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GiveItemByTDBID(
    this.m_owner, SDP_OrderDeadeyeItemID(1), 1
  );
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EnsureDeadeyeUpgradeShard() -> Void {
  return;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_DeadeyeTier1PlusUpgradeCost() -> Int32 {
  return 20;
}

// Runs from the processor menu anywhere outside combat. The physical copy is
// replaced; the character-owned Tier 1 and Tier 1+ progress is untouched.
@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalUpgradeDeadeye() -> Bool {
  return this.SDP_OrderUpgradeDeadeye(2);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalEquipProcessor() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  let data: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.m_owner);
  let slot: Int32 = this.SDP_ProcessorEquipSlotIndex();
  if !IsDefined(data) || slot < 0 || slot >= data.GetNumberOfSlots(gamedataEquipmentArea.EyesCW, true) { return false; };
  let req: ref<EquipRequest> = new EquipRequest();
  req.owner = this.m_owner;
  req.itemID = ItemID.FromTDBID(t"SkillDrivenProgression.NeuralProcessor");
  req.slotIndex = slot;
  req.addToInventory = true;
  GameInstance.GetScriptableSystemsContainer(this.m_owner.GetGame()).Get(n"EquipmentSystem").QueueRequest(req);
  return true;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalSlotDeadeye(slot: Int32) -> Bool {
  return this.SDP_OrderSlotDeadeye(1, slot);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalSlotDeadeyeTier1Plus(slot: Int32) -> Bool {
  return this.SDP_OrderSlotDeadeye(2, slot);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PhysicalUnslotDeadeye() -> Bool {
  return this.SDP_OrderUnslotDeadeye();
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypePackageApplied() -> Bool {
  return this.SDP_DeadeyePackageApplied(t"SkillDrivenProgression.DeadeyePrototypeTier1");
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_DeadeyePackageApplied(packageID: TweakDBID) -> Bool {
  if !IsDefined(this.m_owner) {
    return false;
  };
  let ids: array<TweakDBID>;
  GameInstance.GetGameplayLogicPackageSystem(this.m_owner.GetGame()).GetAppliedPackages(this.m_owner, ids);
  let i: Int32 = 0;
  while i < ArraySize(ids) {
    if Equals(ids[i], packageID) {
      return true;
    };
    i += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeReconcileDeadeye() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() {
    return;
  };
  let packages: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(this.m_owner.GetGame());
  let packageID: TweakDBID = t"SkillDrivenProgression.DeadeyePrototypeTier1";
  let applied: Bool = this.SDP_PrototypePackageApplied();
  if this.SDP_PrototypeDeadeyeActive() && !applied {
    packages.ApplyPackage(this.m_owner, this.m_owner, packageID);
  } else {
    if !this.SDP_PrototypeDeadeyeActive() && applied {
      packages.RemovePackage(this.m_owner, packageID);
    };
  };
  let plusPackage: TweakDBID = t"SkillDrivenProgression.DeadeyePrototypeTier1Plus";
  let plusApplied: Bool = this.SDP_DeadeyePackageApplied(plusPackage);
  if this.SDP_DeadeyeTier1PlusActive() && !plusApplied {
    packages.ApplyPackage(this.m_owner, this.m_owner, plusPackage);
  } else {
    if !this.SDP_DeadeyeTier1PlusActive() && plusApplied {
      packages.RemovePackage(this.m_owner, plusPackage);
    };
  };
  this.SDP_OrderReconcileDeadeyePackages();
  this.SDP_FamilyReconcilePackages();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeEquipProcessor(equipped: Bool) -> Void {
  this.SDP_PrototypeEnsureSlots();
  this.m_sdpPrototypeProcessorEquipped = equipped;
  if !equipped {
    let i: Int32 = 0;
    while i < ArraySize(this.m_sdpPrototypeShardSlots) {
      this.m_sdpPrototypeShardSlots[i] = 0;
      i += 1;
    };
  };
  this.SDP_PrototypeReconcileDeadeye();
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeSlotDeadeye(slot: Int32) -> Bool {
  this.SDP_PrototypeEnsureSlots();
  if !this.m_sdpPrototypeProcessorEquipped
    || this.m_sdpPrototypeDeadeyeBurned
    || slot < 0 || slot >= 3 {
    return false;
  };
  if this.m_sdpPrototypeShardSlots[slot] != 0 || this.SDP_PrototypeHasDeadeyeSlotted() {
    return false;
  };
  this.m_sdpPrototypeShardSlots[slot] = 1;
  this.SDP_PrototypeReconcileDeadeye();
  return true;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeUnslot(slot: Int32) -> Bool {
  this.SDP_PrototypeEnsureSlots();
  if slot < 0 || slot >= 3 || this.m_sdpPrototypeShardSlots[slot] == 0 {
    return false;
  };
  this.m_sdpPrototypeShardSlots[slot] = 0;
  this.SDP_PrototypeReconcileDeadeye();
  return true;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeAddUseXP(amount: Int32) -> Int32 {
  if amount > 0 {
    if this.SDP_PrototypeDeadeyeTraining() {
      this.m_sdpPrototypeDeadeyeXP = Min(
        this.SDP_PrototypeDeadeyeThreshold(),
        this.m_sdpPrototypeDeadeyeXP + amount
      );
    } else {
      if this.SDP_DeadeyeTier1PlusTraining() {
        this.m_sdpDeadeyeTier1PlusXP = Min(
          this.SDP_DeadeyeTier1PlusThreshold(),
          this.m_sdpDeadeyeTier1PlusXP + amount
        );
      };
    };
  };
  if this.SDP_DeadeyeTier1PlusTraining() { return this.m_sdpDeadeyeTier1PlusXP; };
  return this.m_sdpPrototypeDeadeyeXP;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeOnDamagingHit(evt: ref<gameTargetDamageEvent>) -> Void {
  let legacyTraining: Bool = this.SDP_PrototypeDeadeyeTraining() || this.SDP_DeadeyeTier1PlusTraining();
  let orderTraining: Bool = this.SDP_OrderDeadeyeTrainingGrade() > 0;
  if (!legacyTraining && !orderTraining)
    || !IsDefined(evt)
    || evt.damage <= 0.00
    || !IsDefined(evt.target)
    || !IsDefined(evt.attackData)
    || !IsDefined(evt.attackData.GetWeapon())
    || !evt.attackData.GetWeapon().IsRanged()
    || evt.attackData.HasFlag(hitFlag.DamageOverTime) {
    return;
  };
  let targetPuppet: ref<ScriptedPuppet> = evt.target as ScriptedPuppet;
  if !IsDefined(targetPuppet) || !targetPuppet.AwardsExperience() {
    return;
  };
  let headshot: Bool = evt.attackData.HasFlag(hitFlag.Headshot);
  let weakspot: Bool = evt.attackData.HasFlag(hitFlag.WeakspotHit);
  let focusHit: Bool = orderTraining
    && StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"FocusedCoolPerkSE");
  let deadeyeHit: Bool = orderTraining
    && StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"DeadeyeSE");
  let weaponType: gamedataItemType = WeaponObject.GetWeaponType(evt.attackData.GetWeapon().GetItemID());
  let precisionWeapon: Bool = Equals(weaponType, gamedataItemType.Wea_Handgun)
    || Equals(weaponType, gamedataItemType.Wea_Revolver)
    || Equals(weaponType, gamedataItemType.Wea_SniperRifle)
    || Equals(weaponType, gamedataItemType.Wea_PrecisionRifle);
  let neutralization: Bool = orderTraining
    && (evt.attackData.HasFlag(hitFlag.WasKillingBlow)
      || evt.attackData.HasFlag(hitFlag.Defeated));
  if !headshot && !weakspot && !focusHit && !deadeyeHit && !neutralization {
    return;
  };
  let targetID: EntityID = evt.target.GetEntityID();
  let attackTime: Float = evt.attackData.GetAttackTime();
  if this.m_sdpPrototypeLastDeadeyeAttack == evt.attackData
    && this.m_sdpPrototypeLastDeadeyeTarget == targetID
    && this.m_sdpPrototypeLastDeadeyeAttackTime == attackTime {
    return;
  };
  this.m_sdpPrototypeLastDeadeyeAttack = evt.attackData;
  this.m_sdpPrototypeLastDeadeyeTarget = targetID;
  this.m_sdpPrototypeLastDeadeyeAttackTime = attackTime;
  if neutralization { this.SDP_OrderNoteAimedNeutralization(evt); };
  let legacyAward: Int32 = (headshot || weakspot) ? 2 : 0;
  if orderTraining {
    let grade: Int32 = this.SDP_OrderDeadeyeTrainingGrade();
    let useEvent: TweakDBID = t"None";
    if focusHit {
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.FocusDamagingHit", grade);
    };
    if headshot {
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.DeadeyeHeadshotHit", grade);
    };
    if weakspot {
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.DeadeyeWeakspotHit", grade);
    };
    if focusHit && neutralization {
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.FocusNeutralization", grade);
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.HeadToHeadNeutralization", grade);
    };
    if deadeyeHit && precisionWeapon {
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.DeadeyeDamagingHit", grade);
      useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.DeadeyeEfficiencyHit", grade);
      if Vector4.Distance(this.m_owner.GetWorldPosition(), evt.target.GetWorldPosition()) >= 25.00 {
        useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.LongShotHit", grade);
      };
      if neutralization && (headshot || weakspot) {
        useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.CaliforniaReaperNeutralization", grade);
      };
      if (headshot || weakspot) && evt.attackData.HasFlag(hitFlag.CriticalHit) {
        useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.TungstenSteelCriticalHit", grade);
      };
    };
    if grade >= 10 && !focusHit {
      let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_owner.GetGame());
      if stats.GetStatValue(Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatType.IsAimingWithWeapon) < 0.50 {
        useEvent = SDP_OrderPreferDeadeyeUseEvent(useEvent, t"SkillDrivenProgression.RunNGunHipFireHit", grade);
      };
    };
    if NotEquals(useEvent, t"None") { this.SDP_OrderAwardDeadeyeUseEvent(useEvent, grade); };
  };
  if legacyTraining && legacyAward > 0 {
    let trainingPlus: Bool = this.SDP_DeadeyeTier1PlusTraining();
    if trainingPlus { legacyAward = legacyAward / 2; };
    let before: Int32 = trainingPlus ? this.m_sdpDeadeyeTier1PlusXP : this.m_sdpPrototypeDeadeyeXP;
    this.SDP_PrototypeAddUseXP(legacyAward);
    if trainingPlus {
      this.m_sdpDeadeyeTier1PlusHitXP += this.m_sdpDeadeyeTier1PlusXP - before;
    } else {
      this.m_sdpPrototypeDeadeyeHitXP += this.m_sdpPrototypeDeadeyeXP - before;
    };
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_PrototypeBurnDeadeye() -> Bool {
  if this.m_sdpPrototypeDeadeyeBurned
    || !this.SDP_PrototypeDeadeyeTraining()
    || this.m_sdpPrototypeDeadeyeXP < this.SDP_PrototypeDeadeyeThreshold() {
    return false;
  };
  if this.m_sdpPrototypePhysicalMode {
    let physicalSlot: Int32 = this.SDP_PrototypePhysicalDeadeyeSlot();
    if physicalSlot >= 0 {
      let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
      let removed: ItemID = ts.RemovePart(
        this.m_owner,
        this.SDP_PrototypePhysicalProcessorID(),
        this.SDP_PrototypeShardSlotID(physicalSlot)
      );
      if !ItemID.IsValid(removed) { return false; };
      if !ts.GiveItem(this.m_owner, removed, 1) {
        ts.AddPart(this.m_owner, this.SDP_PrototypePhysicalProcessorID(), removed, this.SDP_PrototypeShardSlotID(physicalSlot));
        return false;
      };
      this.m_sdpDeadeyeUpgradeProvisioned = true;
    };
  };
  this.m_sdpPrototypeDeadeyeBurned = true;
  this.SDP_PrototypeEnsureSlots();
  let i: Int32 = 0;
  while i < ArraySize(this.m_sdpPrototypeShardSlots) {
    if this.m_sdpPrototypeShardSlots[i] == 1 {
      this.m_sdpPrototypeShardSlots[i] = 0;
    };
    i += 1;
  };
  this.SDP_PrototypeReconcileDeadeye();
  return true;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_BurnDeadeyeTier1Plus() -> Bool {
  if this.m_sdpDeadeyeTier1PlusBurned
    || !this.SDP_DeadeyeTier1PlusTraining()
    || this.m_sdpDeadeyeTier1PlusXP < this.SDP_DeadeyeTier1PlusThreshold() {
    return false;
  };
  let slot: Int32 = this.SDP_PrototypePhysicalDeadeyeSlot();
  if slot >= 0 {
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
    let removed: ItemID = ts.RemovePart(
      this.m_owner,
      this.SDP_PrototypePhysicalProcessorID(),
      this.SDP_PrototypeShardSlotID(slot)
    );
    if !ItemID.IsValid(removed) { return false; };
    if !ts.GiveItem(this.m_owner, removed, 1) {
      ts.AddPart(this.m_owner, this.SDP_PrototypePhysicalProcessorID(), removed, this.SDP_PrototypeShardSlotID(slot));
      return false;
    };
  };
  this.m_sdpDeadeyeTier1PlusBurned = true;
  this.SDP_PrototypeReconcileDeadeye();
  return true;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_PrototypeStatus() -> String {
  let slot0: Int32 = 0;
  let slot1: Int32 = 0;
  let slot2: Int32 = 0;
  if ArraySize(this.m_sdpPrototypeShardSlots) > 0 {
    slot0 = this.m_sdpPrototypeShardSlots[0];
  };
  if ArraySize(this.m_sdpPrototypeShardSlots) > 1 {
    slot1 = this.m_sdpPrototypeShardSlots[1];
  };
  if ArraySize(this.m_sdpPrototypeShardSlots) > 2 {
    slot2 = this.m_sdpPrototypeShardSlots[2];
  };
  if this.m_sdpPrototypePhysicalMode {
    slot0 = 0;
    slot1 = 0;
    slot2 = 0;
    let physicalSlot: Int32 = this.SDP_PrototypePhysicalDeadeyeSlot();
    if physicalSlot == 0 { slot0 = 1; };
    if physicalSlot == 1 { slot1 = 1; };
    if physicalSlot == 2 { slot2 = 1; };
  };
  return "mode=" + (this.m_sdpPrototypePhysicalMode ? "physical" : "virtual")
    + " processor=" + ToString(this.SDP_PrototypeProcessorPresent())
    + " relic=" + ToString(this.SDP_RelicModulePresent())
    + " slots=" + IntToString(slot0) + "," + IntToString(slot1) + "," + IntToString(slot2)
    + " DeadeyeXP=" + IntToString(this.m_sdpPrototypeDeadeyeXP)
    + "/" + IntToString(this.SDP_PrototypeDeadeyeThreshold())
    + " hitXP=" + IntToString(this.m_sdpPrototypeDeadeyeHitXP)
    + " Deadeye1PlusXP=" + IntToString(this.m_sdpDeadeyeTier1PlusXP)
    + "/" + IntToString(this.SDP_DeadeyeTier1PlusThreshold())
    + " plusHitXP=" + IntToString(this.m_sdpDeadeyeTier1PlusHitXP)
    + " plusBurned=" + ToString(this.m_sdpDeadeyeTier1PlusBurned)
    + " slottedTier=" + IntToString(this.SDP_PrototypePhysicalDeadeyeTier())
    + " burned=" + ToString(this.m_sdpPrototypeDeadeyeBurned)
    + " active=" + ToString(this.SDP_PrototypeDeadeyeActive())
    + " package=" + ToString(this.SDP_PrototypePackageApplied())
    + " plusPackage=" + ToString(this.SDP_DeadeyePackageApplied(t"SkillDrivenProgression.DeadeyePrototypeTier1Plus"));
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ConvertLegacyDeadeyeItem(oldID: TweakDBID, newID: TweakDBID) -> Bool {
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let remaining: Int32 = ts.GetItemQuantityWithDuplicates(this.m_owner, ItemID.CreateQuery(oldID));
  while remaining > 0 {
    if !ts.RemoveItemByTDBID(this.m_owner, oldID, 1, true) { return false; };
    if !ts.GiveItemByTDBID(this.m_owner, newID, 1) {
      ts.GiveItemByTDBID(this.m_owner, oldID, 1);
      return false;
    };
    remaining -= 1;
  };
  return true;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_MigrateLegacyDeadeye() -> Void {
  if this.m_sdpLegacyDeadeyeMigrated || !IsDefined(this.m_owner)
    || !this.m_owner.IsPlayerControlled() { return; };
  this.SDP_OrderEnsureDeadeyeXP();
  let previousGrade: Int32 = this.m_sdpOrderDeadeyeMasteredGrade;
  let legacyGrade: Int32 = this.m_sdpDeadeyeTier1PlusBurned ? 2
    : (this.m_sdpPrototypeDeadeyeBurned ? 1 : 0);
  if legacyGrade > previousGrade { this.m_sdpOrderDeadeyeMasteredGrade = legacyGrade; };
  if !this.m_sdpPrototypeDeadeyeBurned && previousGrade == 0 {
    this.m_sdpOrderDeadeyeXP[0] = Max(this.m_sdpOrderDeadeyeXP[0],
      Min(SDP_OrderDeadeyeThreshold(1), this.m_sdpPrototypeDeadeyeXP));
  };
  if this.m_sdpPrototypeDeadeyeBurned && !this.m_sdpDeadeyeTier1PlusBurned
    && previousGrade <= 1 {
    this.m_sdpOrderDeadeyeXP[1] = Max(this.m_sdpOrderDeadeyeXP[1],
      Min(SDP_OrderDeadeyeThreshold(2), this.m_sdpDeadeyeTier1PlusXP));
  };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  let formerSlot: Int32 = -1;
  let formerTier: Int32 = 0;
  if ItemID.IsValid(processor) {
    let itemData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
    if IsDefined(itemData) {
      let slot: Int32 = 0;
      while slot < 3 {
        let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
        if itemData.HasPartInSlot(slotID) {
          let part: InnerItemData;
          itemData.GetItemPart(part, slotID);
          let tier: Int32 = SDP_DeadeyeShardTier(ItemID.GetTDBID(InnerItemData.GetItemID(part)));
          if tier > 0 {
            let removed: ItemID = ts.RemovePart(this.m_owner, processor, slotID);
            if !ItemID.IsValid(removed) { return; };
            if !ts.GiveItem(this.m_owner, removed, 1) {
              ts.AddPart(this.m_owner, processor, removed, slotID);
              return;
            };
            formerSlot = slot;
            formerTier = tier;
          };
        };
        slot += 1;
      };
    };
  };
  let oldBase: TweakDBID = t"SkillDrivenProgression.DeadeyeTier1Shard";
  let oldPlus: TweakDBID = t"SkillDrivenProgression.DeadeyeTier1PlusShard";
  let hadBase: Bool = ts.GetItemQuantityWithDuplicates(this.m_owner, ItemID.CreateQuery(oldBase)) > 0;
  let hadPlus: Bool = ts.GetItemQuantityWithDuplicates(this.m_owner, ItemID.CreateQuery(oldPlus)) > 0;
  if !this.SDP_ConvertLegacyDeadeyeItem(oldBase, SDP_OrderDeadeyeItemID(1))
    || !this.SDP_ConvertLegacyDeadeyeItem(oldPlus, SDP_OrderDeadeyeItemID(2)) { return; };
  if legacyGrade > previousGrade {
    let gradeItem: TweakDBID = SDP_OrderDeadeyeItemID(legacyGrade);
    if ts.GetItemQuantityWithDuplicates(this.m_owner, ItemID.CreateQuery(gradeItem)) == 0 {
      if !ts.GiveItemByTDBID(this.m_owner, gradeItem, 1) { return; };
    };
  };
  let virtualShard: Bool = false;
  let virtualIndex: Int32 = 0;
  while virtualIndex < ArraySize(this.m_sdpPrototypeShardSlots) {
    if this.m_sdpPrototypeShardSlots[virtualIndex] == 1 { virtualShard = true; };
    virtualIndex += 1;
  };
  if legacyGrade == 0 && !hadBase && !hadPlus
    && (this.m_sdpPrototypeDeadeyeXP > 0 || virtualShard) && previousGrade == 0 {
    if !ts.GiveItemByTDBID(this.m_owner, SDP_OrderDeadeyeItemID(1), 1) { return; };
  };
  let index: Int32 = 0;
  while index < ArraySize(this.m_sdpPrototypeShardSlots) {
    this.m_sdpPrototypeShardSlots[index] = 0;
    index += 1;
  };
  this.m_sdpPrototypeProcessorEquipped = false;
  this.m_sdpLegacyDeadeyeMigrated = true;
  if formerSlot >= 0 && formerTier == this.m_sdpOrderDeadeyeMasteredGrade + 1 {
    this.SDP_OrderSlotDeadeye(formerTier, formerSlot);
  };
  this.SDP_PrototypeReconcileDeadeye();
}

@wrapMethod(PlayerDevelopmentData)
public final func OnRestored(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);
  this.SDP_PrototypeEnsureSlots();
  this.SDP_OrderEnsureDeadeyeXP();
  this.SDP_FamilyEnsureData();
  this.SDP_ClampShardXPToUseOnlyCaps();
  this.SDP_MigrateLegacyDeadeye();
  this.SDP_PrototypeRefreshPhysical();
  this.SDP_EnsureStarterProcessor();
  this.SDP_PrototypeReconcileDeadeye();
}

@wrapMethod(PlayerDevelopmentData)
public final func RefreshDevelopmentSystemOnNewGameStarted() -> Void {
  wrappedMethod();
  this.SDP_PrototypeEnsureSlots();
  this.SDP_OrderEnsureDeadeyeXP();
  this.SDP_FamilyEnsureData();
  this.m_sdpLegacyDeadeyeMigrated = true;
  this.SDP_EnsureStarterProcessor();
  this.SDP_PrototypeReconcileDeadeye();
}

@wrapMethod(PlayerDevelopmentData)
public final const func IsNewPerkBought(perkType: gamedataNewPerkType) -> Int32 {
  let vanillaLevel: Int32 = wrappedMethod(perkType);
  if Equals(perkType, gamedataNewPerkType.Cool_Left_Milestone_2)
    && this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.FocusMode") {
    return Max(vanillaLevel, 2);
  };
  if Equals(perkType, gamedataNewPerkType.Cool_Inbetween_Left_2)
    && this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.DeepBreath") {
    return Max(vanillaLevel, 1);
  };
  if Equals(perkType, gamedataNewPerkType.Cool_Left_Milestone_3)
    && this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.DeadeyeMode") {
    return Max(vanillaLevel, 3);
  };
  // Ambidextrous (vanilla extra Hands slot) comes from the Hands Expansion shard.
  if Equals(perkType, gamedataNewPerkType.Tech_Central_Perk_3_2) && this.SDP_FamilyActiveGrade(22) >= 1 {
    return Max(vanillaLevel, 1);
  };
  return Max(vanillaLevel, this.SDP_FamilyPerkRank(perkType));
}

@wrapMethod(PlayerPuppet)
protected cb func OnWeaponEquipEvent(evt: ref<WeaponEquipEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  if IsDefined(evt) && IsDefined(evt.item) {
    let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
    if IsDefined(data) {
      data.SDP_OrderOnWeaponEquipped(evt.item.GetItemID());
      this.SDP_BoltUpdateWeapon(data.SDP_FamilyActiveGrade(9) >= 9);
    };
  };
  return result;
}

@wrapMethod(BaseGrenade)
protected cb func OnHit(evt: ref<gameHitEvent>) -> Bool {
  let shotBefore: Bool = this.m_shotDownByThePlayer;
  let airborne: Bool = !this.m_landedOnGround;
  let result: Bool = wrappedMethod(evt);
  if !shotBefore && this.m_shotDownByThePlayer && airborne {
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    if IsDefined(player)
      && StatusEffectSystem.ObjectHasStatusEffectWithTag(player, n"FocusedCoolPerkSE") {
      let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
      if IsDefined(data) {
        data.SDP_EncounterAddTrigger(0, 7);
        data.SDP_ChannelEvent(0, 13, 4, 1.00);   // v2: Pull! airborne grenade
        data.SDP_OrderAwardDeadeyeUseEvent(
          t"SkillDrivenProgression.PullAirborneGrenade", data.SDP_OrderDeadeyeTrainingGrade()
        );
      };
    };
  };
  return result;
}

@wrapMethod(ScriptedPuppet)
protected cb func OnDamageDealt(evt: ref<gameTargetDamageEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  if this.IsPlayer() {
    let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
    if IsDefined(data) {
      data.SDP_MeasureDeadeyeHit(evt);
      data.SDP_PrototypeOnDamagingHit(evt);
      data.SDP_FamilyOnDamagingHit(evt);
      data.SDP_ChannelOnDamageDealt(evt);
      data.SDP_EncounterOnDamageDealt(evt);
    };
  };
  return result;
}

@addMethod(EquipmentSystemPlayerData)
public final func SDP_RefreshShardProcessor() -> Void {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this.m_owner);
  if IsDefined(data) { data.SDP_PrototypeRefreshPhysical(); };
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnEquipRequest(request: ref<EquipRequest>) -> Void {
  wrappedMethod(request);
  this.SDP_RefreshShardProcessor();
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnUnequipRequest(request: ref<UnequipRequest>) -> Void {
  wrappedMethod(request);
  this.SDP_RefreshShardProcessor();
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnInstallCyberwareRequest(request: ref<InstallCyberwareRequest>) -> Void {
  wrappedMethod(request);
  this.SDP_RefreshShardProcessor();
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnUninstallCyberwareRequest(request: ref<UninstallCyberwareRequest>) -> Void {
  wrappedMethod(request);
  this.SDP_RefreshShardProcessor();
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnPartInstallRequest(request: ref<PartInstallRequest>) -> Void {
  wrappedMethod(request);
  this.SDP_RefreshShardProcessor();
}

@wrapMethod(EquipmentSystemPlayerData)
public final func OnPartUninstallRequest(request: ref<PartUninstallRequest>) -> Void {
  wrappedMethod(request);
  this.SDP_RefreshShardProcessor();
}

@wrapMethod(InventoryDataManagerV2)
public final static func GetAttachmentSlotsForInventory() -> array<TweakDBID> {
  let slots: array<TweakDBID> = wrappedMethod();
  ArrayPush(slots, t"SkillDrivenProgression.ShardSlot1");
  ArrayPush(slots, t"SkillDrivenProgression.ShardSlot2");
  ArrayPush(slots, t"SkillDrivenProgression.ShardSlot3");
  ArrayPush(slots, t"SkillDrivenProgression.RelicSlot");
  return slots;
}

@wrapMethod(UIInventoryItemModsStaticData)
public final static func GetAttachmentSlots(itemType: gamedataItemType) -> array<TweakDBID> {
  let slots: array<TweakDBID> = wrappedMethod(itemType);
  ArrayPush(slots, t"SkillDrivenProgression.ShardSlot1");
  ArrayPush(slots, t"SkillDrivenProgression.ShardSlot2");
  ArrayPush(slots, t"SkillDrivenProgression.ShardSlot3");
  ArrayPush(slots, t"SkillDrivenProgression.RelicSlot");
  return slots;
}
