// Credit a completed weapon reload after a recent aimed neutralization.
module SkillDrivenProgression

@wrapMethod(ReloadEvents)
protected final func OnUpdate(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  let finishedBefore: Bool = stateContext.GetBoolParameter(n"FinishedReload", true);
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  if finishedBefore || !stateContext.GetBoolParameter(n"FinishedReload", true) { return; };
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  let weapon: ref<WeaponObject> = scriptInterface.owner as WeaponObject;
  if !IsDefined(player) || !IsDefined(weapon) { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if IsDefined(data) { data.SDP_OrderOnReloadCompleted(weapon.GetItemID()); };
}
