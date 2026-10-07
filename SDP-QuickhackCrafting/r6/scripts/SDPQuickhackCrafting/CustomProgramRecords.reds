// Finishes the program chip records at TweakDB load (TweakXL runs this after
// CustomPrograms.yaml). Each action starts as a clone of Reboot Optics; this
// replaces what belongs to Optics with per-slot records whose values the
// compiled design sets at runtime: cooldown, RAM cost, upload time, completion.
// The base layout is read live rather than assumed, and SDPQH_RecordCheck()
// reports the result in game.
module SkillDrivenProgression

public class SDPQHProgramTweak extends ScriptableTweak {
  protected cb func OnApply() -> Void {
    let base: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BlindHack");
    if !IsDefined(base) { return; };
    let slot: Int32 = 1;
    while slot <= SDPQHDesign.SlotCount() {
      SDPQHRecordBuilder.Build(slot, base);
      slot += 1;
    };
  }
}

public abstract class SDPQHRecordBuilder {
  public static func Clone(id: TweakDBID, name: String, source: TweakDBID) -> Bool {
    if IsDefined(TweakDBInterface.GetRecord(id)) { return true; };
    return TweakDBManager.CloneRecord(StringToName(name), source);
  }

  public static func Name(slot: Int32, suffix: String) -> String {
    return "SkillDrivenProgression.CustomHack" + IntToString(slot) + suffix;
  }

  public static func ConstantAdditive(mod: wref<StatModifier_Record>) -> Bool {
    return IsDefined(mod as ConstantStatModifier_Record) && Equals(mod.ModifierType(), n"Additive");
  }

  // Keep percentage/stat-driven modifiers (perks, cyberdeck bonuses); replace the
  // base constant with ours. `keep` lists constants that must survive anyway.
  public static func ReplaceConstant(mods: array<wref<StatModifier_Record>>, ours: TweakDBID, keep: array<TweakDBID>) -> array<TweakDBID> {
    let ids: array<TweakDBID>;
    let typed: Bool = false;
    let i: Int32 = 0;
    while i < ArraySize(mods) {
      if IsDefined(mods[i]) {
        if SDPQHRecordBuilder.ConstantAdditive(mods[i]) && !ArrayContains(keep, mods[i].GetID()) {
          if !typed && IsDefined(mods[i].StatType()) {
            TweakDBManager.SetFlat(ours + t".statType", ToVariant(mods[i].StatType().GetID()));
            TweakDBManager.UpdateRecord(ours);
            typed = true;
          };
        } else {
          ArrayPush(ids, mods[i].GetID());
        };
      };
      i += 1;
    };
    ArrayPush(ids, ours);
    return ids;
  }

  public static func Build(slot: Int32, base: ref<ObjectAction_Record>) -> Void {
    let action: TweakDBID = SDPQHDesign.ActionRecord(slot);
    if !IsDefined(TweakDBInterface.GetObjectActionRecord(action)) { return; };
    let none: array<TweakDBID>;

    // Cooldown: drop Optics' PlayerCooldown start effect and add our own copy.
    let starts: array<wref<ObjectActionEffect_Record>>;
    base.StartEffects(starts);
    let startIDs: array<TweakDBID>;
    let baseCooldown: wref<StatusEffect_Record>;
    let cooldownEffect: wref<ObjectActionEffect_Record>;
    let i: Int32 = 0;
    while i < ArraySize(starts) {
      let status: wref<StatusEffect_Record> = starts[i].StatusEffect();
      if IsDefined(status) && IsDefined(status.StatusEffectType())
        && Equals(status.StatusEffectType().Type(), gamedataStatusEffectType.PlayerCooldown) {
        if !IsDefined(cooldownEffect) { cooldownEffect = starts[i]; baseCooldown = status; };
      } else {
        ArrayPush(startIDs, starts[i].GetID());
      };
      i += 1;
    };
    let cooldownStatus: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_Cooldown"));
    if IsDefined(cooldownEffect) && IsDefined(baseCooldown.Duration())
      && SDPQHRecordBuilder.Clone(cooldownStatus, SDPQHRecordBuilder.Name(slot, "_Cooldown"), baseCooldown.GetID()) {
      let group: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_CooldownDuration"));
      let shared: array<TweakDBID>;
      let sharedGroup: ref<StatModifierGroup_Record> = TweakDBInterface.GetStatModifierGroupRecord(t"BaseStatusEffect.QuickHackCooldownDuration");
      if IsDefined(sharedGroup) {
        let n: Int32 = 0;
        while n < sharedGroup.GetStatModifiersCount() {
          ArrayPush(shared, sharedGroup.GetStatModifiersItem(n).GetID());
          n += 1;
        };
      };
      if SDPQHRecordBuilder.Clone(group, SDPQHRecordBuilder.Name(slot, "_CooldownDuration"), baseCooldown.Duration().GetID()) {
        let mods: array<wref<StatModifier_Record>>;
        baseCooldown.Duration().StatModifiers(mods);
        TweakDBManager.SetFlat(group + t".statModifiers", ToVariant(SDPQHRecordBuilder.ReplaceConstant(mods, SDPQHDesign.Record("CustomHack", slot, "_CooldownTime"), shared)));
        TweakDBManager.UpdateRecord(group);
        TweakDBManager.SetFlat(cooldownStatus + t".duration", ToVariant(group));
        TweakDBManager.UpdateRecord(cooldownStatus);
      };
      let effect: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_CooldownEffect"));
      if SDPQHRecordBuilder.Clone(effect, SDPQHRecordBuilder.Name(slot, "_CooldownEffect"), cooldownEffect.GetID()) {
        TweakDBManager.SetFlat(effect + t".statusEffect", ToVariant(cooldownStatus));
        TweakDBManager.UpdateRecord(effect);
        ArrayPush(startIDs, effect);
      };
    };
    TweakDBManager.SetFlat(action + t".startEffects", ToVariant(startIDs));

    // The cooldown's "not active" prerequisite must check our cooldown, not Optics'.
    let prereqs: array<wref<IPrereq_Record>>;
    base.InstigatorPrereqs(prereqs);
    let prereqIDs: array<TweakDBID>;
    i = 0;
    while i < ArraySize(prereqs) {
      let check: ref<StatusEffectPrereq_Record> = prereqs[i] as StatusEffectPrereq_Record;
      let copy: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_CooldownPrereq"));
      if IsDefined(check) && IsDefined(baseCooldown) && IsDefined(check.StatusEffect())
        && check.StatusEffect().GetID() == baseCooldown.GetID()
        && SDPQHRecordBuilder.Clone(copy, SDPQHRecordBuilder.Name(slot, "_CooldownPrereq"), prereqs[i].GetID()) {
        TweakDBManager.SetFlat(copy + t".statusEffect", ToVariant(cooldownStatus));
        TweakDBManager.UpdateRecord(copy);
        ArrayPush(prereqIDs, copy);
      } else {
        ArrayPush(prereqIDs, prereqs[i].GetID());
      };
      i += 1;
    };
    TweakDBManager.SetFlat(action + t".instigatorPrereqs", ToVariant(prereqIDs));

    // Completion: keep the generic quickhack effects (the "was quickhacked"
    // bookkeeping, the hacked-armor reduction and the ping refresh every native
    // quickhack runs), drop Optics' own effects and signal our slot instead.
    let completions: array<wref<ObjectActionEffect_Record>>;
    base.CompletionEffects(completions);
    let completionIDs: array<TweakDBID>;
    let template: wref<ObjectActionEffect_Record>;
    i = 0;
    while i < ArraySize(completions) {
      if SDPQHRecordBuilder.KeepsCompletion(completions[i]) {
        ArrayPush(completionIDs, completions[i].GetID());
      } else {
        if !IsDefined(template) && IsDefined(completions[i].StatusEffect()) && IsDefined(completions[i].Recipient())
          && Equals(completions[i].Recipient().Type(), gamedataObjectActionReference.Target) {
          template = completions[i];
        };
      };
      i += 1;
    };
    let signal: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_Completion"));
    if IsDefined(template) && SDPQHRecordBuilder.Clone(signal, SDPQHRecordBuilder.Name(slot, "_Completion"), template.GetID()) {
      TweakDBManager.SetFlat(signal + t".statusEffect", ToVariant(SDPQHDesign.SignalRecord(slot)));
      TweakDBManager.UpdateRecord(signal);
      ArrayPush(completionIDs, signal);
    };
    TweakDBManager.SetFlat(action + t".completionEffects", ToVariant(completionIDs));

    // Optics refuses targets that are already blinded; our chip must not.
    TweakDBManager.SetFlat(action + t".targetActivePrereqs", ToVariant(SDPQHRecordBuilder.BaseTargetChecks(base, true)));
    TweakDBManager.SetFlat(action + t".targetPrereqs", ToVariant(SDPQHRecordBuilder.BaseTargetChecks(base, false)));

    // RAM cost and upload time: per-slot constants updated by SDPQH_ApplySlot.
    if base.GetCostsCount() > 0 {
      let cost: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_Cost"));
      if SDPQHRecordBuilder.Clone(cost, SDPQHRecordBuilder.Name(slot, "_Cost"), base.GetCostsItem(0).GetID()) {
        let costMods: array<wref<StatModifier_Record>>;
        base.GetCostsItem(0).CostMods(costMods);
        TweakDBManager.SetFlat(cost + t".costMods", ToVariant(SDPQHRecordBuilder.ReplaceConstant(costMods, SDPQHDesign.Record("CustomHack", slot, "_Ram"), none)));
        TweakDBManager.UpdateRecord(cost);
        let costIDs: array<TweakDBID>;
        ArrayPush(costIDs, cost);
        let c: Int32 = 1;
        while c < base.GetCostsCount() {
          ArrayPush(costIDs, base.GetCostsItem(c).GetID());
          c += 1;
        };
        TweakDBManager.SetFlat(action + t".costs", ToVariant(costIDs));
      };
    };
    let uploadMods: array<wref<StatModifier_Record>>;
    base.ActivationTime(uploadMods);
    TweakDBManager.SetFlat(action + t".activationTime", ToVariant(SDPQHRecordBuilder.ReplaceConstant(uploadMods, SDPQHDesign.Record("CustomHack", slot, "_Upload"), none)));

    // A private interaction record keeps choice IDs distinct from Optics.
    if IsDefined(base.ObjectActionUI()) {
      let ui: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_UI"));
      if SDPQHRecordBuilder.Clone(ui, SDPQHRecordBuilder.Name(slot, "_UI"), base.ObjectActionUI().GetID()) {
        TweakDBManager.SetFlat(action + t".objectActionUI", ToVariant(ui));
      };
    };
    TweakDBManager.UpdateRecord(action);

    // The chip carries our action instead of Optics' quickhack actions.
    let item: ref<Item_Record> = TweakDBInterface.GetItemRecord(SDPQHDesign.ItemRecord(slot));
    if IsDefined(item) {
      let itemActions: array<wref<ObjectAction_Record>>;
      item.ObjectActions(itemActions);
      let itemIDs: array<TweakDBID>;
      i = 0;
      while i < ArraySize(itemActions) {
        if IsDefined(itemActions[i]) && IsDefined(itemActions[i].ObjectActionType())
          && NotEquals(itemActions[i].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack)
          && NotEquals(itemActions[i].ObjectActionType().Type(), gamedataObjectActionType.DeviceQuickHack)
          && NotEquals(itemActions[i].ObjectActionType().Type(), gamedataObjectActionType.VehicleQuickHack) {
          ArrayPush(itemIDs, itemActions[i].GetID());
        };
        i += 1;
      };
      ArrayPush(itemIDs, action);
      TweakDBManager.SetFlat(SDPQHDesign.ItemRecord(slot) + t".objectActions", ToVariant(itemIDs));
      TweakDBManager.UpdateRecord(SDPQHDesign.ItemRecord(slot));
    };
  }

  // What a chip keeps from Optics' completion: the bookkeeping statuses and
  // the generic quickhack effectors. Optics' own statuses, its spread step
  // and the police notice are dropped; a recreation runs its native program's
  // police and crime effectors from script (SDPQHPorts).
  public static func KeepsCompletion(effect: wref<ObjectActionEffect_Record>) -> Bool {
    if IsDefined(effect.StatusEffect()) { return SDPQHNativeRef.Bookkeeping(effect.StatusEffect().GetID()); };
    let effector: wref<Effector_Record> = effect.EffectorToTrigger();
    if !IsDefined(effector) { return false; };
    let name: CName = effector.EffectorClassName();
    return NotEquals(name, n"SpreadEffector") && NotEquals(name, n"SpreadInitEffector")
      && NotEquals(name, n"NotifyPoliceEffector") && NotEquals(name, n"RewardPlayerWithCrimeScoreEffector");
  }

  // Optics' target checks (`active`: targetActivePrereqs, else targetPrereqs)
  // without those that test for the Optics statuses the chip no longer applies.
  public static func BaseTargetChecks(base: ref<ObjectAction_Record>, active: Bool) -> array<TweakDBID> {
    let dropped: array<TweakDBID>;
    let droppedTags: array<CName>;
    let completions: array<wref<ObjectActionEffect_Record>>;
    base.CompletionEffects(completions);
    let i: Int32 = 0;
    while i < ArraySize(completions) {
      let status: wref<StatusEffect_Record> = completions[i].StatusEffect();
      if IsDefined(status) && !SDPQHNativeRef.Bookkeeping(status.GetID()) {
        ArrayPush(dropped, status.GetID());
        let t: Int32 = 0;
        while t < status.GetGameplayTagsCount() {
          ArrayPush(droppedTags, status.GetGameplayTagsItem(t));
          t += 1;
        };
      };
      i += 1;
    };
    let ids: array<TweakDBID>;
    if active {
      let checks: array<wref<ObjectActionPrereq_Record>>;
      base.TargetActivePrereqs(checks);
      i = 0;
      while i < ArraySize(checks) {
        let failures: array<wref<IPrereq_Record>>;
        checks[i].FailureConditionPrereq(failures);
        if !SDPQHRecordBuilder.ChecksDropped(failures, dropped, droppedTags) { ArrayPush(ids, checks[i].GetID()); };
        i += 1;
      };
    } else {
      let prereqs: array<wref<IPrereq_Record>>;
      base.TargetPrereqs(prereqs);
      i = 0;
      while i < ArraySize(prereqs) {
        let single: array<wref<IPrereq_Record>>;
        ArrayPush(single, prereqs[i]);
        if !SDPQHRecordBuilder.ChecksDropped(single, dropped, droppedTags) { ArrayPush(ids, prereqs[i].GetID()); };
        i += 1;
      };
    };
    return ids;
  }

  // Per slot at runtime (SDPQH_ApplySlot): a recreation takes its native
  // program's category, cost records, target checks and wheel icon, so
  // category perks, target resistance, tier costs and the wheel's refusals
  // ("immune", "needs a ranged weapon") match the native. Our _Ram constant
  // replaces the first cost record's constant. A designed program or an empty
  // slot gets Optics', the chip's base.
  public static func ApplyNative(slot: Int32, native: ref<ObjectAction_Record>) -> Void {
    let base: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(t"QuickHack.BlindHack");
    let action: TweakDBID = SDPQHDesign.ActionRecord(slot);
    if !IsDefined(base) || !IsDefined(TweakDBInterface.GetObjectActionRecord(action)) { return; };
    let source: ref<ObjectAction_Record> = IsDefined(native) ? native : base;
    if IsDefined(source.HackCategory()) { TweakDBManager.SetFlat(action + t".hackCategory", ToVariant(source.HackCategory().GetID())); };
    TweakDBManager.SetFlat(action + t".gameplayCategory", ToVariant(IsDefined(source.GameplayCategory()) ? source.GameplayCategory().GetID() : t""));
    let cost: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_Cost"));
    if source.GetCostsCount() > 0 && IsDefined(TweakDBInterface.GetRecord(cost)) {
      let none: array<TweakDBID>;
      let mods: array<wref<StatModifier_Record>>;
      source.GetCostsItem(0).CostMods(mods);
      TweakDBManager.SetFlat(cost + t".costMods", ToVariant(SDPQHRecordBuilder.ReplaceConstant(mods, SDPQHDesign.Record("CustomHack", slot, "_Ram"), none)));
      TweakDBManager.UpdateRecord(cost);
      let costs: array<TweakDBID>;
      ArrayPush(costs, cost);
      let c: Int32 = 1;
      while c < source.GetCostsCount() {
        ArrayPush(costs, source.GetCostsItem(c).GetID());
        c += 1;
      };
      TweakDBManager.SetFlat(action + t".costs", ToVariant(costs));
    };
    let active: array<TweakDBID> = SDPQHRecordBuilder.BaseTargetChecks(base, true);
    let checks: array<TweakDBID> = SDPQHRecordBuilder.BaseTargetChecks(base, false);
    if IsDefined(native) {
      let i: Int32 = 0;
      while i < native.GetTargetActivePrereqsCount() {
        let id: TweakDBID = native.GetTargetActivePrereqsItem(i).GetID();
        if !ArrayContains(active, id) { ArrayPush(active, id); };
        i += 1;
      };
      i = 0;
      while i < native.GetTargetPrereqsCount() {
        let id: TweakDBID = native.GetTargetPrereqsItem(i).GetID();
        if !ArrayContains(checks, id) { ArrayPush(checks, id); };
        i += 1;
      };
    };
    TweakDBManager.SetFlat(action + t".targetActivePrereqs", ToVariant(active));
    TweakDBManager.SetFlat(action + t".targetPrereqs", ToVariant(checks));
    TweakDBManager.UpdateRecord(action);
    // The wheel's icon comes from the action's interaction record.
    let ui: TweakDBID = TDBID.Create(SDPQHRecordBuilder.Name(slot, "_UI"));
    if IsDefined(TweakDBInterface.GetRecord(ui)) && IsDefined(source.ObjectActionUI()) && IsDefined(source.ObjectActionUI().CaptionIcon()) {
      TweakDBManager.SetFlat(ui + t".captionIcon", ToVariant(source.ObjectActionUI().CaptionIcon().GetID()));
      TweakDBManager.UpdateRecord(ui);
    };
  }

  // True when a prerequisite list tests for one of the statuses we removed.
  public static func ChecksDropped(prereqs: array<wref<IPrereq_Record>>, dropped: array<TweakDBID>, tags: array<CName>) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(prereqs) {
      let check: ref<StatusEffectPrereq_Record> = prereqs[i] as StatusEffectPrereq_Record;
      if IsDefined(check) {
        if IsDefined(check.StatusEffect()) && ArrayContains(dropped, check.StatusEffect().GetID()) { return true; };
        if IsNameValid(check.TagToCheck()) && ArrayContains(tags, check.TagToCheck()) { return true; };
      };
      i += 1;
    };
    return false;
  }
}

// Reports whether the scriptable tweak produced what the chips need.
@addMethod(PlayerPuppet)
public final func SDPQH_RecordCheck() -> String {
  let text: String = "";
  let slot: Int32 = 1;
  while slot <= SDPQHDesign.SlotCount() {
    let problems: String = "";
    let action: ref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(SDPQHDesign.ActionRecord(slot));
    let item: ref<Item_Record> = TweakDBInterface.GetItemRecord(SDPQHDesign.ItemRecord(slot));
    if !IsDefined(action) || !IsDefined(item) {
      problems = " records missing (deploy CustomPrograms.yaml)";
    } else {
      let effects: array<wref<ObjectActionEffect_Record>>;
      action.CompletionEffects(effects);
      let signal: Bool = false;
      let foreign: Int32 = 0;
      let i: Int32 = 0;
      while i < ArraySize(effects) {
        if IsDefined(effects[i].StatusEffect()) && effects[i].StatusEffect().GetID() == SDPQHDesign.SignalRecord(slot) {
          signal = true;
        } else {
          if !SDPQHRecordBuilder.KeepsCompletion(effects[i]) { foreign += 1; };
        };
        i += 1;
      };
      if !signal { problems += " no completion signal"; };
      if foreign > 0 { problems += " " + IntToString(foreign) + " Optics completion effects left"; };
      let starts: array<wref<ObjectActionEffect_Record>>;
      action.StartEffects(starts);
      let cooldown: Bool = false;
      i = 0;
      while i < ArraySize(starts) {
        if IsDefined(starts[i].StatusEffect()) && starts[i].StatusEffect().GetID() == SDPQHDesign.Record("CustomHack", slot, "_Cooldown") { cooldown = true; };
        i += 1;
      };
      if !cooldown { problems += " shares Optics cooldown"; };
      let ram: Bool = false;
      if action.GetCostsCount() > 0 {
        let mods: array<wref<StatModifier_Record>>;
        action.GetCostsItem(0).CostMods(mods);
        i = 0;
        while i < ArraySize(mods) {
          if IsDefined(mods[i]) && mods[i].GetID() == SDPQHDesign.Record("CustomHack", slot, "_Ram") { ram = true; };
          i += 1;
        };
      };
      if !ram { problems += " RAM cost not designed"; };
      let upload: Bool = false;
      let times: array<wref<StatModifier_Record>>;
      action.ActivationTime(times);
      i = 0;
      while i < ArraySize(times) {
        if IsDefined(times[i]) && times[i].GetID() == SDPQHDesign.Record("CustomHack", slot, "_Upload") { upload = true; };
        i += 1;
      };
      if !upload { problems += " upload time not designed"; };
      let itemActions: array<wref<ObjectAction_Record>>;
      item.ObjectActions(itemActions);
      let carried: Bool = false;
      i = 0;
      while i < ArraySize(itemActions) {
        if IsDefined(itemActions[i]) && itemActions[i].GetID() == SDPQHDesign.ActionRecord(slot) { carried = true; };
        i += 1;
      };
      if !carried { problems += " chip does not carry its action"; };
    };
    text += (slot > 1 ? " | " : "") + SDPQHDesign.Letter(slot) + (StrLen(problems) == 0 ? ": ok" : ":" + problems);
    slot += 1;
  };
  return "Program records " + text;
}
