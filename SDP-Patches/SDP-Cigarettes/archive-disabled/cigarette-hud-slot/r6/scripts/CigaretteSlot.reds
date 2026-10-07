module SkillDrivenProgression

// Dedicated cigarette quickslot on the HUD, next to the vanilla D-pad slots.
// It reuses the game's DPAD_UP slot widget for its look, but shows this mod's
// cigarettes and ignores the health-item hotkey, charges, and D-pad up events.

public class SDPCigaretteSlotEvent extends Event {
  // 0 = refresh, 1 = used, 2 = use failed
  public let kind: Int32;
}

public func SDP_CigaretteSlotNotify(player: wref<PlayerPuppet>, kind: Int32) -> Void {
  if !IsDefined(player) { return; };
  let evt: ref<SDPCigaretteSlotEvent> = new SDPCigaretteSlotEvent();
  evt.kind = kind;
  player.QueueEvent(evt);
}

@addField(GenericHotkeyController)
public let m_sdpCigaretteSlot: Bool;

@wrapMethod(HotkeysWidgetController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  let panel: wref<inkCompoundWidget> = inkWidgetRef.Get(this.m_dpadHintsPanel) as inkCompoundWidget;
  if IsDefined(panel) && !IsDefined(panel.GetWidget(n"sdpCigaretteSlot")) {
    let slot: wref<inkWidget> = this.SpawnFromLocal(panel, n"DPAD_UP");
    if IsDefined(slot) {
      slot.SetName(n"sdpCigaretteSlot");
    };
  };
  this.SDP_WidenHud();
  return result;
}

// With Codeware, widen the HUD entry so the extra slot is not clipped.
@if(ModuleExists("Codeware"))
@addMethod(HotkeysWidgetController)
private func SDP_WidenHud() -> Void {
  let info: ref<inkHudEntryInfo> = this.GetRootWidget().GetUserData(n"inkHudEntryInfo") as inkHudEntryInfo;
  if IsDefined(info) && info.size.X < 3500.00 {
    info.size = new Vector2(3500.00, MaxF(info.size.Y, 300.00));
  };
}

@if(!ModuleExists("Codeware"))
@addMethod(HotkeysWidgetController)
private func SDP_WidenHud() -> Void {}

@addMethod(GenericHotkeyController)
protected final func SDP_CigaretteDetect() -> Void {
  if !this.m_sdpCigaretteSlot && Equals(this.GetRootWidget().GetName(), n"sdpCigaretteSlot") {
    this.m_sdpCigaretteSlot = true;
  };
}

@addMethod(GenericHotkeyController)
protected final func SDP_CigaretteApplyHint() -> Void {
  let player: wref<PlayerPuppet> = this.GetPlayer();
  if !IsDefined(player) || !IsDefined(this.m_buttonHintController) { return; };
  if player.PlayerLastUsedKBM() {
    // Keyboard use is the CET "Smoke cigarette" hotkey, which the HUD cannot show.
    inkWidgetRef.SetVisible(this.m_buttonHint, false);
    return;
  };
  inkWidgetRef.SetVisible(this.m_buttonHint, true);
  if player.SDP_CigaretteSquareHeld() {
    this.m_buttonHintController.SetInputAction(n"dpad_left");
    this.m_buttonHintController.SetHoldIndicatorType(inkInputHintHoldIndicationType.Press);
  } else {
    this.m_buttonHintController.SetInputAction(n"SDP_CigaretteSquare");
    this.m_buttonHintController.SetHoldIndicatorType(inkInputHintHoldIndicationType.Hold);
  };
}

@addMethod(GenericHotkeyController)
protected final func SDP_CigaretteResolveState() -> Void {
  let player: wref<PlayerPuppet> = this.GetPlayer();
  let usable: Bool = IsDefined(player) && this.IsInDefaultState() && !player.IsInCombat()
    && SDP_CigaretteTotal(player) > 0;
  this.GetRootWidget().SetState(usable ? n"Default" : n"Unavailable");
}

@addMethod(HotkeyItemController)
protected final func SDP_CigaretteRefresh() -> Void {
  let player: wref<PlayerPuppet> = this.GetPlayer();
  if !IsDefined(player) || !IsDefined(this.m_hotkeyItemController) { return; };
  let data: InventoryItemData;
  let found: wref<gameItemData> = SDP_FindCigarette(player);
  if IsDefined(found) && IsDefined(this.m_inventoryManager) {
    data = this.m_inventoryManager.GetInventoryItemData(found);
    data.Quantity = SDP_CigaretteTotal(player);
  };
  this.m_currentItem = data;
  this.m_hotkeyItemController.Setup(this.m_currentItem, ItemDisplayContext.DPAD_RADIAL);
  this.GetRootWidget().SetVisible(!this.IsControllingDevice());
  this.ResolveState();
}

// Once-a-second resync, in case an inventory or combat change was missed.
public class SDPCigaretteSlotTick extends DelayCallback {
  public let m_slot: wref<HotkeyItemController>;

  public func Call() -> Void {
    if IsDefined(this.m_slot) { this.m_slot.SDP_CigaretteTick(); };
  }
}

@addField(HotkeyItemController)
private let m_sdpTickStarted: Bool;

@addMethod(HotkeyItemController)
public final func SDP_CigaretteTick() -> Void {
  let player: wref<PlayerPuppet> = this.GetPlayer();
  if !IsDefined(player) { this.m_sdpTickStarted = false; return; };
  this.SDP_CigaretteRefresh();
  let tick: ref<SDPCigaretteSlotTick> = new SDPCigaretteSlotTick();
  tick.m_slot = this;
  GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(tick, 1.00, false);
}

@addMethod(HotkeyItemController)
private final func SDP_CigaretteStartTick() -> Void {
  if this.m_sdpTickStarted { return; };
  this.m_sdpTickStarted = true;
  this.SDP_CigaretteTick();
}

@wrapMethod(HotkeyItemController)
protected func Initialize() -> Bool {
  this.SDP_CigaretteDetect();
  return wrappedMethod();
}

@wrapMethod(HotkeyItemController)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
  this.SDP_CigaretteDetect();
  let result: Bool = wrappedMethod(playerPuppet);
  if this.m_sdpCigaretteSlot {
    this.SDP_CigaretteApplyHint();
    this.SDP_CigaretteStartTick();
  };
  return result;
}

@wrapMethod(GenericHotkeyController)
private final func InitializeButtonHint() -> Void {
  if this.m_sdpCigaretteSlot {
    this.SDP_CigaretteApplyHint();
    return;
  };
  wrappedMethod();
}

@wrapMethod(GenericHotkeyController)
protected func ResolveState() -> Void {
  if this.m_sdpCigaretteSlot {
    this.SDP_CigaretteResolveState();
    return;
  };
  wrappedMethod();
}

@wrapMethod(ChargedHotkeyItemBaseController)
protected func ResolveState() -> Void {
  if this.m_sdpCigaretteSlot {
    this.SDP_CigaretteResolveState();
    return;
  };
  wrappedMethod();
}

// The slot borrows the healing-item widget; keep its charge bar hidden.
@wrapMethod(ChargedHotkeyItemBaseController)
protected func SetRechargeProgress(progress: Float, valueChanged: Bool) -> Void {
  if this.m_sdpCigaretteSlot {
    inkWidgetRef.SetVisible(this.m_chargebarOpacityWidget, false);
    inkWidgetRef.SetVisible(this.m_chargebarSizeWidget, false);
    return;
  };
  wrappedMethod(progress, valueChanged);
}

@wrapMethod(HotkeyItemController)
protected func UpdateCurrentItem() -> Void {
  if this.m_sdpCigaretteSlot {
    this.SDP_CigaretteRefresh();
    return;
  };
  wrappedMethod();
}

@wrapMethod(ChargedHotkeyItemConsumableController)
protected func UpdateCurrentItem() -> Void {
  if this.m_sdpCigaretteSlot {
    this.SDP_CigaretteRefresh();
    return;
  };
  wrappedMethod();
}

@wrapMethod(HotkeyItemController)
protected cb func OnHotkeyRefreshed(value: Variant) -> Bool {
  if this.m_sdpCigaretteSlot { return false; };
  return wrappedMethod(value);
}

@wrapMethod(GenericHotkeyController)
protected cb func OnDpadActionPerformed(evt: ref<DPADActionPerformed>) -> Bool {
  if this.m_sdpCigaretteSlot { return false; };
  return wrappedMethod(evt);
}

@wrapMethod(HotkeyItemController)
protected cb func OnDpadActionPerformed(evt: ref<DPADActionPerformed>) -> Bool {
  if this.m_sdpCigaretteSlot { return false; };
  return wrappedMethod(evt);
}

@addMethod(HotkeyItemController)
protected cb func OnSDPCigaretteSlotEvent(evt: ref<SDPCigaretteSlotEvent>) -> Bool {
  if !this.m_sdpCigaretteSlot { return false; };
  if evt.kind == 1 {
    this.StopDpadAnim();
    this.m_dpadAnim = this.PlayLibraryAnimation(n"onUse_DPAD_UP");
  } else {
    if evt.kind == 2 {
      this.StopDpadAnim();
      this.m_dpadAnim = this.PlayLibraryAnimation(n"onFailUse_DPAD_UP");
    };
  };
  this.SDP_CigaretteRefresh();
  this.SDP_CigaretteApplyHint();
  return false;
}
