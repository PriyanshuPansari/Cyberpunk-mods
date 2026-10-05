module SDPCE

// Combat Evolved - Trait-based Ring Override ╰(°▽°)╯

@wrapMethod(SquadMemberBaseComponent)
protected cb func OnSquadActionEvent(evt: ref<SquadActionEvent>) -> Bool {
    let result = wrappedMethod(evt);

    if !Equals(evt.squadVerb, EAISquadVerb.AcknowledgeOrder) { return result; };

    let puppet: ref<ScriptedPuppet> = this.GetEntity() as ScriptedPuppet;
    if !IsDefined(puppet) { return result; };
    if !GBPStateOf(puppet).GBP_factionCached || GBPStateOf(puppet).GBP_shouldFlee { return result; };

    let bb: ref<IBlackboard> = AICoverHelper.GetCoverBlackboard(puppet);
    if !IsDefined(bb) { return result; };

    let currentRing: gamedataAIRingType = FromVariant<gamedataAIRingType>(
        bb.GetVariant(GetAllBlackboardDefs().AICover.currentRing));
    if Equals(currentRing, gamedataAIRingType.Invalid) { return result; };

    let override: gamedataAIRingType = currentRing;
    let traits: Int32 = GBPStateOf(puppet).GBP_traits;
    
    let melee: Bool = GBPCapability.IsMeleeArchetype(GBPChromeDetect.Archetype(puppet));

    if GBPSystem.HasTrait(traits, GBPSystem.TraitRusher()) {
        if Equals(currentRing, gamedataAIRingType.Extreme) {
            override = gamedataAIRingType.Medium;
        } else {
            if Equals(currentRing, gamedataAIRingType.Far) {
                override = gamedataAIRingType.Close;
            };
        };
    };

    if !melee && (GBPSystem.HasTrait(traits, GBPSystem.TraitCoward()) || GBPSystem.HasTrait(traits, GBPSystem.TraitCautious())) {
        if Equals(currentRing, gamedataAIRingType.Melee) || Equals(currentRing, gamedataAIRingType.Close) || Equals(currentRing, gamedataAIRingType.Medium) {
            override = gamedataAIRingType.Far;
        };
    };

    if !melee && GBPSystem.HasTrait(traits, GBPSystem.TraitFormationFighter()) {
        if Equals(currentRing, gamedataAIRingType.Melee) || Equals(currentRing, gamedataAIRingType.Close) {
            override = gamedataAIRingType.Medium;
        };
    };

    if GBPSystem.HasTrait(traits, GBPSystem.TraitShowOff()) {
        if Equals(currentRing, gamedataAIRingType.Extreme) {
            override = gamedataAIRingType.Far;
        } else {
            if Equals(currentRing, gamedataAIRingType.Far) {
                override = gamedataAIRingType.Medium;
            };
        };
    };

    if !melee && GBPStateOf(puppet).GBP_moraleWound > 0.3 {
        if Equals(override, gamedataAIRingType.Melee) || Equals(override, gamedataAIRingType.Close) {
            override = gamedataAIRingType.Medium;
        };
    };

    if !melee && GBPStateOf(puppet).GBP_districtFearMod > 1.1 {
        if Equals(override, gamedataAIRingType.Melee) {
            override = gamedataAIRingType.Close;
        } else {
            if Equals(override, gamedataAIRingType.Close) {
                override = gamedataAIRingType.Medium;
            };
        };
    };

    if GBPStateOf(puppet).GBP_districtFearMod < 0.9 {
        if Equals(override, gamedataAIRingType.Extreme) {
            override = gamedataAIRingType.Far;
        } else {
            if Equals(override, gamedataAIRingType.Far) {
                override = gamedataAIRingType.Medium;
            };
        };
    };

    if NotEquals(override, currentRing) {
        bb.SetVariant(GetAllBlackboardDefs().AICover.currentRing, ToVariant(override));
    };

    return result;
}
