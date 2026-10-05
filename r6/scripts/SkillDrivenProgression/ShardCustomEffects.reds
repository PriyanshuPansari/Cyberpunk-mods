// Weapon-local modifier for Bolt's high-grade precision bonus.
module SkillDrivenProgression

@addField(PlayerPuppet)
private let m_sdpBoltWeaponID: EntityID;

@addField(PlayerPuppet)
private let m_sdpBoltHeadshotMod: ref<gameStatModifierData>;

@addMethod(PlayerPuppet)
public final func SDP_BoltUpdateWeapon(active: Bool) -> Void {
  let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(this);
  let nextID: EntityID;
  if active && IsDefined(weapon)
    && Equals(RPGManager.GetWeaponEvolution(weapon.GetItemID()), gamedataWeaponEvolution.Tech) {
    nextID = weapon.GetEntityID();
  };
  if EntityID.IsDefined(nextID) && nextID == this.m_sdpBoltWeaponID
    && IsDefined(this.m_sdpBoltHeadshotMod) { return; };

  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  if EntityID.IsDefined(this.m_sdpBoltWeaponID) && IsDefined(this.m_sdpBoltHeadshotMod) {
    stats.RemoveModifier(Cast<StatsObjectID>(this.m_sdpBoltWeaponID), this.m_sdpBoltHeadshotMod);
  };
  this.m_sdpBoltHeadshotMod = null;
  this.m_sdpBoltWeaponID = nextID;
  if EntityID.IsDefined(nextID) {
    let modifier: ref<gameStatModifierData> = RPGManager.CreateStatModifier(
      gamedataStatType.HeadshotDamageMultiplier, gameStatModifierType.Additive, 0.05
    );
    if stats.AddModifier(Cast<StatsObjectID>(nextID), modifier) {
      this.m_sdpBoltHeadshotMod = modifier;
    };
  };
}
