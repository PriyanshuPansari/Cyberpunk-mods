module SDPCE

// CE capability layer (4.12.0): doctrine abilities (cover preference, sprint harass, catch-up policy).
// SDPCombat cut-down: melee swarm charges and the grapple-duration hook removed (ENC owns grapples).

public class GBPCapability {

  public static func IsMeleeArchetype(arch: GBPChromeArchetype) -> Bool {
    return Equals(arch, GBPChromeArchetype.GenericMelee)
      || Equals(arch, GBPChromeArchetype.FastMelee)
      || Equals(arch, GBPChromeArchetype.HeavyMelee);
  }

  public static func IsRangedArchetype(arch: GBPChromeArchetype) -> Bool {
    return Equals(arch, GBPChromeArchetype.GenericRanged)
      || Equals(arch, GBPChromeArchetype.FastRanged)
      || Equals(arch, GBPChromeArchetype.HeavyRanged)
      || Equals(arch, GBPChromeArchetype.Sniper)
      || Equals(arch, GBPChromeArchetype.Shotgunner)
      || Equals(arch, GBPChromeArchetype.Officer);   
                                                     
  }

  public static func GrantAbility(puppet: ref<ScriptedPuppet>, id: TweakDBID) -> Void {
    let rec = TweakDBInterface.GetGameplayAbilityRecord(id);
    if !IsDefined(rec) { return; };
    RPGManager.ApplyAbility(puppet, rec);
    if !ArrayContains(GBPStateOf(puppet).GBP_chromeAbilities, id) {
      ArrayPush(GBPEnsureState(puppet).GBP_chromeAbilities, id);
    };
  }

  public static func Apply(puppet: ref<ScriptedPuppet>, factionIndex: Int32) -> Void {
    let st: ref<GBPNpcState> = GBPStateOf(puppet);
    if st.GBP_isBoss { return; };
    
    
    if !GBPManeuversOn(puppet.GetGame()) { return; };
    let profile: ref<GBPProfile> = GBPProfiles.GetProfile(factionIndex);
    if !IsDefined(profile) { return; };
    let arch: GBPChromeArchetype = GBPChromeDetect.Archetype(puppet);

    if st.GBP_rarityVal == 6 && st.GBP_bossStyle == 0 {
        GBPEnsureState(puppet).GBP_bossStyle = RandRange(1, 4);
    };

    let style: array<TweakDBID> = profile.GetStyleAbilities(arch, st.GBP_rarityVal);
    let i: Int32 = 0;
    while i < ArraySize(style) {
      GBPCapability.GrantAbility(puppet, style[i]);
      i += 1;
    };

    let catchUp: Int32 = profile.GetCatchUpPolicy();
    if GBPStateOf(puppet).GBP_bossStyle == 3 { catchUp = 2; };   
    if catchUp == 0 {
      let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(puppet.GetGame());
      if IsDefined(statsSystem) && !IsDefined(st.GBP_modCatchUpStrip) {
        let entityID: StatsObjectID = Cast<StatsObjectID>(puppet.GetEntityID());
        let m1 = RPGManager.CreateStatModifier(gamedataStatType.CanCatchUp, gameStatModifierType.Additive, -100.0);
        let m2 = RPGManager.CreateStatModifier(gamedataStatType.CanCatchUpDistance, gameStatModifierType.Additive, -100.0);
        GBPEnsureState(puppet).GBP_modCatchUpStrip = m1;
        GBPEnsureState(puppet).GBP_modCatchUpDistStrip = m2;
        statsSystem.AddModifier(entityID, m1);
        statsSystem.AddModifier(entityID, m2);
      };
    } else {
      if catchUp == 2 {
        GBPCapability.GrantAbility(puppet, t"Ability.CanCatchUp");
        GBPCapability.GrantAbility(puppet, t"Ability.CanCatchUpDistance");
      };
    };

    if !profile.GetGuardBreakEligible(st.GBP_rarityVal) { return; };
    if !GBPCapability.IsMeleeArchetype(arch) { return; };
    GBPCapability.GrantAbility(puppet, t"Ability.CanGuardBreak");
  }
}
