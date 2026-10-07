module SDPCE

// SDPCombat cut-down of Combat Evolved 4.16.8 (nexus 29125, by DigitalVixen): core system.
// Kept: faction profiles, traits, fears, morale, flee/rally, squad flank pings, enrolment.
// Removed: health/armour/resistance overrides, boss and cyberpsycho stats, combat healing, chrome distribution,
// melee ticket caps, recoil dampeners, projectile bullets, stun duration, NPC damage multipliers.

public func GBPLog(msg: String) -> Void {
    let cfg: ref<GBPConfig> = GBPConfig.Get(GetGameInstance());
    if IsDefined(cfg) && cfg.debugON { FTLog("[SDPCE] " + msg); };
}

public func GBPNpcTag(puppet: ref<ScriptedPuppet>) -> String {
    if !IsDefined(puppet) { return "[null]"; }
    let rec: String = TDBID.ToStringDEBUG(puppet.GetRecordID());
    let hp: Float = GameInstance.GetStatPoolsSystem(puppet.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health, false);
    return s"[\(rec) hp=\(RoundF(hp))]";
}

public func GBPHasStatusEffect(puppet: ref<ScriptedPuppet>, effect: TweakDBID) -> Bool {
    return StatusEffectSystem.ObjectHasStatusEffect(puppet, effect);
}

public func GBPLogHP(puppet: ref<ScriptedPuppet>, label: String) -> Void {
    if !IsDefined(puppet) { return; }
    let gi = puppet.GetGame();
    let entityID: StatsObjectID = Cast<StatsObjectID>(puppet.GetEntityID());
    let pools = GameInstance.GetStatPoolsSystem(gi);
    let stats = GameInstance.GetStatsSystem(gi);
    let hpAbs: Float = pools.GetStatPoolValue(entityID, gamedataStatPoolType.Health, false);
    let hpPct: Float = pools.GetStatPoolValue(entityID, gamedataStatPoolType.Health, true);
    let hpMax: Float = pools.GetStatPoolMaxPointValue(entityID, gamedataStatPoolType.Health);
    let hpStat: Float = stats.GetStatValue(entityID, gamedataStatType.Health);
    GBPLog(s"[GBP][HP] \(label) hpAbs=\(RoundF(hpAbs)) hpPct=\(FloatToStringPrec(hpPct, 1))% hpMax=\(RoundF(hpMax)) HealthStat=\(RoundF(hpStat))");
}

public class GBPFearCallback extends DelayCallback {
    private let puppet: wref<ScriptedPuppet>;
    private let m_resetGen: Int32;

    public func Call() {
        if GBPIsCorpse(this.puppet) { return; }
        if GBPNeverFears(this.puppet) { return; }
        
        if GBPStateOf(this.puppet).GBP_resetGen != this.m_resetGen { return; }
        let gi = this.puppet.GetGame();
        let player = GetPlayer(gi);
        if !IsDefined(player) { return; }

        GBPEnsureState(this.puppet).GBP_shouldFlee = true;
        GBPSystem.Note(gi, 2);
        GBPEnsureState(this.puppet).GBP_suppressUntil = 0.0;   
        GBPEnsureState(this.puppet).GBP_fleeSeenPos = GBPBelievedPlayerPos(this.puppet, player);
        
        let recProfile = GBPProfiles.GetProfile(GBPStateOf(this.puppet).GBP_factionIndex);
        let recThr: Float = 0.5;
        if IsDefined(recProfile) { recThr = recProfile.GetFleeWoundThreshold(); };
        let fleeDur: Float = ClampF(30.0 + MaxF(0.0, recThr - 0.35) * 1900.0, 30.0, 600.0);
        
        GBPEnsureState(this.puppet).GBP_watchGen += 1;
        GameInstance.GetDelaySystem(gi).DelayCallback(GBPFleeRecovery.Create(this.puppet), fleeDur, false);

        GBPSendFlee(this.puppet, player);
        
        GameInstance.GetDelaySystem(gi).DelayCallback(GBPFleeWatch.Create(this.puppet), GBPFleeWatch.FirstLook(), false);
        GBPFleeDbg(this.puppet, "requested (Fear + Scream), hlsNow=" + ToString(this.puppet.GetHighLevelStateFromBlackboard()));
    }

    public static func Create(target: wref<ScriptedPuppet>) -> ref<GBPFearCallback> {
        let self = new GBPFearCallback();
        self.puppet = target;
        self.m_resetGen = GBPStateOf(target).GBP_resetGen;
        return self;
    }
}

public class GBPFleeRecovery extends DelayCallback {
    private let puppet: wref<ScriptedPuppet>;
    private let m_resetGen: Int32;
    private let m_watchGen: Int32;

    public func Call() {
        if GBPIsCorpse(this.puppet) { return; }
        if GBPStateOf(this.puppet).GBP_resetGen != this.m_resetGen { return; }
        if GBPStateOf(this.puppet).GBP_watchGen != this.m_watchGen { return; }   
        if !GBPStateOf(this.puppet).GBP_shouldFlee { return; }
        GBPEndPanic(this.puppet, GetPlayer(this.puppet.GetGame()));
        let profile = GBPProfiles.GetProfile(GBPStateOf(this.puppet).GBP_factionIndex);
        let thr: Float = 0.5;
        if IsDefined(profile) { thr = profile.GetFleeWoundThreshold(); };
        GBPEnsureState(this.puppet).GBP_moraleWound = MinF(GBPStateOf(this.puppet).GBP_moraleWound, thr * 0.5);
    }

    public static func Create(target: wref<ScriptedPuppet>) -> ref<GBPFleeRecovery> {
        let self = new GBPFleeRecovery();
        self.puppet = target;
        self.m_resetGen = GBPStateOf(target).GBP_resetGen;
        self.m_watchGen = GBPStateOf(target).GBP_watchGen;
        return self;
    }
}

public class GBPFightMemory {
    public let id: EntityID;
    public let record: TweakDBID;
    public let at: Float;
    public let rolled: Bool;
    public let wound: Float;
    public let fear1: Int32;
    public let fear2: Int32;
    public let fighting: Bool;
}

public class GBPMoraleBreakCallback extends DelayCallback {
    public let deadPos: Vector4;
    public let deadFaction: Int32;
    public let deadRarityVal: Int32;

    public func Call() {
        let gi = GetGameInstance();
        let system = GBPSystem.Get(gi);
        if IsDefined(system) {
            system.ProcessMoraleBreak(this.deadPos, this.deadFaction, this.deadRarityVal);
        }
    }

    public static func Create(pos: Vector4, faction: Int32, rarity: Int32) -> ref<GBPMoraleBreakCallback> {
        let self = new GBPMoraleBreakCallback();
        self.deadPos = pos;
        self.deadFaction = faction;
        self.deadRarityVal = rarity;
        return self;
    }
}

public abstract class GBPBossArmorRepairCallback {
    public static func IsKnownBossRecord(puppet: wref<ScriptedPuppet>) -> Bool {
        if !IsDefined(puppet) { return false; }
        return GBPSystem.IsNamedBossRecord(TDBID.ToStringDEBUG(puppet.GetRecordID()));
    }

    public static func IsCyberpsychoRecord(recordStr: String) -> Bool {
        let lower: String = StrLower(recordStr);
        return StrContains(lower, "cyberpsycho")
            || StrContains(lower, "_psycho")
            || StrContains(lower, "ma_wat_nid_22_monk");
    }
}

public class GBPSystem extends ScriptableSystem {

    private let m_config: ref<GBPConfig>;
    private let m_player: wref<PlayerPuppet>;
    private let m_isSessionActive: Bool;
    private let m_trackedPuppets: array<wref<ScriptedPuppet>>;
    private let m_factionLookup: array<Int32>;
    private let m_profileCache: array<ref<GBPProfile>>;
    private let m_defaultState: ref<GBPNpcState>;
    
    private let m_deathPos: array<Vector4>;
    private let m_deathFaction: array<Int32>;
    private let m_deathTime: array<Float>;
    private let m_fightMemory: array<ref<GBPFightMemory>>;

    private let m_attachSeen: Int32;
    private let m_enrolled: Int32;
    private let m_civilian: Int32;
    public func GetAttachSeen() -> Int32 { return this.m_attachSeen; }
    public func GetEnrolledCount() -> Int32 { return this.m_enrolled; }
    public func GetCivilianCount() -> Int32 { return this.m_civilian; }
    public func NoteAttachSeen() -> Void { this.m_attachSeen += 1; }   
    
    public func NextEnrollDelay() -> Float { return 0.15 + Cast<Float>(this.m_attachSeen % 10) * 0.03; }
    public func NoteCivilian() -> Void { this.m_civilian += 1; }       

    // event counters for the SDPCombat report (0 detection panic, 1 morale break, 2 fled, 3 rallied,
    // 4 flank, 5 cover eject, 6 covering fire, 7 pinned, 8 arm crippled, 9 leg crippled, 10 incapacitated)
    private let m_events: array<Int32>;
    public static func Note(gi: GameInstance, i: Int32) -> Void {
        let sys = GBPSystem.Get(gi);
        if !IsDefined(sys) { return; };
        if ArraySize(sys.m_events) < 11 { ArrayResize(sys.m_events, 11); };
        sys.m_events[i] += 1;
    }
    public func ResetEvents() -> Void { ArrayClear(this.m_events); ArrayResize(this.m_events, 11); }
    public func EventSummary() -> String {
        if ArraySize(this.m_events) < 11 { ArrayResize(this.m_events, 11); };
        let e = this.m_events;
        return s"detection panics \(e[0]), morale breaks \(e[1]), fled \(e[2]), rallied \(e[3]), flanks \(e[4]), cover ejects \(e[5]), covering fire \(e[6]), pinned \(e[7]), arms crippled \(e[8]), legs crippled \(e[9]), incapacitated \(e[10])";
    }

    private let m_flankPingCooldown: Bool;
    public func ClearFlankPingCooldown() -> Void { this.m_flankPingCooldown = false; }
    public func PingSquadFlank(victim: ref<ScriptedPuppet>) -> Void {
        if this.m_flankPingCooldown { return; };
        if !GBPStateOf(victim).GBP_factionCached { return; };
        if !GBPManeuversOn(this.GetGameInstance()) { return; };   
        this.m_flankPingCooldown = true;
        GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(GBPFlankPingClear.Create(this), 2.0, false);
        let vFaction: Int32 = GBPStateOf(victim).GBP_factionIndex;
        let vPos: Vector4 = victim.GetWorldPosition();
        let flanked: Bool = false;
        let overwatch: ref<ScriptedPuppet>;
        let i: Int32 = ArraySize(this.m_trackedPuppets) - 1;
        while i >= 0 {
            let ally = this.m_trackedPuppets[i];
            if !GBPIsCorpse(ally) && NotEquals(ally.GetEntityID(), victim.GetEntityID()) {
                
                if GBPStateOf(ally).GBP_factionCached && GBPStateOf(ally).GBP_factionIndex == vFaction
                  && GBPMayPullIntoFight(ally) {
                    if Vector4.Distance(ally.GetWorldPosition(), vPos) <= 30.0 {
                        if GBPFlank.OnHit(ally as NPCPuppet) {
                            flanked = true;
                        } else {
                            
                            let owNpc: ref<NPCPuppet> = ally as NPCPuppet;
                            if !IsDefined(overwatch) && IsDefined(owNpc) && !GBPStateOf(ally).GBP_shouldFlee
                              && !GBPSuppression.IsPinned(ally)
                              && Equals(owNpc.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Combat)
                              && NotEquals(AICoverHelper.GetCurrentCoverId(ally), Cast<Uint64>(0)) {
                                overwatch = ally;
                            };
                        };
                    };
                };
            };
            i -= 1;
        };
        
        if flanked && IsDefined(overwatch) {
            let owProfile = GBPProfiles.GetProfile(GBPStateOf(overwatch).GBP_factionIndex);
            let owChance: Float = 0.0;
            if IsDefined(owProfile) { owChance = owProfile.GetSuppressorChance(); };
            if GBPStateOf(overwatch).GBP_bossStyle == 2 { owChance = 1.0; };   
            if RandF() < owChance {
                let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
                
                if now >= GBPStateOf(overwatch).GBP_suppressReadyAt {
                    GBPEnsureState(overwatch).GBP_suppressUntil = now + 4.0;
                    GBPSystem.Note(this.GetGameInstance(), 6);
                    GBPEnsureState(overwatch).GBP_suppressReadyAt = now + 12.0;
                };
            };
        };
    }

    private let m_debugLockedTarget: wref<ScriptedPuppet>;
    public func GetDebugLockedTarget() -> wref<ScriptedPuppet> { return this.m_debugLockedTarget; }
    public func SetDebugLockedTarget(t: ref<ScriptedPuppet>) -> Void { this.m_debugLockedTarget = t; }
    public func ClearDebugLockedTarget() -> Void { this.m_debugLockedTarget = null; }

    // Vanilla lifecycle (CE used Codeware's session callbacks).
    public func OnAttach() -> Void {
        this.m_defaultState = new GBPNpcState();
    }

    public func OnDetach() -> Void {
        this.EndSession();
    }

    private func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
        this.EndSession();
        this.EnsureSession();
    }

    private func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
        this.EndSession();
    }

    public func EnsureSession() -> Bool {
        if this.m_isSessionActive { return true; };
        if !IsDefined(GetPlayer(this.GetGameInstance())) { return false; };
        this.m_isSessionActive = true;
        this.InitSession();
        return true;
    }

    private func EndSession() -> Void {
        if !this.m_isSessionActive { return; };
        this.m_isSessionActive = false;
        this.TeardownSession();
    }

    private func InitSession() -> Void {
        let gi = this.GetGameInstance();
        let player = GetPlayer(gi);
        if !IsDefined(player) { return; };
        this.m_player = player;
        this.m_config = GBPConfig.Get(gi);

        this.BuildFactionLookup();
        this.BuildProfileCache();

        // CE also set melee ticket caps, recoil dampeners, projectile bullets and stun duration here: removed.
    }

    private func TeardownSession() -> Void {
        ArrayClear(this.m_trackedPuppets);
        ArrayClear(this.m_deathPos);
        ArrayClear(this.m_deathFaction);
        ArrayClear(this.m_deathTime);
        ArrayClear(this.m_fightMemory);
        this.m_config = null;
        this.m_player = null;
    }

    public func EnrollPuppet(puppet: ref<ScriptedPuppet>) -> Void {
        if !this.EnsureSession() { return; };
        if !IsDefined(this.m_config) || !this.m_config.modON { return; };
        

        if !IsDefined(puppet) { return; };
        if puppet.IsDead() { return; };
                if puppet.IsDeadNoStatPool() { return; };

        if puppet.IsIncapacitated() || GBPIsSacredBody(puppet) { return; };
        
        let dyingNpc: ref<NPCPuppet> = puppet as NPCPuppet;
        if IsDefined(dyingNpc) && dyingNpc.IsAboutToDieOrDefeated() { return; };

        let factionIndex = this.ResolveFaction(puppet);
        if factionIndex < 0 {
            if IsDefined(puppet.sdpceState) && puppet.sdpceState.GBP_factionCached {
                GBPSystem.ResetGBPFields(puppet, true);   
            };
            return;
        };

        let mem: ref<GBPFightMemory> = this.TakeFightMemory(puppet);

        GBPSystem.ResetGBPFields(puppet);

        GBPEnsureState(puppet).GBP_factionCached = true;
        GBPEnsureState(puppet).GBP_factionIndex = factionIndex;
        GBPEnsureState(puppet).GBP_rarityVal = GBPSystem.ResolveRarityVal(puppet);

        if IsDefined(mem) && mem.fear1 != 0 {
            GBPEnsureState(puppet).GBP_fear1 = mem.fear1;
            GBPEnsureState(puppet).GBP_fear2 = mem.fear2;
        } else {
            let fears = GBPSystem.RollFearsFromProfile(factionIndex, GBPStateOf(puppet).GBP_rarityVal);
            GBPEnsureState(puppet).GBP_fear1 = fears / 10;
            GBPEnsureState(puppet).GBP_fear2 = fears % 10;
        }
        if IsDefined(mem) {
            GBPEnsureState(puppet).GBP_detectionRolled = mem.rolled;
            GBPEnsureState(puppet).GBP_moraleWound = mem.wound;
            if this.m_config.debugON {
                GBPLog(s"[GBP] re-attach of \(GBPNpcTag(puppet)) \(EntityID.ToDebugString(puppet.GetEntityID())): kept rolled=\(mem.rolled) wound=\(FloatToStringPrec(mem.wound, 2)) fighting=\(mem.fighting)");
            }
        }

        if GBPStateOf(puppet).GBP_fear1 == 8 {
            let profile = GBPProfiles.GetProfile(factionIndex);
            if IsDefined(profile) && profile.GetMoraleBreakChance(GBPStateOf(puppet).GBP_rarityVal) <= 0.0 {
                GBPEnsureState(puppet).GBP_unbreakable = true;
            }
        }
        if GBPNeverFears(puppet) { GBPEnsureState(puppet).GBP_unbreakable = true; }

        this.ApplyFactionCombatProfile(puppet, factionIndex);
        GBPCapability.Apply(puppet, factionIndex);

        if IsDefined(this.m_config) && this.m_config.debugON {
            GBPLog(s"[GBP] EnrollPuppet \(GBPNpcTag(puppet)) faction=\(factionIndex) rarity=\(GBPStateOf(puppet).GBP_rarityVal) armor=\(RoundF(GBPStateOf(puppet).GBP_appliedArmor)) isBoss=\(GBPStateOf(puppet).GBP_isBoss)");
        }

        this.TrackPuppet(puppet);

        if IsDefined(mem) && mem.fighting {
            GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(GBPReengage.Create(puppet), 1.0, false);
        }
    }

    public func RememberFight(puppet: ref<ScriptedPuppet>) -> Void {
        let st = puppet.sdpceState;
        if !IsDefined(st) || !st.GBP_factionCached || GBPIsCorpse(puppet) { return; }
        let hls = puppet.GetHighLevelStateFromBlackboard();
        let fighting: Bool = st.GBP_shouldFlee || Equals(hls, gamedataNPCHighLevelState.Combat) || Equals(hls, gamedataNPCHighLevelState.Fear);
        if !fighting && !st.GBP_detectionRolled && st.GBP_moraleWound <= 0.0 { return; }
        let m = new GBPFightMemory();
        m.id = puppet.GetEntityID();
        m.record = puppet.GetRecordID();
        m.at = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
        m.rolled = st.GBP_detectionRolled;
        m.wound = st.GBP_moraleWound;
        m.fear1 = st.GBP_fear1;
        m.fear2 = st.GBP_fear2;
        m.fighting = fighting;
        this.TakeFightMemory(puppet);   
        ArrayPush(this.m_fightMemory, m);
    }

    public func TakeFightMemory(puppet: ref<ScriptedPuppet>) -> ref<GBPFightMemory> {
        let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
        let id: EntityID = puppet.GetEntityID();
        let rec: TweakDBID = puppet.GetRecordID();
        let found: ref<GBPFightMemory>;
        let keep: array<ref<GBPFightMemory>>;
        let i: Int32 = 0;
        while i < ArraySize(this.m_fightMemory) {
            let m = this.m_fightMemory[i];
            if now - m.at <= 300.0 {
                if !IsDefined(found) && Equals(m.id, id) && Equals(m.record, rec) { found = m; }
                else { ArrayPush(keep, m); }
            }
            i += 1;
        }
        this.m_fightMemory = keep;
        return found;
    }

    public func TrackPuppet(puppet: ref<ScriptedPuppet>) -> Void {
        if GBPStateOf(puppet).GBP_tracked { return; };
        GBPEnsureState(puppet).GBP_tracked = true;
        ArrayPush(this.m_trackedPuppets, puppet);
        this.m_enrolled += 1;
        if ArraySize(this.m_trackedPuppets) > 50 {
            this.CleanTrackedPuppets();
        };
    }

    public func ResetAndReapplyNPC(puppet: ref<ScriptedPuppet>) -> Bool {
        if !IsDefined(puppet) || !IsDefined(this.m_config) || !this.m_config.modON { return false; };
        GBPSystem.ResetGBPFields(puppet);
        let factionIndex: Int32 = this.ResolveFaction(puppet);
        if factionIndex < 0 { return false; };
        GBPEnsureState(puppet).GBP_factionCached = true;
        GBPEnsureState(puppet).GBP_factionIndex = factionIndex;
        GBPEnsureState(puppet).GBP_rarityVal = GBPSystem.ResolveRarityVal(puppet);
        let fears: Int32 = GBPSystem.RollFearsFromProfile(factionIndex, GBPStateOf(puppet).GBP_rarityVal);
        GBPEnsureState(puppet).GBP_fear1 = fears / 10;
        GBPEnsureState(puppet).GBP_fear2 = fears % 10;
        if GBPStateOf(puppet).GBP_fear1 == 8 {
            let profile = GBPProfiles.GetProfile(factionIndex);
            if IsDefined(profile) && profile.GetMoraleBreakChance(GBPStateOf(puppet).GBP_rarityVal) <= 0.0 {
                GBPEnsureState(puppet).GBP_unbreakable = true;
            }
        }
        if GBPNeverFears(puppet) { GBPEnsureState(puppet).GBP_unbreakable = true; }
        this.ApplyFactionCombatProfile(puppet, factionIndex);
        GBPCapability.Apply(puppet, factionIndex);
        this.TrackPuppet(puppet);   
        return true;
    }

    private func DetectArchetype(puppet: ref<ScriptedPuppet>) -> Int32 {
        if GBPStateOf(puppet).GBP_rarityVal >= 5 { return 8; };

        let gi: GameInstance = puppet.GetGame();
        let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
        if !IsDefined(ts) { return 0; };

        let weapon: wref<WeaponObject> = ts.GetItemInSlot(puppet, t"AttachmentSlots.WeaponRight") as WeaponObject;
        if IsDefined(weapon) {
            return GBPSystem.ArchetypeFromItemType(RPGManager.GetItemType(weapon.GetItemID()));
        };

        let items: array<wref<gameItemData>>;
        ts.GetItemList(puppet, items);
        let meleeFound: Bool = false;
        let i: Int32 = 0;
        while i < ArraySize(items) {
            let data: wref<gameItemData> = items[i];
            if IsDefined(data) {
                let id: ItemID = data.GetID();
                if RPGManager.IsItemWeapon(id) {
                    let arch: Int32 = GBPSystem.ArchetypeFromItemType(RPGManager.GetItemType(id));
                    if arch == 7 {
                        meleeFound = true;
                    } else {
                        return arch;
                    };
                };
            };
            i += 1;
        };
        if meleeFound { return 7; };

        let fromRecord: Int32 = GBPSystem.ArchetypeFromRecord(puppet);
        if fromRecord >= 0 { return fromRecord; };
        return 7;
    }

    public static func ArchetypeFromItemType(itemType: gamedataItemType) -> Int32 {
        if Equals(itemType, gamedataItemType.Wea_Shotgun) || Equals(itemType, gamedataItemType.Wea_ShotgunDual) { return 1; };
        if Equals(itemType, gamedataItemType.Wea_SubmachineGun) { return 2; };
        
        if Equals(itemType, gamedataItemType.Wea_AssaultRifle) || Equals(itemType, gamedataItemType.Wea_Rifle) { return 3; };
        if Equals(itemType, gamedataItemType.Wea_PrecisionRifle) || Equals(itemType, gamedataItemType.Wea_SniperRifle) { return 4; };
        if Equals(itemType, gamedataItemType.Wea_HeavyMachineGun) || Equals(itemType, gamedataItemType.Wea_LightMachineGun) { return 6; };
        if Equals(itemType, gamedataItemType.Wea_Hammer) || Equals(itemType, gamedataItemType.Wea_Katana)
            || Equals(itemType, gamedataItemType.Wea_Knife) || Equals(itemType, gamedataItemType.Wea_LongBlade)
            || Equals(itemType, gamedataItemType.Wea_ShortBlade) || Equals(itemType, gamedataItemType.Wea_OneHandedClub)
            || Equals(itemType, gamedataItemType.Wea_TwoHandedClub) || Equals(itemType, gamedataItemType.Wea_Fists)
            || Equals(itemType, gamedataItemType.Wea_Machete) || Equals(itemType, gamedataItemType.Wea_Chainsword)
            || Equals(itemType, gamedataItemType.Wea_Sword) || Equals(itemType, gamedataItemType.Cyb_MantisBlades)
            || Equals(itemType, gamedataItemType.Cyb_StrongArms) || Equals(itemType, gamedataItemType.Cyb_NanoWires)
            || Equals(itemType, gamedataItemType.Wea_Melee) || Equals(itemType, gamedataItemType.Wea_Axe) { return 7; };
        return 0;
    }

    public static func ArchetypeFromRecord(puppet: ref<ScriptedPuppet>) -> Int32 {
        let rec: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(puppet.GetRecordID());
        if !IsDefined(rec) { return -1; };
        let s: String = StrLower(TDBID.ToStringDEBUG(puppet.GetRecordID()));
        let archRec = rec.ArchetypeData();
        if IsDefined(archRec) { s = s + " " + StrLower(TDBID.ToStringDEBUG(archRec.GetID())); };
        
        s = s + " " + GBPChromeDetect.ArchetypeEnum(puppet);
        if StrContains(s, "netrunner") { return 5; };
        if StrContains(s, "sniper") { return 4; };
        if StrContains(s, "shotgun") { return 1; };
        if StrContains(s, "hmg") || StrContains(s, "lmg") || StrContains(s, "heavyranged") || StrContains(s, "heavyrifle") || StrContains(s, "gunner") { return 6; };
        if StrContains(s, "melee") { return 7; };
        
        if StrContains(s, "copperhead") || StrContains(s, "_ajax") || StrContains(s, "masamune") || StrContains(s, "sidewinder")
            || StrContains(s, "_umbra") || StrContains(s, "_kyubi") || StrContains(s, "hercules") || StrContains(s, "_rifle") { return 3; };
        if StrContains(s, "pulsar") || StrContains(s, "saratoga") || StrContains(s, "shingen") || StrContains(s, "_dian") { return 2; };
        if StrContains(s, "nekomata") || StrContains(s, "ashura") || StrContains(s, "_grad") || StrContains(s, "overwatch")
            || StrContains(s, "achilles") || StrContains(s, "sor22") { return 4; };
        if StrContains(s, "carnage") || StrContains(s, "_igla") || StrContains(s, "tactician") || StrContains(s, "crusher")
            || StrContains(s, "palica") || StrContains(s, "satara") || StrContains(s, "_zhuo") || StrContains(s, "testera") { return 1; };
        if StrContains(s, "defender") || StrContains(s, "mk31") { return 6; };
        if StrContains(s, "_knife") || StrContains(s, "baseball") || StrContains(s, "_baton") || StrContains(s, "pipewrench")
            || StrContains(s, "tireiron") || StrContains(s, "ironpipe") || StrContains(s, "crowbar") || StrContains(s, "_wrench")
            || StrContains(s, "machete") || StrContains(s, "_hammer") || StrContains(s, "katana") || StrContains(s, "_fists") { return 7; };
        
        if StrContains(s, "_nova") || StrContains(s, "_nue") || StrContains(s, "lexington") || StrContains(s, "slaughtomatic")
            || StrContains(s, "_omaha") || StrContains(s, "kenshin") || StrContains(s, "overture") || StrContains(s, "yukimura")
            || StrContains(s, "_burya") || StrContains(s, "quasar") || StrContains(s, "handgun") || StrContains(s, "pistol")
            || StrContains(s, "revolver") { return 0; };
        if StrContains(s, "smg") || StrContains(s, "fastranged") { return 2; };
        if StrContains(s, "ranged") { return 0; };
        return -1;
    }

    // Behaviour only. CE's version also set accuracy, base speed, health, armour, resistances, headshot
    // multipliers and helmets; those belong to ENC (health) and SDPCombat (armour, aim) in this install.
    public func ApplyFactionCombatProfile(puppet: ref<ScriptedPuppet>, factionIndex: Int32) -> Void {
        let profile = GBPProfiles.GetProfile(factionIndex);
        if !IsDefined(profile) { return; };
        profile.Setup(this.m_config);

        let gi = puppet.GetGame();
        let statsSystem = GameInstance.GetStatsSystem(gi);
        let entityID = Cast<StatsObjectID>(puppet.GetEntityID());
        let rarityVal = GBPStateOf(puppet).GBP_rarityVal;
        let archetype: Int32 = this.DetectArchetype(puppet);
        let recordStr = TDBID.ToStringDEBUG(puppet.GetRecordID());
        let isVariant = profile.IsDistrictVariant(recordStr);

        // bosses, cyberpsychos and Beat on the Brat fighters keep their nerve and don't run squad maneuvers
        if IsDefined(GBPBossStats.For(recordStr)) || GBPBossArmorRepairCallback.IsCyberpsychoRecord(recordStr)
          || GBPSystem.BrawlerHp(recordStr) > 0.0 {
            GBPEnsureState(puppet).GBP_isBoss = true;
            GBPEnsureState(puppet).GBP_unbreakable = true;
        };

        if IsDefined(GBPStateOf(puppet).GBP_modSpeedRusher) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modSpeedRusher); GBPEnsureState(puppet).GBP_modSpeedRusher = null; }
        if IsDefined(GBPStateOf(puppet).GBP_modSpeedShowOff) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modSpeedShowOff); GBPEnsureState(puppet).GBP_modSpeedShowOff = null; }

        let traitStr = profile.GetTraits(rarityVal, archetype, isVariant);
        GBPEnsureState(puppet).GBP_traits = GBPSystem.ParseTraitString(traitStr);
        let traits = GBPStateOf(puppet).GBP_traits;

        let districtStr = GBPSystem.GetCurrentDistrictName(gi);
        GBPEnsureState(puppet).GBP_districtFearMod = profile.GetDistrictFearModifier(districtStr);
        if GBPStateOf(puppet).GBP_districtFearMod < 0.01 { GBPEnsureState(puppet).GBP_districtFearMod = 1.0; }

        if GBPSystem.HasTrait(traits, GBPSystem.TraitRusher()) {
            let rMod = RPGManager.CreateStatModifier(gamedataStatType.MaxSpeed, gameStatModifierType.AdditiveMultiplier, 0.20);
            GBPEnsureState(puppet).GBP_modSpeedRusher = rMod;
            statsSystem.AddModifier(entityID, rMod);
        };
        if GBPSystem.HasTrait(traits, GBPSystem.TraitShowOff()) {
            let soMod = RPGManager.CreateStatModifier(gamedataStatType.MaxSpeed, gameStatModifierType.AdditiveMultiplier, 0.08);
            GBPEnsureState(puppet).GBP_modSpeedShowOff = soMod;
            statsSystem.AddModifier(entityID, soMod);
        };
    }

    public func ProcessMoraleBreak(deadPos: Vector4, deadFaction: Int32, deadRarityVal: Int32) -> Void {
        let gi = GetGameInstance();
        let player = GetPlayer(gi);
        if !IsDefined(player) || !IsDefined(this.m_config) || !this.m_config.enableFear { return; };

        let profile = GBPProfiles.GetProfile(deadFaction);
        if !IsDefined(profile) { return; };

        let breakRange: Float = 35.0;
        let diff: Int32 = 100;
        if IsDefined(this.m_config) { diff = this.m_config.npcDifficulty; };
        let fearMult = GBPSystem.GetDifficultyFearMult(diff);
        if fearMult <= 0.0 { return; };

        let statPoolsSystem = GameInstance.GetStatPoolsSystem(gi);
        let delaySystem = GameInstance.GetDelaySystem(gi);
        let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(gi));
        this.RecordDeath(deadPos, deadFaction, now);

        let i: Int32 = ArraySize(this.m_trackedPuppets) - 1;
        while i >= 0 {
            let puppet = this.m_trackedPuppets[i];
            if !GBPIsCorpse(puppet) && !GBPStateOf(puppet).GBP_shouldFlee && !GBPStateOf(puppet).GBP_unbreakable {
                if GBPStateOf(puppet).GBP_factionCached && Equals(GBPStateOf(puppet).GBP_factionIndex, deadFaction) {
                    let dist = Vector4.Distance(puppet.GetWorldPosition(), deadPos);
                    if dist <= breakRange {
                        let rarityVal = GBPStateOf(puppet).GBP_rarityVal;
                        let breakChance = profile.GetMoraleBreakChance(rarityVal);

                        if deadRarityVal >= 3 { breakChance = breakChance * 1.5; }
                        else if deadRarityVal >= 2 { breakChance = breakChance * 1.2; }

                        let hpPct = statPoolsSystem.GetStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health, true);
                        if hpPct > 100.0 { hpPct = 100.0; }
                        let healthDrain = (1.0 - (hpPct / 100.0)) * 0.5;
                        breakChance = breakChance + healthDrain;

                        breakChance = breakChance + GBPStateOf(puppet).GBP_moraleWound;

                        let lossRatio: Float = this.SquadLossRatio(puppet, breakRange, now);
                        let decimation: Float = lossRatio * lossRatio * this.m_config.decimationStrength * GBPSystem.DecimationDamp(rarityVal);
                        breakChance = breakChance + decimation;

                        let credMult: Float = GBPSystem.GetStreetCredFearMult(gi, rarityVal, this.m_config);
                        breakChance = breakChance * fearMult * credMult * GBPSystem.DoctrineBreakMult(profile.GetDoctrineTier());

                        let allyDistrictMod: Float = GBPStateOf(puppet).GBP_districtFearMod;
                        if allyDistrictMod < 0.01 { allyDistrictMod = 1.0; }
                        breakChance = breakChance * allyDistrictMod;

                        let alliedTraits = GBPStateOf(puppet).GBP_traits;
                        if GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitFormationFighter()) || GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitSteady()) {
                            
                            breakChance = breakChance * 0.4;
                            GBPEnsureState(puppet).GBP_moraleWound = GBPStateOf(puppet).GBP_moraleWound - 0.1;
                            if GBPStateOf(puppet).GBP_moraleWound < 0.0 { GBPEnsureState(puppet).GBP_moraleWound = 0.0; }
                        }
                        if GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitCoward()) {
                            breakChance = breakChance * 1.75;
                        }
                        if GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitCyberJunkie()) {
                            breakChance = breakChance * 0.6;
                        }
                        if GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitPackTactics()) {
                            let ptAllies: Int32 = this.CountSameFactionAlliesNearby(puppet, 35.0);
                            if ptAllies >= 2 { breakChance = breakChance * 0.6; }
                            else { breakChance = breakChance * 1.2; }
                        }
                        if GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitSolo()) {
                            let soloAllies: Int32 = this.CountSameFactionAlliesNearby(puppet, 35.0);
                            if soloAllies == 0 { breakChance = breakChance * 0.6; }
                            else if soloAllies >= 2 { breakChance = breakChance * 1.4; }
                        }
                        
                        if GBPSystem.HasTrait(alliedTraits, GBPSystem.TraitShowOff()) {
                            let soAllies: Int32 = this.CountSameFactionAlliesNearby(puppet, 35.0);
                            if soAllies >= 2 { breakChance = breakChance * 0.8; }
                            else { breakChance = breakChance * 1.3; }
                        }

                        let autoFlee = breakChance >= 1.0;
                        if breakChance > 0.95 { breakChance = 0.95; }

                        if (autoFlee || RandF() < breakChance) && GBPMayCommand(puppet) {
                            let delay = 0.3 + RandF() * 1.2;
                            delaySystem.DelayCallback(GBPFearCallback.Create(puppet), delay, false);
                            GBPSystem.Note(gi, 1);
                            if IsDefined(this.m_config) && this.m_config.debugON {
                                GBPLog(s"[GBP] Morale broken - \(GBPNpcTag(puppet)) will flee in \(FloatToStringPrec(delay, 2))s (chance=\(FloatToStringPrec(breakChance, 2)), losses=\(FloatToStringPrec(lossRatio, 2)), cred x\(FloatToStringPrec(credMult, 2)))");
                            }
                        }
                    }
                }
            }
            i -= 1;
        }
    }

    private func RecordDeath(pos: Vector4, faction: Int32, now: Float) -> Void {
        
        let keepPos: array<Vector4>;
        let keepFaction: array<Int32>;
        let keepTime: array<Float>;
        let i: Int32 = 0;
        while i < ArraySize(this.m_deathTime) {
            if now - this.m_deathTime[i] <= 60.0 {
                ArrayPush(keepPos, this.m_deathPos[i]);
                ArrayPush(keepFaction, this.m_deathFaction[i]);
                ArrayPush(keepTime, this.m_deathTime[i]);
            }
            i += 1;
        }
        ArrayPush(keepPos, pos);
        ArrayPush(keepFaction, faction);
        ArrayPush(keepTime, now);
        this.m_deathPos = keepPos;
        this.m_deathFaction = keepFaction;
        this.m_deathTime = keepTime;
    }

    private func SquadLossRatio(puppet: wref<ScriptedPuppet>, range: Float, now: Float) -> Float {
        let faction: Int32 = GBPStateOf(puppet).GBP_factionIndex;
        let pos: Vector4 = puppet.GetWorldPosition();
        let dead: Int32 = 0;
        let i: Int32 = 0;
        while i < ArraySize(this.m_deathTime) {
            if this.m_deathFaction[i] == faction && now - this.m_deathTime[i] <= 60.0 && Vector4.Distance(this.m_deathPos[i], pos) <= range {
                dead += 1;
            }
            i += 1;
        }
        if dead == 0 { return 0.0; }
        let alive: Int32 = this.CountSameFactionAlliesNearby(puppet, range) + 1;
        return Cast<Float>(dead) / Cast<Float>(dead + alive);
    }

    private func CleanTrackedPuppets() -> Void {
        let clean: array<wref<ScriptedPuppet>>;
        let i: Int32 = 0;
        while i < ArraySize(this.m_trackedPuppets) {
            let puppet = this.m_trackedPuppets[i];
            if !GBPIsCorpse(puppet) {
                ArrayPush(clean, puppet);
            } else {
                
                if IsDefined(puppet) { GBPEnsureState(puppet).GBP_tracked = false; };
            }
            i += 1;
        }
        this.m_trackedPuppets = clean;
    }

    public static func IsSpeccedBoss(factionIndex: Int32, recordStr: String) -> Bool {
        return factionIndex == 20 || (factionIndex >= 22 && factionIndex <= 26) || GBPSystem.IsNamedBossRecord(recordStr);
    }

    public static func IsUnaffiliatedHoldout(recordStr: String) -> Bool {
        
        return StrContains(StrLower(recordStr), "_lifebar");
    }

    public static func BrawlerHp(recordStr: String) -> Float {
        let r: String = StrLower(recordStr);
        if StrContains(r, "mq025_twin") { return 260.0; }            
        if StrContains(r, "mq025_buck") { return 360.0; }            
        if StrContains(r, "mq025_cesar") { return 420.0; }           
        if StrContains(r, "mq025_ozob_fist_fight") { return 460.0; } 
        if StrContains(r, "mq025_rhino") { return 560.0; }           
        if StrContains(r, "mq025_razor") { return 680.0; }           
        return 0.0;
    }

    public static func IsExcludedBossRecord(recordStr: String) -> Bool {
        let lower: String = StrLower(recordStr);
        return StrContains(lower, "_hologram")      
            || StrContains(lower, "_follower")      
            || StrContains(lower, "_photomode")
            || StrContains(lower, "q004_bd_")       
            || StrContains(lower, "q112_smasher");  
    }

    public static func IsNamedBossRecord(recordStr: String) -> Bool {
        return IsDefined(GBPBossStats.For(recordStr));
    }

    public static func Get(gi: GameInstance) -> ref<GBPSystem> {
        return GameInstance.GetScriptableSystemsContainer(gi).Get(n"SDPCE.GBPSystem") as GBPSystem;
    }

    public func GetDefaultState() -> ref<GBPNpcState> {
        if IsDefined(this.m_defaultState) { return this.m_defaultState; }
        return new GBPNpcState();
    }

    public func GetCachedProfile(factionIndex: Int32) -> ref<GBPProfile> {
        if factionIndex < 0 || factionIndex >= ArraySize(this.m_profileCache) { return null; }
        return this.m_profileCache[factionIndex];
    }

    private func BuildProfileCache() -> Void {
        ArrayClear(this.m_profileCache);
        ArrayResize(this.m_profileCache, 27);
        this.m_profileCache[0]  = new GBPMaelstromProfile();
        this.m_profileCache[1]  = new GBPTygerClawsProfile();
        this.m_profileCache[2]  = new GBPAnimalsProfile();
        this.m_profileCache[3]  = new GBPScavengerProfile();
        this.m_profileCache[4]  = new GBPValentinosProfile();
        this.m_profileCache[5]  = new GBPVoodooBoysProfile();
        this.m_profileCache[6]  = new GBPSixthStreetProfile();
        this.m_profileCache[7]  = new GBPArasakaProfile();
        this.m_profileCache[8]  = new GBPMilitechProfile();
        this.m_profileCache[9]  = new GBPKangTaoProfile();
        this.m_profileCache[10] = new GBPTraumaTeamProfile();
        this.m_profileCache[11] = new GBPWraithsProfile();
        this.m_profileCache[12] = new GBPBarghestProfile();
        this.m_profileCache[13] = new GBPNCPDProfile();
        this.m_profileCache[14] = new GBPMoxProfile();
        this.m_profileCache[15] = new GBPAldecaldosProfile();
        this.m_profileCache[16] = new GBPNetWatchProfile();
        this.m_profileCache[17] = new GBPBiotechnicaProfile();
        this.m_profileCache[18] = new GBPNUSAProfile();
        this.m_profileCache[19] = new GBPAfterlifeProfile();
        this.m_profileCache[20] = new GBPCyberpsychoProfile();
        this.m_profileCache[21] = new GBPUnaffiliatedProfile();
        this.m_profileCache[22] = new GBPPsychoAnchorProfile();
        this.m_profileCache[23] = new GBPPsychoRusherProfile();
        this.m_profileCache[24] = new GBPPsychoGunnerProfile();
        this.m_profileCache[25] = new GBPPsychoSniperProfile();
        this.m_profileCache[26] = new GBPPsychoNetrunnerProfile();
    }

    public static func ResetGBPFields(puppet: ref<ScriptedPuppet>, opt skipStatusStrip: Bool) -> Void {
        let gi: GameInstance = puppet.GetGame();
        let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(gi);
        let entityID: StatsObjectID = Cast<StatsObjectID>(puppet.GetEntityID());
        let cfgDbg: ref<GBPConfig> = GBPConfig.Get(gi);
        let dbg: Bool = IsDefined(cfgDbg) && cfgDbg.debugON;
        if dbg { GBPLogHP(puppet, "RESET entry"); }
        if IsDefined(statsSystem) {
            if IsDefined(GBPStateOf(puppet).GBP_modAccuracyProfile) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modAccuracyProfile); GBPEnsureState(puppet).GBP_modAccuracyProfile = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modAccuracyTrait) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modAccuracyTrait); GBPEnsureState(puppet).GBP_modAccuracyTrait = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modAccuracyCripple) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modAccuracyCripple); GBPEnsureState(puppet).GBP_modAccuracyCripple = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modSpeedProfile) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modSpeedProfile); GBPEnsureState(puppet).GBP_modSpeedProfile = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modSpeedRusher) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modSpeedRusher); GBPEnsureState(puppet).GBP_modSpeedRusher = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modSpeedShowOff) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modSpeedShowOff); GBPEnsureState(puppet).GBP_modSpeedShowOff = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modAccuracyPackTactics) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modAccuracyPackTactics); GBPEnsureState(puppet).GBP_modAccuracyPackTactics = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modSpeedCripple) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modSpeedCripple); GBPEnsureState(puppet).GBP_modSpeedCripple = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modHealthProfile) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modHealthProfile); GBPEnsureState(puppet).GBP_modHealthProfile = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modHealthBoss) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modHealthBoss); GBPEnsureState(puppet).GBP_modHealthBoss = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modArmor) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modArmor); GBPEnsureState(puppet).GBP_modArmor = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modThermalR) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modThermalR); GBPEnsureState(puppet).GBP_modThermalR = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modElectricR) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modElectricR); GBPEnsureState(puppet).GBP_modElectricR = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modChemicalR) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modChemicalR); GBPEnsureState(puppet).GBP_modChemicalR = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modHeadshotMult) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modHeadshotMult); GBPEnsureState(puppet).GBP_modHeadshotMult = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modBossDmg) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modBossDmg); GBPEnsureState(puppet).GBP_modBossDmg = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modCatchUpStrip) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modCatchUpStrip); GBPEnsureState(puppet).GBP_modCatchUpStrip = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modCatchUpDistStrip) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modCatchUpDistStrip); GBPEnsureState(puppet).GBP_modCatchUpDistStrip = null; }
            if IsDefined(GBPStateOf(puppet).GBP_modDoctrineDmg) { statsSystem.RemoveModifier(entityID, GBPStateOf(puppet).GBP_modDoctrineDmg); GBPEnsureState(puppet).GBP_modDoctrineDmg = null; }
        };

        let abIdx: Int32 = 0;
        while abIdx < ArraySize(GBPStateOf(puppet).GBP_chromeAbilities) {
            let abRec = TweakDBInterface.GetGameplayAbilityRecord(GBPStateOf(puppet).GBP_chromeAbilities[abIdx]);
            if IsDefined(abRec) { RPGManager.RemoveAbility(puppet, abRec); };
            abIdx += 1;
        };
        ArrayClear(GBPEnsureState(puppet).GBP_chromeAbilities);

        if dbg { GBPLogHP(puppet, "RESET exit"); }

        GBPEnsureState(puppet).GBP_isBoss = false;
        GBPEnsureState(puppet).GBP_isFemale = false;
        GBPEnsureState(puppet).GBP_armorRepairCharges = 0;
        GBPEnsureState(puppet).GBP_armorRepairAmount = 0.0;
        GBPEnsureState(puppet).GBP_armorRepairOnCooldown = false;
        GBPEnsureState(puppet).GBP_appliedArmor = 0.0;
        GBPEnsureState(puppet).GBP_armorIntegrity = 100.0;

        GBPEnsureState(puppet).GBP_unbreakable = false;
        GBPEnsureState(puppet).GBP_shouldFlee = false;
        GBPEnsureState(puppet).GBP_nerveGone = 0;
        GBPEnsureState(puppet).GBP_fleeSeenPos = GBPV4(0.0, 0.0, 0.0, 0.0);
        GBPEnsureState(puppet).GBP_moraleWound = 0.0;
        GBPEnsureState(puppet).GBP_fear1 = 0;
        GBPEnsureState(puppet).GBP_fear2 = 0;
        GBPEnsureState(puppet).GBP_districtFearMod = 1.0;

        GBPEnsureState(puppet).GBP_thermalResist = 0.0;
        GBPEnsureState(puppet).GBP_electricResist = 0.0;
        GBPEnsureState(puppet).GBP_chemicalResist = 0.0;
        GBPEnsureState(puppet).GBP_hackingResist = 0.0;
        GBPEnsureState(puppet).GBP_ramCostAdd = 0.0;
        GBPEnsureState(puppet).GBP_uploadTimeAdd = 0.0;

        GBPEnsureState(puppet).GBP_leftArmCrippled = false;
        GBPEnsureState(puppet).GBP_rightArmCrippled = false;
        GBPEnsureState(puppet).GBP_leftLegCrippled = false;
        GBPEnsureState(puppet).GBP_rightLegCrippled = false;
        GBPEnsureState(puppet).GBP_incapacitated = false;
        GBPEnsureState(puppet).GBP_primaryDropped = false;
        GBPEnsureState(puppet).GBP_hasHelmet = false;
        GBPEnsureState(puppet).GBP_helmetArmorValue = 0;
        GBPEnsureState(puppet).GBP_headshotMult = 0.0;

        GBPEnsureState(puppet).GBP_detectionRolled = false;
        GBPEnsureState(puppet).GBP_traits = 0;

        GBPEnsureState(puppet).GBP_factionCached = false;
        GBPEnsureState(puppet).GBP_factionIndex = -1;
        GBPEnsureState(puppet).GBP_initAttempted = false;
        GBPEnsureState(puppet).GBP_rarityVal = 0;

        GBPEnsureState(puppet).GBP_chromeApplied = false;

        GBPEnsureState(puppet).GBP_orderGen += 1;
        GBPEnsureState(puppet).GBP_orderPhase = 0;
        GBPEnsureState(puppet).GBP_orderReacquired = false;
        
        GBPEnsureState(puppet).GBP_resetGen += 1;

        GBPEnsureState(puppet).GBP_coverBreakReaction = 0.0;   
        GBPEnsureState(puppet).GBP_coverEjectPending = false;
        GBPEnsureState(puppet).GBP_flankOnCooldown = false;

        GBPEnsureState(puppet).GBP_suppressPressure = 0.0;
        GBPEnsureState(puppet).GBP_suppressStamp = 0.0;
        GBPEnsureState(puppet).GBP_pinnedUntil = 0.0;
        GBPEnsureState(puppet).GBP_pinReadyAt = 0.0;
        GBPEnsureState(puppet).GBP_suppressUntil = 0.0;
        GBPEnsureState(puppet).GBP_suppressReadyAt = 0.0;
        GBPEnsureState(puppet).GBP_bossStyle = 0;   

        if IsDefined(GBPStateOf(puppet).GBP_orderCmd) {
            let resetAi: ref<AIHumanComponent> = puppet.GetAIControllerComponent();
            if IsDefined(resetAi) { resetAi.StopExecutingCommand(GBPStateOf(puppet).GBP_orderCmd, true); };
            GBPEnsureState(puppet).GBP_orderCmd = null;
        };
    }

    private func BuildFactionLookup() -> Void {
        ArrayClear(this.m_factionLookup);
        ArrayResize(this.m_factionLookup, 43);
        let i: Int32 = 0;
        while i < 43 {
            this.m_factionLookup[i] = -1;
            i += 1;
        };
        this.m_factionLookup[10] = 0;   
        this.m_factionLookup[11] = 0;   
        this.m_factionLookup[2]  = 2;   
        this.m_factionLookup[3]  = 7;   
        this.m_factionLookup[4]  = 12;  
        this.m_factionLookup[9]  = 9;   
        this.m_factionLookup[12] = 8;   
        this.m_factionLookup[13] = 13;  
        this.m_factionLookup[20] = 3;   
        this.m_factionLookup[21] = 3;   
        this.m_factionLookup[22] = 6;   
        this.m_factionLookup[23] = 6;   
        this.m_factionLookup[26] = 10;  
        this.m_factionLookup[27] = 1;   
        this.m_factionLookup[31] = 4;   
        this.m_factionLookup[32] = 5;   
        this.m_factionLookup[33] = 11;  
        this.m_factionLookup[34] = 11;  
        this.m_factionLookup[25] = 14;  
        this.m_factionLookup[1]  = 15;  
        this.m_factionLookup[15] = 16;  
        this.m_factionLookup[5]  = 17;  
        this.m_factionLookup[14] = 18;  
        this.m_factionLookup[0]  = 19;  
    }

    public func ResolveFaction(puppet: ref<ScriptedPuppet>) -> Int32 {
        if !IsDefined(puppet) { return -1; };
        if puppet.IsMaxTac() { return 13; };

        let recordStr: String = TDBID.ToStringDEBUG(puppet.GetRecordID());
        if GBPBossArmorRepairCallback.IsCyberpsychoRecord(recordStr) { return GBPPsychoStats.For(recordStr).profileIndex; };

        let rec = TweakDBInterface.GetCharacterRecord(puppet.GetRecordID());
        if !IsDefined(rec) { return -1; };
        let aff = rec.Affiliation();
        if !IsDefined(aff) { return -1; };

        let idx = EnumInt(aff.Type());
        
        if idx >= 0 && idx < ArraySize(this.m_factionLookup) && this.m_factionLookup[idx] < 0 {
            if GBPSystem.IsNamedBossRecord(recordStr) { return 21; };
            
            if GBPSystem.IsDogtownCyberjunkie(recordStr) { return 21; };
            
            if !GBPSystem.IsUnaffiliatedHoldout(recordStr) && GBPSystem.ResolveRarityVal(puppet) >= 5 {
                return 21;
            };
        };
        
        if IsDefined(this.m_config) && this.m_config.leoCompatibility && StrBeginsWith(recordStr, "Character.leo_") {
            idx = GBPSystem.MapLeoAffiliation(idx);
        }
        if idx < 0 || idx >= ArraySize(this.m_factionLookup) { return -1; };
        return this.m_factionLookup[idx];
    }

    public static func MapLeoAffiliation(idx: Int32) -> Int32 {
        switch idx {
            case 8:  return 14; 
            case 24: return 14; 
            case 17: return 5;  
            case 35: return 5;  
            case 29: return 3;  
            case 30: return 12; 
            case 28: return 0;  
            default: return idx;
        }
    }

    public static func GetFactionNameByIndex(factionIndex: Int32) -> String {
        switch factionIndex {
            case 0: return "Maelstrom";
            case 1: return "Tyger Claws";
            case 2: return "Animals";
            case 3: return "Scavengers";
            case 4: return "Valentinos";
            case 5: return "Voodoo Boys";
            case 6: return "Sixth Street";
            case 7: return "Arasaka";
            case 8: return "Militech";
            case 9: return "Kang Tao";
            case 10: return "Trauma Team";
            case 11: return "Wraiths";
            case 12: return "Barghest";
            case 13: return "NCPD";
            case 14: return "The Moxes";
            case 15: return "Aldecaldos";
            case 16: return "NetWatch";
            case 17: return "Biotechnica";
            case 18: return "NUSA";
            case 19: return "Afterlife";
            case 20: return "Cyberpsycho";
            case 21: return "Unaffiliated";
            case 22: return "Cyberpsycho (anchor)";
            case 23: return "Cyberpsycho (rusher)";
            case 24: return "Cyberpsycho (gunner)";
            case 25: return "Cyberpsycho (sniper)";
            case 26: return "Cyberpsycho (netrunner)";
            default: return "Unknown";
        }
    }

    public static func IsDogtownCyberjunkie(recordStr: String) -> Bool {
        return StrContains(recordStr, "cbj_ep1_") && StrContains(recordStr, "_cyberjunkie");
    }

    public static func ResolveRarityVal(puppet: ref<ScriptedPuppet>) -> Int32 {
        if !IsDefined(puppet) { return 2; };
        let base: Int32 = GBPSystem.GetRarityValue(puppet.GetNPCRarity());
        if base >= 6 { return base; };
        let recordStr: String = TDBID.ToStringDEBUG(puppet.GetRecordID());
        if StrContains(recordStr, "_outpost_miniboss") { return 6; };
        
        if GBPSystem.IsDogtownCyberjunkie(recordStr) { return 6; };
        
        if StrContains(recordStr, "mq030_melisa") { return 7; };
        return base;
    }

    public static func GetRarityValue(rarity: gamedataNPCRarity) -> Int32 {
        switch rarity {
            case gamedataNPCRarity.Trash: return 0;
            case gamedataNPCRarity.Weak: return 1;
            case gamedataNPCRarity.Normal: return 2;
            case gamedataNPCRarity.Rare: return 3;
            case gamedataNPCRarity.Elite: return 4;
            case gamedataNPCRarity.Officer: return 5;
            case gamedataNPCRarity.Boss: return 6;
            case gamedataNPCRarity.MaxTac: return 7;
            default: return 2;
        }
    }

    public static func GetRarityHpMult(rarityVal: Int32, cfg: ref<GBPConfig>) -> Float {
        if !IsDefined(cfg) { return 1.0; }
        switch rarityVal {
            case 0: return cfg.hpTierTrash;
            case 1: return cfg.hpTierWeak;
            case 2: return cfg.hpTierNormal;
            case 3: return cfg.hpTierRare;
            case 4: return cfg.hpTierElite;
            case 5: return cfg.hpTierOfficer;
            case 6: return cfg.hpTierStreetBoss;
            case 7: return cfg.hpTierMaxTac;
        };
        return cfg.hpTierNormal;
    }

    public static func GetDifficultyAccuracyMult(difficulty: Int32) -> Float {
        return 0.6 + Cast<Float>(difficulty) * 0.006;
    }

    public static func GetDifficultyHealthMult(difficulty: Int32) -> Float {
        return 0.7 + Cast<Float>(difficulty) * 0.005;
    }

    public static func GetDifficultySpeedMult(difficulty: Int32) -> Float {
        let s = Cast<Float>(difficulty) / 100.0;
        return 0.9 + s * 0.15;
    }

    public static func GetDifficultyFearMult(difficulty: Int32) -> Float {
        if difficulty <= 0 { return 1.0; }
        return 100.0 / Cast<Float>(difficulty);
    }

    public static func GetStreetCredFearMult(gi: GameInstance, rarityVal: Int32, cfg: ref<GBPConfig>) -> Float {
        if !IsDefined(cfg) || cfg.fearStreetCredStrength <= 0.0 { return 1.0; }
        let player = GetPlayer(gi);
        if !IsDefined(player) { return 1.0; }
        let sc: Float = GameInstance.GetStatsSystem(gi).GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.StreetCred);
        return 1.0 + cfg.fearStreetCredStrength * (MaxF(sc - 10.0, 0.0) / 40.0) * GBPSystem.StreetCredFearDamp(rarityVal);
    }

    public static func StreetCredFearDamp(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 1.0; }
        if rarityVal == 1 { return 0.8; }
        if rarityVal == 2 { return 0.6; }
        if rarityVal == 3 { return 0.4; }
        if rarityVal <= 5 { return 0.2; }
        return 0.0;
    }

    public static func DoctrineBreakMult(tier: Int32) -> Float {
        if tier == 0 { return 0.7; }
        if tier == 1 { return 0.85; }
        if tier == 3 { return 1.2; }
        return 1.0;
    }

    public static func DecimationDamp(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 1.0; }
        if rarityVal == 1 { return 0.9; }
        if rarityVal == 2 { return 0.8; }
        if rarityVal == 3 { return 0.6; }
        if rarityVal <= 5 { return 0.4; }
        return 0.0;
    }

    public static func RollFears(rarityVal: Int32) -> Int32 {
        let roll = RandF();
        let fearCount: Int32 = 2;

        if rarityVal <= 0 {
            if roll < 0.05 { fearCount = 0; }
            else if roll < 0.15 { fearCount = 1; }
        } else if rarityVal == 1 {
            if roll < 0.10 { fearCount = 0; }
            else if roll < 0.35 { fearCount = 1; }
        } else if rarityVal == 2 {
            if roll < 0.25 { fearCount = 0; }
            else if roll < 0.65 { fearCount = 1; }
        } else if rarityVal == 3 {
            if roll < 0.55 { fearCount = 0; }
            else if roll < 0.90 { fearCount = 1; }
        } else if rarityVal == 4 {
            if roll < 0.80 { fearCount = 0; }
            else if roll < 0.95 { fearCount = 1; }
        } else if rarityVal == 5 {
            if roll < 0.90 { fearCount = 0; }
            else { fearCount = 1; }
        } else {
            if roll < 0.95 { fearCount = 0; }
            else { fearCount = 1; }
        }

        if fearCount == 0 { return 80; }

        let fear1 = RandRange(1, 8);
        let fear2: Int32 = 0;
        if fearCount >= 2 {
            fear2 = RandRange(1, 8);
            if fear2 == fear1 { fear2 = (fear1 % 7) + 1; }
        }
        return fear1 * 10 + fear2;
    }

    public static func GetBaseWound(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.08; }
        if rarityVal == 1 { return 0.06; }
        if rarityVal == 2 { return 0.04; }
        if rarityVal == 3 { return 0.03; }
        if rarityVal == 4 { return 0.02; }
        if rarityVal == 5 { return 0.01; }
        return 0.005;
    }

    public static func AttackRecordStr(attackData: ref<AttackData>) -> String {
        let def: ref<IAttack> = attackData.GetAttackDefinition();
        if !IsDefined(def) { return ""; }
        let rec: ref<Attack_Record> = def.GetRecord();
        if !IsDefined(rec) { return ""; }
        return StrLower(TDBID.ToStringDEBUG(rec.GetID()));
    }

    public static func GetAttackFearType(attackData: ref<AttackData>) -> Int32 {
        let attackType = attackData.GetAttackType();

        if Equals(attackType, gamedataAttackType.Hack) || attackData.HasFlag(hitFlag.QuickHack) {
            let qhStr: String = GBPSystem.AttackRecordStr(attackData);
            if StrContains(qhStr, "overheat") || StrContains(qhStr, "burn") { return 5; }
            if StrContains(qhStr, "overload") || StrContains(qhStr, "brainmelt") || StrContains(qhStr, "shortcircuit") || StrContains(qhStr, "synapse") { return 7; }
            if StrContains(qhStr, "contagion") || StrContains(qhStr, "poison") { return 6; }
            return 9;
        }

        let weapon = attackData.GetWeapon();
        let itemType: gamedataItemType = gamedataItemType.Invalid;
        if IsDefined(weapon) { itemType = RPGManager.GetItemType(weapon.GetItemID()); }

        if Equals(attackType, gamedataAttackType.Explosion) || Equals(itemType, gamedataItemType.Cyb_Launcher) {
            let boomStr: String = GBPSystem.AttackRecordStr(attackData);
            if StrContains(boomStr, "incendiary") || StrContains(boomStr, "thermal") { return 5; }
            if StrContains(boomStr, "biohaz") || StrContains(boomStr, "biotech") || StrContains(boomStr, "chemical") { return 6; }
            if StrContains(boomStr, "emp") { return 7; }
            return 4;
        }

        if Equals(itemType, gamedataItemType.Wea_Katana) || Equals(itemType, gamedataItemType.Wea_Knife)
            || Equals(itemType, gamedataItemType.Wea_ShortBlade) || Equals(itemType, gamedataItemType.Wea_LongBlade)
            || Equals(itemType, gamedataItemType.Wea_Machete) || Equals(itemType, gamedataItemType.Wea_Sword)
            || Equals(itemType, gamedataItemType.Wea_Chainsword) || Equals(itemType, gamedataItemType.Cyb_MantisBlades)
            || Equals(itemType, gamedataItemType.Cyb_NanoWires) || Equals(itemType, gamedataItemType.Wea_Axe) {
            return 1;
        }
        if GBPSystem.ArchetypeFromItemType(itemType) == 7 || AttackData.IsMelee(attackType) { return 2; }
        if Equals(itemType, gamedataItemType.Wea_Shotgun) || Equals(itemType, gamedataItemType.Wea_ShotgunDual) { return 3; }

        return 0;
    }

    public static func AttackMatchesFear(attackFear: Int32, fear1: Int32, fear2: Int32, isHack: Bool) -> Bool {
        if attackFear <= 0 { return false; }
        if attackFear == fear1 || attackFear == fear2 { return true; }
        if isHack && (fear1 == 9 || fear2 == 9) { return true; }
        return false;
    }

    public static func ComputeProfileFearWound(profile: ref<GBPProfile>, attackData: ref<AttackData>, rarityVal: Int32, fear1: Int32, fear2: Int32) -> Float {
        if !IsDefined(profile) || !IsDefined(attackData) {
            return GBPSystem.GetBaseWound(rarityVal);
        }
        let moraleType = GBPSystem.AttackDataToMoraleType(attackData);
        let base = profile.GetMoraleWound(moraleType, rarityVal);

        if fear1 == 8 { return base * 0.2; }

        if fear1 <= 0 { return base; }

        let attackFear = GBPSystem.GetAttackFearType(attackData);
        let isHack = moraleType == 2;
        if GBPSystem.AttackMatchesFear(attackFear, fear1, fear2, isHack) {
            return base * 3.0;
        }
        return base * 0.5;
    }

    public static func GetFearDisplay(fear1: Int32, fear2: Int32) -> String {
        if fear1 == 8 { return "FEARLESS"; }
        if fear1 <= 0 { return "Unknown"; }
        let text = GBPSystem.GetFearName(fear1);
        if fear2 > 0 { text = text + ", " + GBPSystem.GetFearName(fear2); }
        return text;
    }

    public static func TraitFormationFighter() -> Int32 = 1
    public static func TraitRusher()           -> Int32 = 2
    public static func TraitCoward()           -> Int32 = 4
    public static func TraitShowOff()          -> Int32 = 8
    public static func TraitCyberJunkie()      -> Int32 = 16
    public static func TraitOpportunist()      -> Int32 = 32
    public static func TraitPackTactics()      -> Int32 = 64
    public static func TraitSolo()             -> Int32 = 128
    
    public static func TraitSteady()           -> Int32 = 256
    
    public static func TraitCautious()         -> Int32 = 512

    public static func ParseTraitString(traitStr: String) -> Int32 {
        if StrLen(traitStr) == 0 { return 0; }
        let lower = StrLower(traitStr);
        let flags: Int32 = 0;
        if StrContains(lower, "formation") { flags += GBPSystem.TraitFormationFighter(); }
        if StrContains(lower, "steady") { flags += GBPSystem.TraitSteady(); }
        if StrContains(lower, "rusher") { flags += GBPSystem.TraitRusher(); }
        if StrContains(lower, "coward") { flags += GBPSystem.TraitCoward(); }
        if StrContains(lower, "cautious") { flags += GBPSystem.TraitCautious(); }
        if StrContains(lower, "show_off") || StrContains(lower, "showoff") { flags += GBPSystem.TraitShowOff(); }
        if StrContains(lower, "cyber_junkie") || StrContains(lower, "junkie") { flags += GBPSystem.TraitCyberJunkie(); }
        if StrContains(lower, "opportunist") { flags += GBPSystem.TraitOpportunist(); }
        if StrContains(lower, "pack_tactics") { flags += GBPSystem.TraitPackTactics(); }
        if StrContains(lower, "solo") { flags += GBPSystem.TraitSolo(); }
        return flags;
    }

    public static func HasTrait(traits: Int32, trait: Int32) -> Bool {
        return (traits / trait) % 2 == 1;
    }

    public func CountSameFactionAlliesNearby(self: wref<ScriptedPuppet>, range: Float) -> Int32 {
        if !IsDefined(self) { return 0; }
        let count: Int32 = 0;
        let selfPos: Vector4 = self.GetWorldPosition();
        let selfFaction: Int32 = GBPStateOf(self).GBP_factionIndex;
        let selfID: EntityID = self.GetEntityID();
        let i: Int32 = 0;
        while i < ArraySize(this.m_trackedPuppets) {
            let other = this.m_trackedPuppets[i];
            if !GBPIsCorpse(other) && !Equals(other.GetEntityID(), selfID) {
                if GBPStateOf(other).GBP_factionCached && GBPStateOf(other).GBP_factionIndex == selfFaction {
                    let dist: Float = Vector4.Distance(other.GetWorldPosition(), selfPos);
                    if dist <= range {
                        count += 1;
                    }
                }
            }
            i += 1;
        }
        return count;
    }

    public static func GetCurrentDistrictName(gi: GameInstance) -> String {
        let player = GetPlayer(gi);
        if !IsDefined(player) { return ""; }
        let prevSys = player.GetPreventionSystem();
        if !IsDefined(prevSys) { return ""; }
        let district = prevSys.GetCurrentDistrict();
        if !IsDefined(district) { return ""; }
        
        let record: wref<District_Record> = district.GetDistrictRecord();
        let chain: String = "";
        let depth: Int32 = 0;
        while IsDefined(record) && depth < 4 {
            chain = chain + record.EnumName() + " ";
            record = record.ParentDistrict();
            depth += 1;
        };
        return chain;
    }

    public static func GetFearName(fearType: Int32) -> String {
        switch fearType {
            case 1: return "Blades";
            case 2: return "Blunt";
            case 3: return "Shotguns";
            case 4: return "Explosives";
            case 5: return "Fire";
            case 6: return "Chemical";
            case 7: return "Electric";
            case 9: return "Hacking";
            default: return "None";
        }
    }

    public static func ParseFearToken(token: String) -> Int32 {
        let t = StrLower(token);
        if StrContains(t, "blade") { return 1; }
        if StrContains(t, "blunt") { return 2; }
        if StrContains(t, "shotgun") { return 3; }
        if StrContains(t, "explo") { return 4; }
        if StrContains(t, "fire") { return 5; }
        if StrContains(t, "chem") { return 6; }
        if StrContains(t, "electric") || StrContains(t, "emp") { return 7; }
        if StrContains(t, "hack") { return 9; }
        return 0;
    }

    public static func RollFearsFromProfile(factionIndex: Int32, rarityVal: Int32) -> Int32 {
        let profile = GBPProfiles.GetProfile(factionIndex);
        if !IsDefined(profile) { return GBPSystem.RollFears(rarityVal); }

        let fearStr = profile.GetFears(rarityVal);
        if StrLen(fearStr) == 0 { return GBPSystem.RollFears(rarityVal); }
        if StrContains(StrLower(fearStr), "none") { return 80; }

        let tokens: array<String>;
        let buf: String = "";
        let i: Int32 = 0;
        let total: Int32 = StrLen(fearStr);
        while i < total {
            let ch: String = StrMid(fearStr, i, 1);
            if Equals(ch, ",") {
                ArrayPush(tokens, buf);
                buf = "";
            } else if !Equals(ch, " ") {
                buf = buf + ch;
            }
            i += 1;
        }
        if StrLen(buf) > 0 { ArrayPush(tokens, buf); }

        let ids: array<Int32>;
        let k: Int32 = 0;
        while k < ArraySize(tokens) {
            let id = GBPSystem.ParseFearToken(tokens[k]);
            if id > 0 && !ArrayContains(ids, id) { ArrayPush(ids, id); }
            k += 1;
        }

        let count = ArraySize(ids);
        if count == 0 { return GBPSystem.RollFears(rarityVal); }
        if count == 1 { return ids[0] * 10; }

        let pickA: Int32 = RandRange(0, count);
        let pickB: Int32 = RandRange(0, count);
        while pickB == pickA { pickB = (pickB + 1) % count; }
        return ids[pickA] * 10 + ids[pickB];
    }

    public static func AttackDataToMoraleType(attackData: ref<AttackData>) -> Int32 {
        if !IsDefined(attackData) { return 1; }
        let attackType = attackData.GetAttackType();
        if Equals(attackType, gamedataAttackType.Hack) || attackData.HasFlag(hitFlag.QuickHack) { return 2; }
        
        if AttackData.IsMelee(attackType) || Equals(attackType, gamedataAttackType.WhipAttack)
            || Equals(attackType, gamedataAttackType.ChargedWhipAttack) { return 0; }

        if Equals(attackType, gamedataAttackType.Explosion) { return 3; }
        let weapon = attackData.GetWeapon();
        if IsDefined(weapon) && Equals(RPGManager.GetItemType(weapon.GetItemID()), gamedataItemType.Cyb_Launcher) { return 3; }
        return 1;
    }

}
