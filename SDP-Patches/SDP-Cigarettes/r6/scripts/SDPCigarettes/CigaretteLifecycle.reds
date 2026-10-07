module SkillDrivenProgression

// Player attach/detach for the cigarette systems: starter supply, Composure
// steady hands on the SDP Core loop, and cleanup. Using cigarettes goes through Custom Quickslots
// (compat/CustomQuickslots) or the CET "Smoke cigarette" hotkey.

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  let development: ref<PlayerDevelopmentSystem> = PlayerDevelopmentSystem.GetInstance(this);
  if IsDefined(development) {
    let data: ref<PlayerDevelopmentData> = development.GetDevelopmentData(this);
    if IsDefined(data) { data.SDP_GrantStarterCigarettes(); };
  };
  this.SDP_RegisterTick(new SDPCigarettesTick());
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  this.SDP_ClearSteadyAim();
  return wrappedMethod();
}

// Custom Quickslots (and any other caller) consumes items through
// ItemActionsHelper.ConsumeItem. When Consumable Animations is installed, send
// this mod's cigarettes through SDP_UseCigarette so they get its animation.
@wrapMethod(ItemActionsHelper)
public final static func ConsumeItem(executor: wref<GameObject>, itemID: ItemID, fromInventory: Bool) -> Void {
  let player: ref<PlayerPuppet> = executor as PlayerPuppet;
  if IsDefined(player) && SDP_ConsumableAnimationsInstalled()
    && SDP_IsOwnCigarette(ItemID.GetTDBID(itemID)) {
    let development: ref<PlayerDevelopmentSystem> = PlayerDevelopmentSystem.GetInstance(player);
    let data: ref<PlayerDevelopmentData> = IsDefined(development) ? development.GetDevelopmentData(player) : null;
    if IsDefined(data) {
      data.SDP_UseCigarette();
      return;
    };
  };
  wrappedMethod(executor, itemID, fromInventory);
}
