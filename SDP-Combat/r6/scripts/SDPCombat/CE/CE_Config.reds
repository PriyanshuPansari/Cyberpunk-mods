module SDPCE

// SDPCombat cut-down of Combat Evolved 4.16.8 (nexus 29125, by DigitalVixen): config.
// Personal-install fork. Only maneuvers (flank, cover eject, suppression), fear/flee/detection panic and limb
// crippling run; every switch for removed systems is off and the code behind it is gone. No settings UI:
// change values here.

public class GBPConfig extends ScriptableSystem {

  public let modON: Bool = true;

  public let enableManeuvers: Bool = true;

  public let showGangSettings: Bool = false;

  public let leoCompatibility: Bool = false;

  public let enableShootingSystem: Bool = false;

  public let mercyTimer: Float = 0.0;

  public let firingAggression: Float = 0.5;

  public let enablePerkEvasion: Bool = false;

  public let stunDuration: Float = 1.6;

  public let enableLimbCripple: Bool = true;

  public let armCrippleThreshold: Float = 0.30;

  public let legCrippleThreshold: Float = 0.40;

  public let enableCombatHealing: Bool = false;

  public let healingMinRarity: Int32 = 3;

  public let unlimitedMeleeTickets: Bool = false;

  public let backstabMultiplier: Float = 2.0;

  public let backstabAngle: Int32 = 60;

  public let quickhackScaleEnabled: Bool = false;

  public let quickhackUserMult: Float = 1.0;

  public let enableBossOverhaul: Bool = false;

  public let smasherHpMult: Float = 1.0;
  public let smasherArmorMult: Float = 1.0;
  public let smasherDmgMult: Float = 1.0;

  public let odaHpMult: Float = 1.0;
  public let odaArmorMult: Float = 1.0;
  public let odaDmgMult: Float = 1.0;

  public let royceHpMult: Float = 1.0;
  public let royceArmorMult: Float = 1.0;
  public let royceDmgMult: Float = 1.0;

  public let sasquatchHpMult: Float = 1.0;
  public let sasquatchArmorMult: Float = 1.0;
  public let sasquatchDmgMult: Float = 1.0;

  public let kurtHpMult: Float = 1.0;
  public let kurtArmorMult: Float = 1.0;
  public let kurtDmgMult: Float = 1.0;

  public let chimeraHpMult: Float = 1.0;
  public let chimeraArmorMult: Float = 1.0;
  public let chimeraDmgMult: Float = 1.0;

  public let ribakovHpMult: Float = 1.0;
  public let ribakovArmorMult: Float = 1.0;
  public let ribakovDmgMult: Float = 1.0;

  public let yashaHpMult: Float = 1.0;
  public let yashaArmorMult: Float = 1.0;
  public let yashaDmgMult: Float = 1.0;

  public let woodmanHpMult: Float = 1.0;
  public let woodmanArmorMult: Float = 1.0;
  public let woodmanDmgMult: Float = 1.0;

  public let placideHpMult: Float = 1.0;
  public let placideArmorMult: Float = 1.0;
  public let placideDmgMult: Float = 1.0;

  public let rmk2HpMult: Float = 1.0;
  public let rmk2ArmorMult: Float = 1.0;
  public let rmk2DmgMult: Float = 1.0;

  public let maxtacOperatorHpMult: Float = 1.0;
  public let maxtacOperatorArmorMult: Float = 1.0;
  public let maxtacOperatorDmgMult: Float = 1.0;

  public let zarinHpMult: Float = 1.0;
  public let zarinArmorMult: Float = 1.0;
  public let zarinDmgMult: Float = 1.0;

  public let mrsDroneHpMult: Float = 1.0;
  public let mrsDroneArmorMult: Float = 1.0;
  public let mrsDroneDmgMult: Float = 1.0;

  public let militechMechHpMult: Float = 1.0;
  public let militechMechArmorMult: Float = 1.0;
  public let militechMechDmgMult: Float = 1.0;

  public let cyberpsychoHealthMult: Float = 1.0;

  public let cyberpsychoArmorMult: Float = 1.0;

  public let brawlerHpMult: Float = 1.0;

  public let cyberpsychoDmgMult: Float = 1.0;

  public let enableEvasionControl: Bool = false;

  public let evasionStrictMode: Bool = false;

  public let evasionFlatBonus: Float = 25.0;

  public let evasionLevelBonus: Float = 0.5;

  public let evasionSniperMult: Float = 2.0;

  public let evasionPrecisionMult: Float = 1.6;

  public let evasionRevolverMult: Float = 1.5;

  public let evasionPistolMult: Float = 1.4;

  public let evasionARMult: Float = 1.3;

  public let evasionSMGMult: Float = 1.2;

  public let evasionShotgunMult: Float = 1.0;

  public let evasionLMGMult: Float = 1.0;

  public let evasionLauncherMult: Float = 3.0;

  public let evasionTechMult: Float = 1.2;

  public let evasionSmartMult: Float = 1.1;

  public let evasionPowerMult: Float = 1.0;

  public let evasionThrowableMult: Float = 2.5;

  public let enableFear: Bool = true;

  public let fearStreetCredStrength: Float = 1.0;

  public let detectionFearCap: Int32 = 70;

  public let decimationStrength: Float = 1.0;

  public let npcDifficulty: Int32 = 100;

  public let globalAccuracyMult: Int32 = 500;

  public let globalHpBase: Int32 = 200;

  public let hpTierTrash: Float = 0.70;

  public let hpTierWeak: Float = 0.85;

  public let hpTierNormal: Float = 1.00;

  public let hpTierRare: Float = 1.25;

  public let hpTierElite: Float = 1.45;

  public let hpTierOfficer: Float = 1.45;

  public let hpTierStreetBoss: Float = 1.60;

  public let hpTierMaxTac: Float = 1.60;

  public let maxTacArmorMult: Float = 2.0;

  public let enableNpcHpOverride: Bool = false;

  public let enablePlayerHpOverride: Bool = false;

  public let playerHpFlat: Int32 = 200;

  public let forceArmorPipeline: Bool = false;

  public let enableFactionWeaknesses: Bool = true;

  public let npcMaxMitigation: Int32 = 70;

  public let npcArmorDurability: Int32 = 100;

  public let armorIntegrityBleed: Int32 = 100;

  public let armorCurveMode: Bool = false;

  public let armorCurveStrength: Int32 = 5;

  public let bossArmorRepairScale: Int32 = 100;

  public let resistanceIntensity: Int32 = 100;

  public let debugON: Bool = false;

  public let showArmorDebug: Bool = false;

  public let enableZombieSweep: Bool = false;

  public let zombiePurge: Bool = false;

  public let unstickOnHit: Bool = false;

  public let chromeDebug: Bool = false;

  public let codewareDeleteDelaySec: Int32 = 180;

  public let zombiePurgeDelaySec: Int32 = 2;

  public let enableChromeDist: Bool = true;

  public let chromeDensity: Float = 1.0;

  public let showChromeFactions: Bool = false;

  public let chromeMaelstrom: Bool = true;

  public let chromeTygerClaws: Bool = true;

  public let chromeAnimals: Bool = true;

  public let chromeVoodooBoys: Bool = true;

  public let chromeScavengers: Bool = true;

  public let chromeMilitech: Bool = true;

  public let chromeArasaka: Bool = true;

  public let chromeSixthStreet: Bool = true;

  public let chromeWraiths: Bool = true;

  public let chromeValentinos: Bool = true;

  public let chromeAldecaldos: Bool = true;

  public let chromeNCPD: Bool = true;

  public let unaffiliatedAccuracy: Float = 1.25;

  public let unaffiliatedSpeed: Float = 0.45;

  public let unaffiliatedHealth: Float = 1.00;

  public let unaffiliatedArmorMin: Int32 = 50;

  public let unaffiliatedArmorMax: Int32 = 350;

  public let unaffiliatedRarityScale: Float = 0.13;

  public let maelstromAccuracy: Float = 1.23;

  public let maelstromSpeed: Float = 0.35;

  public let maelstromHealth: Float = 0.70;

  public let maelstromArmorMin: Int32 = 400;

  public let maelstromArmorMax: Int32 = 1300;

  public let maelstromRarityScale: Float = 0.15;

  public let tygerClawsAccuracy: Float = 1.28;

  public let tygerClawsSpeed: Float = 0.70;

  public let tygerClawsHealth: Float = 1.15;

  public let tygerClawsArmorMin: Int32 = 15;

  public let tygerClawsArmorMax: Int32 = 150;

  public let tygerClawsRarityScale: Float = 0.12;

  public let animalsAccuracy: Float = 0.68;

  public let animalsSpeed: Float = 1.60;

  public let animalsHealth: Float = 1.60;

  public let animalsArmorMin: Int32 = 10;

  public let animalsArmorMax: Int32 = 120;

  public let animalsRarityScale: Float = 0.20;

  public let scavengersAccuracy: Float = 0.83;

  public let scavengersSpeed: Float = 0.90;

  public let scavengersHealth: Float = 0.85;

  public let scavengersArmorMin: Int32 = 5;

  public let scavengersArmorMax: Int32 = 80;

  public let scavengersRarityScale: Float = 0.18;

  public let valentinosAccuracy: Float = 1.17;

  public let valentinosSpeed: Float = 0.65;

  public let valentinosHealth: Float = 1.15;

  public let valentinosArmorMin: Int32 = 25;

  public let valentinosArmorMax: Int32 = 280;

  public let valentinosRarityScale: Float = 0.14;

  public let voodooBoysAccuracy: Float = 0.98;

  public let voodooBoysSpeed: Float = 0.30;

  public let voodooBoysHealth: Float = 0.80;

  public let voodooBoysArmorMin: Int32 = 5;

  public let voodooBoysArmorMax: Int32 = 60;

  public let voodooBoysRarityScale: Float = 0.10;

  public let sixthStreetAccuracy: Float = 1.32;

  public let sixthStreetSpeed: Float = 0.35;

  public let sixthStreetHealth: Float = 1.00;

  public let sixthStreetArmorMin: Int32 = 110;

  public let sixthStreetArmorMax: Int32 = 450;

  public let sixthStreetRarityScale: Float = 0.12;

  public let arasakaAccuracy: Float = 1.47;

  public let arasakaSpeed: Float = 0.55;

  public let arasakaHealth: Float = 1.00;

  public let arasakaArmorMin: Int32 = 175;

  public let arasakaArmorMax: Int32 = 600;

  public let arasakaRarityScale: Float = 0.08;

  public let militechAccuracy: Float = 1.35;

  public let militechSpeed: Float = 0.22;

  public let militechHealth: Float = 1.00;

  public let militechArmorMin: Int32 = 175;

  public let militechArmorMax: Int32 = 900;

  public let militechRarityScale: Float = 0.10;

  public let kangTaoAccuracy: Float = 1.44;

  public let kangTaoSpeed: Float = 0.40;

  public let kangTaoHealth: Float = 1.00;

  public let kangTaoArmorMin: Int32 = 110;

  public let kangTaoArmorMax: Int32 = 420;

  public let kangTaoRarityScale: Float = 0.10;

  public let traumaTeamAccuracy: Float = 1.32;

  public let traumaTeamSpeed: Float = 0.30;

  public let traumaTeamHealth: Float = 1.15;

  public let traumaTeamArmorMin: Int32 = 175;

  public let traumaTeamArmorMax: Int32 = 700;

  public let traumaTeamRarityScale: Float = 0.08;

  public let wraithsAccuracy: Float = 1.20;

  public let wraithsSpeed: Float = 0.95;

  public let wraithsHealth: Float = 1.00;

  public let wraithsArmorMin: Int32 = 20;

  public let wraithsArmorMax: Int32 = 180;

  public let wraithsRarityScale: Float = 0.16;

  public let barghestAccuracy: Float = 1.32;

  public let barghestSpeed: Float = 0.42;

  public let barghestHealth: Float = 1.00;

  public let barghestArmorMin: Int32 = 75;

  public let barghestArmorMax: Int32 = 500;

  public let barghestRarityScale: Float = 0.14;

  public let ncpdAccuracy: Float = 1.28;

  public let ncpdSpeed: Float = 0.32;

  public let ncpdHealth: Float = 1.00;

  public let ncpdArmorMin: Int32 = 200;

  public let ncpdArmorMax: Int32 = 450;

  public let ncpdRarityScale: Float = 0.14;

  public let moxAccuracy: Float = 1.02;

  public let moxSpeed: Float = 0.38;

  public let moxHealth: Float = 0.70;

  public let moxArmorMin: Int32 = 15;

  public let moxArmorMax: Int32 = 200;

  public let moxRarityScale: Float = 0.12;

  public let aldecaldosAccuracy: Float = 1.17;

  public let aldecaldosSpeed: Float = 0.45;

  public let aldecaldosHealth: Float = 1.00;

  public let aldecaldosArmorMin: Int32 = 30;

  public let aldecaldosArmorMax: Int32 = 300;

  public let aldecaldosRarityScale: Float = 0.14;

  public let netwatchAccuracy: Float = 1.13;

  public let netwatchSpeed: Float = 0.35;

  public let netwatchHealth: Float = 0.85;

  public let netwatchArmorMin: Int32 = 20;

  public let netwatchArmorMax: Int32 = 250;

  public let netwatchRarityScale: Float = 0.12;

  public let biotechnicaAccuracy: Float = 1.17;

  public let biotechnicaSpeed: Float = 0.40;

  public let biotechnicaHealth: Float = 0.90;

  public let biotechnicaArmorMin: Int32 = 20;

  public let biotechnicaArmorMax: Int32 = 200;

  public let biotechnicaRarityScale: Float = 0.10;

  public let nusaAccuracy: Float = 1.40;

  public let nusaSpeed: Float = 0.48;

  public let nusaHealth: Float = 1.05;

  public let nusaArmorMin: Int32 = 175;

  public let nusaArmorMax: Int32 = 500;

  public let nusaRarityScale: Float = 0.14;

  public let afterlifeAccuracy: Float = 1.34;

  public let afterlifeSpeed: Float = 0.42;

  public let afterlifeHealth: Float = 0.95;

  public let afterlifeArmorMin: Int32 = 75;

  public let afterlifeArmorMax: Int32 = 550;

  public let afterlifeRarityScale: Float = 0.14;

  public let staggerEnabled: Bool = true;

  public let staggerSeverity: Float = 1.0;

  public let staggerCooldownSec: Float = 1.0;

  public let cameraImpactEnabled: Bool = true;

  public let cameraImpactCooldownSec: Float = 0.25;

  public let cameraImpactHitThreshold: Float = 0.03;

  public let cameraImpactWorldExplosions: Bool = true;

  public let cameraImpactMagnitude: Float = 2.0;
  public let cameraImpactDuration: Float = 0.8;
  
  public let cameraImpactFinalMult: Float = 1.0;

  public let explosionGrenadeIntensity: Float = 1.2;
  public let explosionGrenadeDuration: Float = 0.6;
  public let explosionGrenadeSpeed: Float = 2.5;
  public let explosionMineIntensity: Float = 2.0;
  public let explosionMineDuration: Float = 1.0;
  public let explosionMineSpeed: Float = 6.0;
  public let explosionVehicleIntensity: Float = 2.5;
  public let explosionVehicleDuration: Float = 1.6;
  public let explosionVehicleSpeed: Float = 2.0;
  public let explosionOtherIntensity: Float = 1.2;
  public let explosionOtherDuration: Float = 1.0;
  public let explosionOtherSpeed: Float = 2.5;

  public static func Get(gi: GameInstance) -> ref<GBPConfig> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"SDPCE.GBPConfig") as GBPConfig;
  }

}

public func GBPManeuversOn(gi: GameInstance) -> Bool {
  let cfg: ref<GBPConfig> = GBPConfig.Get(gi);
  return IsDefined(cfg) && cfg.modON && cfg.enableManeuvers;
}
