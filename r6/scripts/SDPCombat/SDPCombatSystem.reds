// SDPCombat Phase 1: runtime switches and shot telemetry.
// CET console access:
//   local s = Game.GetScriptableSystemsContainer():Get("SDPCombat.SDPCombatSystem")
//   s:SetEnabled(false)  s:SetAllHostiles(true)  s:SetLogShots(true)  s:Report()  s:ResetStats()
//   s:Mark("still")  -> reports and resets the previous segment, then labels every following log line
//   s:SetTestGodMode(true)  -> V cannot die (test only); logs which protections are really active
//   s:SetDurability(true)  s:SetOneShotProtection(true)  s:SetIncomingScale(1.0)  s:Status()
// Output goes to cyber_engine_tweaks/gamelog.log (redscript FTLog), which flushes only on exit;
// the segment report is also kept as text: print(SDPC:LastReport()) then error('flush') writes it to scripting.log.
module SDPCombat

public class SDPCombatSystem extends ScriptableSystem {
  private let m_initialized: Bool;
  private let m_enabled: Bool;
  private let m_allHostiles: Bool;
  private let m_logShots: Bool;
  private let m_segment: String;
  private let m_durability: Bool;
  private let m_oneShotProtection: Bool;
  private let m_incomingScale: Float;

  // aim zones of sampled shots: 0 miss, 1 head, 2 torso, 3 legs
  private let m_aimZones: array<Int32>;
  // damage events by direction (index 0 NPC->V, 1 V->NPC) x zone (0 unknown, 1 head, 2 torso, 3 legs)
  private let m_hitZones: array<Int32>;
  private let m_dmgHits: array<Int32>;
  private let m_dmgPen: array<Int32>;
  private let m_dmgPct: array<Float>;
  private let m_loggedWeapons: array<TweakDBID>;
  private let m_loggedWeaponKeys: array<String>;
  private let m_firstShots: Int32;
  private let m_firstShotsRaised: Int32;
  private let m_firstShotDelay: Float;
  private let m_outOfRangeHolds: Int32;
  private let m_lastReport: String;
  private let m_testGodMode: Bool;
  private let m_vArmor: ref<SDPArmorKit>;
  private let m_armorTickRunning: Bool;
  private let m_vArmorBar: wref<healthbarWidgetGameController>;
  private let m_lastEnemyBar: String;
  private let m_aimingDelayRemoved: Int32;
  private let m_blindShots: Int32;
  private let m_weaponDamage: Bool;
  private let m_vvKeys: array<String>;
  private let m_vvValues: array<ref<SDPVVersion>>;
  private let m_unsampledHits: Int32;
  private let m_armorCovered: array<Int32>;   // per direction
  private let m_armorStopped: array<Int32>;
  private let m_armorBroken: array<Int32>;
  private let m_fatal: array<Int32>;
  private let m_wdIds: array<TweakDBID>;      // damage check per weapon record
  private let m_wdDir: array<Int32>;
  private let m_wdSum: array<Float>;
  private let m_wdN: array<Int32>;
  private let m_wdInfo: array<String>;
  private let m_partMatrix: array<Int32>;   // predicted zone (0..3) x actual part (0..4)
  private let m_partHeight: array<Float>;   // sum of hit heights per predicted zone
  private let m_absorbedHits: Int32;
  private let m_absorbedDamage: Float;
  private let m_beliefN: array<Int32>;
  private let m_beliefAbs: array<Float>;

  // telemetry, indexed by shooter tier 0..4 (see SDPProfiles.TierName)
  private let m_shots: array<Int32>;
  private let m_hits: array<Int32>;
  private let m_sumP: array<Float>;
  private let m_pauses: array<Int32>;
  private let m_sumPause: array<Float>;
  private let m_zeroPauses: array<Int32>;
  // per tier x 4 lateral-speed bins (still <0.3, slow <1.5, strafe <4, sprint) : index tier*4+bin
  private let m_binShots: array<Int32>;
  private let m_binHits: array<Int32>;
  private let m_binP: array<Float>;
  private let m_blocked: array<Int32>;   // shots with no line of sight to V
  private let m_covered: array<Int32>;   // aimed shots at V with only part of V visible
  // per tier x 5 pause bins (0, <0.25, <0.5, <1, >=1 s) : index tier*5+bin
  private let m_pauseHist: array<Int32>;

  public func OnAttach() -> Void {
    this.Init();
  }

  private final func Init() -> Void {
    if this.m_initialized { return; };
    this.m_initialized = true;
    this.m_enabled = true;
    this.m_allHostiles = true;
    this.m_weaponDamage = false;   // V's-version damage disabled: temporary item data has no stats and may be unsafe   // every hostile human uses the model; SetAllHostiles(false) limits it to the test factions
    this.m_logShots = false;
    this.m_durability = true;
    this.m_oneShotProtection = false;
    this.m_incomingScale = 1.0;
    this.ResetStats();
  }

  public static func Get(game: GameInstance) -> ref<SDPCombatSystem> {
    let system = GameInstance.GetScriptableSystemsContainer(game).Get(n"SDPCombat.SDPCombatSystem") as SDPCombatSystem;
    if IsDefined(system) { system.Init(); };
    return system;
  }

  public final func IsEnabled() -> Bool { return this.m_enabled; }
  public final func AllHostiles() -> Bool { return this.m_allHostiles; }
  public final func LogShots() -> Bool { return this.m_logShots; }
  public final func Segment() -> String { return this.m_segment; }
  public final func DurabilityEnabled() -> Bool { return this.m_durability; }
  public final func OneShotProtection() -> Bool { return this.m_oneShotProtection; }
  public final func IncomingScale() -> Float { return this.m_incomingScale; }

  public final func SetDurability(value: Bool) -> Void { this.m_durability = value; FTLog(s"[SDPCombat] durability = \(value)"); }
  public final func SetOneShotProtection(value: Bool) -> Void { this.m_oneShotProtection = value; FTLog(s"[SDPCombat] oneShotProtection = \(value)"); }
  public final func SetIncomingScale(value: Float) -> Void { this.m_incomingScale = ClampF(value, 0.0, 5.0); FTLog(s"[SDPCombat] incomingScale = \(this.m_incomingScale)"); }

  public final func Status() -> Void {
    let game = this.GetGameInstance();
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    FTLog(s"[SDPCombat] status: enabled=\(this.m_enabled) allHostiles=\(this.m_allHostiles) durability=\(this.m_durability) oneShotProtection=\(this.m_oneShotProtection) incomingScale=\(this.m_incomingScale)");
    if IsDefined(player) {
      let stats = GameInstance.GetStatsSystem(game);
      let id = Cast<StatsObjectID>(player.GetEntityID());
      let armor = stats.GetStatValue(id, gamedataStatType.Armor);
      let eff = GameInstance.GetStatsDataSystem(game).GetArmorEffectivenessValue(true) * stats.GetStatValue(id, gamedataStatType.ArmorEffectivenessMultiplier);
      let a = armor * eff;
      let maxHealth = GameInstance.GetStatPoolsSystem(game).GetStatPoolMaxPointValue(id, gamedataStatPoolType.Health);
      FTLog(s"[SDPCombat] V: maxHealth=\(maxHealth) armor=\(armor) effectiveness=\(eff) protection=\(8.0 * a / (1.0 + a))");
    };
  }

  public final func FirstTimeWeaponKey(key: String) -> Bool {
    if ArrayContains(this.m_loggedWeaponKeys, key) { return false; };
    ArrayPush(this.m_loggedWeaponKeys, key);
    return true;
  }

  public final func FirstTimeWeapon(record: TweakDBID) -> Bool {
    if ArrayContains(this.m_loggedWeapons, record) { return false; };
    ArrayPush(this.m_loggedWeapons, record);
    return true;
  }

  public final func RecordBeliefError(lateral: Float, err: Float) -> Void {
    if ArraySize(this.m_beliefN) < 4 { ArrayResize(this.m_beliefN, 4); ArrayResize(this.m_beliefAbs, 4); };
    let b = SDPCombatSystem.LateralBin(lateral);
    this.m_beliefN[b] += 1;
    this.m_beliefAbs[b] += AbsF(err);
  }

  public final func TestGodMode() -> Bool { return this.m_testGodMode; }

  // Every handling and damage stat of V's held gun, as V's version of it has them: print(SDPC:ProbeWeapon())
  public final func ProbeWeapon() -> String {
    let game = this.GetGameInstance();
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    let weapon = GameObject.GetActiveWeapon(player);
    if !IsDefined(weapon) { return "[SDPCombat] probe: no weapon in hand"; };
    let s = GameInstance.GetStatsSystem(game);
    let id = Cast<StatsObjectID>(weapon.GetEntityID());
    let out = s"[SDPCombat] probe \(TDBID.ToStringDEBUG(ItemID.GetTDBID(weapon.GetItemID()))) quality=\(EnumValueToString("gamedataQuality", Cast<Int64>(EnumInt(RPGManager.GetItemDataQuality(weapon.GetItemData())))))\n";
    let i = 0;
    while i < 1709 {
      let t = IntEnum<gamedataStatType>(i);
      let name = EnumValueToString("gamedataStatType", Cast<Int64>(i));
      if StrBeginsWith(name, "Spread") || StrBeginsWith(name, "Recoil") || StrBeginsWith(name, "Sway") || StrContains(name, "Damage")
        || StrContains(name, "DPS") || Equals(name, "ItemLevel") || Equals(name, "PowerLevel") || Equals(name, "Quality")
        || Equals(name, "IsItemPlus") || Equals(name, "CycleTime") || Equals(name, "AimInTime") || Equals(name, "EffectiveRange")
        || Equals(name, "MaximumRange") || Equals(name, "ProjectilesPerShot") || Equals(name, "CanIgnoreArmor") {
        let v = s.GetStatValue(id, t);
        if v != 0.0 { out += s"  \(name)=\(v)\n"; };
      };
      i += 1;
    };
    FTLog(out);
    return out;
  }

  // Enemy hits do what V's version of the same gun (record, tier, mods) does. SetWeaponDamage(false) = vanilla NPC damage.
  public final func WeaponDamage() -> Bool { return this.m_weaponDamage; }
  public final func SetWeaponDamage(value: Bool) -> Void { this.m_weaponDamage = value; FTLog(s"[SDPCombat] weaponDamage = \(value)"); }

  public final func VVersion(weapon: wref<WeaponObject>) -> ref<SDPVVersion> {
    if !IsDefined(weapon) { return null; };
    let parts: array<InnerItemData>;
    let data = weapon.GetItemData();
    if IsDefined(data) { data.GetItemParts(parts); };
    let key = TDBID.ToStringDEBUG(ItemID.GetTDBID(weapon.GetItemID()));
    let q = GameInstance.GetStatsSystem(weapon.GetGame()).GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.Quality);
    key += s"|q\(q)";
    for p in parts { key += "|" + TDBID.ToStringDEBUG(ItemID.GetTDBID(InnerItemData.GetItemID(p))); };
    let i = 0;
    while i < ArraySize(this.m_vvKeys) {
      if Equals(this.m_vvKeys[i], key) { return this.m_vvValues[i]; };
      i += 1;
    };
    // Inventory.CreateItemData gives item data with uninitialised stats (all 0) and adding modifiers to it is a
    // crash suspect (2026-10-06 00:40). Disabled until the damage source is found another way.
    if !this.m_weaponDamage { return null; };
    let v = new SDPVVersion();
    ArrayPush(this.m_vvKeys, key);
    ArrayPush(this.m_vvValues, v);
    FTLog(s"[SDPCombat] V's version of \(key): damage/hit=\(v.damage) kick=\(v.kickMin)-\(v.kickMax) quality=\(v.quality) (enemy gun quality \(v.enemyQuality)) mods=\(v.mods)");
    return v;
  }

  public final func RecordAimingDelayRemoved() -> Void { this.m_aimingDelayRemoved += 1; }
  public final func RecordBlindShot() -> Void { this.m_blindShots += 1; }
  public final func RecordUnsampledHit() -> Void { this.m_unsampledHits += 1; }

  // V's subdermal armour: rating follows her Armor stat (cyberware), integrity persists and self-repairs
  public final func VArmor(target: ref<GameObject>, now: Float) -> ref<SDPArmorKit> {
    if !IsDefined(this.m_vArmor) {
      this.m_vArmor = new SDPArmorKit();
      this.m_vArmor.label = "V";
      this.m_vArmor.repairedByTick = true;
      this.StartArmorTick();
      ArrayPush(this.m_vArmor.pieces, SDPArmorPiece.Make("subdermal armour", 0.0, 1 | 2 | 4 | 8, true));
      this.m_vArmor.lastUpdate = now;
    };
    this.m_vArmor.pieces[0].rating = SDPArmor.RatingFromStat(target);
    this.StartArmorTick();
    return this.m_vArmor;
  }

  // Every 2 s: while V is out of combat (the game's own combat state) her plating repairs, full in 90 s.
  public final func StartArmorTick() -> Void {
    if this.m_armorTickRunning { return; };
    this.m_armorTickRunning = true;
    let cb = new SDPArmorTick();
    cb.system = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(cb, 2.0, false);
  }

  public final func ArmorTick() -> Void {
    this.m_armorTickRunning = false;
    let game = this.GetGameInstance();
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) && IsDefined(this.m_vArmor) {
      let now = SDPHitModel.Now(game);
      let dt = ClampF(now - this.m_vArmor.lastUpdate, 0.0, 5.0);
      this.m_vArmor.lastUpdate = now;
      this.m_vArmor.pieces[0].rating = SDPArmor.RatingFromStat(player);
      if !player.IsInCombat() { this.m_vArmor.Repair(dt / 90.0); };
      this.UpdateVArmorBar();
    };
    this.StartArmorTick();
  }

  public final func RegisterVArmorBar(bar: ref<healthbarWidgetGameController>) -> Void {
    this.m_vArmorBar = bar;
    let game = this.GetGameInstance();
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    if IsDefined(player) { this.VArmor(player, SDPHitModel.Now(game)); };
    this.UpdateVArmorBar();
  }

  // console: print(SDPC:ArmorBarDebug())  /  SDPC:ArmorBarMode(1)  /  SDPC:ArmorBarAt(100, 900)
  public final func ArmorBarDebug() -> String {
    if !IsDefined(this.m_vArmorBar) { return "[SDPCombat] armour bar: HUD controller never registered (bar not built)"; };
    let s = this.m_vArmorBar.SDP_ArmorBarDebug() + s"  width now \(this.m_vArmorBar.m_sdpArmorWidth)\n";
    if IsDefined(this.m_vArmor) && ArraySize(this.m_vArmor.pieces) > 0 {
      s += s"  V armour: P\(this.m_vArmor.pieces[0].rating) integrity \(this.m_vArmor.pieces[0].integrity)\n";
    } else { s += "  V armour: no kit yet\n"; };
    s += "  last enemy bar: " + this.m_lastEnemyBar + "\n";
    return s;
  }

  public final func ArmorBarMode(mode: Int32) -> Void {
    if IsDefined(this.m_vArmorBar) { this.m_vArmorBar.SDP_SetArmorBarMode(mode, this.m_vArmorBar.m_sdpArmorX, this.m_vArmorBar.m_sdpArmorY); this.UpdateVArmorBar(); };
  }

  // console: SDPC:ArmorBarWidth(700) sets the bar length in pixels (0 = automatic)
  public final func ArmorBarWidth(w: Float) -> Void {
    if IsDefined(this.m_vArmorBar) {
      this.m_vArmorBar.m_sdpArmorWidthOverride = w;
      this.m_vArmorBar.SDP_SetArmorBarMode(this.m_vArmorBar.m_sdpArmorMode, this.m_vArmorBar.m_sdpArmorX, this.m_vArmorBar.m_sdpArmorY);
      this.UpdateVArmorBar();
    };
  }

  public final func ArmorBarAt(x: Float, y: Float) -> Void {
    if IsDefined(this.m_vArmorBar) { this.m_vArmorBar.SDP_SetArmorBarMode(2, x, y); this.UpdateVArmorBar(); };
  }

  public final func NoteEnemyBar(status: String) -> Void { this.m_lastEnemyBar = status; }

  public final func UpdateVArmorBar() -> Void {
    if !IsDefined(this.m_vArmorBar) { return; };
    if !IsDefined(this.m_vArmor) || ArraySize(this.m_vArmor.pieces) == 0 || !this.m_durability {
      this.m_vArmorBar.SDP_SetArmorBar(0.0, 0.0);
      return;
    };
    let p = this.m_vArmor.pieces[0];
    this.m_vArmorBar.SDP_SetArmorBar(p.integrity, p.rating);
  }

  public final func RepairVArmor() -> Void {
    if IsDefined(this.m_vArmor) { for p in this.m_vArmor.pieces { p.integrity = 1.0; }; };
    this.UpdateVArmorBar();
    FTLog("[SDPCombat] V's armour repaired");
  }

  // Combat Evolved state of each sampled shooter (0 neutral .. 5 panicking), plus crippled-arm shots
  private let m_ceStates: array<Int32>;
  private let m_ceCrippled: Int32;
  public final func RecordCEState(state: Int32, crippled: Bool) -> Void {
    if ArraySize(this.m_ceStates) < 6 { ArrayResize(this.m_ceStates, 6); };
    this.m_ceStates[Clamp(state, 0, 5)] += 1;
    if crippled { this.m_ceCrippled += 1; };
  }

  // enemy armour kits met (one count per NPC hit by V)
  private let m_kitLabels: array<String>;
  private let m_kitCounts: array<Int32>;
  public final func NoteKit(label: String) -> Void {
    let i = 0;
    while i < ArraySize(this.m_kitLabels) {
      if Equals(this.m_kitLabels[i], label) { this.m_kitCounts[i] += 1; return; };
      i += 1;
    };
    ArrayPush(this.m_kitLabels, label);
    ArrayPush(this.m_kitCounts, 1);
  }

  public final func RecordArmor(direction: Int32, covered: Bool, penetrated: Bool, broke: Bool, fatal: Bool) -> Void {
    if ArraySize(this.m_armorCovered) < 2 {
      ArrayResize(this.m_armorCovered, 2); ArrayResize(this.m_armorStopped, 2); ArrayResize(this.m_armorBroken, 2); ArrayResize(this.m_fatal, 2);
    };
    let d = direction == 1 ? 0 : 1;
    if covered { this.m_armorCovered[d] += 1; };
    if covered && !penetrated { this.m_armorStopped[d] += 1; };
    if broke { this.m_armorBroken[d] += 1; };
    if fatal { this.m_fatal[d] += 1; };
  }

  // Decision G measurement: actual per-hit damage per weapon, next to what the weapon record says the gun does.
  public final func RecordWeaponDamage(direction: Int32, weapon: wref<WeaponObject>, damage: Float) -> Void {
    if !IsDefined(weapon) { return; };
    let id = ItemID.GetTDBID(weapon.GetItemID());
    let i = 0;
    while i < ArraySize(this.m_wdIds) {
      if this.m_wdIds[i] == id && this.m_wdDir[i] == direction {
        this.m_wdSum[i] += damage;
        this.m_wdN[i] += 1;
        return;
      };
      i += 1;
    };
    let info = "";
    let owner = weapon.GetOwner() as NPCPuppet;
    if IsDefined(owner) {
      let vv: ref<SDPVVersion>;
      let src = SDPStatSource.Make(owner, weapon);
      if IsDefined(vv) { info = s"V's version: dmg/hit=\(vv.damage) kick=\(vv.kickMin)-\(vv.kickMax) quality=\(vv.quality) (enemy gun quality \(vv.enemyQuality)) mods=\(vv.mods) | "; };
      info += s"NPC package dmg/hit=\(src.Runtime(gamedataStatType.DamagePerHit)) effective=\(src.Runtime(gamedataStatType.EffectiveDamagePerHit)) base=\(src.Runtime(gamedataStatType.BaseDamage)) phys=\(src.Runtime(gamedataStatType.PhysicalDamage)) | V's version of the gun at this NPC's level dmg/hit=\(src.RecordOnly(gamedataStatType.DamagePerHit)) effective=\(src.RecordOnly(gamedataStatType.EffectiveDamagePerHit)) base=\(src.RecordOnly(gamedataStatType.BaseDamage)) phys=\(src.RecordOnly(gamedataStatType.PhysicalDamage))";
    } else {
      let s = GameInstance.GetStatsSystem(weapon.GetGame());
      let wid = Cast<StatsObjectID>(weapon.GetEntityID());
      info = s"V's gun dmg/hit=\(s.GetStatValue(wid, gamedataStatType.DamagePerHit)) effective=\(s.GetStatValue(wid, gamedataStatType.EffectiveDamagePerHit)) base=\(s.GetStatValue(wid, gamedataStatType.BaseDamage)) phys=\(s.GetStatValue(wid, gamedataStatType.PhysicalDamage))";
    };
    ArrayPush(this.m_wdIds, id);
    ArrayPush(this.m_wdDir, direction);
    ArrayPush(this.m_wdSum, damage);
    ArrayPush(this.m_wdN, 1);
    ArrayPush(this.m_wdInfo, info);
  }

  public final func RecordPredictedVsActual(predicted: Int32, actual: Int32, height: Float) -> Void {
    if ArraySize(this.m_partMatrix) < 20 { ArrayResize(this.m_partMatrix, 20); ArrayResize(this.m_partHeight, 4); };
    let p = Max(0, Min(3, predicted));
    let a = Max(0, Min(4, actual));
    this.m_partMatrix[p * 5 + a] += 1;
    this.m_partHeight[p] += height;
  }

  public final func RecordAbsorbed(damage: Float) -> Void {
    this.m_absorbedHits += 1;
    this.m_absorbedDamage += damage;
  }

  public final func RecordOutOfRangeHold() -> Void {
    this.m_outOfRangeHolds += 1;
  }

  public final func RecordFirstShot(raised: Bool, delay: Float) -> Void {
    this.m_firstShots += 1;
    if raised { this.m_firstShotsRaised += 1; };
    this.m_firstShotDelay += delay;
  }

  public final func RecordAimZone(zone: Int32) -> Void {
    if zone < 0 || zone > 3 { return; };
    this.m_aimZones[zone] += 1;
  }

  public final func RecordHit(direction: Int32, zone: Int32, penetrated: Bool, pctOfMax: Float) -> Void {
    let d = direction == 1 ? 0 : 1;
    this.m_dmgHits[d] += 1;
    if penetrated { this.m_dmgPen[d] += 1; };
    this.m_dmgPct[d] += pctOfMax;
    if zone >= 0 && zone <= 4 { this.m_hitZones[d * 5 + zone] += 1; };
  }

  // Close the current test segment (report + reset) and start a new labelled one.
  public final func Mark(label: String) -> Void {
    this.Report();
    this.ResetStats();
    this.m_segment = label;
    FTLog(s"[SDPCombat] === segment: \(label) ===");
  }

  public final func SetEnabled(value: Bool) -> Void {
    this.m_enabled = value;
    FTLog(s"[SDPCombat] enabled = \(value)");
  }

  public final func SetAllHostiles(value: Bool) -> Void {
    this.m_allHostiles = value;
    FTLog(s"[SDPCombat] allHostiles = \(value)");
  }

  public final func SetLogShots(value: Bool) -> Void {
    this.m_logShots = value;
    FTLog(s"[SDPCombat] logShots = \(value)");
  }

  public final func ResetStats() -> Void {
    ArrayClear(this.m_ceStates); ArrayResize(this.m_ceStates, 6);
    this.m_ceCrippled = 0;
    ArrayClear(this.m_kitLabels); ArrayClear(this.m_kitCounts);
    SDPCEBridge.ResetEvents(this.GetGameInstance());
    ArrayClear(this.m_shots); ArrayResize(this.m_shots, 5);
    ArrayClear(this.m_hits); ArrayResize(this.m_hits, 5);
    ArrayClear(this.m_sumP); ArrayResize(this.m_sumP, 5);
    ArrayClear(this.m_pauses); ArrayResize(this.m_pauses, 5);
    ArrayClear(this.m_sumPause); ArrayResize(this.m_sumPause, 5);
    ArrayClear(this.m_zeroPauses); ArrayResize(this.m_zeroPauses, 5);
    ArrayClear(this.m_binShots); ArrayResize(this.m_binShots, 20);
    ArrayClear(this.m_binHits); ArrayResize(this.m_binHits, 20);
    ArrayClear(this.m_binP); ArrayResize(this.m_binP, 20);
    ArrayClear(this.m_blocked); ArrayResize(this.m_blocked, 5);
    ArrayClear(this.m_covered); ArrayResize(this.m_covered, 5);
    ArrayClear(this.m_pauseHist); ArrayResize(this.m_pauseHist, 25);
    ArrayClear(this.m_aimZones); ArrayResize(this.m_aimZones, 4);
    ArrayClear(this.m_hitZones); ArrayResize(this.m_hitZones, 10);
    ArrayClear(this.m_armorCovered); ArrayResize(this.m_armorCovered, 2);
    ArrayClear(this.m_armorStopped); ArrayResize(this.m_armorStopped, 2);
    ArrayClear(this.m_armorBroken); ArrayResize(this.m_armorBroken, 2);
    ArrayClear(this.m_fatal); ArrayResize(this.m_fatal, 2);
    ArrayClear(this.m_wdIds); ArrayClear(this.m_wdDir); ArrayClear(this.m_wdSum); ArrayClear(this.m_wdN); ArrayClear(this.m_wdInfo);
    ArrayClear(this.m_dmgHits); ArrayResize(this.m_dmgHits, 2);
    ArrayClear(this.m_dmgPen); ArrayResize(this.m_dmgPen, 2);
    ArrayClear(this.m_dmgPct); ArrayResize(this.m_dmgPct, 2);
    this.m_firstShots = 0;
    this.m_firstShotsRaised = 0;
    this.m_firstShotDelay = 0.0;
    this.m_outOfRangeHolds = 0;
    this.m_absorbedHits = 0;
    this.m_aimingDelayRemoved = 0;
    this.m_blindShots = 0;
    this.m_unsampledHits = 0;
    ArrayClear(this.m_partMatrix); ArrayResize(this.m_partMatrix, 20);
    ArrayClear(this.m_partHeight); ArrayResize(this.m_partHeight, 4);
    this.m_absorbedDamage = 0.0;
    ArrayClear(this.m_beliefN); ArrayResize(this.m_beliefN, 4);
    ArrayClear(this.m_beliefAbs); ArrayResize(this.m_beliefAbs, 4);
  }

  public static func LateralBin(lateral: Float) -> Int32 {
    if lateral < 0.3 { return 0; };
    if lateral < 1.5 { return 1; };
    if lateral < 4.0 { return 2; };
    return 3;
  }

  public final func RecordAimedShot(tier: Int32, lateral: Float, exposure: Float, p: Float, hit: Bool) -> Void {
    if tier < 0 || tier > 4 { return; };
    this.RecordShot(tier, p, hit);
    let i = tier * 4 + SDPCombatSystem.LateralBin(lateral);
    this.m_binShots[i] += 1;
    this.m_binP[i] += p;
    if hit { this.m_binHits[i] += 1; };
    if exposure < 0.95 { this.m_covered[tier] += 1; };
  }

  public final func RecordBlockedShot(tier: Int32) -> Void {
    if tier < 0 || tier > 4 { return; };
    this.RecordShot(tier, 0.0, false);
    this.m_blocked[tier] += 1;
  }

  public final func SetTestGodMode(value: Bool) -> Void {
    let game = this.GetGameInstance();
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    if !IsDefined(player) { FTLog("[SDPCombat] test god mode: no player"); return; };
    let gm = GameInstance.GetGodModeSystem(game);
    let id = player.GetEntityID();
    if value {
      gm.AddGodMode(id, gameGodModeType.Invulnerable, n"SDPCombatTest");
      gm.AddGodMode(id, gameGodModeType.Immortal, n"SDPCombatTest");
    } else {
      gm.RemoveGodMode(id, gameGodModeType.Invulnerable, n"SDPCombatTest");
      gm.RemoveGodMode(id, gameGodModeType.Immortal, n"SDPCombatTest");
    };
    this.m_testGodMode = value;
    FTLog(s"[SDPCombat] test god mode request=\(value): damage to V zeroed after logging=\(value) invulnerable=\(gm.HasGodMode(id, gameGodModeType.Invulnerable)) immortal=\(gm.HasGodMode(id, gameGodModeType.Immortal))");
  }

  public final func RecordShot(tier: Int32, p: Float, hit: Bool) -> Void {
    if tier < 0 || tier > 4 { return; };
    this.m_shots[tier] += 1;
    this.m_sumP[tier] += p;
    if hit { this.m_hits[tier] += 1; };
  }

  public final func RecordPause(tier: Int32, pause: Float) -> Void {
    if tier < 0 || tier > 4 { return; };
    this.m_pauses[tier] += 1;
    this.m_sumPause[tier] += pause;
    if pause <= 0.0 { this.m_zeroPauses[tier] += 1; };
    let b = 4;
    if pause <= 0.0 { b = 0; } else { if pause < 0.25 { b = 1; } else { if pause < 0.5 { b = 2; } else { if pause < 1.0 { b = 3; }; }; }; };
    this.m_pauseHist[tier * 5 + b] += 1;
  }

  public final func Report() -> Void {
    this.m_lastReport = "";
    this.R(s"report [\(this.m_segment)]: enabled=\(this.m_enabled) allHostiles=\(this.m_allHostiles)");
    let tier: Int32 = 0;
    while tier < 5 {
      let shots = this.m_shots[tier];
      let pauses = this.m_pauses[tier];
      if shots > 0 || pauses > 0 {
        let hitPct = shots > 0 ? 100.0 * Cast<Float>(this.m_hits[tier]) / Cast<Float>(shots) : 0.0;
        let meanP = shots > 0 ? 100.0 * this.m_sumP[tier] / Cast<Float>(shots) : 0.0;
        let meanPause = pauses > 0 ? this.m_sumPause[tier] / Cast<Float>(pauses) : 0.0;
        this.R(s"\(SDPProfiles.TierName(tier)): shots=\(shots) hit=\(hitPct)% meanP=\(meanP)% blocked=\(this.m_blocked[tier]) partlyCovered=\(this.m_covered[tier]) pauses=\(pauses) meanPause=\(meanPause)s");
        let bin = 0;
        while bin < 4 {
          let i = tier * 4 + bin;
          let n = this.m_binShots[i];
          if n > 0 {
            let binName = bin == 0 ? "V still" : (bin == 1 ? "V slow" : (bin == 2 ? "V strafe" : "V sprint"));
            this.R(s"  \(binName): shots=\(n) hit=\(100.0 * Cast<Float>(this.m_binHits[i]) / Cast<Float>(n))% meanP=\(100.0 * this.m_binP[i] / Cast<Float>(n))%");
          };
          bin += 1;
        };
        let h = tier * 5;
        this.R(s"  pauses: zero=\(this.m_pauseHist[h]) <0.25s=\(this.m_pauseHist[h + 1]) <0.5s=\(this.m_pauseHist[h + 2]) <1s=\(this.m_pauseHist[h + 3]) >=1s=\(this.m_pauseHist[h + 4])");
      };
      tier += 1;
    };
    if ArraySize(this.m_beliefN) == 4 {
      let names = ["still", "slow", "strafe", "sprint"];
      let bi = 0;
      while bi < 4 {
        if this.m_beliefN[bi] > 0 {
          this.R(s"game aim point vs V's real position, V \(names[bi]): shots=\(this.m_beliefN[bi]) mean sideways gap=\(this.m_beliefAbs[bi] / Cast<Float>(this.m_beliefN[bi]))m");
        };
        bi += 1;
      };
    };
    if ArraySize(this.m_partMatrix) == 20 && ArraySize(this.m_aimZones) >= 4 {
      let zn = ["miss", "head", "torso", "legs"];
      let zi = 0;
      while zi < 4 {
        let o = zi * 5;
        let hits = this.m_partMatrix[o] + this.m_partMatrix[o + 1] + this.m_partMatrix[o + 2] + this.m_partMatrix[o + 3] + this.m_partMatrix[o + 4];
        let aims = this.m_aimZones[zi];
        let meanH = hits > 0 ? this.m_partHeight[zi] / Cast<Float>(hits) : 0.0;
        this.R(s"aimed \(zn[zi]) x\(aims) -> hit V's head \(this.m_partMatrix[o + 1]), torso \(this.m_partMatrix[o + 2]), legs \(this.m_partMatrix[o + 3]), arms \(this.m_partMatrix[o + 4]), unknown part \(this.m_partMatrix[o]), no hit \(Max(0, aims - hits)); mean hit height \(meanH)m");
        zi += 1;
      };
    };
    if IsDefined(this.m_vArmor) {
      this.R(s"V's armour now: \(this.m_vArmor.Describe())");
    };
    let wi = 0;
    while wi < ArraySize(this.m_wdIds) {
      this.R(s"damage check \(this.m_wdDir[wi] == 1 ? "NPC->V" : "V->NPC") \(TDBID.ToStringDEBUG(this.m_wdIds[wi])): hits=\(this.m_wdN[wi]) mean damage before armour=\(this.m_wdSum[wi] / Cast<Float>(this.m_wdN[wi])) | \(this.m_wdInfo[wi])");
      wi += 1;
    };
    this.R(s"shots whose built-in aiming delay was replaced by the model: \(this.m_aimingDelayRemoved); blind shots at V's last known position (scattered by the model): \(this.m_blindShots); hits on V from shots the model did not sample (smart, blind fire): \(this.m_unsampledHits)");
    if this.m_testGodMode {
      this.R(s"test god mode: \(this.m_absorbedHits) hits on V absorbed, \(this.m_absorbedDamage) health damage not applied");
    };
    if this.m_outOfRangeHolds > 0 {
      this.R(s"held fire beyond weapon maximum range: \(this.m_outOfRangeHolds) times");
    };
    if this.m_firstShots > 0 {
      this.R(s"burst starts: \(this.m_firstShots) (weapon already raised \(this.m_firstShotsRaised)) mean first-shot delay \(this.m_firstShotDelay / Cast<Float>(this.m_firstShots))s");
    };
    let aimed = this.m_aimZones[0] + this.m_aimZones[1] + this.m_aimZones[2] + this.m_aimZones[3];
    if aimed > 0 {
      this.R(s"aim points: \(aimed) sampled -> on V's body \(aimed - this.m_aimZones[0]) (head \(this.m_aimZones[1]), torso \(this.m_aimZones[2]), legs \(this.m_aimZones[3])); physical hits on V counted below");
    };
    let d = 0;
    while d < 2 {
      let n = this.m_dmgHits[d];
      if n > 0 {
        let label = d == 0 ? "NPC->V" : "V->NPC";
        this.R(s"\(label): hits=\(n) penetrated=\(this.m_dmgPen[d]) meanDamage=\(this.m_dmgPct[d] / Cast<Float>(n))% of max HP  parts: unknown=\(this.m_hitZones[d * 5]) head=\(this.m_hitZones[d * 5 + 1]) torso=\(this.m_hitZones[d * 5 + 2]) legs=\(this.m_hitZones[d * 5 + 3]) arms=\(this.m_hitZones[d * 5 + 4])");
        if ArraySize(this.m_armorCovered) == 2 {
          this.R(s"  armour: \(this.m_armorCovered[d]) hits on armour, \(this.m_armorStopped[d]) stopped, \(this.m_armorBroken[d]) pieces broken, \(this.m_fatal[d]) fatal head hits");
        };
      };
      d += 1;
    };
    if ArraySize(this.m_kitLabels) > 0 {
      let kits = "";
      let k = 0;
      while k < ArraySize(this.m_kitLabels) {
        kits += s"\(k > 0 ? "; " : "")\(this.m_kitLabels[k]) x\(this.m_kitCounts[k])";
        k += 1;
      };
      this.R("enemy armour kits hit: " + kits);
    };
    if ArraySize(this.m_ceStates) == 6 {
      let total = 0;
      let c = 0;
      while c < 6 { total += this.m_ceStates[c]; c += 1; };
      if total > 0 {
        this.R(s"shooter state at each sampled shot: neutral \(this.m_ceStates[0]), in cover \(this.m_ceStates[1]), repositioning \(this.m_ceStates[2]), suppressing \(this.m_ceStates[3]), pinned \(this.m_ceStates[4]), panicking \(this.m_ceStates[5]); crippled arm \(this.m_ceCrippled)");
      };
    };
    this.R(SDPCEBridge.EventLine(this.GetGameInstance()));
  }
  // Report lines also go to the console log, which CET flushes on error('flush'); gamelog.log only flushes on exit.
  private final func R(line: String) -> Void {
    FTLog("[SDPCombat] " + line);
    this.m_lastReport += "[SDPCombat] " + line + "\n";
  }

  // Last segment report as text: print(SDPC:LastReport())
  public final func LastReport() -> String { return this.m_lastReport; }

  // Current counters as text without starting a new segment: print(SDPC:ReportText())
  public final func ReportText() -> String {
    this.Report();
    return this.m_lastReport;
  }

}

public class SDPArmorTick extends DelayCallback {
  public let system: wref<SDPCombatSystem>;
  public func Call() -> Void {
    if IsDefined(this.system) { this.system.ArmorTick(); };
  }
}
