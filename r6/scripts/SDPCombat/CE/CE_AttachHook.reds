module SDPCE
// SDPCombat cut-down of Combat Evolved 4.16.8: enrolment on spawn (corpse-guard calls removed).

@wrapMethod(NPCPuppet)
protected cb func OnGameAttached() -> Bool {
  let result = wrappedMethod();
  let gi: GameInstance = this.GetGame();
  let sys: ref<GBPSystem> = GBPSystem.Get(gi);
  if !IsDefined(sys) {
    if this.IsDeadNoStatPool() { GBPLog(s"[GBP][CORPSE] attach bail: no system \(GBPNpcTag(this))"); }
    return result;
  }
  sys.NoteAttachSeen();
  
  let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(gi);
  if !IsDefined(delaySystem) {
    if this.IsDeadNoStatPool() { GBPLog(s"[GBP][CORPSE] attach bail: no delay system \(GBPNpcTag(this))"); }
    return result;
  }
  
  let cb: ref<GBPEnrollRetry> = GBPEnrollRetry.Create(this, 0);
  cb.SetCrowdAtAttach(this.m_isCrowd);
  
  delaySystem.DelayCallback(cb, sys.NextEnrollDelay(), false);
  return result;
}

public class GBPEnrollRetry extends DelayCallback {
  private let m_npc: wref<NPCPuppet>;
  private let m_attempt: Int32;
  private let m_crowdAtAttach: Bool;
  public static func Create(npc: ref<NPCPuppet>, attempt: Int32) -> ref<GBPEnrollRetry> {
    let c: ref<GBPEnrollRetry> = new GBPEnrollRetry();
    c.m_npc = npc;
    c.m_attempt = attempt;
    return c;
  }
  public func SetCrowdAtAttach(v: Bool) -> Void { this.m_crowdAtAttach = v; }

  public static func LogScope(npc: ref<NPCPuppet>, gi: GameInstance, sys: ref<GBPSystem>, crowdAtAttach: Bool) -> Void {
    let cfg: ref<GBPConfig> = GBPConfig.Get(gi);
    if !IsDefined(cfg) || !cfg.debugON { return; }
    let armed: Bool = false;
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
    if IsDefined(ts) {
      armed = IsDefined(ts.GetItemInSlot(npc, t"AttachmentSlots.WeaponRight") as WeaponObject);
    }
    let att: String = "n/a";
    let player: ref<GameObject> = GetPlayer(gi);
    if IsDefined(player) { att = ToString(GameObject.GetAttitudeBetween(npc, player)); }
    let attGrp: String = "none";
    let agent: ref<AttitudeAgent> = npc.GetAttitudeAgent();
    if IsDefined(agent) { attGrp = NameToString(agent.GetAttitudeGroup()); }
    GBPLog(s"[GBP][SCOPE] \(GBPNpcTag(npc)) crowd=\(npc.m_isCrowd)/\(crowdAtAttach) civ=\(npc.IsCivilian()) faction=\(sys.ResolveFaction(npc)) armed=\(armed) att=\(att) attGrp=\(attGrp) rarity=\(ToString(npc.GetNPCRarity()))");
  }

  private func Reschedule(npc: ref<NPCPuppet>, gi: GameInstance, attempt: Int32) -> Void {
    let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(gi);
    if !IsDefined(delaySystem) { return; }
    delaySystem.DelayCallback(GBPEnrollRetry.Create(npc, attempt), 0.8, false);
  }

  public func Call() -> Void {
    let npc: ref<NPCPuppet> = this.m_npc;
    if !IsDefined(npc) { return; }
    let gi: GameInstance = npc.GetGame();
    let sys: ref<GBPSystem> = GBPSystem.Get(gi);
    if !IsDefined(sys) { return; }

    if this.m_attempt == 0 {
      
      if npc.IsDeadNoStatPool() { return; }
      
      GBPEnrollRetry.LogScope(npc, gi, sys, this.m_crowdAtAttach);
      
      sys.EnrollPuppet(npc);
      
      if !GBPStateOf(npc).GBP_factionCached && !GBPIsCorpse(npc) {
        let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(gi);
        if IsDefined(delaySystem) {
          delaySystem.DelayCallback(GBPEnrollRetry.Create(npc, 1), 0.6, false);
        }
      }
      return;
    }

    if GBPIsCorpse(npc) { return; }
    if GBPStateOf(npc).GBP_factionCached { return; }   
    
    if sys.ResolveFaction(npc) < 0 {
      if this.m_attempt < 3 {
        this.Reschedule(npc, gi, this.m_attempt + 1);
      } else {
        sys.NoteCivilian();   
      }
      return;
    }
    sys.EnrollPuppet(npc);   
    
    if !GBPStateOf(npc).GBP_factionCached && this.m_attempt < 3 {
      this.Reschedule(npc, gi, this.m_attempt + 1);
    }
  }
}

@wrapMethod(NPCPuppet)
protected cb func OnDetach() -> Bool {
  if IsDefined(this.sdpceState) && this.sdpceState.GBP_factionCached {
    let sys: ref<GBPSystem> = GBPSystem.Get(this.GetGame());
    if IsDefined(sys) { sys.RememberFight(this); }
  }
  return wrappedMethod();
}
