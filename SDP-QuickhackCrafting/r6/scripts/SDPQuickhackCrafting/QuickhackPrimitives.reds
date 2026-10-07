module SkillDrivenProgression

// Each instance owns a private status and an independent, bounded pulse clock.
// A recreation's native look keeps its native duration and stacking: its
// instance lasts while the look is on the target (up to 600 s) and pulses
// until then.
public class SDPPrimitiveInstance extends IScriptable {
  public let target: wref<NPCPuppet>;
  public let rule: ref<SDPPrototypeRule>;
  public let record: TweakDBID;
  public let started: Float;
  public let expires: Float;
  public let nextPulse: Float;

  public final func Look() -> Bool { return TDBID.IsValid(this.rule.look); }

  // Removes the status, every stack of a native look.
  public final func Remove() -> Void {
    if !IsDefined(this.target) { return; };
    let count: Uint32 = 1u;
    let status: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(this.target, this.record);
    if IsDefined(status) && status.GetStackCount() > 1u { count = status.GetStackCount(); };
    StatusEffectHelper.RemoveStatusEffect(this.target, this.record, count);
  }

  public final static func Name(payload: Int32) -> String {
    switch payload {
      case 1: return "Blind";
      case 2: return "Burn";
      case 3: return "Shock";
      case 4: return "Stun";
      case 6: return "Slow";
      case 7: return "Chemical";
      case 8: return "Physical";
      case 9: return "Immobilize";
      case 10: return "Jam";
      case 11: return "Deafen";
      case 12: return "Cyberware";
    };
    // 13 (native behavior) exists only as a recreation's native look.
    return "";
  }

  // Designed rules last 2, 4 or 8 s and use fixed records. Native references can
  // last any time: they use the open-ended record, trimmed after it is applied.
  public final static func FixedDuration(duration: Float) -> Bool {
    return duration == 2.00 || duration == 4.00 || duration == 8.00;
  }

  public final static func Record(rule: ref<SDPPrototypeRule>) -> TweakDBID {
    if SDPQHLook.Ready(rule.look) { return SDPQHLook.ID(rule.look); };
    let name: String = SDPPrimitiveInstance.Name(rule.payload);
    if StrLen(name) == 0 { return t""; };
    let suffix: String = "Long";
    if rule.duration == 4.00 { suffix = ""; };
    if rule.duration == 2.00 || rule.duration == 8.00 { suffix = IntToString(Cast<Int32>(rule.duration)); };
    return TDBID.Create("SkillDrivenProgression.Prototype" + name + suffix);
  }

  public final static func Damaging(payload: Int32) -> Bool {
    return SDPQHDesign.Damaging(payload);
  }

  // The same effect refreshes rather than stacks. A recreation's parts wear
  // distinct native looks, so for them "the same effect" is the same record.
  public final static func Same(entry: ref<SDPPrimitiveInstance>, rule: ref<SDPPrototypeRule>, record: TweakDBID) -> Bool {
    if TDBID.IsValid(entry.rule.look) || TDBID.IsValid(rule.look) { return entry.record == record; };
    return entry.rule.payload == rule.payload;
  }

  public final static func Start(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>, target: ref<NPCPuppet>, rule: ref<SDPPrototypeRule>, expires: Float, nextPulse: Float) -> Bool {
    let now: Float = SDPPrototypeRuntime.Now(player);
    let record: TweakDBID = SDPPrimitiveInstance.Record(rule);
    if !IsDefined(TweakDBInterface.GetStatusEffectRecord(record)) || (expires > 0.00 && expires <= now) { return false; };
    let look: Bool = TDBID.IsValid(rule.look);
    // A target immune to the native status gets none of the part, as the native refuses it.
    if look && SDPQHLook.Immune(target, rule.look) { return false; };
    // The same effect refreshes, never stacks; a native look stacks and
    // refreshes as its native status does. Other effects retain their own clocks.
    let i: Int32 = ArraySize(runtime.effects) - 1;
    while i >= 0 {
      if runtime.effects[i].target == target && SDPPrimitiveInstance.Same(runtime.effects[i], rule, record) {
        if !look { runtime.effects[i].Remove(); };
        ArrayErase(runtime.effects, i);
      };
      i -= 1;
    };
    if ArraySize(runtime.effects) >= 128 { return false; };
    player.SDP_OpticsTraceStatus(target, TweakDBInterface.GetStatusEffectRecord(record), "CUSTOM_PRIMITIVE_REQUEST");
    StatusEffectHelper.ApplyStatusEffect(target, record, player.GetEntityID());
    let entry: ref<SDPPrimitiveInstance> = new SDPPrimitiveInstance();
    entry.target = target;
    entry.rule = rule;
    entry.record = record;
    entry.started = now;
    let fresh: Bool = expires <= 0.00;
    entry.expires = fresh ? now + (look ? 600.00 : MaxF(rule.duration, 0.10)) : expires;
    entry.nextPulse = fresh ? now : nextPulse;
    // Open-ended records last 600 s until trimmed here; a look keeps its native duration.
    if !look && !SDPPrimitiveInstance.FixedDuration(rule.duration) {
      GameInstance.GetStatusEffectSystem(player.GetGame()).SetStatusEffectRemainingDuration(target.GetEntityID(), record, entry.expires - now);
    };
    ArrayPush(runtime.effects, entry);
    // The first pulse lands with the status; a single-hit rule (interval 0) ends there.
    if fresh && SDPPrimitiveInstance.Damaging(rule.payload) { SDPPrimitiveInstance.PulseDue(runtime, player, entry, now); };
    player.SDP_PrototypeWake();
    return true;
  }

  public final static func PulseDue(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>, entry: ref<SDPPrimitiveInstance>, now: Float) -> Void {
    SDPPrimitiveInstance.Pulse(runtime, player, entry);
    // Skip missed ticks instead of releasing a burst after a long pause.
    entry.nextPulse = entry.rule.interval > 0.00 ? now + entry.rule.interval : entry.expires + 1.00;
  }

  public final static func Pulse(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>, entry: ref<SDPPrimitiveInstance>) -> Void {
    let context: AttackInitContext;
    // A recreation's pulse is the native hit without its damage values
    // (SDPQHLook.MakeAttack): native damage type, attack type and hit flags.
    let native: Bool = SDPQHLook.AttackReady(entry.rule.attack);
    context.record = TweakDBInterface.GetAttackRecord(native ? SDPQHLook.AttackID(entry.rule.attack) : t"SkillDrivenProgression.PrimitiveAttack");
    context.instigator = player;
    context.source = player;
    if !IsDefined(context.record) { runtime.lastEvent = "Missing primitive attack record."; return; };
    let attack: ref<IAttack> = IAttack.Create(context);
    if !IsDefined(attack) { runtime.lastEvent = "Could not create primitive attack."; return; };
    let stat: gamedataStatType = gamedataStatType.ThermalDamage;
    if entry.rule.payload == 3 { stat = gamedataStatType.ElectricDamage; };
    if entry.rule.payload == 7 { stat = gamedataStatType.ChemicalDamage; };
    if entry.rule.payload == 8 { stat = gamedataStatType.PhysicalDamage; };
    let amount: Float = entry.rule.amount;
    // A stackable native damage package hits once per stack.
    if entry.rule.stacks {
      let status: ref<StatusEffect> = StatusEffectHelper.GetStatusEffectByID(entry.target, entry.record);
      if IsDefined(status) && status.GetStackCount() > 1u { amount *= Cast<Float>(status.GetStackCount()); };
    };
    attack.AddStatModifier(RPGManager.CreateStatModifier(stat, gameStatModifierType.Additive, amount));
    let hit: ref<gameHitEvent> = new gameHitEvent();
    hit.target = entry.target;
    hit.attackData = new AttackData();
    hit.attackData.SetAttackDefinition(attack);
    hit.attackData.SetSource(player);
    hit.attackData.SetInstigator(player);
    let kind: gamedataAttackType = gamedataAttackType.Hack;
    if native && IsDefined(context.record.AttackType()) { kind = context.record.AttackType().Type(); };
    hit.attackData.SetAttackType(kind);
    // The SDPPrimitive source marks our pulses for the comparison meter.
    hit.attackData.AddFlag(hitFlag.QuickHack, n"SDPPrimitive");
    if native {
      // As TriggerAttackOnOwnerEffect turns the record's hit flags into the hit's.
      let flags: array<String> = context.record.HitFlags();
      let f: Int32 = 0;
      while f < ArraySize(flags) {
        hit.attackData.AddFlag(IntEnum<hitFlag>(Cast<Int32>(EnumValueFromString("hitFlag", flags[f]))), n"SDPPrimitive");
        f += 1;
      };
    } else {
      // A single-hit rule (interval 0) is burst damage, not damage over time.
      if entry.rule.interval > 0.00 { hit.attackData.AddFlag(hitFlag.DamageOverTime, n"SDPPrimitive"); };
    };
    // Native damage pipeline keeps attribution, defenses and death handling.
    GameInstance.GetDamageSystem(player.GetGame()).QueueHitEvent(hit, entry.target);
    runtime.pulses += 1;
  }

  public final static func Tick(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>) -> Void {
    let now: Float = SDPPrototypeRuntime.Now(player);
    let i: Int32 = ArraySize(runtime.effects) - 1;
    while i >= 0 {
      let entry: ref<SDPPrimitiveInstance> = runtime.effects[i];
      // Program chips may target bosses, so effects end on death rather than eligibility.
      // A native look ends with its native status (given half a second to land);
      // the status system removes it, so only our own statuses are removed here.
      let gone: Bool = entry.Look() && IsDefined(entry.target) && now - entry.started > 0.50
        && !StatusEffectSystem.ObjectHasStatusEffect(entry.target, entry.record);
      if !SDPPrototypeRuntime.Alive(entry.target) || now >= entry.expires || gone {
        if !entry.Look() { entry.Remove(); };
        ArrayErase(runtime.effects, i);
      } else {
        if SDPPrimitiveInstance.Damaging(entry.rule.payload) && now >= entry.nextPulse {
          SDPPrimitiveInstance.PulseDue(runtime, player, entry, now);
        };
      };
      i -= 1;
    };
  }

  public final static func CopyActive(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>, source: ref<NPCPuppet>, target: ref<NPCPuppet>) -> Void {
    let snapshot: array<ref<SDPPrimitiveInstance>> = runtime.effects;
    let i: Int32 = 0;
    while i < ArraySize(snapshot) {
      if snapshot[i].target == source {
        SDPPrimitiveInstance.Start(runtime, player, target, snapshot[i].rule, snapshot[i].expires, snapshot[i].nextPulse);
      };
      i += 1;
    };
  }

  public final static func Clear(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(runtime.effects) {
      runtime.effects[i].Remove();
      i += 1;
    };
    ArrayClear(runtime.effects);
  }

  public final static func Describe(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>, target: ref<NPCPuppet>) -> String {
    let result: String = "";
    let i: Int32 = 0;
    while i < ArraySize(runtime.effects) {
      let entry: ref<SDPPrimitiveInstance> = runtime.effects[i];
      if entry.target == target {
        result += " | primitive " + IntToString(entry.rule.payload) + ": "
          + (StatusEffectSystem.ObjectHasStatusEffect(target, entry.record) ? "registered" : "status absent")
          + ", " + IntToString(Cast<Int32>(MaxF(0.00, entry.expires - SDPPrototypeRuntime.Now(player)))) + "s";
        if entry.rule.payload == 1 && IsDefined(target.GetSensesComponent()) {
          result += ", recorded optics preset=" + TDBID.ToStringDEBUG(target.GetSensesComponent().SDP_RecordedPreset());
        };
      };
      i += 1;
    };
    return result;
  }
}


// Drives pulses, expiry and delayed rules while anything runs, so program chips
// work without CET. CET's per-frame tick is harmless on top: pulses are timed.
public class SDPPrototypeTicker extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if IsDefined(this.player) { this.player.SDP_PrototypeTickerFired(); };
  }
}

@addField(PlayerPuppet)
private let m_sdpTickerArmed: Bool;

@addField(PlayerPuppet)
private let m_sdpTickerArmedAt: Float;

@addMethod(PlayerPuppet)
public final func SDP_PrototypeWake() -> Void {
  let now: Float = SDPPrototypeRuntime.Now(this);
  // A callback that never fired (dropped by the delay system) must not stall the tick.
  if this.m_sdpTickerArmed && now - this.m_sdpTickerArmedAt < 1.00 { return; };
  this.m_sdpTickerArmed = true;
  this.m_sdpTickerArmedAt = now;
  let ticker: ref<SDPPrototypeTicker> = new SDPPrototypeTicker();
  ticker.player = this;
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(ticker, 0.10, true);
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeTickerFired() -> Void {
  this.m_sdpTickerArmed = false;
  this.SDP_PrototypeTick();
  if IsDefined(this.m_sdpPrototype) && (ArraySize(this.m_sdpPrototype.effects) > 0 || ArraySize(this.m_sdpPrototype.hosts) > 0) {
    this.SDP_PrototypeWake();
  };
}

// Weapon jam primitive: a jammed NPC's shots do not leave the gun.
@wrapMethod(AIWeapon)
public final static func Fire(weaponOwner: wref<GameObject>, weapon: wref<WeaponObject>, const timeStamp: Float, tbhCoefficient: Float, requestedTriggerMode: gamedataTriggerMode, opt targetPosition: Vector4, opt target: ref<GameObject>, opt rangedAttack: TweakDBID, opt maxSpreadOverride: Float, opt aimingDelay: Float, opt offset: Vector4, opt shouldTrackTarget: Bool, opt predictionTime: Float, opt posProviderOverride: ref<IPositionProvider>, opt muzzleOffset: Vector4, opt weaponCustomEvent: CName) -> Void {
  if IsDefined(weaponOwner) && StatusEffectSystem.ObjectHasStatusEffectWithTag(weaponOwner, n"SDPJam") { return; };
  wrappedMethod(weaponOwner, weapon, timeStamp, tbhCoefficient, requestedTriggerMode, targetPosition, target, rangedAttack, maxSpreadOverride, aimingDelay, offset, shouldTrackTarget, predictionTime, posProviderOverride, muzzleOffset, weaponCustomEvent);
}
