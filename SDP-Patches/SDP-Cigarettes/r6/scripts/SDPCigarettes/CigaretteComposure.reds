module SkillDrivenProgression

// Composure: the cigarette buff. The status effect (Cigarettes.yaml) gives the
// HUD icon, 5-minute timer and single stack; this file applies its effects:
//   - +10% XP for all five skills (Solo, Shinobi, Engineer, Netrunner, Headhunter)
//   - Steady hands: 15% less recoil kick and base spread on the equipped weapon

public func SDP_ComposureActive(owner: wref<GameObject>) -> Bool {
  return IsDefined(owner)
    && StatusEffectSystem.ObjectHasStatusEffect(owner, t"SkillDrivenProgression.Composure");
}

// Called once a cigarette has actually been smoked (after any animation).
public func SDP_OnCigaretteSmoked(player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(player) { return; };
  StatusEffectHelper.ApplyStatusEffect(player, t"SkillDrivenProgression.Composure");
  player.SDP_SteadyAimTick();
}

// ---- Skill XP -------------------------------------------------------------

@addField(PlayerDevelopmentData)
private let m_sdpComposureCarry: Float;

@wrapMethod(PlayerDevelopmentData)
public final const func AddExperience(amount: Int32, type: gamedataProficiencyType, telemetryGainReason: telemetryLevelGainReason, opt isDebug: Bool) -> Void {
  let awarded: Int32 = amount;
  if !isDebug && amount > 0 && SDP_IsSkillProficiency(type)
    && IsDefined(this.m_owner) && this.m_owner.IsPlayerControlled()
    && SDP_ComposureActive(this.m_owner) {
    // Fractions carry over so small awards still get their bonus over time.
    let exact: Float = Cast<Float>(amount) * 1.10 + this.m_sdpComposureCarry;
    awarded = FloorF(exact);
    this.m_sdpComposureCarry = exact - Cast<Float>(awarded);
  };
  wrappedMethod(awarded, type, telemetryGainReason, isDebug);
}

// ---- Steady hands ---------------------------------------------------------

// Twice a second from the SDP Core loop (CigaretteLifecycle.reds registers it).
public class SDPCigarettesTick extends SDPTickListener {
  public func Key() -> CName { return n"SDP.Cigarettes"; }
  public func Tick(player: ref<PlayerPuppet>, seconds: Float) -> Void { player.SDP_SteadyAimTick(); }
}

@addField(PlayerPuppet)
private let m_sdpSteadyWeapon: EntityID;

@addField(PlayerPuppet)
private let m_sdpSteadyMods: array<ref<gameStatModifierData>>;

// Puts the modifiers on the equipped weapon while Composure is active and
// moves them when the weapon changes; removes them when it ends.
@addMethod(PlayerPuppet)
public final func SDP_SteadyAimTick() -> Void {
  let nextID: EntityID;
  if SDP_ComposureActive(this) {
    let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(this);
    if IsDefined(weapon) { nextID = weapon.GetEntityID(); };
  };
  if nextID == this.m_sdpSteadyWeapon { return; };
  this.SDP_ClearSteadyAim();
  if !EntityID.IsDefined(nextID) { return; };
  this.m_sdpSteadyWeapon = nextID;
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  let weaponID: StatsObjectID = Cast<StatsObjectID>(nextID);
  let types: array<gamedataStatType> = [
    gamedataStatType.RecoilKickMin, gamedataStatType.RecoilKickMax,
    gamedataStatType.RecoilKickMinADS, gamedataStatType.RecoilKickMaxADS,
    gamedataStatType.SpreadDefaultX, gamedataStatType.SpreadDefaultY,
    gamedataStatType.SpreadAdsDefaultX, gamedataStatType.SpreadAdsDefaultY
  ];
  for statType in types {
    let modifier: ref<gameStatModifierData> = RPGManager.CreateStatModifier(
      statType, gameStatModifierType.Multiplier, 0.85
    );
    if stats.AddModifier(weaponID, modifier) { ArrayPush(this.m_sdpSteadyMods, modifier); };
  };
}

@addMethod(PlayerPuppet)
public final func SDP_ClearSteadyAim() -> Void {
  if EntityID.IsDefined(this.m_sdpSteadyWeapon) {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
    let weaponID: StatsObjectID = Cast<StatsObjectID>(this.m_sdpSteadyWeapon);
    for modifier in this.m_sdpSteadyMods {
      stats.RemoveModifier(weaponID, modifier);
    };
  };
  ArrayClear(this.m_sdpSteadyMods);
  let none: EntityID;
  this.m_sdpSteadyWeapon = none;
}
