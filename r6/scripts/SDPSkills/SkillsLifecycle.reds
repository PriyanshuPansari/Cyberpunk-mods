module SkillDrivenProgression

// SDP Skills on the shared SDP Core loop: skill milestones twice a second.
public class SDPSkillsTick extends SDPTickListener {
  public func Key() -> CName { return n"SDP.Skills"; }
  public func Tick(player: ref<PlayerPuppet>, seconds: Float) -> Void { player.SDP_MilestoneTick(); }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  this.SDP_RegisterTick(new SDPSkillsTick());
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  this.SDP_ClearMilestones();
  return wrappedMethod();
}

// A new game needs the tuning modifiers too (OnRestored covers loaded saves).
@wrapMethod(PlayerDevelopmentData)
public final func RefreshDevelopmentSystemOnNewGameStarted() -> Void {
  wrappedMethod();
  this.SDP_TuningRefreshPassives();
  this.SDP_TuningRefreshCapacity();
}
