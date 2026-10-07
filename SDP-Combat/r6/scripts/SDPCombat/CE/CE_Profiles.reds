module SDPCE
// GBP_Profiles - faction combat profiles ╾━╤デ╦︻ (•_- )

public abstract class GBPArchetypeMults {

    public static func AccuracyMult(arch: Int32) -> Float {
        if arch == 1 { return 0.80; };  
        if arch == 2 { return 0.90; };  
        if arch == 3 { return 1.10; };  
        if arch == 4 { return 1.30; };  
        if arch == 5 { return 0.70; };  
        if arch == 6 { return 0.90; };  
        if arch == 7 { return 0.50; };  
        if arch == 8 { return 1.15; };  
        return 1.0;
    }

    public static func SpeedMult(arch: Int32) -> Float {
        if arch == 1 { return 1.10; };
        if arch == 2 { return 1.00; };
        if arch == 3 { return 0.85; };
        if arch == 4 { return 0.60; };  
        if arch == 5 { return 0.80; };
        if arch == 6 { return 0.50; };  
        if arch == 7 { return 1.80; };  
        if arch == 8 { return 0.90; };
        return 1.0;
    }

    public static func HealthMult(arch: Int32) -> Float {
        if arch == 1 { return 1.20; };
        if arch == 2 { return 1.05; };
        if arch == 3 { return 1.00; };
        if arch == 4 { return 0.80; };  
        if arch == 5 { return 0.70; };  
        if arch == 6 { return 1.40; };  
        if arch == 7 { return 1.30; };  
        if arch == 8 { return 1.20; };
        return 1.0;
    }

    public static func ArmorMult(arch: Int32) -> Float {
        if arch == 1 { return 1.10; };
        if arch == 2 { return 0.95; };
        if arch == 3 { return 1.00; };
        if arch == 4 { return 0.70; };
        if arch == 5 { return 0.50; };  
        if arch == 6 { return 1.50; };  
        if arch == 7 { return 0.80; };
        if arch == 8 { return 1.30; };  
        return 1.0;
    }

    public static func HackingResistBonus(arch: Int32) -> Float {
        if arch == 5 { return 25.0; };
        return 0.0;
    }
}

public abstract class GBPProfile {

    protected let cfgAcc: Float;
    protected let cfgSpd: Float;
    protected let cfgHp: Float;
    protected let cfgArmorMin: Float;
    protected let cfgArmorMax: Float;
    protected let cfgRarityScale: Float;
    protected let cfgLoaded: Bool;

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetRamCostAdd(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetUploadTimeAdd(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { return 0.0; }
    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float { return 0.02; }
    public func GetFears(rarityVal: Int32) -> String { return ""; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.0; }

    protected func DetectionRarityScale(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 1.0; }
        if rarityVal == 1 { return 0.5; }
        if rarityVal == 2 { return 0.2; }
        return 0.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return ""; }

    public func GetDistrictFearModifier(districtStr: String) -> Float { return 1.0; }

    public func GetDoctrineTier() -> Int32 { return 1; }

    public func GetFlankChance(rarityVal: Int32) -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 && rarityVal >= 1 { return 0.4; };
        if tier == 1 && rarityVal >= 2 { return 0.3; };
        if tier == 2 && rarityVal >= 3 { return 0.2; };
        return 0.0;
    }
    public func GetFlankCooldownMin() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 6.0; };
        if tier == 2 { return 10.0; };
        if tier == 3 { return 12.0; };
        return 8.0;
    }
    public func GetFlankCooldownMax() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 10.0; };
        if tier == 2 { return 16.0; };
        if tier == 3 { return 18.0; };
        return 14.0;
    }
    
    public func GetCoverEjectThreshold(rarityVal: Int32) -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 4 { return 0.0; };
        if rarityVal < 1 { return 0.0; };
        if tier == 0 { return 0.25; };
        if tier == 2 { return 0.5; };
        if tier == 3 { return 0.55; };
        return 0.38;
    }
    public func GetCoverReactionMin() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 1.0; };
        if tier == 3 { return 3.0; };
        return 2.0;
    }
    public func GetCoverReactionMax() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 4.0; };
        if tier == 1 { return 6.0; };
        if tier == 2 { return 8.0; };
        return 10.0;
    }
    
    public func GetFleeWoundThreshold() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.65; };
        if tier == 2 { return 0.42; };
        if tier == 3 { return 0.35; };
        if tier == 4 { return 9.99; };   
        return 0.5;
    }
    
    public func GetIntentPanicMult() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.8; };
        if tier == 2 { return 0.64; };
        if tier == 3 { return 0.6; };
        if tier == 4 { return 1.0; };
        return 0.72;
    }
    public func GetIntentRepositionMult() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.9; };
        if tier == 2 { return 0.82; };
        if tier == 3 { return 0.8; };
        if tier == 4 { return 1.0; };
        return 0.86;
    }
    public func GetIntentAnchorMult() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 1.08; };
        if tier == 2 { return 1.02; };
        if tier == 3 || tier == 4 { return 1.0; };
        return 1.06;
    }

    public func GetPinThreshold() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 5.5; };
        if tier == 2 { return 3.5; };
        if tier == 3 { return 2.5; };
        if tier == 4 { return 99.0; };   
        return 4.0;
    }
    public func GetPinDuration() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 1.6; };
        if tier == 2 { return 2.8; };
        if tier == 3 { return 3.5; };
        if tier == 4 { return 0.0; };
        return 2.4;
    }
    public func GetPinCooldown() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 9.0; };
        if tier == 2 { return 6.0; };
        if tier == 3 { return 5.0; };
        if tier == 4 { return 99.0; };
        return 7.0;
    }
    
    public func GetPinMoraleDrip() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.04; };
        if tier == 2 { return 0.12; };
        if tier == 3 { return 0.16; };
        if tier == 4 { return 0.0; };
        return 0.08;
    }
    public func GetIntentPinnedMult() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.75; };
        if tier == 2 { return 0.58; };
        if tier == 3 { return 0.52; };
        if tier == 4 { return 1.0; };
        return 0.66;
    }

    public func GetSuppressorChance() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.75; };
        if tier == 1 { return 0.5; };
        if tier == 2 { return 0.25; };
        return 0.0;   
    }
    public func GetIntentSuppressMult() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 0.72; };
        if tier == 2 { return 0.62; };
        if tier == 3 || tier == 4 { return 1.0; };
        return 0.68;
    }

    public func GetGuardBreakEligible(rarityVal: Int32) -> Bool {
        if rarityVal < 2 { return false; };
        return this.GetDoctrineTier() <= 2;   
    }

    public func GetGrappleBase() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 5.0; };
        if tier == 1 { return 12.0; };
        if tier == 2 { return 18.0; };
        if tier == 3 { return 30.0; };
        return 0.0;   
    }
    public func GetGrapplePerRarity() -> Float {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 0 { return 1.1; };
        if tier == 2 { return 1.8; };
        if tier == 3 { return 2.5; };
        return 1.4;
    }

    public func GetStyleAbilities(arch: GBPChromeArchetype, rarityVal: Int32) -> array<TweakDBID> {
        let out: array<TweakDBID>;
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 4 { return out; };   
        
        if Equals(arch, GBPChromeArchetype.Sniper) || Equals(arch, GBPChromeArchetype.HeavyRanged)
          || Equals(arch, GBPChromeArchetype.Netrunner) {
            ArrayPush(out, t"Ability.PrefersCovers");
            return out;
        };
        if tier == 0 && GBPCapability.IsRangedArchetype(arch) {
            ArrayPush(out, t"Ability.PrefersCovers");
        };
        if tier == 2 && GBPCapability.IsMeleeArchetype(arch) {
            ArrayPush(out, t"Ability.CanSprintHarass");
        };
        return out;
    }

    public func GetCatchUpPolicy() -> Int32 {
        let tier: Int32 = this.GetDoctrineTier();
        if tier == 2 || tier == 3 { return 2; };   
        return 1;
    }

    public func GetNPCDamageMult() -> Float { return 1.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
    }
}

public abstract class GBPProfiles {
    public static func GetProfile(factionIndex: Int32) -> ref<GBPProfile> {
        let system: ref<GBPSystem> = GBPSystem.Get(GetGameInstance());
        if IsDefined(system) {
            let cached: ref<GBPProfile> = system.GetCachedProfile(factionIndex);
            if IsDefined(cached) { return cached; }
        }
        switch factionIndex {
            case 0:  return new GBPMaelstromProfile();
            case 1:  return new GBPTygerClawsProfile();
            case 2:  return new GBPAnimalsProfile();
            case 3:  return new GBPScavengerProfile();
            case 4:  return new GBPValentinosProfile();
            case 5:  return new GBPVoodooBoysProfile();
            case 6:  return new GBPSixthStreetProfile();
            case 7:  return new GBPArasakaProfile();
            case 8:  return new GBPMilitechProfile();
            case 9:  return new GBPKangTaoProfile();
            case 10: return new GBPTraumaTeamProfile();
            case 11: return new GBPWraithsProfile();
            case 12: return new GBPBarghestProfile();
            case 13: return new GBPNCPDProfile();
            case 14: return new GBPMoxProfile();
            case 15: return new GBPAldecaldosProfile();
            case 16: return new GBPNetWatchProfile();
            case 17: return new GBPBiotechnicaProfile();
            case 18: return new GBPNUSAProfile();
            case 19: return new GBPAfterlifeProfile();
            case 20: return new GBPCyberpsychoProfile();
            case 21: return new GBPUnaffiliatedProfile();
            case 22: return new GBPPsychoAnchorProfile();
            case 23: return new GBPPsychoRusherProfile();
            case 24: return new GBPPsychoGunnerProfile();
            case 25: return new GBPPsychoSniperProfile();
            case 26: return new GBPPsychoNetrunnerProfile();
            default: return null;
        }
    }
}

public class GBPMaelstromProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetFleeWoundThreshold() -> Float { return 0.55; }
    
    public func GetPinThreshold() -> Float { return 4.5; }
    public func GetPinMoraleDrip() -> Float { return 0.08; }
    public func GetGrappleBase() -> Float { return 15.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.maelstromAccuracy;
        this.cfgSpd = cfg.maelstromSpeed;
        this.cfgHp = cfg.maelstromHealth;
        this.cfgArmorMin = Cast<Float>(cfg.maelstromArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.maelstromArmorMax);
        this.cfgRarityScale = cfg.maelstromRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.23;
        let scale: Float = 0.15;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.35;
        let scale: Float = 0.15;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.80;
        let scale: Float = 0.15;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 400.0;
        let aMax: Float = 1300.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 70.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 60.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 60.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.65 + (0.25 - 0.65) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Hacking, Explosives, Blunt"; }
        if rarityVal == 2 { return "Hacking, Explosives"; }
        if rarityVal == 3 { return "Hacking"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            if rarityVal == 2 { return 0.03; }
            if rarityVal == 3 { return 0.02; }
            return 0.005;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.25; }
            if rarityVal == 1 { return 0.20; }
            if rarityVal == 2 { return 0.15; }
            if rarityVal == 3 { return 0.10; }
            if rarityVal == 4 { return 0.06; }
            return 0.03;
        }
        
        if rarityVal <= 0 { return 0.20; }
        if rarityVal == 1 { return 0.16; }
        if rarityVal == 2 { return 0.12; }
        if rarityVal == 3 { return 0.08; }
        if rarityVal == 4 { return 0.04; }
        return 0.02;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Watson") { return 0.75; }
        if StrContains(districtStr, "Kabuki") { return 0.75; }
        if StrContains(districtStr, "Northside") { return 0.75; }
        if StrContains(districtStr, "LittleChina") { return 0.75; }
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        if StrContains(districtStr, "CorpoPlaza") { return 1.25; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "cyber_junkie, rusher"; }
        if rarityVal >= 3 { return "cyber_junkie, formation_fighter"; }
        return "cyber_junkie";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.05 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.15; }
        if rarityVal == 1 { return 0.08; }
        if rarityVal == 2 { return 0.04; }
        if rarityVal == 3 { return 0.01; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPTygerClawsProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 2 { return 0.34; };
        return 0.0;
    }
    public func GetCoverReactionMax() -> Float { return 5.0; }
    
    public func GetGuardBreakEligible(rarityVal: Int32) -> Bool { return rarityVal >= 1; }
    public func GetGrappleBase() -> Float { return 9.0; }
    
    public func GetStyleAbilities(arch: GBPChromeArchetype, rarityVal: Int32) -> array<TweakDBID> {
        let out: array<TweakDBID>;
        if Equals(arch, GBPChromeArchetype.Sniper) || Equals(arch, GBPChromeArchetype.HeavyRanged)
          || Equals(arch, GBPChromeArchetype.Netrunner) {
            ArrayPush(out, t"Ability.PrefersCovers");
            return out;
        };
        if GBPCapability.IsMeleeArchetype(arch) {
            ArrayPush(out, t"Ability.CanSprintHarass");
        };
        return out;
    }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.tygerClawsAccuracy;
        this.cfgSpd = cfg.tygerClawsSpeed;
        this.cfgHp = cfg.tygerClawsHealth;
        this.cfgArmorMin = Cast<Float>(cfg.tygerClawsArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.tygerClawsArmorMax);
        this.cfgRarityScale = cfg.tygerClawsRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.28;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.70;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 15.0;
        let aMax: Float = 150.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 50.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 20.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0 + (0.8 - 1.0) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Shotguns, Explosives, Chemical"; }
        if rarityVal == 2 { return "Shotguns, Explosives"; }
        if rarityVal == 3 { return "Explosives"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.10; }
            if rarityVal == 1 { return 0.08; }
            if rarityVal == 2 { return 0.06; }
            if rarityVal == 3 { return 0.03; }
            if rarityVal == 4 { return 0.02; }
            return 0.005;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.12; }
            if rarityVal == 1 { return 0.08; }
            if rarityVal == 2 { return 0.06; }
            if rarityVal == 3 { return 0.04; }
            if rarityVal == 4 { return 0.02; }
            return 0.01;
        }
        
        if rarityVal <= 0 { return 0.18; }
        if rarityVal == 1 { return 0.14; }
        if rarityVal == 2 { return 0.10; }
        if rarityVal == 3 { return 0.06; }
        if rarityVal == 4 { return 0.03; }
        return 0.015;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Westbrook") { return 0.75; }
        if StrContains(districtStr, "JapanTown") { return 0.75; }
        if StrContains(districtStr, "CharterHill") { return 0.75; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        if StrContains(districtStr, "Badlands") { return 1.25; }
        if StrContains(districtStr, "SantoDomingo") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "rusher, show_off"; }
        if rarityVal >= 3 { return "formation_fighter, show_off"; }
        return "show_off";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.08 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.10; }
        if rarityVal == 1 { return 0.05; }
        if rarityVal == 2 { return 0.02; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPAnimalsProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetCoverEjectThreshold(rarityVal: Int32) -> Float {
        if rarityVal < 1 { return 0.0; };
        return 0.6;
    }
    public func GetFlankCooldownMin() -> Float { return 8.0; }
    public func GetFlankCooldownMax() -> Float { return 12.0; }
    
    public func GetGrappleBase() -> Float { return 6.0; }
    public func GetGrapplePerRarity() -> Float { return 1.2; }
    public func GetGuardBreakEligible(rarityVal: Int32) -> Bool { return rarityVal >= 1; }
    public func GetPinThreshold() -> Float { return 4.0; }
    
    public func GetStyleAbilities(arch: GBPChromeArchetype, rarityVal: Int32) -> array<TweakDBID> {
        let out: array<TweakDBID>;
        ArrayPush(out, t"Ability.CanSprintHarass");
        ArrayPush(out, t"Ability.CanCloseCombat");
        ArrayPush(out, t"Ability.CanCatchUpDistance");
        return out;
    }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.animalsAccuracy;
        this.cfgSpd = cfg.animalsSpeed;
        this.cfgHp = cfg.animalsHealth;
        this.cfgArmorMin = Cast<Float>(cfg.animalsArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.animalsArmorMax);
        this.cfgRarityScale = cfg.animalsRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.68;
        let scale: Float = 0.20;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.60;
        let scale: Float = 0.20;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.60;
        let scale: Float = 0.20;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 10.0;
        let aMax: Float = 120.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 60.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 60.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 60.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 60.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.8 + (0.5 - 0.8) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal >= 4 { return "None"; }
        return "Fire, Electric";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        
        if rarityVal >= 4 { return 0.01; }
        if attackType == 0 {
            
            if rarityVal <= 0 { return 0.03; }
            if rarityVal == 1 { return 0.02; }
            return 0.01;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.08; }
            if rarityVal == 1 { return 0.06; }
            return 0.04;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.15; }
            if rarityVal == 1 { return 0.12; }
            return 0.08;
        }
        
        if rarityVal <= 0 { return 0.18; }
        if rarityVal == 1 { return 0.14; }
        return 0.10;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Pacifica") { return 0.75; }
        if StrContains(districtStr, "Coastview") { return 0.75; }
        if StrContains(districtStr, "Wellsprings") { return 0.75; }
        if StrContains(districtStr, "WestWindEstate") { return 0.75; }
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        if StrContains(districtStr, "CorpoPlaza") { return 1.25; }
        if StrContains(districtStr, "Downtown") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "rusher, steady";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.03 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.10; }
        if rarityVal == 1 { return 0.05; }
        if rarityVal == 2 { return 0.03; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPScavengerProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 3; }
    public func GetPinDuration() -> Float { return 4.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.scavengersAccuracy;
        this.cfgSpd = cfg.scavengersSpeed;
        this.cfgHp = cfg.scavengersHealth;
        this.cfgArmorMin = Cast<Float>(cfg.scavengersArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.scavengersArmorMax);
        this.cfgRarityScale = cfg.scavengersRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.83;
        let scale: Float = 0.18;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.90;
        let scale: Float = 0.18;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.85;
        let scale: Float = 0.18;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 5.0;
        let aMax: Float = 80.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 40.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 40.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 40.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 50.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0 + (0.9 - 1.0) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Blades, Explosives, Fire"; }
        if rarityVal == 2 { return "Blades, Fire"; }
        if rarityVal == 3 { return "Fire"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.15; }
            if rarityVal == 1 { return 0.12; }
            if rarityVal == 2 { return 0.08; }
            if rarityVal == 3 { return 0.05; }
            return 0.02;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.10; }
            if rarityVal == 1 { return 0.08; }
            if rarityVal == 2 { return 0.05; }
            if rarityVal == 3 { return 0.03; }
            return 0.01;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.20; }
            if rarityVal == 1 { return 0.15; }
            if rarityVal == 2 { return 0.10; }
            if rarityVal == 3 { return 0.06; }
            if rarityVal == 4 { return 0.03; }
            return 0.02;
        }
        
        if rarityVal <= 0 { return 0.25; }
        if rarityVal == 1 { return 0.20; }
        if rarityVal == 2 { return 0.15; }
        if rarityVal == 3 { return 0.10; }
        if rarityVal == 4 { return 0.05; }
        return 0.03;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        if StrContains(districtStr, "CorpoPlaza") { return 1.25; }
        if StrContains(districtStr, "Downtown") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if rarityVal >= 3 { return "opportunist"; }
        return "coward, opportunist";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.25 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.25; }
        if rarityVal == 1 { return 0.15; }
        if rarityVal == 2 { return 0.08; }
        if rarityVal == 3 { return 0.03; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPValentinosProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFleeWoundThreshold() -> Float { return 0.55; }
    
    public func GetPinThreshold() -> Float { return 4.5; }
    public func GetSuppressorChance() -> Float { return 0.55; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.valentinosAccuracy;
        this.cfgSpd = cfg.valentinosSpeed;
        this.cfgHp = cfg.valentinosHealth;
        this.cfgArmorMin = Cast<Float>(cfg.valentinosArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.valentinosArmorMax);
        this.cfgRarityScale = cfg.valentinosRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.17;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.65;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 25.0;
        let aMax: Float = 280.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 20.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 45.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 20.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0 + (0.85 - 1.0) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Chemical, Explosives"; }
        if rarityVal == 2 { return "Chemical"; }
        if rarityVal == 3 { return "Chemical"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.04; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.10; }
            if rarityVal == 1 { return 0.08; }
            if rarityVal == 2 { return 0.06; }
            if rarityVal == 3 { return 0.04; }
            if rarityVal == 4 { return 0.02; }
            return 0.01;
        }
        
        if rarityVal <= 0 { return 0.14; }
        if rarityVal == 1 { return 0.10; }
        if rarityVal == 2 { return 0.08; }
        if rarityVal == 3 { return 0.05; }
        if rarityVal == 4 { return 0.03; }
        return 0.015;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Heywood") { return 0.75; }
        if StrContains(districtStr, "Glen") { return 0.75; }
        if StrContains(districtStr, "VistaDelRey") { return 0.75; }
        if StrContains(districtStr, "Wellsprings") { return 0.75; }
        if StrContains(districtStr, "Watson") { return 1.25; }
        if StrContains(districtStr, "Badlands") { return 1.25; }
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "rusher, show_off"; }
        if rarityVal >= 3 { return "formation_fighter, show_off"; }
        return "show_off";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.10 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.12; }
        if rarityVal == 1 { return 0.06; }
        if rarityVal == 2 { return 0.03; }
        if rarityVal == 3 { return 0.01; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPVoodooBoysProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 2 { return 0.24; };
        return 0.0;
    }
    public func GetIntentAnchorMult() -> Float { return 1.08; }
    
    public func GetPinDuration() -> Float { return 2.0; }
    public func GetSuppressorChance() -> Float { return 0.4; }
    public func GetGrappleBase() -> Float { return 13.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.voodooBoysAccuracy;
        this.cfgSpd = cfg.voodooBoysSpeed;
        this.cfgHp = cfg.voodooBoysHealth;
        this.cfgArmorMin = Cast<Float>(cfg.voodooBoysArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.voodooBoysArmorMax);
        this.cfgRarityScale = cfg.voodooBoysRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.98;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.30;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.80;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 5.0;
        let aMax: Float = 60.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 40.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 60.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 80.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetRamCostAdd(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0;
    }

    public func GetUploadTimeAdd(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0;
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0 + (0.9 - 1.0) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Chemical, Blades, Shotguns"; }
        if rarityVal == 2 { return "Chemical, Blades"; }
        if rarityVal == 3 { return "Chemical"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.12; }
            if rarityVal == 1 { return 0.10; }
            if rarityVal == 2 { return 0.08; }
            if rarityVal == 3 { return 0.05; }
            return 0.02;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.08; }
            if rarityVal == 1 { return 0.06; }
            if rarityVal == 2 { return 0.04; }
            if rarityVal == 3 { return 0.02; }
            return 0.01;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.02; }
            if rarityVal == 1 { return 0.01; }
            if rarityVal == 2 { return 0.005; }
            if rarityVal == 3 { return 0.003; }
            return 0.001;
        }
        
        if rarityVal <= 0 { return 0.15; }
        if rarityVal == 1 { return 0.12; }
        if rarityVal == 2 { return 0.08; }
        if rarityVal == 3 { return 0.05; }
        if rarityVal == 4 { return 0.03; }
        return 0.02;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Pacifica") { return 0.75; }
        if StrContains(districtStr, "Coastview") { return 0.75; }
        if StrContains(districtStr, "Wellsprings") { return 0.75; }
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        if StrContains(districtStr, "CorpoPlaza") { return 1.25; }
        if StrContains(districtStr, "Downtown") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if rarityVal >= 3 { return "formation_fighter"; }
        return "";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.12 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.08; }
        if rarityVal == 1 { return 0.04; }
        if rarityVal == 2 { return 0.02; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPSixthStreetProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 2 { return 0.26; };
        return 0.0;
    }
    
    public func GetSuppressorChance() -> Float { return 0.65; }
    public func GetIntentSuppressMult() -> Float { return 0.64; }
    public func GetPinThreshold() -> Float { return 3.5; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.sixthStreetAccuracy;
        this.cfgSpd = cfg.sixthStreetSpeed;
        this.cfgHp = cfg.sixthStreetHealth;
        this.cfgArmorMin = Cast<Float>(cfg.sixthStreetArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.sixthStreetArmorMax);
        this.cfgRarityScale = cfg.sixthStreetRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.32;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.35;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 30.0;
        let aMax: Float = 450.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 20.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 35.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 30.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.9 + (0.7 - 0.9) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Chemical, Hacking, Fire"; }
        if rarityVal == 2 { return "Chemical, Hacking"; }
        if rarityVal == 3 { return "Chemical"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            if rarityVal == 2 { return 0.03; }
            if rarityVal == 3 { return 0.02; }
            return 0.01;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.04; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.14; }
            if rarityVal == 1 { return 0.10; }
            if rarityVal == 2 { return 0.08; }
            if rarityVal == 3 { return 0.05; }
            if rarityVal == 4 { return 0.03; }
            return 0.015;
        }
        
        if rarityVal <= 0 { return 0.12; }
        if rarityVal == 1 { return 0.08; }
        if rarityVal == 2 { return 0.06; }
        if rarityVal == 3 { return 0.04; }
        if rarityVal == 4 { return 0.02; }
        return 0.01;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "SantoDomingo") { return 0.75; }
        if StrContains(districtStr, "RanchoCoronado") { return 0.75; }
        if StrContains(districtStr, "Arroyo") { return 0.75; }
        if StrContains(districtStr, "VistaDelRey") { return 0.75; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        if StrContains(districtStr, "Dogtown") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.06 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.10; }
        if rarityVal == 1 { return 0.05; }
        if rarityVal == 2 { return 0.03; }
        if rarityVal == 3 { return 0.01; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPArasakaProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    public func GetIntentPanicMult() -> Float { return 0.82; }
    public func GetCoverEjectThreshold(rarityVal: Int32) -> Float {
        if rarityVal < 1 { return 0.0; };
        return 0.22;
    }
    
    public func GetPinThreshold() -> Float { return 6.5; }
    public func GetGrappleBase() -> Float { return 4.5; }
    
    public func GetCatchUpPolicy() -> Int32 { return 0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.arasakaAccuracy;
        this.cfgSpd = cfg.arasakaSpeed;
        this.cfgHp = cfg.arasakaHealth;
        this.cfgArmorMin = Cast<Float>(cfg.arasakaArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.arasakaArmorMax);
        this.cfgRarityScale = cfg.arasakaRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.47;
        let scale: Float = 0.08;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant { return 0.0; }
        let base: Float = 0.55;
        let scale: Float = 0.08;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.08;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant {
            let mechArmor: Float = 2000.0 + (3500.0 - 2000.0) * Cast<Float>(rarityVal) / 6.0;
            return mechArmor;
        }
        let aMin: Float = 40.0;
        let aMax: Float = 600.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant {
            return -80.0 + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        }
        let base: Float = 20.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant {
            let mechBase: Float = -60.0 + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
            return mechBase + GBPArchetypeMults.HackingResistBonus(archetype);
        }
        let base: Float = 50.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.8 + (0.5 - 0.8) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal >= 4 { return "None"; }
        return "Electric, Chemical";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if rarityVal >= 4 { return 0.01; }
        if attackType == 0 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.04; }
            return 0.03;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.02; }
            if rarityVal == 1 { return 0.02; }
            return 0.01;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            return 0.03;
        }
        
        if rarityVal <= 0 { return 0.07; }
        if rarityVal == 1 { return 0.05; }
        return 0.04;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "CityCenter") { return 0.75; }
        if StrContains(districtStr, "CorpoPlaza") { return 0.75; }
        if StrContains(districtStr, "Downtown") { return 0.75; }
        if StrContains(districtStr, "ArasakaWaterfront") { return 0.75; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        if StrContains(districtStr, "Dogtown") { return 1.25; }
        if StrContains(districtStr, "Badlands") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.02 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.08; }
        if rarityVal == 1 { return 0.04; }
        if rarityVal == 2 { return 0.02; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool {
        let lower: String = StrLower(recordStr);
        return StrContains(lower, "mech") || StrContains(lower, "minotaur");
    }
}

public class GBPMilitechProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 1 { return 0.44; };
        return 0.0;
    }
    
    public func GetSuppressorChance() -> Float { return 0.82; }
    public func GetPinDuration() -> Float { return 1.4; }
    
    public func GetCatchUpPolicy() -> Int32 { return 2; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.militechAccuracy;
        this.cfgSpd = cfg.militechSpeed;
        this.cfgHp = cfg.militechHealth;
        this.cfgArmorMin = Cast<Float>(cfg.militechArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.militechArmorMax);
        this.cfgRarityScale = cfg.militechRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.35;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.22;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant {
            let mechArmor: Float = 3000.0 + (5000.0 - 3000.0) * Cast<Float>(rarityVal) / 6.0;
            return mechArmor;
        }
        let aMin: Float = 50.0;
        let aMax: Float = 900.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 25.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant {
            return -70.0 + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        }
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 25.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        if isVariant {
            let mechBase: Float = -50.0 + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
            return mechBase + GBPArchetypeMults.HackingResistBonus(archetype);
        }
        let base: Float = 30.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.7 + (0.4 - 0.7) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal >= 4 { return "None"; }
        return "Electric, Hacking";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if rarityVal >= 4 { return 0.01; }
        if attackType == 0 {
            if rarityVal <= 0 { return 0.04; }
            if rarityVal == 1 { return 0.03; }
            return 0.02;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.02; }
            if rarityVal == 1 { return 0.01; }
            return 0.01;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.08; }
            if rarityVal == 1 { return 0.06; }
            return 0.04;
        }
        
        if rarityVal <= 0 { return 0.06; }
        if rarityVal == 1 { return 0.04; }
        return 0.03;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "CityCenter") { return 0.75; }
        if StrContains(districtStr, "CorpoPlaza") { return 0.75; }
        if StrContains(districtStr, "Downtown") { return 0.75; }
        if StrContains(districtStr, "Badlands") { return 0.75; }
        if StrContains(districtStr, "NorthBadlands") { return 0.75; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        if StrContains(districtStr, "Dogtown") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.03 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.05; }
        if rarityVal == 1 { return 0.03; }
        if rarityVal == 2 { return 0.01; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool {
        let lower: String = StrLower(recordStr);
        return StrContains(lower, "mech") || StrContains(lower, "minotaur");
    }
}

public class GBPKangTaoProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 1 { return 0.3; };
        return 0.0;
    }
    public func GetIntentAnchorMult() -> Float { return 1.1; }
    
    public func GetIntentSuppressMult() -> Float { return 0.78; }
    public func GetPinThreshold() -> Float { return 5.0; }
    
    public func GetCatchUpPolicy() -> Int32 { return 0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.kangTaoAccuracy;
        this.cfgSpd = cfg.kangTaoSpeed;
        this.cfgHp = cfg.kangTaoHealth;
        this.cfgArmorMin = Cast<Float>(cfg.kangTaoArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.kangTaoArmorMax);
        this.cfgRarityScale = cfg.kangTaoRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.44;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.40;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 35.0;
        let aMax: Float = 420.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 35.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 40.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 40.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.85 + (0.6 - 0.85) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal >= 4 { return "None"; }
        return "Chemical, Explosives";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if rarityVal >= 4 { return 0.01; }
        if attackType == 0 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            return 0.03;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.03; }
            if rarityVal == 1 { return 0.02; }
            return 0.01;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.04; }
            return 0.03;
        }
        
        if rarityVal <= 0 { return 0.08; }
        if rarityVal == 1 { return 0.06; }
        return 0.04;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "CityCenter") { return 0.75; }
        if StrContains(districtStr, "CorpoPlaza") { return 0.75; }
        if StrContains(districtStr, "Downtown") { return 0.75; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        if StrContains(districtStr, "Dogtown") { return 1.25; }
        if StrContains(districtStr, "Badlands") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.03 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.06; }
        if rarityVal == 1 { return 0.03; }
        if rarityVal == 2 { return 0.01; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPTraumaTeamProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 1 { return 0.25; };
        return 0.0;
    }
    public func GetFleeWoundThreshold() -> Float { return 0.75; }
    public func GetCoverEjectThreshold(rarityVal: Int32) -> Float {
        if rarityVal < 1 { return 0.0; };
        return 0.2;
    }
    
    public func GetSuppressorChance() -> Float { return 0.88; }
    public func GetPinThreshold() -> Float { return 6.0; }
    public func GetGrappleBase() -> Float { return 6.5; }
    
    public func GetCatchUpPolicy() -> Int32 { return 0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.traumaTeamAccuracy;
        this.cfgSpd = cfg.traumaTeamSpeed;
        this.cfgHp = cfg.traumaTeamHealth;
        this.cfgArmorMin = Cast<Float>(cfg.traumaTeamArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.traumaTeamArmorMax);
        this.cfgRarityScale = cfg.traumaTeamRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.32;
        let scale: Float = 0.08;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.30;
        let scale: Float = 0.08;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.15;
        let scale: Float = 0.08;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 60.0;
        let aMax: Float = 700.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 50.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 25.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.7 + (0.4 - 0.7) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal >= 4 { return "None"; }
        return "Electric, Hacking";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if rarityVal >= 4 { return 0.01; }
        if attackType == 0 {
            if rarityVal <= 0 { return 0.04; }
            if rarityVal == 1 { return 0.03; }
            return 0.02;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.02; }
            if rarityVal == 1 { return 0.02; }
            return 0.01;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            return 0.03;
        }
        
        if rarityVal <= 0 { return 0.05; }
        if rarityVal == 1 { return 0.04; }
        return 0.03;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.05 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.04; }
        if rarityVal == 1 { return 0.02; }
        if rarityVal == 2 { return 0.01; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPWraithsProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetPinDuration() -> Float { return 2.4; }
    public func GetSuppressorChance() -> Float { return 0.32; }
    public func GetGrappleBase() -> Float { return 17.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.wraithsAccuracy;
        this.cfgSpd = cfg.wraithsSpeed;
        this.cfgHp = cfg.wraithsHealth;
        this.cfgArmorMin = Cast<Float>(cfg.wraithsArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.wraithsArmorMax);
        this.cfgRarityScale = cfg.wraithsRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.20;
        let scale: Float = 0.16;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.95;
        let scale: Float = 0.16;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.16;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 20.0;
        let aMax: Float = 180.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 20.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 30.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 25.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 40.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0 + (0.85 - 1.0) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Explosives, Fire, Blades"; }
        if rarityVal == 2 { return "Explosives, Fire"; }
        if rarityVal == 3 { return "Explosives"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.08; }
            if rarityVal == 1 { return 0.06; }
            if rarityVal == 2 { return 0.04; }
            if rarityVal == 3 { return 0.02; }
            return 0.01;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            if rarityVal == 2 { return 0.03; }
            if rarityVal == 3 { return 0.02; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.12; }
            if rarityVal == 1 { return 0.10; }
            if rarityVal == 2 { return 0.06; }
            if rarityVal == 3 { return 0.04; }
            if rarityVal == 4 { return 0.02; }
            return 0.01;
        }
        
        if rarityVal <= 0 { return 0.20; }
        if rarityVal == 1 { return 0.16; }
        if rarityVal == 2 { return 0.12; }
        if rarityVal == 3 { return 0.08; }
        if rarityVal == 4 { return 0.04; }
        return 0.02;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Badlands") { return 0.75; }
        if StrContains(districtStr, "NorthBadlands") { return 0.75; }
        if StrContains(districtStr, "SouthBadlands") { return 0.75; }
        if StrContains(districtStr, "Dogtown") { return 0.75; }
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        if StrContains(districtStr, "CorpoPlaza") { return 1.25; }
        if StrContains(districtStr, "Heywood") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if rarityVal >= 3 { return "opportunist, formation_fighter"; }
        return "coward, opportunist";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.15 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.12; }
        if rarityVal == 1 { return 0.06; }
        if rarityVal == 2 { return 0.03; }
        if rarityVal == 3 { return 0.01; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPBarghestProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 2 { return 0.33; };
        return 0.0;
    }
    public func GetFleeWoundThreshold() -> Float { return 0.6; }
    
    public func GetPinMoraleDrip() -> Float { return 0.06; }
    public func GetSuppressorChance() -> Float { return 0.6; }
    public func GetGrappleBase() -> Float { return 10.5; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.barghestAccuracy;
        this.cfgSpd = cfg.barghestSpeed;
        this.cfgHp = cfg.barghestHealth;
        this.cfgArmorMin = Cast<Float>(cfg.barghestArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.barghestArmorMax);
        this.cfgRarityScale = cfg.barghestRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.32;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.42;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 35.0;
        let aMax: Float = 500.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 30.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 20.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.85 + (0.65 - 0.85) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Chemical, Hacking, Explosives"; }
        if rarityVal == 2 { return "Chemical, Hacking"; }
        if rarityVal == 3 { return "Chemical"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.04; }
            if rarityVal == 2 { return 0.03; }
            if rarityVal == 3 { return 0.02; }
            return 0.01;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.04; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.10; }
            if rarityVal == 1 { return 0.08; }
            if rarityVal == 2 { return 0.06; }
            if rarityVal == 3 { return 0.04; }
            if rarityVal == 4 { return 0.02; }
            return 0.01;
        }
        
        if rarityVal <= 0 { return 0.10; }
        if rarityVal == 1 { return 0.08; }
        if rarityVal == 2 { return 0.06; }
        if rarityVal == 3 { return 0.04; }
        if rarityVal == 4 { return 0.02; }
        return 0.01;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Dogtown") { return 0.75; }
        if StrContains(districtStr, "CityCenter") { return 1.25; }
        if StrContains(districtStr, "CorpoPlaza") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.05 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.08; }
        if rarityVal == 1 { return 0.04; }
        if rarityVal == 2 { return 0.02; }
        if rarityVal == 3 { return 0.0; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPNCPDProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    
    public func GetGrappleBase() -> Float { return 5.5; }
    public func GetPinThreshold() -> Float { return 5.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.ncpdAccuracy;
        this.cfgSpd = cfg.ncpdSpeed;
        this.cfgHp = cfg.ncpdHealth;
        this.cfgArmorMin = Cast<Float>(cfg.ncpdArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.ncpdArmorMax);
        this.cfgRarityScale = cfg.ncpdRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.28;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.32;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 200.0;
        let aMax: Float = 450.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 20.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0 - 35.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.85 + (0.65 - 0.85) * Cast<Float>(rarityVal) / 6.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Hacking, Chemical, Explosives"; }
        if rarityVal == 2 { return "Hacking, Explosives"; }
        if rarityVal == 3 { return "Hacking"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.06; }
            if rarityVal == 1 { return 0.04; }
            if rarityVal == 2 { return 0.03; }
            if rarityVal == 3 { return 0.02; }
            return 0.01;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.04; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.15; }
            if rarityVal == 1 { return 0.12; }
            if rarityVal == 2 { return 0.08; }
            if rarityVal == 3 { return 0.05; }
            if rarityVal == 4 { return 0.03; }
            return 0.015;
        }
        
        if rarityVal <= 0 { return 0.12; }
        if rarityVal == 1 { return 0.08; }
        if rarityVal == 2 { return 0.06; }
        if rarityVal == 3 { return 0.04; }
        if rarityVal == 4 { return 0.02; }
        return 0.01;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "CityCenter") { return 0.75; }
        if StrContains(districtStr, "CorpoPlaza") { return 0.75; }
        if StrContains(districtStr, "Downtown") { return 0.75; }
        if StrContains(districtStr, "Heywood") { return 0.75; }
        if StrContains(districtStr, "Pacifica") { return 1.25; }
        if StrContains(districtStr, "Dogtown") { return 1.25; }
        if StrContains(districtStr, "Badlands") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.08 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.10; }
        if rarityVal == 1 { return 0.05; }
        if rarityVal == 2 { return 0.03; }
        if rarityVal == 3 { return 0.01; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPMoxProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetIntentAnchorMult() -> Float { return 1.07; }
    
    public func GetGrappleBase() -> Float { return 9.5; }
    public func GetIntentPinnedMult() -> Float { return 0.71; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.moxAccuracy;
        this.cfgSpd = cfg.moxSpeed;
        this.cfgHp = cfg.moxHealth;
        this.cfgArmorMin = Cast<Float>(cfg.moxArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.moxArmorMax);
        this.cfgRarityScale = cfg.moxRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.02;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal));
        return scaled * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.38;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        let scaled: Float = base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5);
        return scaled * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.70;
        let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 15.0;
        let aMax: Float = 200.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        let armor: Float = aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0;
        return armor * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 35.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        let result: Float = base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
        return result + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.0;
    }

    public func GetFears(rarityVal: Int32) -> String {
        if rarityVal <= 1 { return "Blades, Shotguns"; }
        if rarityVal == 2 { return "Shotguns"; }
        return "None";
    }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 {
            if rarityVal <= 0 { return 0.08; }
            if rarityVal == 1 { return 0.06; }
            if rarityVal == 2 { return 0.04; }
            if rarityVal == 3 { return 0.02; }
            return 0.01;
        }
        if attackType == 1 {
            if rarityVal <= 0 { return 0.05; }
            if rarityVal == 1 { return 0.03; }
            if rarityVal == 2 { return 0.02; }
            if rarityVal == 3 { return 0.01; }
            return 0.005;
        }
        if attackType == 2 {
            if rarityVal <= 0 { return 0.14; }
            if rarityVal == 1 { return 0.10; }
            if rarityVal == 2 { return 0.07; }
            if rarityVal == 3 { return 0.04; }
            if rarityVal == 4 { return 0.02; }
            return 0.01;
        }
        if rarityVal <= 0 { return 0.16; }
        if rarityVal == 1 { return 0.12; }
        if rarityVal == 2 { return 0.08; }
        if rarityVal == 3 { return 0.05; }
        if rarityVal == 4 { return 0.03; }
        return 0.015;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Westbrook") { return 0.75; }
        if StrContains(districtStr, "JapanTown") { return 0.75; }
        if StrContains(districtStr, "Watson") { return 0.80; }
        if StrContains(districtStr, "Kabuki") { return 0.80; }
        if StrContains(districtStr, "Badlands") { return 1.25; }
        if StrContains(districtStr, "Dogtown") { return 1.25; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "rusher, show_off"; }
        if rarityVal >= 3 { return "formation_fighter"; }
        return "show_off";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float {
        return 0.06 * this.DetectionRarityScale(rarityVal);
    }

    public func GetMoraleBreakChance(rarityVal: Int32) -> Float {
        if rarityVal <= 0 { return 0.10; }
        if rarityVal == 1 { return 0.06; }
        if rarityVal == 2 { return 0.03; }
        if rarityVal == 3 { return 0.01; }
        return 0.0;
    }

    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPAldecaldosProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFleeWoundThreshold() -> Float { return 0.55; }
    
    public func GetPinCooldown() -> Float { return 6.0; }
    public func GetGrappleBase() -> Float { return 11.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.aldecaldosAccuracy;
        this.cfgSpd = cfg.aldecaldosSpeed;
        this.cfgHp = cfg.aldecaldosHealth;
        this.cfgArmorMin = Cast<Float>(cfg.aldecaldosArmorMin);
        this.cfgArmorMax = Cast<Float>(cfg.aldecaldosArmorMax);
        this.cfgRarityScale = cfg.aldecaldosRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.17; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal)) * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.45; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5) * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 30.0; let aMax: Float = 300.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        return (aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0) * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return (base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0))) + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }

    public func GetFears(rarityVal: Int32) -> String { if rarityVal <= 1 { return "Explosions"; } return "None"; }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 { if rarityVal <= 0 { return 0.06; } if rarityVal == 1 { return 0.04; } if rarityVal == 2 { return 0.03; } if rarityVal == 3 { return 0.015; } return 0.008; }
        if attackType == 1 { if rarityVal <= 0 { return 0.04; } if rarityVal == 1 { return 0.025; } if rarityVal == 2 { return 0.015; } if rarityVal == 3 { return 0.008; } return 0.004; }
        if attackType == 2 { if rarityVal <= 0 { return 0.10; } if rarityVal == 1 { return 0.07; } if rarityVal == 2 { return 0.05; } if rarityVal == 3 { return 0.03; } if rarityVal == 4 { return 0.015; } return 0.008; }
        if rarityVal <= 0 { return 0.12; } if rarityVal == 1 { return 0.09; } if rarityVal == 2 { return 0.06; } if rarityVal == 3 { return 0.035; } if rarityVal == 4 { return 0.02; } return 0.01;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Badlands") { return 0.70; } if StrContains(districtStr, "SantoDomingo") { return 0.85; }
        if StrContains(districtStr, "CityCenter") { return 1.20; } if StrContains(districtStr, "Westbrook") { return 1.20; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "rusher, pack_tactics"; } if rarityVal >= 3 { return "pack_tactics, formation_fighter"; } return "pack_tactics";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.04 * this.DetectionRarityScale(rarityVal); }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { if rarityVal <= 0 { return 0.08; } if rarityVal == 1 { return 0.05; } if rarityVal == 2 { return 0.02; } if rarityVal == 3 { return 0.008; } return 0.0; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPNetWatchProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 1 { return 0.28; };
        return 0.0;
    }
    public func GetIntentAnchorMult() -> Float { return 1.09; }
    
    public func GetSuppressorChance() -> Float { return 0.6; }
    public func GetPinDuration() -> Float { return 1.8; }
    
    public func GetCatchUpPolicy() -> Int32 { return 0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.netwatchAccuracy; this.cfgSpd = cfg.netwatchSpeed; this.cfgHp = cfg.netwatchHealth;
        this.cfgArmorMin = Cast<Float>(cfg.netwatchArmorMin); this.cfgArmorMax = Cast<Float>(cfg.netwatchArmorMax);
        this.cfgRarityScale = cfg.netwatchRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.13; let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal)) * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.35; let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5) * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.85; let scale: Float = 0.12;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 20.0; let aMax: Float = 250.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        return (aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0) * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 30.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 50.0;
        return (base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0))) + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetFears(rarityVal: Int32) -> String { if rarityVal <= 1 { return "Blades, Shotguns"; } if rarityVal == 2 { return "Blades"; } return "None"; }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 { if rarityVal <= 0 { return 0.09; } if rarityVal == 1 { return 0.07; } if rarityVal == 2 { return 0.05; } if rarityVal == 3 { return 0.03; } return 0.015; }
        if attackType == 1 { if rarityVal <= 0 { return 0.06; } if rarityVal == 1 { return 0.04; } if rarityVal == 2 { return 0.03; } if rarityVal == 3 { return 0.015; } return 0.008; }
        if attackType == 2 { if rarityVal <= 0 { return 0.15; } if rarityVal == 1 { return 0.11; } if rarityVal == 2 { return 0.08; } if rarityVal == 3 { return 0.05; } if rarityVal == 4 { return 0.025; } return 0.012; }
        if rarityVal <= 0 { return 0.18; } if rarityVal == 1 { return 0.13; } if rarityVal == 2 { return 0.09; } if rarityVal == 3 { return 0.06; } if rarityVal == 4 { return 0.035; } return 0.018;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Pacifica") { return 0.75; } if StrContains(districtStr, "CityCenter") { return 0.80; }
        if StrContains(districtStr, "Badlands") { return 1.20; } return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 4 { return "hacker, cautious"; } if rarityVal >= 3 { return "cautious, formation_fighter"; } return "cautious";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.07 * this.DetectionRarityScale(rarityVal); }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { if rarityVal <= 0 { return 0.12; } if rarityVal == 1 { return 0.08; } if rarityVal == 2 { return 0.04; } if rarityVal == 3 { return 0.015; } return 0.0; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPBiotechnicaProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetCoverReactionMin() -> Float { return 3.0; }
    public func GetCoverReactionMax() -> Float { return 7.0; }
    
    public func GetPinThreshold() -> Float { return 3.2; }
    public func GetPinDuration() -> Float { return 3.0; }
    public func GetSuppressorChance() -> Float { return 0.38; }
    public func GetGrappleBase() -> Float { return 15.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.biotechnicaAccuracy; this.cfgSpd = cfg.biotechnicaSpeed; this.cfgHp = cfg.biotechnicaHealth;
        this.cfgArmorMin = Cast<Float>(cfg.biotechnicaArmorMin); this.cfgArmorMax = Cast<Float>(cfg.biotechnicaArmorMax);
        this.cfgRarityScale = cfg.biotechnicaRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.17; let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal)) * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.40; let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5) * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.90; let scale: Float = 0.10;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 20.0; let aMax: Float = 200.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        return (aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0) * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 5.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 40.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 5.0;
        return (base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0))) + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetFears(rarityVal: Int32) -> String { if rarityVal <= 1 { return "Heavy Weapons"; } return "None"; }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 { if rarityVal <= 0 { return 0.08; } if rarityVal == 1 { return 0.06; } if rarityVal == 2 { return 0.04; } if rarityVal == 3 { return 0.02; } return 0.01; }
        if attackType == 1 { if rarityVal <= 0 { return 0.05; } if rarityVal == 1 { return 0.035; } if rarityVal == 2 { return 0.02; } if rarityVal == 3 { return 0.01; } return 0.005; }
        if attackType == 2 { if rarityVal <= 0 { return 0.14; } if rarityVal == 1 { return 0.10; } if rarityVal == 2 { return 0.07; } if rarityVal == 3 { return 0.04; } if rarityVal == 4 { return 0.02; } return 0.01; }
        if rarityVal <= 0 { return 0.16; } if rarityVal == 1 { return 0.12; } if rarityVal == 2 { return 0.08; } if rarityVal == 3 { return 0.05; } if rarityVal == 4 { return 0.03; } return 0.015;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Badlands") { return 0.80; } if StrContains(districtStr, "Watson") { return 0.85; } return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { if rarityVal >= 3 { return "formation_fighter, cautious"; } return "cautious"; }
    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.06 * this.DetectionRarityScale(rarityVal); }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { if rarityVal <= 0 { return 0.10; } if rarityVal == 1 { return 0.07; } if rarityVal == 2 { return 0.04; } if rarityVal == 3 { return 0.015; } return 0.0; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPNUSAProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 0; }
    public func GetPinMoraleDrip() -> Float { return 0.03; }
    public func GetSuppressorChance() -> Float { return 0.7; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.nusaAccuracy; this.cfgSpd = cfg.nusaSpeed; this.cfgHp = cfg.nusaHealth;
        this.cfgArmorMin = Cast<Float>(cfg.nusaArmorMin); this.cfgArmorMax = Cast<Float>(cfg.nusaArmorMax);
        this.cfgRarityScale = cfg.nusaRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.40; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal)) * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.48; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5) * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.05; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 150.0; let aMax: Float = 500.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        return (aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0) * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 10.0;
        return (base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0))) + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetFears(rarityVal: Int32) -> String { if rarityVal <= 0 { return "Explosions"; } return "None"; }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 { if rarityVal <= 0 { return 0.05; } if rarityVal == 1 { return 0.035; } if rarityVal == 2 { return 0.025; } if rarityVal == 3 { return 0.012; } return 0.006; }
        if attackType == 1 { if rarityVal <= 0 { return 0.03; } if rarityVal == 1 { return 0.02; } if rarityVal == 2 { return 0.012; } if rarityVal == 3 { return 0.006; } return 0.003; }
        if attackType == 2 { if rarityVal <= 0 { return 0.09; } if rarityVal == 1 { return 0.06; } if rarityVal == 2 { return 0.04; } if rarityVal == 3 { return 0.025; } if rarityVal == 4 { return 0.012; } return 0.006; }
        if rarityVal <= 0 { return 0.10; } if rarityVal == 1 { return 0.07; } if rarityVal == 2 { return 0.05; } if rarityVal == 3 { return 0.03; } if rarityVal == 4 { return 0.015; } return 0.008;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Dogtown") { return 0.65; } if StrContains(districtStr, "Pacifica") { return 0.80; }
        if StrContains(districtStr, "Badlands") { return 0.85; } return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "rusher, formation_fighter"; } if rarityVal >= 3 { return "formation_fighter"; } return "formation_fighter";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.03 * this.DetectionRarityScale(rarityVal); }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { if rarityVal <= 0 { return 0.06; } if rarityVal == 1 { return 0.03; } if rarityVal == 2 { return 0.015; } if rarityVal == 3 { return 0.005; } return 0.0; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPAfterlifeProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 1; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 2 { return 0.36; };
        return 0.0;
    }
    public func GetFleeWoundThreshold() -> Float { return 0.6; }
    
    public func GetPinThreshold() -> Float { return 5.0; }
    public func GetSuppressorChance() -> Float { return 0.62; }
    public func GetGrappleBase() -> Float { return 8.5; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.afterlifeAccuracy; this.cfgSpd = cfg.afterlifeSpeed; this.cfgHp = cfg.afterlifeHealth;
        this.cfgArmorMin = Cast<Float>(cfg.afterlifeArmorMin); this.cfgArmorMax = Cast<Float>(cfg.afterlifeArmorMax);
        this.cfgRarityScale = cfg.afterlifeRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.34; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal)) * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.42; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5) * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.95; let scale: Float = 0.14;
        if this.cfgLoaded { base = this.cfgHp; scale = this.cfgRarityScale; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 25.0; let aMax: Float = 550.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        return (aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0) * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 5.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 5.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 5.0;
        return base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0));
    }

    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 15.0;
        return (base + Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 12.0))) + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetFears(rarityVal: Int32) -> String { if rarityVal <= 0 { return "Heavy Weapons"; } return "None"; }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 { if rarityVal <= 0 { return 0.07; } if rarityVal == 1 { return 0.05; } if rarityVal == 2 { return 0.035; } if rarityVal == 3 { return 0.018; } return 0.009; }
        if attackType == 1 { if rarityVal <= 0 { return 0.045; } if rarityVal == 1 { return 0.03; } if rarityVal == 2 { return 0.018; } if rarityVal == 3 { return 0.009; } return 0.004; }
        if attackType == 2 { if rarityVal <= 0 { return 0.12; } if rarityVal == 1 { return 0.08; } if rarityVal == 2 { return 0.06; } if rarityVal == 3 { return 0.035; } if rarityVal == 4 { return 0.018; } return 0.009; }
        if rarityVal <= 0 { return 0.14; } if rarityVal == 1 { return 0.10; } if rarityVal == 2 { return 0.07; } if rarityVal == 3 { return 0.04; } if rarityVal == 4 { return 0.02; } return 0.01;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float {
        if StrContains(districtStr, "Kabuki") { return 0.80; }   
        if StrContains(districtStr, "Watson") { return 0.75; }
        return 1.0;
    }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if archetype == 7 { return "rusher, solo"; } if rarityVal >= 4 { return "solo, formation_fighter"; } if rarityVal >= 2 { return "solo"; } return "show_off";
    }

    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.05 * this.DetectionRarityScale(rarityVal); }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { if rarityVal <= 0 { return 0.09; } if rarityVal == 1 { return 0.06; } if rarityVal == 2 { return 0.03; } if rarityVal == 3 { return 0.01; } return 0.0; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPPsychoAnchorProfile extends GBPCyberpsychoProfile {
    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return "cyber_junkie"; }
}

public class GBPPsychoRusherProfile extends GBPCyberpsychoProfile {
    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return "rusher, show_off"; }
}

public class GBPPsychoGunnerProfile extends GBPCyberpsychoProfile {
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return "cyber_junkie"; }
}

public class GBPPsychoSniperProfile extends GBPCyberpsychoProfile {
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return "formation_fighter"; }
}

public class GBPPsychoNetrunnerProfile extends GBPCyberpsychoProfile {
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return "opportunist"; }
}

public class GBPUnaffiliatedProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 2; }
    public func GetFlankChance(rarityVal: Int32) -> Float {
        if rarityVal >= 2 { return 0.22; };
        return 0.0;
    }
    public func GetFleeWoundThreshold() -> Float { return 0.5; }
    public func GetPinThreshold() -> Float { return 4.0; }
    public func GetSuppressorChance() -> Float { return 0.40; }
    public func GetGrappleBase() -> Float { return 6.0; }

    public func Setup(cfg: ref<GBPConfig>) -> Void {
        if !IsDefined(cfg) { return; };
        this.cfgAcc = cfg.unaffiliatedAccuracy; this.cfgSpd = cfg.unaffiliatedSpeed; this.cfgHp = cfg.unaffiliatedHealth;
        this.cfgArmorMin = Cast<Float>(cfg.unaffiliatedArmorMin); this.cfgArmorMax = Cast<Float>(cfg.unaffiliatedArmorMax);
        this.cfgRarityScale = cfg.unaffiliatedRarityScale;
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.25; let scale: Float = 0.13;
        if this.cfgLoaded { base = this.cfgAcc; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal)) * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 0.45; let scale: Float = 0.13;
        if this.cfgLoaded { base = this.cfgSpd; scale = this.cfgRarityScale; };
        return base * (1.0 + scale * Cast<Float>(rarityVal) * 0.5) * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let base: Float = 1.00;
        if this.cfgLoaded { base = this.cfgHp; };
        return base * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        let aMin: Float = 50.0; let aMax: Float = 350.0;
        if this.cfgLoaded { aMin = this.cfgArmorMin; aMax = this.cfgArmorMax; };
        return (aMin + (aMax - aMin) * Cast<Float>(rarityVal) / 6.0) * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }
    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return Cast<Float>(Cast<Int32>(SqrtF(Cast<Float>(rarityVal)) * 8.0)) + GBPArchetypeMults.HackingResistBonus(archetype);
    }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 1.0; }
    public func GetFears(rarityVal: Int32) -> String { if rarityVal <= 1 { return "Heavy Weapons"; } return "None"; }

    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float {
        if attackType == 0 { if rarityVal <= 0 { return 0.09; } if rarityVal == 1 { return 0.06; } if rarityVal == 2 { return 0.04; } if rarityVal == 3 { return 0.02; } return 0.01; }
        if attackType == 1 { if rarityVal <= 0 { return 0.055; } if rarityVal == 1 { return 0.035; } if rarityVal == 2 { return 0.02; } if rarityVal == 3 { return 0.01; } return 0.005; }
        if attackType == 2 { if rarityVal <= 0 { return 0.14; } if rarityVal == 1 { return 0.10; } if rarityVal == 2 { return 0.07; } if rarityVal == 3 { return 0.04; } if rarityVal == 4 { return 0.02; } return 0.01; }
        if rarityVal <= 0 { return 0.16; } if rarityVal == 1 { return 0.12; } if rarityVal == 2 { return 0.08; } if rarityVal == 3 { return 0.05; } if rarityVal == 4 { return 0.025; } return 0.012;
    }

    public func GetDistrictFearModifier(districtStr: String) -> Float { return 1.0; }
    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String {
        if rarityVal >= 4 { return "formation_fighter"; } return "";
    }
    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.10 * this.DetectionRarityScale(rarityVal); }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { if rarityVal <= 0 { return 0.14; } if rarityVal == 1 { return 0.10; } if rarityVal == 2 { return 0.06; } if rarityVal == 3 { return 0.03; } return 0.01; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}

public class GBPCyberpsychoProfile extends GBPProfile {
    
    public func GetDoctrineTier() -> Int32 { return 4; }
    
    public func Setup(cfg: ref<GBPConfig>) -> Void {
        this.cfgLoaded = true;
    }

    public func GetAccuracy(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.2 * GBPArchetypeMults.AccuracyMult(archetype);
    }

    public func GetSpeed(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 0.5 * GBPArchetypeMults.SpeedMult(archetype);
    }

    public func GetHealth(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 1.3 * GBPArchetypeMults.HealthMult(archetype);
    }

    public func GetArmor(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float {
        return 200.0 * GBPArchetypeMults.ArmorMult(archetype);
    }

    public func GetThermalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 10.0; }
    public func GetElectricResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0 - 30.0; }   
    public func GetChemicalResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 40.0; }         
    
    public func GetHackingResist(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.0; }

    public func GetHeadshotMult(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> Float { return 0.75; }           

    public func GetFears(rarityVal: Int32) -> String { return "None"; }
    public func GetMoraleWound(attackType: Int32, rarityVal: Int32) -> Float { return 0.0; }
    public func GetMoraleBreakChance(rarityVal: Int32) -> Float { return 0.0; }
    public func GetDetectionFearChance(rarityVal: Int32) -> Float { return 0.0; }

    public func GetTraits(rarityVal: Int32, archetype: Int32, isVariant: Bool) -> String { return "cyber_junkie, rusher"; }
    public func GetDistrictFearModifier(districtStr: String) -> Float { return 1.0; }
    public func IsDistrictVariant(recordStr: String) -> Bool { return false; }
}
