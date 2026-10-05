module SDPCE

public class GBPIntent {

  public static func ShotQualityMult(npc: ref<ScriptedPuppet>) -> Float {
    if !IsDefined(npc) { return 1.0; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if !st.GBP_factionCached { return 1.0; };                          
    if !GBPManeuversOn(npc.GetGame()) { return 1.0; };                 
    let panicM: Float = 0.72;    
    let repoM: Float = 0.86;
    let anchorM: Float = 1.06;
    let profile: ref<GBPProfile> = GBPProfiles.GetProfile(st.GBP_factionIndex);
    if IsDefined(profile) {
      panicM = profile.GetIntentPanicMult();
      repoM = profile.GetIntentRepositionMult();
      anchorM = profile.GetIntentAnchorMult();
    };
    if st.GBP_shouldFlee { return panicM; };                          
    if GBPSuppression.IsPinned(npc) {                                 
      if IsDefined(profile) { return profile.GetIntentPinnedMult(); };
      return 0.66;
    };
    if GBPSuppression.IsSuppressing(npc) {                            
      if IsDefined(profile) { return profile.GetIntentSuppressMult(); };
      return 0.68;
    };
    if st.GBP_orderPhase > 0 { return repoM; };                       
    if NotEquals(AICoverHelper.GetCurrentCoverId(npc), Cast<Uint64>(0)) {
      if st.GBP_bossStyle == 2 { return anchorM + 0.05; };            
      return anchorM;                                                  
    };
    return 1.0;                                                        
  }

  public static func IntentName(npc: ref<ScriptedPuppet>) -> String {
    if !IsDefined(npc) { return "n/a"; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if !st.GBP_factionCached { return "n/a"; };
    let m: String = FloatToStringPrec(GBPIntent.ShotQualityMult(npc), 2);
    if st.GBP_shouldFlee { return s"panicking (\(m)x)"; };
    if GBPSuppression.IsPinned(npc) { return s"pinned (\(m)x)"; };
    if GBPSuppression.IsSuppressing(npc) { return s"suppressing (\(m)x)"; };
    if st.GBP_orderPhase > 0 { return s"repositioning (\(m)x)"; };
    if NotEquals(AICoverHelper.GetCurrentCoverId(npc), Cast<Uint64>(0)) { return s"anchored (\(m)x)"; };
    return s"neutral (\(m)x)";
  }
}
