module SkillDrivenProgression

// SDP Core: the shared twice-a-second player loop and small helpers used by several SDP parts.
// Parts register a listener on player attach; the loop starts with the first registration and
// runs for the session. Listeners are keyed, so re-registering on reload replaces the old one.

public abstract class SDPTickListener {
  public func Key() -> CName { return n""; }
  public func Tick(player: ref<PlayerPuppet>, seconds: Float) -> Void {}
}

public class SDPCoreTick extends DelayCallback {
  public let m_player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if IsDefined(this.m_player) { this.m_player.SDP_CoreLoop(); };
  }
}

@addField(PlayerPuppet)
private let m_sdpTickListeners: array<ref<SDPTickListener>>;

@addField(PlayerPuppet)
private let m_sdpLoopRunning: Bool;

@addField(PlayerPuppet)
private let m_sdpLoopTicks: Int32;

@addMethod(PlayerPuppet)
public final func SDP_LoopTicks() -> Int32 { return this.m_sdpLoopTicks; }

@addMethod(PlayerPuppet)
public final func SDP_RegisterTick(listener: ref<SDPTickListener>) -> Void {
  if !IsDefined(listener) { return; };
  let i: Int32 = 0;
  while i < ArraySize(this.m_sdpTickListeners) {
    if Equals(this.m_sdpTickListeners[i].Key(), listener.Key()) {
      this.m_sdpTickListeners[i] = listener;
      return;
    };
    i += 1;
  };
  ArrayPush(this.m_sdpTickListeners, listener);
  if !this.m_sdpLoopRunning {
    this.m_sdpLoopRunning = true;
    this.SDP_CoreLoop();
  };
}

@addMethod(PlayerPuppet)
public final func SDP_CoreLoop() -> Void {
  this.m_sdpLoopTicks += 1;
  for listener in this.m_sdpTickListeners {
    listener.Tick(this, 0.50);
  };
  let tick: ref<SDPCoreTick> = new SDPCoreTick();
  tick.m_player = this;
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(tick, 0.50, false);
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  ArrayClear(this.m_sdpTickListeners);
  this.m_sdpLoopRunning = false;
  return wrappedMethod();
}

public func SDP_IsSkillProficiency(type: gamedataProficiencyType) -> Bool {
  return Equals(type, gamedataProficiencyType.StrengthSkill)
    || Equals(type, gamedataProficiencyType.ReflexesSkill)
    || Equals(type, gamedataProficiencyType.TechnicalAbilitySkill)
    || Equals(type, gamedataProficiencyType.IntelligenceSkill)
    || Equals(type, gamedataProficiencyType.CoolSkill);
}
