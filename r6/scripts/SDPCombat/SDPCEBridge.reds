// SDPCombat <-> cut-down Combat Evolved (CE/ folder, module SDPCE).
// CE makes pinned, suppressing, panicking, repositioning and crippled NPCs shoot worse by changing the vanilla
// Accuracy stat, which the SDPCombat hit model does not read. Here those states widen the shooter's spread instead.
// CE's numbers are hit-chance multipliers (pinned 0.66, suppressing 0.68, panicking 0.72, repositioning 0.86,
// anchored in cover 1.06, crippled arm 0.5). Hit chance on a small target scales with 1/sigma^2, so sigma is
// divided by sqrt(multiplier): the same hit-chance change CE intended, applied through the physical model.
module SDPCombat
import SDPCE.*

public abstract class SDPCEBridge {
  // state index: 0 neutral, 1 anchored, 2 repositioning, 3 suppressing, 4 pinned, 5 panicking
  public static func State(npc: ref<NPCPuppet>) -> Int32 {
    let st = GBPStateOf(npc);
    if !st.GBP_factionCached { return 0; };
    if st.GBP_shouldFlee { return 5; };
    if GBPSuppression.IsPinned(npc) { return 4; };
    if GBPSuppression.IsSuppressing(npc) { return 3; };
    if st.GBP_orderPhase > 0 { return 2; };
    if NotEquals(AICoverHelper.GetCurrentCoverId(npc), Cast<Uint64>(0)) { return 1; };
    return 0;
  }

  public static func ArmCrippled(npc: ref<NPCPuppet>) -> Bool {
    let st = GBPStateOf(npc);
    return st.GBP_leftArmCrippled || st.GBP_rightArmCrippled;
  }

  public static func SpreadMult(npc: ref<NPCPuppet>) -> Float {
    let m = 1.0;
    let q = GBPIntent.ShotQualityMult(npc);
    if q > 0.05 { m = 1.0 / SqrtF(q); };
    if SDPCEBridge.ArmCrippled(npc) { m *= 1.41421; };
    return m;
  }

  public static func StateName(i: Int32) -> String {
    switch i {
      case 1: return "anchored in cover";
      case 2: return "repositioning";
      case 3: return "suppressing";
      case 4: return "pinned";
      case 5: return "panicking";
    };
    return "neutral";
  }

  // CE's own event counters since the last reset
  public static func EventLine(game: GameInstance) -> String {
    let sys = GBPSystem.Get(game);
    if !IsDefined(sys) { return "Combat Evolved (cut-down): not running"; };
    return s"Combat Evolved (cut-down): enrolled \(sys.GetEnrolledCount()) NPCs; \(sys.EventSummary())";
  }

  public static func ResetEvents(game: GameInstance) -> Void {
    let sys = GBPSystem.Get(game);
    if IsDefined(sys) { sys.ResetEvents(); };
  }
}
