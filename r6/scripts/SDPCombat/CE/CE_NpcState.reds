module SDPCE

// CE per-NPC state, lazy-allocated. ┻━┻ ︵ヽ(`Д´)ﾉ︵ ┻━┻

public class GBPNpcState {
    public let GBP_factionCached: Bool;
    public let GBP_factionIndex: Int32;
    public let GBP_initAttempted: Bool;
    public let GBP_rarityVal: Int32;
    public let GBP_fear1: Int32;
    public let GBP_fear2: Int32;
    public let GBP_moraleWound: Float;
    public let GBP_unbreakable: Bool;
    public let GBP_shouldFlee: Bool;
    
    public let GBP_cower: Bool;
    
    public let GBP_fleeDispatching: Bool;
    
    public let GBP_nerveGone: Int32;
    
    public let GBP_fleeSeenPos: Vector4;
    
    public let GBP_watchGen: Int32;
    public let GBP_appliedArmor: Float;
    public let GBP_armorIntegrity: Float;
    public let GBP_thermalResist: Float;
    public let GBP_electricResist: Float;
    public let GBP_chemicalResist: Float;
    public let GBP_hackingResist: Float;
    public let GBP_ramCostAdd: Float;
    public let GBP_uploadTimeAdd: Float;
    public let GBP_headshotMult: Float;
    public let GBP_hasHelmet: Bool;
    public let GBP_helmetArmorValue: Int32;
    public let GBP_leftArmCrippled: Bool;
    public let GBP_rightArmCrippled: Bool;
    public let GBP_leftLegCrippled: Bool;
    public let GBP_rightLegCrippled: Bool;
    public let GBP_incapacitated: Bool;
    public let GBP_primaryDropped: Bool;
    public let GBP_detectionRolled: Bool;
    public let GBP_traits: Int32;
    public let GBP_districtFearMod: Float;
    public let GBP_healsScanned: Bool;
    public let GBP_healsRemaining: Int32;
    public let GBP_healOnCooldown: Bool;
    public let GBP_isBoss: Bool;
    public let GBP_armorRepairCharges: Int32;
    public let GBP_armorRepairAmount: Float;
    public let GBP_armorRepairOnCooldown: Bool;
    public let GBP_modAccuracyProfile: ref<gameStatModifierData>;
    public let GBP_modAccuracyTrait: ref<gameStatModifierData>;
    public let GBP_modAccuracyCripple: ref<gameStatModifierData>;
    public let GBP_modSpeedProfile: ref<gameStatModifierData>;
    public let GBP_modSpeedRusher: ref<gameStatModifierData>;
    public let GBP_modSpeedShowOff: ref<gameStatModifierData>;
    public let GBP_modAccuracyPackTactics: ref<gameStatModifierData>;
    public let GBP_modSpeedCripple: ref<gameStatModifierData>;
    public let GBP_modHealthProfile: ref<gameStatModifierData>;
    public let GBP_modHealthBoss: ref<gameStatModifierData>;
    public let GBP_modArmor: ref<gameStatModifierData>;
    public let GBP_modThermalR: ref<gameStatModifierData>;
    public let GBP_modElectricR: ref<gameStatModifierData>;
    public let GBP_modChemicalR: ref<gameStatModifierData>;
    public let GBP_modHeadshotMult: ref<gameStatModifierData>;
    public let GBP_modBossDmg: ref<gameStatModifierData>;
    public let GBP_chromeApplied: Bool;
    
    public let GBP_chromeAbilities: array<TweakDBID>;
    
    
    public let GBP_orderGen: Int32;        
    public let GBP_orderPhase: Int32;      
    public let GBP_orderOwner: CName;       
    public let GBP_orderBaseline: Vector4;  
    public let GBP_orderTarget: Vector4;    
    public let GBP_orderCoverId: Uint64;    
    public let GBP_orderReacquired: Bool;   
    
    public let GBP_coverBreakReaction: Float;  
    public let GBP_coverEjectPending: Bool;    
    
    public let GBP_flankOnCooldown: Bool;
    
    public let GBP_suppressPressure: Float;   
    public let GBP_suppressStamp: Float;      
    public let GBP_pinnedUntil: Float;        
    public let GBP_pinReadyAt: Float;         
    public let GBP_suppressUntil: Float;      
    public let GBP_suppressReadyAt: Float;    
    public let GBP_orderCmd: ref<AIMoveToCommand>;   
    
    public let GBP_bossStyle: Int32;
    
    public let GBP_modCatchUpStrip: ref<gameStatModifierData>;
    public let GBP_modCatchUpDistStrip: ref<gameStatModifierData>;
    
    public let GBP_modDoctrineDmg: ref<gameStatModifierData>;
    
    public let GBP_tracked: Bool;
    public let GBP_resetGen: Int32;
    
    public let GBP_isFemale: Bool;
}

@addField(ScriptedPuppet) public let sdpceState: ref<GBPNpcState>;

public static func GBPStateOf(puppet: ref<ScriptedPuppet>) -> ref<GBPNpcState> {
    if IsDefined(puppet) && IsDefined(puppet.sdpceState) {
        return puppet.sdpceState;
    }
    if IsDefined(puppet) {
        let sys: ref<GBPSystem> = GBPSystem.Get(puppet.GetGame());
        if IsDefined(sys) {
            return sys.GetDefaultState();
        }
    }
    return new GBPNpcState();
}

public static func GBPEnsureState(puppet: ref<ScriptedPuppet>) -> ref<GBPNpcState> {
    if !IsDefined(puppet) {
        return new GBPNpcState();
    }
    if !IsDefined(puppet.sdpceState) {
        puppet.sdpceState = new GBPNpcState();
    }
    return puppet.sdpceState;
}

public static func GBPSeedFrac(entityID: EntityID, salt: Int32) -> Float {
    let h: Int32 = Cast<Int32>(EntityID.GetHash(entityID));
    if h < 0 { h = -(h + 1); }
    let x: Int32 = (h % 100000) * (31 + salt * 6) + salt * 7919;
    if x < 0 { x = -(x + 1); }
    return Cast<Float>(x % 1000) / 999.0;
}

public static func GBPSeedOffset(entityID: EntityID, salt: Int32, amplitude: Float) -> Float {
    return (GBPSeedFrac(entityID, salt) * 2.0 - 1.0) * amplitude;
}

public static func GBPSeedMult(entityID: EntityID, salt: Int32, amplitude: Float) -> Float {
    return 1.0 + GBPSeedOffset(entityID, salt, amplitude);
}

public static func GBPSaltHealth() -> Int32   = 1
public static func GBPSaltArmor() -> Int32    = 2
public static func GBPSaltThermal() -> Int32  = 3
public static func GBPSaltElectric() -> Int32 = 4
public static func GBPSaltChemical() -> Int32 = 5
public static func GBPSaltHacking() -> Int32  = 6

private static func GBPHasBodyToken(s: String, tok: String) -> Bool {
    return StrContains(s, "_" + tok + "_")
        || StrBeginsWith(s, tok + "_")
        || StrEndsWith(s, "_" + tok);
}

private static func GBPNameSaysFemale(s: String) -> Bool {
    return GBPHasBodyToken(s, "wa") || GBPHasBodyToken(s, "wb") || GBPHasBodyToken(s, "wf");
}

private static func GBPNameSaysMale(s: String) -> Bool {
    return GBPHasBodyToken(s, "ma") || GBPHasBodyToken(s, "mb") || GBPHasBodyToken(s, "mf");
}

public static func GBPIsFemalePuppet(puppet: ref<ScriptedPuppet>) -> Bool {
    if !IsDefined(puppet) { return false; }
    let app: String = StrLower(NameToString(puppet.GetCurrentAppearanceName()));
    if GBPNameSaysFemale(app) { return true; }
    if GBPNameSaysMale(app) { return false; }
    
    let rec: String = StrLower(TDBID.ToStringDEBUG(puppet.GetRecordID()));
    if StrContains(rec, "female") { return true; }
    if StrContains(rec, "male") { return false; }
    if GBPNameSaysFemale(rec) { return true; }
    return false;   
}

// struct builders that compile on both redscript 0.5 and 1.0 (CE used `new Vector4(...)`)
public static func GBPV4(x: Float, y: Float, z: Float, w: Float) -> Vector4 {
    let v: Vector4;
    v.X = x; v.Y = y; v.Z = z; v.W = w;
    return v;
}

public static func GBPV3(x: Float, y: Float, z: Float) -> Vector3 {
    let v: Vector3;
    v.X = x; v.Y = y; v.Z = z;
    return v;
}
