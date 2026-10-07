module SDPCE
// SDPCombat cut-down of Combat Evolved 4.16.8: hit and death hooks.
// Kept: late enrolment on first hit, fear wounds and flee rolls, cover ejection and flank pings, morale breaks on death.
// Removed: CE's armour mitigation and ProcessArmor block (SDPCombat owns armour), elemental and hacking resistances,
// quickhack damage scaling, backstab multiplier, boss armour repair, combat healing, quickhack RAM/upload costs.

@wrapMethod(ScriptedPuppet)
protected cb func OnDamageReceived(evt: ref<gameDamageReceivedEvent>) -> Bool {
    let npc = this as NPCPuppet;
    if IsDefined(npc) && IsDefined(evt.hitEvent) && IsDefined(evt.hitEvent.attackData) {
        let attackData = evt.hitEvent.attackData;
        let instigator = attackData.GetInstigator();
        let isPlayer = IsDefined(instigator) && instigator.IsPlayer();

        let cfgDbg: ref<GBPConfig> = GBPConfig.Get(this.GetGame());
        if IsDefined(cfgDbg) && cfgDbg.debugON && isPlayer {
            let totalRcv = evt.hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
            let postHasDef = GBPHasStatusEffect(npc, t"BaseStatusEffect.Defeated");
            let postHasInvuln = GBPHasStatusEffect(npc, t"BaseStatusEffect.Invulnerable");
            let postHasInvulnAD = GBPHasStatusEffect(npc, t"BaseStatusEffect.InvulnerableAfterDefeated");
            let postHasDefRec = GBPHasStatusEffect(npc, t"BaseStatusEffect.DefeatedWithRecover");
            GBPLog(s"[GBP] OnDamageReceived \(GBPNpcTag(npc)) totalApplied=\(RoundF(totalRcv)) Def=\(postHasDef) Invuln=\(postHasInvuln) InvulnAD=\(postHasInvulnAD) DefRec=\(postHasDefRec) factionCached=\(GBPStateOf(npc).GBP_factionCached) incap=\(GBPStateOf(npc).GBP_incapacitated)");
        }

        let isHostileToPlayer: Bool = true;
        if isPlayer {
            let pPuppet = instigator as ScriptedPuppet;
            let myAg: ref<AttitudeAgent> = npc.GetAttitudeAgent();
            let plAg: ref<AttitudeAgent>;
            if IsDefined(pPuppet) { plAg = pPuppet.GetAttitudeAgent(); };
            if IsDefined(myAg) && IsDefined(plAg) {
                isHostileToPlayer = Equals(myAg.GetAttitudeTowards(plAg), EAIAttitude.AIA_Hostile);
            };
        };

        if isPlayer {
            
            if !GBPStateOf(npc).GBP_factionCached && !GBPStateOf(npc).GBP_initAttempted
              && !GBPIsDownedNPC(npc) && !npc.IsAboutToDieOrDefeated() {
                let gi = npc.GetGame();
                let gbpSystem = GBPSystem.Get(gi);
                if IsDefined(gbpSystem) {
                    GBPEnsureState(npc).GBP_initAttempted = true;

                    let lateFactionIndex: Int32 = gbpSystem.ResolveFaction(npc);
                    if lateFactionIndex >= 0 {
                        GBPLogHP(npc, "LATE-INIT pre-Reset");
                        GBPSystem.ResetGBPFields(npc);
                        GBPLogHP(npc, "LATE-INIT post-Reset");
                        GBPEnsureState(npc).GBP_factionCached = true;
                        GBPEnsureState(npc).GBP_factionIndex = lateFactionIndex;
                        GBPEnsureState(npc).GBP_rarityVal = GBPSystem.ResolveRarityVal(npc);

                        let fears = GBPSystem.RollFearsFromProfile(lateFactionIndex, GBPStateOf(npc).GBP_rarityVal);
                        GBPEnsureState(npc).GBP_fear1 = fears / 10;
                        GBPEnsureState(npc).GBP_fear2 = fears % 10;

                        if GBPStateOf(npc).GBP_fear1 == 8 {
                            let unbreakProfile = GBPProfiles.GetProfile(lateFactionIndex);
                            if IsDefined(unbreakProfile) && unbreakProfile.GetMoraleBreakChance(GBPStateOf(npc).GBP_rarityVal) <= 0.0 {
                                GBPEnsureState(npc).GBP_unbreakable = true;
                            };
                        };
                        if GBPNeverFears(npc) { GBPEnsureState(npc).GBP_unbreakable = true; };

                        GBPLogHP(npc, "LATE-INIT pre-ApplyProfile");
                        gbpSystem.ApplyFactionCombatProfile(npc, lateFactionIndex);
                        GBPLogHP(npc, "LATE-INIT post-ApplyProfile");
                        GBPCapability.Apply(npc, lateFactionIndex);
                        gbpSystem.TrackPuppet(npc);
                    };
                };
            }
        }

        if isPlayer && isHostileToPlayer && GBPStateOf(npc).GBP_moraleWound < 1.0
          && IsDefined(cfgDbg) && cfgDbg.enableFear {

            if GBPStateOf(npc).GBP_factionIndex >= 0 {
                
                if GBPStateOf(npc).GBP_fear1 == 0 {
                    let lf = GBPSystem.RollFearsFromProfile(GBPStateOf(npc).GBP_factionIndex, GBPStateOf(npc).GBP_rarityVal);
                    GBPEnsureState(npc).GBP_fear1 = lf / 10;
                    GBPEnsureState(npc).GBP_fear2 = lf % 10;
                }

                if !GBPStateOf(npc).GBP_unbreakable {
                    let woundProfile = GBPProfiles.GetProfile(GBPStateOf(npc).GBP_factionIndex);
                    if IsDefined(woundProfile) {
                        let woundCfg = GBPConfig.Get(npc.GetGame());
                        woundProfile.Setup(woundCfg);
                    }
                    let wound: Float = GBPSystem.ComputeProfileFearWound(woundProfile, attackData, GBPStateOf(npc).GBP_rarityVal, GBPStateOf(npc).GBP_fear1, GBPStateOf(npc).GBP_fear2);

                    let traits = GBPStateOf(npc).GBP_traits;
                    if GBPSystem.HasTrait(traits, GBPSystem.TraitCyberJunkie()) { wound = wound * 0.5; }
                    if GBPSystem.HasTrait(traits, GBPSystem.TraitCoward()) { wound = wound * 1.5; }
                    if GBPSystem.HasTrait(traits, GBPSystem.TraitShowOff()) { wound = wound * 1.15; }
                    if GBPSystem.HasTrait(traits, GBPSystem.TraitRusher()) { wound = wound * 0.75; }
                    
                    if GBPSystem.HasTrait(traits, GBPSystem.TraitOpportunist()) {
                        let playerObj: ref<PlayerPuppet> = GetPlayer(npc.GetGame());
                        if IsDefined(playerObj) {
                            
                            let oppHP: Float = GameInstance.GetStatPoolsSystem(npc.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(playerObj.GetEntityID()), gamedataStatPoolType.Health, true);
                            if oppHP > 80.0 { wound = wound * 1.3; }
                            else if oppHP < 40.0 { wound = wound * 0.5; }
                        }
                    }

                    GBPEnsureState(npc).GBP_moraleWound = MinF(GBPStateOf(npc).GBP_moraleWound + wound, 1.0);

                    let fleeThreshold: Float = 0.5;
                    if IsDefined(woundProfile) { fleeThreshold = woundProfile.GetFleeWoundThreshold(); }
                    if GBPSystem.HasTrait(traits, GBPSystem.TraitCoward()) { fleeThreshold = fleeThreshold * 0.5; }
                    else if GBPSystem.HasTrait(traits, GBPSystem.TraitFormationFighter()) || GBPSystem.HasTrait(traits, GBPSystem.TraitSteady()) { fleeThreshold = fleeThreshold * 1.5; }

                    if GBPStateOf(npc).GBP_moraleWound >= fleeThreshold && !GBPStateOf(npc).GBP_shouldFlee {
                        let gi = npc.GetGame();
                        let profile = GBPProfiles.GetProfile(GBPStateOf(npc).GBP_factionIndex);
                        if IsDefined(profile) {
                            let config = GBPConfig.Get(gi);
                            profile.Setup(config);
                            let baseMorale = profile.GetMoraleBreakChance(GBPStateOf(npc).GBP_rarityVal);
                            let diff: Int32 = 100;
                            if IsDefined(config) { diff = config.npcDifficulty; };
                            let fearMult = GBPSystem.GetDifficultyFearMult(diff);
                            let districtMod: Float = GBPStateOf(npc).GBP_districtFearMod;
                            if districtMod < 0.01 { districtMod = 1.0; }
                            let credMult: Float = GBPSystem.GetStreetCredFearMult(gi, GBPStateOf(npc).GBP_rarityVal, config);
                            let totalBreak = (baseMorale * fearMult * districtMod * credMult) + GBPStateOf(npc).GBP_moraleWound;

                            let statPoolsSystem = GameInstance.GetStatPoolsSystem(gi);
                            
                            let hpPct = statPoolsSystem.GetStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, true);
                            if hpPct > 100.0 { hpPct = 100.0; }
                            totalBreak = totalBreak + (1.0 - (hpPct / 100.0)) * 0.5;

                            if totalBreak >= 1.0 {
                                
                                let delaySystem = GameInstance.GetDelaySystem(gi);
                                let delay = 0.2 + RandF() * 0.5;
                                delaySystem.DelayCallback(GBPFearCallback.Create(npc), delay, false);
                            }
                        }
                    }
                }
            }
        }

        if isPlayer && isHostileToPlayer {
            GBPCoverEject.OnHit(npc);
            GBPFlank.OnHit(npc);
            
            let sysPing = GBPSystem.Get(npc.GetGame());
            if IsDefined(sysPing) { sysPing.PingSquadFlank(npc); }
        }
    }
    return wrappedMethod(evt);
}

@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    let result = wrappedMethod(evt);

    let player = evt.instigator as PlayerPuppet;
    if !IsDefined(player) { return result; }

    if !GBPStateOf(this).GBP_factionCached || GBPStateOf(this).GBP_factionIndex < 0 { return result; }

    let gi = this.GetGame();
    let config = GBPConfig.Get(gi);
    if IsDefined(config) && config.modON && config.enableFear {
        let deadPos = this.GetWorldPosition();
        let deadRarity = GBPStateOf(this).GBP_rarityVal;
        let delaySystem = GameInstance.GetDelaySystem(gi);
        
        delaySystem.DelayCallback(GBPMoraleBreakCallback.Create(deadPos, GBPStateOf(this).GBP_factionIndex, deadRarity), 0.3, false);
    }

    return result;
}

