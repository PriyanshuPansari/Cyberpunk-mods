// Full record dump of the native quickhack programs, so they can be rebuilt
// exactly. The CET window writes it to native-quickhacks-dump.txt.
// Each program's records are walked from its quickhack action: costs, upload,
// start and completion effects, statuses, AI data, VFX/SFX, packages, stat
// modifiers, effectors, attacks and prerequisites, including statuses that
// effectors apply. With Codeware every field of every record is listed (field
// names from reflection, values from TweakXL's flat reader); without it, the
// record tree with the main values only.
module SkillDrivenProgression

public class SDPQHDump extends IScriptable {
  public let player: wref<PlayerPuppet>;
  public let text: String;
  public let seen: array<TweakDBID>;

  public final func Line(depth: Int32, line: String) -> Void {
    let pad: String = "";
    let i: Int32 = 0;
    while i < depth { pad += "  "; i += 1; };
    this.text += pad + line + "\n";
  }

  public final static func Name(id: TweakDBID) -> String {
    return TDBID.IsValid(id) ? TDBID.ToStringDEBUG(id) : "none";
  }

  // "gamedataStatusEffect_Record" -> "StatusEffect".
  public final static func Kind(record: ref<TweakDBRecord>) -> String {
    let kind: String = NameToString(record.GetClassName());
    if StrBeginsWith(kind, "gamedata") { kind = StrMid(kind, 8); };
    if StrEndsWith(kind, "_Record") { kind = StrLeft(kind, StrLen(kind) - 7); };
    return kind;
  }

  // Records that make up a quickhack; anything else is listed by ID only.
  public final static func Expand(record: ref<TweakDBRecord>) -> Bool {
    return record.IsA(n"gamedataObjectAction_Record") || record.IsA(n"gamedataObjectActionEffect_Record")
      || record.IsA(n"gamedataObjectActionCost_Record") || record.IsA(n"gamedataObjectActionPrereq_Record")
      || record.IsA(n"gamedataStatusEffect_Record") || record.IsA(n"gamedataStatusEffectAIData_Record")
      || record.IsA(n"gamedataStatusEffectFX_Record") || record.IsA(n"gamedataStatModifierGroup_Record")
      || record.IsA(n"gamedataStatModifier_Record") || record.IsA(n"gamedataGameplayLogicPackage_Record")
      || record.IsA(n"gamedataEffector_Record") || record.IsA(n"gamedataAttack_Record")
      || record.IsA(n"gamedataStatusEffectAttackData_Record") || record.IsA(n"gamedataIPrereq_Record");
  }

  public final static func Program(player: ref<PlayerPuppet>, reference: ref<SDPQHNativeRef>) -> String {
    let dump: ref<SDPQHDump> = new SDPQHDump();
    dump.player = player;
    let item: ref<Item_Record> = TweakDBInterface.GetItemRecord(reference.item);
    dump.Line(0, "=== " + reference.Title() + " | " + SDPQHDump.Name(reference.item));
    if IsDefined(item) && IsDefined(item.Quality()) {
      dump.Line(1, "quality = " + SDPQHDump.Name(item.Quality().GetID())
        + " | shardType = " + NameToString(TweakDBInterface.GetCName(reference.item + t".shardType", n"None")));
    };
    dump.Line(1, "Measured for you: " + IntToString(reference.ram) + " RAM | upload " + SDPQHDesign.Num(reference.upload)
      + "s (constant part " + SDPQHDesign.Num(reference.uploadBase) + "s) | cooldown " + SDPQHDesign.Num(reference.cooldown)
      + "s | duration " + SDPQHDesign.Num(reference.duration) + "s | spread " + IntToString(reference.spread)
      + " within " + SDPQHDesign.Num(reference.spreadRange) + "m");
    let i: Int32 = 0;
    while i < ArraySize(reference.parts) {
      let part: ref<SDPQHRefPart> = reference.parts[i];
      dump.Line(1, "Recreated part " + IntToString(i + 1) + ": payload " + IntToString(part.payload) + " (" + SDPQHDesign.PayloadText(part.payload)
        + ") for " + SDPQHDesign.Num(part.duration) + "s, amount " + SDPQHDesign.Num(part.amount) + ", interval " + SDPQHDesign.Num(part.interval)
        + "s, from " + part.source + ", native look " + (SDPQHLook.Ready(part.look, part.payload) ? "ready" : "none"));
      i += 1;
    };
    i = 0;
    while i < ArraySize(reference.missing) {
      dump.Line(1, "Not recreated: " + reference.missing[i]);
      i += 1;
    };
    dump.Node(reference.action, "Action", 1);
    return dump.text;
  }

  public final func Node(id: TweakDBID, label: String, depth: Int32) -> Void {
    let record: ref<TweakDBRecord> = TweakDBInterface.GetRecord(id);
    if !IsDefined(record) {
      this.Line(depth, label + ": " + SDPQHDump.Name(id) + " (no record)");
      return;
    };
    if ArrayContains(this.seen, id) {
      this.Line(depth, label + ": " + SDPQHDump.Name(id) + " [" + SDPQHDump.Kind(record) + "] (listed above)");
      return;
    };
    ArrayPush(this.seen, id);
    this.Line(depth, label + ": " + SDPQHDump.Name(id) + " [" + SDPQHDump.Kind(record) + "]");
    if depth > 12 {
      this.Line(depth + 1, "(depth limit)");
      return;
    };
    this.Computed(record, depth + 1);
    let children: array<TweakDBID> = SDPQH_DumpFields(this, record, depth + 1);
    let i: Int32 = 0;
    while i < ArraySize(children) {
      this.Node(children[i], "->", depth + 1);
      i += 1;
    };
  }

  // Values as the game computes them for you, next to the raw fields.
  public final func Computed(record: ref<TweakDBRecord>, depth: Int32) -> Void {
    let player: ref<PlayerPuppet> = this.player;
    if !IsDefined(player) { return; };
    let mods: array<wref<StatModifier_Record>>;
    let group: ref<StatModifierGroup_Record> = record as StatModifierGroup_Record;
    if IsDefined(group) {
      group.StatModifiers(mods);
      this.Line(depth, "(computed for you = " + SDPQHDesign.Num(RPGManager.CalculateStatModifiers(mods, player.GetGame(), player,
        Cast<StatsObjectID>(player.GetEntityID()), Cast<StatsObjectID>(player.GetEntityID()))) + ")");
    };
    let attack: ref<Attack_Record> = record as Attack_Record;
    if IsDefined(attack) {
      attack.StatModifiers(mods);
      this.Line(depth, "(computed damage for you = " + SDPQHDesign.Num(RPGManager.CalculateStatModifiers(mods, player.GetGame(), player,
        Cast<StatsObjectID>(player.GetEntityID()), Cast<StatsObjectID>(player.GetEntityID()))) + ")");
    };
  }

  public final func Child(id: TweakDBID, children: script_ref<[TweakDBID]>) -> Void {
    if !TDBID.IsValid(id) || ArrayContains(Deref(children), id) { return; };
    let record: ref<TweakDBRecord> = TweakDBInterface.GetRecord(id);
    if IsDefined(record) && SDPQHDump.Expand(record) { ArrayPush(Deref(children), id); };
  }
}

// ---- With Codeware: every field ---------------------------------------------

// Flat names follow the getters: StatusEffectType -> statusEffectType,
// AIData -> AIData or aiData, VFX -> VFX or vfx. The first that exists wins.
@if(ModuleExists("Codeware"))
public func SDPQH_FlatNames(getter: String) -> array<String> {
  let names: array<String>;
  let first: String = StrLower(StrLeft(getter, 1)) + StrMid(getter, 1);
  ArrayPush(names, first);
  ArrayPush(names, getter);
  let caps: Int32 = 0;
  while caps < StrLen(getter) && NotEquals(StrMid(getter, caps, 1), StrLower(StrMid(getter, caps, 1))) { caps += 1; };
  if caps >= 2 {
    let keep: Int32 = caps < StrLen(getter) ? caps - 1 : caps;
    ArrayPush(names, StrLower(StrLeft(getter, keep)) + StrMid(getter, keep));
  };
  return names;
}

@if(ModuleExists("Codeware"))
public func SDPQH_DumpFields(dump: ref<SDPQHDump>, record: ref<TweakDBRecord>, depth: Int32) -> array<TweakDBID> {
  let children: array<TweakDBID>;
  let getters: array<String>;
  let cls: ref<ReflectionClass> = Reflection.GetClass(record.GetClassName());
  while IsDefined(cls) && NotEquals(cls.GetName(), n"gamedataTweakDBRecord") && NotEquals(cls.GetName(), n"TweakDBRecord") {
    let functions: array<ref<ReflectionMemberFunc>> = cls.GetFunctions();
    let i: Int32 = 0;
    while i < ArraySize(functions) {
      let name: String = NameToString(functions[i].GetName());
      let parameters: array<ref<ReflectionProp>> = functions[i].GetParameters();
      let params: Int32 = ArraySize(parameters);
      let property: String = "";
      if params == 0 && StrBeginsWith(name, "Get") && StrEndsWith(name, "Count") && StrLen(name) > 8 {
        property = StrMid(name, 3, StrLen(name) - 8);
      } else {
        if params == 0 && !StrBeginsWith(name, "Get") && !StrEndsWith(name, "Handle") && !StrEndsWith(name, "Contains") { property = name; };
      };
      if StrLen(property) > 0 && !ArrayContains(getters, property) { ArrayPush(getters, property); };
      i += 1;
    };
    cls = cls.GetParent();
  };
  let n: Int32 = 0;
  while n < ArraySize(getters) {
    let names: array<String> = SDPQH_FlatNames(getters[n]);
    let k: Int32 = 0;
    let done: Bool = false;
    while k < ArraySize(names) && !done {
      let value: Variant = TweakDBInterface.GetFlat(record.GetID() + TDBID.Create("." + names[k]));
      let type: ref<ReflectionType> = Reflection.GetTypeOf(value);
      if IsDefined(type) {
        dump.Line(depth, names[k] + " = " + SDPQH_DumpValue(dump, value, NameToString(type.GetName()), children));
        done = true;
      };
      k += 1;
    };
    n += 1;
  };
  return children;
}

@if(ModuleExists("Codeware"))
public func SDPQH_DumpValue(dump: ref<SDPQHDump>, value: Variant, type: String, children: script_ref<[TweakDBID]>) -> String {
  let text: String = "";
  let i: Int32 = 0;
  if Equals(type, "TweakDBID") {
    let id: TweakDBID = FromVariant<TweakDBID>(value);
    dump.Child(id, children);
    return SDPQHDump.Name(id);
  };
  if Equals(type, "array:TweakDBID") {
    let ids: array<TweakDBID> = FromVariant<array<TweakDBID>>(value);
    while i < ArraySize(ids) {
      dump.Child(ids[i], children);
      text += (i > 0 ? ", " : "") + SDPQHDump.Name(ids[i]);
      i += 1;
    };
    return "[" + text + "]";
  };
  if Equals(type, "Int32") { return IntToString(FromVariant<Int32>(value)); };
  if Equals(type, "Float") { return FloatToString(FromVariant<Float>(value)); };
  if Equals(type, "Bool") { return FromVariant<Bool>(value) ? "true" : "false"; };
  if Equals(type, "String") { return "\"" + FromVariant<String>(value) + "\""; };
  if Equals(type, "CName") { return NameToString(FromVariant<CName>(value)); };
  if Equals(type, "array:CName") {
    let names: array<CName> = FromVariant<array<CName>>(value);
    while i < ArraySize(names) { text += (i > 0 ? ", " : "") + NameToString(names[i]); i += 1; };
    return "[" + text + "]";
  };
  if Equals(type, "array:String") {
    let strings: array<String> = FromVariant<array<String>>(value);
    while i < ArraySize(strings) { text += (i > 0 ? ", " : "") + strings[i]; i += 1; };
    return "[" + text + "]";
  };
  if Equals(type, "array:Float") {
    let floats: array<Float> = FromVariant<array<Float>>(value);
    while i < ArraySize(floats) { text += (i > 0 ? ", " : "") + FloatToString(floats[i]); i += 1; };
    return "[" + text + "]";
  };
  if Equals(type, "array:Int32") {
    let ints: array<Int32> = FromVariant<array<Int32>>(value);
    while i < ArraySize(ints) { text += (i > 0 ? ", " : "") + IntToString(ints[i]); i += 1; };
    return "[" + text + "]";
  };
  if Equals(type, "Vector2") {
    let v2: Vector2 = FromVariant<Vector2>(value);
    return "(" + FloatToString(v2.X) + ", " + FloatToString(v2.Y) + ")";
  };
  if Equals(type, "Vector3") {
    let v3: Vector3 = FromVariant<Vector3>(value);
    return "(" + FloatToString(v3.X) + ", " + FloatToString(v3.Y) + ", " + FloatToString(v3.Z) + ")";
  };
  return "<" + type + ">";
}

@if(ModuleExists("Codeware"))
public func SDPQH_DumpMode() -> String { return "full (Codeware: every field of every record)"; }

// ---- Without Codeware: the record tree and its main values -----------------

@if(!ModuleExists("Codeware"))
public func SDPQH_DumpMode() -> String { return "outline (install Codeware for every field of every record)"; }

@if(!ModuleExists("Codeware"))
public func SDPQH_DumpFields(dump: ref<SDPQHDump>, record: ref<TweakDBRecord>, depth: Int32) -> array<TweakDBID> {
  let children: array<TweakDBID>;
  let i: Int32;
  let action: ref<ObjectAction_Record> = record as ObjectAction_Record;
  if IsDefined(action) {
    dump.Line(depth, "actionName = " + NameToString(action.ActionName()) + " | priority = " + FloatToString(action.Priority()));
    i = 0;
    while i < action.GetCostsCount() { dump.Child(action.GetCostsItem(i).GetID(), children); i += 1; };
    i = 0;
    while i < action.GetActivationTimeCount() { dump.Child(action.GetActivationTimeItem(i).GetID(), children); i += 1; };
    i = 0;
    while i < action.GetStartEffectsCount() { dump.Child(action.GetStartEffectsItem(i).GetID(), children); i += 1; };
    i = 0;
    while i < action.GetCompletionEffectsCount() { dump.Child(action.GetCompletionEffectsItem(i).GetID(), children); i += 1; };
  };
  let effect: ref<ObjectActionEffect_Record> = record as ObjectActionEffect_Record;
  if IsDefined(effect) {
    dump.Line(depth, "recipient = " + (IsDefined(effect.Recipient()) ? SDPQHDump.Name(effect.Recipient().GetID()) : "none"));
    if IsDefined(effect.StatusEffect()) { dump.Child(effect.StatusEffect().GetID(), children); };
    if IsDefined(effect.EffectorToTrigger()) { dump.Child(effect.EffectorToTrigger().GetID(), children); };
  };
  let cost: ref<ObjectActionCost_Record> = record as ObjectActionCost_Record;
  if IsDefined(cost) {
    i = 0;
    while i < cost.GetCostModsCount() { dump.Child(cost.GetCostModsItem(i).GetID(), children); i += 1; };
  };
  let status: ref<StatusEffect_Record> = record as StatusEffect_Record;
  if IsDefined(status) {
    dump.Line(depth, "statusEffectType = " + (IsDefined(status.StatusEffectType()) ? SDPQHDump.Name(status.StatusEffectType().GetID()) : "none"));
    let tags: String = "";
    i = 0;
    while i < status.GetGameplayTagsCount() { tags += (i > 0 ? ", " : "") + NameToString(status.GetGameplayTagsItem(i)); i += 1; };
    dump.Line(depth, "gameplayTags = [" + tags + "]");
    dump.Line(depth, "AIData = " + (IsDefined(status.AIData()) ? SDPQHDump.Name(status.AIData().GetID()) : "none")
      + " | VFX " + IntToString(status.GetVFXCount()) + " | SFX " + IntToString(status.GetSFXCount()));
    if IsDefined(status.Duration()) { dump.Child(status.Duration().GetID(), children); };
    if IsDefined(status.AIData()) { dump.Child(status.AIData().GetID(), children); };
    i = 0;
    while i < status.GetPackagesCount() { dump.Child(status.GetPackagesItem(i).GetID(), children); i += 1; };
  };
  let ai: ref<StatusEffectAIData_Record> = record as StatusEffectAIData_Record;
  if IsDefined(ai) {
    dump.Line(depth, "priority = " + FloatToString(ai.Priority()) + " | behaviourName = " + NameToString(ai.BehaviourName())
      + " | behaviorType = " + (IsDefined(ai.BehaviorType()) ? SDPQHDump.Name(ai.BehaviorType().GetID()) : "none"));
  };
  let group: ref<StatModifierGroup_Record> = record as StatModifierGroup_Record;
  if IsDefined(group) {
    i = 0;
    while i < group.GetStatModifiersCount() { dump.Child(group.GetStatModifiersItem(i).GetID(), children); i += 1; };
  };
  let constant: ref<ConstantStatModifier_Record> = record as ConstantStatModifier_Record;
  if IsDefined(constant) {
    dump.Line(depth, "statType = " + (IsDefined(constant.StatType()) ? SDPQHDump.Name(constant.StatType().GetID()) : "none")
      + " | modifierType = " + NameToString(constant.ModifierType()) + " | value = " + FloatToString(constant.Value()));
  };
  let package: ref<GameplayLogicPackage_Record> = record as GameplayLogicPackage_Record;
  if IsDefined(package) {
    i = 0;
    while i < package.GetStatsCount() { dump.Child(package.GetStatsItem(i).GetID(), children); i += 1; };
    i = 0;
    while i < package.GetEffectorsCount() { dump.Child(package.GetEffectorsItem(i).GetID(), children); i += 1; };
  };
  let effector: ref<Effector_Record> = record as Effector_Record;
  if IsDefined(effector) {
    dump.Line(depth, "effectorClassName = " + NameToString(effector.EffectorClassName()));
    let single: ref<TriggerAttackEffector_Record> = record as TriggerAttackEffector_Record;
    let continuous: ref<ContinuousAttackEffector_Record> = record as ContinuousAttackEffector_Record;
    if IsDefined(continuous) { dump.Line(depth, "delayTime = " + FloatToString(continuous.DelayTime())); };
    if IsDefined(single) && IsDefined(single.AttackRecord()) { dump.Child(single.AttackRecord().GetID(), children); };
    if IsDefined(continuous) && IsDefined(continuous.AttackRecord()) { dump.Child(continuous.AttackRecord().GetID(), children); };
  };
  let attack: ref<Attack_Record> = record as Attack_Record;
  if IsDefined(attack) {
    let flags: String = "";
    i = 0;
    while i < attack.GetHitFlagsCount() { flags += (i > 0 ? ", " : "") + attack.GetHitFlagsItem(i); i += 1; };
    dump.Line(depth, "damageType = " + (IsDefined(attack.DamageType()) ? SDPQHDump.Name(attack.DamageType().GetID()) : "none")
      + " | hitFlags = [" + flags + "]");
    i = 0;
    while i < attack.GetStatModifiersCount() { dump.Child(attack.GetStatModifiersItem(i).GetID(), children); i += 1; };
  };
  return children;
}

// ---- API ----------------------------------------------------------------------

@addMethod(PlayerPuppet)
public final func SDPQH_DumpHeader() -> String {
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.GetGame());
  let id: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());
  return "SDP native quickhack dump | build " + IntToString(this.SDP_PrototypeVersion()) + " | " + SDPQH_DumpMode()
    + "\nPlayer level " + SDPQHDesign.Num(stats.GetStatValue(id, gamedataStatType.Level))
    + " | Intelligence " + SDPQHDesign.Num(stats.GetStatValue(id, gamedataStatType.Intelligence))
    + " | max RAM " + SDPQHDesign.Num(stats.GetStatValue(id, gamedataStatType.Memory))
    + " | " + IntToString(this.SDPQH_RefCount()) + " programs\n\n";
}

@addMethod(PlayerPuppet)
public final func SDPQH_RefDump(index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  return IsDefined(reference) ? SDPQHDump.Program(this, reference) : "";
}
