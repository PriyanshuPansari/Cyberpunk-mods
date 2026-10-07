module SkillDrivenProgression

// Each instance owns a private status and an independent, bounded pulse clock.
public class SDPPrimitiveInstance extends IScriptable {
  public let target: wref<NPCPuppet>;
  public let rule: ref<SDPPrototypeRule>;
  public let record: TweakDBID;
  public let expires: Float;
  public let nextPulse: Float;

  public final static func Record(rule: ref<SDPPrototypeRule>) -> TweakDBID {
    let name: String;
    switch rule.payload {
      case 1: name = "Blind"; break;
      case 2: name = "Burn"; break;
      case 3: name = "Shock"; break;
      case 4: name = "Stun"; break;
      case 6: name = "Slow"; break;
      case 7: name = "Chemical"; break;
      case 8: name = "Physical"; break;
      default: return t"";
    };
    return TDBID.Create("SkillDrivenProgression.Prototype" + name + (rule.duration == 4.00 ? "" : IntToString(Cast<Int32>(rule.duration))));
  }

  public final static func Damaging(payload: Int32) -> Bool {
    return payload == 2 || payload == 3 || payload == 7 || payload == 8;
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
    entry.expires = expires > 0.00 ? expires : now + rule.duration;
    entry.nextPulse = expires > 0.00 ? nextPulse : now;
    ArrayPush(runtime.effects, entry);
    return true;
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
    hit.attackData.AddFlag(hitFlag.DamageOverTime, n"SDPPrimitive");
    // Native damage pipeline keeps attribution, defenses and death handling.
    GameInstance.GetDamageSystem(player.GetGame()).QueueHitEvent(hit, entry.target);
    runtime.pulses += 1;
  }

  public final static func Tick(runtime: ref<SDPPrototypeRuntime>, player: ref<PlayerPuppet>) -> Void {
    let now: Float = SDPPrototypeRuntime.Now(player);
    let i: Int32 = ArraySize(runtime.effects) - 1;
    while i >= 0 {
      let entry: ref<SDPPrimitiveInstance> = runtime.effects[i];
      if !SDPPrototypeRuntime.Eligible(player, entry.target) || now >= entry.expires {
        if IsDefined(entry.target) { StatusEffectHelper.RemoveStatusEffect(entry.target, entry.record); };
        ArrayErase(runtime.effects, i);
      } else {
        if SDPPrimitiveInstance.Damaging(entry.rule.payload) && now >= entry.nextPulse {
          SDPPrimitiveInstance.Pulse(runtime, player, entry);
          // Skip missed ticks instead of releasing a burst after a long pause.
          entry.nextPulse = now + entry.rule.interval;
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

