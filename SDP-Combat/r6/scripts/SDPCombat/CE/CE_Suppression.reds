module SDPCE

// CE suppression pressure (4.12.0) - fire that MISSES matters. (ﾉ>_<)ﾉ

@wrapMethod(ReactionManagerComponent)
protected func HandleStimEventByTask(stimEvent: ref<StimuliEvent>, opt delayed: Bool) -> Void {
  GBPSuppression.OnStim(this.GetOwnerPuppet(), stimEvent);
  wrappedMethod(stimEvent, delayed);
}

public class GBPSuppression {

  public static func IsPinned(npc: ref<ScriptedPuppet>) -> Bool {
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if st.GBP_pinnedUntil <= 0.0 { return false; };
    let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(npc.GetGame()));
    return st.GBP_pinnedUntil > now;
  }

  public static func IsSuppressing(npc: ref<ScriptedPuppet>) -> Bool {
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if st.GBP_suppressUntil <= 0.0 { return false; };
    let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(npc.GetGame()));
    return st.GBP_suppressUntil > now;
  }

  public static func OnStim(owner: ref<ScriptedPuppet>, stimEvent: ref<StimuliEvent>) -> Void {
    if !IsDefined(owner) || !IsDefined(stimEvent) { return; };
    let stimType: gamedataStimType = stimEvent.GetStimType();
    if !Equals(stimType, gamedataStimType.Gunshot) && !Equals(stimType, gamedataStimType.SilencedGunshot) { return; };
    if !IsDefined(stimEvent.sourceObject) || !stimEvent.sourceObject.IsPlayer() { return; };
    let npc: ref<NPCPuppet> = owner as NPCPuppet;
    if GBPIsCorpse(npc) { return; };
    let st: ref<GBPNpcState> = GBPStateOf(npc);
    if !st.GBP_factionCached || st.GBP_isBoss || st.GBP_shouldFlee { return; };
    if st.GBP_bossStyle == 3 { return; };   
    if !GBPManeuversOn(npc.GetGame()) { return; };   

    let shooter: ref<GameObject> = stimEvent.sourceObject;
    let gi: GameInstance = npc.GetGame();
    let o: Vector4 = shooter.GetWorldPosition();
    let f: Vector4 = GameInstance.GetCameraSystem(gi).GetActiveCameraForward();
    let p: Vector4 = npc.GetWorldPosition();
    let vx: Float = p.X - o.X;
    let vy: Float = p.Y - o.Y;
    let vz: Float = (p.Z + 1.2) - (o.Z + 1.5);
    let along: Float = vx * f.X + vy * f.Y + vz * f.Z;
    if along < 2.0 || along > 60.0 { return; };   
    let px: Float = vx - f.X * along;
    let py: Float = vy - f.Y * along;
    let pz: Float = vz - f.Z * along;
    let perp: Float = SqrtF(px * px + py * py + pz * pz);
    if perp > 3.0 { return; };

    let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
    
    if st.GBP_suppressStamp > 0.0 {
      let elapsed: Float = now - st.GBP_suppressStamp;
      if elapsed > 0.0 {
        GBPEnsureState(npc).GBP_suppressPressure = MaxF(0.0, st.GBP_suppressPressure - elapsed * 0.9);
      };
    };
    GBPEnsureState(npc).GBP_suppressStamp = now;
    
    let add: Float = 1.0 - (perp / 3.0) * 0.75;
    GBPEnsureState(npc).GBP_suppressPressure = st.GBP_suppressPressure + add;

    if now < st.GBP_pinReadyAt { return; };
    let profile: ref<GBPProfile> = GBPProfiles.GetProfile(st.GBP_factionIndex);
    if !IsDefined(profile) { return; };
    
    let threshold: Float = profile.GetPinThreshold() + MaxF(0.0, Cast<Float>(st.GBP_rarityVal - 2)) * 0.5;
    if st.GBP_suppressPressure < threshold { return; };

    GBPEnsureState(npc).GBP_pinnedUntil = now + profile.GetPinDuration();
    GBPSystem.Note(gi, 7);
    GBPEnsureState(npc).GBP_pinReadyAt = now + profile.GetPinCooldown();
    GBPEnsureState(npc).GBP_suppressPressure = 0.0;
    GBPEnsureState(npc).GBP_suppressUntil = 0.0;   
    GBPEnsureState(npc).GBP_moraleWound = MinF(st.GBP_moraleWound + profile.GetPinMoraleDrip(), 1.0);
  }
}
