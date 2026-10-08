module SkillDrivenProgression

// Per-encounter XP tracking for the CET overlay. An encounter starts when
// combat starts and stays open until 60 s after combat ends, so fights that
// follow each other closely count as one encounter. It collects shard XP (per
// shard) and skill XP (per skill). The last closed encounter is kept for display.
// It also counts triggers: every time a shard's XP condition is met, whether
// or not the shard is being trained or is already capped (per shard and
// source), and every skill XP event (per skill). Nothing here is saved.

@addField(PlayerDevelopmentData) private let m_sdpEncOpen: Bool;
@addField(PlayerDevelopmentData) private let m_sdpEncInCombat: Bool;
@addField(PlayerDevelopmentData) private let m_sdpEncStart: Float;
@addField(PlayerDevelopmentData) private let m_sdpEncLastCombat: Float;
@addField(PlayerDevelopmentData) private let m_sdpEncShard: array<Int32>;     // slot 0..15
@addField(PlayerDevelopmentData) private let m_sdpEncSkill: array<Int32>;     // 5 skills
@addField(PlayerDevelopmentData) private let m_sdpEncLastShard: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncLastSkill: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncLastLength: Float;
@addField(PlayerDevelopmentData) private let m_sdpEncHasLast: Bool;
// Death closes the encounter at once (the reload would lose it otherwise) and
// marks it failed; no new encounter opens until the save is reloaded.
@addField(PlayerDevelopmentData) private let m_sdpEncLastDied: Bool;
// Character snapshot when the encounter closes: 5 skill levels, player level,
// 5 attributes (Body, Reflexes, Tech, Int, Cool).
@addField(PlayerDevelopmentData) private let m_sdpEncLastLevels: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncDead: Bool;
@addField(PlayerDevelopmentData) private let m_sdpEncClosed: Int32;
@addField(PlayerDevelopmentData) private let m_sdpEncTrig: array<Int32>;        // slot * 33 + source
@addField(PlayerDevelopmentData) private let m_sdpEncLastTrig: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncSkillEvents: array<Int32>; // 5 skills
@addField(PlayerDevelopmentData) private let m_sdpEncChanXP: array<Int32>;      // slot * 33 + channel (v2 XP)
@addField(PlayerDevelopmentData) private let m_sdpEncLastChanXP: array<Int32>;
// Shard XP earned out of combat (e.g. Ninjutsu sneaking) is held here and
// folded into the next encounter if it starts within 120 s.
@addField(PlayerDevelopmentData) private let m_sdpEncPreShard: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncPreChanXP: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncPreTime: Float;
// Kills by NPC rarity (gamedataNPCRarity order: Boss, Elite, MaxTac, Normal,
// Officer, Rare, Trash, Weak) - enemy overhauls such as ENC change rarities,
// and rarity multiplies both native and shard XP.
@addField(PlayerDevelopmentData) private let m_sdpEncKills: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncLastKills: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncLastSkillEvents: array<Int32>;
// Neutralizations (see "Neutralization log" below): one CSV fragment per enemy,
// the enemy IDs (a defeat followed by a kill counts once), and counters
// [killed, defeated, unconscious, rarity changed, gun, melee, cyberarm,
//  quickhack, thrown, explosive, status, takedown, unattributed].
@addField(PlayerDevelopmentData) private let m_sdpEncNeutRows: array<String>;
@addField(PlayerDevelopmentData) private let m_sdpEncNeutIDs: array<EntityID>;
@addField(PlayerDevelopmentData) private let m_sdpEncNeutMethod: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncNeutType: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncNeutCount: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpEncLastNeutRows: array<String>;
@addField(PlayerDevelopmentData) private let m_sdpEncLastNeutCount: array<Int32>;
// Last player hit per enemy (kept across encounters, newest 64).
@addField(PlayerDevelopmentData) private let m_sdpHitIDs: array<EntityID>;
@addField(PlayerDevelopmentData) private let m_sdpHitMethod: array<Int32>;
@addField(PlayerDevelopmentData) private let m_sdpHitTime: array<Float>;
@addField(PlayerDevelopmentData) private let m_sdpDbgSkillCalls: Int32;
@addField(PlayerDevelopmentData) private let m_sdpDbgSkillAmount: Int32;
@addField(PlayerDevelopmentData) private let m_sdpDbgShardCalls: Int32;

public func SDP_EncounterGrace() -> Float { return 60.00; }

// Encounter slots: 0 = Deadeye, 1..SDP_FamilyCount() = shard families.
public func SDP_EncounterSlots() -> Int32 { return SDP_FamilyCount() + 1; }

// Trigger sources per shard slot: 0..32 (Deadeye uses up to 32).
public func SDP_EncounterSourceStride() -> Int32 { return 33; }

public func SDP_EncounterSlotName(slot: Int32) -> String {
  return slot == 0 ? "Deadeye" : SDP_FamilyName(slot);
}

public func SDP_EncounterSkillIndex(type: gamedataProficiencyType) -> Int32 {
  if Equals(type, gamedataProficiencyType.StrengthSkill) { return 0; };
  if Equals(type, gamedataProficiencyType.ReflexesSkill) { return 1; };
  if Equals(type, gamedataProficiencyType.TechnicalAbilitySkill) { return 2; };
  if Equals(type, gamedataProficiencyType.IntelligenceSkill) { return 3; };
  if Equals(type, gamedataProficiencyType.CoolSkill) { return 4; };
  return -1;
}

public func SDP_EncounterSkillName(index: Int32) -> String {
  if index == 0 { return "Solo"; };
  if index == 1 { return "Shinobi"; };
  if index == 2 { return "Engineer"; };
  if index == 3 { return "Netrunner"; };
  return "Headhunter";
}

// NPC death tasks can run concurrently. All encounter open/reset/close and
// neutralization updates must use the same system request queue, including
// ticks from the player loop/CET. Otherwise an explosion killing two NPCs can
// make both death threads clear and grow the same counter arrays at once.
public class SDPEncounterTickRequest extends PlayerScriptableSystemRequest {
  public let inCombat: Bool;
}

public class SDPEncounterPlayerDeathRequest extends PlayerScriptableSystemRequest {}

public class SDPEncounterNeutralizedRequest extends PlayerScriptableSystemRequest {
  // Keep the victim alive until the queued update has read its metadata.
  public let npc: ref<NPCPuppet>;
  public let type: Int32;
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterQueue(request: ref<PlayerScriptableSystemRequest>) -> Void {
  if !IsDefined(this.m_owner) { return; };
  let system: ref<ScriptableSystem> = GameInstance.GetScriptableSystemsContainer(this.m_owner.GetGame()).Get(n"PlayerDevelopmentSystem");
  if !IsDefined(system) { return; };
  request.owner = this.m_owner;
  system.QueueRequest(request);
}

@addMethod(PlayerDevelopmentSystem)
private final func OnSDPEncounterTick(request: ref<SDPEncounterTickRequest>) -> Void {
  if !IsDefined(request.owner) { return; };
  let data: ref<PlayerDevelopmentData> = this.GetDevelopmentData(request.owner);
  if IsDefined(data) { data.SDP_EncounterApplyTick(request.inCombat); };
}

@addMethod(PlayerDevelopmentSystem)
private final func OnSDPEncounterPlayerDeath(request: ref<SDPEncounterPlayerDeathRequest>) -> Void {
  if !IsDefined(request.owner) { return; };
  let data: ref<PlayerDevelopmentData> = this.GetDevelopmentData(request.owner);
  if IsDefined(data) { data.SDP_EncounterApplyPlayerDeath(); };
}

@addMethod(PlayerDevelopmentSystem)
private final func OnSDPEncounterNeutralized(request: ref<SDPEncounterNeutralizedRequest>) -> Void {
  if !IsDefined(request.owner) || !IsDefined(request.npc) { return; };
  let data: ref<PlayerDevelopmentData> = this.GetDevelopmentData(request.owner);
  if IsDefined(data) { data.SDP_EncounterApplyNeutralized(request.npc, request.type); };
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterReset() -> Void {
  ArrayClear(this.m_sdpEncShard);
  ArrayClear(this.m_sdpEncSkill);
  ArrayClear(this.m_sdpEncTrig);
  ArrayClear(this.m_sdpEncSkillEvents);
  ArrayClear(this.m_sdpEncChanXP);
  ArrayClear(this.m_sdpEncKills);
  ArrayClear(this.m_sdpEncNeutRows);
  ArrayClear(this.m_sdpEncNeutIDs);
  ArrayClear(this.m_sdpEncNeutMethod);
  ArrayClear(this.m_sdpEncNeutType);
  ArrayClear(this.m_sdpEncNeutCount);
  let n: Int32 = 0;
  while n < SDP_NeutCounterCount() { ArrayPush(this.m_sdpEncNeutCount, 0); n += 1; };
  let k: Int32 = 0;
  while k < 8 { ArrayPush(this.m_sdpEncKills, 0); k += 1; };
  let i: Int32 = 0;
  while i < SDP_EncounterSlots() { ArrayPush(this.m_sdpEncShard, 0); i += 1; };
  i = 0;
  while i < SDP_EncounterSlots() * SDP_EncounterSourceStride() { ArrayPush(this.m_sdpEncTrig, 0); ArrayPush(this.m_sdpEncChanXP, 0); i += 1; };
  i = 0;
  while i < 5 { ArrayPush(this.m_sdpEncSkill, 0); ArrayPush(this.m_sdpEncSkillEvents, 0); i += 1; };
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterNow() -> Float {
  if !IsDefined(this.m_owner) { return 0.00; };
  return EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_owner.GetGame()));
}

// Called twice a second from the player loop.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterTick(inCombat: Bool) -> Void {
  let request: ref<SDPEncounterTickRequest> = new SDPEncounterTickRequest();
  request.inCombat = inCombat;
  this.SDP_EncounterQueue(request);
}

// Called only by the PlayerDevelopmentSystem request handler.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterApplyTick(inCombat: Bool) -> Void {
  let now: Float = this.SDP_EncounterNow();
  if this.m_sdpEncDead {
    // Cleared once the player is alive again (reload, or a revive).
    let puppet: ref<ScriptedPuppet> = this.m_owner as ScriptedPuppet;
    if IsDefined(puppet) && puppet.IsDead() { return; };
    this.m_sdpEncDead = false;
  };
  this.m_sdpEncInCombat = inCombat;
  if inCombat {
    if !this.m_sdpEncOpen {
      this.SDP_EncounterReset();
      this.m_sdpEncOpen = true;
      this.m_sdpEncStart = now;
      this.SDP_EncounterTakePreCombat(now);
    };
    this.m_sdpEncLastCombat = now;
    return;
  };
  if this.m_sdpEncOpen && now - this.m_sdpEncLastCombat > SDP_EncounterGrace() {
    this.SDP_EncounterClose(false);
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterOnPlayerDeath() -> Void {
  this.SDP_EncounterQueue(new SDPEncounterPlayerDeathRequest());
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterApplyPlayerDeath() -> Void {
  if this.m_sdpEncDead { return; };
  this.m_sdpEncDead = true;
  this.m_sdpEncInCombat = false;
  if this.m_sdpEncOpen {
    this.m_sdpEncLastCombat = this.SDP_EncounterNow();
    this.SDP_EncounterClose(true);
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastDied() -> Bool { return this.m_sdpEncLastDied; }

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterClose(died: Bool) -> Void {
  if this.m_sdpEncOpen {
    this.m_sdpEncOpen = false;
    this.m_sdpEncLastDied = died;
    this.SDP_EncounterSnapshotLevels();
    this.m_sdpEncLastShard = this.m_sdpEncShard;
    this.m_sdpEncLastSkill = this.m_sdpEncSkill;
    this.m_sdpEncLastTrig = this.m_sdpEncTrig;
    this.m_sdpEncLastChanXP = this.m_sdpEncChanXP;
    this.m_sdpEncLastKills = this.m_sdpEncKills;
    this.m_sdpEncLastNeutRows = this.m_sdpEncNeutRows;
    this.m_sdpEncLastNeutCount = this.m_sdpEncNeutCount;
    this.m_sdpEncLastSkillEvents = this.m_sdpEncSkillEvents;
    this.m_sdpEncLastLength = this.m_sdpEncLastCombat - this.m_sdpEncStart;
    this.m_sdpEncHasLast = true;
    this.m_sdpEncClosed += 1;
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterAddShard(slot: Int32, amount: Int32) -> Void {
  this.m_sdpDbgShardCalls += 1;
  if amount <= 0 || slot < 0 || slot >= SDP_EncounterSlots() { return; };
  if !this.m_sdpEncOpen {
    while ArraySize(this.m_sdpEncPreShard) < SDP_EncounterSlots() { ArrayPush(this.m_sdpEncPreShard, 0); };
    this.m_sdpEncPreShard[slot] += amount;
    this.m_sdpEncPreTime = this.SDP_EncounterNow();
    return;
  };
  if slot < ArraySize(this.m_sdpEncShard) { this.m_sdpEncShard[slot] += amount; };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterAddChannelXP(slot: Int32, channel: Int32, amount: Int32) -> Void {
  let stride: Int32 = SDP_EncounterSourceStride();
  if amount <= 0 || slot < 0 || slot >= SDP_EncounterSlots() || channel < 0 || channel >= stride { return; };
  let index: Int32 = slot * stride + channel;
  if !this.m_sdpEncOpen {
    while ArraySize(this.m_sdpEncPreChanXP) < SDP_EncounterSlots() * stride { ArrayPush(this.m_sdpEncPreChanXP, 0); };
    this.m_sdpEncPreChanXP[index] += amount;
    return;
  };
  if index < ArraySize(this.m_sdpEncChanXP) { this.m_sdpEncChanXP[index] += amount; };
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterTakePreCombat(now: Float) -> Void {
  if now - this.m_sdpEncPreTime <= 120.00 {
    let i: Int32 = 0;
    while i < ArraySize(this.m_sdpEncPreShard) && i < ArraySize(this.m_sdpEncShard) {
      this.m_sdpEncShard[i] += this.m_sdpEncPreShard[i];
      i += 1;
    };
    i = 0;
    while i < ArraySize(this.m_sdpEncPreChanXP) && i < ArraySize(this.m_sdpEncChanXP) {
      this.m_sdpEncChanXP[i] += this.m_sdpEncPreChanXP[i];
      i += 1;
    };
  };
  ArrayClear(this.m_sdpEncPreShard);
  ArrayClear(this.m_sdpEncPreChanXP);
}

// "Carnage +35, Obliterate +5" for one shard (v2 channels), or "".
@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterChannelBreakdown(values: array<Int32>, slot: Int32) -> String {
  let stride: Int32 = SDP_EncounterSourceStride();
  let text: String = "";
  let channel: Int32 = 11;
  while channel < stride && slot * stride + channel < ArraySize(values) {
    let xp: Int32 = values[slot * stride + channel];
    if xp > 0 {
      text += (StrLen(text) > 0 ? ", " : "") + SDP_ChannelName(slot, channel) + " +" + IntToString(xp);
    };
    channel += 1;
  };
  return text;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterAddSkill(type: gamedataProficiencyType, amount: Int32) -> Void {
  this.m_sdpDbgSkillCalls += 1;
  this.m_sdpDbgSkillAmount += amount;
  let index: Int32 = SDP_EncounterSkillIndex(type);
  if !this.m_sdpEncOpen || amount <= 0 || index < 0 || index >= ArraySize(this.m_sdpEncSkill) { return; };
  this.m_sdpEncSkill[index] += amount;
  if index < ArraySize(this.m_sdpEncSkillEvents) { this.m_sdpEncSkillEvents[index] += 1; };
}

// A shard's XP condition was met (called before any training/cap check).
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterAddTrigger(slot: Int32, source: Int32) -> Void {
  let stride: Int32 = SDP_EncounterSourceStride();
  if !this.m_sdpEncOpen || slot < 0 || slot >= SDP_EncounterSlots() || source < 0 || source >= stride { return; };
  let index: Int32 = slot * stride + source;
  if index < ArraySize(this.m_sdpEncTrig) { this.m_sdpEncTrig[index] += 1; };
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterTriggerText(values: array<Int32>, withSources: Bool) -> String {
  let stride: Int32 = SDP_EncounterSourceStride();
  let line: String = "";
  let slot: Int32 = 0;
  while slot < SDP_EncounterSlots() && ArraySize(values) >= SDP_EncounterSlots() * stride {
    let total: Int32 = 0;
    let detail: String = "";
    let source: Int32 = 0;
    while source < stride {
      let count: Int32 = values[slot * stride + source];
      if count > 0 {
        total += count;
        detail += (StrLen(detail) > 0 ? " " : "") + "s" + IntToString(source) + ":" + IntToString(count);
      };
      source += 1;
    };
    if total > 0 {
      line += (StrLen(line) > 0 ? "   " : "") + SDP_EncounterSlotName(slot) + " x" + IntToString(total)
        + (withSources ? " (" + detail + ")" : "");
    };
    slot += 1;
  };
  return StrLen(line) > 0 ? line : "none";
}

public func SDP_EncounterRarityIndex(rarity: gamedataNPCRarity) -> Int32 {
  if Equals(rarity, gamedataNPCRarity.Boss) { return 0; };
  if Equals(rarity, gamedataNPCRarity.Elite) { return 1; };
  if Equals(rarity, gamedataNPCRarity.MaxTac) { return 2; };
  if Equals(rarity, gamedataNPCRarity.Normal) { return 3; };
  if Equals(rarity, gamedataNPCRarity.Officer) { return 4; };
  if Equals(rarity, gamedataNPCRarity.Rare) { return 5; };
  if Equals(rarity, gamedataNPCRarity.Trash) { return 6; };
  if Equals(rarity, gamedataNPCRarity.Weak) { return 7; };
  return -1;
}

public func SDP_EncounterRarityName(index: Int32) -> String {
  if index == 0 { return "Boss"; };
  if index == 1 { return "Elite"; };
  if index == 2 { return "MaxTac"; };
  if index == 3 { return "Normal"; };
  if index == 4 { return "Officer"; };
  if index == 5 { return "Rare"; };
  if index == 6 { return "Trash"; };
  if index == 7 { return "Weak"; };
  return "Other";
}

// Kills by rarity are counted in SDP_EncounterOnNeutralized; hits only
// remember how each enemy was last hit.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterOnDamageDealt(evt: ref<gameTargetDamageEvent>) -> Void {
  if !IsDefined(evt) || !IsDefined(evt.attackData) { return; };
  let npc: ref<NPCPuppet> = evt.target as NPCPuppet;
  if !IsDefined(npc) { return; };
  this.SDP_EncounterRememberHit(npc.GetEntityID(), SDP_NeutMethodFromAttack(evt.attackData));
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterKillText(values: array<Int32>) -> String {
  let line: String = "";
  let i: Int32 = 0;
  while i < ArraySize(values) {
    if values[i] > 0 {
      line += (StrLen(line) > 0 ? ", " : "") + SDP_EncounterRarityName(i) + " " + IntToString(values[i]);
    };
    i += 1;
  };
  return StrLen(line) > 0 ? line : "none";
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterKillLine() -> String {
  return "Kills:  " + this.SDP_EncounterKillText(this.m_sdpEncOpen ? this.m_sdpEncKills : this.m_sdpEncLastKills);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastKillText() -> String {
  return this.SDP_EncounterKillText(this.m_sdpEncLastKills);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastKills(index: Int32) -> Int32 {
  if index < 0 || index >= ArraySize(this.m_sdpEncLastKills) { return 0; };
  return this.m_sdpEncLastKills[index];
}

// ---- Overlay text (read by CET) -------------------------------------------

// Header: current encounter while one is open, otherwise the last one.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterHeader() -> String {
  if this.m_sdpEncOpen {
    let seconds: Int32 = FloorF(this.SDP_EncounterNow() - this.m_sdpEncStart);
    let state: String = this.m_sdpEncInCombat ? "In combat" : "After combat";
    return "Encounter XP  (" + state + ", " + IntToString(seconds / 60) + ":"
      + (seconds % 60 < 10 ? "0" : "") + IntToString(seconds % 60) + ")";
  };
  if this.m_sdpEncHasLast {
    let length: Int32 = FloorF(this.m_sdpEncLastLength);
    return "Last encounter XP  (" + IntToString(length / 60) + ":"
      + (length % 60 < 10 ? "0" : "") + IntToString(length % 60) + ")";
  };
  return "Encounter XP  (no combat yet)";
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterSkillLine() -> String {
  let values: array<Int32> = this.m_sdpEncOpen ? this.m_sdpEncSkill : this.m_sdpEncLastSkill;
  let line: String = "";
  let i: Int32 = 0;
  while i < ArraySize(values) {
    if values[i] > 0 {
      line += (StrLen(line) > 0 ? "   " : "") + SDP_EncounterSkillName(i) + " +" + IntToString(values[i]);
    };
    i += 1;
  };
  return StrLen(line) > 0 ? "Skills:  " + line : "Skills:  none";
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterShardLine() -> String {
  let values: array<Int32> = this.m_sdpEncOpen ? this.m_sdpEncShard : this.m_sdpEncLastShard;
  let channels: array<Int32> = this.m_sdpEncOpen ? this.m_sdpEncChanXP : this.m_sdpEncLastChanXP;
  let line: String = "";
  let i: Int32 = 0;
  while i < ArraySize(values) {
    if values[i] > 0 {
      let name: String = i == 0 ? "Deadeye" : SDP_FamilyName(i);
      let detail: String = this.SDP_EncounterChannelBreakdown(channels, i);
      line += (StrLen(line) > 0 ? "   " : "") + name + " +" + IntToString(values[i])
        + (StrLen(detail) > 0 ? " (" + detail + ")" : "");
    };
    i += 1;
  };
  return StrLen(line) > 0 ? "Shards:  " + line : "Shards:  none";
}

// v2 channel triggers by name: "Obliteration: Carnage x40, Obliterate x2".
@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterChannelTriggerText(values: array<Int32>) -> String {
  let stride: Int32 = SDP_EncounterSourceStride();
  let line: String = "";
  let slot: Int32 = 0;
  while slot < SDP_EncounterSlots() && ArraySize(values) >= SDP_EncounterSlots() * stride {
    let detail: String = "";
    let channel: Int32 = 11;
    while channel < stride {
      let count: Int32 = values[slot * stride + channel];
      let name: String = SDP_ChannelName(slot, channel);
      if count > 0 && StrLen(name) > 0 {
        detail += (StrLen(detail) > 0 ? ", " : "") + name + " x" + IntToString(count);
      };
      channel += 1;
    };
    if StrLen(detail) > 0 {
      line += (StrLen(line) > 0 ? "   " : "") + (slot == 0 ? "Deadeye" : SDP_FamilyName(slot)) + ": " + detail;
    };
    slot += 1;
  };
  return StrLen(line) > 0 ? line : "none";
}

// v1 source triggers only (s1-s10), kept for comparison.
@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterV1TriggerText(values: array<Int32>) -> String {
  let stride: Int32 = SDP_EncounterSourceStride();
  let trimmed: array<Int32> = values;
  let slot: Int32 = 0;
  while slot < SDP_EncounterSlots() && ArraySize(trimmed) >= SDP_EncounterSlots() * stride {
    let channel: Int32 = 11;
    while channel < stride { trimmed[slot * stride + channel] = 0; channel += 1; };
    slot += 1;
  };
  return this.SDP_EncounterTriggerText(trimmed, true);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterTriggerLine() -> String {
  return "Triggers:  " + this.SDP_EncounterChannelTriggerText(
    this.m_sdpEncOpen ? this.m_sdpEncTrig : this.m_sdpEncLastTrig
  );
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastChannelTriggerText() -> String {
  return this.SDP_EncounterChannelTriggerText(this.m_sdpEncLastTrig);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastV1TriggerText() -> String {
  return this.SDP_EncounterV1TriggerText(this.m_sdpEncLastTrig);
}

// For the CSV: the v2 channel name (or "" if none) and last-encounter XP.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterChannelLabel(slot: Int32, channel: Int32) -> String {
  return SDP_ChannelName(slot, channel);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastChannelXP(slot: Int32, channel: Int32) -> Int32 {
  let index: Int32 = slot * SDP_EncounterSourceStride() + channel;
  if slot < 0 || slot >= SDP_EncounterSlots() || channel < 0 || index >= ArraySize(this.m_sdpEncLastChanXP) { return 0; };
  return this.m_sdpEncLastChanXP[index];
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastShardText() -> String {
  let line: String = "";
  let i: Int32 = 0;
  while i < ArraySize(this.m_sdpEncLastShard) {
    if this.m_sdpEncLastShard[i] > 0 {
      let detail: String = this.SDP_EncounterChannelBreakdown(this.m_sdpEncLastChanXP, i);
      line += (StrLen(line) > 0 ? "   " : "") + (i == 0 ? "Deadeye" : SDP_FamilyName(i))
        + " +" + IntToString(this.m_sdpEncLastShard[i]) + (StrLen(detail) > 0 ? " (" + detail + ")" : "");
    };
    i += 1;
  };
  return StrLen(line) > 0 ? line : "none";
}

// ---- Raw values for the CET encounter log --------------------------------

// Triggers of the last closed encounter, with the source breakdown.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastTriggerText() -> String {
  return this.SDP_EncounterTriggerText(this.m_sdpEncLastTrig, true);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastTriggers(slot: Int32) -> Int32 {
  let stride: Int32 = SDP_EncounterSourceStride();
  if slot < 0 || slot >= SDP_EncounterSlots() || ArraySize(this.m_sdpEncLastTrig) < SDP_EncounterSlots() * stride { return 0; };
  let total: Int32 = 0;
  let source: Int32 = 0;
  while source < stride { total += this.m_sdpEncLastTrig[slot * stride + source]; source += 1; };
  return total;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastSkillEvents(index: Int32) -> Int32 {
  if index < 0 || index >= ArraySize(this.m_sdpEncLastSkillEvents) { return 0; };
  return this.m_sdpEncLastSkillEvents[index];
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterIsOpen() -> Bool { return this.m_sdpEncOpen; }

// Increments each time an encounter closes; CET logs the last one then.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterClosedCount() -> Int32 { return this.m_sdpEncClosed; }

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastSeconds() -> Float { return this.m_sdpEncLastLength; }

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastSkillXP(index: Int32) -> Int32 {
  if index < 0 || index >= ArraySize(this.m_sdpEncLastSkill) { return 0; };
  return this.m_sdpEncLastSkill[index];
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastShardXP(slot: Int32) -> Int32 {
  if slot < 0 || slot >= ArraySize(this.m_sdpEncLastShard) { return 0; };
  return this.m_sdpEncLastShard[slot];
}

// CET: print(PlayerDevelopmentSystem.GetInstance(Game.GetPlayer()):GetDevelopmentData(Game.GetPlayer()):SDP_EncounterDebug())
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterDebug() -> String {
  let loop: Int32 = 0;
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) { loop = player.SDP_LoopTicks(); };
  return "open=" + (this.m_sdpEncOpen ? "true" : "false") + " inCombat=" + (this.m_sdpEncInCombat ? "true" : "false")
    + " closed=" + IntToString(this.m_sdpEncClosed)
    + " skillSlots=" + IntToString(ArraySize(this.m_sdpEncSkill))
    + " playerLoopTicks=" + IntToString(loop)
    + " skillCalls=" + IntToString(this.m_sdpDbgSkillCalls) + "/" + IntToString(this.m_sdpDbgSkillAmount) + "xp"
    + " shardCalls=" + IntToString(this.m_sdpDbgShardCalls)
    + " | " + this.SDP_EncounterSkillLine() + " | " + this.SDP_EncounterShardLine();
}

// Identifies this development-data instance for CET, which gets a new Lua
// handle on every call and so cannot compare handles to detect a new load.
@addField(PlayerDevelopmentData) private let m_sdpSessionId: Int32;

@addMethod(PlayerDevelopmentData)
public final func SDP_SessionId() -> Int32 {
  if this.m_sdpSessionId == 0 { this.m_sdpSessionId = RandRange(1, 2000000000); };
  return this.m_sdpSessionId;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this);
  if IsDefined(data) { data.SDP_EncounterOnPlayerDeath(); };
  return wrappedMethod(evt);
}

// ---- Neutralization log ------------------------------------------------------------
// Every enemy the player kills, defeats or knocks unconscious, from the game's
// kill reward (so takedowns, quickhack and status-effect kills count too, and a
// defeat finished later counts once). Each one is a row in kills.csv (CET);
// the encounter keeps totals by outcome and method. Neutralizing someone out
// of combat (stealth) opens an encounter, so stealth runs are logged as well.

public func SDP_NeutCounterCount() -> Int32 { return 13; }

// Methods 0..8: gun, melee, cyberarm, quickhack, thrown, explosive, status,
// takedown, unattributed (no player hit, hack or takedown seen: environment,
// turrets, companions, some scripted deaths).
public func SDP_NeutMethodName(method: Int32) -> String {
  if method == 0 { return "gun"; };
  if method == 1 { return "melee"; };
  if method == 2 { return "cyberarm"; };
  if method == 3 { return "quickhack"; };
  if method == 4 { return "thrown"; };
  if method == 5 { return "explosive"; };
  if method == 6 { return "status"; };
  if method == 7 { return "takedown"; };
  return "unattributed";
}

public func SDP_NeutTypeName(type: Int32) -> String {
  if type == 0 { return "killed"; };
  if type == 1 { return "defeated"; };
  return "unconscious";
}

public func SDP_NeutIsCyberarm(attackData: ref<AttackData>) -> Bool {
  let weapon: ref<WeaponObject> = attackData.GetWeapon();
  if !IsDefined(weapon) { return false; };
  let type: gamedataItemType = RPGManager.GetItemType(weapon.GetItemID());
  return Equals(type, gamedataItemType.Cyb_MantisBlades) || Equals(type, gamedataItemType.Cyb_StrongArms)
    || Equals(type, gamedataItemType.Cyb_NanoWires) || Equals(type, gamedataItemType.Cyb_Launcher);
}

public func SDP_NeutMethodFromAttack(attackData: ref<AttackData>) -> Int32 {
  let attack: gamedataAttackType = attackData.GetAttackType();
  if Equals(attack, gamedataAttackType.Hack) { return 3; };
  if Equals(attack, gamedataAttackType.Thrown) { return 4; };
  if Equals(attack, gamedataAttackType.Explosion) || Equals(attack, gamedataAttackType.PressureWave) { return 5; };
  if Equals(attack, gamedataAttackType.Effect) { return 6; };
  if SDP_NeutIsCyberarm(attackData) { return 2; };
  if Equals(attack, gamedataAttackType.Ranged) { return 0; };
  if Equals(attack, gamedataAttackType.Melee) || Equals(attack, gamedataAttackType.StrongMelee)
    || Equals(attack, gamedataAttackType.QuickMelee) || Equals(attack, gamedataAttackType.WhipAttack)
    || Equals(attack, gamedataAttackType.ChargedWhipAttack) || Equals(attack, gamedataAttackType.GuardBreak) {
    return 1;
  };
  return 8;
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterRememberHit(id: EntityID, method: Int32) -> Void {
  let now: Float = this.SDP_EncounterNow();
  let i: Int32 = 0;
  while i < ArraySize(this.m_sdpHitIDs) {
    if this.m_sdpHitIDs[i] == id {
      this.m_sdpHitMethod[i] = method;
      this.m_sdpHitTime[i] = now;
      return;
    };
    i += 1;
  };
  if ArraySize(this.m_sdpHitIDs) >= 64 {
    ArrayErase(this.m_sdpHitIDs, 0);
    ArrayErase(this.m_sdpHitMethod, 0);
    ArrayErase(this.m_sdpHitTime, 0);
  };
  ArrayPush(this.m_sdpHitIDs, id);
  ArrayPush(this.m_sdpHitMethod, method);
  ArrayPush(this.m_sdpHitTime, now);
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterNeutMethod(id: EntityID) -> Int32 {
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) {
    let blackboard: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
    if IsDefined(blackboard) && blackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Takedown) != 0 { return 7; };
  };
  let now: Float = this.SDP_EncounterNow();
  let i: Int32 = 0;
  while i < ArraySize(this.m_sdpHitIDs) {
    if this.m_sdpHitIDs[i] == id && now - this.m_sdpHitTime[i] <= 15.00 { return this.m_sdpHitMethod[i]; };
    i += 1;
  };
  if this.SDP_ChannelNow() - this.m_sdpChanLastHack <= 10.00 { return 3; };
  return 8;
}

// type: 0 killed, 1 defeated, 2 unconscious.
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterOnNeutralized(npc: ref<NPCPuppet>, type: Int32) -> Void {
  if !IsDefined(npc) { return; };
  let request: ref<SDPEncounterNeutralizedRequest> = new SDPEncounterNeutralizedRequest();
  request.npc = npc;
  request.type = type;
  this.SDP_EncounterQueue(request);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterApplyNeutralized(npc: ref<NPCPuppet>, type: Int32) -> Void {
  if !IsDefined(npc) || this.m_sdpEncDead { return; };
  let now: Float = this.SDP_EncounterNow();
  if !this.m_sdpEncOpen {
    this.SDP_EncounterReset();
    this.m_sdpEncOpen = true;
    this.m_sdpEncStart = now;
    this.SDP_EncounterTakePreCombat(now);
  };
  this.m_sdpEncLastCombat = now;
  let id: EntityID = npc.GetEntityID();
  let method: Int32 = this.SDP_EncounterNeutMethod(id);

  let rarity: gamedataNPCRarity = npc.GetNPCRarity();
  let baseRarity: gamedataNPCRarity = rarity;
  let record: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(npc.GetRecordID());
  let archetype: String = "";
  let name: String = "";
  if IsDefined(record) {
    name = StrReplaceAll(GetLocalizedTextByKey(record.DisplayName()), ",", " ");
    if IsDefined(record.Rarity()) { baseRarity = record.Rarity().Type(); };
    if IsDefined(record.ArchetypeData()) && IsDefined(record.ArchetypeData().Type()) {
      archetype = NameToString(record.ArchetypeData().Type().EnumName());
    };
  };
  let level: Float = GameInstance.GetStatsSystem(npc.GetGame())
    .GetStatValue(Cast<StatsObjectID>(id), gamedataStatType.PowerLevel);
  let changed: Bool = NotEquals(rarity, baseRarity);
  let row: String = SDP_NeutTypeName(type) + "," + SDP_NeutMethodName(method) + ","
    + SDP_EncounterRarityName(SDP_EncounterRarityIndex(rarity)) + ","
    + SDP_EncounterRarityName(SDP_EncounterRarityIndex(baseRarity)) + ","
    + npc.GetAffiliation() + ","
    + EnumValueToString("gamedataNPCType", Cast<Int64>(EnumInt(npc.GetNPCType()))) + ","
    + archetype + "," + IntToString(RoundF(level)) + ","
    + (npc.AwardsExperience() ? "yes" : "no") + ","
    + name;

  // A defeat finished off later (or a revived enemy downed again) updates its row.
  let index: Int32 = ArrayFindFirst(this.m_sdpEncNeutIDs, id);
  if index >= 0 {
    this.m_sdpEncNeutCount[this.m_sdpEncNeutType[index]] -= 1;
    this.m_sdpEncNeutCount[4 + this.m_sdpEncNeutMethod[index]] -= 1;
    this.m_sdpEncNeutRows[index] = row;
    this.m_sdpEncNeutType[index] = type;
    this.m_sdpEncNeutMethod[index] = method;
  } else {
    ArrayPush(this.m_sdpEncNeutIDs, id);
    ArrayPush(this.m_sdpEncNeutRows, row);
    ArrayPush(this.m_sdpEncNeutType, type);
    ArrayPush(this.m_sdpEncNeutMethod, method);
    if changed { this.m_sdpEncNeutCount[3] += 1; };
    if npc.AwardsExperience() {
      let r: Int32 = SDP_EncounterRarityIndex(rarity);
      if r >= 0 && r < ArraySize(this.m_sdpEncKills) { this.m_sdpEncKills[r] += 1; };
    };
  };
  this.m_sdpEncNeutCount[type] += 1;
  this.m_sdpEncNeutCount[4 + method] += 1;
}

public func SDP_NeutCounterName(index: Int32) -> String {
  if index == 0 { return "killed"; };
  if index == 1 { return "defeated"; };
  if index == 2 { return "unconscious"; };
  if index == 3 { return "rarity_changed"; };
  return "by_" + SDP_NeutMethodName(index - 4);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastNeutCount(index: Int32) -> Int32 {
  if index < 0 || index >= ArraySize(this.m_sdpEncLastNeutCount) { return 0; };
  return this.m_sdpEncLastNeutCount[index];
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastNeutRowCount() -> Int32 { return ArraySize(this.m_sdpEncLastNeutRows); }

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastNeutRow(index: Int32) -> String {
  if index < 0 || index >= ArraySize(this.m_sdpEncLastNeutRows) { return ""; };
  return this.m_sdpEncLastNeutRows[index];
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterNeutText(counts: array<Int32>) -> String {
  let line: String = "";
  let i: Int32 = 0;
  while i < ArraySize(counts) {
    if counts[i] > 0 {
      line += (StrLen(line) > 0 ? ", " : "") + SDP_NeutCounterName(i) + " " + IntToString(counts[i]);
    };
    i += 1;
  };
  return StrLen(line) > 0 ? line : "none";
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterNeutLine() -> String {
  return "Down:  " + this.SDP_EncounterNeutText(this.m_sdpEncOpen ? this.m_sdpEncNeutCount : this.m_sdpEncLastNeutCount);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastNeutText() -> String {
  return this.SDP_EncounterNeutText(this.m_sdpEncLastNeutCount);
}

@wrapMethod(ScriptedPuppet)
protected func RewardKiller(killer: wref<GameObject>, killType: gameKillType, isAnyDamageNonlethal: Bool) -> Void {
  let disabled: Bool = this.m_killRewardDisabled;
  wrappedMethod(killer, killType, isAnyDamageNonlethal);
  if disabled { return; };
  let player: ref<PlayerPuppet> = killer as PlayerPuppet;
  let npc: ref<NPCPuppet> = this as NPCPuppet;
  if !IsDefined(player) || !IsDefined(npc) { return; };
  let data: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(player);
  if !IsDefined(data) { return; };
  let type: Int32 = 0;
  if Equals(killType, gameKillType.Defeat) || this.m_forceDefeatReward {
    type = isAnyDamageNonlethal ? 2 : 1;
  };
  data.SDP_EncounterOnNeutralized(npc, type);
}

// ---- Character snapshot ------------------------------------------------------------

// called from the CET overlay as data:SDP_EncounterLevelName(i), so it must be a method
@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLevelName(index: Int32) -> String {
  if index < 5 { return "lvl_" + SDP_EncounterSkillName(index); };
  if index == 5 { return "player_level"; };
  if index == 6 { return "attr_Body"; };
  if index == 7 { return "attr_Reflexes"; };
  if index == 8 { return "attr_Tech"; };
  if index == 9 { return "attr_Intelligence"; };
  return "attr_Cool";
}

@addMethod(PlayerDevelopmentData)
private final func SDP_EncounterSnapshotLevels() -> Void {
  ArrayClear(this.m_sdpEncLastLevels);
  ArrayPush(this.m_sdpEncLastLevels, this.GetProficiencyLevel(gamedataProficiencyType.StrengthSkill));
  ArrayPush(this.m_sdpEncLastLevels, this.GetProficiencyLevel(gamedataProficiencyType.ReflexesSkill));
  ArrayPush(this.m_sdpEncLastLevels, this.GetProficiencyLevel(gamedataProficiencyType.TechnicalAbilitySkill));
  ArrayPush(this.m_sdpEncLastLevels, this.GetProficiencyLevel(gamedataProficiencyType.IntelligenceSkill));
  ArrayPush(this.m_sdpEncLastLevels, this.GetProficiencyLevel(gamedataProficiencyType.CoolSkill));
  ArrayPush(this.m_sdpEncLastLevels, this.GetProficiencyLevel(gamedataProficiencyType.Level));
  if !IsDefined(this.m_owner) { return; };
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_owner.GetGame());
  let id: StatsObjectID = Cast<StatsObjectID>(this.m_owner.GetEntityID());
  let types: array<gamedataStatType> = [gamedataStatType.Strength, gamedataStatType.Reflexes,
    gamedataStatType.TechnicalAbility, gamedataStatType.Intelligence, gamedataStatType.Cool];
  let i: Int32 = 0;
  while i < ArraySize(types) {
    ArrayPush(this.m_sdpEncLastLevels, RoundF(stats.GetStatValue(id, types[i])));
    i += 1;
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_EncounterLastLevel(index: Int32) -> Int32 {
  if index < 0 || index >= ArraySize(this.m_sdpEncLastLevels) { return 0; };
  return this.m_sdpEncLastLevels[index];
}
