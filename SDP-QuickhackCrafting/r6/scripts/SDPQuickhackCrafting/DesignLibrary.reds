// Quickhack designs stored in the save. One value layout serves both the design
// library and the compiled program slots (SDPQHDesign.Stride()):
// [0] present, [1] lifetime index 1-3, [2] spread,
// [3-8] first rule {trigger, payload, condition, duration, amount, interval},
// [9-14] second rule, [15] reserved.
// Mirrors quickhack_designs.lua (validation, points, signature, starters).
module SkillDrivenProgression

public class SDPQHSpec extends IScriptable {
  public let v: array<Float>;
  public let name: String;

  public static func Make(name: String, t1: Int32, p1: Int32, c1: Int32, d1: Float, a1: Float, i1: Float,
      t2: Int32, p2: Int32, c2: Int32, d2: Float, a2: Float, i2: Float, life: Int32, spread: Int32) -> ref<SDPQHSpec> {
    let spec: ref<SDPQHSpec> = new SDPQHSpec();
    spec.name = name;
    ArrayPush(spec.v, 1.00);
    ArrayPush(spec.v, Cast<Float>(life));
    ArrayPush(spec.v, Cast<Float>(spread));
    ArrayPush(spec.v, Cast<Float>(t1)); ArrayPush(spec.v, Cast<Float>(p1)); ArrayPush(spec.v, Cast<Float>(c1));
    ArrayPush(spec.v, d1); ArrayPush(spec.v, a1); ArrayPush(spec.v, i1);
    ArrayPush(spec.v, Cast<Float>(t2)); ArrayPush(spec.v, Cast<Float>(p2)); ArrayPush(spec.v, Cast<Float>(c2));
    ArrayPush(spec.v, d2); ArrayPush(spec.v, a2); ArrayPush(spec.v, i2);
    ArrayPush(spec.v, 0.00);
    return spec;
  }

  // Same as quickhack_designs.lua M.new(): an on-upload blindness program.
  public static func Default(name: String) -> ref<SDPQHSpec> {
    return SDPQHSpec.Make(name, 4, 1, 0, 4.00, 25.00, 1.00, 0, 0, 0, 4.00, 25.00, 1.00, 2, 0);
  }

  public static func Read(const source: script_ref<[Float]>, base: Int32, name: String) -> ref<SDPQHSpec> {
    let spec: ref<SDPQHSpec> = new SDPQHSpec();
    spec.name = name;
    let i: Int32 = 0;
    while i < SDPQHDesign.Stride() {
      ArrayPush(spec.v, base + i < ArraySize(Deref(source)) ? Deref(source)[base + i] : 0.00);
      i += 1;
    };
    return spec;
  }

  public final func Copy() -> ref<SDPQHSpec> {
    let spec: ref<SDPQHSpec> = new SDPQHSpec();
    spec.name = this.name;
    spec.v = this.v;
    return spec;
  }

  public final func F(k: Int32) -> Float { return k >= 0 && k < ArraySize(this.v) ? this.v[k] : 0.00; }
  public final func I(k: Int32) -> Int32 { return Cast<Int32>(this.F(k)); }
  public final func Set(k: Int32, value: Float) -> Void { if k >= 0 && k < ArraySize(this.v) { this.v[k] = value; }; }
  public final func Present() -> Bool { return this.F(0) > 0.50; }
  public final func LifetimeIndex() -> Int32 { return this.I(1); }
  public final func LifetimeSeconds() -> Int32 { return SDPQHDesign.LifetimeSeconds(this.I(1)); }
  public final func Spread() -> Int32 { return this.I(2); }

  // Offset of a rule's first value: 3 for the primary rule, 9 for the secondary.
  public final static func RuleBase(first: Bool) -> Int32 { return first ? 3 : 9; }

  public final func RuleValid(first: Bool) -> Bool {
    let o: Int32 = SDPQHSpec.RuleBase(first);
    return SDPQHDesign.RuleValid(this.I(o), this.I(o + 1), this.I(o + 2), this.F(o + 3), this.F(o + 4), this.F(o + 5), first);
  }

  public final func Complexity() -> Int32 {
    return SDPPrototypeRuntime.Cost(this.I(3), this.I(4), this.I(5)) + SDPPrototypeRuntime.Cost(this.I(9), this.I(10), this.I(11));
  }

  public final func Points() -> Int32 {
    return this.Complexity()
      + SDPQHDesign.ParamPoints(this.I(3), this.I(4), this.F(6), this.F(7), this.F(8))
      + SDPQHDesign.ParamPoints(this.I(9), this.I(10), this.F(12), this.F(13), this.F(14))
      + 2 * this.Spread() + this.LifetimeIndex() - 1;
  }

  // Empty when the design can be compiled. Messages match quickhack_designs.lua.
  public final func Problem() -> String {
    if StrLen(this.name) == 0 { return "Name the design."; };
    if !this.RuleValid(true) || !this.RuleValid(false) { return "Choose valid components and a primary rule."; };
    if this.I(3) == this.I(9) && this.I(4) == this.I(10) && this.I(5) == this.I(11) { return "Duplicate rules are not supported."; };
    if this.Complexity() > 12 { return "Complexity exceeds 12. Use a headshot trigger or remove a rule."; };
    if this.I(1) < 1 || this.I(1) > 3 { return "Choose a program lifetime of 15, 30 or 60 seconds."; };
    if this.Spread() < 0 || this.Spread() > 3 { return "Spread must be 0 to 3 targets."; };
    return "";
  }

  public final func Signature() -> String {
    return SDPQHDesign.RuleSignature(this.I(3), this.I(4), this.I(5), this.F(6), this.F(7), this.F(8))
      + "|" + SDPQHDesign.RuleSignature(this.I(9), this.I(10), this.I(11), this.F(12), this.F(13), this.F(14))
      + "|" + IntToString(this.I(1)) + "|" + IntToString(this.Spread());
  }

  public final func Description() -> String {
    let text: String = SDPQHDesign.RuleSentence(this.I(3), this.I(4), this.I(5), this.F(6), this.F(7), this.F(8));
    if this.I(9) != 0 {
      text += "\n" + SDPQHDesign.RuleSentence(this.I(9), this.I(10), this.I(11), this.F(12), this.F(13), this.F(14));
    };
    text += "\nProgram runs " + IntToString(this.LifetimeSeconds()) + "s with 3 charges per rule.";
    let spread: Int32 = this.Spread();
    if spread > 0 {
      text += " On upload it spreads to " + IntToString(spread) + " nearby " + (spread == 1 ? "enemy" : "enemies") + " within 8m.";
    };
    return text;
  }

  public final func Rule(first: Bool) -> ref<SDPPrototypeRule> {
    let o: Int32 = SDPQHSpec.RuleBase(first);
    let rule: ref<SDPPrototypeRule> = SDPPrototypeRuntime.Rule(this.I(o), this.I(o + 1), this.I(o + 2));
    rule.duration = this.F(o + 3);
    rule.amount = this.F(o + 4);
    rule.interval = this.F(o + 5);
    return rule;
  }

  // Starter designs: the lab presets that use only designed primitives
  // (quickhack_designs.lua M.starters()). Lifetime 30 s, no spread.
  public final static func Starters() -> array<ref<SDPQHSpec>> {
    let list: array<ref<SDPQHSpec>>;
    ArrayPush(list, SDPQHSpec.Make("Empty Chamber", 1, 1, 0, 4.00, 25.00, 1.00, 3, 2, 1, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Blackout Gun", 3, 1, 0, 4.00, 25.00, 1.00, 3, 2, 1, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Heat Response", 2, 2, 0, 4.00, 25.00, 1.00, 3, 1, 2, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Reload Blackout", 1, 1, 0, 4.00, 25.00, 1.00, 0, 0, 0, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Optics core", 4, 1, 0, 4.00, 25.00, 1.00, 0, 0, 0, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Thermal core", 4, 2, 0, 4.00, 25.00, 1.00, 0, 0, 0, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Shock core", 4, 3, 0, 4.00, 25.00, 1.00, 0, 0, 0, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Delayed Flash", 5, 1, 0, 4.00, 25.00, 1.00, 5, 4, 0, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Burning Trap", 4, 2, 0, 4.00, 25.00, 1.00, 3, 4, 2, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Cripple core", 4, 6, 0, 4.00, 25.00, 1.00, 0, 0, 0, 4.00, 25.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Caustic blackout", 4, 1, 0, 8.00, 25.00, 1.00, 4, 7, 0, 8.00, 10.00, 1.00, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Headshot furnace", 4, 6, 0, 8.00, 25.00, 1.00, 3, 2, 0, 4.00, 50.00, 0.50, 2, 0));
    ArrayPush(list, SDPQHSpec.Make("Reload Shock", 1, 3, 0, 4.00, 25.00, 1.00, 3, 1, 0, 4.00, 25.00, 1.00, 2, 0));
    return list;
  }
}

// Strings cannot be persistent, so names are saved as character codes:
// SDPQHDesign.MaxName() codes per name, 1-based indices into Charset(), 0 ends.
public abstract class SDPQHNames {
  public static func Charset() -> String {
    return " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;!?'-_+*/()&#%@<>=";
  }

  public static func Write(codes: script_ref<[Int32]>, base: Int32, name: String) -> Void {
    let charset: String = SDPQHNames.Charset();
    let unknown: Int32 = StrFindFirst(charset, "?") + 1;
    let width: Int32 = SDPQHDesign.MaxName();
    while ArraySize(Deref(codes)) < base + width { ArrayPush(Deref(codes), 0); };
    let i: Int32 = 0;
    while i < width {
      let code: Int32 = 0;
      if i < StrLen(name) {
        code = StrFindFirst(charset, StrMid(name, i, 1)) + 1;
        if code <= 0 { code = unknown; };
      };
      Deref(codes)[base + i] = code;
      i += 1;
    };
  }

  public static func Read(const codes: script_ref<[Int32]>, base: Int32) -> String {
    let charset: String = SDPQHNames.Charset();
    let name: String = "";
    let i: Int32 = 0;
    while i < SDPQHDesign.MaxName() && base + i < ArraySize(Deref(codes)) {
      let code: Int32 = Deref(codes)[base + i];
      if code <= 0 || code > StrLen(charset) { return name; };
      name += StrMid(charset, code - 1, 1);
      i += 1;
    };
    return name;
  }
}

@addField(PlayerDevelopmentData)
private persistent let m_sdpqhDesigns: array<Float>;

@addField(PlayerDevelopmentData)
private persistent let m_sdpqhDesignNames: array<Int32>;

@addField(PlayerDevelopmentData)
private persistent let m_sdpqhSeeded: Bool;

@addField(PlayerDevelopmentData)
private persistent let m_sdpqhSlotNames: array<Int32>;

// Bumped on every library change so CET and open menus can refresh.
@addField(PlayerDevelopmentData)
private let m_sdpqhRevision: Int32;

// Starts at a random value so a different save never looks unchanged to CET.
@addMethod(PlayerDevelopmentData)
public final func SDPQH_Revision() -> Int32 {
  if this.m_sdpqhRevision == 0 { this.m_sdpqhRevision = RandRange(1, 1000000000); };
  return this.m_sdpqhRevision;
}

@addMethod(PlayerDevelopmentData)
private final func SDPQH_Touch() -> Void { this.m_sdpqhRevision = this.SDPQH_Revision() + 1; }

// A new save starts with the starter designs, once.
@addMethod(PlayerDevelopmentData)
public final func SDPQH_EnsureSeeded() -> Void {
  if this.m_sdpqhSeeded { return; };
  this.m_sdpqhSeeded = true;
  let starters: array<ref<SDPQHSpec>> = SDPQHSpec.Starters();
  let i: Int32 = 0;
  while i < ArraySize(starters) {
    this.SDPQH_StoreDesign(-1, starters[i]);
    i += 1;
  };
  this.SDPQH_Touch();
}

// Names may be missing if a save predates them; numbers decide the count.
@addMethod(PlayerDevelopmentData)
public final func SDPQH_DesignCount() -> Int32 {
  this.SDPQH_EnsureSeeded();
  return ArraySize(this.m_sdpqhDesigns) / SDPQHDesign.Stride();
}

@addMethod(PlayerDevelopmentData)
public final func SDPQH_Design(index: Int32) -> ref<SDPQHSpec> {
  if index < 0 || index >= this.SDPQH_DesignCount() { return null; };
  let name: String = SDPQHNames.Read(this.m_sdpqhDesignNames, index * SDPQHDesign.MaxName());
  if StrLen(name) == 0 { name = "Design " + IntToString(index + 1); };
  return SDPQHSpec.Read(this.m_sdpqhDesigns, index * SDPQHDesign.Stride(), name);
}

// Replaces design `index`, or appends when index is outside the library.
// Returns the stored index, or -1 when the library is full.
@addMethod(PlayerDevelopmentData)
public final func SDPQH_StoreDesign(index: Int32, spec: ref<SDPQHSpec>) -> Int32 {
  if !IsDefined(spec) { return -1; };
  let count: Int32 = ArraySize(this.m_sdpqhDesigns) / SDPQHDesign.Stride();
  if index < 0 || index >= count {
    if count >= SDPQHDesign.MaxDesigns() { return -1; };
    index = count;
    let n: Int32 = 0;
    while n < SDPQHDesign.Stride() { ArrayPush(this.m_sdpqhDesigns, 0.00); n += 1; };
  };
  let i: Int32 = 0;
  while i < SDPQHDesign.Stride() {
    this.m_sdpqhDesigns[index * SDPQHDesign.Stride() + i] = spec.F(i);
    i += 1;
  };
  this.m_sdpqhDesigns[index * SDPQHDesign.Stride()] = 1.00;
  SDPQHNames.Write(this.m_sdpqhDesignNames, index * SDPQHDesign.MaxName(), spec.name);
  this.SDPQH_Touch();
  return index;
}

@addMethod(PlayerDevelopmentData)
public final func SDPQH_RemoveDesign(index: Int32) -> Bool {
  let count: Int32 = this.SDPQH_DesignCount();
  if index < 0 || index >= count || count <= 1 { return false; };
  let i: Int32 = SDPQHDesign.Stride() - 1;
  while i >= 0 {
    ArrayErase(this.m_sdpqhDesigns, index * SDPQHDesign.Stride() + i);
    i -= 1;
  };
  i = SDPQHDesign.MaxName() - 1;
  while i >= 0 {
    if index * SDPQHDesign.MaxName() + i < ArraySize(this.m_sdpqhDesignNames) {
      ArrayErase(this.m_sdpqhDesignNames, index * SDPQHDesign.MaxName() + i);
    };
    i -= 1;
  };
  this.SDPQH_Touch();
  return true;
}

@addMethod(PlayerDevelopmentData)
public final func SDPQH_SlotLabel(slot: Int32) -> String {
  return slot >= 1 ? SDPQHNames.Read(this.m_sdpqhSlotNames, (slot - 1) * SDPQHDesign.MaxName()) : "";
}

@addMethod(PlayerDevelopmentData)
public final func SDPQH_SetSlotLabel(slot: Int32, name: String) -> Void {
  if slot >= 1 && slot <= SDPQHDesign.SlotCount() { SDPQHNames.Write(this.m_sdpqhSlotNames, (slot - 1) * SDPQHDesign.MaxName(), name); };
  this.SDPQH_Touch();
}

// Library API for the native menu and CET.
@addMethod(PlayerPuppet)
public final func SDPQH_Library() -> ref<PlayerDevelopmentData> {
  return PlayerDevelopmentSystem.GetData(this);
}

@addMethod(PlayerPuppet)
public final func SDPQH_LibraryRevision() -> Int32 {
  let data: ref<PlayerDevelopmentData> = this.SDPQH_Library();
  return IsDefined(data) ? data.SDPQH_Revision() : -1;
}

@addMethod(PlayerPuppet)
public final func SDPQH_DesignCount() -> Int32 {
  let data: ref<PlayerDevelopmentData> = this.SDPQH_Library();
  return IsDefined(data) ? data.SDPQH_DesignCount() : 0;
}

@addMethod(PlayerPuppet)
public final func SDPQH_Design(index: Int32) -> ref<SDPQHSpec> {
  let data: ref<PlayerDevelopmentData> = this.SDPQH_Library();
  return IsDefined(data) ? data.SDPQH_Design(index) : null;
}

@addMethod(PlayerPuppet)
public final func SDPQH_DesignName(index: Int32) -> String {
  let spec: ref<SDPQHSpec> = this.SDPQH_Design(index);
  return IsDefined(spec) ? spec.name : "";
}

@addMethod(PlayerPuppet)
public final func SDPQH_DesignField(index: Int32, field: Int32) -> Float {
  let spec: ref<SDPQHSpec> = this.SDPQH_Design(index);
  return IsDefined(spec) ? spec.F(field) : 0.00;
}

@addMethod(PlayerPuppet)
public final func SDPQH_StoreDesign(index: Int32, spec: ref<SDPQHSpec>) -> Int32 {
  let data: ref<PlayerDevelopmentData> = this.SDPQH_Library();
  return IsDefined(data) ? data.SDPQH_StoreDesign(index, spec) : -1;
}

// CET entry point; lifetime in seconds as in quickhack_designs.lua.
@addMethod(PlayerPuppet)
public final func SDPQH_SaveDesign(index: Int32, name: String, t1: Int32, p1: Int32, c1: Int32, d1: Float, a1: Float, i1: Float,
    t2: Int32, p2: Int32, c2: Int32, d2: Float, a2: Float, i2: Float, lifetime: Int32, spread: Int32) -> Int32 {
  return this.SDPQH_StoreDesign(index, SDPQHSpec.Make(name, t1, p1, c1, d1, a1, i1, t2, p2, c2, d2, a2, i2,
    SDPQHDesign.LifetimeIndex(lifetime), spread));
}

@addMethod(PlayerPuppet)
public final func SDPQH_NewDesign() -> Int32 {
  return this.SDPQH_StoreDesign(-1, SDPQHSpec.Default("New design " + IntToString(this.SDPQH_DesignCount() + 1)));
}

@addMethod(PlayerPuppet)
public final func SDPQH_DuplicateDesign(index: Int32) -> Int32 {
  let spec: ref<SDPQHSpec> = this.SDPQH_Design(index);
  if !IsDefined(spec) { return -1; };
  spec.name = StrLeft(spec.name + " copy", SDPQHDesign.MaxName());
  return this.SDPQH_StoreDesign(-1, spec);
}

@addMethod(PlayerPuppet)
public final func SDPQH_DeleteDesign(index: Int32) -> Bool {
  let data: ref<PlayerDevelopmentData> = this.SDPQH_Library();
  return IsDefined(data) && data.SDPQH_RemoveDesign(index);
}

// Re-adds any starter design whose rules are missing from the library.
@addMethod(PlayerPuppet)
public final func SDPQH_AddStarters() -> Int32 {
  let count: Int32 = this.SDPQH_DesignCount();
  let present: array<String>;
  let i: Int32 = 0;
  while i < count {
    ArrayPush(present, this.SDPQH_Design(i).Signature());
    i += 1;
  };
  let starters: array<ref<SDPQHSpec>> = SDPQHSpec.Starters();
  let added: Int32 = 0;
  i = 0;
  while i < ArraySize(starters) {
    if !ArrayContains(present, starters[i].Signature()) && this.SDPQH_StoreDesign(-1, starters[i]) >= 0 { added += 1; };
    i += 1;
  };
  return added;
}
