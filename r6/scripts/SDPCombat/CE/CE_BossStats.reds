module SDPCE

// Per-boss stat blocks. The designed numbers live HERE, not in the settings menu. (⌐■_■)

public class GBPBossStat {
    public let id: Int32;             
    public let hp: Float;             
    public let armor: Float;          
    public let dmg: Float;            
    public let repairCharges: Int32;
    public let repairAmount: Float;
    public let label: String;
}

public abstract class GBPBossStats {

    private static func Make(id: Int32, hp: Float, armor: Float, dmg: Float,
                             charges: Int32, amount: Float, label: String) -> ref<GBPBossStat> {
        let s = new GBPBossStat();
        s.id = id; s.hp = hp; s.armor = armor; s.dmg = dmg;
        s.repairCharges = charges; s.repairAmount = amount; s.label = label;
        return s;
    }

    public static func For(recordStr: String) -> ref<GBPBossStat> {
        if GBPSystem.IsExcludedBossRecord(recordStr) { return null; };

        if StrContains(recordStr, "q113_boss_smasher") || StrContains(recordStr, "q116_boss_smasher")
            || StrContains(recordStr, "main_boss_adam_smasher") || Equals(recordStr, "Character.Smasher") {
            return GBPBossStats.Make(0, 840.0, 3000.0, 1.50, 3, 60.0, "Smasher");
        };
        if StrContains(recordStr, "boss_oda") || StrContains(recordStr, "Cyberninja_Oda") {
            return GBPBossStats.Make(1, 720.0, 1200.0, 1.50, 2, 40.0, "Oda");
        };
        
        if StrContains(recordStr, "q003_royce_boss") || StrContains(recordStr, "boss_royce") {
            return GBPBossStats.Make(2, 504.0, 1500.0, 1.50, 1, 50.0, "Royce");
        };
        if StrContains(recordStr, "boss_sasquatch") {
            return GBPBossStats.Make(3, 1344.0, 800.0, 1.50, 2, 50.0, "Sasquatch");
        };
        
        if StrContains(recordStr, "Character.Woodman") || StrContains(recordStr, "sq026_woodman") {
            return GBPBossStats.Make(8, 400.0, 250.0, 1.00, 0, 0.0, "Woodman");
        };
        
        if StrContains(recordStr, "Character.Placide") {
            return GBPBossStats.Make(9, 500.0, 400.0, 1.15, 0, 0.0, "Placide");
        };

        if StrContains(recordStr, "q304_kurt_miniboss") || StrContains(recordStr, "mq304_kurt") {
            return GBPBossStats.Make(4, 1080.0, 1000.0, 1.50, 2, 50.0, "Kurt");
        };
        if StrContains(recordStr, "boss_chimera") {
            return GBPBossStats.Make(5, 1080.0, 4000.0, 1.50, 4, 75.0, "Chimera");
        };
        if StrContains(recordStr, "sts_ep1_08_kgb_boss") {
            return GBPBossStats.Make(6, 510.0, 500.0, 1.50, 1, 40.0, "Ribakov");
        };
        if StrContains(recordStr, "sts_ep1_03_miniboss_placeholder") {
            return GBPBossStats.Make(7, 510.0, 700.0, 1.50, 1, 40.0, "Yasha");
        };
        if StrContains(recordStr, "sts_ep1_12_droid_miniboss") {
            return GBPBossStats.Make(10, 800.0, 1200.0, 1.30, 2, 60.0, "R Mk.2");
        };
        
        if StrContains(recordStr, "q305_maxtac_miniboss_sniper") {
            return GBPBossStats.Make(11, 384.0, 800.0, 1.40, 0, 0.0, "MaxTac operator");
        };
        if StrContains(recordStr, "we_ep1_05_mini_boss") {
            return GBPBossStats.Make(12, 500.0, 350.0, 1.20, 0, 0.0, "Ayo Zarin");
        };
        
        if StrContains(recordStr, "we_ep1_17_miniboss") {
            return GBPBossStats.Make(13, 650.0, 900.0, 1.35, 1, 50.0, "MRS-071 Drone");
        };
        
        if StrContains(recordStr, "ma_wbr_nok_05_outpost_miniboss") {
            return GBPBossStats.Make(14, 600.0, 1000.0, 1.25, 1, 50.0, "Militech Mech");
        };

        return null;
    }
}
