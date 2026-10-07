// Comparison meter: what a native quickhack and our recreation actually did.
// A native upload (statuses tagged Quickhack, applied by V) or a program chip
// upload opens an entry per target. Damage V deals with hacks and damage over
// time, and the statuses involved, are added to the newest entry of the same
// kind on that target: our pulses use our own attack record, so the two never
// mix even on one target.
module SkillDrivenProgression

public class SDPQHMeterEntry extends IScriptable {
  public let label: String;
  public let program: Bool;
  public let target: wref<NPCPuppet>;
  public let targetName: String;
  public let started: Float;
  public let lastActivity: Float;
  public let firstHit: Float;
  public let lastHit: Float;
  public let damage: Float;
  public let hits: Int32;
  public let statuses: array<TweakDBID>;
  public let statusStart: array<Float>;
  // -1 while the status is still on the target.
  public let statusEnd: array<Float>;

  public final func Status(id: TweakDBID, now: Float, applied: Bool) -> Void {
    let i: Int32 = ArraySize(this.statuses) - 1;
    while i >= 0 && this.statuses[i] != id { i -= 1; };
    if applied {
      // A refresh keeps the running record; a new application starts one.
      if i >= 0 && this.statusEnd[i] < 0.00 { return; };
      if ArraySize(this.statuses) >= 6 { return; };
      ArrayPush(this.statuses, id);
      ArrayPush(this.statusStart, now);
      ArrayPush(this.statusEnd, -1.00);
    } else {
      if i < 0 || this.statusEnd[i] >= 0.00 { return; };
      this.statusEnd[i] = now;
    };
    this.lastActivity = now;
  }

  public final func Active() -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(this.statusEnd) {
      if this.statusEnd[i] < 0.00 { return true; };
      i += 1;
    };
    return false;
  }

  public final func Text(now: Float) -> String {
    let text: String = (this.program ? "[ours] " : "[native] ") + this.label + " on " + this.targetName + ": ";
    if this.hits > 0 {
      text += SDPQHDesign.Num(this.damage) + " damage in " + IntToString(this.hits) + (this.hits == 1 ? " hit" : " hits");
      if this.hits > 1 { text += " over " + SDPQHDesign.Num(this.lastHit - this.firstHit) + "s"; };
      text += ", first at +" + SDPQHDesign.Num(this.firstHit - this.started) + "s";
    } else {
      text += "no damage";
    };
    let i: Int32 = 0;
    while i < ArraySize(this.statuses) {
      text += " | " + SDPQHNativeRef.Short(this.statuses[i]) + " "
        + (this.statusEnd[i] < 0.00 ? "on for " + SDPQHDesign.Num(now - this.statusStart[i]) + "s" : SDPQHDesign.Num(this.statusEnd[i] - this.statusStart[i]) + "s");
      i += 1;
    };
    return text;
  }
}

public class SDPQHMeter extends IScriptable {
  public let entries: array<ref<SDPQHMeterEntry>>;

  public final static func MaxEntries() -> Int32 { return 12; }

  public final func Open(target: ref<NPCPuppet>, label: String, program: Bool, now: Float) -> ref<SDPQHMeterEntry> {
    let entry: ref<SDPQHMeterEntry> = new SDPQHMeterEntry();
    entry.label = label;
    entry.program = program;
    entry.target = target;
    entry.targetName = GetLocalizedText(target.GetDisplayName());
    if StrLen(entry.targetName) == 0 { entry.targetName = "target"; };
    entry.started = now;
    entry.lastActivity = now;
    if ArraySize(this.entries) >= SDPQHMeter.MaxEntries() { ArrayErase(this.entries, 0); };
    ArrayPush(this.entries, entry);
    return entry;
  }

  // Newest entry of a kind on a target that is still running or recently active.
  public final func Find(target: ref<NPCPuppet>, program: Bool, now: Float, window: Float) -> ref<SDPQHMeterEntry> {
    let i: Int32 = ArraySize(this.entries) - 1;
    while i >= 0 {
      let entry: ref<SDPQHMeterEntry> = this.entries[i];
      if entry.target == target && entry.program == program {
        return entry.Active() || now - entry.lastActivity <= window ? entry : null;
      };
      i -= 1;
    };
    return null;
  }

  public final func Report(now: Float) -> String {
    if ArraySize(this.entries) == 0 {
      return "Nothing measured yet. Upload a native quickhack and its recreation on two similar enemies.";
    };
    let text: String = "";
    let i: Int32 = ArraySize(this.entries) - 1;
    while i >= 0 {
      text += (StrLen(text) > 0 ? "\n" : "") + this.entries[i].Text(now);
      i -= 1;
    };
    return text;
  }
}

@addField(PlayerPuppet)
private let m_sdpqhMeter: ref<SDPQHMeter>;

@addMethod(PlayerPuppet)
public final func SDPQH_Meter() -> ref<SDPQHMeter> {
  if !IsDefined(this.m_sdpqhMeter) { this.m_sdpqhMeter = new SDPQHMeter(); };
  return this.m_sdpqhMeter;
}

@addMethod(PlayerPuppet)
public final func SDPQH_MeterProgram(target: ref<NPCPuppet>, label: String) -> Void {
  if IsDefined(target) { this.SDPQH_Meter().Open(target, label, true, SDPPrototypeRuntime.Now(this)); };
}

@addMethod(PlayerPuppet)
public final func SDPQH_MeterStatus(target: ref<NPCPuppet>, status: ref<StatusEffect_Record>, applied: Bool) -> Void {
  if !IsDefined(target) || !IsDefined(status) || status.GameplayTagsContains(n"SDPCustomHack")
    || status.GetID() == t"BaseStatusEffect.WasQuickHacked" || status.GetID() == t"BaseStatusEffect.QuickHackUploaded" { return; };
  let ours: Bool = status.GameplayTagsContains(n"SDPPrimitive");
  if !ours && !status.GameplayTagsContains(n"Quickhack") { return; };
  let meter: ref<SDPQHMeter> = this.SDPQH_Meter();
  let now: Float = SDPPrototypeRuntime.Now(this);
  let entry: ref<SDPQHMeterEntry> = meter.Find(target, ours, now, 15.00);
  // Statuses applied within a second belong to the same native upload.
  if !ours && applied && (!IsDefined(entry) || now - entry.started > 1.00) {
    entry = meter.Open(target, "native " + SDPQHNativeRef.Short(status.GetID()), false, now);
  };
  if IsDefined(entry) { entry.Status(status.GetID(), now, applied); };
}

@addMethod(PlayerPuppet)
public final func SDPQH_MeterDamage(target: ref<NPCPuppet>, evt: ref<gameDamageReceivedEvent>) -> Void {
  if !IsDefined(this.m_sdpqhMeter) || ArraySize(this.m_sdpqhMeter.entries) == 0 || !IsDefined(evt)
    || !IsDefined(evt.hitEvent) || !IsDefined(evt.hitEvent.attackData) || evt.totalDamageReceived <= 0.00 { return; };
  let attack: ref<AttackData> = evt.hitEvent.attackData;
  let instigator: ref<PlayerPuppet> = attack.GetInstigator() as PlayerPuppet;
  if instigator != this { return; };
  let record: wref<Attack_Record> = IsDefined(attack.GetAttackDefinition()) ? attack.GetAttackDefinition().GetRecord() : null;
  let ours: Bool = IsDefined(record) && record.GetID() == t"SkillDrivenProgression.PrimitiveAttack";
  let kind: gamedataAttackType = attack.GetAttackType();
  if !ours && NotEquals(kind, gamedataAttackType.Hack) && NotEquals(kind, gamedataAttackType.Effect)
    && !attack.HasFlag(hitFlag.QuickHack) && !attack.HasFlag(hitFlag.DamageOverTime) { return; };
  let now: Float = SDPPrototypeRuntime.Now(this);
  let entry: ref<SDPQHMeterEntry> = this.m_sdpqhMeter.Find(target, ours, now, 15.00);
  if !IsDefined(entry) { return; };
  if entry.hits == 0 { entry.firstHit = now; };
  entry.hits += 1;
  entry.lastHit = now;
  entry.damage += evt.totalDamageReceived;
  entry.lastActivity = now;
}

@addMethod(PlayerPuppet)
public final func SDPQH_MeterReport() -> String {
  return this.SDPQH_Meter().Report(SDPPrototypeRuntime.Now(this));
}

@addMethod(PlayerPuppet)
public final func SDPQH_MeterClear() -> String {
  this.m_sdpqhMeter = new SDPQHMeter();
  return "Comparison meter cleared.";
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if IsDefined(player) && IsDefined(evt) && evt.instigatorEntityID == player.GetEntityID() {
    player.SDPQH_MeterStatus(this, evt.staticData, true);
  };
  return result;
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectRemoved(evt: ref<RemoveStatusEffect>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  if IsDefined(player) && IsDefined(evt) && evt.isFinalRemoval { player.SDPQH_MeterStatus(this, evt.staticData, false); };
  return result;
}

@wrapMethod(GameObject)
protected final func ProcessDamageReceived(evt: ref<gameDamageReceivedEvent>) -> Void {
  wrappedMethod(evt);
  let target: ref<NPCPuppet> = this as NPCPuppet;
  if IsDefined(target) {
    let player: ref<PlayerPuppet> = GetPlayer(target.GetGame());
    if IsDefined(player) { player.SDPQH_MeterDamage(target, evt); };
  };
}
