module SDPCE
// SDPCombat cut-down of Combat Evolved 4.16.8: limb crippling on V's hits.
// An arm hit taking >=30% of current health cripples it (drops a ranged weapon; both arms: incapacitated);
// a leg hit taking >=40% halves speed (both legs: incapacitated).
// GBP_HitZones - localized hit effects (⌐■_■)


@wrapMethod(DamageSystem)
private func ProcessLocalizedDamage(hitEvent: ref<gameHitEvent>) -> Void {
    wrappedMethod(hitEvent);
    
    if hitEvent.projectionPipeline { return; }

    let npc = hitEvent.target as NPCPuppet;
    if !IsDefined(npc) || !GBPStateOf(npc).GBP_factionCached || GBPStateOf(npc).GBP_incapacitated { return; };

    let instigator = hitEvent.attackData.GetInstigator();
    if !IsDefined(instigator) || !instigator.IsPlayer() { return; };

    let hitShapes = hitEvent.hitRepresentationResult.hitShapes;
    if ArraySize(hitShapes) == 0 { return; };

    let hitUserData = DamageSystemHelper.GetHitShapeUserDataBase(hitShapes[0]);
    if !IsDefined(hitUserData) { return; };

    let gi = npc.GetGame();
    let config = GBPConfig.Get(gi);
    if !IsDefined(config) || !config.modON { return; };

    // heads: SDPCombat armour decides (helmet pieces, fatal penetration); CE's helmet damage cut removed
    if HitShapeUserDataBase.IsHitReactionZoneHead(hitUserData) { return; };

    if !config.enableLimbCripple { return; };

    if GBPStateOf(npc).GBP_isBoss { return; };
    if npc.IsQuest() { return; };

    let totalDmg = hitEvent.attackComputed.GetTotalAttackValue(gamedataStatPoolType.Health);
    if totalDmg <= 0.0 { return; };

    let statPools = GameInstance.GetStatPoolsSystem(gi);
    let hpNow = statPools.GetStatPoolValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health, false);
    if hpNow <= 0.0 { return; };
    
    let hpMaxCl = statPools.GetStatPoolMaxPointValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatPoolType.Health);
    let dmgPct = totalDmg / MaxF(hpNow, hpMaxCl * 0.25);

    if config.debugON {
        let zone: String = "Body";
        if HitShapeUserDataBase.IsHitReactionZoneLeftArm(hitUserData) { zone = "LArm"; }
        else if HitShapeUserDataBase.IsHitReactionZoneRightArm(hitUserData) { zone = "RArm"; }
        else if HitShapeUserDataBase.IsHitReactionZoneLeftLeg(hitUserData) { zone = "LLeg"; }
        else if HitShapeUserDataBase.IsHitReactionZoneRightLeg(hitUserData) { zone = "RLeg"; }
        GBPLog(s"[GBP] LocalizedDmg \(GBPNpcTag(npc)) zone=\(zone) totalDmg=\(RoundF(totalDmg)) hpNow=\(RoundF(hpNow)) dmgPct=\(FloatToStringPrec(dmgPct, 2)) armCripT=\(FloatToStringPrec(config.armCrippleThreshold, 2)) legCripT=\(FloatToStringPrec(config.legCrippleThreshold, 2)) limbs=L\(GBPStateOf(npc).GBP_leftArmCrippled)R\(GBPStateOf(npc).GBP_rightArmCrippled)/L\(GBPStateOf(npc).GBP_leftLegCrippled)R\(GBPStateOf(npc).GBP_rightLegCrippled)");
    }

    if HitShapeUserDataBase.IsHitReactionZoneLeftArm(hitUserData) {
        if !GBPStateOf(npc).GBP_leftArmCrippled && dmgPct >= config.armCrippleThreshold {
            GBPEnsureState(npc).GBP_leftArmCrippled = true;
            GBPHitZones.OnArmCrippled(npc, gi, config);
        };
        return;
    };
    if HitShapeUserDataBase.IsHitReactionZoneRightArm(hitUserData) {
        if !GBPStateOf(npc).GBP_rightArmCrippled && dmgPct >= config.armCrippleThreshold {
            GBPEnsureState(npc).GBP_rightArmCrippled = true;
            GBPHitZones.OnArmCrippled(npc, gi, config);
        };
        return;
    };

    if HitShapeUserDataBase.IsHitReactionZoneLeftLeg(hitUserData) {
        if !GBPStateOf(npc).GBP_leftLegCrippled && dmgPct >= config.legCrippleThreshold {
            GBPEnsureState(npc).GBP_leftLegCrippled = true;
            GBPHitZones.OnLegCrippled(npc, gi, config);
        };
        return;
    };
    if HitShapeUserDataBase.IsHitReactionZoneRightLeg(hitUserData) {
        if !GBPStateOf(npc).GBP_rightLegCrippled && dmgPct >= config.legCrippleThreshold {
            GBPEnsureState(npc).GBP_rightLegCrippled = true;
            GBPHitZones.OnLegCrippled(npc, gi, config);
        };
        return;
    };
}

public abstract class GBPHitZones {

    public static func IsDroppableRangedWeapon(npc: ref<NPCPuppet>, gi: GameInstance) -> Bool {
        let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
        if !IsDefined(ts) { return false; };
        let item: ref<ItemObject> = ts.GetItemInSlot(npc, t"AttachmentSlots.WeaponRight");
        if !IsDefined(item) { return false; };
        let data: ref<gameItemData> = item.GetItemData();
        if !IsDefined(data) { return false; };
        let itemType: gamedataItemType = data.GetItemType();
        switch itemType {
            case gamedataItemType.Wea_Fists: return false;
            case gamedataItemType.Wea_Knife: return false;
            case gamedataItemType.Wea_ShortBlade: return false;
            case gamedataItemType.Wea_LongBlade: return false;
            case gamedataItemType.Wea_Katana: return false;
            case gamedataItemType.Wea_Machete: return false;
            case gamedataItemType.Wea_Sword: return false;
            case gamedataItemType.Wea_Chainsword: return false;
            case gamedataItemType.Wea_OneHandedClub: return false;
            case gamedataItemType.Wea_TwoHandedClub: return false;
            case gamedataItemType.Wea_Hammer: return false;
            case gamedataItemType.Wea_Axe: return false;     
            case gamedataItemType.Wea_Melee: return false;
            case gamedataItemType.Cyb_MantisBlades: return false;
            case gamedataItemType.Cyb_NanoWires: return false;
            case gamedataItemType.Cyb_StrongArms: return false;
            case gamedataItemType.Cyb_Launcher: return false;
            case gamedataItemType.Cyb_Ability: return false;
        };
        return true;
    }

    public static func OnArmCrippled(npc: ref<NPCPuppet>, gi: GameInstance, config: ref<GBPConfig>) -> Void {
        GBPSystem.Note(gi, 8);
        let bothArms = GBPStateOf(npc).GBP_leftArmCrippled && GBPStateOf(npc).GBP_rightArmCrippled;

        if bothArms {
            GBPHitZones.Incapacitate(npc, gi);
            return;
        };

        if !GBPStateOf(npc).GBP_primaryDropped {
            GBPEnsureState(npc).GBP_primaryDropped = true;
            if GBPHitZones.IsDroppableRangedWeapon(npc, gi) {
                ScriptedPuppet.DropWeaponFromSlot(npc, t"AttachmentSlots.WeaponRight");
            };
        };

        // aim: SDPCombat reads the crippled-arm flags and widens this shooter's spread (CE lowered the Accuracy stat)

        if IsDefined(config) && config.debugON {
            GBPLog(s"[GBP] OnArmCrippled \(GBPNpcTag(npc)) limbs=L\(GBPStateOf(npc).GBP_leftArmCrippled)R\(GBPStateOf(npc).GBP_rightArmCrippled) bothArms=\(bothArms) droppedPrimary=\(GBPStateOf(npc).GBP_primaryDropped)");
        }
    }

    public static func OnLegCrippled(npc: ref<NPCPuppet>, gi: GameInstance, config: ref<GBPConfig>) -> Void {
        GBPSystem.Note(gi, 9);
        let bothLegs = GBPStateOf(npc).GBP_leftLegCrippled && GBPStateOf(npc).GBP_rightLegCrippled;

        if bothLegs {
            GBPHitZones.Incapacitate(npc, gi);
            return;
        };

        let statsSystem = GameInstance.GetStatsSystem(gi);
        let entityID = Cast<StatsObjectID>(npc.GetEntityID());
        if IsDefined(GBPStateOf(npc).GBP_modSpeedCripple) { statsSystem.RemoveModifier(entityID, GBPStateOf(npc).GBP_modSpeedCripple); GBPEnsureState(npc).GBP_modSpeedCripple = null; }
        let cripMod = RPGManager.CreateStatModifier(gamedataStatType.MaxSpeed, gameStatModifierType.Multiplier, 0.5);
        GBPEnsureState(npc).GBP_modSpeedCripple = cripMod;
        statsSystem.AddModifier(entityID, cripMod);

        if IsDefined(config) && config.debugON {
            GBPLog(s"[GBP] OnLegCrippled \(GBPNpcTag(npc)) limbs=L\(GBPStateOf(npc).GBP_leftLegCrippled)R\(GBPStateOf(npc).GBP_rightLegCrippled) bothLegs=\(bothLegs)");
        }
    }

    public static func Incapacitate(npc: ref<NPCPuppet>, gi: GameInstance) -> Void {
        if GBPStateOf(npc).GBP_incapacitated { return; };
        GBPEnsureState(npc).GBP_incapacitated = true;
        GBPSystem.Note(gi, 10);

        if GBPHitZones.IsDroppableRangedWeapon(npc, gi) {
            npc.DropHeldItems();
        };
        SenseComponent.RequestSecondaryPresetChange(npc, t"Senses.Blind");
        
        StatusEffectHelper.ApplyStatusEffect(npc, t"BaseStatusEffect.Defeated", 0.10);

        let cfg: ref<GBPConfig> = GBPConfig.Get(gi);
        if IsDefined(cfg) && cfg.debugON {
            GBPLog(s"[GBP] Incapacitated \(GBPNpcTag(npc)) limbs=L\(GBPStateOf(npc).GBP_leftArmCrippled)R\(GBPStateOf(npc).GBP_rightArmCrippled)/L\(GBPStateOf(npc).GBP_leftLegCrippled)R\(GBPStateOf(npc).GBP_rightLegCrippled)");
        }
    }
}
