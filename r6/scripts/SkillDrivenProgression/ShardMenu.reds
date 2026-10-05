// R3 opens the game's cyberware modification inventory for our processor.
// The native menu supplies the attachment grid and item selection controls.
module SkillDrivenProgression

@addMethod(RipperDocGameController)
private final func SDP_OpenSelectedProcessorShards() -> Bool {
  let grid: wref<CyberwareInventoryMiniGrid> = this.m_previewMinigrid;
  let eyesActive: Bool = Equals(this.m_hoverArea, gamedataEquipmentArea.EyesCW)
    || Equals(this.m_filterArea, gamedataEquipmentArea.EyesCW);
  if !IsDefined(grid) || NotEquals(grid.GetEquipmentArea(), gamedataEquipmentArea.EyesCW)
    || grid.GetSelectedSlotIndex() < 0 {
    if !eyesActive {
      return false;
    };
    grid = this.GetMinigrid(gamedataEquipmentArea.EyesCW);
  };
  if !IsDefined(grid) { return false; };

  let displays: array<wref<InventoryItemDisplayController>> = grid.GetInventoryItemDisplays();
  let index: Int32 = grid.GetSelectedSlotIndex();
  if index >= 0 && index < ArraySize(displays) {
    return this.SDP_OpenProcessorShards(displays[index]);
  };

  // Inventory mode can highlight an equipment area without selecting its tile.
  if eyesActive {
    index = 0;
    while index < ArraySize(displays) {
      if this.SDP_OpenProcessorShards(displays[index]) { return true; };
      index += 1;
    };
  };
  return false;
}

@addMethod(RipperDocGameController)
private final func SDP_OpenProcessorShards(selected: wref<InventoryItemDisplayController>) -> Bool {
  if !IsDefined(selected) || selected.IsLocked() { return false; };
  let item: wref<UIInventoryItem> = selected.GetUIInventoryItem();
  if !IsDefined(item)
    || NotEquals(item.GetTweakDBID(), t"SkillDrivenProgression.NeuralProcessor") {
    return false;
  };
  let request: ref<CyberwareTabModsRequest> = new CyberwareTabModsRequest();
  request.open = true;
  request.wrapper = new CyberwareDisplayWrapper();
  request.wrapper.displayData = selected.GetItemDisplayData();
  this.m_uiSystem.QueueEvent(request);
  return true;
}

@wrapMethod(RipperDocGameController)
protected cb func OnReleaseInput(e: ref<inkPointerEvent>) -> Bool {
  if IsDefined(e) && e.IsAction(n"install_quickhack")
    && !e.IsHandled() && !e.IsConsumed()
    && this.SDP_OpenSelectedProcessorShards() {
    e.Handle();
    e.Consume();
    return true;
  };
  return wrappedMethod(e);
}

@wrapMethod(RipperDocGameController)
protected cb func OnPreviewCyberwareClick(evt: ref<inkPointerEvent>) -> Bool {
  if IsDefined(evt) && evt.IsAction(n"install_quickhack") {
    let selected: ref<InventoryItemDisplayController> = this.GetCyberwareSlotControllerFromTarget(evt);
    if this.SDP_OpenProcessorShards(selected) {
      evt.Handle();
      evt.Consume();
      return true;
    };
  };
  return wrappedMethod(evt);
}

@wrapMethod(gameuiInventoryGameController)
protected cb func OnEquipmentClick(evt: ref<ItemDisplayClickEvent>) -> Bool {
  if IsDefined(evt) && evt.actionName.IsAction(n"install_quickhack") {
    let selected: wref<InventoryItemDisplayController> = evt.display;
    if IsDefined(selected) && !selected.IsLocked() {
      let itemData: InventoryItemData = selected.GetItemData();
      if !InventoryItemData.IsEmpty(itemData)
        && Equals(ItemID.GetTDBID(InventoryItemData.GetID(itemData)), t"SkillDrivenProgression.NeuralProcessor") {
        this.OpenCyberwareModificationScreen(selected.GetItemDisplayData());
        return true;
      };
    };
  };
  return wrappedMethod(evt);
}

// Cyberware items normally hide attachment pips. The processor needs the same
// pip row that cyberdecks use so its three shard bays and Relic bay are visible.
@wrapMethod(InventoryItemDisplayController)
protected func NewUpdateMods(itemData: wref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  if !IsDefined(itemData)
    || NotEquals(itemData.GetTweakDBID(), t"SkillDrivenProgression.NeuralProcessor")
    || !IsDefined(inkWidgetRef.Get(this.m_commonModsRoot)) {
    return;
  };
  let mods: wref<UIInventoryItemModsManager> = itemData.GetModsManager();
  if !IsDefined(mods) { return; };
  let targetSize: Int32 = mods.GetAttachmentsSize();
  while ArraySize(this.m_attachmentsDisplay) > targetSize {
    inkCompoundRef.RemoveChild(this.m_commonModsRoot, ArrayPop(this.m_attachmentsDisplay).GetRootWidget());
  };
  let index: Int32 = 0;
  while index < targetSize {
    if ArraySize(this.m_attachmentsDisplay) <= index {
      let display: wref<InventoryItemModSlotDisplay> = this.SpawnFromLocal(
        inkWidgetRef.Get(this.m_commonModsRoot), n"itemModSlot"
      ).GetController() as InventoryItemModSlotDisplay;
      ArrayPush(this.m_attachmentsDisplay, display);
    };
    this.m_attachmentsDisplay[index].Setup(mods.GetAttachment(index));
    index += 1;
  };
}
