module SDPCE

// CE cover-ejection (4.12.0) - first consumer of the maneuver layer. ( ﾟ▽ﾟ)/

public class GBPCoverEject {

  public static func CoverIsFailing(npc: ref<NPCPuppet>) -> Bool {
    
    let coverId: Uint64 = AICoverHelper.GetCurrentCoverId(npc);
    if Equals(coverId, Cast<Uint64>(0)) { return false; };
    let hp: Float = AICoverHelper.GetCoverRemainingHealthPerc(npc, coverId);
    if hp < 0.0 { return false; };
    
    let threshold: Float = 0.38;
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if st.GBP_factionCached {
      let profile: ref<GBPProfile> = GBPProfiles.GetProfile(st.GBP_factionIndex);
      if IsDefined(profile) { threshold = profile.GetCoverEjectThreshold(st.GBP_rarityVal); };
    };
    
    if GBPStateOf(npc).GBP_bossStyle == 3 { return false; };
    if GBPStateOf(npc).GBP_bossStyle == 1 { threshold = MinF(threshold * 1.5, 0.9); };
    return threshold > 0.0 && hp < threshold;
  }

  public static func OnHit(npc: ref<NPCPuppet>) -> Void {
    if !IsDefined(npc) { return; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if !st.GBP_factionCached || st.GBP_shouldFlee { return; };
    if !GBPManeuversOn(npc.GetGame()) { return; };
    if st.GBP_isBoss { return; };
    if st.GBP_coverEjectPending { return; };                        
    if !GBPCoverEject.CoverIsFailing(npc) { return; };              

    if st.GBP_coverBreakReaction < 0.5 {
      let rMin: Float = 1.0;
      let rMax: Float = 10.0;
      let profile: ref<GBPProfile> = GBPProfiles.GetProfile(st.GBP_factionIndex);
      if IsDefined(profile) {
        rMin = profile.GetCoverReactionMin();
        rMax = profile.GetCoverReactionMax();
      };
      GBPEnsureState(npc).GBP_coverBreakReaction = RandRangeF(rMin, rMax);
    };
    GBPEnsureState(npc).GBP_coverEjectPending = true;
    GameInstance.GetDelaySystem(npc.GetGame())
      .DelayCallback(GBPCoverEjectDecision.Create(npc), st.GBP_coverBreakReaction, false);
  }

  public static func ComputeEjectSpot(npc: ref<NPCPuppet>, believedPlayer: Vector4) -> Vector4 {
    let p: Vector4 = npc.GetWorldPosition();
    let dx: Float = p.X - believedPlayer.X;
    let dy: Float = p.Y - believedPlayer.Y;
    
    let len: Float = SqrtF(dx * dx + dy * dy);
    let ax: Float = 1.0;
    let ay: Float = 0.0;
    if len > 0.1 {
      ax = dx / len;
      ay = dy / len;
    };
    let side: Float = 1.0;
    if RandF() < 0.5 { side = -1.0; };
    
    let latX: Float = -ay * side;
    let latY: Float = ax * side;
    let outDist: Float = 5.0;   
    let latDist: Float = 3.5;   
    return GBPV4(p.X + ax * outDist + latX * latDist, p.Y + ay * outDist + latY * latDist, p.Z, 1.0);
  }
}

public class GBPCoverEjectDecision extends DelayCallback {
  private let m_npc: wref<NPCPuppet>;
  private let m_resetGen: Int32;
  public static func Create(npc: ref<NPCPuppet>) -> ref<GBPCoverEjectDecision> {
    let c: ref<GBPCoverEjectDecision> = new GBPCoverEjectDecision();
    c.m_npc = npc;
    c.m_resetGen = GBPStateOf(npc).GBP_resetGen;
    return c;
  }
  public func Call() -> Void {
    let npc: ref<NPCPuppet> = this.m_npc;
    if !IsDefined(npc) { return; };
    if GBPStateOf(npc).GBP_resetGen != this.m_resetGen { return; };   
    GBPEnsureState(npc).GBP_coverEjectPending = false;   
    if GBPIsCorpse(npc) { return; };
    if !GBPManeuversOn(npc.GetGame()) { return; };       
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if st.GBP_shouldFlee { return; };                    
    if !GBPCoverEject.CoverIsFailing(npc) { return; };   
    let player: ref<PlayerPuppet> = GetPlayer(npc.GetGame());
    let believed: Vector4 = GBPManeuver.BelievedPlayerPos(npc, player);
    let target: Vector4 = GBPCoverEject.ComputeEjectSpot(npc, believed);
    GBPSystem.Note(npc.GetGame(), 5);
    GBPManeuver.Reposition(npc, target, n"CoverEject", 1.25);
  }
}
