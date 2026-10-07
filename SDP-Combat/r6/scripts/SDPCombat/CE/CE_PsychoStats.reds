module SDPCE

// Per-cyberpsycho stat blocks. Seventeen individuals, not one group. (⌐■_■)

public class GBPPsychoStat {
    public let hp: Float;
    public let armor: Float;
    public let dmg: Float;
    public let profileIndex: Int32;   
    public let known: Bool;
}

public abstract class GBPPsychoBehaviour {
    public static func Berserker() -> Int32 { return 20; }   
    public static func Anchor() -> Int32 { return 22; }      
    public static func Rusher() -> Int32 { return 23; }      
    public static func Gunner() -> Int32 { return 24; }      
    public static func Sniper() -> Int32 { return 25; }      
    public static func Netrunner() -> Int32 { return 26; }   
}

public abstract class GBPPsychoStats {

    public static func Fallback() -> ref<GBPPsychoStat> {
        let s = new GBPPsychoStat();
        s.hp = 460.0; s.armor = 450.0; s.dmg = 1.15;
        s.profileIndex = GBPPsychoBehaviour.Berserker();
        s.known = false;
        return s;
    }

    private static func Make(hp: Float, armor: Float, dmg: Float, behaviour: Int32) -> ref<GBPPsychoStat> {
        let s = new GBPPsychoStat();
        s.hp = hp; s.armor = armor; s.dmg = dmg; s.profileIndex = behaviour; s.known = true;
        return s;
    }

    public static func For(recordStr: String) -> ref<GBPPsychoStat> {
        let r: String = StrLower(recordStr);

        if StrContains(r, "ma_std_rcr_11") { return GBPPsychoStats.Make(700.0, 1400.0, 1.30, GBPPsychoBehaviour.Anchor()); }   
        if StrContains(r, "ma_bls_ina_se1_07") { return GBPPsychoStats.Make(700.0, 1400.0, 1.30, GBPPsychoBehaviour.Anchor()); } 

        if StrContains(r, "ma_wat_lch_06") { return GBPPsychoStats.Make(620.0, 900.0, 1.20, GBPPsychoBehaviour.Berserker()); }    

        if StrContains(r, "ma_bls_ina_se1_08") { return GBPPsychoStats.Make(540.0, 640.0, 1.20, GBPPsychoBehaviour.Rusher()); } 
        if StrContains(r, "ma_cct_dtn_03") { return GBPPsychoStats.Make(520.0, 620.0, 1.15, GBPPsychoBehaviour.Rusher()); }    
        if StrContains(r, "ma_pac_cvi_08") { return GBPPsychoStats.Make(520.0, 600.0, 1.15, GBPPsychoBehaviour.Rusher()); }    
        if StrContains(r, "ma_wat_nid_22") { return GBPPsychoStats.Make(520.0, 600.0, 1.15, GBPPsychoBehaviour.Rusher()); }    

        if StrContains(r, "ma_wat_kab_08") { return GBPPsychoStats.Make(560.0, 520.0, 1.25, GBPPsychoBehaviour.Berserker()); }    

        if StrContains(r, "ma_wat_nid_03") { return GBPPsychoStats.Make(500.0, 420.0, 1.10, GBPPsychoBehaviour.Berserker()); }    

        if StrContains(r, "ma_hey_spr_06") { return GBPPsychoStats.Make(460.0, 450.0, 1.10, GBPPsychoBehaviour.Gunner()); }    

        if StrContains(r, "ma_hey_spr_04") { return GBPPsychoStats.Make(440.0, 400.0, 1.25, GBPPsychoBehaviour.Gunner()); }    

        if StrContains(r, "ma_cct_dtn_07") { return GBPPsychoStats.Make(430.0, 340.0, 1.35, GBPPsychoBehaviour.Berserker()); }    
        if StrContains(r, "ma_wat_nid_15") { return GBPPsychoStats.Make(420.0, 320.0, 1.40, GBPPsychoBehaviour.Berserker()); }    

        if StrContains(r, "ma_wat_kab_02") { return GBPPsychoStats.Make(380.0, 320.0, 1.50, GBPPsychoBehaviour.Sniper()); }    
        if StrContains(r, "ma_bls_ina_se1_22") { return GBPPsychoStats.Make(380.0, 320.0, 1.45, GBPPsychoBehaviour.Sniper()); } 

        if StrContains(r, "ma_pac_cvi_15") { return GBPPsychoStats.Make(350.0, 260.0, 1.00, GBPPsychoBehaviour.Netrunner()); }    
        if StrContains(r, "ma_std_arr_06") { return GBPPsychoStats.Make(340.0, 250.0, 1.00, GBPPsychoBehaviour.Netrunner()); }    

        return GBPPsychoStats.Fallback();
    }
}
