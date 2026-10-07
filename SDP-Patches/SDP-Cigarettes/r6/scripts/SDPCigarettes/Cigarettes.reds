module SkillDrivenProgression

// Cigarette items and use behaviour. The items and their use action are
// defined in r6/tweaks/SkillDrivenProgression/Cigarettes.yaml; no other mod is
// needed. Optional: when Consumable Animations is installed, smoking is routed
// through the vanilla Yeheyuan/Morley junk items it animates, and those count too.
//
// Smoking grants the Composure buff (CigaretteComposure.reds) through
// SDP_OnCigaretteSmoked.

@addField(PlayerDevelopmentData)
public persistent let m_sdpCigarettesGranted: Bool;

// One-time starter supply so the feature works before any vendor stocks it.
@addMethod(PlayerDevelopmentData)
public final func SDP_GrantStarterCigarettes() -> Void {
  if this.m_sdpCigarettesGranted { return; };
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  let inventory: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  if !IsDefined(inventory) { return; };
  inventory.GiveItem(this.m_owner, ItemID.FromTDBID(t"SkillDrivenProgression.CigaretteYeheyuan"), 5);
  inventory.GiveItem(this.m_owner, ItemID.FromTDBID(t"SkillDrivenProgression.CigaretteMorley"), 5);
  this.m_sdpCigarettesGranted = true;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_CigaretteCount() -> Int32 {
  return SDP_CigaretteTotal(this.m_owner);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_UseCigarette() -> Bool {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return false; };
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if !IsDefined(player) { return false; };
  return this.SDP_TryUseCigarette(player);
}

@addMethod(PlayerDevelopmentData)
private final func SDP_TryUseCigarette(player: ref<PlayerPuppet>) -> Bool {
  if player.IsInCombat() { return false; };
  let itemData: wref<gameItemData> = SDP_FindCigarette(player);
  if !IsDefined(itemData) { return false; };
  if SDP_ConsumableAnimationsInstalled() && SDP_IsOwnCigarette(ItemID.GetTDBID(itemData.GetID())) {
    // Swap one of ours for the vanilla item Consumable Animations animates.
    let inventory: ref<TransactionSystem> = GameInstance.GetTransactionSystem(player.GetGame());
    let vanilla: TweakDBID = ItemID.GetTDBID(itemData.GetID()) == t"SkillDrivenProgression.CigaretteMorley"
      ? t"Items.GenericJunkItem24" : t"Items.GenericJunkItem23";
    if inventory.RemoveItem(player, itemData.GetID(), 1) {
      inventory.GiveItem(player, ItemID.FromTDBID(vanilla), 1);
      itemData = SDP_FindItemByRecord(player, vanilla);
      if !IsDefined(itemData) { return false; };
    };
  };
  let consume: wref<ObjectAction_Record> = ItemActionsHelper.GetConsumeAction(itemData.GetID());
  if !IsDefined(consume) { return false; };
  return ItemActionsHelper.ProcessItemAction(player.GetGame(), player, itemData, consume.GetID(), true);
}

@if(ModuleExists("ConsumableAnimations.Main"))
public func SDP_ConsumableAnimationsInstalled() -> Bool { return true; }

@if(!ModuleExists("ConsumableAnimations.Main"))
public func SDP_ConsumableAnimationsInstalled() -> Bool { return false; }

public func SDP_IsOwnCigarette(id: TweakDBID) -> Bool {
  return id == t"SkillDrivenProgression.CigaretteYeheyuan"
    || id == t"SkillDrivenProgression.CigaretteMorley";
}

public func SDP_FindItemByRecord(owner: wref<GameObject>, record: TweakDBID) -> wref<gameItemData> {
  let items: array<wref<gameItemData>>;
  GameInstance.GetTransactionSystem(owner.GetGame()).GetItemList(owner, items);
  for item in items {
    if IsDefined(item) && item.GetQuantity() > 0 && ItemID.GetTDBID(item.GetID()) == record {
      return item;
    };
  };
  return null;
}

public func SDP_IsCigarette(id: TweakDBID) -> Bool {
  if SDP_IsOwnCigarette(id) { return true; };
  return SDP_ConsumableAnimationsInstalled()
    && (id == t"Items.GenericJunkItem23" || id == t"Items.GenericJunkItem24");
}

// Looks cigarettes up by record in the actual inventory, so stacks added by
// vendors, loot, or CET are all found whatever their ItemID seed.
public func SDP_FindCigarette(owner: wref<GameObject>) -> wref<gameItemData> {
  if !IsDefined(owner) { return null; };
  let items: array<wref<gameItemData>>;
  GameInstance.GetTransactionSystem(owner.GetGame()).GetItemList(owner, items);
  let fallback: wref<gameItemData>;
  for item in items {
    if IsDefined(item) && item.GetQuantity() > 0 {
      let id: TweakDBID = ItemID.GetTDBID(item.GetID());
      if id == t"SkillDrivenProgression.CigaretteYeheyuan" { return item; };
      if SDP_IsCigarette(id) && !IsDefined(fallback) { fallback = item; };
    };
  };
  return fallback;
}

public func SDP_CigaretteTotal(owner: wref<GameObject>) -> Int32 {
  if !IsDefined(owner) { return 0; };
  let items: array<wref<gameItemData>>;
  GameInstance.GetTransactionSystem(owner.GetGame()).GetItemList(owner, items);
  let total: Int32 = 0;
  for item in items {
    if IsDefined(item) && SDP_IsCigarette(ItemID.GetTDBID(item.GetID())) {
      total += item.GetQuantity();
    };
  };
  return total;
}

// Runs after the game's consume action for any cigarette (slot, hotkey or inventory).
@wrapMethod(ConsumeAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  let itemID: TweakDBID = ItemID.GetTDBID(this.GetItemData().GetID());
  let executor: wref<GameObject> = this.GetExecutor();
  wrappedMethod(gameInstance);
  if SDP_IsCigarette(itemID) {
    let player: ref<PlayerPuppet> = executor as PlayerPuppet;
    if IsDefined(player) && player.IsPlayerControlled() {
      SDP_OnCigaretteSmoked(player);
    };
  };
}
