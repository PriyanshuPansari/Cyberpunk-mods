module SkillDrivenProgression

public class SDPOpticsTrace extends IScriptable {
  public let npc: wref<NPCPuppet>;
  public let started: Float;
  public let expires: Float;
  public let nextSample: Float;
  public let lines: array<String>;
  public let dropped: Int32;
  public let lastAudit: String;
  public let referenceIndex: Int32;

  // One reference per drain, with an explicit label: these records are not applied.
  public final func AuditReference(player: ref<PlayerPuppet>) -> Void {
    let id: TweakDBID;
    switch this.referenceIndex {
      case 0: id = t"SkillDrivenProgression.PrototypeBlind"; break;
      case 1: id = t"BaseStatusEffect.ShortBlind"; break;
      case 2: id = t"BaseStatusEffect.QuickHackBlind"; break;
      case 3: id = t"BaseStatusEffect.WeaponMalfunction"; break;
      default: return;
    };
    this.referenceIndex += 1;
    this.Add(player, "REFERENCE_RECORD_BEGIN id=" + TDBID.ToStringDEBUG(id));
    this.AuditRecord(player, TweakDBInterface.GetStatusEffectRecord(id));
    this.Add(player, "REFERENCE_RECORD_END");
  }

  public final static func Modifier(record: ref<StatModifier_Record>) -> String {
    if !IsDefined(record) { return "missing"; };
    let text: String = TDBID.ToStringDEBUG(record.GetID()) + " stat=" + TDBID.ToStringDEBUG(record.StatType().GetID()) + " operation=" + NameToString(record.ModifierType());
    let constant: ref<ConstantStatModifier_Record> = record as ConstantStatModifier_Record;
    let combined: ref<CombinedStatModifier_Record> = record as CombinedStatModifier_Record;
    if IsDefined(constant) { text += " value=" + FloatToString(constant.Value()); };
    if IsDefined(combined) { text += " value=" + FloatToString(combined.Value()) + " reference=" + TDBID.ToStringDEBUG(combined.RefStat().GetID()) + " operator=" + NameToString(combined.OpSymbol()); };
    return text;
  }

  // Bound recursion because modded stat groups can contain cycles.
  public final func AuditGroup(player: ref<PlayerPuppet>, parent: String, group: ref<StatModifierGroup_Record>, depth: Int32) -> Void {
    if !IsDefined(group) { return; };
    this.Add(player, "STAT_GROUP parent=" + parent + " id=" + TDBID.ToStringDEBUG(group.GetID()));
    if depth >= 4 { this.Add(player, "STAT_GROUP_LIMIT depth=4"); return; };
    let i: Int32 = 0;
    while i < group.GetStatModifiersCount() {
      this.Add(player, "GROUP_STAT group=" + TDBID.ToStringDEBUG(group.GetID()) + " modifier=" + SDPOpticsTrace.Modifier(group.GetStatModifiersItem(i)));
      i += 1;
    };
    i = 0;
    while i < group.GetRelatedModifierGroupsCount() {
      this.AuditGroup(player, TDBID.ToStringDEBUG(group.GetID()), group.GetRelatedModifierGroupsItem(i), depth + 1);
      i += 1;
    };
  }

  public final func AuditRecord(player: ref<PlayerPuppet>, record: ref<StatusEffect_Record>) -> Void {
    if !IsDefined(record) { return; };
    let id: String = TDBID.ToStringDEBUG(record.GetID());
    let tags: array<CName> = record.GameplayTags();
    let i: Int32 = 0;
    let tagText: String = "";
    while i < ArraySize(tags) { tagText += NameToString(tags[i]) + ","; i += 1; };
    this.Add(player, "STATUS_RECORD id=" + id + " type=" + TDBID.ToStringDEBUG(record.StatusEffectType().GetID()) + " tags=" + tagText);
    this.AuditGroup(player, id + ".duration", record.Duration(), 0);
    let ai: ref<StatusEffectAIData_Record> = record.AIData();
    if IsDefined(ai) {
      this.Add(player, "STATUS_AI status=" + id + " ai=" + TDBID.ToStringDEBUG(ai.GetID())
        + " behavior=" + NameToString(ai.BehaviourName()) + " priority=" + FloatToString(ai.Priority())
        + " updateSenses=" + (ai.UpdateSenses() ? "yes" : "no"));
      if IsDefined(ai.SensePreset()) { this.Add(player, "AI_SENSE_PRESET status=" + id + " preset=" + TDBID.ToStringDEBUG(ai.SensePreset().GetID())); };
      i = 0;
      while i < ai.GetBehaviorSignalResendDelayCount() {
        this.Add(player, "AI_RESEND_DELAY status=" + id + " modifier=" + SDPOpticsTrace.Modifier(ai.GetBehaviorSignalResendDelayItem(i)));
        i += 1;
      };
    };
    let j: Int32 = 0;
    while j < record.GetPackagesCount() {
      let package: ref<GameplayLogicPackage_Record> = record.GetPackagesItem(j);
      let k: Int32 = 0;
      while k < package.GetStatsCount() {
        this.Add(player, "PACKAGE_STAT status=" + id + " package=" + TDBID.ToStringDEBUG(package.GetID()) + " modifier=" + SDPOpticsTrace.Modifier(package.GetStatsItem(k)));
        k += 1;
      };
      k = 0;
      while k < package.GetEffectorsCount() {
        let effector: ref<Effector_Record> = package.GetEffectorsItem(k);
        this.Add(player, "PACKAGE_EFFECTOR status=" + id + " id=" + TDBID.ToStringDEBUG(effector.GetID()) + " class=" + NameToString(effector.EffectorClassName()));
        let apply: ref<ApplyStatusEffectEffector_Record> = effector as ApplyStatusEffectEffector_Record;
        if IsDefined(apply) && IsDefined(apply.StatusEffect()) { this.Add(player, "EFFECTOR_APPLIES parent=" + TDBID.ToStringDEBUG(effector.GetID()) + " child=" + TDBID.ToStringDEBUG(apply.StatusEffect().GetID())); };
        let statGroup: ref<ApplyStatGroupEffector_Record> = effector as ApplyStatGroupEffector_Record;
        if IsDefined(statGroup) {
          this.Add(player, "EFFECTOR_STAT_TARGET id=" + TDBID.ToStringDEBUG(effector.GetID()) + " target=" + NameToString(statGroup.ApplicationTarget()) + " removeWithEffector=" + (statGroup.RemoveWithEffector() ? "yes" : "no"));
          this.AuditGroup(player, TDBID.ToStringDEBUG(effector.GetID()), statGroup.StatGroup(), 0);
        };
        k += 1;
      };
      j += 1;
    };
  }

  public final func Audit(player: ref<PlayerPuppet>) -> Void {
    let statuses: array<ref<StatusEffect>>;
    GameInstance.GetStatusEffectSystem(player.GetGame()).GetAppliedEffects(this.npc.GetEntityID(), statuses);
    let accuracy: Float = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.npc.GetEntityID()), gamedataStatType.Accuracy);
    let senses: ref<SenseComponent> = this.npc.GetSensesComponent();
    let presetID: TweakDBID;
    if IsDefined(senses) { presetID = senses.SDP_RecordedPreset(); };
    let signature: String = FloatToString(accuracy) + "/" + TDBID.ToStringDEBUG(presetID);
    let i: Int32 = 0;
    while i < ArraySize(statuses) {
      signature += "/" + TDBID.ToStringDEBUG(statuses[i].GetRecord().GetID()) + ":" + IntToString(Cast<Int32>(statuses[i].GetStackCount())) + ":" + FloatToString(EngineTime.ToFloat(statuses[i].GetInitialApplicationSimTimestamp()));
      i += 1;
    };
    if Equals(signature, this.lastAudit) { return; };
    this.lastAudit = signature;
    this.Add(player, "AUDIT accuracy=" + FloatToString(accuracy) + " activeStatuses=" + IntToString(ArraySize(statuses)));
    if IsDefined(senses) { senses.SDP_TracePresetState("SENSE_STATE", presetID); };
    let preset: ref<SensePreset_Record> = TweakDBInterface.GetSensePresetRecord(presetID);
    if IsDefined(preset) {
      this.Add(player, "SENSE_PRESET id=" + TDBID.ToStringDEBUG(presetID) + " detectionFactor=" + FloatToString(preset.DetectionFactor()) + " dropFactor=" + FloatToString(preset.DetectionDropFactor()) + " cooldown=" + FloatToString(preset.DetectionCoolDownTime()));
      let n: Int32 = 0;
      while n < preset.GetShapesCount() {
        this.Add(player, "SENSE_SHAPE id=" + TDBID.ToStringDEBUG(preset.GetShapesItem(n).GetID()) + " name=" + NameToString(preset.GetShapesItem(n).Name()) + " detectionMultiplier=" + FloatToString(preset.GetShapesItem(n).DetectionMultiplier()));
        n += 1;
      };
      n = 0;
      while n < preset.GetCurvesCount() {
        this.Add(player, "SENSE_CURVE id=" + TDBID.ToStringDEBUG(preset.GetCurvesItem(n).GetID()) + " name=" + NameToString(preset.GetCurvesItem(n).Name()) + " maxDistance=" + FloatToString(preset.GetCurvesItem(n).MaxDistance()));
        n += 1;
      };
    };
    let details: array<gameStatDetailedData> = GameInstance.GetStatsSystem(player.GetGame()).GetStatDetails(Cast<StatsObjectID>(this.npc.GetEntityID()));
    i = 0;
    while i < ArraySize(details) {
      if Equals(details[i].statType, gamedataStatType.Accuracy) {
        let m: Int32 = 0;
        while m < ArraySize(details[i].modifiers) {
          this.Add(player, "ACCURACY_MOD operation=" + EnumValueToString("gameStatModifierType", Cast<Int64>(EnumInt(details[i].modifiers[m].modifierType))) + " value=" + FloatToString(details[i].modifiers[m].value));
          m += 1;
        };
      };
      i += 1;
    };
    i = 0;
    while i < ArraySize(statuses) {
      let status: ref<StatusEffect> = statuses[i];
      let record: ref<StatusEffect_Record> = status.GetRecord();
      this.Add(player, "ACTIVE_STATUS id=" + TDBID.ToStringDEBUG(record.GetID()) + " remaining=" + FloatToString(status.GetRemainingDuration()) + " stacks=" + IntToString(Cast<Int32>(status.GetStackCount())) + " instigator=" + EntityID.ToDebugStringDecimal(status.GetInstigatorEntityID()));
      this.AuditRecord(player, record);
      i += 1;
    };
  }

  public final func Active(player: ref<PlayerPuppet>) -> Bool {
    return IsDefined(this.npc) && SDPPrototypeRuntime.Now(player) < this.expires;
  }

  public final func Add(player: ref<PlayerPuppet>, event: String) -> Void {
    if ArraySize(this.lines) >= 512 { this.dropped += 1; return; };
    ArrayPush(this.lines, FloatToString(SDPPrototypeRuntime.Now(player) - this.started) + " " + event);
  }

  public final func Snapshot(player: ref<PlayerPuppet>) -> String {
    let visible: String = "unknown";
    let los: Float = -1.00;
    let belief: Float = -1.00;
    if IsDefined(this.npc.GetSensesComponent()) { visible = this.npc.GetSensesComponent().IsAgentVisible(player) ? "yes" : "no"; };
    if IsDefined(this.npc.GetSourceShootComponent()) {
      if !this.npc.GetSourceShootComponent().GetContinuousLineOfSightToTarget(player, los) { los = -1.00; };
    };
    if IsDefined(this.npc.GetTargetTrackerComponent()) { belief = this.npc.GetTargetTrackerComponent().GetVisibleThreatBeliefAccuracy(player); };
    let accuracy: Float = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.npc.GetEntityID()), gamedataStatType.Accuracy);
    return "jamWeaponTag=" + (StatusEffectSystem.ObjectHasStatusEffectWithTag(this.npc, n"JamWeapon") ? "yes" : "no")
      + " weaponJamTag=" + (StatusEffectSystem.ObjectHasStatusEffectWithTag(this.npc, n"WeaponJam") ? "yes" : "no")
      + " blind=" + (ScriptedPuppet.IsBlinded(this.npc) ? "yes" : "no")
      + " visible=" + visible + " continuousLOS=" + FloatToString(los)
      + " visibleBelief=" + FloatToString(belief) + " accuracyStat=" + FloatToString(accuracy)
      + " distance=" + FloatToString(Vector4.Distance(this.npc.GetWorldPosition(), player.GetWorldPosition()))
      + SDPCombatBlindTrace.Describe(this.npc);
  }
}

@addField(PlayerPuppet)
private let m_sdpOpticsTrace: ref<SDPOpticsTrace>;

@addMethod(PlayerPuppet)
public final func SDP_OpticsTraceStart() -> String {
  if IsDefined(this.m_sdpOpticsTrace) { return "Recording or undrained trace already exists. Wait for completion."; };
  let npc: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  if !IsDefined(npc) { return "Select an NPC in the scanner before starting the recording."; };
  this.m_sdpOpticsTrace = new SDPOpticsTrace();
  this.m_sdpOpticsTrace.npc = npc;
  this.m_sdpOpticsTrace.started = SDPPrototypeRuntime.Now(this);
  this.m_sdpOpticsTrace.expires = this.m_sdpOpticsTrace.started + 30.00;
  this.m_sdpOpticsTrace.Add(this, "START traceVersion=4 npc=" + EntityID.ToDebugStringDecimal(npc.GetEntityID()) + " record=" + TDBID.ToStringDEBUG(npc.GetRecordID()));
  return "Recording started: trace v4, 30 simulation seconds with status and Accuracy modifier sources. Fight normally, upload Optics after a few seconds, then keep moving.";
}

@addMethod(PlayerPuppet)
public final func SDP_OpticsTraceDrain() -> String {
  if !IsDefined(this.m_sdpOpticsTrace) { return "ABORT no active trace (session changed)\n"; };
  let trace: ref<SDPOpticsTrace> = this.m_sdpOpticsTrace;
  let active: Bool = trace.Active(this);
  if active { trace.AuditReference(this); };
  if active && SDPPrototypeRuntime.Now(this) >= trace.nextSample {
    trace.Add(this, "SAMPLE " + trace.Snapshot(this));
    trace.Audit(this);
    trace.nextSample = SDPPrototypeRuntime.Now(this) + 0.25;
  };
  if !active { trace.Add(this, "END dropped=" + IntToString(trace.dropped)); };
  let text: String = "";
  let i: Int32 = 0;
  while i < ArraySize(trace.lines) { text += trace.lines[i] + "\n"; i += 1; };
  ArrayClear(trace.lines);
  if !active { this.m_sdpOpticsTrace = null; };
  return text;
}

@addMethod(PlayerPuppet)
public final func SDP_OpticsTraceStatus(npc: ref<NPCPuppet>, record: ref<StatusEffect_Record>, event: String) -> Void {
  let trace: ref<SDPOpticsTrace> = this.m_sdpOpticsTrace;
  if !IsDefined(trace) || !trace.Active(this) || npc != trace.npc || !IsDefined(record) { return; };
  trace.Add(this, event + " id=" + TDBID.ToStringDEBUG(record.GetID()) + " " + trace.Snapshot(this));
  trace.lastAudit = "";
}

@addMethod(PlayerPuppet)
public final func SDP_OpticsTraceSenses(npc: ref<NPCPuppet>, text: String) -> Void {
  let trace: ref<SDPOpticsTrace> = this.m_sdpOpticsTrace;
  if !IsDefined(trace) || !trace.Active(this) || npc != trace.npc { return; };
  trace.Add(this, text);
}

@addMethod(SenseComponent)
public final func SDP_TracePresetState(event: String, requested: TweakDBID) -> Void {
  let npc: ref<NPCPuppet> = this.GetOwnerPuppet() as NPCPuppet;
  if !IsDefined(npc) { return; };
  let player: ref<PlayerPuppet> = GetPlayer(npc.GetGame());
  if !IsDefined(player) || !player.SDP_IsOpticsTraceTarget(npc) { return; };
  let shapes: array<ref<ISenseShape>> = this.GetSenseShapes();
  player.SDP_OpticsTraceSenses(npc, event + " requested=" + TDBID.ToStringDEBUG(requested)
    + " getter=" + TDBID.ToStringDEBUG(this.GetCurrentPreset())
    + " main=" + TDBID.ToStringDEBUG(this.m_mainPreset)
    + " secondary=" + TDBID.ToStringDEBUG(this.m_secondaryPreset)
    + " shapes=" + IntToString(ArraySize(shapes))
    + " visible=" + (this.IsAgentVisible(player) ? "yes" : "no"));
}

@addMethod(PlayerPuppet)
public final func SDP_IsOpticsTraceTarget(npc: ref<NPCPuppet>) -> Bool {
  return IsDefined(this.m_sdpOpticsTrace) && this.m_sdpOpticsTrace.Active(this) && this.m_sdpOpticsTrace.npc == npc;
}

@wrapMethod(SenseComponent)
protected cb func OnSensePresetChangeEvent(evt: ref<SensePresetChangeEvent>) -> Bool {
  let action: String = evt.reset ? "RESET" : (evt.mainPreset ? "MAIN" : "SECONDARY");
  this.SDP_TracePresetState("PRESET_EVENT_BEFORE_" + action, evt.presetID);
  let result: Bool = wrappedMethod(evt);
  this.SDP_TracePresetState("PRESET_EVENT_AFTER_" + action, evt.presetID);
  return result;
}

@wrapMethod(SenseComponent)
protected cb func OnHACK_UseSensePresetEvent(evt: ref<HACK_UseSensePresetEvent>) -> Bool {
  this.SDP_TracePresetState("HACK_PRESET_BEFORE", evt.sensePreset);
  let result: Bool = wrappedMethod(evt);
  this.SDP_TracePresetState("HACK_PRESET_AFTER", evt.sensePreset);
  return result;
}

@wrapMethod(SenseComponent)
protected cb func OnSenseInitialize(evt: ref<SenseInitializeEvent>) -> Bool {
  this.SDP_TracePresetState("SENSE_INITIALIZE_BEFORE", t"");
  let result: Bool = wrappedMethod(evt);
  this.SDP_TracePresetState("SENSE_INITIALIZE_AFTER", t"");
  return result;
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if IsDefined(player) && IsDefined(evt) { player.SDP_OpticsTraceStatus(this, evt.staticData, "STATUS_APPLIED"); };
  return result;
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectRemoved(evt: ref<RemoveStatusEffect>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if IsDefined(player) && IsDefined(evt) { player.SDP_OpticsTraceStatus(this, evt.staticData, "STATUS_REMOVED"); };
  return result;
}

@addMethod(PlayerPuppet)
public final func SDP_OpticsTraceShot(owner: ref<GameObject>, target: ref<GameObject>, tracking: Bool, delay: Float) -> Void {
  let trace: ref<SDPOpticsTrace> = this.m_sdpOpticsTrace;
  if !IsDefined(trace) || !trace.Active(this) || owner != trace.npc { return; };
  trace.Add(this, "FIRE_CALL targetPlayer=" + (target == this ? "yes" : "no") + " trackingOverride=" + (tracking ? "yes" : "no") + " aimingDelay=" + FloatToString(delay) + " " + trace.Snapshot(this));
}

@addMethod(PlayerPuppet)
public final func SDP_OpticsTraceDamage(evt: ref<gameDamageReceivedEvent>) -> Void {
  let trace: ref<SDPOpticsTrace> = this.m_sdpOpticsTrace;
  if !IsDefined(trace) || !trace.Active(this) || !IsDefined(evt) || !IsDefined(evt.hitEvent) || !IsDefined(evt.hitEvent.attackData) { return; };
  if evt.hitEvent.attackData.GetInstigator() != trace.npc || evt.totalDamageReceived <= 0.00 { return; };
  trace.Add(this, "DAMAGE_RECEIVED amount=" + FloatToString(evt.totalDamageReceived) + " type=" + EnumValueToString("gamedataAttackType", Cast<Int64>(EnumInt(evt.hitEvent.attackData.GetAttackType()))) + " " + trace.Snapshot(this));
}

@wrapMethod(AIWeapon)
public final static func Fire(weaponOwner: wref<GameObject>, weapon: wref<WeaponObject>, const timeStamp: Float, tbhCoefficient: Float, requestedTriggerMode: gamedataTriggerMode, opt targetPosition: Vector4, opt target: ref<GameObject>, opt rangedAttack: TweakDBID, opt maxSpreadOverride: Float, opt aimingDelay: Float, opt offset: Vector4, opt shouldTrackTarget: Bool, opt predictionTime: Float, opt posProviderOverride: ref<IPositionProvider>, opt muzzleOffset: Vector4, opt weaponCustomEvent: CName) -> Void {
  if IsDefined(weaponOwner) {
    let player: ref<PlayerPuppet> = GetPlayer(weaponOwner.GetGame());
    if IsDefined(player) { player.SDP_OpticsTraceShot(weaponOwner, target, shouldTrackTarget, aimingDelay); };
  };
  wrappedMethod(weaponOwner, weapon, timeStamp, tbhCoefficient, requestedTriggerMode, targetPosition, target, rangedAttack, maxSpreadOverride, aimingDelay, offset, shouldTrackTarget, predictionTime, posProviderOverride, muzzleOffset, weaponCustomEvent);
}

@wrapMethod(GameObject)
protected final func ProcessDamageReceived(evt: ref<gameDamageReceivedEvent>) -> Void {
  let player: ref<PlayerPuppet> = this as PlayerPuppet;
  if IsDefined(player) { player.SDP_OpticsTraceDamage(evt); };
  wrappedMethod(evt);
}

@addMethod(SenseComponent)
public final func SDP_RecordedPreset() -> TweakDBID {
  if TDBID.IsValid(this.m_secondaryPreset) { return this.m_secondaryPreset; };
  if TDBID.IsValid(this.m_mainPreset) { return this.m_mainPreset; };
  return this.GetCurrentPreset();
}

// This is the native Fire function's bookkeeping after its shoot call, not a
// projectile collision confirmation. It excludes Fire's early-return paths.
@wrapMethod(AIWeapon)
private final static func OnShotFired(weapon: wref<WeaponObject>, requestedTriggerMode: gamedataTriggerMode, const timeStamp: Float) -> Void {
  wrappedMethod(weapon, requestedTriggerMode, timeStamp);
  if !IsDefined(weapon) { return; };
  let npc: ref<NPCPuppet> = weapon.GetOwner() as NPCPuppet;
  if !IsDefined(npc) { return; };
  let player: ref<PlayerPuppet> = GetPlayer(npc.GetGame());
  if IsDefined(player) && player.SDP_IsOpticsTraceTarget(npc) {
    player.SDP_OpticsTraceSenses(npc, "SHOT_BOOKKEEPING weapon=" + TDBID.ToStringDEBUG(ItemID.GetTDBID(weapon.GetItemID())));
  };
}

@wrapMethod(NPCPuppet)
protected final func SendStatusEffectSignal(priority: Float, const tags: script_ref<[CName]>, const flags: script_ref<[EAIGateSignalFlags]>, statusEffectID: TweakDBID, repeatSignalDelay: Float, remainingStatusEffectDuration: Float) -> Void {
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if IsDefined(player) && player.SDP_IsOpticsTraceTarget(this) {
    // Signal submission is not confirmation that the AI chose the behavior.
    player.SDP_OpticsTraceSenses(this, "AI_SIGNAL_REQUEST status=" + TDBID.ToStringDEBUG(statusEffectID)
      + " priority=" + FloatToString(priority) + " repeatDelay=" + FloatToString(repeatSignalDelay)
      + " remaining=" + FloatToString(remainingStatusEffectDuration));
  };
  wrappedMethod(priority, tags, flags, statusEffectID, repeatSignalDelay, remainingStatusEffectDuration);
}
