// Designed quickhacks as real cyberdeck programs. Four program chips (slots A-D)
// carry their own actions in the scanner quickhack wheel. A slot holds a
// compiled design (SDPQHSpec, DesignLibrary.reds); uploading the chip's
// quickhack installs that design on the target through SDPPrototypeRuntime.
// The design model mirrors quickhack_designs.lua; change both together.
module SkillDrivenProgression

public abstract class SDPQHDesign {
  public static func SlotCount() -> Int32 { return 4; }
  public static func MaxDesigns() -> Int32 { return 48; }
  public static func MaxName() -> Int32 { return 48; }

  // Values per design or slot; layout in DesignLibrary.reds.
  public static func Stride() -> Int32 { return 16; }

  public static func Letter(slot: Int32) -> String {
    switch slot {
      case 1: return "A";
      case 2: return "B";
      case 3: return "C";
      case 4: return "D";
    };
    return "?";
  }

  public static func Record(prefix: String, slot: Int32, suffix: String) -> TweakDBID {
    return TDBID.Create("SkillDrivenProgression." + prefix + IntToString(slot) + suffix);
  }

  // Literal IDs: the item checks run for every inventory name and status event.
  public static func ActionRecord(slot: Int32) -> TweakDBID {
    switch slot {
      case 1: return t"SkillDrivenProgression.CustomHack1";
      case 2: return t"SkillDrivenProgression.CustomHack2";
      case 3: return t"SkillDrivenProgression.CustomHack3";
      case 4: return t"SkillDrivenProgression.CustomHack4";
    };
    return t"";
  }

  public static func ItemRecord(slot: Int32) -> TweakDBID {
    switch slot {
      case 1: return t"SkillDrivenProgression.CustomProgram1";
      case 2: return t"SkillDrivenProgression.CustomProgram2";
      case 3: return t"SkillDrivenProgression.CustomProgram3";
      case 4: return t"SkillDrivenProgression.CustomProgram4";
    };
    return t"";
  }

  public static func SignalRecord(slot: Int32) -> TweakDBID {
    switch slot {
      case 1: return t"SkillDrivenProgression.CustomHackSignal1";
      case 2: return t"SkillDrivenProgression.CustomHackSignal2";
      case 3: return t"SkillDrivenProgression.CustomHackSignal3";
      case 4: return t"SkillDrivenProgression.CustomHackSignal4";
    };
    return t"";
  }

  public static func LabelFlat(slot: Int32) -> TweakDBID { return SDPQHDesign.Record("CustomProgramLabel", slot, ""); }
  public static func SummaryFlat(slot: Int32) -> TweakDBID { return SDPQHDesign.Record("CustomProgramSummary", slot, ""); }

  public static func SlotForItem(id: TweakDBID) -> Int32 {
    let slot: Int32 = 1;
    while slot <= SDPQHDesign.SlotCount() {
      if id == SDPQHDesign.ItemRecord(slot) { return slot; };
      slot += 1;
    };
    return 0;
  }

  public static func SlotForSignal(id: TweakDBID) -> Int32 {
    let slot: Int32 = 1;
    while slot <= SDPQHDesign.SlotCount() {
      if id == SDPQHDesign.SignalRecord(slot) { return slot; };
      slot += 1;
    };
    return 0;
  }

  public static func DurationIndex(value: Float) -> Int32 {
    if value == 2.00 { return 1; };
    if value == 4.00 { return 2; };
    if value == 8.00 { return 3; };
    return 0;
  }

  public static func AmountIndex(value: Float) -> Int32 {
    if value == 10.00 { return 1; };
    if value == 25.00 { return 2; };
    if value == 50.00 { return 3; };
    return 0;
  }

  // Ordered cheap -> expensive: a shorter pulse interval costs more.
  public static func IntervalIndex(value: Float) -> Int32 {
    if value == 2.00 { return 1; };
    if value == 1.00 { return 2; };
    if value == 0.50 { return 3; };
    return 0;
  }

  public static func LifetimeIndex(seconds: Int32) -> Int32 {
    if seconds == 15 { return 1; };
    if seconds == 30 { return 2; };
    if seconds == 60 { return 3; };
    return 0;
  }

  public static func LifetimeSeconds(index: Int32) -> Int32 {
    if index == 1 { return 15; };
    if index == 3 { return 60; };
    return 30;
  }

  public static func Damaging(payload: Int32) -> Bool {
    return payload == 2 || payload == 3 || payload == 7 || payload == 8;
  }

  // The native reference payload (5) stays a Lab comparison tool.
  public static func ProgramPayload(payload: Int32) -> Bool {
    return payload >= 1 && payload <= 12 && payload != 5;
  }

  // Native behavior (13): a native status with no primitive of ours, worn
  // with its own AI and effects. Only recreations of native programs use it.
  public static func ReferencePayload(payload: Int32) -> Bool {
    return SDPQHDesign.ProgramPayload(payload) || payload == 13;
  }

  public static func MaxReferenceSpread() -> Int32 { return 8; }

  // Native references (NativeReferences.reds) use exact values: any duration up
  // to 600 s, any damage, and an interval of 0 for a single hit.
  public static func ReferenceRuleValid(t: Int32, p: Int32, c: Int32, d: Float, a: Float, i: Float, primary: Bool) -> Bool {
    if t == 0 { return !primary && p == 0 && c == 0; };
    return t >= 1 && t <= 5 && SDPQHDesign.ReferencePayload(p) && c >= 0 && c <= 2
      && d >= 0.00 && d <= 600.00 && a >= 0.00 && a <= 100000.00 && i >= 0.00 && i <= 60.00;
  }

  public static func RuleValid(t: Int32, p: Int32, c: Int32, d: Float, a: Float, i: Float, primary: Bool) -> Bool {
    if SDPQHDesign.DurationIndex(d) == 0 || SDPQHDesign.AmountIndex(a) == 0 || SDPQHDesign.IntervalIndex(i) == 0 { return false; };
    if t == 0 { return !primary && p == 0 && c == 0; };
    return t >= 1 && t <= 5 && SDPQHDesign.ProgramPayload(p) && c >= 0 && c <= 2;
  }

  public static func ParamPoints(t: Int32, p: Int32, d: Float, a: Float, i: Float) -> Int32 {
    if t == 0 { return 0; };
    let points: Int32 = SDPQHDesign.DurationIndex(d) - 1;
    if SDPQHDesign.Damaging(p) {
      points += SDPQHDesign.AmountIndex(a) - 1 + SDPQHDesign.IntervalIndex(i) - 1;
    };
    return points;
  }

  public static func Ram(points: Int32) -> Int32 { return 1 + (points + 1) / 2; }
  public static func UploadTenths(points: Int32) -> Int32 { return 3 + points; }
  public static func Cooldown(points: Int32) -> Int32 { return 4 + 2 * points; }
  public static func Uncommon(points: Int32) -> Int32 { return points; }
  public static func Rare(points: Int32) -> Int32 { return points > 14 ? (points - 13) / 2 : 0; }
  public static func ChipCost() -> Int32 { return 10; }

  public static func UploadText(points: Int32) -> String {
    let tenths: Int32 = SDPQHDesign.UploadTenths(points);
    return IntToString(tenths / 10) + "." + IntToString(tenths % 10) + "s";
  }

  // Whole numbers without decimals, otherwise one or two places: "4", "0.5", "6.25".
  public static func Num(value: Float) -> String {
    let whole: Int32 = RoundF(value);
    if AbsF(value - Cast<Float>(whole)) < 0.005 { return IntToString(whole); };
    let tenths: Int32 = RoundF(value * 10.00);
    if AbsF(value * 10.00 - Cast<Float>(tenths)) < 0.05 { return FloatToStringPrec(value, 1); };
    return FloatToStringPrec(value, 2);
  }

  public static func DurationText(d: Float) -> String { return SDPQHDesign.Num(d) + "s"; }
  public static func AmountText(a: Float) -> String { return SDPQHDesign.Num(a); }
  public static func IntervalText(i: Float) -> String { return SDPQHDesign.Num(i) + "s"; }

  public static func TriggerText(t: Int32) -> String {
    switch t {
      case 1: return "When the target starts reloading";
      case 2: return "When you hit the target with a ranged weapon";
      case 3: return "When you headshot the target";
      case 4: return "On upload";
      case 5: return "3 seconds after upload";
    };
    return "Never";
  }

  public static func PayloadText(p: Int32) -> String {
    switch p {
      case 1: return "blindness";
      case 2: return "thermal damage pulses";
      case 3: return "electrical damage pulses";
      case 4: return "stun";
      case 6: return "movement restriction (speed x0.2)";
      case 7: return "chemical damage pulses";
      case 8: return "physical damage pulses";
      case 9: return "immobilization";
      case 10: return "weapon jam";
      case 11: return "deafness and comms jam";
      case 12: return "cyberware malfunction";
      case 13: return "native behavior";
    };
    return "nothing";
  }

  public static func ConditionText(c: Int32) -> String {
    if c == 1 { return " (only if already blinded)"; };
    if c == 2 { return " (only if already burning)"; };
    return "";
  }

  public static func DamageTypeText(p: Int32) -> String {
    switch p {
      case 2: return "thermal";
      case 3: return "electrical";
      case 7: return "chemical";
      case 8: return "physical";
    };
    return "";
  }

  public static func RuleSentence(t: Int32, p: Int32, c: Int32, d: Float, a: Float, i: Float) -> String {
    let lead: String = SDPQHDesign.TriggerText(t) + SDPQHDesign.ConditionText(c) + ": ";
    if SDPQHDesign.Damaging(p) && i <= 0.00 {
      return lead + SDPQHDesign.AmountText(a) + " base " + SDPQHDesign.DamageTypeText(p) + " damage in one hit.";
    };
    let text: String = lead + SDPQHDesign.PayloadText(p);
    if SDPQHDesign.Damaging(p) {
      text += ", " + SDPQHDesign.AmountText(a) + " base damage every " + SDPQHDesign.IntervalText(i);
    };
    // Native statuses without a fixed duration (recreations only).
    if d >= 600.00 { return text + " with no time limit."; };
    return text + " for " + SDPQHDesign.DurationText(d) + ".";
  }

  public static func RuleSignature(t: Int32, p: Int32, c: Int32, d: Float, a: Float, i: Float) -> String {
    if t == 0 { return "0"; };
    return IntToString(t) + "." + IntToString(p) + "." + IntToString(c) + "." + IntToString(SDPQHDesign.DurationIndex(d))
      + "." + IntToString(SDPQHDesign.AmountIndex(a)) + "." + IntToString(SDPQHDesign.IntervalIndex(i));
  }
}

@addField(PlayerDevelopmentData)
private persistent let m_sdpqhSlots: array<Float>;

@addMethod(PlayerDevelopmentData)
public final func SDPQH_SlotSpec(slot: Int32) -> ref<SDPQHSpec> {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return null; };
  return SDPQHSpec.Read(this.m_sdpqhSlots, (slot - 1) * SDPQHDesign.Stride(), this.SDPQH_SlotLabel(slot));
}

// A null spec clears the slot.
@addMethod(PlayerDevelopmentData)
public final func SDPQH_SetSlotSpec(slot: Int32, spec: ref<SDPQHSpec>) -> Void {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return; };
  let size: Int32 = SDPQHDesign.SlotCount() * SDPQHDesign.Stride();
  while ArraySize(this.m_sdpqhSlots) < size { ArrayPush(this.m_sdpqhSlots, 0.00); };
  let i: Int32 = 0;
  while i < SDPQHDesign.Stride() {
    this.m_sdpqhSlots[(slot - 1) * SDPQHDesign.Stride() + i] = IsDefined(spec) ? spec.F(i) : 0.00;
    i += 1;
  };
  this.SDPQH_SetSlotLabel(slot, IsDefined(spec) ? spec.name : "");
}

// The native program a slot recreates (invalid for designed programs).
@addField(PlayerDevelopmentData)
private persistent let m_sdpqhSlotRefs: array<TweakDBID>;

@addMethod(PlayerDevelopmentData)
public final func SDPQH_SlotRef(slot: Int32) -> TweakDBID {
  return slot >= 1 && slot <= ArraySize(this.m_sdpqhSlotRefs) ? this.m_sdpqhSlotRefs[slot - 1] : t"";
}

@addMethod(PlayerDevelopmentData)
public final func SDPQH_SetSlotRef(slot: Int32, item: TweakDBID) -> Void {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return; };
  while ArraySize(this.m_sdpqhSlotRefs) < SDPQHDesign.SlotCount() { ArrayPush(this.m_sdpqhSlotRefs, t""); };
  this.m_sdpqhSlotRefs[slot - 1] = item;
}

// Records hold global TweakDB values; reapply this save's slots once per player object.
@addField(PlayerPuppet)
private let m_sdpqhApplied: Bool;

@addMethod(PlayerPuppet)
public final func SDPQH_Slot(slot: Int32) -> ref<SDPQHSpec> {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  return IsDefined(data) ? data.SDPQH_SlotSpec(slot) : null;
}

// A reference slot is re-measured from its native program whenever it is used,
// so the recreation follows the player's current stats like the native does.
@addMethod(PlayerPuppet)
public final func SDPQH_SlotReference(slot: Int32) -> ref<SDPQHNativeRef> {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  if !IsDefined(data) { return null; };
  let item: TweakDBID = data.SDPQH_SlotRef(slot);
  if !TDBID.IsValid(item) { return null; };
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  if !IsDefined(spec) || !spec.Present() || !spec.Reference() { return null; };
  return SDPQHNativeRef.FromItem(this, item);
}

// The spec a slot runs: live values for a reference, the stored design otherwise.
@addMethod(PlayerPuppet)
public final func SDPQH_LiveSlot(slot: Int32) -> ref<SDPQHSpec> {
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  if !IsDefined(spec) || !spec.Present() || !spec.Reference() { return spec; };
  let reference: ref<SDPQHNativeRef> = this.SDPQH_SlotReference(slot);
  if !IsDefined(reference) || !reference.Supported() { return spec; };
  let live: ref<SDPQHSpec> = reference.Spec();
  live.name = spec.name;
  return live;
}

@addMethod(PlayerPuppet)
public final func SDPQH_IsCompiled(slot: Int32) -> Bool {
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  return IsDefined(spec) && spec.Present();
}

@addMethod(PlayerPuppet)
public final func SDPQH_SlotSignature(slot: Int32) -> String {
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  return IsDefined(spec) && spec.Present() ? spec.Signature() : "";
}

@addMethod(PlayerPuppet)
public final func SDPQH_SlotName(slot: Int32) -> String {
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  if !IsDefined(spec) || !spec.Present() { return "Blank program " + SDPQHDesign.Letter(slot); };
  return StrLen(spec.name) > 0 ? spec.name : "Custom program " + SDPQHDesign.Letter(slot);
}

// Starts with the slot letter so chips never read alike.
@addMethod(PlayerPuppet)
public final func SDPQH_SlotDescription(slot: Int32) -> String {
  let spec: ref<SDPQHSpec> = this.SDPQH_LiveSlot(slot);
  let lead: String = "Program " + SDPQHDesign.Letter(slot) + ": ";
  if !IsDefined(spec) || !spec.Present() {
    return lead + "blank chip. Compile a design into slot " + SDPQHDesign.Letter(slot)
      + " from Crafting > Quickhack Designer to load it.";
  };
  if spec.Reference() {
    let reference: ref<SDPQHNativeRef> = this.SDPQH_SlotReference(slot);
    return lead + spec.name + ", rebuilt from our primitives with the native program's values and looks.\n"
      + (IsDefined(reference) ? reference.Description() : spec.Description());
  };
  return lead + spec.name + ".\n" + spec.Description();
}

// Name and summary also live in global TweakDB flats so static UI paths
// (item names and tooltips without an owner) can read them.
@addMethod(PlayerPuppet)
private final func SDPQH_ApplySlot(slot: Int32) -> Void {
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  let compiled: Bool = IsDefined(spec) && spec.Present();
  let points: Int32 = compiled ? spec.Points() : 0;
  let ram: Float = compiled ? Cast<Float>(SDPQHDesign.Ram(points)) : 2.00;
  let upload: Float = Cast<Float>(SDPQHDesign.UploadTenths(points)) / 10.00;
  let cooldown: Float = Cast<Float>(SDPQHDesign.Cooldown(points));
  // A reference costs what the native program costs: base RAM, base upload
  // constant and the program's own cooldown. Shared perk modifiers still apply.
  let reference: ref<SDPQHNativeRef> = compiled && spec.Reference() ? this.SDPQH_SlotReference(slot) : null;
  if IsDefined(reference) {
    ram = reference.ramBase;
    upload = reference.uploadBase;
    cooldown = reference.cooldown;
  };
  SDPQHRecordBuilder.ApplyNative(slot, IsDefined(reference) ? TweakDBInterface.GetObjectActionRecord(reference.action) : null);
  TweakDBManager.SetFlat(SDPQHDesign.Record("CustomHack", slot, "_Ram.value"), ToVariant(ram));
  TweakDBManager.UpdateRecord(SDPQHDesign.Record("CustomHack", slot, "_Ram"));
  TweakDBManager.SetFlat(SDPQHDesign.Record("CustomHack", slot, "_Upload.value"), ToVariant(upload));
  TweakDBManager.UpdateRecord(SDPQHDesign.Record("CustomHack", slot, "_Upload"));
  TweakDBManager.SetFlat(SDPQHDesign.Record("CustomHack", slot, "_CooldownTime.value"), ToVariant(cooldown));
  TweakDBManager.UpdateRecord(SDPQHDesign.Record("CustomHack", slot, "_CooldownTime"));
  TweakDBManager.SetFlat(SDPQHDesign.SummaryFlat(slot), ToVariant(this.SDPQH_SlotDescription(slot)));
  TweakDBManager.SetFlat(SDPQHDesign.LabelFlat(slot), ToVariant(compiled ? this.SDPQH_SlotName(slot) : ""));
}

@addMethod(PlayerPuppet)
public final func SDPQH_EnsureApplied() -> Void {
  if this.m_sdpqhApplied { return; };
  this.m_sdpqhApplied = true;
  let slot: Int32 = 1;
  while slot <= SDPQHDesign.SlotCount() {
    this.SDPQH_ApplySlot(slot);
    slot += 1;
  };
}

@addMethod(PlayerPuppet)
private final func SDPQH_Material(rare: Bool) -> ItemID {
  return ItemID.FromTDBID(rare ? t"Items.QuickHackRareMaterial1" : t"Items.QuickHackUncommonMaterial1");
}

@addMethod(PlayerPuppet)
public final func SDPQH_MaterialCount(rare: Bool) -> Int32 {
  return GameInstance.GetTransactionSystem(this.GetGame()).GetItemQuantity(this, this.SDPQH_Material(rare));
}

@addMethod(PlayerPuppet)
private final func SDPQH_Spend(rare: Bool, amount: Int32) -> Void {
  if amount > 0 { GameInstance.GetTransactionSystem(this.GetGame()).RemoveItem(this, this.SDPQH_Material(rare), amount); };
}

@addMethod(PlayerPuppet)
public final func SDPQH_CompileSpec(slot: Int32, spec: ref<SDPQHSpec>, free: Bool) -> String {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return "Unknown program slot."; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  if !IsDefined(data) || !IsDefined(spec) { return "Character data unavailable; load a save first."; };
  let problem: String = spec.Problem();
  if StrLen(problem) > 0 { return "Design rejected: " + problem; };
  let points: Int32 = spec.Points();
  let uncommon: Int32 = SDPQHDesign.Uncommon(points);
  let rare: Int32 = SDPQHDesign.Rare(points);
  if !free && (this.SDPQH_MaterialCount(false) < uncommon || this.SDPQH_MaterialCount(true) < rare) {
    return "Compiling needs " + IntToString(uncommon) + " uncommon" + (rare > 0 ? " and " + IntToString(rare) + " rare" : "")
      + " quickhack components.";
  };
  if !free {
    this.SDPQH_Spend(false, uncommon);
    this.SDPQH_Spend(true, rare);
  };
  let stored: ref<SDPQHSpec> = spec.Copy();
  stored.Set(0, 1.00);
  stored.Set(15, 0.00);
  data.SDPQH_SetSlotSpec(slot, stored);
  data.SDPQH_SetSlotRef(slot, t"");
  this.SDPQH_ApplySlot(slot);
  return "Compiled " + spec.name + " into program " + SDPQHDesign.Letter(slot) + ": " + IntToString(SDPQHDesign.Ram(points)) + " RAM, "
    + SDPQHDesign.UploadText(points) + " upload, " + IntToString(SDPQHDesign.Cooldown(points)) + "s cooldown"
    + (free ? " (free mode)." : ".");
}

@addMethod(PlayerPuppet)
public final func SDPQH_CompileDesign(slot: Int32, index: Int32, free: Bool) -> String {
  let spec: ref<SDPQHSpec> = this.SDPQH_Design(index);
  if !IsDefined(spec) { return "Pick a design first."; };
  return this.SDPQH_CompileSpec(slot, spec, free);
}

@addMethod(PlayerPuppet)
public final func SDPQH_ClearSlot(slot: Int32) -> String {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  if !IsDefined(data) || slot < 1 || slot > SDPQHDesign.SlotCount() { return "Unknown program slot."; };
  data.SDPQH_SetSlotSpec(slot, null);
  data.SDPQH_SetSlotRef(slot, t"");
  this.SDPQH_ApplySlot(slot);
  return "Program " + SDPQHDesign.Letter(slot) + " cleared. Its chip stays installed but does nothing until recompiled.";
}

// Loads a native reference into a slot. References are a comparison tool, so
// compiling one costs no components; the chip itself still has to be made.
@addMethod(PlayerPuppet)
public final func SDPQH_CompileReferenceItem(slot: Int32, item: TweakDBID) -> String {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return "Unknown program slot."; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  if !IsDefined(data) { return "Character data unavailable; load a save first."; };
  let reference: ref<SDPQHNativeRef> = SDPQHNativeRef.FromItem(this, item);
  if !IsDefined(reference) { return "That native program could not be read."; };
  if !reference.Supported() { return reference.Title() + " has no effect our primitives can recreate yet."; };
  let spec: ref<SDPQHSpec> = reference.Spec();
  let problem: String = spec.Problem();
  if StrLen(problem) > 0 { return "Reference rejected: " + problem; };
  data.SDPQH_SetSlotSpec(slot, spec);
  data.SDPQH_SetSlotRef(slot, item);
  this.SDPQH_ApplySlot(slot);
  return "Program " + SDPQHDesign.Letter(slot) + " now recreates " + reference.Title() + ": " + IntToString(reference.ram) + " RAM, "
    + SDPQHDesign.Num(reference.upload) + "s upload, " + SDPQHDesign.Num(reference.cooldown) + "s cooldown, as the native program."
    + " Upload both and compare them in the meter.";
}

@addMethod(PlayerPuppet)
public final func SDPQH_FabricateChip(slot: Int32, free: Bool) -> String {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return "Unknown program slot."; };
  if !IsDefined(TweakDBInterface.GetItemRecord(SDPQHDesign.ItemRecord(slot))) {
    return "Program chip record missing. Deploy CustomPrograms.yaml with the scripts.";
  };
  if !free && this.SDPQH_MaterialCount(false) < SDPQHDesign.ChipCost() {
    return "A program chip needs " + IntToString(SDPQHDesign.ChipCost()) + " uncommon quickhack components.";
  };
  if !GameInstance.GetTransactionSystem(this.GetGame()).GiveItem(this, ItemID.FromTDBID(SDPQHDesign.ItemRecord(slot)), 1) {
    return "The game refused to create the chip.";
  };
  if !free { this.SDPQH_Spend(false, SDPQHDesign.ChipCost()); };
  return "Program chip " + SDPQHDesign.Letter(slot) + " added to your inventory. Install it in your cyberdeck.";
}

@addMethod(PlayerPuppet)
public final func SDPQH_ChipInstalled(slot: Int32) -> Bool {
  let list: array<PlayerQuickhackData> = RPGManager.GetPlayerQuickHackListWithQuality(this);
  let i: Int32 = 0;
  while i < ArraySize(list) {
    if IsDefined(list[i].actionRecord) && list[i].actionRecord.GetID() == SDPQHDesign.ActionRecord(slot) { return true; };
    i += 1;
  };
  return false;
}

@addMethod(PlayerPuppet)
public final func SDPQH_ChipCount(slot: Int32) -> Int32 {
  return GameInstance.GetTransactionSystem(this.GetGame()).GetItemQuantity(this, ItemID.FromTDBID(SDPQHDesign.ItemRecord(slot)));
}

@addMethod(PlayerPuppet)
public final func SDPQH_SlotStatus(slot: Int32) -> String {
  if slot < 1 || slot > SDPQHDesign.SlotCount() { return "Unknown slot."; };
  this.SDPQH_EnsureApplied();
  let chip: String = (this.SDPQH_ChipInstalled(slot) ? "installed in deck" : "not installed")
    + ", " + IntToString(this.SDPQH_ChipCount(slot)) + " spare in inventory";
  let spec: ref<SDPQHSpec> = this.SDPQH_Slot(slot);
  if !IsDefined(spec) || !spec.Present() { return "Blank | chip " + chip; };
  if spec.Reference() {
    let reference: ref<SDPQHNativeRef> = this.SDPQH_SlotReference(slot);
    if !IsDefined(reference) { return "Native reference (program record missing) | chip " + chip; };
    return "Native reference | " + IntToString(reference.ram) + " RAM | " + SDPQHDesign.Num(reference.upload) + "s upload | "
      + SDPQHDesign.Num(reference.cooldown) + "s cooldown | chip " + chip;
  };
  let points: Int32 = spec.Points();
  return "Compiled | " + IntToString(SDPQHDesign.Ram(points)) + " RAM | " + SDPQHDesign.UploadText(points) + " upload | "
    + IntToString(SDPQHDesign.Cooldown(points)) + "s cooldown | chip " + chip;
}

@addMethod(PlayerPuppet)
public final func SDPQH_Components() -> String {
  return IntToString(this.SDPQH_MaterialCount(false)) + " uncommon, " + IntToString(this.SDPQH_MaterialCount(true)) + " rare quickhack components";
}

// Called when a program chip's upload completes on a target.
@addMethod(PlayerPuppet)
public final func SDPQH_Execute(slot: Int32, target: ref<NPCPuppet>) -> Void {
  if !SDPPrototypeRuntime.Alive(target) { return; };
  let spec: ref<SDPQHSpec> = this.SDPQH_LiveSlot(slot);
  if !IsDefined(spec) || !spec.Present() {
    this.SDP_PrototypeNotify("Program " + SDPQHDesign.Letter(slot) + " is blank. Compile a design into it first.");
    return;
  };
  if !IsDefined(this.m_sdpPrototype) { this.m_sdpPrototype = new SDPPrototypeRuntime(); };
  let runtime: ref<SDPPrototypeRuntime> = this.m_sdpPrototype;
  let first: ref<SDPPrototypeRule> = spec.Rule(true);
  let second: ref<SDPPrototypeRule> = spec.Rule(false);
  let extra: array<ref<SDPPrototypeRule>>;
  let reference: ref<SDPQHNativeRef> = spec.Reference() ? this.SDPQH_SlotReference(slot) : null;
  if IsDefined(reference) && reference.Supported() {
    // A recreation runs every native part on upload: the first two as the
    // program's rules, the rest alongside them, each wearing its native look.
    let rules: array<ref<SDPPrototypeRule>> = reference.Rules();
    first = rules[0];
    second = ArraySize(rules) > 1 ? rules[1] : SDPPrototypeRuntime.Rule(0, 0, 0);
    let r: Int32 = 2;
    while r < ArraySize(rules) {
      ArrayPush(extra, rules[r]);
      r += 1;
    };
  };
  let expires: Float = SDPPrototypeRuntime.Now(this) + Cast<Float>(spec.LifetimeSeconds());
  let installed: array<ref<NPCPuppet>>;
  if !IsDefined(runtime.InstallProgram(this, target, first, second, expires)) { return; };
  ArrayPush(installed, target);
  let spread: Int32 = spec.Spread();
  let range: Float = 8.00;
  if IsDefined(reference) {
    // As SpreadInitEffector rolls it at upload.
    spread = Min(reference.spread + reference.OverclockSpread(this), SDPQHDesign.MaxReferenceSpread());
    if reference.spreadRange > 0.00 { range = reference.spreadRange; };
  };
  if spread > 0 {
    let query: TargetSearchQuery;
    query.testedSet = TargetingSet.Complete;
    query.maxDistance = 40.00;
    query.filterObjectByDistance = true;
    query.includeSecondaryTargets = false;
    query.ignoreInstigator = true;
    let parts: array<TS_TargetPartInfo>;
    GameInstance.GetTargetingSystem(this.GetGame()).GetTargetParts(this, query, parts);
    let i: Int32 = 0;
    while i < ArraySize(parts) && ArraySize(installed) <= spread {
      let component: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
      if IsDefined(component) {
        let other: ref<NPCPuppet> = component.GetEntity() as NPCPuppet;
        if SDPPrototypeRuntime.SpreadEligible(this, other) && !ArrayContains(installed, other)
          && Vector4.Distance(target.GetWorldPosition(), other.GetWorldPosition()) <= range
          && IsDefined(runtime.InstallProgram(this, other, first, second, expires)) {
          ArrayPush(installed, other);
        };
      };
      i += 1;
    };
  };
  // Each host spends its own charges; upload rules fire on every recipient.
  let n: Int32 = 0;
  while n < ArraySize(installed) {
    this.SDPQH_MeterProgram(installed[n], "Program " + SDPQHDesign.Letter(slot) + ": " + spec.name);
    // Conditional parts in native completion order: those listed before the
    // statuses read what was already on the target (Cyberware Malfunction's
    // stack ladder), the rest read the upload's own statuses too.
    if IsDefined(reference) { reference.RunConditional(this, runtime, installed[n], false); };
    runtime.Dispatch(this, installed[n], 4, null);
    let e: Int32 = 0;
    while e < ArraySize(extra) {
      runtime.Apply(this, installed[n], extra[e]);
      e += 1;
    };
    if IsDefined(reference) {
      reference.RunConditional(this, runtime, installed[n], true);
      // The native program's own completion effectors, on every recipient as its spread action does.
      let p: Int32 = 0;
      while p < ArraySize(reference.ports) {
        SDPQHPorts.Run(this, installed[n], reference.ports[p]);
        p += 1;
      };
    };
    n += 1;
  };
  let running: String = spec.Reference() ? " recreation running" : " running for " + IntToString(spec.LifetimeSeconds()) + "s";
  this.SDP_PrototypeNotify(this.SDPQH_SlotName(slot) + running
    + (ArraySize(installed) > 1 ? "; spread to " + IntToString(ArraySize(installed) - 1) + " more" : "") + ".");
}

@addMethod(PlayerPuppet)
public final func SDPQH_DecorateCommand(slot: Int32, command: ref<QuickhackData>) -> Void {
  command.m_title = this.SDPQH_SlotName(slot);
  command.m_description = this.SDPQH_SlotDescription(slot);
  let spec: ref<SDPQHSpec> = this.SDPQH_LiveSlot(slot);
  if !IsDefined(spec) || !spec.Present() {
    command.m_isLocked = true;
    command.m_actionState = EActionInactivityReson.Locked;
    command.m_inactiveReason = "Blank program: compile a design in Crafting > Quickhack Designer.";
    if IsDefined(command.m_action) {
      (command.m_action as PuppetAction).SetInactiveWithReason(false, command.m_inactiveReason);
    };
    return;
  };
  let reference: ref<SDPQHNativeRef> = spec.Reference() ? this.SDPQH_SlotReference(slot) : null;
  command.m_duration = IsDefined(reference) ? reference.duration : (spec.Reference() ? spec.MaxDuration() : Cast<Float>(spec.LifetimeSeconds()));
}

// Program chips reach the target through its object actions, matched by action
// name. Offer ours to any NPC that already exposes puppet quickhacks.
@wrapMethod(ScriptedPuppetPS)
public final const func GetAllChoices(const actions: script_ref<[wref<ObjectAction_Record>]>, const context: script_ref<GetActionsContext>, puppetActions: script_ref<[ref<PuppetAction>]>) -> Void {
  let hackable: Bool = false;
  let i: Int32 = 0;
  while i < ArraySize(Deref(actions)) && !hackable {
    if IsDefined(Deref(actions)[i]) && IsDefined(Deref(actions)[i].ObjectActionType())
      && Equals(Deref(actions)[i].ObjectActionType().Type(), gamedataObjectActionType.PuppetQuickHack) {
      hackable = true;
    };
    i += 1;
  };
  if !hackable {
    wrappedMethod(actions, context, puppetActions);
    return;
  };
  let extended: array<wref<ObjectAction_Record>> = Deref(actions);
  let slot: Int32 = 1;
  while slot <= SDPQHDesign.SlotCount() {
    let record: wref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(SDPQHDesign.ActionRecord(slot));
    if IsDefined(record) && !ArrayContains(extended, record) { ArrayPush(extended, record); };
    slot += 1;
  };
  wrappedMethod(extended, context, puppetActions);
}

@wrapMethod(ScriptedPuppet)
private final func TranslateChoicesIntoQuickSlotCommands(const puppetActions: script_ref<[ref<PuppetAction>]>, commands: script_ref<[ref<QuickhackData>]>) -> Void {
  let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
  // Costs and upload times are read from records inside the native builder.
  if IsDefined(player) { player.SDPQH_EnsureApplied(); };
  wrappedMethod(puppetActions, commands);
  if !IsDefined(player) { return; };
  let i: Int32 = 0;
  while i < ArraySize(Deref(commands)) {
    let command: ref<QuickhackData> = Deref(commands)[i];
    let slot: Int32 = IsDefined(command) ? SDPQHDesign.SlotForItem(ItemID.GetTDBID(command.m_itemID)) : 0;
    if slot > 0 { player.SDPQH_DecorateCommand(slot, command); };
    i += 1;
  };
}

@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  if IsDefined(evt) && IsDefined(evt.staticData) && evt.staticData.GameplayTagsContains(n"SDPCustomHack") {
    let slot: Int32 = SDPQHDesign.SlotForSignal(evt.staticData.GetID());
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    if slot > 0 && IsDefined(player) && evt.instigatorEntityID == player.GetEntityID() {
      player.SDPQH_Execute(slot, this);
    };
  };
  return result;
}

// Item names and descriptions for the program chips in inventory and tooltips.
public func SDPQH_ChipName(name: String, id: TweakDBID) -> String {
  let slot: Int32 = SDPQHDesign.SlotForItem(id);
  if slot == 0 { return name; };
  let label: String = TweakDBInterface.GetString(SDPQHDesign.LabelFlat(slot), "");
  return "Program " + SDPQHDesign.Letter(slot) + ": " + (StrLen(label) > 0 ? label : "Custom quickhack");
}

public func SDPQH_ChipDescription(description: String, id: TweakDBID) -> String {
  let slot: Int32 = SDPQHDesign.SlotForItem(id);
  if slot == 0 { return description; };
  let summary: String = TweakDBInterface.GetString(SDPQHDesign.SummaryFlat(slot), "");
  return StrLen(summary) > 0 ? summary : "Designed quickhack chip. Compile a design into slot " + SDPQHDesign.Letter(slot) + " in Crafting > Quickhack Designer.";
}

@wrapMethod(UIInventoryItem)
public final func GetName() -> String {
  return SDPQH_ChipName(wrappedMethod(), this.GetTweakDBID());
}

@wrapMethod(UIInventoryItem)
public final func GetDescription() -> String {
  return SDPQH_ChipDescription(wrappedMethod(), this.GetTweakDBID());
}

@wrapMethod(InventoryItemData)
public final static func GetName(const self: script_ref<InventoryItemData>) -> String {
  return SDPQH_ChipName(wrappedMethod(self), ItemID.GetTDBID(InventoryItemData.GetID(self)));
}

@wrapMethod(InventoryItemData)
public final static func GetDescription(const self: script_ref<InventoryItemData>) -> String {
  return SDPQH_ChipDescription(wrappedMethod(self), ItemID.GetTDBID(InventoryItemData.GetID(self)));
}

// Program tooltips read duration and damage from the action's completion
// effects, which for a chip is only its 1 s upload signal. Show the program's.
@wrapMethod(UIInventoryItemProgramData)
public final static func Make(itemRecord: wref<Item_Record>, player: wref<PlayerPuppet>) -> ref<UIInventoryItemProgramData> {
  let data: ref<UIInventoryItemProgramData> = wrappedMethod(itemRecord, player);
  let slot: Int32 = IsDefined(itemRecord) ? SDPQHDesign.SlotForItem(itemRecord.GetID()) : 0;
  if slot == 0 || !IsDefined(data) || !IsDefined(player) { return data; };
  let spec: ref<SDPQHSpec> = player.SDPQH_LiveSlot(slot);
  if !IsDefined(spec) || !spec.Present() { return data; };
  let reference: ref<SDPQHNativeRef> = spec.Reference() ? player.SDPQH_SlotReference(slot) : null;
  data.Duration = IsDefined(reference) ? reference.duration : (spec.Reference() ? spec.MaxDuration() : Cast<Float>(spec.LifetimeSeconds()));
  let native: ref<Item_Record> = IsDefined(reference) ? TweakDBInterface.GetItemRecord(reference.item) : null;
  if IsDefined(native) {
    let nativeData: ref<UIInventoryItemProgramData> = UIInventoryItemProgramData.Make(native, player);
    if IsDefined(nativeData) { data.AttackEffects = nativeData.AttackEffects; };
  };
  return data;
}

@wrapMethod(InventoryTooltipData)
public final static func FromInventoryItemData(const itemData: script_ref<InventoryItemData>) -> ref<InventoryTooltipData> {
  let tooltip: ref<InventoryTooltipData> = wrappedMethod(itemData);
  let id: TweakDBID = ItemID.GetTDBID(InventoryItemData.GetID(itemData));
  if IsDefined(tooltip) && SDPQHDesign.SlotForItem(id) > 0 {
    tooltip.itemName = SDPQH_ChipName(tooltip.itemName, id);
    tooltip.description = SDPQH_ChipDescription(tooltip.description, id);
  };
  return tooltip;
}
