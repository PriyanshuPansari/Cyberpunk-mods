module SkillDrivenProgression

// Native statuses are reusable leaf primitives. Full action costs, upload queues,
// activation/instigator effects and non-status effectors are audited, not emulated.
public class SDPQHSpreadStamp extends IScriptable {
  public let target: wref<NPCPuppet>;
  public let recordID: TweakDBID;
  public let initialTime: Float;
}

// Native on-application handlers can extend duration on the next frame. Correct
// the copied instance once after those handlers, without touching a later recast.
public class SDPQHDurationCorrection extends DelayCallback {
  public let target: wref<NPCPuppet>;
  public let recordID: TweakDBID;
  public let initialTime: Float;
  public let lastTime: Float;
  public let expires: Float;
  public func Call() -> Void {
    if !IsDefined(this.target) { return; };
    let current: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(this.target, this.recordID);
    if !IsDefined(current) || EngineTime.ToFloat(current.GetInitialApplicationSimTimestamp()) != this.initialTime
      || EngineTime.ToFloat(current.GetLastApplicationSimTimestamp()) != this.lastTime { return; };
    let remaining: Float = this.expires - EngineTime.ToFloat(GameInstance.GetSimTime(this.target.GetGame()));
    if remaining <= 0.00 {
      GameInstance.GetStatusEffectSystem(this.target.GetGame()).RemoveStatusEffect(this.target.GetEntityID(), this.recordID, current.GetStackCount());
    } else {
      GameInstance.GetStatusEffectSystem(this.target.GetGame()).SetStatusEffectRemainingDuration(this.target.GetEntityID(), this.recordID, remaining);
    };
  }
}

public class SDPQHLab extends IScriptable {
  public let used: array<ref<SDPQHSpreadStamp>>;
  public let pending: Bool;
  public let report: String;
  public let sequence: Int32;

  public final static func Family(record: ref<StatusEffect_Record>) -> Int32 {
    if !IsDefined(record) { return 0; };
    if record.GameplayTagsContains(n"QuickHackBlind") { return 1; };
    if record.GameplayTagsContains(n"Overheat") { return 2; };
    if record.GameplayTagsContains(n"LocomotionMalfunction") || record.GameplayTagsContains(n"LocomotionMalfunctionLevel3") { return 3; };
    if record.GameplayTagsContains(n"JamWeapon") { return 4; };
    if record.GameplayTagsContains(n"CyberwareMalfunction") { return 5; };
    if record.GameplayTagsContains(n"CommsNoise") || record.GameplayTagsContains(n"CommsNoiseJam") { return 6; };
    return 0;
  }

  public final static func FamilyName(family: Int32) -> String {
    if family == 1 { return "Reboot Optics"; };
    if family == 2 { return "Overheat"; };
    if family == 3 { return "Cripple Movement"; };
    if family == 4 { return "Weapon Glitch"; };
    if family == 5 { return "Cyberware Malfunction"; };
    if family == 6 { return "Sonic Shock"; };
    return "Unsupported effect";
  }

  public final func Prune(player: ref<PlayerPuppet>) -> Void {
    let i: Int32 = ArraySize(this.used) - 1;
    while i >= 0 {
      let current: ref<StatusEffect>;
      if IsDefined(this.used[i].target) { current = StatusEffectHelper.GetStatusEffectByID(this.used[i].target, this.used[i].recordID); };
      if !IsDefined(current) || EngineTime.ToFloat(current.GetInitialApplicationSimTimestamp()) != this.used[i].initialTime {
        ArrayErase(this.used, i);
      };
      current = null;
      i -= 1;
    };
  }

  public final func IsUsed(target: ref<NPCPuppet>, recordID: TweakDBID) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(this.used) {
      if IsDefined(this.used[i].target) && this.used[i].target.GetEntityID() == target.GetEntityID()
        && this.used[i].recordID == recordID { return true; };
      i += 1;
    };
    return false;
  }

  public final func Mark(target: ref<NPCPuppet>, recordID: TweakDBID) -> Void {
    let stamp: ref<SDPQHSpreadStamp> = new SDPQHSpreadStamp();
    stamp.target = target;
    stamp.recordID = recordID;
    let current: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(target, recordID);
    if IsDefined(current) { stamp.initialTime = EngineTime.ToFloat(current.GetInitialApplicationSimTimestamp()); };
    ArrayPush(this.used, stamp);
  }

  public final static func HasFamily(target: ref<NPCPuppet>, family: Int32) -> Bool {
    let effects: array<ref<StatusEffect>> = StatusEffectHelper.GetAppliedEffects(target);
    let i: Int32 = 0;
    while i < ArraySize(effects) {
      if SDPQHLab.Family(effects[i].GetRecord()) == family { return true; };
      i += 1;
    };
    return false;
  }
}

// Verify registration after native status handlers have run. API return values
// alone do not establish whether a visible/registered copy exists.
public class SDPQHSpreadReceipt extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public let lab: ref<SDPQHLab>;
  public let source: wref<NPCPuppet>;
  public let targets: array<wref<NPCPuppet>>;
  public let recordID: TweakDBID;
  public let family: Int32;
  public let started: Float;
  public let expires: Float;
  public let accepted: Int32;

  public func Call() -> Void {
    this.lab.pending = false;
    if !IsDefined(this.player) { return; };
    let confirmed: Int32 = 0;
    let timed: Int32 = 0;
    let i: Int32 = 0;
    let system: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(this.player.GetGame());
    while i < ArraySize(this.targets) {
      let target: ref<NPCPuppet> = this.targets[i];
      if IsDefined(target) {
        let effect: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(target, this.recordID);
        if IsDefined(effect) && effect.GetInstigatorEntityID() == this.player.GetEntityID()
          && EngineTime.ToFloat(effect.GetInitialApplicationSimTimestamp()) >= this.started {
          confirmed += 1;
          this.lab.Mark(target, this.recordID);
          let remaining: Float = this.expires - SDPPrototypeRuntime.Now(this.player);
          if remaining > 0.00 {
            system.SetStatusEffectRemainingDuration(target.GetEntityID(), this.recordID, remaining);
            let observed: Float = effect.GetRemainingDuration();
            if observed >= remaining - 0.20 && observed <= remaining + 0.20 { timed += 1; };
            // Expire this copied instance at the source deadline even if the
            // setter refuses. A later recast/refresh has different timestamps.
            let expiry: ref<SDPQHDurationCorrection> = new SDPQHDurationCorrection();
            expiry.target = target;
            expiry.recordID = this.recordID;
            expiry.initialTime = EngineTime.ToFloat(effect.GetInitialApplicationSimTimestamp());
            expiry.lastTime = EngineTime.ToFloat(effect.GetLastApplicationSimTimestamp());
            expiry.expires = this.expires;
            GameInstance.GetDelaySystem(this.player.GetGame()).DelayCallback(expiry, remaining + 0.02);
          };
        };
      };
      i += 1;
    };
    if confirmed > 0 && IsDefined(this.source) && StatusEffectSystem.ObjectHasStatusEffect(this.source, this.recordID) {
      this.lab.Mark(this.source, this.recordID);
    };
    this.lab.report = SDPQHLab.FamilyName(this.family) + ": " + IntToString(confirmed) + "/" + IntToString(ArraySize(this.targets))
      + " recipients have the copied status. Duration verified: " + IntToString(timed)
      + "; expiry guard: " + IntToString(confirmed - timed) + ". Apply API accepted: " + IntToString(this.accepted) + ".";
    this.lab.sequence += 1;
    this.player.SDP_PrototypeNotify(this.lab.report);
  }
}

@addField(PlayerPuppet)
private let m_sdpQHLab: ref<SDPQHLab>;

@addMethod(PlayerPuppet)
public final func SDP_LabAction(index: Int32) -> ref<ObjectAction_Record> {
  let actions: array<TweakDBID> = RPGManager.GetPlayerQuickHackList(this);
  if index < 0 || index >= ArraySize(actions) { return null; };
  return TweakDBInterface.GetObjectActionRecord(actions[index]);
}

@addMethod(PlayerPuppet)
public final func SDP_LabCount() -> Int32 {
  let actions: array<TweakDBID> = RPGManager.GetPlayerQuickHackList(this);
  return ArraySize(actions);
}

@addMethod(PlayerPuppet)
public final func SDP_LabAudit(index: Int32) -> String {
  let action: ref<ObjectAction_Record> = this.SDP_LabAction(index);
  if !IsDefined(action) { return "Equip quickhacks in a cyberdeck to inspect their live records."; };
  let effects: array<wref<ObjectActionEffect_Record>>;
  action.CompletionEffects(effects);
  let text: String = TDBID.ToStringDEBUG(action.GetID()) + "\nAction: " + NameToString(action.ActionName());
  let startEffects: array<wref<ObjectActionEffect_Record>>;
  action.StartEffects(startEffects);
  text += "\nStart effects (not reconstructed): " + IntToString(ArraySize(startEffects));
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    text += "\nCompletion " + IntToString(i) + " recipient=" + EnumValueToString("gamedataObjectActionReference", Cast<Int64>(EnumInt(effects[i].Recipient().Type())));
    let status: ref<StatusEffect_Record> = effects[i].StatusEffect();
    if IsDefined(status) {
      text += "\n  Status leaf: " + TDBID.ToStringDEBUG(status.GetID()) + " | " + SDPQHLab.FamilyName(SDPQHLab.Family(status));
      text += "\n  Tags:";
      let j: Int32 = 0;
      while j < status.GetGameplayTagsCount() { text += " " + NameToString(status.GetGameplayTagsItem(j)); j += 1; };
      if IsDefined(status.Duration()) { text += "\n  Duration: " + TDBID.ToStringDEBUG(status.Duration().GetID()); };
      if IsDefined(status.AIData()) { text += "\n  AI: " + TDBID.ToStringDEBUG(status.AIData().GetID()); };
      text += "\n  Packages: " + IntToString(status.GetPackagesCount());
      j = 0;
      while j < status.GetPackagesCount() {
        let package: ref<GameplayLogicPackage_Record> = status.GetPackagesItem(j);
        text += "\n    " + TDBID.ToStringDEBUG(package.GetID());
        let k: Int32 = 0;
        while k < package.GetEffectorsCount() {
          text += "\n      Effector: " + TDBID.ToStringDEBUG(package.GetEffectorsItem(k).GetID())
            + " [" + NameToString(package.GetEffectorsItem(k).EffectorClassName()) + "]";
          k += 1;
        };
        k = 0;
        while k < package.GetStatsCount() {
          text += "\n      Stat: " + TDBID.ToStringDEBUG(package.GetStatsItem(k).GetID());
          k += 1;
        };
        j += 1;
      };
    };
    if IsDefined(effects[i].EffectorToTrigger()) { text += "\n  Effector (not reconstructed): " + TDBID.ToStringDEBUG(effects[i].EffectorToTrigger().GetID()); };
    i += 1;
  };
  text += "\nStart/activation, RAM, trace and upload queue remain native-only.";
  return text;
}

// Reject partial reconstructions: the entire completion list must be one or two
// supported target-status leaves, without side effectors or other recipients.
@addMethod(PlayerPuppet)
public final func SDP_LabRebuildable(index: Int32) -> Bool {
  let action: ref<ObjectAction_Record> = this.SDP_LabAction(index);
  if !IsDefined(action) { return false; };
  let effects: array<wref<ObjectActionEffect_Record>>;
  action.CompletionEffects(effects);
  if ArraySize(effects) < 1 || ArraySize(effects) > 2 { return false; };
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    if !IsDefined(effects[i].Recipient()) || NotEquals(effects[i].Recipient().Type(), gamedataObjectActionReference.Target)
      || IsDefined(effects[i].EffectorToTrigger()) || SDPQHLab.Family(effects[i].StatusEffect()) == 0 { return false; };
    i += 1;
  };
  return true;
}

@addMethod(PlayerPuppet)
public final func SDP_LabLeaf(index: Int32, leaf: Int32) -> String {
  let action: ref<ObjectAction_Record> = this.SDP_LabAction(index);
  if !IsDefined(action) || leaf < 0 { return ""; };
  let effects: array<wref<ObjectActionEffect_Record>>;
  action.CompletionEffects(effects);
  let found: Int32 = 0;
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    if IsDefined(effects[i].Recipient()) && Equals(effects[i].Recipient().Type(), gamedataObjectActionReference.Target)
      && SDPQHLab.Family(effects[i].StatusEffect()) > 0 {
      if found == leaf { return TDBID.ToStringDEBUG(effects[i].StatusEffect().GetID()); };
      found += 1;
    };
    i += 1;
  };
  return "";
}

@addMethod(PlayerPuppet)
public final func SDP_LabInspectTarget() -> String {
  let target: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  if !IsDefined(target) { return "No NPC selected."; };
  let effects: array<ref<StatusEffect>> = StatusEffectHelper.GetAppliedEffects(target);
  let text: String = "Target " + EntityID.ToDebugString(target.GetEntityID());
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    let record: ref<StatusEffect_Record> = effects[i].GetRecord();
    if record.GameplayTagsContains(n"Quickhack") || SDPQHLab.Family(record) > 0 {
      text += "\n" + TDBID.ToStringDEBUG(record.GetID()) + " | remaining=" + FloatToString(effects[i].GetRemainingDuration())
        + " | total=" + FloatToString(effects[i].GetTotalDuration())
        + " | stacks=" + IntToString(Cast<Int32>(effects[i].GetStackCount()))
        + " | player-owned=" + (effects[i].GetInstigatorEntityID() == this.GetEntityID() ? "yes" : "no");
    };
    i += 1;
  };
  return text;
}

@addMethod(PlayerPuppet)
public final func SDP_LabSpreadNative() -> String {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled { return "Enable the workbench first."; };
  let target: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  let rejection: Int32 = SDPPrototypeRuntime.TargetRejection(this, target);
  if rejection != 0 { return SDPPrototypeRuntime.RejectionText(rejection); };
  if Vector4.Distance(this.GetWorldPosition(), target.GetWorldPosition()) > 30.00 { return "Native spread source must be within 30m."; };
  if !IsDefined(this.m_sdpQHLab) { this.m_sdpQHLab = new SDPQHLab(); };
  if this.m_sdpQHLab.pending { return "Waiting for the previous spread's recipient check."; };
  this.m_sdpQHLab.Prune(this);
  if ArraySize(this.m_sdpQHLab.used) > 60 { return "Native spread tracking is full; wait for existing effects to expire."; };
  let effects: array<ref<StatusEffect>> = StatusEffectHelper.GetAppliedEffects(target);
  let chosen: ref<StatusEffect>;
  let latest: Float = -1.00;
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    if effects[i].GetInstigatorEntityID() == this.GetEntityID() && effects[i].GetRemainingDuration() > 0.10
      && SDPQHLab.Family(effects[i].GetRecord()) > 0 {
      let stamp: Float = EngineTime.ToFloat(effects[i].GetLastApplicationSimTimestamp());
      if stamp > latest { chosen = effects[i]; latest = stamp; };
    };
    i += 1;
  };
  if !IsDefined(chosen) { return "No supported, active player quickhack. Try Reboot Optics or Overheat, then inspect the target."; };
  let recordID: TweakDBID = chosen.GetRecord().GetID();
  if this.m_sdpQHLab.IsUsed(target, recordID) { return "This active hack was already spread, or is a copy. Wait for it to expire before another native upload."; };
  let query: TargetSearchQuery;
  query.testedSet = TargetingSet.Complete;
  query.maxDistance = 40.00;
  query.filterObjectByDistance = true;
  query.includeSecondaryTargets = false;
  query.ignoreInstigator = true;
  let parts: array<TS_TargetPartInfo>;
  GameInstance.GetTargetingSystem(this.GetGame()).GetTargetParts(this, query, parts);
  let family: Int32 = SDPQHLab.Family(chosen.GetRecord());
  let nearby: Int32 = 0;
  let already: Int32 = 0;
  let excluded: Int32 = 0;
  let seen: array<EntityID>;
  let remaining: Float = chosen.GetRemainingDuration();
  let expires: Float = SDPPrototypeRuntime.Now(this) + remaining;
  let system: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(this.GetGame());
  let receipt: ref<SDPQHSpreadReceipt> = new SDPQHSpreadReceipt();
  receipt.player = this;
  receipt.lab = this.m_sdpQHLab;
  receipt.source = target;
  receipt.recordID = recordID;
  receipt.family = family;
  receipt.started = SDPPrototypeRuntime.Now(this);
  receipt.expires = expires;
  if remaining <= 0.25 { return "Source hack is about to expire. Apply a fresh hack before spreading."; };
  i = 0;
  while i < ArraySize(parts) && ArraySize(receipt.targets) < 3 {
    let component: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(component) {
      let other: ref<NPCPuppet> = component.GetEntity() as NPCPuppet;
      if IsDefined(other) && other.GetEntityID() != target.GetEntityID()
        && Vector4.Distance(target.GetWorldPosition(), other.GetWorldPosition()) <= 8.00
        && !ArrayContains(seen, other.GetEntityID()) {
        ArrayPush(seen, other.GetEntityID());
        nearby += 1;
        if !SDPPrototypeRuntime.Eligible(this, other) { excluded += 1; } else {
          if SDPQHLab.HasFamily(other, family) || this.m_sdpQHLab.IsUsed(other, recordID) { already += 1; } else {
            ArrayPush(receipt.targets, other);
            if system.ApplyStatusEffect(other.GetEntityID(), recordID,
              chosen.GetInstigatorStaticDataID(), this.GetEntityID(), chosen.GetStackCount()) { receipt.accepted += 1; };
          };
        };
      };
    };
    i += 1;
  };
  if ArraySize(receipt.targets) == 0 {
    return "No new spread requests: nearby=" + IntToString(nearby) + ", already affected=" + IntToString(already) + ", excluded=" + IntToString(excluded) + ".";
  };
  this.m_sdpQHLab.pending = true;
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(receipt, 0.10);
  return "Sent " + IntToString(ArraySize(receipt.targets)) + " spread requests; checking recipients after native processing.";
}

@addMethod(PlayerPuppet)
public final func SDP_LabSpreadSequence() -> Int32 { return IsDefined(this.m_sdpQHLab) ? this.m_sdpQHLab.sequence : 0; }

@addMethod(PlayerPuppet)
public final func SDP_LabSpreadReport() -> String { return IsDefined(this.m_sdpQHLab) ? this.m_sdpQHLab.report : ""; }
