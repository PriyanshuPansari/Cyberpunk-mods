// SDPCombat Phase 1: shooter and weapon profiles (realism pass, sections 3-4).
// All numbers are starting values to calibrate in-game.
module SDPCombat

public class SDPShooterProfile {
  public let tier: Int32;          // 0 untrained, 1 poorly disciplined, 2 trained, 3 elite, 4 mechanical
  public let sigmaShooter: Float;  // aiming error under combat stress, mrad (tuned 2026-10-05 by offline simulation)
  public let reaction: Float;      // seconds of lag when tracking a moving target
  public let tracking: Float;      // 0..1, fraction of target motion the shooter compensates
  public let recovery: Float;      // recoil-control skill: 10 = trained (x1 of the weapon's own settle time)
  public let steadiness: Float;    // multiplier on the weapon's own sway (1 = untrained hands)
  public let kickMult: Float;      // recoil control: share of the gun's raw kick that reaches the muzzle
                                   // (V's build gives about 0.28: her Ajax kicks 0.13-0.20 deg against the raw 0.48-0.72)
  public let smartLink: Bool;
  public let kerenzikov: Bool;
  public let affiliation: gamedataAffiliation;
}

@addField(NPCPuppet) public let m_sdpcProfile: ref<SDPShooterProfile>;
@addField(NPCPuppet) public let m_sdpcRecoilX: Float;     // accumulated muzzle displacement from recoil, mrad (+ = right)
@addField(NPCPuppet) public let m_sdpcRecoilY: Float;     // mrad (+ = up)
@addField(NPCPuppet) public let m_sdpcBloom: Float;       // accumulated extra spread from sustained fire, mrad
@addField(NPCPuppet) public let m_sdpcRecoilTime: Float;  // sim time of the last shot
@addField(NPCPuppet) public let m_sdpcShotCount: Int32;   // for weapons whose recoil alternates sides
@addField(NPCPuppet) public let m_sdpcSwayFromX: Float;   // sway path segment, degrees
@addField(NPCPuppet) public let m_sdpcSwayFromY: Float;
@addField(NPCPuppet) public let m_sdpcSwayToX: Float;
@addField(NPCPuppet) public let m_sdpcSwayToY: Float;
@addField(NPCPuppet) public let m_sdpcSwayT0: Float;
@addField(NPCPuppet) public let m_sdpcAimStart: Float;    // when the weapon was last brought up
@addField(NPCPuppet) public let m_sdpcLastZone: Int32;     // zone of this shooter's last aimed shot at V (0 miss, 1 head, 2 torso, 3 legs)
@addField(NPCPuppet) public let m_sdpcLastZoneTime: Float;
@addField(NPCPuppet) public let m_sdpcSpread: Float;        // current spread from sustained fire, degrees
@addField(NPCPuppet) public let m_sdpcSpreadTime: Float;
@addField(NPCPuppet) public let m_sdpcExposure: Float;      // share of V visible at this shooter's last shot (6-point test)
@addField(NPCPuppet) public let m_sdpcExposureTime: Float;

public abstract class SDPProfiles {

  public static func TierName(tier: Int32) -> String {
    if tier == 0 { return "Untrained"; };
    if tier == 1 { return "Poor discipline"; };
    if tier == 2 { return "Trained"; };
    if tier == 3 { return "Elite"; };
    return "Mechanical";
  }

  public static func Affiliation(npc: ref<NPCPuppet>) -> gamedataAffiliation {
    let record = npc.GetRecord();
    if IsDefined(record) && IsDefined(record.Affiliation()) {
      return record.Affiliation().Type();
    };
    return gamedataAffiliation.Unaffiliated;
  }

  // Phase 1 test factions; SetAllHostiles(true) widens enrollment to every hostile human.
  public static func IsPhaseOneFaction(a: gamedataAffiliation) -> Bool {
    return Equals(a, gamedataAffiliation.Maelstrom) || Equals(a, gamedataAffiliation.Arasaka);
  }

  public static func BaseTier(a: gamedataAffiliation) -> Int32 {
    if Equals(a, gamedataAffiliation.Scavengers) || Equals(a, gamedataAffiliation.Animals)
      || Equals(a, gamedataAffiliation.Wraiths) || Equals(a, gamedataAffiliation.Unaffiliated)
      || Equals(a, gamedataAffiliation.Civilian) {
      return 0;
    };
    if Equals(a, gamedataAffiliation.Arasaka) || Equals(a, gamedataAffiliation.Militech)
      || Equals(a, gamedataAffiliation.KangTao) || Equals(a, gamedataAffiliation.NCPD)
      || Equals(a, gamedataAffiliation.SixthStreet) || Equals(a, gamedataAffiliation.Barghest)
      || Equals(a, gamedataAffiliation.NUSA) || Equals(a, gamedataAffiliation.Biotechnica)
      || Equals(a, gamedataAffiliation.Zetatech) || Equals(a, gamedataAffiliation.TraumaTeam)
      || Equals(a, gamedataAffiliation.NetWatch) || Equals(a, gamedataAffiliation.UnaffiliatedCorpo)
      || Equals(a, gamedataAffiliation.AfterlifeMercs) || Equals(a, gamedataAffiliation.SSI)
      || Equals(a, gamedataAffiliation.Classified) {
      return 2;
    };
    return 1; // Maelstrom, Valentinos, Tyger Claws, Mox, Voodoo Boys, nomads and other gangs
  }

  public static func Get(npc: ref<NPCPuppet>) -> ref<SDPShooterProfile> {
    if IsDefined(npc.m_sdpcProfile) { return npc.m_sdpcProfile; };
    let p = new SDPShooterProfile();
    p.affiliation = SDPProfiles.Affiliation(npc);
    let rarity = npc.GetNPCRarity();
    let tier = SDPProfiles.BaseTier(p.affiliation);
    if Equals(rarity, gamedataNPCRarity.Trash) || Equals(rarity, gamedataNPCRarity.Weak) { tier -= 1; };
    if Equals(rarity, gamedataNPCRarity.Elite) || Equals(rarity, gamedataNPCRarity.Officer)
      || Equals(rarity, gamedataNPCRarity.Boss) { tier += 1; };
    if Equals(rarity, gamedataNPCRarity.MaxTac) { tier = 3; };
    tier = Max(0, Min(3, tier));
    if npc.IsMechanical() || npc.IsDrone() { tier = 4; };
    p.tier = tier;

    if tier == 0 { p.sigmaShooter = 18.0; p.reaction = 0.35; p.tracking = 0.50; p.recovery = 5.0; p.steadiness = 1.00; p.kickMult = 0.60; };
    if tier == 1 { p.sigmaShooter = 14.0; p.reaction = 0.30; p.tracking = 0.55; p.recovery = 6.0; p.steadiness = 0.85; p.kickMult = 0.50; };
    if tier == 2 { p.sigmaShooter = 7.0; p.reaction = 0.22; p.tracking = 0.75; p.recovery = 10.0; p.steadiness = 0.60; p.kickMult = 0.36; };
    if tier == 3 { p.sigmaShooter = 4.0; p.reaction = 0.18; p.tracking = 0.82; p.recovery = 16.0; p.steadiness = 0.45; p.kickMult = 0.28; };
    if tier == 4 { p.sigmaShooter = 3.0; p.reaction = 0.15; p.tracking = 0.85; p.recovery = 80.0; p.steadiness = 0.05; p.kickMult = 0.20; };

    let stats = GameInstance.GetStatsSystem(npc.GetGame());
    let id = Cast<StatsObjectID>(npc.GetEntityID());
    p.smartLink = stats.GetStatValue(id, gamedataStatType.HasSmartLink) > 0.0;
    p.kerenzikov = stats.GetStatValue(id, gamedataStatType.HasKerenzikov) > 0.0;
    if p.smartLink {
      p.sigmaShooter *= 0.6;
      p.tracking = MinF(0.95, p.tracking + 0.10);
      p.recovery *= 2.0;
      p.steadiness *= 0.7;
    };
    if p.kerenzikov {
      p.reaction = MinF(p.reaction, 0.08);
      p.tracking = MinF(0.95, p.tracking + 0.07);
    };
    npc.m_sdpcProfile = p;
    return p;
  }

  // Intrinsic dispersion of the weapon class, mrad.
  public static func WeaponSigma(t: gamedataItemType) -> Float {
    if Equals(t, gamedataItemType.Wea_SniperRifle) { return 0.3; };
    if Equals(t, gamedataItemType.Wea_PrecisionRifle) { return 0.6; };
    if Equals(t, gamedataItemType.Wea_AssaultRifle) || Equals(t, gamedataItemType.Wea_Rifle) { return 1.5; };
    if Equals(t, gamedataItemType.Wea_LightMachineGun) { return 2.5; };
    if Equals(t, gamedataItemType.Wea_HeavyMachineGun) { return 3.0; };
    if Equals(t, gamedataItemType.Wea_Revolver) { return 2.5; };
    if Equals(t, gamedataItemType.Wea_Shotgun) || Equals(t, gamedataItemType.Wea_ShotgunDual) { return 4.0; };
    return 3.0; // handguns, SMGs, anything else
  }

  // Muzzle climb per shot, mrad.
  public static func WeaponKick(t: gamedataItemType) -> Float {
    if Equals(t, gamedataItemType.Wea_SniperRifle) { return 6.0; };
    if Equals(t, gamedataItemType.Wea_PrecisionRifle) { return 4.0; };
    if Equals(t, gamedataItemType.Wea_Revolver) { return 4.5; };
    if Equals(t, gamedataItemType.Wea_Shotgun) || Equals(t, gamedataItemType.Wea_ShotgunDual) { return 6.0; };
    if Equals(t, gamedataItemType.Wea_Handgun) { return 3.0; };
    if Equals(t, gamedataItemType.Wea_AssaultRifle) || Equals(t, gamedataItemType.Wea_Rifle) { return 2.5; };
    if Equals(t, gamedataItemType.Wea_LightMachineGun) { return 2.0; };
    if Equals(t, gamedataItemType.Wea_HeavyMachineGun) { return 1.5; };
    return 1.8; // SMGs
  }

  public static func IsShotgun(t: gamedataItemType) -> Bool {
    return Equals(t, gamedataItemType.Wea_Shotgun) || Equals(t, gamedataItemType.Wea_ShotgunDual);
  }
}

// Armour penetration rating per weapon class (higher = defeats more armour). Starting values.
public abstract class SDPCaliber {
  public static func Penetration(weapon: wref<WeaponObject>) -> Float {
    if !IsDefined(weapon) { return 2.0; };
    let t = RPGManager.GetItemType(weapon.GetItemID());
    let pen = 2.0;
    if Equals(t, gamedataItemType.Wea_Handgun) || Equals(t, gamedataItemType.Wea_SubmachineGun) { pen = 2.0; };
    if Equals(t, gamedataItemType.Wea_Revolver) { pen = 3.5; };
    if Equals(t, gamedataItemType.Wea_Shotgun) || Equals(t, gamedataItemType.Wea_ShotgunDual) { pen = 1.5; };
    if Equals(t, gamedataItemType.Wea_AssaultRifle) || Equals(t, gamedataItemType.Wea_Rifle) || Equals(t, gamedataItemType.Wea_LightMachineGun) { pen = 4.0; };
    if Equals(t, gamedataItemType.Wea_PrecisionRifle) { pen = 5.0; };
    if Equals(t, gamedataItemType.Wea_HeavyMachineGun) { pen = 6.0; };
    if Equals(t, gamedataItemType.Wea_SniperRifle) { pen = 6.5; };
    if Equals(weapon.GetWeaponRecord().Evolution().Type(), gamedataWeaponEvolution.Tech) { pen += 1.5; };
    pen += 4.0 * WeaponObject.CanIgnoreArmor(weapon);
    return pen;
  }
}
