module SDPCE

// CE native-first maneuver layer (4.12.0). (ノ ゜Д゜)ノ ︵

public class GBPManeuver {
  
  public static func BelievedPlayerPos(npc: ref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Vector4 {
    if IsDefined(player) { return player.GetWorldPosition(); }
    return GBPV4(0.0, 0.0, 0.0, 1.0);
  }

  public static func Reposition(npc: ref<ScriptedPuppet>, targetPos: Vector4, ownerTag: CName, nativeWindow: Float) -> Void {
    if GBPIsCorpse(npc) { return; };
    
    if !GBPMayCommand(npc) { return; };
    let st: ref<GBPNpcState> = GBPEnsureState(npc);
    st.GBP_orderGen += 1;
    st.GBP_orderOwner = ownerTag;
    st.GBP_orderPhase = 1;
    st.GBP_orderTarget = targetPos;
    st.GBP_orderBaseline = npc.GetWorldPosition();
    st.GBP_orderCoverId = AICoverHelper.GetCurrentCoverId(npc);
    st.GBP_orderReacquired = false;
    
    ScriptedPuppet.SendActionSignal(npc, n"GracefulCombatInterruption", nativeWindow);
    GameInstance.GetDelaySystem(npc.GetGame())
      .DelayCallback(GBPManeuverReceipt.Create(npc, st.GBP_orderGen), nativeWindow, false);
  }

  public static func Complied(npc: ref<ScriptedPuppet>, st: ref<GBPNpcState>) -> Bool {
    if Vector4.Distance(npc.GetWorldPosition(), st.GBP_orderBaseline) >= 2.0 { return true; };
    if NotEquals(AICoverHelper.GetCurrentCoverId(npc), st.GBP_orderCoverId) { return true; };
    return false;
  }

  public static func IssueMove(npc: ref<ScriptedPuppet>, targetPos: Vector4, distTol: Float) -> Void {
    let ai: ref<AIHumanComponent> = npc.GetAIControllerComponent();
    if !IsDefined(ai) { return; };
    let cmd: ref<AIMoveToCommand> = new AIMoveToCommand();
    let spec: AIPositionSpec;
    let wp: WorldPosition;
    WorldPosition.SetVector4(wp, targetPos);
    AIPositionSpec.SetWorldPosition(spec, wp);
    cmd.movementTarget = spec;
    cmd.movementType = moveMovementType.Run;
    cmd.desiredDistanceFromTarget = distTol;
    cmd.finishWhenDestinationReached = true;
    cmd.ignoreInCombat = true;
    cmd.ignoreNavigation = false;
    cmd.alwaysUseStealth = false;
    ai.SendCommand(cmd);
    GBPEnsureState(npc).GBP_orderCmd = cmd;   
  }

  public static func CancelMove(npc: ref<ScriptedPuppet>, st: ref<GBPNpcState>) -> Void {
    if !IsDefined(st.GBP_orderCmd) { return; };
    let ai: ref<AIHumanComponent> = npc.GetAIControllerComponent();
    if IsDefined(ai) { ai.StopExecutingCommand(st.GBP_orderCmd, true); };
    st.GBP_orderCmd = null;
  }

  public static func Clear(st: ref<GBPNpcState>) -> Void {
    st.GBP_orderPhase = 0;
    st.GBP_orderReacquired = false;
    st.GBP_orderCmd = null;   
  }
}

public class GBPManeuverReceipt extends DelayCallback {
  private let m_npc: wref<ScriptedPuppet>;
  private let m_gen: Int32;
  public static func Create(npc: ref<ScriptedPuppet>, gen: Int32) -> ref<GBPManeuverReceipt> {
    let c: ref<GBPManeuverReceipt> = new GBPManeuverReceipt();
    c.m_npc = npc;
    c.m_gen = gen;
    return c;
  }
  public func Call() -> Void {
    let npc: ref<ScriptedPuppet> = this.m_npc;
    if !IsDefined(npc) { return; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if st.GBP_orderGen != this.m_gen || st.GBP_orderPhase != 1 { return; };   
    if GBPIsCorpse(npc) || st.GBP_shouldFlee { GBPManeuver.CancelMove(npc, st); GBPManeuver.Clear(st); return; };  
    if GBPManeuver.Complied(npc, st) {
      GBPManeuver.Clear(st);   
      return;
    };
    st.GBP_orderPhase = 2;
    st.GBP_orderBaseline = npc.GetWorldPosition();
    GBPManeuver.IssueMove(npc, st.GBP_orderTarget, 1.0);
    GameInstance.GetDelaySystem(npc.GetGame())
      .DelayCallback(GBPManeuverWatchdog.Create(npc, this.m_gen), 2.5, false);
  }
}

public class GBPManeuverWatchdog extends DelayCallback {
  private let m_npc: wref<ScriptedPuppet>;
  private let m_gen: Int32;
  public static func Create(npc: ref<ScriptedPuppet>, gen: Int32) -> ref<GBPManeuverWatchdog> {
    let c: ref<GBPManeuverWatchdog> = new GBPManeuverWatchdog();
    c.m_npc = npc;
    c.m_gen = gen;
    return c;
  }
  public func Call() -> Void {
    let npc: ref<ScriptedPuppet> = this.m_npc;
    if !IsDefined(npc) { return; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if st.GBP_orderGen != this.m_gen || st.GBP_orderPhase != 2 { return; };
    if GBPIsCorpse(npc) || st.GBP_shouldFlee { GBPManeuver.CancelMove(npc, st); GBPManeuver.Clear(st); return; };  
    if Vector4.Distance(npc.GetWorldPosition(), st.GBP_orderBaseline) >= 2.0 {
      GBPManeuver.Clear(st);   
      return;
    };
    if !st.GBP_orderReacquired {
      st.GBP_orderReacquired = true;
      st.GBP_orderBaseline = npc.GetWorldPosition();
      GBPManeuver.IssueMove(npc, st.GBP_orderTarget, 1.0);
      GameInstance.GetDelaySystem(npc.GetGame())
        .DelayCallback(GBPManeuverWatchdog.Create(npc, this.m_gen), 2.5, false);
    } else {
      GBPManeuver.Clear(st);   
    };
  }
}
