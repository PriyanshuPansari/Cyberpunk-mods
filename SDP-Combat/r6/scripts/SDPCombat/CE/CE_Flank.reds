module SDPCE

// CE flanking (4.12.0) - proactive maneuver-layer consumer. (ﾉ>ω<)ﾉ

public class GBPFlank {
  
  public static func OnHit(npc: ref<NPCPuppet>) -> Bool {
    if !IsDefined(npc) { return false; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if !st.GBP_factionCached || st.GBP_shouldFlee { return false; };
    if !GBPManeuversOn(npc.GetGame()) { return false; };
    if st.GBP_isBoss { return false; };
    if st.GBP_flankOnCooldown { return false; };
    if st.GBP_orderPhase > 0 || st.GBP_coverEjectPending { return false; };  
    if GBPSuppression.IsPinned(npc) { return false; };                 
    if GBPSuppression.IsSuppressing(npc) { return false; };            
    if GBPCoverEject.CoverIsFailing(npc) { return false; };            
    
    if !Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat) { return false; };

    let profile: ref<GBPProfile> = GBPProfiles.GetProfile(st.GBP_factionIndex);
    if !IsDefined(profile) { return false; };
    if st.GBP_bossStyle == 2 { return false; };   
    let flankChance: Float = profile.GetFlankChance(st.GBP_rarityVal);
    if st.GBP_bossStyle == 1 { flankChance = flankChance * 1.5; };   
    if flankChance <= 0.0 { return false; };

    let gi: GameInstance = npc.GetGame();
    let player: ref<PlayerPuppet> = GetPlayer(gi);
    if !IsDefined(player) { return false; };
    
    if Vector4.Length(player.GetVelocity()) > 5.0 { return false; };

    if RandF() >= flankChance { return false; };   

    GBPEnsureState(npc).GBP_flankOnCooldown = true;
    GameInstance.GetDelaySystem(gi).DelayCallback(GBPFlankCooldownClear.Create(npc),
      RandRangeF(profile.GetFlankCooldownMin(), profile.GetFlankCooldownMax()), false);

    let believed: Vector4 = GBPManeuver.BelievedPlayerPos(npc, player);
    let spot: Vector4 = GBPFlank.ComputeFlankSpot(npc, believed);
    GBPSystem.Note(gi, 4);
    GBPManeuver.Reposition(npc, spot, n"Flank", 1.25);
    return true;
  }

  public static func ComputeFlankSpot(npc: ref<NPCPuppet>, believedPlayer: Vector4) -> Vector4 {
    let p: Vector4 = npc.GetWorldPosition();
    let dx: Float = p.X - believedPlayer.X;
    let dy: Float = p.Y - believedPlayer.Y;
    let d: Float = SqrtF(dx * dx + dy * dy);
    let ring: Float = ClampF(d, 6.0, 16.0);
    let ax: Float = 1.0;
    let ay: Float = 0.0;
    if d > 0.1 { ax = dx / d; ay = dy / d; };
    let side: Float = 1.0;
    if RandF() < 0.5 { side = -1.0; };
    
    let c: Float = 0.208;
    let s: Float = 0.978 * side;
    let rx: Float = ax * c - ay * s;
    let ry: Float = ax * s + ay * c;
    return GBPV4(believedPlayer.X + rx * ring, believedPlayer.Y + ry * ring, p.Z, 1.0);
  }
}

public class GBPFlankPingClear extends DelayCallback {
  private let m_sys: wref<GBPSystem>;
  public static func Create(sys: ref<GBPSystem>) -> ref<GBPFlankPingClear> {
    let c: ref<GBPFlankPingClear> = new GBPFlankPingClear();
    c.m_sys = sys;
    return c;
  }
  public func Call() -> Void {
    if IsDefined(this.m_sys) { this.m_sys.ClearFlankPingCooldown(); };
  }
}

public class GBPFlankCooldownClear extends DelayCallback {
  private let m_npc: wref<NPCPuppet>;
  private let m_resetGen: Int32;
  public static func Create(npc: ref<NPCPuppet>) -> ref<GBPFlankCooldownClear> {
    let c: ref<GBPFlankCooldownClear> = new GBPFlankCooldownClear();
    c.m_npc = npc;
    c.m_resetGen = GBPStateOf(npc).GBP_resetGen;
    return c;
  }
  public func Call() -> Void {
    let npc: ref<NPCPuppet> = this.m_npc;
    if !IsDefined(npc) { return; };
    if GBPStateOf(npc).GBP_resetGen != this.m_resetGen { return; };   
    GBPEnsureState(npc).GBP_flankOnCooldown = false;
  }
}
