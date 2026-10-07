// Native quickhack references. Every native puppet quickhack program, at every
// tier the game defines, is read from TweakDB at runtime and rebuilt from our
// primitives with the native numbers: RAM, upload, cooldown, effect durations,
// damage per hit, pulse interval and spread. Compiled into a program slot, the
// recreation runs through the same chip, rule engine and primitives as a
// designed program, so it can be uploaded next to the native program and the
// two compared (ComparisonMeter.reds). Numbers are computed the way the
// program tooltip computes them, from the player's current stats.
module SkillDrivenProgression

// One native effect rebuilt as one of our primitives.
public class SDPQHRefPart extends IScriptable {
  public let payload: Int32;
  public let duration: Float;
  public let amount: Float;
  // Seconds between damage pulses; 0 = a single hit.
  public let interval: Float;
  public let source: String;
  // The native status this effect came from; its look record (SDPQHLook)
  // gives the recreation the native animation, AI reaction and effects.
  public let look: TweakDBID;
}

public class SDPQHNativeRef extends IScriptable {
  public let item: TweakDBID;
  public let action: TweakDBID;
  public let name: String;
  public let tier: Int32;
  public let plus: Int32;
  public let ram: Int32;
  public let upload: Float;
  // Additive constant part of the upload time; the chip's own constant takes it.
  public let uploadBase: Float;
  public let cooldown: Float;
  public let duration: Float;
  public let spread: Int32;
  public let spreadRange: Float;
  public let parts: array<ref<SDPQHRefPart>>;
  // Native effects with no primitive yet.
  public let missing: array<String>;
  // Native damage as the program tooltip computes it.
  public let damage: array<String>;

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

  // Which of our control primitives a native status corresponds to, by the
  // gameplay tags the game's scripts react to. 0 = none.
  public final static func ControlPayload(status: ref<StatusEffect_Record>) -> Int32 {
    if status.GameplayTagsContains(n"QuickHackBlind") || status.GameplayTagsContains(n"Blind") { return 1; };
    if status.GameplayTagsContains(n"LocomotionMalfunction") || status.GameplayTagsContains(n"LocomotionMalfunctionLevel3") { return 9; };
    if status.GameplayTagsContains(n"JamWeapon") || status.GameplayTagsContains(n"WeaponJam") { return 10; };
    if status.GameplayTagsContains(n"CommsNoiseJam") || status.GameplayTagsContains(n"CommsNoise") || status.GameplayTagsContains(n"Deaf") { return 11; };
    if status.GameplayTagsContains(n"CyberwareMalfunction") { return 12; };
    if IsDefined(status.StatusEffectType()) && Equals(status.StatusEffectType().Type(), gamedataStatusEffectType.Stunned) { return 4; };
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

  public final func Measure(player: ref<PlayerPuppet>, action: ref<ObjectAction_Record>) -> Void {
    let game: GameInstance = player.GetGame();
    let playerID: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let dummy: EntityID;
    this.ram = BaseScriptableAction.GetBaseCostStatic(player, action);

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

    // Cooldown: the program's own part, without the shared cooldown group.
    let shared: array<wref<StatModifier_Record>>;
    let group: ref<StatModifierGroup_Record> = TweakDBInterface.GetStatModifierGroupRecord(t"BaseStatusEffect.QuickHackCooldownDuration");
    if IsDefined(group) { group.StatModifiers(shared); };
    let starts: array<wref<ObjectActionEffect_Record>>;
    action.StartEffects(starts);
    i = 0;
    while i < ArraySize(starts) && this.cooldown == 0.00 {
      let status: wref<StatusEffect_Record> = starts[i].StatusEffect();
      if IsDefined(status) && IsDefined(status.StatusEffectType()) && IsDefined(status.Duration())
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
      i += 1;
    };

    let effects: array<wref<ObjectActionEffect_Record>>;
    action.CompletionEffects(effects);
    i = 0;
    while i < ArraySize(effects) {
      let effect: wref<ObjectActionEffect_Record> = effects[i];
      // Effects on the instigator are buffs for V, not part of the hack's effect.
      let onTarget: Bool = !IsDefined(effect.Recipient()) || Equals(effect.Recipient().Type(), gamedataObjectActionReference.Target);
      let status: wref<StatusEffect_Record> = effect.StatusEffect();
      if onTarget && IsDefined(status) {
        if status.GetID() != t"BaseStatusEffect.WasQuickHacked" && status.GetID() != t"BaseStatusEffect.QuickHackUploaded" {
          this.AddStatus(player, status);
        };
      } else {
        if onTarget && IsDefined(effect.EffectorToTrigger())
          && !this.ScanEffector(player, effect.EffectorToTrigger(), 0.00, NameToString(effect.EffectorToTrigger().EffectorClassName()), t"") {
          ArrayPush(this.missing, NameToString(effect.EffectorToTrigger().EffectorClassName()));
        };
      };
      i += 1;
    };
    this.spread = Min(this.spread, SDPQHDesign.MaxReferenceSpread());
  }

  public final func AddStatus(player: ref<PlayerPuppet>, status: ref<StatusEffect_Record>) -> Void {
    let source: String = SDPQHNativeRef.Short(status.GetID());
    let length: Float = SDPQHNativeRef.StatusDuration(player, status);
    if length < 600.00 { this.duration = MaxF(this.duration, length); };
    let handled: Bool = false;
    let control: Int32 = SDPQHNativeRef.ControlPayload(status);
    if control > 0 {
      this.AddPart(control, length, 0.00, 1.00, source, status.GetID());
      handled = true;
    };
    let packages: array<wref<GameplayLogicPackage_Record>>;
    status.Packages(packages);
    let i: Int32 = 0;
    while i < ArraySize(packages) {
      let effectors: array<wref<Effector_Record>>;
      packages[i].Effectors(effectors);
      let j: Int32 = 0;
      while j < ArraySize(effectors) {
        if this.ScanEffector(player, effectors[j], length, source, status.GetID()) { handled = true; };
        j += 1;
      };
      i += 1;
    };
    // Bookkeeping statuses (no packages, no AI behavior) do nothing to recreate.
    if !handled && (status.GetPackagesCount() > 0 || IsDefined(status.AIData())) { ArrayPush(this.missing, source); };
  }

  // Damage and spread effectors. True when the effector was recreated or read.
  public final func ScanEffector(player: ref<PlayerPuppet>, effector: ref<Effector_Record>, length: Float, source: String, look: TweakDBID) -> Bool {
    if !IsDefined(effector) { return false; };
    let spreader: ref<SpreadInitEffector_Record> = effector as SpreadInitEffector_Record;
    if IsDefined(spreader) {
      this.ReadSpread(player, spreader);
      return true;
    };
    let attack: ref<Attack_Record>;
    let interval: Float = 0.00;
    let single: ref<TriggerAttackEffector_Record> = effector as TriggerAttackEffector_Record;
    let continuous: ref<ContinuousAttackEffector_Record> = effector as ContinuousAttackEffector_Record;
    if IsDefined(single) { attack = single.AttackRecord(); };
    if IsDefined(continuous) {
      attack = continuous.AttackRecord();
      interval = continuous.DelayTime() > 0.00 ? continuous.DelayTime() : 1.00;
    };
    if !IsDefined(attack) || attack.GetStatModifiersCount() <= 0 { return false; };
    let payload: Int32 = SDPQHNativeRef.DamagePayload(attack);
    if payload == 0 { return false; };
    let mods: array<wref<StatModifier_Record>>;
    attack.StatModifiers(mods);
    // As InventoryDataManagerV2.ProcessQuickhackEffects computes the tooltip value.
    let amount: Float = MaxF(1.00, RPGManager.CalculateStatModifiers(mods, player.GetGame(), player, Cast<StatsObjectID>(player.GetEntityID()), Cast<StatsObjectID>(player.GetEntityID())));
    let pulseLength: Float = length >= 600.00 ? MaxF(interval, 0.10) : length;
    ArrayPush(this.damage, SDPQHDesign.Num(amount) + " " + SDPQHDesign.DamageTypeText(payload)
      + (interval > 0.00 ? " every " + SDPQHDesign.Num(interval) + "s for " + SDPQHDesign.Num(pulseLength) + "s" : " in one hit"));
    // A single hit keeps its native status for its native length: that status
    // carries the hit's reaction (an electrocution, for example).
    this.AddPart(payload, interval > 0.00 ? pulseLength : (length >= 600.00 ? 1.00 : MaxF(0.10, length)), amount, interval, source, look);
    return true;
  }

  // As SpreadInitEffector.ActionOn counts jumps and range.
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
    if count > this.spread && range > 0.00 {
      this.spread = count;
      this.spreadRange = range;
    };
  }

  // One part per primitive: a second native effect of the same kind is listed
  // as not recreated, since a program cannot hold two identical rules.
  public final func AddPart(payload: Int32, length: Float, amount: Float, interval: Float, source: String, look: TweakDBID) -> Void {
    let i: Int32 = 0;
    while i < ArraySize(this.parts) {
      if this.parts[i].payload == payload {
        ArrayPush(this.missing, "second " + SDPQHDesign.PayloadText(payload) + " effect (" + source + ")");
        return;
      };
      i += 1;
    };
    let part: ref<SDPQHRefPart> = new SDPQHRefPart();
    part.payload = payload;
    part.duration = length;
    part.amount = amount;
    part.interval = interval;
    part.source = source;
    part.look = look;
    ArrayPush(this.parts, part);
  }

  public final func Supported() -> Bool { return ArraySize(this.parts) > 0; }

  // The native status behind recreated rule `index` (0 or 1), if it has a look record.
  public final func Look(index: Int32) -> TweakDBID {
    if index < 0 || index >= ArraySize(this.parts) || index > 1 { return t""; };
    return SDPQHLook.Ready(this.parts[index].look, this.parts[index].payload) ? this.parts[index].look : t"";
  }

  // Everything recreated: at most two effects and nothing native-only.
  public final func Complete() -> Bool { return this.Supported() && ArraySize(this.parts) <= 2 && ArraySize(this.missing) == 0; }

  public final func TierText() -> String {
    return "T" + IntToString(this.tier) + (this.plus >= 2 ? "++" : (this.plus == 1 ? "+" : ""));
  }

  public final func Title() -> String { return this.name + " " + this.TierText(); }

  public final func Coverage() -> String {
    if !this.Supported() { return "native only"; };
    return this.Complete() ? "recreated" : "partly recreated";
  }

  // Both rules fire on upload with the native values; lifetime is irrelevant.
  public final func Spec() -> ref<SDPQHSpec> {
    let a: ref<SDPQHRefPart> = ArraySize(this.parts) > 0 ? this.parts[0] : null;
    let b: ref<SDPQHRefPart> = ArraySize(this.parts) > 1 ? this.parts[1] : null;
    let spec: ref<SDPQHSpec> = SDPQHSpec.Make(StrLeft(this.Title(), SDPQHDesign.MaxName()),
      IsDefined(a) ? 4 : 0, IsDefined(a) ? a.payload : 0, 0, IsDefined(a) ? a.duration : 4.00, IsDefined(a) ? a.amount : 25.00, IsDefined(a) ? a.interval : 1.00,
      IsDefined(b) ? 4 : 0, IsDefined(b) ? b.payload : 0, 0, IsDefined(b) ? b.duration : 4.00, IsDefined(b) ? b.amount : 25.00, IsDefined(b) ? b.interval : 1.00,
      1, this.spread);
    spec.Set(15, 1.00);
    return spec;
  }

  // The nearest design the Quickhack Designer can make (2/4/8 s, 10/25/50
  // damage, 0.5/1/2 s pulses, up to 3 spread): the craftable approximation.
  public final func Approximation() -> ref<SDPQHSpec> {
    let spec: ref<SDPQHSpec> = this.Spec();
    spec.name = StrLeft(this.Title() + " approx", SDPQHDesign.MaxName());
    spec.Set(15, 0.00);
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

  public final func LookText(index: Int32) -> String {
    let look: TweakDBID = this.Look(index);
    return TDBID.IsValid(look) ? " Native look: " + SDPQHNativeRef.Short(look) + "." : " Our look (no native status).";
  }

  public final static func Nearest(value: Float, a: Float, b: Float, c: Float) -> Float {
    let best: Float = a;
    if AbsF(value - b) < AbsF(value - best) { best = b; };
    if AbsF(value - c) < AbsF(value - best) { best = c; };
    return best;
  }

  public final func Summary() -> String {
    let text: String = this.Title() + " (" + SDPQHNativeRef.Short(this.item) + ") - " + this.Coverage();
    text += "\nNative: " + IntToString(this.ram) + " RAM, " + SDPQHDesign.Num(this.upload) + "s upload, "
      + SDPQHDesign.Num(this.cooldown) + "s cooldown" + (this.duration > 0.00 ? ", " + SDPQHDesign.Num(this.duration) + "s duration" : "");
    if this.spread > 0 {
      text += ", spreads to " + IntToString(this.spread) + " within " + SDPQHDesign.Num(this.spreadRange) + "m";
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
      let spec: ref<SDPQHSpec> = this.Spec();
      text += "\n  " + SDPQHDesign.RuleSentence(spec.I(3), spec.I(4), spec.I(5), spec.F(6), spec.F(7), spec.F(8)) + this.LookText(0);
      if spec.I(9) != 0 {
        text += "\n  " + SDPQHDesign.RuleSentence(spec.I(9), spec.I(10), spec.I(11), spec.F(12), spec.F(13), spec.F(14)) + this.LookText(1);
      };
    };
    let left: array<String> = this.missing;
    i = 2;
    while i < ArraySize(this.parts) {
      ArrayPush(left, SDPQHDesign.PayloadText(this.parts[i].payload) + " (" + this.parts[i].source + "; only two rules fit)");
      i += 1;
    };
    if ArraySize(left) > 0 {
      text += "\nNot recreated: ";
      i = 0;
      while i < ArraySize(left) {
        text += (i > 0 ? ", " : "") + left[i];
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
  if !IsDefined(reference) || !reference.Supported() { return -1; };
  return this.SDPQH_StoreDesign(-1, reference.Approximation());
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

// Native look for recreations. For every native status a recreation can use,
// a copy is made at TweakDB load with our mechanics swapped in: our open-ended
// duration, our stacking, our packages (no native damage, stat changes or
// effectors) and our primitive's tags added to the native ones. Everything
// else stays native: status type, AI data (the reaction and animation the
// NPC's AI plays), VFX, SFX, UI data and immunities. Damage, timing, triggers
// and spread remain the mod's.
public abstract class SDPQHLook {
  public static func ID(status: TweakDBID, payload: Int32) -> TweakDBID {
    return status + TDBID.Create(".SDPLook" + IntToString(payload));
  }

  public static func Ready(status: TweakDBID, payload: Int32) -> Bool {
    return TDBID.IsValid(status) && IsDefined(TweakDBInterface.GetStatusEffectRecord(SDPQHLook.ID(status, payload)));
  }

  // The payloads our recreation takes from a native status.
  public static func Payloads(status: ref<StatusEffect_Record>) -> array<Int32> {
    let list: array<Int32>;
    let control: Int32 = SDPQHNativeRef.ControlPayload(status);
    if control > 0 { ArrayPush(list, control); };
    let packages: array<wref<GameplayLogicPackage_Record>>;
    status.Packages(packages);
    let i: Int32 = 0;
    while i < ArraySize(packages) {
      let effectors: array<wref<Effector_Record>>;
      packages[i].Effectors(effectors);
      let j: Int32 = 0;
      while j < ArraySize(effectors) {
        let attack: ref<Attack_Record>;
        let single: ref<TriggerAttackEffector_Record> = effectors[j] as TriggerAttackEffector_Record;
        let continuous: ref<ContinuousAttackEffector_Record> = effectors[j] as ContinuousAttackEffector_Record;
        if IsDefined(single) { attack = single.AttackRecord(); };
        if IsDefined(continuous) { attack = continuous.AttackRecord(); };
        let payload: Int32 = IsDefined(attack) ? SDPQHNativeRef.DamagePayload(attack) : 0;
        if payload > 0 && !ArrayContains(list, payload) { ArrayPush(list, payload); };
        j += 1;
      };
      i += 1;
    };
    return list;
  }

  public static func Make(status: ref<StatusEffect_Record>, payload: Int32) -> Bool {
    let id: TweakDBID = SDPQHLook.ID(status.GetID(), payload);
    if IsDefined(TweakDBInterface.GetStatusEffectRecord(id)) { return true; };
    let primitive: ref<StatusEffect_Record> = TweakDBInterface.GetStatusEffectRecord(
      TDBID.Create("SkillDrivenProgression.Prototype" + SDPPrimitiveInstance.Name(payload) + "Long"));
    if !IsDefined(primitive) || !TweakDBManager.CloneRecord(id, status.GetID()) { return false; };
    // Named after its native status, so dumps and the meter can show it.
    TweakDBManager.RegisterName(StringToName(TDBID.ToStringDEBUG(status.GetID()) + ".SDPLook" + IntToString(payload)));
    let tags: array<CName> = status.GameplayTags();
    let ours: array<CName> = primitive.GameplayTags();
    let i: Int32 = 0;
    while i < ArraySize(ours) {
      if !ArrayContains(tags, ours[i]) { ArrayPush(tags, ours[i]); };
      i += 1;
    };
    let packages: array<TweakDBID>;
    i = 0;
    while i < primitive.GetPackagesCount() {
      ArrayPush(packages, primitive.GetPackagesItem(i).GetID());
      i += 1;
    };
    TweakDBManager.SetFlat(id + t".gameplayTags", ToVariant(tags));
    TweakDBManager.SetFlat(id + t".packages", ToVariant(packages));
    TweakDBManager.SetFlat(id + t".duration", ToVariant(t"SkillDrivenProgression.PrimitiveDurationLong"));
    TweakDBManager.SetFlat(id + t".maxStacks", ToVariant(t"SkillDrivenProgression.PrimitiveStacks"));
    TweakDBManager.SetFlat(id + t".savable", ToVariant(false));
    return TweakDBManager.UpdateRecord(id);
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
        if IsDefined(action) {
          let effects: array<wref<ObjectActionEffect_Record>>;
          action.CompletionEffects(effects);
          let j: Int32 = 0;
          while j < ArraySize(effects) {
            let status: ref<StatusEffect_Record> = effects[j].StatusEffect();
            if IsDefined(status) && status.GetID() != t"BaseStatusEffect.WasQuickHacked" && status.GetID() != t"BaseStatusEffect.QuickHackUploaded"
              && (!IsDefined(effects[j].Recipient()) || Equals(effects[j].Recipient().Type(), gamedataObjectActionReference.Target)) {
              let payloads: array<Int32> = SDPQHLook.Payloads(status);
              let k: Int32 = 0;
              while k < ArraySize(payloads) {
                SDPQHLook.Make(status, payloads[k]);
                k += 1;
              };
            };
            j += 1;
          };
        };
      };
      i += 1;
    };
  }
}
