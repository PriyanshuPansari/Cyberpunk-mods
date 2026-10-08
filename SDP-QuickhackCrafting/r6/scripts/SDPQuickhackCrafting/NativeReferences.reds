// Native quickhack references. Every native puppet quickhack program, at every
// tier the game defines, is read from TweakDB at runtime and rebuilt from our
// primitives with the native numbers: RAM, upload, cooldown, effect durations,
// damage per hit, pulse interval and spread. Compiled into a program slot, the
// recreation runs through the same chip, rule engine and primitives as a
// designed program, so it can be uploaded next to the native program and the
// two compared (ComparisonMeter.reds). Numbers are computed the way the
// program tooltip computes them, from the player's current stats.
//
// Build 14: each native status becomes its own part and wears its full native
// look (SDPQHLook): AI reaction, animation overrides, effects and every
// non-damage mechanic. Statuses with no primitive of ours (Ping, Memory Wipe,
// Suicide, System Collapse...) become native-behavior parts. Effectors that
// only fire under a condition are no longer recreated as unconditional damage.
// See design/NATIVE_RECREATION.md.
module SkillDrivenProgression

// One native effect rebuilt as one of our primitives.
public class SDPQHRefPart extends IScriptable {
  public let payload: Int32;
  public let duration: Float;
  public let amount: Float;
  // Seconds between damage pulses; 0 = a single hit.
  public let interval: Float;
  public let source: String;
  // The native status this part wears (SDPQHLook): its AI reaction, animation,
  // effects and non-damage mechanics. Each native status is worn by one part
  // only; a second part from the same status (damage on a control status)
  // runs as our plain primitive, so the status's packages never apply twice.
  public let look: TweakDBID;
  // The native attack whose damage type, attack type and hit flags our pulses
  // carry (SDPQHLook.AttackID). Invalid for parts that deal no damage.
  public let attack: TweakDBID;
  // The damage comes from a stackable package: each native stack adds a pulse's worth.
  public let stacks: Bool;
  // A part the native applies only when its completion effector's
  // prerequisite passes (Cyberware Malfunction's stack ladder, Short Circuit's
  // weakspot combo): checked per target on upload (SDPQHConditions).
  public let when: TweakDBID;
  // Checked after the upload's other statuses land, as in the native completion order.
  public let after: Bool;

  public final func Conditional() -> Bool { return TDBID.IsValid(this.when); }

  public final func Met(player: ref<PlayerPuppet>, target: ref<GameObject>) -> Bool {
    return !this.Conditional() || SDPQHConditions.Met(player, target, this.when);
  }

  // The part as an on-upload rule, with its look and attack when they exist.
  public final func Rule() -> ref<SDPPrototypeRule> {
    let rule: ref<SDPPrototypeRule> = SDPPrototypeRuntime.Rule(4, this.payload, 0);
    rule.duration = this.duration;
    rule.amount = this.amount;
    rule.interval = this.interval;
    rule.look = SDPQHLook.Ready(this.look) ? this.look : t"";
    rule.attack = SDPQHLook.AttackReady(this.attack) ? this.attack : t"";
    rule.stacks = this.stacks;
    return rule;
  }

  public final func Text() -> String {
    let text: String = SDPQHDesign.RuleSentence(4, this.payload, 0, this.duration, this.amount, this.interval);
    if this.Conditional() { text = "Only when " + SDPQHConditions.Text(this.when) + ": " + text; };
    if SDPQHLook.Ready(this.look) {
      text += " Native look: " + SDPQHNativeRef.Short(this.look) + ".";
    } else {
      text += (TDBID.IsValid(this.look) ? " Native look missing: " + SDPQHNativeRef.Short(this.look) + "." : " Our status (" + this.source + " is worn by another part).");
    };
    if SDPQHLook.AttackReady(this.attack) { text += " Native hit: " + SDPQHNativeRef.Short(this.attack) + "."; };
    return text;
  }
}

public class SDPQHNativeRef extends IScriptable {
  public let item: TweakDBID;
  public let action: TweakDBID;
  public let name: String;
  public let tier: Int32;
  public let plus: Int32;
  // Base RAM as the tooltip shows it (all cost records).
  public let ram: Int32;
  // The constant part of the first cost record. The chip takes it; the native's
  // other cost records (tier increases) are added to the chip as they are.
  public let ramBase: Float;
  public let upload: Float;
  // Additive constant part of the upload time; the chip's own constant takes it.
  public let uploadBase: Float;
  public let cooldown: Float;
  public let duration: Float;
  public let spread: Int32;
  public let spreadRange: Float;
  // The upload spread also rolls the player's Overclock spread chance.
  public let spreadOverclock: Bool;
  public let parts: array<ref<SDPQHRefPart>>;
  // Native effects with no primitive yet.
  public let missing: array<String>;
  // Native damage as the program tooltip computes it.
  public let damage: array<String>;
  // Native bugs the recreation does not reproduce.
  public let fixes: array<String>;
  // Conditional damage a worn look keeps with its native condition (the
  // Cyberware Malfunction explosion at 8 stacks): native, not ours.
  public let kept: array<String>;
  // Completion effectors the chip runs from script on every recipient, after
  // the statuses land (SDPQHPorts): the police notice, the crime score,
  // duration changes, System Collapse's reveal bar, breach destruction.
  public let ports: array<TweakDBID>;
  // Native statuses already made into parts.
  public let statuses: array<TweakDBID>;
  // The condition the parts being added get (a conditional completion effector).
  public let when: TweakDBID;

  public final static func FromItem(player: ref<PlayerPuppet>, item: TweakDBID) -> ref<SDPQHNativeRef> {
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(item);
    if !IsDefined(player) || !IsDefined(record) || !IsDefined(record.ItemType())
      || NotEquals(record.ItemType().Type(), gamedataItemType.Prt_Program) || SDPQHDesign.SlotForItem(item) > 0 {
      return null;
    };
    let action: ref<ObjectAction_Record> = SDPQHNativeRef.PuppetAction(record);
    if !IsDefined(action) { return null; };
    let reference: ref<SDPQHNativeRef> = new SDPQHNativeRef();
    reference.item = item;
    reference.action = action.GetID();
    reference.name = SDPQHNativeRef.DisplayName(record, action);
    if IsDefined(record.Quality()) {
      reference.tier = SDPQHNativeRef.TierOf(record.Quality().Type());
      reference.plus = SDPQHNativeRef.PlusOf(record.Quality().Type());
    };
    reference.Measure(player, action);
    return reference;
  }

  // The program's puppet quickhack, highest priority first (as the tooltip picks it).
  public final static func PuppetAction(record: ref<Item_Record>) -> ref<ObjectAction_Record> {
    let actions: array<wref<ObjectAction_Record>>;
    record.ObjectActions(actions);
    let best: ref<ObjectAction_Record>;
    let i: Int32 = 0;
    while i < ArraySize(actions) {
      if IsDefined(actions[i]) && IsDefined(actions[i].ObjectActionType())
        && Equals(actions[i].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack)
        && (!IsDefined(best) || actions[i].Priority() > best.Priority()) {
        best = actions[i];
      };
      i += 1;
    };
    return best;
  }

  public final static func DisplayName(record: ref<Item_Record>, action: ref<ObjectAction_Record>) -> String {
    let name: String = GetLocalizedItemNameByCName(record.DisplayName());
    if StrLen(name) == 0 && IsDefined(action.ObjectActionUI()) {
      name = GetLocalizedText(LocKeyToString(action.ObjectActionUI().Caption()));
    };
    if StrLen(name) == 0 { name = SDPQHNativeRef.Short(record.GetID()); };
    return name;
  }

  public final static func TierOf(quality: gamedataQuality) -> Int32 {
    if Equals(quality, gamedataQuality.Uncommon) || Equals(quality, gamedataQuality.UncommonPlus) { return 2; };
    if Equals(quality, gamedataQuality.Rare) || Equals(quality, gamedataQuality.RarePlus) { return 3; };
    if Equals(quality, gamedataQuality.Epic) || Equals(quality, gamedataQuality.EpicPlus) { return 4; };
    if Equals(quality, gamedataQuality.Legendary) || Equals(quality, gamedataQuality.LegendaryPlus)
      || Equals(quality, gamedataQuality.LegendaryPlusPlus) || Equals(quality, gamedataQuality.Iconic) { return 5; };
    return 1;
  }

  public final static func PlusOf(quality: gamedataQuality) -> Int32 {
    if Equals(quality, gamedataQuality.LegendaryPlusPlus) { return 2; };
    if Equals(quality, gamedataQuality.CommonPlus) || Equals(quality, gamedataQuality.UncommonPlus) || Equals(quality, gamedataQuality.RarePlus)
      || Equals(quality, gamedataQuality.EpicPlus) || Equals(quality, gamedataQuality.LegendaryPlus) { return 1; };
    return 0;
  }

  // Record name without its package: "BaseStatusEffect.OverheatLevel3" -> "OverheatLevel3".
  public final static func Short(id: TweakDBID) -> String {
    let text: String = TDBID.ToStringDEBUG(id);
    let tail: String = StrAfterFirst(text, ".");
    return StrLen(tail) > 0 ? tail : text;
  }

  public final static func MaxParts() -> Int32 { return 6; }

  // Statuses every quickhack applies for bookkeeping; the chip applies them itself.
  public final static func Bookkeeping(status: TweakDBID) -> Bool {
    return status == t"BaseStatusEffect.WasQuickHacked" || status == t"BaseStatusEffect.QuickHackUploaded";
  }

  // Effects on the instigator are buffs for V, not part of the hack's effect.
  public final static func OnTarget(effect: wref<ObjectActionEffect_Record>) -> Bool {
    return !IsDefined(effect.Recipient()) || Equals(effect.Recipient().Type(), gamedataObjectActionReference.Target);
  }

  // Which of our control primitives a native status is. Its type decides; a
  // misc status is matched by the gameplay tags the game's scripts react to.
  // A status whose type is its own AI behavior (Suicide, System Collapse,
  // Memory Wipe, Ping...) is none of them, even when it carries a Blind tag:
  // it becomes a native-behavior part. 0 = none.
  public final static func ControlPayload(status: ref<StatusEffect_Record>) -> Int32 {
    if !IsDefined(status.StatusEffectType()) { return 0; };
    let kind: gamedataStatusEffectType = status.StatusEffectType().Type();
    if Equals(kind, gamedataStatusEffectType.Blind) { return status.GameplayTagsContains(n"MemoryWipe") ? 0 : 1; };
    if Equals(kind, gamedataStatusEffectType.QuickHackStaggerLocomotion) { return 9; };
    if Equals(kind, gamedataStatusEffectType.Jam) { return 10; };
    if Equals(kind, gamedataStatusEffectType.CommsNoise) { return 11; };
    if Equals(kind, gamedataStatusEffectType.QuickHackStaggerCyberware) { return 12; };
    if Equals(kind, gamedataStatusEffectType.Stunned) { return 4; };
    if NotEquals(kind, gamedataStatusEffectType.Misc) { return 0; };
    if status.GameplayTagsContains(n"QuickHackBlind") || status.GameplayTagsContains(n"Blind") { return 1; };
    if status.GameplayTagsContains(n"LocomotionMalfunction") { return 9; };
    if status.GameplayTagsContains(n"JamWeapon") || status.GameplayTagsContains(n"WeaponJam") { return 10; };
    if status.GameplayTagsContains(n"CommsNoiseJam") || status.GameplayTagsContains(n"CommsNoise") || status.GameplayTagsContains(n"Deaf") { return 11; };
    if status.GameplayTagsContains(n"CyberwareMalfunction") { return 12; };
    return 0;
  }

  public final static func DamagePayload(attack: ref<Attack_Record>) -> Int32 {
    if !IsDefined(attack.DamageType()) { return 0; };
    let kind: gamedataDamageType = attack.DamageType().DamageType();
    if Equals(kind, gamedataDamageType.Thermal) { return 2; };
    if Equals(kind, gamedataDamageType.Electric) { return 3; };
    if Equals(kind, gamedataDamageType.Chemical) { return 7; };
    if Equals(kind, gamedataDamageType.Physical) { return 8; };
    return 0;
  }

  // Empty when the effector always fires, otherwise its condition in words.
  public final static func Condition(effector: ref<Effector_Record>) -> String {
    let prereq: ref<IPrereq_Record> = effector.PrereqRecord();
    if !IsDefined(prereq) || prereq.GetID() == t"Prereqs.AlwaysTruePrereq" || Equals(prereq.PrereqClassName(), n"AlwaysTruePrereq") { return ""; };
    let stat: ref<StatPrereq_Record> = prereq as StatPrereq_Record;
    if IsDefined(stat) {
      return (Equals(stat.ObjectToCheck(), n"Player") ? "your " : "") + NameToString(stat.StatType()) + " "
        + SDPQHNativeRef.Comparison(stat.ComparisonType()) + " " + SDPQHDesign.Num(stat.ValueToCheck());
    };
    let status: ref<StatusEffectPrereq_Record> = prereq as StatusEffectPrereq_Record;
    if IsDefined(status) {
      return (status.Invert() ? "without " : "with ")
        + (IsDefined(status.StatusEffect()) ? SDPQHNativeRef.Short(status.StatusEffect().GetID()) : NameToString(status.TagToCheck()));
    };
    return NameToString(prereq.PrereqClassName());
  }

  public final static func Comparison(kind: CName) -> String {
    if Equals(kind, n"Less") { return "<"; };
    if Equals(kind, n"LessOrEqual") { return "<="; };
    if Equals(kind, n"Greater") { return ">"; };
    if Equals(kind, n"GreaterOrEqual") { return ">="; };
    if Equals(kind, n"NotEqual") { return "!="; };
    return "=";
  }

  // True when a modifier list reads `stat` (a combined modifier's reference stat).
  public final static func ReadsStat(mods: array<wref<StatModifier_Record>>, stat: gamedataStatType) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(mods) {
      let combined: ref<CombinedStatModifier_Record> = mods[i] as CombinedStatModifier_Record;
      if IsDefined(combined) && IsDefined(combined.RefStat()) && Equals(combined.RefStat().StatType(), stat) { return true; };
      i += 1;
    };
    return false;
  }

  // Base duration as the game applies it (NPCPuppet.OnQuickHackEffectApplied),
  // plus Overheat's package bonus as the program tooltip adds it. A status
  // without a fixed duration is recreated at the 600 s maximum.
  public final static func StatusDuration(player: ref<PlayerPuppet>, status: ref<StatusEffect_Record>) -> Float {
    if !IsDefined(status.Duration()) { return 600.00; };
    let mods: array<wref<StatModifier_Record>>;
    status.Duration().StatModifiers(mods);
    let value: Float = RPGManager.CalculateStatModifiers(mods, player.GetGame(), player, Cast<StatsObjectID>(player.GetEntityID()), Cast<StatsObjectID>(player.GetEntityID()));
    if status.GameplayTagsContains(n"Overheat") {
      let packages: array<wref<GameplayLogicPackage_Record>>;
      status.Packages(packages);
      let i: Int32 = 0;
      while i < ArraySize(packages) {
        let stats: array<wref<StatModifier_Record>>;
        packages[i].Stats(stats);
        let j: Int32 = 0;
        while j < ArraySize(stats) {
          let constant: ref<ConstantStatModifier_Record> = stats[j] as ConstantStatModifier_Record;
          if IsDefined(constant) && IsDefined(constant.StatType()) && Equals(constant.StatType().StatType(), gamedataStatType.OverheatDurationIncrease) {
            value += constant.Value();
          };
          j += 1;
        };
        i += 1;
      };
    };
    return value > 0.00 ? MinF(value, 600.00) : 600.00;
  }

  // Completion effects every program chip keeps from Reboot Optics: the
  // generic bookkeeping, hacked-armor reduction and ping refresh
  // (CustomProgramRecords.reds). A recreation runs them through the chip.
  public final static func ChipKeeps() -> array<TweakDBID> {
    let ids: array<TweakDBID>;
    let chip: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(SDPQHDesign.ActionRecord(1));
    if IsDefined(chip) {
      let i: Int32 = 0;
      while i < chip.GetCompletionEffectsCount() {
        ArrayPush(ids, chip.GetCompletionEffectsItem(i).GetID());
        i += 1;
      };
    };
    return ids;
  }

  public final func Measure(player: ref<PlayerPuppet>, action: ref<ObjectAction_Record>) -> Void {
    let game: GameInstance = player.GetGame();
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let dummy: EntityID;
    this.ram = BaseScriptableAction.GetBaseCostStatic(player, action);
    this.ramBase = Cast<Float>(this.ram);
    if action.GetCostsCount() > 0 {
      let costMods: array<wref<StatModifier_Record>>;
      action.GetCostsItem(0).CostMods(costMods);
      let costConstants: array<wref<StatModifier_Record>>;
      let c: Int32 = 0;
      while c < ArraySize(costMods) {
        if SDPQHRecordBuilder.ConstantAdditive(costMods[c]) { ArrayPush(costConstants, costMods[c]); };
        c += 1;
      };
      this.ramBase = RPGManager.CalculateStatModifiers(costConstants, game, player, Cast<StatsObjectID>(dummy), playerID);
    };

    let uploadMods: array<wref<StatModifier_Record>>;
    action.ActivationTime(uploadMods);
    this.upload = RPGManager.CalculateStatModifiers(uploadMods, game, player, Cast<StatsObjectID>(dummy), playerID);
    let constants: array<wref<StatModifier_Record>>;
    let i: Int32 = 0;
    while i < ArraySize(uploadMods) {
      if SDPQHRecordBuilder.ConstantAdditive(uploadMods[i]) { ArrayPush(constants, uploadMods[i]); };
      i += 1;
    };
    this.uploadBase = RPGManager.CalculateStatModifiers(constants, game, player, Cast<StatsObjectID>(dummy), playerID);

    // Start effects: the program's own cooldown (without the shared cooldown
    // group) and its upload spread, which the game prepares when the upload starts.
    let shared: array<wref<StatModifier_Record>>;
    let group: ref<StatModifierGroup_Record> = TweakDBInterface.GetStatModifierGroupRecord(t"BaseStatusEffect.QuickHackCooldownDuration");
    if IsDefined(group) { group.StatModifiers(shared); };
    let starts: array<wref<ObjectActionEffect_Record>>;
    action.StartEffects(starts);
    i = 0;
    while i < ArraySize(starts) {
      let status: wref<StatusEffect_Record> = starts[i].StatusEffect();
      if this.cooldown == 0.00 && IsDefined(status) && IsDefined(status.StatusEffectType()) && IsDefined(status.Duration())
        && Equals(status.StatusEffectType().Type(), gamedataStatusEffectType.PlayerCooldown) {
        let mods: array<wref<StatModifier_Record>>;
        status.Duration().StatModifiers(mods);
        let own: array<wref<StatModifier_Record>>;
        let j: Int32 = 0;
        while j < ArraySize(mods) {
          if !ArrayContains(shared, mods[j]) { ArrayPush(own, mods[j]); };
          j += 1;
        };
        this.cooldown = RPGManager.CalculateStatModifiers(own, game, player, Cast<StatsObjectID>(dummy), playerID);
      };
      let trigger: ref<Effector_Record> = starts[i].EffectorToTrigger();
      let spreader: ref<SpreadInitEffector_Record> = trigger as SpreadInitEffector_Record;
      if IsDefined(spreader) { this.ReadSpread(player, spreader); };
      i += 1;
    };

    let kept: array<TweakDBID> = SDPQHNativeRef.ChipKeeps();
    let effects: array<wref<ObjectActionEffect_Record>>;
    action.CompletionEffects(effects);
    i = 0;
    while i < ArraySize(effects) {
      let effect: wref<ObjectActionEffect_Record> = effects[i];
      if SDPQHNativeRef.OnTarget(effect) && !ArrayContains(kept, effect.GetID()) {
        let applied: ref<StatusEffect_Record> = effect.StatusEffect();
        let effector: ref<Effector_Record> = effect.EffectorToTrigger();
        if IsDefined(applied) {
          if !SDPQHNativeRef.Bookkeeping(applied.GetID()) { this.AddStatus(player, applied); };
        } else {
          if IsDefined(effector) { this.CompletionEffector(player, effector); };
        };
      };
      i += 1;
    };
    this.spread = Min(this.spread, SDPQHDesign.MaxReferenceSpread());
  }

  // A completion effector on the target that is not a status.
  public final func CompletionEffector(player: ref<PlayerPuppet>, effector: ref<Effector_Record>) -> Void {
    let name: CName = effector.EffectorClassName();
    // Our spread installs the same program on each recipient: the native
    // spread step has nothing left to do.
    if Equals(name, n"SpreadEffector") { return; };
    let condition: String = SDPQHNativeRef.Condition(effector);
    let prereq: ref<IPrereq_Record> = effector.PrereqRecord();
    let checkable: Bool = StrLen(condition) == 0 || SDPQHConditions.Supported(prereq);
    // Effectors the chip runs itself, as their game class does (SDPQHPorts).
    if SDPQHPorts.Ported(name) && checkable {
      let status: ref<StatusEffect_Record> = TweakDBInterface.GetStatusEffectRecord(SDPQHPorts.AppliedStatus(name));
      if IsDefined(status) {
        this.AddStatus(player, status);
        ArrayPush(this.missing, SDPQHPorts.Gap(name));
      } else {
        ArrayPush(this.ports, effector.GetID());
      };
      return;
    };
    let spreader: ref<SpreadInitEffector_Record> = effector as SpreadInitEffector_Record;
    if IsDefined(spreader) {
      // Spread prepared on completion is not upload spread (Reboot Optics T5++
      // spreads to a nearby enemy when the target dies).
      ArrayPush(this.missing, "spread on completion"
        + (IsDefined(spreader.ObjectAction()) ? " (" + SDPQHNativeRef.Short(spreader.ObjectAction().GetID()) + ")" : ""));
      return;
    };
    let applier: ref<ApplyStatusEffectEffector_Record> = effector as ApplyStatusEffectEffector_Record;
    if IsDefined(applier) && IsDefined(applier.StatusEffect()) {
      if StrLen(condition) == 0 {
        this.AddStatus(player, applier.StatusEffect());
      } else {
        if checkable {
          // Checked per target at upload, as the native effector checks it.
          this.when = prereq.GetID();
          this.AddStatus(player, applier.StatusEffect());
          this.when = t"";
        } else {
          ArrayPush(this.missing, SDPQHNativeRef.Short(applier.StatusEffect().GetID()) + " (only when " + condition + ")");
        };
      };
      return;
    };
    if this.DamageEffector(player, effector, 0.00, NameToString(name), t"", false, false) > 0 { return; };
    ArrayPush(this.missing, NameToString(name) + (StrLen(condition) > 0 ? " (only when " + condition + ")" : ""));
  }

  public final func AddStatus(player: ref<PlayerPuppet>, status: ref<StatusEffect_Record>) -> Void {
    if ArrayContains(this.statuses, status.GetID()) { return; };
    ArrayPush(this.statuses, status.GetID());
    let source: String = SDPQHNativeRef.Short(status.GetID());
    let length: Float = SDPQHNativeRef.StatusDuration(player, status);
    if length < 600.00 { this.duration = MaxF(this.duration, length); };
    // The first part made from a status wears its look.
    let look: TweakDBID = status.GetID();
    let control: Int32 = SDPQHNativeRef.ControlPayload(status);
    if control > 0 && this.AddPart(control, length, 0.00, 1.00, source, look, t"") { look = t""; };
    let packages: array<wref<GameplayLogicPackage_Record>>;
    status.Packages(packages);
    let i: Int32 = 0;
    while i < ArraySize(packages) {
      let effectors: array<wref<Effector_Record>>;
      packages[i].Effectors(effectors);
      let j: Int32 = 0;
      while j < ArraySize(effectors) {
        if this.DamageEffector(player, effectors[j], length, source, look, packages[i].Stackable(), true) == 1 { look = t""; };
        j += 1;
      };
      i += 1;
    };
    // No primitive of ours fits: the part is the status's own behavior, its
    // AI, animation, effects and the tags the game's scripts react to (Short
    // Circuit's WeakspotDestruction). The bookkeeping statuses never get here.
    if TDBID.IsValid(look) { this.AddPart(13, length, 0.00, 1.00, source, look, t""); };
  }

  // A damage effector: 1 when it became a part, 2 when it fires only under a
  // condition, 0 when it is not typed damage. A conditional one in a status's
  // package stays in that status's look with its native condition; one
  // directly on the action is listed as not recreated. `stackable`: its
  // package applies once per stack.
  public final func DamageEffector(player: ref<PlayerPuppet>, effector: ref<Effector_Record>, length: Float, source: String, look: TweakDBID, stackable: Bool, inLook: Bool) -> Int32 {
    let attack: ref<Attack_Record> = SDPQHLook.AttackOf(effector);
    if !SDPQHLook.Damage(attack) { return 0; };
    let payload: Int32 = SDPQHNativeRef.DamagePayload(attack);
    let condition: String = SDPQHNativeRef.Condition(effector);
    if StrLen(condition) > 0 {
      let text: String = SDPQHNativeRef.Short(attack.GetID()) + " " + SDPQHDesign.DamageTypeText(payload) + " damage (only when " + condition + ")";
      if inLook { ArrayPush(this.kept, text); } else { ArrayPush(this.missing, text); };
      return 2;
    };
    let continuous: ref<ContinuousAttackEffector_Record> = effector as ContinuousAttackEffector_Record;
    let interval: Float = 0.00;
    if IsDefined(continuous) { interval = continuous.DelayTime() > 0.00 ? continuous.DelayTime() : 1.00; };
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let mods: array<wref<StatModifier_Record>>;
    attack.StatModifiers(mods);
    // As InventoryDataManagerV2.ProcessQuickhackEffects computes the tooltip value.
    let nativeAmount: Float = MaxF(1.00, RPGManager.CalculateStatModifiers(mods, player.GetGame(), player, playerID, playerID));
    let amount: Float = nativeAmount;
    // Native bug (Quickhack Damage Fix): the stat-screen quickhack damage bonus
    // reaches only attacks whose record reads it (Synapse Burnout). Every
    // recreated damage hack gets it.
    if !SDPQHNativeRef.ReadsStat(mods, gamedataStatType.BonusQuickHackDamage) {
      let bonus: Float = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(playerID, gamedataStatType.BonusQuickHackDamage);
      if bonus > 0.00 {
        amount *= 1.00 + bonus;
        this.Fix("quickhack damage bonus applies to " + SDPQHNativeRef.Short(attack.GetID()) + " (+" + SDPQHDesign.Num(bonus * 100.00) + "%)");
      };
    };
    let pulseLength: Float = length >= 600.00 ? MaxF(interval, 0.10) : length;
    ArrayPush(this.damage, SDPQHDesign.Num(nativeAmount) + " " + SDPQHDesign.DamageTypeText(payload)
      + (interval > 0.00 ? " every " + SDPQHDesign.Num(interval) + "s for " + SDPQHDesign.Num(pulseLength) + "s" : " in one hit"));
    // A single hit keeps its native status for its native length: that status
    // carries the hit's reaction (an electrocution, for example).
    let partLength: Float = interval > 0.00 ? pulseLength : (length >= 600.00 ? 1.00 : MaxF(0.10, length));
    if !this.AddPart(payload, partLength, amount, interval, source, look, attack.GetID()) { return 2; };
    this.parts[ArraySize(this.parts) - 1].stacks = stackable && interval > 0.00;
    return 1;
  }

  // As SpreadInitEffector.ActionOn counts jumps and range. A count of 0 spreads
  // only when the Overclock roll succeeds; that roll happens at upload.
  public final func ReadSpread(player: ref<PlayerPuppet>, record: ref<SpreadInitEffector_Record>) -> Void {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
    let id: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let count: Int32 = record.SpreadCount();
    if count < 0 {
      count = Cast<Int32>(stats.GetStatValue(id, gamedataStatType.QuickHackSpreadNumber));
      let actionName: String = IsDefined(record.ObjectAction()) ? NameToString(record.ObjectAction().ActionName()) : "";
      if StrEndsWith(actionName, "Blind") { count += Cast<Int32>(stats.GetStatValue(id, gamedataStatType.QuickHackBlindSpreadNumber)); };
      if StrEndsWith(actionName, "Contagion") { count += Cast<Int32>(stats.GetStatValue(id, gamedataStatType.QuickHackContagionSpreadNumber)); };
      if StrEndsWith(actionName, "BlackWall") { count += Cast<Int32>(stats.GetStatValue(id, gamedataStatType.QuickHackBlackWallSpreadNumber)); };
    };
    let range: Float = Cast<Float>(record.SpreadDistance());
    if range < 0.00 { range = stats.GetStatValue(id, gamedataStatType.QuickHackSpreadDistance); };
    range += stats.GetStatValue(id, gamedataStatType.QuickHackSpreadDistanceIncrease);
    count += record.BonusJumps();
    if range <= 0.00 { return; };
    let overclock: Bool = TweakDBInterface.GetBool(record.GetID() + t".applyOverclock", true);
    if count > this.spread || (count == this.spread && overclock && !this.spreadOverclock) {
      this.spread = Max(0, count);
      this.spreadRange = range;
      this.spreadOverclock = overclock;
    };
  }

  // Extra spread targets from the Overclock roll, as SpreadInitEffector rolls it.
  public final func OverclockSpread(player: ref<PlayerPuppet>) -> Int32 {
    if !this.spreadOverclock { return 0; };
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(player.GetGame());
    let id: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    if RandRangeF(0.00, 1.00) > stats.GetStatValue(id, gamedataStatType.OverclockSpreadChance) { return 0; };
    return Max(0, Cast<Int32>(stats.GetStatValue(id, gamedataStatType.QuickHackOverclockSpreadNumber)));
  }

  public final func AddPart(payload: Int32, length: Float, amount: Float, interval: Float, source: String, look: TweakDBID, attack: TweakDBID) -> Bool {
    if ArraySize(this.parts) >= SDPQHNativeRef.MaxParts() {
      ArrayPush(this.missing, SDPQHDesign.PayloadText(payload) + " (" + source + "; too many effects)");
      return false;
    };
    let part: ref<SDPQHRefPart> = new SDPQHRefPart();
    part.payload = payload;
    part.duration = length;
    part.amount = amount;
    part.interval = interval;
    part.source = source;
    part.look = look;
    part.attack = attack;
    part.when = this.when;
    // A condition met after the upload's own statuses landed reads them (Short
    // Circuit's combo); one met before reads what was there (Cyberware
    // Malfunction's ladder). Native completion order decides.
    part.after = TDBID.IsValid(this.when) && this.Supported();
    ArrayPush(this.parts, part);
    return true;
  }

  // Applies the conditional parts of one phase (before or after the upload's
  // statuses) whose condition `target` meets.
  public final func RunConditional(player: ref<PlayerPuppet>, runtime: ref<SDPPrototypeRuntime>, target: ref<NPCPuppet>, after: Bool) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.parts) {
      if this.parts[i].Conditional() && Equals(this.parts[i].after, after) && this.parts[i].Met(player, target) {
        runtime.Apply(player, target, this.parts[i].Rule());
      };
      i += 1;
    };
  }

  public final func Fix(text: String) -> Void {
    if !ArrayContains(this.fixes, text) { ArrayPush(this.fixes, text); };
  }

  // At least one part applies on every upload.
  public final func Supported() -> Bool { return IsDefined(this.Unconditional(0)); }

  // The `index`th part that applies on every upload, or null.
  public final func Unconditional(index: Int32) -> ref<SDPQHRefPart> {
    let i: Int32 = 0;
    while i < ArraySize(this.parts) {
      if !this.parts[i].Conditional() {
        if index == 0 { return this.parts[i]; };
        index -= 1;
      };
      i += 1;
    };
    return null;
  }

  // Every native effect recreated or worn as a native look.
  public final func Complete() -> Bool { return this.Supported() && ArraySize(this.missing) == 0; }

  // One on-upload rule per part that applies on every upload, in order: the
  // first two are the program's rules. Conditional parts are checked per
  // target by SDPQH_Execute.
  public final func Rules() -> array<ref<SDPPrototypeRule>> {
    let rules: array<ref<SDPPrototypeRule>>;
    let i: Int32 = 0;
    while i < ArraySize(this.parts) {
      if !this.parts[i].Conditional() { ArrayPush(rules, this.parts[i].Rule()); };
      i += 1;
    };
    return rules;
  }

  public final func TierText() -> String {
    return "T" + IntToString(this.tier) + (this.plus >= 2 ? "++" : (this.plus == 1 ? "+" : ""));
  }

  public final func Title() -> String { return this.name + " " + this.TierText(); }

  public final func Coverage() -> String {
    if !this.Supported() { return "native only"; };
    return this.Complete() ? "recreated" : "partly recreated";
  }

  // The first two unconditional parts as a slot spec (both fire on upload with
  // the native values). Further parts run alongside them (CustomPrograms.reds).
  public final func Spec() -> ref<SDPQHSpec> {
    let spec: ref<SDPQHSpec> = SDPQHNativeRef.SpecOf(this.Title(), this.Unconditional(0), this.Unconditional(1), this.spread);
    spec.Set(15, 1.00);
    return spec;
  }

  public final static func SpecOf(title: String, a: ref<SDPQHRefPart>, b: ref<SDPQHRefPart>, spread: Int32) -> ref<SDPQHSpec> {
    return SDPQHSpec.Make(StrLeft(title, SDPQHDesign.MaxName()),
      IsDefined(a) ? 4 : 0, IsDefined(a) ? a.payload : 0, 0, IsDefined(a) ? a.duration : 4.00, IsDefined(a) ? a.amount : 25.00, IsDefined(a) ? a.interval : 1.00,
      IsDefined(b) ? 4 : 0, IsDefined(b) ? b.payload : 0, 0, IsDefined(b) ? b.duration : 4.00, IsDefined(b) ? b.amount : 25.00, IsDefined(b) ? b.interval : 1.00,
      1, spread);
  }

  // The nearest design the Quickhack Designer can make (2/4/8 s, 10/25/50
  // damage, 0.5/1/2 s pulses, up to 3 spread) from the first two parts that
  // have a designed primitive: the craftable approximation. Null when none has.
  public final func Approximation() -> ref<SDPQHSpec> {
    let picked: array<ref<SDPQHRefPart>>;
    let i: Int32 = 0;
    while i < ArraySize(this.parts) && ArraySize(picked) < 2 {
      if SDPQHDesign.ProgramPayload(this.parts[i].payload) && !this.parts[i].Conditional()
        && (ArraySize(picked) == 0 || picked[0].payload != this.parts[i].payload) {
        ArrayPush(picked, this.parts[i]);
      };
      i += 1;
    };
    if ArraySize(picked) == 0 { return null; };
    let spec: ref<SDPQHSpec> = SDPQHNativeRef.SpecOf(this.Title() + " approx", picked[0], ArraySize(picked) > 1 ? picked[1] : null, this.spread);
    spec.Set(1, 2.00);
    spec.Set(2, Cast<Float>(Min(this.spread, 3)));
    let first: Bool = true;
    let n: Int32 = 0;
    while n < 2 {
      let o: Int32 = SDPQHSpec.RuleBase(first);
      if spec.I(o) != 0 {
        let single: Bool = spec.F(o + 5) <= 0.00;
        spec.Set(o + 3, single ? 2.00 : SDPQHNativeRef.Nearest(spec.F(o + 3), 2.00, 4.00, 8.00));
        spec.Set(o + 4, SDPQHNativeRef.Nearest(spec.F(o + 4), 10.00, 25.00, 50.00));
        // One pulse in a 2 s window stands in for a single hit.
        spec.Set(o + 5, single ? 2.00 : SDPQHNativeRef.Nearest(spec.F(o + 5), 0.50, 1.00, 2.00));
      } else {
        spec.Set(o + 3, 4.00);
        spec.Set(o + 4, 25.00);
        spec.Set(o + 5, 1.00);
      };
      first = false;
      n += 1;
    };
    return spec;
  }

  public final static func Nearest(value: Float, a: Float, b: Float, c: Float) -> Float {
    let best: Float = a;
    if AbsF(value - b) < AbsF(value - best) { best = b; };
    if AbsF(value - c) < AbsF(value - best) { best = c; };
    return best;
  }

  // What the recreation does, one line per part, for the wheel and the menus.
  public final func Description() -> String {
    let text: String = "";
    let i: Int32 = 0;
    while i < ArraySize(this.parts) {
      let line: String = SDPQHDesign.RuleSentence(4, this.parts[i].payload, 0, this.parts[i].duration, this.parts[i].amount, this.parts[i].interval);
      if this.parts[i].Conditional() { line = "Only when " + SDPQHConditions.Text(this.parts[i].when) + ": " + line; };
      text += (i > 0 ? "\n" : "") + line;
      i += 1;
    };
    if this.spread > 0 {
      text += "\nOn upload it spreads to " + IntToString(this.spread) + " nearby " + (this.spread == 1 ? "enemy" : "enemies")
        + " within " + SDPQHDesign.Num(this.spreadRange) + "m" + (this.spreadOverclock ? ", more on an Overclock spread roll" : "") + ".";
    } else {
      if this.spreadOverclock {
        text += "\nAn Overclock spread roll spreads it to enemies within " + SDPQHDesign.Num(this.spreadRange) + "m.";
      };
    };
    return text;
  }

  public final func Summary() -> String {
    let text: String = this.Title() + " (" + SDPQHNativeRef.Short(this.item) + ") - " + this.Coverage();
    text += "\nNative: " + IntToString(this.ram) + " RAM, " + SDPQHDesign.Num(this.upload) + "s upload, "
      + SDPQHDesign.Num(this.cooldown) + "s cooldown" + (this.duration > 0.00 ? ", " + SDPQHDesign.Num(this.duration) + "s duration" : "");
    if this.spread > 0 || this.spreadOverclock {
      text += ", spreads to " + IntToString(this.spread) + (this.spreadOverclock ? " (more on an Overclock roll)" : "")
        + " within " + SDPQHDesign.Num(this.spreadRange) + "m";
    };
    let i: Int32 = 0;
    if ArraySize(this.damage) > 0 {
      text += "\nNative damage (tooltip): ";
      while i < ArraySize(this.damage) {
        text += (i > 0 ? "; " : "") + this.damage[i];
        i += 1;
      };
    };
    if this.Supported() {
      text += "\nRecreation:";
      i = 0;
      while i < ArraySize(this.parts) {
        text += "\n  " + this.parts[i].Text();
        i += 1;
      };
      i = 0;
      while i < ArraySize(this.ports) {
        text += "\n  The chip runs " + SDPQHPorts.Text(this.ports[i]) + ", as the native does.";
        i += 1;
      };
    };
    if ArraySize(this.kept) > 0 {
      text += "\nKept native in its look: ";
      i = 0;
      while i < ArraySize(this.kept) {
        text += (i > 0 ? "; " : "") + this.kept[i];
        i += 1;
      };
    };
    if ArraySize(this.fixes) > 0 {
      text += "\nNative bugs fixed: ";
      i = 0;
      while i < ArraySize(this.fixes) {
        text += (i > 0 ? "; " : "") + this.fixes[i];
        i += 1;
      };
    };
    if ArraySize(this.missing) > 0 {
      text += "\nNot recreated: ";
      i = 0;
      while i < ArraySize(this.missing) {
        text += (i > 0 ? ", " : "") + this.missing[i];
        i += 1;
      };
    };
    return text;
  }

  // Library order: by name, then tier.
  public final func Before(other: ref<SDPQHNativeRef>) -> Bool {
    if NotEquals(this.name, other.name) { return UnicodeStringLessThan(this.name, other.name); };
    if this.tier != other.tier { return this.tier < other.tier; };
    return this.plus < other.plus;
  }
}

// Every native puppet quickhack program, one entry per distinct quickhack
// action, sorted by name and tier. Built on first use; Refresh() re-measures.
public class SDPQHRefCatalog extends IScriptable {
  public let entries: array<ref<SDPQHNativeRef>>;

  public final static func Build(player: ref<PlayerPuppet>) -> ref<SDPQHRefCatalog> {
    let catalog: ref<SDPQHRefCatalog> = new SDPQHRefCatalog();
    let actions: array<TweakDBID>;
    let records: array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(n"Item");
    let i: Int32 = 0;
    while i < ArraySize(records) {
      let item: ref<Item_Record> = records[i] as Item_Record;
      if IsDefined(item) && IsDefined(item.ItemType()) && Equals(item.ItemType().Type(), gamedataItemType.Prt_Program) {
        let reference: ref<SDPQHNativeRef> = SDPQHNativeRef.FromItem(player, item.GetID());
        if IsDefined(reference) && !ArrayContains(actions, reference.action) {
          ArrayPush(actions, reference.action);
          catalog.Insert(reference);
        };
      };
      i += 1;
    };
    return catalog;
  }

  public final func Insert(reference: ref<SDPQHNativeRef>) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.entries) && this.entries[i].Before(reference) { i += 1; };
    ArrayInsert(this.entries, i, reference);
  }

  public final func Refresh(player: ref<PlayerPuppet>) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.entries) {
      let fresh: ref<SDPQHNativeRef> = SDPQHNativeRef.FromItem(player, this.entries[i].item);
      if IsDefined(fresh) { this.entries[i] = fresh; };
      i += 1;
    };
  }

  public final func IndexOf(item: TweakDBID) -> Int32 {
    let i: Int32 = 0;
    while i < ArraySize(this.entries) {
      if this.entries[i].item == item { return i; };
      i += 1;
    };
    return -1;
  }
}

@addField(PlayerPuppet)
private let m_sdpqhRefs: ref<SDPQHRefCatalog>;

@addMethod(PlayerPuppet)
public final func SDPQH_RefCatalog() -> ref<SDPQHRefCatalog> {
  if !IsDefined(this.m_sdpqhRefs) { this.m_sdpqhRefs = SDPQHRefCatalog.Build(this); };
  return this.m_sdpqhRefs;
}

// Re-reads every entry with the player's current stats (menus call this on open).
@addMethod(PlayerPuppet)
public final func SDPQH_RefRefresh() -> Int32 {
  let catalog: ref<SDPQHRefCatalog> = this.SDPQH_RefCatalog();
  catalog.Refresh(this);
  return ArraySize(catalog.entries);
}

@addMethod(PlayerPuppet)
public final func SDPQH_Ref(index: Int32) -> ref<SDPQHNativeRef> {
  let catalog: ref<SDPQHRefCatalog> = this.SDPQH_RefCatalog();
  return index >= 0 && index < ArraySize(catalog.entries) ? catalog.entries[index] : null;
}

// CET API: plain values per catalog index.
@addMethod(PlayerPuppet)
public final func SDPQH_RefCount() -> Int32 { return ArraySize(this.SDPQH_RefCatalog().entries); }

@addMethod(PlayerPuppet)
public final func SDPQH_RefTitle(index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  return IsDefined(reference) ? reference.Title() : "";
}

@addMethod(PlayerPuppet)
public final func SDPQH_RefName(index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  return IsDefined(reference) ? reference.name : "";
}

@addMethod(PlayerPuppet)
public final func SDPQH_RefCoverage(index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  return IsDefined(reference) ? reference.Coverage() : "";
}

@addMethod(PlayerPuppet)
public final func SDPQH_RefSummary(index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  return IsDefined(reference) ? reference.Summary() : "Pick a native quickhack.";
}

@addMethod(PlayerPuppet)
public final func SDPQH_CompileReference(slot: Int32, index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  if !IsDefined(reference) { return "Pick a native quickhack first."; };
  return this.SDPQH_CompileReferenceItem(slot, reference.item);
}

// Adds the nearest craftable design to the library, to compare the designer's
// own numbers with the exact recreation. Returns the new design index or -1.
@addMethod(PlayerPuppet)
public final func SDPQH_RefToLibrary(index: Int32) -> Int32 {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  let approximation: ref<SDPQHSpec> = IsDefined(reference) ? reference.Approximation() : null;
  // Native-behavior parts have no designed primitive to snap to.
  if !IsDefined(approximation) { return -1; };
  return this.SDPQH_StoreDesign(-1, approximation);
}

// Testing aid (free mode only in the menus): the native program to compare with.
@addMethod(PlayerPuppet)
public final func SDPQH_RefGiveNative(index: Int32) -> String {
  let reference: ref<SDPQHNativeRef> = this.SDPQH_Ref(index);
  if !IsDefined(reference) { return "Pick a native quickhack first."; };
  if !GameInstance.GetTransactionSystem(this.GetGame()).GiveItem(this, ItemID.FromTDBID(reference.item), 1) {
    return "The game refused to create " + reference.Title() + ".";
  };
  return reference.Title() + " added to your inventory. Install it next to the recreation's chip.";
}

// Catalog index of the native program a slot recreates, or -1.
@addMethod(PlayerPuppet)
public final func SDPQH_SlotRefIndex(slot: Int32) -> Int32 {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  if !IsDefined(data) || !TDBID.IsValid(data.SDPQH_SlotRef(slot)) { return -1; };
  return this.SDPQH_RefCatalog().IndexOf(data.SDPQH_SlotRef(slot));
}


// Native look for recreations. For every native status a recreation can wear,
// a copy is made at TweakDB load. Kept from the native status: its type, AI
// data (the reaction and animation the NPC's AI plays), VFX, SFX, UI data,
// immunities, gameplay tags, duration (with its perk bonuses), stacking and
// every package: stat changes, animation overrides (Cripple Movement's limp),
// effect and sound effectors (Short Circuit's sparks, Weapon Glitch's gun),
// and other effectors, conditional ones with their native condition (the
// Cyberware Malfunction ladder). Removed: the unconditional damage effectors
// our pulses replace and spread effectors (our spread replaces them); a
// package that loses one is copied. Ours: not saved, plus the SDPPrimitive and
// SDPLook tags. The runtime pulses damage while the look is on the target.
//
// Build 13 replaced the packages with our primitive's, which dropped the
// animations, package effects and stat mechanics, added our mechanics tags
// (SDPJam blocked every shot; the native jam does not) and forced one stack
// and a fixed duration (no repeat-upload extension, no stack ladder).
public abstract class SDPQHLook {
  public static func ID(status: TweakDBID) -> TweakDBID { return status + t".SDPLook"; }

  public static func Ready(status: TweakDBID) -> Bool {
    return TDBID.IsValid(status) && IsDefined(TweakDBInterface.GetStatusEffectRecord(SDPQHLook.ID(status)));
  }

  public static func AttackID(attack: TweakDBID) -> TweakDBID { return attack + t".SDPLook"; }

  public static func AttackReady(attack: TweakDBID) -> Bool {
    return TDBID.IsValid(attack) && IsDefined(TweakDBInterface.GetAttackRecord(SDPQHLook.AttackID(attack)));
  }

  // An attack our pulses can stand in for: it deals typed damage.
  public static func Damage(attack: ref<Attack_Record>) -> Bool {
    return IsDefined(attack) && attack.GetStatModifiersCount() > 0 && SDPQHNativeRef.DamagePayload(attack) > 0;
  }

  public static func AttackOf(effector: ref<Effector_Record>) -> ref<Attack_Record> {
    let single: ref<TriggerAttackEffector_Record> = effector as TriggerAttackEffector_Record;
    if IsDefined(single) { return single.AttackRecord(); };
    let continuous: ref<ContinuousAttackEffector_Record> = effector as ContinuousAttackEffector_Record;
    if IsDefined(continuous) { return continuous.AttackRecord(); };
    return null;
  }

  // Effectors our runtime replaces: unconditional typed damage (our pulses, as
  // SDPQHNativeRef.DamageEffector recreates it) and spread (our spread).
  // Conditional damage stays in the look with its native condition.
  public static func Replaced(effector: ref<Effector_Record>) -> Bool {
    if !IsDefined(effector) { return false; };
    let name: CName = effector.EffectorClassName();
    if Equals(name, n"SpreadEffector") || Equals(name, n"SpreadInitEffector") { return true; };
    return SDPQHLook.Damage(SDPQHLook.AttackOf(effector)) && StrLen(SDPQHNativeRef.Condition(effector)) == 0;
  }

  // True when the target is immune to the native status (its immunity stats),
  // as the status system would refuse it. The recreation then skips the part,
  // pulses included.
  public static func Immune(target: ref<GameObject>, status: TweakDBID) -> Bool {
    let record: ref<StatusEffect_Record> = TweakDBInterface.GetStatusEffectRecord(status);
    if !IsDefined(target) || !IsDefined(record) { return false; };
    let stats: array<wref<Stat_Record>>;
    record.ImmunityStats(stats);
    let system: ref<StatsSystem> = GameInstance.GetStatsSystem(target.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(stats) {
      if IsDefined(stats[i]) && system.GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), stats[i].StatType()) > 0.00 { return true; };
      i += 1;
    };
    return false;
  }

  public static func Make(status: ref<StatusEffect_Record>) -> Bool {
    let id: TweakDBID = SDPQHLook.ID(status.GetID());
    if IsDefined(TweakDBInterface.GetStatusEffectRecord(id)) { return true; };
    if !TweakDBManager.CloneRecord(id, status.GetID()) { return false; };
    // Named after its native status, so dumps and the meter can show it.
    TweakDBManager.RegisterName(StringToName(TDBID.ToStringDEBUG(status.GetID()) + ".SDPLook"));
    let tags: array<CName> = status.GameplayTags();
    if !ArrayContains(tags, n"SDPPrimitive") { ArrayPush(tags, n"SDPPrimitive"); };
    if !ArrayContains(tags, n"SDPLook") { ArrayPush(tags, n"SDPLook"); };
    let packages: array<TweakDBID>;
    let i: Int32 = 0;
    while i < status.GetPackagesCount() {
      let kept: TweakDBID = SDPQHLook.Package(status.GetPackagesItem(i));
      if TDBID.IsValid(kept) { ArrayPush(packages, kept); };
      i += 1;
    };
    TweakDBManager.SetFlat(id + t".gameplayTags", ToVariant(tags));
    TweakDBManager.SetFlat(id + t".packages", ToVariant(packages));
    // Our runtime is session-only, so the look is too.
    TweakDBManager.SetFlat(id + t".savable", ToVariant(false));
    return TweakDBManager.UpdateRecord(id);
  }

  // A native package without the effectors we replace. A package we change is
  // copied (<package>.SDPLook); an untouched one is shared as it is.
  public static func Package(package: ref<GameplayLogicPackage_Record>) -> TweakDBID {
    if !IsDefined(package) { return t""; };
    let effectors: array<TweakDBID>;
    let dropped: Bool = false;
    let i: Int32 = 0;
    while i < package.GetEffectorsCount() {
      let effector: ref<Effector_Record> = package.GetEffectorsItem(i);
      if SDPQHLook.Replaced(effector) {
        dropped = true;
      } else {
        if IsDefined(effector) { ArrayPush(effectors, effector.GetID()); };
      };
      i += 1;
    };
    if !dropped { return package.GetID(); };
    let copy: TweakDBID = package.GetID() + t".SDPLook";
    if !IsDefined(TweakDBInterface.GetGameplayLogicPackageRecord(copy)) {
      // Without a copy the package would bring its native damage along.
      if !TweakDBManager.CloneRecord(copy, package.GetID()) { return t""; };
      TweakDBManager.RegisterName(StringToName(TDBID.ToStringDEBUG(package.GetID()) + ".SDPLook"));
      TweakDBManager.SetFlat(copy + t".effectors", ToVariant(effectors));
      TweakDBManager.UpdateRecord(copy);
    };
    return copy;
  }

  // Our pulses' attack for a native damage attack: the native record without
  // its damage values (each pulse adds our amount). It keeps the damage type,
  // attack type and hit flags (Nonlethal, ForceNoCrit, DisableNPCHitReaction,
  // the perk bonus flags), so the damage pipeline and perks keyed on them
  // treat our pulse as the native hit.
  public static func MakeAttack(attack: ref<Attack_Record>) -> Bool {
    let id: TweakDBID = SDPQHLook.AttackID(attack.GetID());
    if IsDefined(TweakDBInterface.GetAttackRecord(id)) { return true; };
    if !TweakDBManager.CloneRecord(id, attack.GetID()) { return false; };
    TweakDBManager.RegisterName(StringToName(TDBID.ToStringDEBUG(attack.GetID()) + ".SDPLook"));
    let none: array<TweakDBID>;
    TweakDBManager.SetFlat(id + t".statModifiers", ToVariant(none));
    return TweakDBManager.UpdateRecord(id);
  }

  // Looks and attacks for every status a recreation of `action` can wear: its
  // completion statuses on the target and the statuses its completion
  // effectors apply to the target (SDPQHNativeRef.Measure reads the same).
  public static func MakeFor(action: ref<ObjectAction_Record>) -> Void {
    let effects: array<wref<ObjectActionEffect_Record>>;
    action.CompletionEffects(effects);
    let i: Int32 = 0;
    while i < ArraySize(effects) {
      if SDPQHNativeRef.OnTarget(effects[i]) {
        let status: ref<StatusEffect_Record> = effects[i].StatusEffect();
        let effector: ref<Effector_Record> = effects[i].EffectorToTrigger();
        let applier: ref<ApplyStatusEffectEffector_Record> = effector as ApplyStatusEffectEffector_Record;
        if !IsDefined(status) && IsDefined(applier) { status = applier.StatusEffect(); };
        if !IsDefined(status) && IsDefined(effector) {
          status = TweakDBInterface.GetStatusEffectRecord(SDPQHPorts.AppliedStatus(effector.EffectorClassName()));
        };
        if IsDefined(status) && !SDPQHNativeRef.Bookkeeping(status.GetID()) { SDPQHLook.MakeWithAttacks(status); };
        let direct: ref<Attack_Record> = SDPQHLook.AttackOf(effector);
        if SDPQHLook.Damage(direct) { SDPQHLook.MakeAttack(direct); };
      };
      i += 1;
    };
  }

  public static func MakeWithAttacks(status: ref<StatusEffect_Record>) -> Void {
    SDPQHLook.Make(status);
    let i: Int32 = 0;
    while i < status.GetPackagesCount() {
      let package: ref<GameplayLogicPackage_Record> = status.GetPackagesItem(i);
      let j: Int32 = 0;
      while IsDefined(package) && j < package.GetEffectorsCount() {
        let attack: ref<Attack_Record> = SDPQHLook.AttackOf(package.GetEffectorsItem(j));
        if SDPQHLook.Damage(attack) { SDPQHLook.MakeAttack(attack); };
        j += 1;
      };
      i += 1;
    };
  }
}

// Runs after the YAML tweaks, so PrototypeCrafting.yaml's primitives exist.
public class SDPQHLookTweak extends ScriptableTweak {
  protected cb func OnApply() -> Void {
    let records: array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(n"Item");
    let i: Int32 = 0;
    while i < ArraySize(records) {
      let item: ref<Item_Record> = records[i] as Item_Record;
      if IsDefined(item) && IsDefined(item.ItemType()) && Equals(item.ItemType().Type(), gamedataItemType.Prt_Program)
        && SDPQHDesign.SlotForItem(item.GetID()) == 0 {
        let action: ref<ObjectAction_Record> = SDPQHNativeRef.PuppetAction(item);
        if IsDefined(action) { SDPQHLook.MakeFor(action); };
      };
      i += 1;
    };
  }
}

// Effector prerequisites the chip can check itself, per target at upload:
// stat checks on the target or the player, status and tag checks (our native
// look counts as its native status) and AND/OR groups of these.
public abstract class SDPQHConditions {
  public static func Supported(prereq: ref<IPrereq_Record>) -> Bool {
    if !IsDefined(prereq) || Equals(prereq.PrereqClassName(), n"AlwaysTruePrereq") { return true; };
    let stat: ref<StatPrereq_Record> = prereq as StatPrereq_Record;
    if IsDefined(stat) {
      return SDPQHConditions.Owner(stat.ObjectToCheck()) > 0
        && EnumValueFromString("gamedataStatType", NameToString(stat.StatType())) >= 0l;
    };
    let status: ref<StatusEffectPrereq_Record> = prereq as StatusEffectPrereq_Record;
    if IsDefined(status) {
      return SDPQHConditions.Owner(status.ObjectToCheck()) > 0 && (IsDefined(status.StatusEffect()) || IsNameValid(status.TagToCheck()));
    };
    let group: ref<MultiPrereq_Record> = prereq as MultiPrereq_Record;
    if IsDefined(group) {
      let i: Int32 = 0;
      while i < group.GetNestedPrereqsCount() {
        if !SDPQHConditions.Supported(group.GetNestedPrereqsItem(i)) { return false; };
        i += 1;
      };
      return true;
    };
    return false;
  }

  // 1: the effector's owner (the target), 2: the player, 0: not supported.
  public static func Owner(name: CName) -> Int32 {
    if Equals(name, n"Player") { return 2; };
    if Equals(name, n"Owner") || Equals(name, n"None") || !IsNameValid(name) { return 1; };
    return 0;
  }

  public static func Met(player: ref<PlayerPuppet>, target: ref<GameObject>, id: TweakDBID) -> Bool {
    let prereq: ref<IPrereq_Record> = TweakDBInterface.GetIPrereqRecord(id);
    if !IsDefined(prereq) || Equals(prereq.PrereqClassName(), n"AlwaysTruePrereq") { return true; };
    let stat: ref<StatPrereq_Record> = prereq as StatPrereq_Record;
    if IsDefined(stat) {
      let owner: ref<GameObject> = SDPQHConditions.Owner(stat.ObjectToCheck()) == 2 ? player : target;
      if !IsDefined(owner) { return false; };
      let kind: gamedataStatType = IntEnum<gamedataStatType>(Cast<Int32>(EnumValueFromString("gamedataStatType", NameToString(stat.StatType()))));
      let value: Float = GameInstance.GetStatsSystem(owner.GetGame()).GetStatValue(Cast<StatsObjectID>(owner.GetEntityID()), kind);
      let limit: Float = stat.ValueToCheck();
      let compare: CName = stat.ComparisonType();
      if Equals(compare, n"Less") { return value < limit; };
      if Equals(compare, n"LessOrEqual") { return value <= limit; };
      if Equals(compare, n"Greater") { return value > limit; };
      if Equals(compare, n"GreaterOrEqual") { return value >= limit; };
      if Equals(compare, n"NotEqual") { return value != limit; };
      return value == limit;
    };
    let status: ref<StatusEffectPrereq_Record> = prereq as StatusEffectPrereq_Record;
    if IsDefined(status) {
      let holder: ref<GameObject> = SDPQHConditions.Owner(status.ObjectToCheck()) == 2 ? player : target;
      if !IsDefined(holder) { return false; };
      let has: Bool;
      if IsDefined(status.StatusEffect()) {
        let nativeStatus: TweakDBID = status.StatusEffect().GetID();
        has = StatusEffectSystem.ObjectHasStatusEffect(holder, nativeStatus) || StatusEffectSystem.ObjectHasStatusEffect(holder, SDPQHLook.ID(nativeStatus));
      } else {
        has = StatusEffectSystem.ObjectHasStatusEffectWithTag(holder, status.TagToCheck());
      };
      return status.Invert() ? !has : has;
    };
    let group: ref<MultiPrereq_Record> = prereq as MultiPrereq_Record;
    if IsDefined(group) {
      let any: Bool = Equals(group.AggregationType(), n"OR");
      let i: Int32 = 0;
      while i < group.GetNestedPrereqsCount() {
        let met: Bool = SDPQHConditions.Met(player, target, group.GetNestedPrereqsItem(i).GetID());
        if any && met { return true; };
        if !any && !met { return false; };
        i += 1;
      };
      return !any;
    };
    return false;
  }

  public static func Text(id: TweakDBID) -> String {
    let prereq: ref<IPrereq_Record> = TweakDBInterface.GetIPrereqRecord(id);
    if !IsDefined(prereq) { return SDPQHNativeRef.Short(id); };
    let group: ref<MultiPrereq_Record> = prereq as MultiPrereq_Record;
    if IsDefined(group) {
      let text: String = "";
      let i: Int32 = 0;
      while i < group.GetNestedPrereqsCount() {
        text += (i > 0 ? " " + NameToString(group.AggregationType()) + " " : "") + SDPQHConditions.Text(group.GetNestedPrereqsItem(i).GetID());
        i += 1;
      };
      return "(" + text + ")";
    };
    let stat: ref<StatPrereq_Record> = prereq as StatPrereq_Record;
    if IsDefined(stat) {
      return (SDPQHConditions.Owner(stat.ObjectToCheck()) == 2 ? "your " : "the target's ") + NameToString(stat.StatType()) + " "
        + SDPQHNativeRef.Comparison(stat.ComparisonType()) + " " + SDPQHDesign.Num(stat.ValueToCheck());
    };
    let status: ref<StatusEffectPrereq_Record> = prereq as StatusEffectPrereq_Record;
    if IsDefined(status) {
      return (status.Invert() ? "without " : "with ")
        + (IsDefined(status.StatusEffect()) ? SDPQHNativeRef.Short(status.StatusEffect().GetID()) : NameToString(status.TagToCheck()));
    };
    return NameToString(prereq.PrereqClassName());
  }
}

// Completion effectors the chip runs from script, as their game classes do
// (decompiled 2.31 scripts), on every recipient after its statuses land. Each
// reads its record's flats the way the class's Initialize does.
public abstract class SDPQHPorts {
  public static func Ported(name: CName) -> Bool {
    return Equals(name, n"NotifyPoliceEffector") || Equals(name, n"RewardPlayerWithCrimeScoreEffector")
      || Equals(name, n"ModifyStatusEffectDurationEffector") || Equals(name, n"SystemCollapseModifyRevealBarEffector")
      || Equals(name, n"DestroyBreachEffector") || Equals(name, n"ApplyLegendaryWhistleEffector");
  }

  // A ported effector that applies one native status: the recreation wears it
  // as a part instead. ApplyLegendaryWhistleEffector applies WhistleLvl4.
  public static func AppliedStatus(name: CName) -> TweakDBID {
    if Equals(name, n"ApplyLegendaryWhistleEffector") { return t"BaseStatusEffect.WhistleLvl4"; };
    return t"";
  }

  // What such a part leaves out of its effector.
  public static func Gap(name: CName) -> String {
    if Equals(name, n"ApplyLegendaryWhistleEffector") {
      return "WhistleLvl4_TurnAway (re-uploading on a lured target out of combat turns it away)";
    };
    return NameToString(name);
  }

  public static func Text(effector: TweakDBID) -> String {
    let record: ref<Effector_Record> = TweakDBInterface.GetEffectorRecord(effector);
    if !IsDefined(record) { return SDPQHNativeRef.Short(effector); };
    let name: CName = record.EffectorClassName();
    let text: String = NameToString(name);
    if Equals(name, n"NotifyPoliceEffector") { text = "the police notice"; };
    if Equals(name, n"RewardPlayerWithCrimeScoreEffector") { text = "the crime score"; };
    if Equals(name, n"ModifyStatusEffectDurationEffector") { text = "a duration change of the target's other quickhacks"; };
    if Equals(name, n"SystemCollapseModifyRevealBarEffector") { text = "the trace reveal-bar change"; };
    if Equals(name, n"DestroyBreachEffector") { text = "breach destruction"; };
    let condition: String = SDPQHNativeRef.Condition(record);
    return text + (StrLen(condition) > 0 ? " (only when " + condition + ")" : "");
  }

  public static func Run(player: ref<PlayerPuppet>, target: ref<GameObject>, effector: TweakDBID) -> Void {
    let record: ref<Effector_Record> = TweakDBInterface.GetEffectorRecord(effector);
    if !IsDefined(record) || !IsDefined(target) || !IsDefined(player) { return; };
    if IsDefined(record.PrereqRecord()) && !SDPQHConditions.Met(player, target, record.PrereqRecord().GetID()) { return; };
    let name: CName = record.EffectorClassName();
    let game: GameInstance = target.GetGame();
    // NotifyPoliceEffector.ProcessAction
    if Equals(name, n"NotifyPoliceEffector") { PreventionSystem.NotifyPolice(target); };
    // RewardPlayerWithCrimeScoreEffector.ProcessAction
    if Equals(name, n"RewardPlayerWithCrimeScoreEffector") {
      PreventionSystem.CreateNewPreventionDamageRequest(game, target, -1.00, gamedataAttackType.Hack, 1.00, true);
    };
    if Equals(name, n"ModifyStatusEffectDurationEffector") { SDPQHPorts.ChangeDurations(target, effector); };
    // SystemCollapseModifyRevealBarEffector.ProcessEffector
    if Equals(name, n"SystemCollapseModifyRevealBarEffector") && player.IsBeingRevealed() {
      let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
      if IsDefined(puppet) && puppet.IsNetrunnerPuppet() {
        StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.RevealInterrupted");
      } else {
        GameInstance.GetStatPoolsSystem(game).RequestChangingStatPoolValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatPoolType.QuickHackUpload,
          TweakDBInterface.GetFloat(effector + t".value", 0.00), target, true, true);
      };
      StatusEffectHelper.ApplyStatusEffect(player, t"BaseStatusEffect.SystemCollapseMemoryCostReduction");
    };
    // DestroyBreachEffector.ActionOn
    if Equals(name, n"DestroyBreachEffector") {
      let npc: ref<NPCPuppet> = target as NPCPuppet;
      if IsDefined(npc) && !GameInstance.GetGodModeSystem(game).HasGodMode(npc.GetEntityID(), gameGodModeType.Invulnerable)
        && GameInstance.GetStatsSystem(game).GetStatValue(Cast<StatsObjectID>(npc.GetEntityID()), gamedataStatType.IsInvulnerable) <= 0.00
        && IsDefined(npc.GetBreachControllerComponent()) {
        npc.GetBreachControllerComponent().DestroyPreviouslyTrackedBreach();
      };
    };
  }

  // ModifyStatusEffectDurationEffector.ProcessAction: changes the remaining
  // duration of the target's statuses with the effector's tags, by seconds or
  // by a percentage of each status's base duration.
  public static func ChangeDurations(target: ref<GameObject>, effector: TweakDBID) -> Void {
    let game: GameInstance = target.GetGame();
    let tags: array<CName> = TweakDBInterface.GetCNameArray(effector + t".gameplayTags");
    let change: Float = TweakDBInterface.GetFloat(effector + t".change", 0.00);
    let percentage: Bool = TweakDBInterface.GetBool(effector + t".isPercentage", false);
    let canGoOver: Bool = TweakDBInterface.GetBool(effector + t".canGoOverInitialDuration", true);
    let j: Int32 = 0;
    while j < ArraySize(tags) {
      let applied: array<ref<StatusEffect>>;
      if StatusEffectHelper.GetAppliedEffectsWithTag(target, tags[j], applied) {
        let i: Int32 = 0;
        while i < ArraySize(applied) {
          let remaining: Float = applied[i].GetRemainingDuration();
          let status: ref<StatusEffect_Record> = applied[i].GetRecord();
          if remaining > 0.00 && IsDefined(status) && IsDefined(status.Duration()) {
            let mods: array<wref<StatModifier_Record>>;
            status.Duration().StatModifiers(mods);
            let base: Float = RPGManager.CalculateStatModifiers(mods, game, target, Cast<StatsObjectID>(target.GetEntityID()));
            remaining = MaxF(0.00, remaining + (percentage ? base * change / 100.00 : change));
            if !canGoOver && remaining > base { remaining = base; };
            GameInstance.GetStatusEffectSystem(game).SetStatusEffectRemainingDuration(target.GetEntityID(), status.GetID(), remaining);
          };
          i += 1;
        };
      };
      j += 1;
    };
  }
}
