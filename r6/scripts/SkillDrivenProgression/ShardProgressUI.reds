// Tooltip progress is read from the character, not the physical shard copy.
module SkillDrivenProgression

public func SDP_IsProgressShard(itemID: TweakDBID) -> Bool {
  return SDP_OrderDeadeyeItemGrade(itemID) > 0
    || SDP_FamilyItemFamily(itemID) > 0;
}

@addMethod(InventoryDataManagerV2)
public final func SDP_GetProgressOwner() -> ref<GameObject> {
  return this.m_Player;
}

@addMethod(UIInventoryItemsManager)
public final func SDP_GetProgressOwner() -> ref<GameObject> {
  return this.m_player;
}

// The processor modification menu builds legacy InventoryTooltipData without
// an inventory manager. Attach it here so the program tooltip can read the
// same character-owned progress as the regular inventory tooltip.
@wrapMethod(InventoryDataManagerV2)
public final func GetTooltipDataForInventoryItem(const tooltipItemData: script_ref<InventoryItemData>, equipped: Bool, opt vendorItem: Bool, opt overrideRarity: Bool) -> ref<InventoryTooltipData> {
  let tooltip: ref<InventoryTooltipData> = wrappedMethod(tooltipItemData, equipped, vendorItem, overrideRarity);
  if IsDefined(tooltip)
    && SDP_IsProgressShard(ItemID.GetTDBID(InventoryItemData.GetID(tooltipItemData)))
    && IsDefined(this.m_uiInventorySystem) {
    tooltip.SetManager(this.m_uiInventorySystem.GetInventoryItemsManager());
  };
  return tooltip;
}

public func SDP_GetDeadeyeProgressData(opt owner: ref<GameObject>) -> ref<PlayerDevelopmentData> {
  let data: ref<PlayerDevelopmentData>;
  if IsDefined(owner) {
    data = PlayerDevelopmentSystem.GetData(owner);
    if IsDefined(data) { return data; };
  };
  let player: ref<PlayerPuppet> = GetPlayer(GetGameInstance());
  if IsDefined(player) {
    data = PlayerDevelopmentSystem.GetData(player);
    if IsDefined(data) { return data; };
  };
  let playerSystem: ref<PlayerSystem> = GameInstance.GetPlayerSystem(GetGameInstance());
  if IsDefined(playerSystem) {
    owner = playerSystem.GetLocalPlayerMainGameObject();
    if IsDefined(owner) { return PlayerDevelopmentSystem.GetData(owner); };
  };
  return null;
}

public func SDP_DeadeyeShardProgressName(name: String, itemID: TweakDBID, opt owner: ref<GameObject>) -> String {
  let oldProgress: Int32 = StrFindFirst(name, " (XP ");
  if oldProgress >= 0 { name = StrLeft(name, oldProgress); };
  return name;
}

public func SDP_DeadeyeShardProgressDescription(description: String, itemID: TweakDBID, opt owner: ref<GameObject>) -> String {
  let oldProgress: Int32 = StrFindFirst(description, "\nAttunement XP: ");
  if oldProgress >= 0 { description = StrLeft(description, oldProgress); };
  return description;
}

// Inventory mode builds the shard's program tooltip from InventoryItemData.
@wrapMethod(InventoryTooltipData)
public final static func FromInventoryItemData(const itemData: script_ref<InventoryItemData>) -> ref<InventoryTooltipData> {
  let tooltip: ref<InventoryTooltipData> = wrappedMethod(itemData);
  let itemID: TweakDBID = ItemID.GetTDBID(InventoryItemData.GetID(itemData));
  if IsDefined(tooltip) && SDP_IsProgressShard(itemID) {
    let owner: ref<GameObject>;
    if IsDefined(tooltip.GetManager()) { owner = tooltip.GetManager().SDP_GetProgressOwner(); };
    tooltip.itemName = SDP_DeadeyeShardProgressName(tooltip.itemName, itemID, owner);
    tooltip.description = SDP_DeadeyeShardProgressDescription(tooltip.description, itemID, owner);
  };
  if IsDefined(tooltip) && Equals(itemID, t"SkillDrivenProgression.NeuralProcessor") {
    tooltip.description = SDP_ProcessorLedgerDescription(tooltip.description);
  };
  return tooltip;
}

// The modification grid may use either the older item-data path or UIInventoryItem.
@wrapMethod(InventoryItemData)
public final static func GetName(const self: script_ref<InventoryItemData>) -> String {
  let name: String = wrappedMethod(self);
  let itemID: TweakDBID = ItemID.GetTDBID(InventoryItemData.GetID(self));
  if SDP_IsProgressShard(itemID) {
    return SDP_DeadeyeShardProgressName(name, itemID);
  };
  return name;
}

@wrapMethod(UIInventoryItem)
public final func GetName() -> String {
  let name: String = wrappedMethod();
  if SDP_IsProgressShard(this.GetTweakDBID()) {
    return SDP_DeadeyeShardProgressName(name, this.GetTweakDBID(), this.GetOwner());
  };
  return name;
}

// The newer inventory tooltip route reads the UI item directly.
@wrapMethod(UIInventoryItem)
public final func GetDescription() -> String {
  let description: String = wrappedMethod();
  if SDP_IsProgressShard(this.GetTweakDBID()) {
    return SDP_DeadeyeShardProgressDescription(description, this.GetTweakDBID(), this.GetOwner());
  };
  if Equals(this.GetTweakDBID(), t"SkillDrivenProgression.NeuralProcessor") {
    return SDP_ProcessorLedgerDescription(description, this.GetOwner());
  };
  return description;
}

// Program chips use a dedicated tooltip. As with Neuralware, draw progress in
// its details panel during both legacy and newer refresh paths.
@addField(ProgramTooltipController)
private let m_sdpProgressPanel: ref<inkCanvas>;

@addField(ProgramTooltipController)
private let m_sdpProgressText: ref<inkText>;

@addField(ProgramTooltipController)
private let m_sdpProgressFill: ref<inkRectangle>;

@addMethod(ProgramTooltipController)
private func SDP_EnsureProgressPanel() -> Void {
  if IsDefined(this.m_sdpProgressPanel) { return; };
  let details: ref<inkVerticalPanel> = this.GetWidget(n"inkVerticalPanelWidget9/inkVerticalPanelWidget12/details") as inkVerticalPanel;
  if !IsDefined(details) { return; };

  this.m_sdpProgressPanel = new inkCanvas();
  this.m_sdpProgressPanel.SetSize(550.0, 65.0);
  this.m_sdpProgressPanel.Reparent(details, 0);
  this.m_sdpProgressPanel.SetVisible(false);

  this.m_sdpProgressText = new inkText();
  this.m_sdpProgressText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
  this.m_sdpProgressText.SetFontSize(28);
  this.m_sdpProgressText.SetTintColor(new HDRColor(0.9, 0.9, 0.9, 1.0));
  this.m_sdpProgressText.Reparent(this.m_sdpProgressPanel);

  let background: ref<inkRectangle> = new inkRectangle();
  background.SetSize(550.0, 6.0);
  background.SetMargin(0.0, 45.0, 0.0, 0.0);
  background.SetOpacity(0.35);
  background.SetTintColor(new HDRColor(0.9, 0.9, 0.9, 1.0));
  background.Reparent(this.m_sdpProgressPanel);

  this.m_sdpProgressFill = new inkRectangle();
  this.m_sdpProgressFill.SetSize(550.0, 6.0);
  this.m_sdpProgressFill.SetMargin(0.0, 45.0, 0.0, 0.0);
  this.m_sdpProgressFill.SetRenderTransformPivot(new Vector2(0.0, 0.0));
  this.m_sdpProgressFill.SetTintColor(new HDRColor(1.0, 0.25, 0.19, 1.0));
  this.m_sdpProgressFill.Reparent(this.m_sdpProgressPanel);
}

@addMethod(ProgramTooltipController)
private func SDP_UpdateProgressPanel(itemID: TweakDBID, opt owner: ref<GameObject>) -> Void {
  this.SDP_EnsureProgressPanel();
  if !IsDefined(this.m_sdpProgressPanel) { return; };
  let orderGrade: Int32 = SDP_OrderDeadeyeItemGrade(itemID);
  let family: Int32 = SDP_FamilyItemFamily(itemID);
  if orderGrade == 0 && family == 0 {
    this.m_sdpProgressPanel.SetVisible(false);
    return;
  };
  let data: ref<PlayerDevelopmentData> = SDP_GetDeadeyeProgressData(owner);
  if !IsDefined(data) { return; };
  if family > 0 {
    let grade: Int32 = SDP_FamilyItemGrade(itemID);
    let maximum: Int32 = SDP_FamilyThreshold(family, grade);
    let current: Int32 = Min(maximum, Max(0, data.SDP_FamilyXP(family, grade)));
    let label: String = SDP_FamilyName(family) + " attunement  "
      + IntToString(current) + " / " + IntToString(maximum) + " XP";
    if data.SDP_FamilyMasteredGrade(family) >= grade {
      label = SDP_FamilyName(family) + " recorded  "
        + IntToString(current) + " / " + IntToString(maximum) + " XP";
    };
    this.m_sdpProgressText.SetText(label);
    this.m_sdpProgressFill.SetScale(new Vector2(Cast<Float>(current) / Cast<Float>(maximum), 1.0));
    this.m_sdpProgressPanel.SetVisible(true);
    this.GetWidget(n"inkVerticalPanelWidget9/inkVerticalPanelWidget12/details").SetVisible(true);
    return;
  };
  let maximum: Int32 = SDP_OrderDeadeyeThreshold(orderGrade);
  let current: Int32 = data.SDP_OrderDeadeyeXP(orderGrade);
  current = Min(maximum, Max(0, current));
  let label: String = "Deadeye attunement  " + IntToString(current) + " / " + IntToString(maximum) + " XP";
  if data.m_sdpOrderDeadeyeMasteredGrade >= orderGrade {
    label = "Deadeye recorded  " + IntToString(current) + " / " + IntToString(maximum) + " XP";
  };
  this.m_sdpProgressText.SetText(label);
  this.m_sdpProgressFill.SetScale(new Vector2(Cast<Float>(current) / Cast<Float>(maximum), 1.0));
  this.m_sdpProgressPanel.SetVisible(true);
  this.GetWidget(n"inkVerticalPanelWidget9/inkVerticalPanelWidget12/details").SetVisible(true);
}

@addMethod(ProgramTooltipController)
private func SDP_UpdateShardTierLabel(itemID: TweakDBID) -> Void {
  let orderGrade: Int32 = SDP_OrderDeadeyeItemGrade(itemID);
  let family: Int32 = SDP_FamilyItemFamily(itemID);
  if orderGrade > 0 || family > 0 {
    let grade: Int32 = orderGrade > 0 ? orderGrade : SDP_FamilyItemGrade(itemID);
    let quality: gamedataQuality = SDP_OrderDeadeyeGradeQuality(grade);
    inkWidgetRef.SetState(this.m_tierText, UIItemsHelper.QualityEnumToName(quality));
    inkTextRef.SetText(this.m_tierText, GetLocalizedText(UIItemsHelper.QualityToTierPlusString(quality)));
  };
}

@wrapMethod(ProgramTooltipController)
public func SetData(tooltipData: ref<ATooltipData>) -> Void {
  this.SDP_EnsureProgressPanel();
  wrappedMethod(tooltipData);

  let wrappedData: ref<UIInventoryItemTooltipWrapper> = tooltipData as UIInventoryItemTooltipWrapper;
  if IsDefined(wrappedData) {
    let item: wref<UIInventoryItem> = wrappedData.m_data;
    if IsDefined(item) && SDP_IsProgressShard(item.GetTweakDBID()) {
      let owner: ref<GameObject> = item.GetOwner();
      if !IsDefined(owner) { owner = wrappedData.m_displayContext.GetPlayerAsPuppet(); };
      inkTextRef.SetText(this.m_descriptionText, SDP_DeadeyeShardProgressDescription(item.GetDescription(), item.GetTweakDBID(), owner));
      inkWidgetRef.SetVisible(this.m_descriptionWrapper, true);
      this.SDP_UpdateProgressPanel(item.GetTweakDBID(), owner);
      this.SDP_UpdateShardTierLabel(item.GetTweakDBID());
    };
    return;
  };

  let itemTooltip: ref<InventoryTooltipData> = tooltipData as InventoryTooltipData;
  if IsDefined(itemTooltip)
    && SDP_IsProgressShard(ItemID.GetTDBID(itemTooltip.itemID)) {
    let owner: ref<GameObject>;
    if IsDefined(itemTooltip.GetManager()) { owner = itemTooltip.GetManager().SDP_GetProgressOwner(); };
    inkTextRef.SetText(this.m_descriptionText, itemTooltip.description);
    inkWidgetRef.SetVisible(this.m_descriptionWrapper, true);
    this.SDP_UpdateProgressPanel(ItemID.GetTDBID(itemTooltip.itemID), owner);
    this.SDP_UpdateShardTierLabel(ItemID.GetTDBID(itemTooltip.itemID));
  };
}

@wrapMethod(ProgramTooltipController)
private func RefreshUI() -> Void {
  wrappedMethod();
  let owner: ref<GameObject>;
  if IsDefined(this.m_data.GetManager()) { owner = this.m_data.GetManager().SDP_GetProgressOwner(); };
  if SDP_IsProgressShard(ItemID.GetTDBID(this.m_data.itemID)) {
    inkTextRef.SetText(this.m_nameText, SDP_DeadeyeShardProgressName(this.m_data.itemName, ItemID.GetTDBID(this.m_data.itemID), owner));
    inkTextRef.SetText(this.m_descriptionText, SDP_DeadeyeShardProgressDescription(this.m_data.description, ItemID.GetTDBID(this.m_data.itemID), owner));
    inkWidgetRef.SetVisible(this.m_descriptionWrapper, true);
  };
  this.SDP_UpdateProgressPanel(ItemID.GetTDBID(this.m_data.itemID), owner);
  this.SDP_UpdateShardTierLabel(ItemID.GetTDBID(this.m_data.itemID));
}

@wrapMethod(ProgramTooltipController)
private final func NewRefreshUI(itemData: wref<UIInventoryItem>, player: wref<PlayerPuppet>) -> Void {
  wrappedMethod(itemData, player);
  if IsDefined(itemData) {
    if SDP_IsProgressShard(itemData.GetTweakDBID()) {
      let owner: ref<GameObject> = itemData.GetOwner();
      if !IsDefined(owner) { owner = player; };
      inkTextRef.SetText(this.m_nameText, SDP_DeadeyeShardProgressName(itemData.GetName(), itemData.GetTweakDBID(), owner));
      inkTextRef.SetText(this.m_descriptionText, SDP_DeadeyeShardProgressDescription(itemData.GetDescription(), itemData.GetTweakDBID(), owner));
      inkWidgetRef.SetVisible(this.m_descriptionWrapper, true);
      this.SDP_UpdateProgressPanel(itemData.GetTweakDBID(), owner);
      this.SDP_UpdateShardTierLabel(itemData.GetTweakDBID());
      return;
    };
    this.SDP_UpdateProgressPanel(itemData.GetTweakDBID(), itemData.GetOwner());
  };
}

// Keep progress in the tooltip. A small green dot on the item tile only marks
// a shard whose current tier has enough XP to record.
@addField(InventoryItemDisplayController)
private let m_sdpReadyDot: ref<inkCircle>;

@addMethod(InventoryItemDisplayController)
private func SDP_UpdateShardReadyDot(itemID: TweakDBID, opt owner: ref<GameObject>) -> Void {
  let orderGrade: Int32 = SDP_OrderDeadeyeItemGrade(itemID);
  let family: Int32 = SDP_FamilyItemFamily(itemID);
  if orderGrade == 0 && family == 0 {
    if IsDefined(this.m_sdpReadyDot) { this.m_sdpReadyDot.SetVisible(false); };
    return;
  };
  if inkWidgetRef.IsValid(this.m_quantityWrapper) {
    inkWidgetRef.SetVisible(this.m_quantityWrapper, false);
  };
  let data: ref<PlayerDevelopmentData> = SDP_GetDeadeyeProgressData(owner);
  let ready: Bool = false;
  if IsDefined(data) {
    if orderGrade > 0 {
      ready = data.m_sdpOrderDeadeyeMasteredGrade < orderGrade
        && data.SDP_OrderDeadeyeXP(orderGrade) >= SDP_OrderDeadeyeThreshold(orderGrade);
    } else {
      if family > 0 {
        let grade: Int32 = SDP_FamilyItemGrade(itemID);
        ready = data.SDP_FamilyMasteredGrade(family) < grade
          && data.SDP_FamilyXP(family, grade) >= SDP_FamilyThreshold(family, grade);
      };
    };
  };
  if ready && !IsDefined(this.m_sdpReadyDot) {
    let parent: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
    if IsDefined(parent) {
      this.m_sdpReadyDot = new inkCircle();
      this.m_sdpReadyDot.SetSize(14.0, 14.0);
      this.m_sdpReadyDot.SetAnchor(inkEAnchor.TopRight);
      this.m_sdpReadyDot.SetMargin(0.0, 8.0, 8.0, 0.0);
      this.m_sdpReadyDot.SetTintColor(new HDRColor(0.14, 1.0, 0.32, 1.0));
      this.m_sdpReadyDot.SetInteractive(false);
      this.m_sdpReadyDot.Reparent(parent);
    };
  };
  if IsDefined(this.m_sdpReadyDot) { this.m_sdpReadyDot.SetVisible(ready); };
}

@wrapMethod(InventoryItemDisplayController)
protected func RefreshUI() -> Void {
  wrappedMethod();
  let owner: ref<GameObject>;
  if IsDefined(this.m_inventoryDataManager) { owner = this.m_inventoryDataManager.SDP_GetProgressOwner(); };
  this.SDP_UpdateShardReadyDot(ItemID.GetTDBID(InventoryItemData.GetID(this.m_itemData)), owner);
}

@wrapMethod(InventoryItemDisplayController)
protected func NewRefreshUI(itemData: ref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  if !IsDefined(itemData) {
    this.SDP_UpdateShardReadyDot(t"None");
    return;
  };
  let owner: ref<GameObject> = itemData.GetOwner();
  if !IsDefined(owner) && IsDefined(this.m_inventoryDataManager) {
    owner = this.m_inventoryDataManager.SDP_GetProgressOwner();
  };
  this.SDP_UpdateShardReadyDot(itemData.GetTweakDBID(), owner);
}
