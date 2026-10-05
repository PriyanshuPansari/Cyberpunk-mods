module SDPCE
// Combat Evolved - Detection Panic ε=ε=ε=┌(;*´Д`)ノ

@wrapMethod(SenseComponent)
public final func ReevaluateDetectionOverwrite(target: wref<GameObject>, opt isVisible: Bool) -> Bool {
    let result = wrappedMethod(target, isVisible);

    if !IsDefined(target) || !target.IsPlayer() { return result; }

    let owner = this.GetOwnerPuppet();
    if !IsDefined(owner) { return result; }

    let npc = owner as ScriptedPuppet;
    if !IsDefined(npc) { return result; }

    if GBPStateOf(npc).GBP_detectionRolled { return result; }

    let cfg = GBPConfig.Get(npc.GetGame());
    if !IsDefined(cfg) || !cfg.modON || !cfg.enableFear { return result; }

    if !GBPStateOf(npc).GBP_factionCached || GBPStateOf(npc).GBP_factionIndex < 0 { return result; }
    if GBPStateOf(npc).GBP_unbreakable || GBPStateOf(npc).GBP_shouldFlee { return result; }
    if GBPIsCorpse(npc) { return result; }

    let myAgent: ref<AttitudeAgent> = npc.GetAttitudeAgent();
    let theirAgent: ref<AttitudeAgent> = (target as ScriptedPuppet).GetAttitudeAgent();
    if IsDefined(myAgent) && IsDefined(theirAgent)
        && !Equals(myAgent.GetAttitudeTowards(theirAgent), EAIAttitude.AIA_Hostile) {
        return result;
    }

    let detection: Float = this.GetDetection(target.GetEntityID());
    if detection < 100.0 { return result; }
    if !this.IsAgentVisible(target) { return result; }

    GBPEnsureState(npc).GBP_detectionRolled = true;

    let profile = GBPProfiles.GetProfile(GBPStateOf(npc).GBP_factionIndex);
    if !IsDefined(profile) { return result; }
    let chance: Float = profile.GetDetectionFearChance(GBPStateOf(npc).GBP_rarityVal);
    if chance <= 0.0 { return result; }

    let diffMult: Float = GBPSystem.GetDifficultyFearMult(cfg.npcDifficulty);
    let effectiveChance: Float = chance * diffMult;

    let traits = GBPStateOf(npc).GBP_traits;
    
    if GBPSystem.HasTrait(traits, GBPSystem.TraitFormationFighter()) || GBPSystem.HasTrait(traits, GBPSystem.TraitSteady()) { effectiveChance = effectiveChance * 0.25; }
    if GBPSystem.HasTrait(traits, GBPSystem.TraitCyberJunkie()) { effectiveChance = effectiveChance * 0.5; }

    let districtMod: Float = GBPStateOf(npc).GBP_districtFearMod;
    if districtMod < 0.01 { districtMod = 1.0; }
    effectiveChance = effectiveChance * districtMod;

    let credMult: Float = GBPSystem.GetStreetCredFearMult(npc.GetGame(), GBPStateOf(npc).GBP_rarityVal, cfg);
    effectiveChance = MinF(effectiveChance * credMult, Cast<Float>(cfg.detectionFearCap) / 100.0);

    let roll: Float = RandF();
    if roll >= effectiveChance { return result; }

    GBPSystem.Note(npc.GetGame(), 0);
    let delay: Float = 0.3 + RandF() * 0.8;
    GameInstance.GetDelaySystem(npc.GetGame()).DelayCallback(GBPFearCallback.Create(npc), delay, false);

    if cfg.debugON {
        GBPLog("[GBP] Detection panic: " + TDBID.ToStringDEBUG(npc.GetRecordID())
            + " (faction=" + ToString(GBPStateOf(npc).GBP_factionIndex)
            + ", rarity=" + ToString(GBPStateOf(npc).GBP_rarityVal)
            + ", cred x" + FloatToStringPrec(credMult, 2)
            + ", chance=" + FloatToStringPrec(effectiveChance * 100.0, 1) + "%)");
    }

    return result;
}
