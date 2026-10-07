module SkillDrivenProgression

// Each instance owns a private status and an independent, bounded pulse clock.
public class SDPPrimitiveInstance extends IScriptable {
  public let target: wref<NPCPuppet>;
  public let rule: ref<SDPPrototypeRule>;
  public let record: TweakDBID;
  public let expires: Float;
  public let nextPulse: Float;

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
    return "";
  }

  // Designed rules last 2, 4 or 8 s and use fixed records. Native references can
  // last any time: they use the open-ended record, trimmed after it is applied.
  public final static func FixedDuration(duration: Float) -> Bool {
    return duration == 2.00 || duration == 4.00 || duration == 8.00;
  }

  public final static func Record(rule: ref<SDPPrototypeRule>) -> TweakDBID {
    if SDPQHLook.Ready(rule.look, rule.payload) { return SDPQHLook.ID(rule.look, rule.payload); };
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

  public final static func Start(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>, target: ref<NPCPuppet>, rule: ref<SDPPrototypeRule>, expires: Float, nextPulse: Float) -> Bool {
    let now: Float = SDPPrototypeRuntime.Now(player);
    let record: TweakDBID = SDPPrimitiveInstance.Record(rule);
    if !IsDefined(TweakDBInterface.GetStatusEffectRecord(record)) || (expires > 0.00 && expires <= now) { return false; };
    // Same payload refreshes, never stacks. Other payloads retain their own clocks.
    let i: Int32 = ArraySize(runtime.effects) - 1;
    while i >= 0 {
      if runtime.effects[i].target == target && runtime.effects[i].rule.payload == rule.payload {
        StatusEffectHelper.RemoveStatusEffect(target, runtime.effects[i].record);
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
    let fresh: Bool = expires <= 0.00;
    entry.expires = fresh ? now + MaxF(rule.duration, 0.10) : expires;
    entry.nextPulse = fresh ? now : nextPulse;
    // Look records and open-ended records last 600 s until trimmed here.
    if !SDPPrimitiveInstance.FixedDuration(rule.duration) || TDBID.IsValid(rule.look) {
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
    context.record = TweakDBInterface.GetAttackRecord(t"SkillDrivenProgression.PrimitiveAttack");
    context.instigator = player;
    context.source = player;
    if !IsDefined(context.record) { runtime.lastEvent = "Missing primitive attack record."; return; };
    let attack: ref<IAttack> = IAttack.Create(context);
    if !IsDefined(attack) { runtime.lastEvent = "Could not create primitive attack."; return; };
    let stat: gamedataStatType = gamedataStatType.ThermalDamage;
    if entry.rule.payload == 3 { stat = gamedataStatType.ElectricDamage; };
    if entry.rule.payload == 7 { stat = gamedataStatType.ChemicalDamage; };
    if entry.rule.payload == 8 { stat = gamedataStatType.PhysicalDamage; };
    attack.AddStatModifier(RPGManager.CreateStatModifier(stat, gameStatModifierType.Additive, entry.rule.amount));
    let hit: ref<gameHitEvent> = new gameHitEvent();
    hit.target = entry.target;
    hit.attackData = new AttackData();
    hit.attackData.SetAttackDefinition(attack);
    hit.attackData.SetSource(player);
    hit.attackData.SetInstigator(player);
    hit.attackData.SetAttackType(gamedataAttackType.Hack);
    hit.attackData.AddFlag(hitFlag.QuickHack, n"SDPPrimitive");
    // A single-hit rule (interval 0) is burst damage, not damage over time.
    if entry.rule.interval > 0.00 { hit.attackData.AddFlag(hitFlag.DamageOverTime, n"SDPPrimitive"); };
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
      if !SDPPrototypeRuntime.Alive(entry.target) || now >= entry.expires {
        if IsDefined(entry.target) { StatusEffectHelper.RemoveStatusEffect(entry.target, entry.record); };
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
      if IsDefined(runtime.effects[i].target) { StatusEffectHelper.RemoveStatusEffect(runtime.effects[i].target, runtime.effects[i].record); };
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
