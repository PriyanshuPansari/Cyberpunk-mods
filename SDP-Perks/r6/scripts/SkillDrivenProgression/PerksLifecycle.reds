module SkillDrivenProgression

// SDP Perks on the shared SDP Core loop: encounter tracking and shard channel timers twice a second.
public class SDPPerksTick extends SDPTickListener {
  public func Key() -> CName { return n"SDP.Perks"; }
  public func Tick(player: ref<PlayerPuppet>, seconds: Float) -> Void {
    let development: ref<PlayerDevelopmentSystem> = PlayerDevelopmentSystem.GetInstance(player);
    if !IsDefined(development) { return; };
    let data: ref<PlayerDevelopmentData> = development.GetDevelopmentData(player);
    if !IsDefined(data) { return; };
    data.SDP_EncounterTick(player.IsInCombat());
    data.SDP_ChannelTick(seconds);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  this.SDP_RegisterTick(new SDPPerksTick());
  return result;
}

// Skill XP for the encounter log.
@wrapMethod(PlayerDevelopmentData)
public final const func AddExperience(amount: Int32, type: gamedataProficiencyType, telemetryGainReason: telemetryLevelGainReason, opt isDebug: Bool) -> Void {
  wrappedMethod(amount, type, telemetryGainReason, isDebug);
  if !isDebug && IsDefined(this.m_owner) && this.m_owner.IsPlayerControlled() {
    this.SDP_EncounterAddSkill(type, amount);
  };
}
