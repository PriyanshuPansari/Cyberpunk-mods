// Present Skill Rank (1-296) in the player-level UI without changing the
// internal 1-60 level used by game systems. The bar spans all 295 rank gains.
//
// UpdateUIBB is REPLACED (not wrapped) on purpose. Vanilla writes the internal
// level (1-60) to UI_PlayerStats.Level with force=true; a wrap then overwrote
// it with the rank. The HUD level widget (healthbarWidgetGameController.
// AnimateCharacterLevelUpdated) plays the level-up arrow + sound whenever the
// value differs from what it last saw, so every UpdateUIBB call (every XP
// gain, every menu stats request) flipped 12 -> 56 -> 12 -> 56 and replayed the
// level-up. Now the board only ever receives the rank, written once and
// without force, so the arrow plays only when the rank really rises.
// Body below is vanilla (decompiled from the installed final.redscripts)
// with only the Level / CurrentXP / RequiredXP values changed.
module SkillDrivenProgression

@replaceMethod(PlayerDevelopmentData)
public final const func UpdateUIBB() -> Void {
  let gi = this.m_owner.GetGame();
  let skillRank: Int32 = this.SDP_GetSkillRank();
  let m_ownerStatsBB = GameInstance.GetBlackboardSystem(gi).Get(GetAllBlackboardDefs().UI_PlayerStats);
  if IsDefined(m_ownerStatsBB)
    && this.m_owner == GameInstance.GetPlayerSystem(gi).GetLocalPlayerMainGameObject() {
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.Level,
        skillRank,
        false
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.CurrentXP,
        skillRank - 1,
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.RequiredXP,
        295,
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.StreetCredLevel,
        this.GetProficiencyLevel(gamedataProficiencyType.StreetCred),
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.StreetCredPoints,
        this.GetCurrentLevelProficiencyExp(gamedataProficiencyType.StreetCred),
        true
      );
    m_ownerStatsBB
      .SetVariant(
        GetAllBlackboardDefs().UI_PlayerStats.DevelopmentPoints,
        ToVariant(this.m_devPoints),
        true
      );
    m_ownerStatsBB
      .SetVariant(
        GetAllBlackboardDefs().UI_PlayerStats.Proficiency,
        ToVariant(this.m_proficiencies),
        true
      );
    m_ownerStatsBB
      .SetVariant(
        GetAllBlackboardDefs().UI_PlayerStats.Perks,
        ToVariant(this.m_perkAreas),
        true
      );
    m_ownerStatsBB
      .SetVariant(
        GetAllBlackboardDefs().UI_PlayerStats.Attributes,
        ToVariant(this.m_attributes),
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.PhysicalResistance,
        Cast<Int32>(
          GameInstance
            .GetStatsSystem(gi)
            .GetStatValue(
              Cast<StatsObjectID>(this.m_owner.GetEntityID()),
              gamedataStatType.PhysicalResistance
            )
        ),
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.ThermalResistance,
        Cast<Int32>(
          GameInstance
            .GetStatsSystem(gi)
            .GetStatValue(
              Cast<StatsObjectID>(this.m_owner.GetEntityID()),
              gamedataStatType.ThermalDamage
            )
        ),
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.EnergyResistance,
        Cast<Int32>(
          GameInstance
            .GetStatsSystem(gi)
            .GetStatValue(
              Cast<StatsObjectID>(this.m_owner.GetEntityID()),
              gamedataStatType.ElectricResistance
            )
        ),
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.ChemicalResistance,
        Cast<Int32>(
          GameInstance
            .GetStatsSystem(gi)
            .GetStatValue(
              Cast<StatsObjectID>(this.m_owner.GetEntityID()),
              gamedataStatType.ChemicalResistance
            )
        ),
        true
      );
    m_ownerStatsBB
      .SetInt(
        GetAllBlackboardDefs().UI_PlayerStats.weightMax,
        Cast<Int32>(
          GameInstance
            .GetStatsSystem(gi)
            .GetStatValue(
              Cast<StatsObjectID>(this.m_owner.GetEntityID()),
              gamedataStatType.CarryCapacity
            )
        ),
        true
      );
  }
}


@wrapMethod(PlayerDevelopmentSystem)
public final const func GetRemainingExpForLevelUp(owner: ref<GameObject>, type: gamedataProficiencyType) -> Int32 {
  if Equals(type, gamedataProficiencyType.Level) && IsDefined(owner) && owner.IsPlayerControlled() {
    let data: ref<PlayerDevelopmentData> = this.GetDevelopmentData(owner);
    if IsDefined(data) {
      return Max(0, 296 - data.SDP_GetSkillRank());
    };
  };
  return wrappedMethod(owner, type);
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnCharacterLevelCurrentXPUpdated(value: Int32) -> Bool {
  let result: Bool = wrappedMethod(value);
  inkTextRef.SetText(this.m_expText, IntToString(value) + "/295");
  inkTextRef.SetText(this.m_expTextLabel, "Skills gained");
  return result;
}
