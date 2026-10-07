// Component workbench runtime. Sandbox uploads and weapon bindings are opt-in and
// session-only; compiled program chips (CustomPrograms.reds) install hosts here too.
module SkillDrivenProgression

public class SDPPrototypeRule extends IScriptable {
  // Trigger: 1 opponent reload start, 2 direct ranged hit, 3 direct ranged headshot.
  public let trigger: Int32;
  // Payload: 1 blindness, 2 burning. Condition: 0 always, 1 blinded, 2 burning.
  public let payload: Int32;
  public let condition: Int32;
  public let nativeEffect: TweakDBID;
  public let duration: Float;
  public let amount: Float;
  public let interval: Float;
}

public class SDPPrototypeHost extends IScriptable {
  public let target: wref<NPCPuppet>;
  public let first: ref<SDPPrototypeRule>;
  public let second: ref<SDPPrototypeRule>;
  public let expires: Float;
  public let firstReady: Float;
  public let secondReady: Float;
  public let firstCharges: Int32;
  public let secondCharges: Int32;
  public let canSpread: Bool;
  public let lastDamageEvent: Float;
  public let delayedAt: Float;
  // Installed by a program chip upload: the native quickhack already chose the target.
  public let native: Bool;
}

public class SDPPrototypeRuntime extends IScriptable {
  // Sandbox switch: free test uploads, rearm, propagation and weapon binding.
  public let enabled: Bool;
  public let effects: array<ref<SDPPrimitiveInstance>>;
  public let pulses: Int32;
  public let hosts: array<ref<SDPPrototypeHost>>;
  public let weaponHosts: array<ref<SDPPrototypeHost>>;
  public let first: ref<SDPPrototypeRule>;
  public let second: ref<SDPPrototypeRule>;
  public let weaponFirst: ref<SDPPrototypeRule>;
  public let weaponSecond: ref<SDPPrototypeRule>;
  public let weaponID: ItemID;
  public let firing: Bool;
  public let applications: Int32;
  public let reloadEvents: Int32;
  public let hitEvents: Int32;
  public let lastEvent: String;

  public final static func Now(player: ref<PlayerPuppet>) -> Float {
    return EngineTime.ToFloat(GameInstance.GetSimTime(player.GetGame()));
  }

  public final static func Eligible(player: ref<PlayerPuppet>, target: ref<NPCPuppet>) -> Bool {
    return SDPPrototypeRuntime.TargetRejection(player, target) == 0;
  }

  public final static func Alive(target: ref<NPCPuppet>) -> Bool {
    return IsDefined(target) && !target.IsDead() && !ScriptedPuppet.IsDefeated(target) && target.IsActive();
  }

  // Spread recipients of a program chip: hostile, not civilians or quest actors.
  public final static func SpreadEligible(player: ref<PlayerPuppet>, target: ref<NPCPuppet>) -> Bool {
    if !SDPPrototypeRuntime.Alive(target) || target.IsQuest() { return false; };
    if Equals(GameObject.GetAttitudeBetween(target, player), EAIAttitude.AIA_Friendly) { return false; };
    return !target.IsCharacterCivilian() && !target.IsCrowd() && target.IsEnemy();
  }

  public final static func HostValid(player: ref<PlayerPuppet>, host: ref<SDPPrototypeHost>) -> Bool {
    return host.native ? SDPPrototypeRuntime.Alive(host.target) : SDPPrototypeRuntime.Eligible(player, host.target);
  }

  public final static func TargetRejection(player: ref<PlayerPuppet>, target: ref<NPCPuppet>) -> Int32 {
    if !IsDefined(target) { return 1; };
    if target.IsDead() || ScriptedPuppet.IsDefeated(target) || !target.IsActive() { return 2; };
    if target.IsBoss() { return 3; };
    if target.IsQuest() { return 4; };
    if Equals(GameObject.GetAttitudeBetween(target, player), EAIAttitude.AIA_Friendly) { return 5; };
    // IsEnemy includes neutral non-civilian combatants: uploads work before combat starts.
    if target.IsCharacterCivilian() || target.IsCrowd() || !target.IsEnemy() { return 6; };
    return 0;
  }

  public final static func RejectionText(reason: Int32) -> String {
    if reason == 1 { return "No NPC selected. Open scanner, highlight an enemy, then press upload."; };
    if reason == 2 { return "Selected NPC is dead, defeated or inactive."; };
    if reason == 3 { return "Boss targets are excluded from this prototype."; };
    if reason == 4 { return "Selected NPC is quest-protected; choose an ordinary enemy."; };
    if reason == 5 { return "Selected NPC is friendly."; };
    if reason == 6 { return "Selected NPC is a civilian, crowd actor or non-enemy."; };
    return "Selected NPC is unavailable for this prototype.";
  }

  public final static func ResolveTarget(player: ref<PlayerPuppet>) -> ref<NPCPuppet> {
    let state: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
    // Use the scanner's actual selection only while scanning, never a stale scanned ID.
    if IsDefined(state) && state.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Vision) == 1 {
      let scanner: ref<IBlackboard> = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().UI_Scanner);
      if IsDefined(scanner) {
        let selected: ref<GameObject> = GameInstance.FindEntityByID(player.GetGame(), scanner.GetEntityID(GetAllBlackboardDefs().UI_Scanner.ScannedObject)) as GameObject;
        if IsDefined(selected) { return selected as NPCPuppet; };
      };
    };
    return GameInstance.GetTargetingSystem(player.GetGame()).GetLookAtObject(player, true, true) as NPCPuppet;
  }

  public final static func HostStatus(host: ref<SDPPrototypeHost>, now: Float) -> String {
    let remaining: Int32 = Cast<Int32>(MaxF(0.00, host.expires - now));
    return IntToString(remaining) + "s left | charges " + IntToString(host.firstCharges)
      + "/" + (host.second.trigger == 0 ? "off" : IntToString(host.secondCharges));
  }

  public final static func Rule(trigger: Int32, payload: Int32, condition: Int32) -> ref<SDPPrototypeRule> {
    let rule: ref<SDPPrototypeRule> = new SDPPrototypeRule();
    rule.trigger = trigger;
    rule.payload = payload;
    rule.condition = condition;
    rule.duration = 4.00;
    rule.amount = 25.00;
    rule.interval = 1.00;
    return rule;
  }

  public final static func Cost(trigger: Int32, payload: Int32, condition: Int32) -> Int32 {
    if trigger == 0 && payload == 0 && condition == 0 { return 0; };
    if trigger < 1 || trigger > 5 || payload < 1 || payload > 8 || condition < 0 || condition > 2 { return 100; };
    return (trigger == 2 ? 3 : (trigger == 1 ? 2 : 1)) + (payload == 1 || payload == 4 ? 2 : 3) + (condition == 0 ? 0 : 1);
  }

  public final static func Effect(payload: Int32) -> TweakDBID {
    if payload == 3 { return t"SkillDrivenProgression.PrototypeShock"; };
    if payload == 4 { return t"SkillDrivenProgression.PrototypeStun"; };
    return payload == 1 ? t"SkillDrivenProgression.PrototypeBlind" : t"SkillDrivenProgression.PrototypeBurn";
  }

  public final func Prune(player: ref<PlayerPuppet>) -> Void {
    let now: Float = SDPPrototypeRuntime.Now(player);
    let i: Int32 = ArraySize(this.hosts) - 1;
    while i >= 0 {
      if !SDPPrototypeRuntime.HostValid(player, this.hosts[i]) || this.hosts[i].expires <= now {
        ArrayErase(this.hosts, i);
      };
      i -= 1;
    };
    i = ArraySize(this.weaponHosts) - 1;
    while i >= 0 {
      if !SDPPrototypeRuntime.Eligible(player, this.weaponHosts[i].target) || this.weaponHosts[i].expires <= now {
        ArrayErase(this.weaponHosts, i);
      };
      i -= 1;
    };
  }

  public final func Find(target: ref<NPCPuppet>, weapon: Bool) -> ref<SDPPrototypeHost> {
    let entries: array<ref<SDPPrototypeHost>> = weapon ? this.weaponHosts : this.hosts;
    let i: Int32 = 0;
    while i < ArraySize(entries) {
      if IsDefined(entries[i].target) && entries[i].target.GetEntityID() == target.GetEntityID() { return entries[i]; };
      i += 1;
    };
    return null;
  }

  public final func Install(player: ref<PlayerPuppet>, target: ref<NPCPuppet>, source: ref<SDPPrototypeHost>) -> Bool {
    if !this.enabled || !SDPPrototypeRuntime.Eligible(player, target) || ArraySize(this.hosts) >= 16
      || IsDefined(this.Find(target, false)) { return false; };
    let host: ref<SDPPrototypeHost> = new SDPPrototypeHost();
    host.target = target;
    host.lastDamageEvent = -100.00;
    if IsDefined(source) {
      host.first = source.first;
      host.second = source.second;
      host.expires = source.expires;
      host.firstCharges = source.firstCharges;
      host.secondCharges = source.secondCharges;
      host.firstReady = source.firstReady;
      host.secondReady = source.secondReady;
      host.lastDamageEvent = source.lastDamageEvent;
      host.delayedAt = source.delayedAt;
      host.canSpread = false;
    } else {
      host.first = this.first;
      host.second = this.second;
      host.expires = SDPPrototypeRuntime.Now(player) + 30.00;
      host.firstCharges = 3;
      host.secondCharges = 3;
      host.canSpread = true;
      host.delayedAt = SDPPrototypeRuntime.Now(player) + 3.00;
    };
    ArrayPush(this.hosts, host);
    return true;
  }

  // A program chip upload replaces any earlier program on the target. When the
  // table is full the host closest to expiry makes room: the player paid RAM.
  public final func InstallProgram(player: ref<PlayerPuppet>, target: ref<NPCPuppet>, first: ref<SDPPrototypeRule>, second: ref<SDPPrototypeRule>, expires: Float) -> ref<SDPPrototypeHost> {
    if !SDPPrototypeRuntime.Alive(target) { return null; };
    this.Prune(player);
    let existing: ref<SDPPrototypeHost> = this.Find(target, false);
    if IsDefined(existing) { ArrayRemove(this.hosts, existing); };
    if ArraySize(this.hosts) >= 16 {
      let oldest: Int32 = 0;
      let i: Int32 = 1;
      while i < ArraySize(this.hosts) {
        if this.hosts[i].expires < this.hosts[oldest].expires { oldest = i; };
        i += 1;
      };
      ArrayErase(this.hosts, oldest);
    };
    let now: Float = SDPPrototypeRuntime.Now(player);
    let host: ref<SDPPrototypeHost> = new SDPPrototypeHost();
    host.target = target;
    host.first = first;
    host.second = second;
    host.expires = expires;
    host.firstCharges = 3;
    host.secondCharges = 3;
    host.lastDamageEvent = -100.00;
    host.delayedAt = now + 3.00;
    host.native = true;
    ArrayPush(this.hosts, host);
    return host;
  }

  public final static func Matches(rule: ref<SDPPrototypeRule>, event: Int32, blind: Bool, burn: Bool) -> Bool {
    if !IsDefined(rule) || rule.trigger == 0 { return false; };
    if rule.trigger != event && !(rule.trigger == 2 && event == 3) { return false; };
    return rule.condition == 0 || (rule.condition == 1 && blind) || (rule.condition == 2 && burn);
  }

  public final func Apply(player: ref<PlayerPuppet>, target: ref<NPCPuppet>, rule: ref<SDPPrototypeRule>) -> Void {
    if rule.payload != 5 {
      if SDPPrimitiveInstance.Start(this, player, target, rule, 0.00, 0.00) {
        this.applications += 1;
        this.lastEvent = "Primitive started: " + IntToString(rule.payload) + " | pulses queued: " + IntToString(this.pulses);
      } else { this.lastEvent = "Primitive unavailable or active-effect limit reached."; };
      return;
    };
    if StatusEffectHelper.ApplyStatusEffect(target, rule.nativeEffect, player.GetEntityID()) {
      this.applications += 1;
      this.lastEvent = "Native reference applied " + TDBID.ToStringDEBUG(rule.nativeEffect);
    } else { this.lastEvent = "Native reference rejected."; };
  }

  public final func Evaluate(player: ref<PlayerPuppet>, host: ref<SDPPrototypeHost>, event: Int32, blind: Bool, burn: Bool, weapon: Bool) -> Void {
    if !IsDefined(host) { return; };
    let now: Float = SDPPrototypeRuntime.Now(player);
    // Coalesce shotgun pellets/multiple damage callbacks before checking conditions.
    if event == 2 || event == 3 {
      if now - host.lastDamageEvent < 0.10 { return; };
      host.lastDamageEvent = now;
    };
    // Spend charge and reserve cooldown BEFORE dispatch. Both rules see pre-hit conditions.
    if host.firstCharges > 0 && now >= host.firstReady && SDPPrototypeRuntime.Matches(host.first, event, blind, burn) {
      host.firstReady = now + 2.00;
      if !weapon { host.firstCharges -= 1; };
      this.Apply(player, host.target, host.first);
    };
    if host.secondCharges > 0 && now >= host.secondReady && SDPPrototypeRuntime.Matches(host.second, event, blind, burn) {
      host.secondReady = now + 2.00;
      if !weapon { host.secondCharges -= 1; };
      this.Apply(player, host.target, host.second);
    };
  }

  public final func Dispatch(player: ref<PlayerPuppet>, target: ref<NPCPuppet>, event: Int32, weapon: ref<WeaponObject>) -> Void {
    if this.firing || !SDPPrototypeRuntime.Alive(target) { return; };
    // Every NPC reload and player hit lands here: leave early when nothing listens.
    if ArraySize(this.hosts) == 0 && !ItemID.IsValid(this.weaponID) { return; };
    this.Prune(player);
    let weaponHost: ref<SDPPrototypeHost>;
    if this.enabled && SDPPrototypeRuntime.Eligible(player, target) && IsDefined(weapon)
      && ItemID.IsValid(this.weaponID) && weapon.GetItemID() == this.weaponID {
      weaponHost = this.Find(target, true);
      if !IsDefined(weaponHost) && ArraySize(this.weaponHosts) < 16 {
        weaponHost = new SDPPrototypeHost();
        weaponHost.target = target;
        weaponHost.first = this.weaponFirst;
        weaponHost.second = this.weaponSecond;
        weaponHost.expires = SDPPrototypeRuntime.Now(player) + 30.00;
        weaponHost.firstCharges = 1;
        weaponHost.secondCharges = 1;
        weaponHost.lastDamageEvent = -100.00;
        ArrayPush(this.weaponHosts, weaponHost);
      };
      if IsDefined(weaponHost) { weaponHost.expires = SDPPrototypeRuntime.Now(player) + 30.00; };
    };
    let programHost: ref<SDPPrototypeHost> = this.Find(target, false);
    if !IsDefined(programHost) && !IsDefined(weaponHost) { return; };
    let blind: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(target, n"Blind")
      || StatusEffectHelper.HasStatusEffectWithTagConst(target, n"Blind")
      || StatusEffectHelper.HasStatusEffectWithTagConst(target, n"QuickHackBlind");
    let burn: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(target, n"SDPHeat")
      || StatusEffectHelper.HasStatusEffectWithTagConst(target, n"Burning")
      || StatusEffectHelper.HasStatusEffectWithTagConst(target, n"Overheat");
    if event == 1 { this.reloadEvents += 1; } else { if event == 2 || event == 3 { this.hitEvents += 1; }; };
    this.lastEvent = event == 1 ? "Reload detected; checking rules" : "Weapon hit detected; checking rules";
    this.firing = true;
    this.Evaluate(player, programHost, event, blind, burn, false);
    this.Evaluate(player, weaponHost, event, blind, burn, true);
    this.firing = false;
  }
}

@addField(PlayerPuppet)
private let m_sdpPrototype: ref<SDPPrototypeRuntime>;

@addMethod(PlayerPuppet)
public final func SDP_PrototypeVersion() -> Int32 { return 11; }

@addMethod(PlayerPuppet)
public final func SDP_PrototypeEnable(enabled: Bool) -> String {
  // Replacing the runtime clears bindings, programs (including running chip
  // programs), cooldowns and diagnostic counters.
  if IsDefined(this.m_sdpPrototype) { SDPPrimitiveInstance.Clear(this.m_sdpPrototype, this); };
  this.m_sdpPrototype = new SDPPrototypeRuntime();
  if enabled && (!IsDefined(TweakDBInterface.GetStatusEffectRecord(t"SkillDrivenProgression.PrototypeBlind"))
    || !IsDefined(TweakDBInterface.GetStatusEffectRecord(t"SkillDrivenProgression.PrototypeBurn"))) {
    return "Payload records unavailable. Deploy PrototypeCrafting.yaml with the scripts.";
  };
  this.m_sdpPrototype.enabled = enabled;
  return enabled ? "Sandbox enabled. Free test uploads and weapon binding are available." : "Sandbox disabled; programs and weapon binding cleared. Custom effects cleared; native reference effects retain their own duration.";
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeAssemble(t1: Int32, p1: Int32, c1: Int32, t2: Int32, p2: Int32, c2: Int32) -> String {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled { return "Enable the workbench first."; };
  if t1 == 0 || SDPPrototypeRuntime.Cost(t1, p1, c1) + SDPPrototypeRuntime.Cost(t2, p2, c2) > 12 { return "Invalid recipe or complexity above 12."; };
  if t1 == t2 && p1 == p2 && c1 == c2 && p1 != 5 { return "Duplicate rules are not supported."; };
  this.m_sdpPrototype.first = SDPPrototypeRuntime.Rule(t1, p1, c1);
  this.m_sdpPrototype.second = SDPPrototypeRuntime.Rule(t2, p2, c2);
  return "Recipe assembled. Upload it or bind it to your held gun.";
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeSetNative(slot: Int32, recordID: TweakDBID) -> Bool {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled || slot < 1 || slot > 2 { return false; };
  if SDPQHLab.Family(TweakDBInterface.GetStatusEffectRecord(recordID)) == 0 { return false; };
  let rule: ref<SDPPrototypeRule> = slot == 1 ? this.m_sdpPrototype.first : this.m_sdpPrototype.second;
  if !IsDefined(rule) || rule.payload != 5 { return false; };
  let other: ref<SDPPrototypeRule> = slot == 1 ? this.m_sdpPrototype.second : this.m_sdpPrototype.first;
  if IsDefined(other) && other.payload == 5 && other.nativeEffect == recordID
    && other.trigger == rule.trigger && other.condition == rule.condition { return false; };
  rule.nativeEffect = recordID;
  return true;
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeUpload() -> String {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled || !IsDefined(this.m_sdpPrototype.first) { return "Enable and assemble a recipe first."; };
  if (this.m_sdpPrototype.first.payload == 5 && !TDBID.IsValid(this.m_sdpPrototype.first.nativeEffect))
    || (this.m_sdpPrototype.second.payload == 5 && !TDBID.IsValid(this.m_sdpPrototype.second.nativeEffect)) { return "Select valid native status primitives before upload."; };
  let target: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  let rejection: Int32 = SDPPrototypeRuntime.TargetRejection(this, target);
  if rejection != 0 { return SDPPrototypeRuntime.RejectionText(rejection); };
  if Vector4.Distance(this.GetWorldPosition(), target.GetWorldPosition()) > 30.00 { return "Upload range is 30 metres."; };
  this.m_sdpPrototype.Prune(this);
  let existing: ref<SDPPrototypeHost> = this.m_sdpPrototype.Find(target, false);
  if IsDefined(existing) { return "Already installed: " + SDPPrototypeRuntime.HostStatus(existing, SDPPrototypeRuntime.Now(this)) + ". Wait for expiry or select another enemy."; };
  if !this.m_sdpPrototype.Install(this, target, null) { return "16-host limit reached. Wait for a program to expire."; };
  this.m_sdpPrototype.Dispatch(this, target, 4, null);
  return "Program installed: 30s, 3 charges/rule. Effects wait for the selected trigger.";
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeRearm() -> String {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled { return "Enable the workbench first."; };
  this.m_sdpPrototype.Prune(this);
  let target: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  let rejection: Int32 = SDPPrototypeRuntime.TargetRejection(this, target);
  if rejection != 0 { return SDPPrototypeRuntime.RejectionText(rejection); };
  if Vector4.Distance(this.GetWorldPosition(), target.GetWorldPosition()) > 30.00 { return "Rearm range is 30 metres."; };
  let host: ref<SDPPrototypeHost> = this.m_sdpPrototype.Find(target, false);
  if !IsDefined(host) { return "No active program on this enemy. Upload first."; };
  // Explicit sandbox reset only. Do not grant copies the ability to spread.
  host.expires = SDPPrototypeRuntime.Now(this) + 30.00;
  host.firstCharges = 3;
  host.secondCharges = 3;
  host.firstReady = 0.00;
  host.secondReady = 0.00;
  host.lastDamageEvent = -100.00;
  host.delayedAt = SDPPrototypeRuntime.Now(this) + 3.00;
  this.m_sdpPrototype.Dispatch(this, target, 4, null);
  return "Program rearmed: 30s, 3 charges per rule. Waiting for its trigger.";
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypePropagate() -> String {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled { return "Enable the workbench first."; };
  this.m_sdpPrototype.Prune(this);
  let target: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  let rejection: Int32 = SDPPrototypeRuntime.TargetRejection(this, target);
  if rejection != 0 { return SDPPrototypeRuntime.RejectionText(rejection); };
  if Vector4.Distance(this.GetWorldPosition(), target.GetWorldPosition()) > 30.00 { return "Propagation source must be within 30 metres."; };
  let source: ref<SDPPrototypeHost> = this.m_sdpPrototype.Find(target, false);
  if !IsDefined(source) || !source.canSpread { return "No original, unspread prototype program on this target."; };
  if source.firstCharges <= 0 && (source.second.trigger == 0 || source.secondCharges <= 0) { return "Program has no charges left."; };
  let query: TargetSearchQuery;
  query.testedSet = TargetingSet.Complete;
  query.maxDistance = 40.00;
  query.filterObjectByDistance = true;
  query.includeSecondaryTargets = false;
  query.ignoreInstigator = true;
  let parts: array<TS_TargetPartInfo>;
  GameInstance.GetTargetingSystem(this.GetGame()).GetTargetParts(this, query, parts);
  let i: Int32 = 0;
  let count: Int32 = 0;
  while i < ArraySize(parts) && count < 3 {
    let component: wref<TargetingComponent> = TS_TargetPartInfo.GetComponent(parts[i]);
    if IsDefined(component) {
      let other: ref<NPCPuppet> = component.GetEntity() as NPCPuppet;
      if SDPPrototypeRuntime.Eligible(this, other) && Vector4.Distance(target.GetWorldPosition(), other.GetWorldPosition()) <= 8.00 {
        if this.m_sdpPrototype.Install(this, other, source) {
          SDPPrimitiveInstance.CopyActive(this.m_sdpPrototype, this, target, other);
          count += 1;
        };
      };
    };
    i += 1;
  };
  if count > 0 { source.canSpread = false; };
  return "Copied program to " + IntToString(count) + " enemies; copies keep remaining lifetime, charges and cooldowns.";
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeBindWeapon() -> String {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled || !IsDefined(this.m_sdpPrototype.first) { return "Enable and assemble a recipe first."; };
  if this.m_sdpPrototype.first.trigger == 1 || this.m_sdpPrototype.second.trigger == 1
    || this.m_sdpPrototype.first.trigger > 3 || this.m_sdpPrototype.second.trigger > 3 { return "Weapon rules support hit/headshot only."; };
  let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(this);
  if !IsDefined(weapon) || !weapon.IsRanged() { return "Hold a ranged weapon first."; };
  if (this.m_sdpPrototype.first.payload == 5 && !TDBID.IsValid(this.m_sdpPrototype.first.nativeEffect))
    || (this.m_sdpPrototype.second.payload == 5 && !TDBID.IsValid(this.m_sdpPrototype.second.nativeEffect)) { return "Select valid native primitives before binding."; };
  this.m_sdpPrototype.weaponID = weapon.GetItemID();
  this.m_sdpPrototype.weaponFirst = this.m_sdpPrototype.first;
  this.m_sdpPrototype.weaponSecond = this.m_sdpPrototype.second;
  ArrayClear(this.m_sdpPrototype.weaponHosts);
  return "Prototype assembled on this weapon instance. Swap away and back to test the binding.";
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeStatus() -> String {
  if !IsDefined(this.m_sdpPrototype) { return "Build 11 | Sandbox off | No programs running."; };
  this.m_sdpPrototype.Prune(this);
  let target: ref<NPCPuppet> = SDPPrototypeRuntime.ResolveTarget(this);
  let detail: String = "No NPC selected";
  if IsDefined(target) {
    let reason: Int32 = SDPPrototypeRuntime.TargetRejection(this, target);
    detail = reason == 0 ? "Target ready for upload" : SDPPrototypeRuntime.RejectionText(reason);
    let host: ref<SDPPrototypeHost> = this.m_sdpPrototype.Find(target, false);
    if IsDefined(host) { detail = "Installed: " + SDPPrototypeRuntime.HostStatus(host, SDPPrototypeRuntime.Now(this)); };
    detail += " | Target status: blind=" + (StatusEffectSystem.ObjectHasStatusEffectWithTag(target, n"Blind") ? "active" : "off")
      + ", burn=" + (StatusEffectSystem.ObjectHasStatusEffectWithTag(target, n"SDPHeat") ? "active" : "off");
    detail += SDPPrimitiveInstance.Describe(this.m_sdpPrototype, this, target);
  };
  return "Build 11 | Pulses queued: " + IntToString(this.m_sdpPrototype.pulses) + " | Sandbox " + (this.m_sdpPrototype.enabled ? "on" : "off")
    + " | Programs: " + IntToString(ArraySize(this.m_sdpPrototype.hosts))
    + " | Reloads detected: " + IntToString(this.m_sdpPrototype.reloadEvents)
    + " | Hits detected: " + IntToString(this.m_sdpPrototype.hitEvents)
    + " | Weapon bound: " + (ItemID.IsValid(this.m_sdpPrototype.weaponID) ? "yes" : "no")
    + " | Effect dispatches: " + IntToString(this.m_sdpPrototype.applications)
    + " | " + this.m_sdpPrototype.lastEvent + " | " + detail;
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeNotify(text: String) -> Void {
  let message: SimpleScreenMessage;
  message.isShown = true;
  message.duration = 4.00;
  message.message = "Workbench: " + text;
  GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications)
    .SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(message), true);
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeEvent(target: ref<NPCPuppet>, event: Int32, weapon: ref<WeaponObject>) -> Void {
  if IsDefined(this.m_sdpPrototype) { this.m_sdpPrototype.Dispatch(this, target, event, weapon); };
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeTick() -> Void {
  if !IsDefined(this.m_sdpPrototype) { return; };
  this.m_sdpPrototype.Prune(this);
  SDPPrimitiveInstance.Tick(this.m_sdpPrototype, this);
  let hosts: array<ref<SDPPrototypeHost>> = this.m_sdpPrototype.hosts;
  let now: Float = SDPPrototypeRuntime.Now(this);
  let i: Int32 = 0;
  while i < ArraySize(hosts) {
    if hosts[i].delayedAt > 0.00 && now >= hosts[i].delayedAt {
      hosts[i].delayedAt = 0.00;
      this.m_sdpPrototype.Dispatch(this, hosts[i].target, 5, null);
    };
    i += 1;
  };
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  this.m_sdpPrototype = null;
  this.m_sdpqhApplied = false;
  this.m_sdpQHLab = null;
  this.m_sdpOpticsTrace = null;
  return wrappedMethod();
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  if IsDefined(this.m_sdpPrototype) { SDPPrimitiveInstance.Clear(this.m_sdpPrototype, this); };
  this.m_sdpPrototype = null;
  this.m_sdpQHLab = null;
  this.m_sdpOpticsTrace = null;
  return wrappedMethod();
}

@wrapMethod(AISubActionReloadWeapon_Record_Implementation)
public final static func Activate(context: ScriptExecutionContext, record: wref<AISubActionReloadWeapon_Record>) -> Void {
  wrappedMethod(context, record);
  let weapon: wref<WeaponObject>;
  if !AISubActionReloadWeapon_Record_Implementation.GetWeapon(context, record, weapon) { return; };
  let target: ref<NPCPuppet> = ScriptExecutionContext.GetOwner(context) as NPCPuppet;
  if !IsDefined(target) { return; };
  let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(target.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  if IsDefined(player) { player.SDP_PrototypeEvent(target, 1, null); };
}

@wrapMethod(RPGManager)
public final static func AwardExperienceFromDamage(hitEvent: ref<gameHitEvent>, damagePercentage: Float) {
  wrappedMethod(hitEvent, damagePercentage);
  if !IsDefined(hitEvent) || !IsDefined(hitEvent.attackData) || damagePercentage <= 0.00 { return; };
  let attack: ref<AttackData> = hitEvent.attackData;
  // Only direct ranged weapon damage feeds the engine, not hack/DoT/explosion attacks.
  if NotEquals(attack.GetAttackType(), gamedataAttackType.Ranged)
    || attack.HasFlag(hitFlag.QuickHack) || attack.HasFlag(hitFlag.DamageOverTime)
    || attack.HasFlag(hitFlag.DotApplied) { return; };
  let player: ref<PlayerPuppet> = attack.GetInstigator() as PlayerPuppet;
  let target: ref<NPCPuppet> = hitEvent.target as NPCPuppet;
  let weapon: ref<WeaponObject> = attack.GetWeapon();
  if !IsDefined(player) || !IsDefined(weapon) || !weapon.IsRanged() { return; };
  player.SDP_PrototypeEvent(target, attack.HasFlag(hitFlag.Headshot) ? 3 : 2, weapon);
}

@addMethod(PlayerPuppet)
public final func SDP_PrototypeConfigure(slot: Int32, duration: Float, amount: Float, interval: Float) -> Bool {
  if !IsDefined(this.m_sdpPrototype) || !this.m_sdpPrototype.enabled || slot < 1 || slot > 2 { return false; };
  if (duration != 2.00 && duration != 4.00 && duration != 8.00)
    || (amount != 10.00 && amount != 25.00 && amount != 50.00)
    || (interval != 0.50 && interval != 1.00 && interval != 2.00) { return false; };
  let rule: ref<SDPPrototypeRule> = slot == 1 ? this.m_sdpPrototype.first : this.m_sdpPrototype.second;
  if !IsDefined(rule) { return false; };
  let snapshot: ref<SDPPrototypeRule> = SDPPrototypeRuntime.Rule(rule.trigger, rule.payload, rule.condition);
  snapshot.nativeEffect = rule.nativeEffect;
  rule = snapshot;
  rule.duration = duration;
  rule.amount = amount;
  rule.interval = interval;
  if slot == 1 { this.m_sdpPrototype.first = rule; } else { this.m_sdpPrototype.second = rule; };
  return true;
}
