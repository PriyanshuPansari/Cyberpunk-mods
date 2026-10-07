module SDPCE

// Combat Evolved - Flee Pipeline  ε=ε=ε=┌(;*´Д`)ノ

public static func GBPFleeTag(npc: wref<ScriptedPuppet>) -> String {
    if !IsDefined(npc) { return "<gone>"; };
    return TDBID.ToStringDEBUG(npc.GetRecordID()) + " " + EntityID.ToDebugString(npc.GetEntityID());
}

public static func GBPFleeDbg(npc: wref<ScriptedPuppet>, msg: String) -> Void {
    if !IsDefined(npc) { return; };
    let cfg = GBPConfig.Get(npc.GetGame());
    if IsDefined(cfg) && cfg.debugON { GBPLog("[GBP][FLEE] " + msg + " " + GBPFleeTag(npc)); };
}

public class GBPFleeWatch extends DelayCallback {
    private let puppet: wref<ScriptedPuppet>;
    private let m_resetGen: Int32;
    private let m_watchGen: Int32;
    private let lastPos: Vector4;
    private let nudges: Int32;
    private let looks: Int32;
    private let cowerLooks: Int32;

    public static func FirstLook() -> Float = 2.0;
    public static func Interval() -> Float = 3.0;
    
    public static func MaxCowerLooks() -> Int32 = 2;

    public func Call() {
        if !IsDefined(this.puppet) || GBPIsCorpse(this.puppet) { return; }
        let st = GBPStateOf(this.puppet);
        if st.GBP_resetGen != this.m_resetGen || !st.GBP_shouldFlee { return; }   
        if st.GBP_watchGen != this.m_watchGen { return; }   
        let gi = this.puppet.GetGame();
        let player = GetPlayer(gi);
        if !IsDefined(player) { return; }

        let hls: gamedataNPCHighLevelState = this.puppet.GetHighLevelStateFromBlackboard();
        let fleeing: Bool = false;
        let cowering: Bool = false;
        let reaction: String = "none";
        let rc = this.puppet.GetStimReactionComponent();
        if IsDefined(rc) {
            let active = rc.GetActiveReactionData();
            if IsDefined(active) {
                reaction = ToString(active.reactionBehaviorName);
                fleeing = Equals(active.reactionBehaviorName, gamedataOutput.Flee);
                cowering = Equals(active.reactionBehaviorName, gamedataOutput.Surrender);
            }
        }
        let moved: Float = Vector4.Distance(this.puppet.GetWorldPosition(), this.lastPos);
        
        let ok: Bool = Equals(hls, gamedataNPCHighLevelState.Fear) && (moved >= 1.0 || (fleeing && this.looks == 0));
        let verdict: String = "running";
        if st.GBP_cower {
            
            ok = Equals(hls, gamedataNPCHighLevelState.Fear) && cowering;
            verdict = "cowering";
        }

        let cowerLooks: Int32 = this.cowerLooks;
        if ok && st.GBP_cower {
            cowerLooks += 1;
            if cowerLooks >= GBPFleeWatch.MaxCowerLooks() {
                verdict = "cowered, rallying";
                GBPEndPanic(this.puppet, player);
            }
        }
        if !ok {
            if this.nudges < 1 {
                this.nudges += 1;
                verdict = "COWER requested";
                GBPEnsureState(this.puppet).GBP_cower = true;
                GBPSendFlee(this.puppet, player);
            } else {
                verdict = "GAVE UP - back to the fight";
                GBPEndPanic(this.puppet, player);
            }
        }

        GBPFleeDbg(this.puppet, "CHECK hls=" + ToString(hls) + " activeReaction=" + reaction
            + " moved=" + FloatToStringPrec(moved, 1) + "m workspot="
            + ToString(GameInstance.GetWorkspotSystem(gi).IsActorInWorkspot(this.puppet)) + " -> " + verdict);

        if GBPStateOf(this.puppet).GBP_shouldFlee {
            
            let next = GBPFleeWatch.Create(this.puppet);
            next.m_watchGen = this.m_watchGen;
            next.nudges = this.nudges;
            next.looks = this.looks + 1;
            next.cowerLooks = cowerLooks;
            GameInstance.GetDelaySystem(gi).DelayCallback(next, GBPFleeWatch.Interval(), false);
        }
    }

    public static func Create(target: wref<ScriptedPuppet>) -> ref<GBPFleeWatch> {
        let self = new GBPFleeWatch();
        self.puppet = target;
        self.m_resetGen = GBPStateOf(target).GBP_resetGen;
        self.m_watchGen = GBPStateOf(target).GBP_watchGen;
        self.lastPos = target.GetWorldPosition();
        return self;
    }
}

public static func GBPSendFlee(npc: wref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(npc) || !IsDefined(player) { return; };
    NPCPuppet.ChangeHighLevelState(npc, gamedataNPCHighLevelState.Fear);
    StimBroadcasterComponent.SendStimDirectly(player, gamedataStimType.Scream, npc);
}

public static func GBPBelievedPlayerPos(npc: wref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Vector4 {
    let none: Vector4 = GBPV4(0.0, 0.0, 0.0, 0.0);
    if !IsDefined(npc) || !IsDefined(player) { return none; }
    let tl: TrackedLocation;
    if TargetTrackingExtension.GetTrackedLocation(npc, player, tl) {
        if !Vector4.IsZero(tl.location.position) { return tl.location.position; }
        if !Vector4.IsZero(tl.lastKnown.position) { return tl.lastKnown.position; }
    }
    let senses = npc.GetSensesComponent();
    if IsDefined(senses) && senses.IsAgentVisible(player) { return player.GetWorldPosition(); }
    return none;
}

public static func GBPRallyThreat(npc: wref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> String {
    if !IsDefined(npc) || !IsDefined(player) { return "no target"; }
    let senses = npc.GetSensesComponent();
    if IsDefined(senses) && senses.IsAgentVisible(player) {
        AIActionHelper.TryStartCombatWithTarget(npc, player);
        return "V in view";
    }
    if TargetTrackingExtension.IsThreatInThreatList(npc, player, false, true) { return "own belief kept"; }
    let pos: Vector4 = GBPStateOf(npc).GBP_fleeSeenPos;
    if Vector4.IsZero(pos) { return "no memory of V"; }
    TargetTrackingExtension.InjectThreat(npc, pos, 20.0);
    return "searching the last spot";
}

public static func GBPEndPanic(npc: wref<ScriptedPuppet>, player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(npc) || GBPIsCorpse(npc) { return; };
    GBPEnsureState(npc).GBP_shouldFlee = false;
    GBPEnsureState(npc).GBP_cower = false;
    GBPSystem.Note(npc.GetGame(), 3);
    if !IsDefined(player) || player.IsDead() { return; };
    if !Equals(GameObject.GetAttitudeTowards(npc, player), EAIAttitude.AIA_Hostile) { return; };
    if Equals(npc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Fear) {
        
        let rc = npc.GetStimReactionComponent();
        if IsDefined(rc) {
            let bb = rc.GetPuppetReactionBlackboard();
            if IsDefined(bb) { bb.SetBool(GetAllBlackboardDefs().PuppetReaction.exitReactionFlag, true); }
        }
        
        GameInstance.GetDelaySystem(npc.GetGame()).DelayCallback(GBPReengage.Create(npc), 1.0, false);
        GBPFleeDbg(npc, "panic over while still in Fear -> exitReactionFlag, re-engage in 1 s");
    };
}

public class GBPReengage extends DelayCallback {
    private let puppet: wref<ScriptedPuppet>;
    private let tries: Int32;
    private let stuck: Int32;
    private let exits: Int32;
    
    private let guard: Int32;
    private let slips: Int32;
    private let farLooks: Int32;

    public static func GoneDistance() -> Float = 60.0;   
    public static func MaxTries() -> Int32 = 8;
    
    public static func GuardLooks() -> Int32 = 30;
    public static func MaxSlips() -> Int32 = 5;
    
    public static func CowerDistance() -> Float = 12.0;
    public static func MaxNerveGone() -> Int32 = 2;
    
    public static func FarLookInterval() -> Float = 3.0;
    public static func MaxFarLooks() -> Int32 = 40;

    public func Call() {
        if !IsDefined(this.puppet) || GBPIsCorpse(this.puppet) { return; }
        let gi = this.puppet.GetGame();
        let player = GetPlayer(gi);
        if !IsDefined(player) || player.IsDead() { return; }
        if !Equals(GameObject.GetAttitudeTowards(this.puppet, player), EAIAttitude.AIA_Hostile) { return; }
        if GBPStateOf(this.puppet).GBP_shouldFlee { return; }   

        let hls = this.puppet.GetHighLevelStateFromBlackboard();
        let dist: Float = Vector4.Distance(this.puppet.GetWorldPosition(), player.GetWorldPosition());
        if this.tries == 0 && dist > GBPReengage.GoneDistance() {
            if this.farLooks == 0 {
                GameInstance.GetReactionSystem(gi).MarkDespawnCandidate(this.puppet.GetEntityID());
                GBPFleeDbg(this.puppet, "RALLY at " + FloatToStringPrec(dist, 0) + "m: got away (despawn candidate), watching for a return");
            }
            if this.farLooks + 1 < GBPReengage.MaxFarLooks() {
                let far = GBPReengage.Create(this.puppet);
                far.farLooks = this.farLooks + 1;
                GameInstance.GetDelaySystem(gi).DelayCallback(far, GBPReengage.FarLookInterval(), false);
            }
            return;
        }
        if this.tries == 0 && this.farLooks > 0 {
            GBPFleeDbg(this.puppet, "RALLY: came back to " + FloatToStringPrec(dist, 0) + "m after getting away");
        }
        
        let ws = GameInstance.GetWorkspotSystem(gi);
        let inWs: Bool = ws.IsActorInWorkspot(this.puppet);
        if this.guard > 0 {
            this.GuardLook(gi, player, hls, inWs, dist, ws);
            return;
        }
        if Equals(hls, gamedataNPCHighLevelState.Combat) && !inWs {
            this.stuck += 1;
            if this.stuck >= 2 {
                GBPFleeDbg(this.puppet, "REENGAGE held (Combat twice, out of workspot), guarding " + ToString(GBPReengage.GuardLooks() * 2) + " s");
                let guardNext = GBPReengage.Create(this.puppet);
                guardNext.guard = GBPReengage.GuardLooks();
                guardNext.tries = this.tries + 1;
                GameInstance.GetDelaySystem(gi).DelayCallback(guardNext, 2.0, false);
                return;
            }
        } else {
            this.stuck = 0;
            let exit: String = "";
            if inWs {
                if this.exits == 0 { ws.SendFastExitSignal(this.puppet, GBPV3(0.0, 0.0, 0.0), false, true); exit = " fastExit"; }
                else { ws.StopNpcInWorkspot(this.puppet); exit = " StopNpcInWorkspot"; }
                this.exits += 1;
            }
            NPCPuppet.ChangeHighLevelState(this.puppet, gamedataNPCHighLevelState.Combat);
            let how: String = GBPRallyThreat(this.puppet, player);
            GBPFleeDbg(this.puppet, "REENGAGE try " + ToString(this.tries + 1) + " from " + ToString(hls) + " at " + FloatToStringPrec(dist, 0) + "m workspot=" + ToString(inWs) + exit + " (" + how + ")");
        }
        this.tries += 1;
        if this.tries >= GBPReengage.MaxTries() {
            GBPFleeDbg(this.puppet, "REENGAGE gave up after " + ToString(this.tries) + " tries, hls=" + ToString(hls));
            return;
        }
        let next = GBPReengage.Create(this.puppet);
        next.tries = this.tries;
        next.stuck = this.stuck;
        next.exits = this.exits;
        GameInstance.GetDelaySystem(gi).DelayCallback(next, 1.0, false);
    }

    private func GuardLook(gi: GameInstance, player: ref<PlayerPuppet>, hls: gamedataNPCHighLevelState, inWs: Bool, dist: Float, ws: ref<WorkspotGameSystem>) -> Void {
        if dist > GBPReengage.GoneDistance() {
            
            let far = GBPReengage.Create(this.puppet);
            far.farLooks = 1;
            GameInstance.GetDelaySystem(gi).DelayCallback(far, GBPReengage.FarLookInterval(), false);
            GBPFleeDbg(this.puppet, "REENGAGE guard: out to " + FloatToStringPrec(dist, 0) + "m, watching for a return");
            return;
        }
        let slipped: Bool = inWs || Equals(hls, gamedataNPCHighLevelState.Relaxed);
        let slips: Int32 = this.slips;
        if slipped && GBPStateOf(this.puppet).GBP_nerveGone < GBPReengage.MaxNerveGone() {
            
            if inWs { ws.StopNpcInWorkspot(this.puppet); }
            GBPEnsureState(this.puppet).GBP_nerveGone += 1;
            let cower: Bool = dist <= GBPReengage.CowerDistance();
            GBPEnsureState(this.puppet).GBP_cower = cower;
            GameInstance.GetDelaySystem(gi).DelayCallback(GBPFearCallback.Create(this.puppet), 0.1, false);
            GBPFleeDbg(this.puppet, "REENGAGE slipped back (" + ToString(hls) + ", workspot=" + ToString(inWs) + ") at " + FloatToStringPrec(dist, 0)
                + "m -> nerve gone, " + (cower ? "cower" : "run again") + " (" + ToString(GBPStateOf(this.puppet).GBP_nerveGone) + ")");
            return;
        }
        if slipped {
            if inWs { ws.StopNpcInWorkspot(this.puppet); }
            NPCPuppet.ChangeHighLevelState(this.puppet, gamedataNPCHighLevelState.Combat);
            let how: String = GBPRallyThreat(this.puppet, player);
            slips += 1;
            GBPFleeDbg(this.puppet, "REENGAGE slipped back (" + ToString(hls) + ", workspot=" + ToString(inWs) + ") at " + FloatToStringPrec(dist, 0) + "m -> again, slip " + ToString(slips) + " (" + how + ")");
            if slips >= GBPReengage.MaxSlips() { GBPFleeDbg(this.puppet, "REENGAGE guard gave up"); return; }
        }
        if this.guard <= 1 {
            GBPFleeDbg(this.puppet, "REENGAGE guard over at " + FloatToStringPrec(dist, 0) + "m, hls=" + ToString(hls));
            return;
        }
        let next = GBPReengage.Create(this.puppet);
        next.guard = this.guard - 1;
        next.slips = slips;
        next.tries = this.tries;
        GameInstance.GetDelaySystem(gi).DelayCallback(next, 2.0, false);
    }

    public static func Create(target: wref<ScriptedPuppet>) -> ref<GBPReengage> {
        let self = new GBPReengage();
        self.puppet = target;
        return self;
    }
}

@wrapMethod(ReactionManagerComponent)
private func IsInPendingBehavior() -> Bool {
    let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
    if IsDefined(owner) && GBPStateOf(owner).GBP_fleeDispatching {
        return false;
    };
    return wrappedMethod();
}

@wrapMethod(ReactionManagerComponent)
private func TriggerBehaviorReaction(reaction: ReactionOutput, stimTaskData: ref<StimEventTaskData>, stimData: StimEventData) -> Void {
    let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
    let probe: Bool = IsDefined(owner) && GBPStateOf(owner).GBP_shouldFlee && !GBPStateOf(owner).GBP_fleeDispatching;
    wrappedMethod(reaction, stimTaskData, stimData);
    if probe {
        GBPFleeDbg(owner, "vanilla " + ToString(reaction.reactionBehavior) + " during panic -> "
            + (IsDefined(this.m_pendingReaction) ? "parked" : (IsDefined(this.m_desiredReaction) ? "FIRED" : "dropped")));
    }
}

@wrapMethod(ReactionManagerComponent)
private final func ShouldEventBeProcessed(stimEvent: ref<StimuliEvent>) -> Bool {
    let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
    if IsDefined(owner) && GBPStateOf(owner).GBP_shouldFlee {
        if Equals(stimEvent.GetStimType(), gamedataStimType.Scream) {
            GBPFleeDbg(owner, "1 Scream arrived, event forced through");
            return true;
        }
    }
    return wrappedMethod(stimEvent);
}

@wrapMethod(ReactionManagerComponent)
private final func ShouldStimBeProcessed(stimEvent: ref<StimuliEvent>, delayed: Bool) -> Bool {
    let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
    if IsDefined(owner) && GBPStateOf(owner).GBP_shouldFlee {
        if Equals(stimEvent.GetStimType(), gamedataStimType.Scream) {
            return true;
        }
    }
    return wrappedMethod(stimEvent, delayed);
}

@wrapMethod(ReactionManagerComponent)
protected final func HandleStimEventTask(data: ref<ScriptTaskData>) -> Void {
    let stimData: ref<StimEventTaskData> = data as StimEventTaskData;
    if IsDefined(stimData) {
        let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
        if IsDefined(owner) && GBPStateOf(owner).GBP_shouldFlee {
            let stimEvent: ref<StimuliEvent> = stimData.cachedEvt;
            if IsDefined(stimEvent) && Equals(stimEvent.GetStimType(), gamedataStimType.Scream) {
                GBPFleeDbg(owner, "2 task dispatch");
                let stimParams: StimParams = this.ProcessStimParams(stimEvent);
                this.ProcessReactionOutput(stimData, stimParams);
                return;
            }
        }
    }
    wrappedMethod(data);
}

@wrapMethod(ReactionManagerComponent)
protected final func HandleStimEvent(stimData: ref<StimEventTaskData>) -> Void {
    let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
    if IsDefined(owner) && GBPStateOf(owner).GBP_shouldFlee {
        let stimEvent: ref<StimuliEvent> = stimData.cachedEvt;
        if IsDefined(stimEvent) && Equals(stimEvent.GetStimType(), gamedataStimType.Scream) {
            let stimParams: StimParams = this.ProcessStimParams(stimEvent);
            this.ProcessReactionOutput(stimData, stimParams);
            return;
        }
    }
    wrappedMethod(stimData);
}

@wrapMethod(ReactionManagerComponent)
private final func ProcessReactionOutput(stimData: ref<StimEventTaskData>, stimParams: StimParams) -> Void {
    let owner: ref<ScriptedPuppet> = this.GetOwnerPuppet();
    if IsDefined(owner) && GBPStateOf(owner).GBP_shouldFlee {
        let stimEvent: ref<StimuliEvent> = stimData.cachedEvt;
        if IsDefined(stimEvent) && Equals(stimEvent.GetStimType(), gamedataStimType.Scream) {
            stimParams.reactionOutput.reactionBehavior = GBPStateOf(owner).GBP_cower ? gamedataOutput.Surrender : gamedataOutput.Flee;
            stimParams.reactionOutput.reactionPriority = 9;
            stimParams.reactionOutput.AIbehaviorPriority = 7;
            GBPEnsureState(owner).GBP_fleeDispatching = true;
            this.TriggerBehaviorReaction(stimParams.reactionOutput, stimData, stimParams.stimData);
            GBPEnsureState(owner).GBP_fleeDispatching = false;
            
            GBPFleeDbg(owner, "3 TriggerBehaviorReaction(" + ToString(stimParams.reactionOutput.reactionBehavior) + ") desired=" + ToString(IsDefined(this.m_desiredReaction))
                + " pending=" + ToString(IsDefined(this.m_pendingReaction))
                + " hls=" + ToString(owner.GetHighLevelStateFromBlackboard()));
            return;
        }
    }
    wrappedMethod(stimData, stimParams);
}
