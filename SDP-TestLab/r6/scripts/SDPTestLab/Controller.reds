// SDP TestLab: opt-in base-game mod qualification, never a survival-mode director.
// All commands and polls mutate state on one ScriptableSystem request queue.
// Requires Codeware, Combat Arena (read-only catalog/state), and SDP-Combat.
import SDPCombat.*

public class SDPTLCommand extends ScriptableSystemRequest {
  public let command: Int32;
  public let scenario: Int32;
  public let owner: wref<PlayerPuppet>;
}

public class SDPTLPoll extends ScriptableSystemRequest {
  public let generation: Int32;
}

public class SDPTLDelay extends DelayCallback {
  public let system: wref<SDPTLSystem>;
  public let generation: Int32;
  public func Call() -> Void {
    if !IsDefined(this.system) { return; };
    let request = new SDPTLPoll();
    request.generation = this.generation;
    this.system.QueueRequest(request);
  }
}

public abstract class SDPTLData {
  public static func Quote(value: String) -> String {
    let escaped = StrReplaceAll(value, "\\", "\\\\");
    escaped = StrReplaceAll(escaped, "\"", "\\\"");
    escaped = StrReplaceAll(escaped, "\n", "\\n");
    escaped = StrReplaceAll(escaped, "\r", "\\r");
    escaped = StrReplaceAll(escaped, "\t", "\\t");
    return "\"" + escaped + "\"";
  }

  public static func Now() -> Float { return EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance())); }

  public static func Position(pos: Vector4) -> String {
    return "[" + ToString(pos.X) + "," + ToString(pos.Y) + "," + ToString(pos.Z) + "]";
  }

  public static func Health(obj: ref<GameObject>) -> Float {
    return GameInstance.GetStatPoolsSystem(obj.GetGame()).GetStatPoolValue(Cast<StatsObjectID>(obj.GetEntityID()), gamedataStatPoolType.Health, false);
  }

  public static func Stat(obj: ref<GameObject>, stat: gamedataStatType) -> Float {
    return GameInstance.GetStatsSystem(obj.GetGame()).GetStatValue(Cast<StatsObjectID>(obj.GetEntityID()), stat);
  }

  public static func Snapshot(obj: ref<GameObject>) -> String {
    if !IsDefined(obj) { return "null"; };
    let gi = obj.GetGame();
    let pools = GameInstance.GetStatPoolsSystem(gi);
    let weapon = ScriptedPuppet.GetActiveWeapon(obj as ScriptedPuppet);
    let weaponId = "none";
    if IsDefined(weapon) { weaponId = TDBID.ToString(ItemID.GetTDBID(weapon.GetItemID())); };
    let npc = obj as NPCPuppet;
    let kit = "uninitialized";
    // Read the existing kit only: ForNPC/Update would initialize or repair it.
    if IsDefined(npc) && IsDefined(npc.m_sdpcArmor) { kit = npc.m_sdpcArmor.Describe(); };
    let god = GameInstance.GetGodModeSystem(gi);
    return "{\"entity\":" + SDPTLData.Quote(ToString(obj.GetEntityID()))
      + ",\"record\":" + SDPTLData.Quote(TDBID.ToString(obj.GetRecordID()))
      + ",\"position\":" + SDPTLData.Position(obj.GetWorldPosition())
      + ",\"hp\":" + ToString(SDPTLData.Health(obj))
      + ",\"hp_percent\":" + ToString(pools.GetStatPoolValue(Cast<StatsObjectID>(obj.GetEntityID()), gamedataStatPoolType.Health, true))
      + ",\"health_stat\":" + ToString(SDPTLData.Stat(obj, gamedataStatType.Health))
      + ",\"armor\":" + ToString(SDPTLData.Stat(obj, gamedataStatType.Armor))
      + ",\"level\":" + ToString(SDPTLData.Stat(obj, gamedataStatType.Level))
      + ",\"power_level\":" + ToString(SDPTLData.Stat(obj, gamedataStatType.PowerLevel))
      + ",\"weapon\":" + SDPTLData.Quote(weaponId)
      + ",\"armor_kit\":" + SDPTLData.Quote(kit)
      + ",\"dead\":" + ToString(obj.IsDead())
      + ",\"defeated\":" + ToString(ScriptedPuppet.IsDefeated(obj))
      + ",\"immortal\":" + ToString(god.HasGodMode(obj.GetEntityID(), gameGodModeType.Immortal))
      + ",\"invulnerable\":" + ToString(god.HasGodMode(obj.GetEntityID(), gameGodModeType.Invulnerable)) + "}";
  }
}

public class SDPTLSystem extends ScriptableSystem {
  private let m_state: Int32;
  private let m_status: String;
  private let m_report: String;
  private let m_generation: Int32;
  private let m_run: Int32;
  private let m_scenario: Int32;
  private let m_owner: wref<PlayerPuppet>;
  private let m_origin: Vector4;
  private let m_originAngles: EulerAngles;
  private let m_hasOrigin: Bool;
  private let m_ids: array<EntityID>;
  private let m_bound: array<Bool>;
  private let m_hp: array<Float>;
  private let m_finished: array<Bool>;
  private let m_samples: array<String>;
  private let m_dropped: Int32;
  private let m_readyAt: Float;
  private let m_requestedAt: Float;
  private let m_startedAt: Float;
  private let m_lastSample: Float;
  private let m_playerBaseline: Float;
  private let m_observation: Bool;
  private let m_baseline: String;

  public static func Get() -> ref<SDPTLSystem> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"SDPTLSystem") as SDPTLSystem;
  }

  public func State() -> Int32 { return this.m_state; }
  public func Status() -> String {
    return StrLen(this.m_status) == 0 ? "Idle. Use a dedicated test save; normal damage, XP and resource consumption apply." : this.m_status;
  }
  public func Report() -> String { return StrLen(this.m_report) == 0 ? "{}" : this.m_report; }

  private func ArenaBusy() -> Bool {
    let arena = ArenaSystem.Get();
    return IsDefined(arena) && (arena.state != 0 || arena.entering || IsDefined(arena.terminal));
  }

  private func Gameplay(player: ref<PlayerPuppet>) -> Bool {
    let handler = GameInstance.GetSystemRequestsHandler();
    return IsDefined(handler) && !handler.IsPreGame() && IsDefined(player)
      && player.IsPlayerControlled() && !player.IsDead()
      && !VehicleComponent.IsMountedToVehicle(GetGameInstance(), player);
  }

  private func PollLater() -> Void {
    let callback = new SDPTLDelay();
    callback.system = this;
    callback.generation = this.m_generation;
    GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(callback, 0.25, false);
  }

  private func Cleanup() -> Void {
    this.m_generation += 1;
    let entities = GameInstance.GetDynamicEntitySystem();
    if IsDefined(entities) && entities.IsReady() {
      // Unique owned tag; never touch CombatArena or other mod actors.
      entities.DeleteTagged(n"SDPTestLab");
    };
    ArrayClear(this.m_ids); ArrayClear(this.m_bound);
    ArrayClear(this.m_hp); ArrayClear(this.m_finished);
  }

  private func Event(kind: String, detail: String) -> Void {
    if ArraySize(this.m_samples) >= 512 { this.m_dropped += 1; return; };
    ArrayPush(this.m_samples, "{\"time_sim\":" + ToString(SDPTLData.Now())
      + ",\"kind\":" + SDPTLData.Quote(kind) + ",\"data\":" + detail + "}");
  }

  private func Capture(kind: String) -> Void {
    let actors = "[";
    let entities = GameInstance.GetDynamicEntitySystem();
    let i = 0;
    while i < ArraySize(this.m_ids) {
      if i > 0 { actors += ","; };
      actors += SDPTLData.Snapshot(entities.GetEntity(this.m_ids[i]) as GameObject);
      i += 1;
    };
    actors += "]";
    this.Event(kind, "{\"player\":" + SDPTLData.Snapshot(this.m_owner) + ",\"actors\":" + actors + "}");
    this.Publish();
  }

  private func Publish() -> Void {
    let events = "[";
    let i = 0;
    while i < ArraySize(this.m_samples) {
      if i > 0 { events += ","; };
      events += this.m_samples[i]; i += 1;
    };
    events += "]";
    let combat = SDPCombatSystem.Get(GetGameInstance());
    let config = "null";
    if IsDefined(combat) {
      config = "{\"enabled\":" + ToString(combat.IsEnabled())
        + ",\"durability\":" + ToString(combat.DurabilityEnabled())
        + ",\"incoming_scale\":" + ToString(combat.IncomingScale())
        + ",\"one_shot_protection\":" + ToString(combat.OneShotProtection())
        + ",\"test_god_mode\":" + ToString(combat.TestGodMode()) + "}";
    };
    this.m_report = "{\"schema\":1,\"build\":1,\"run\":" + ToString(this.m_run)
      + ",\"scenario\":" + ToString(this.m_scenario)
      + ",\"scenario_revision\":" + ToString(SDPTLScenario.Revision())
      + ",\"name\":" + SDPTLData.Quote(this.m_observation ? "Current-site observation" : SDPTLScenario.Name(this.m_scenario))
      + ",\"state\":" + ToString(this.m_state) + ",\"status\":" + SDPTLData.Quote(this.Status())
      + ",\"time_sim\":" + ToString(SDPTLData.Now()) + ",\"combat\":" + config
      + ",\"baseline\": + (StrLen(this.m_baseline) == 0 ? "null" : this.m_baseline)
      + ",\"dropped_samples\":" + ToString(this.m_dropped) + ",\"events\":" + events + "}";
  }

  private func Fail(reason: String) -> Void {
    this.m_state = 6; this.m_status = reason;
    this.Event("failed", SDPTLData.Quote(reason));
    this.Publish(); this.Cleanup();
  }

  private func Prepare(player: ref<PlayerPuppet>, scenario: Int32) -> Void {
    if !this.Gameplay(player) || this.ArenaBusy() { this.m_status = "Refused: exit Combat Arena survival/menu and enter normal on-foot gameplay first."; return; };
    if player.IsInCombat() { this.m_status = "Refused: finish current combat before transporting to the test site."; return; };
    if !SDPTLScenario.IsValid(scenario) || !SDPTLScenario.HasLocationData() { this.m_status = "Refused: scenario or audited Combat Arena location data mismatch."; return; };
    let entities = GameInstance.GetDynamicEntitySystem();
    if !IsDefined(entities) || !entities.IsReady() { this.m_status = "Dynamic entity system is not ready. Retry after loading."; return; };
    let records = SDPTLScenario.ActorRecords(scenario);
    for record in records {
      if !IsDefined(TweakDBInterface.GetCharacterRecord(record)) { this.m_status = "Missing character record: " + TDBID.ToString(record); return; };
    };
    this.Cleanup();
    this.m_owner = player;
    if !this.m_hasOrigin {
      this.m_origin = player.GetWorldPosition();
      this.m_originAngles = Quaternion.ToEulerAngles(player.GetWorldOrientation());
      this.m_hasOrigin = true;
    };
    this.m_run += 1; this.m_scenario = scenario; this.m_observation = false;
    ArrayClear(this.m_samples); this.m_dropped = 0;
    this.m_baseline = SDPTLData.Snapshot(player);
    let position = SDPTLScenario.PlayerPosition(scenario);
    position.Z += 0.2;
    let angles = new EulerAngles(); angles.Yaw = SDPTLScenario.PlayerYaw(scenario);
    GameInstance.GetTeleportationFacility(GetGameInstance()).Teleport(player, position, angles);
    this.m_state = 1;
    this.m_status = "Inspect the site: floor, routes and return path. Confirm site to spawn candidates. No health/inventory restoration is performed.";
    this.m_requestedAt = SDPTLData.Now();
    this.Event("prepare", this.m_baseline); this.Publish(); this.PollLater();
  }

  private func Spawn() -> Void {
    if this.m_state != 1 || !this.Gameplay(this.m_owner) { return; };
    let origin = SDPTLScenario.PlayerPosition(this.m_scenario);
    if Vector4.Distance(this.m_owner.GetWorldPosition(), origin) > 6.0 { this.m_status = "Return to the marked start area before confirming (within 6 m)."; return; };
    let records = SDPTLScenario.ActorRecords(this.m_scenario);
    let positions = SDPTLScenario.Positions(this.m_scenario);
    if ArraySize(records) != ArraySize(positions) || ArraySize(records) == 0 { this.Fail("Invalid scenario roster/position count."); return; };
    let system = GameInstance.GetDynamicEntitySystem();
    let i = 0;
    while i < ArraySize(records) {
      let spec = new DynamicEntitySpec();
      let angles = new EulerAngles(); angles.Yaw = SDPTLScenario.Facing(this.m_scenario, i);
      let pos = positions[i]; pos.Z += 0.2;
      spec.recordID = records[i]; spec.position = pos; spec.orientation = EulerAngles.ToQuat(angles);
      spec.persistState = false; spec.persistSpawn = false; spec.alwaysSpawned = true;
      spec.spawnInView = true; spec.tags = [n"SDPTestLab"];
      ArrayPush(this.m_ids, system.CreateEntity(spec));
      ArrayPush(this.m_bound, false); ArrayPush(this.m_hp, -1.0); ArrayPush(this.m_finished, false);
      i += 1;
    };
    this.m_state = 2; this.m_requestedAt = SDPTLData.Now(); this.m_readyAt = 0.0;
    this.m_playerBaseline = SDPTLData.Health(this.m_owner);
    this.m_status = "Waiting for all requested NPCs to attach and settle. Uncommanded combat invalidates preparation.";
    this.Event("spawn_requested", ToString(ArraySize(records))); this.Publish();
  }

  private func Start() -> Void {
    if this.m_state != 3 || !this.Gameplay(this.m_owner) { return; };
    if this.ArenaBusy() { this.Fail("Combat Arena became active; test cancelled."); return; };
    let god = GameInstance.GetGodModeSystem(GetGameInstance());
    if god.HasGodMode(this.m_owner.GetEntityID(), gameGodModeType.Immortal)
      || god.HasGodMode(this.m_owner.GetEntityID(), gameGodModeType.Invulnerable) {
      this.m_status = "Start refused: player immortality/invulnerability is active. Disable it through its owner for a valid damage test."; return;
    };
    let dilation = GameInstance.GetTimeSystem(GetGameInstance()).GetActiveTimeDilation();
    if AbsF(dilation - 1.0) > 0.01 { this.m_status = "Start refused: close time-dilating menus/scanner and retry."; return; };
    let system = GameInstance.GetDynamicEntitySystem();
    for id in this.m_ids {
      let npc = system.GetEntity(id) as NPCPuppet;
      if !IsDefined(npc) || npc.IsDead() || ScriptedPuppet.IsDefeated(npc) { this.Fail("Actor disappeared or was defeated before start."); return; };
    };
    this.m_startedAt = SDPTLData.Now(); this.m_lastSample = this.m_startedAt;
    this.m_baseline = SDPTLData.Snapshot(this.m_owner);
    this.m_state = 4; this.m_status = "Running. Native perception only; no forced target updates. Close CET and engage. Normal death/XP/resources apply.";
    this.Capture("start");
    for id in this.m_ids {
      let npc = system.GetEntity(id) as NPCPuppet;
      let agent = npc.GetAttitudeAgent();
      agent.SetAttitudeGroup(n"hostile");
      agent.SetAttitudeTowards(this.m_owner.GetAttitudeAgent(), EAIAttitude.AIA_Hostile);
    };
  }

  private func OnSDPTLCommand(request: ref<SDPTLCommand>) -> Void {
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(request.owner) || !IsDefined(player) || request.owner != player { return; };
    let command = request.command;
    if command == 9 {
      this.Cleanup(); this.m_state = 0; this.m_owner = player; this.m_hasOrigin = false;
      this.m_status = "Session reset. Reloaded saves do not resume a test run."; this.Publish(); return;
    };
    if command == 3 || command == 5 {
      if IsDefined(this.m_owner) { this.Capture("stop"); };
      this.Cleanup(); this.m_state = 0; this.m_status = "Stopped; owned actors removed. Player supplies, injuries and progression remain changed. Reload your baseline for matched trials.";
      if command == 5 && this.m_hasOrigin && this.Gameplay(player) && !this.ArenaBusy() {
        GameInstance.GetTeleportationFacility(GetGameInstance()).Teleport(player, this.m_origin, this.m_originAngles);
        this.m_hasOrigin = false; this.m_status = "Returned to origin; reload your test-save baseline to restore gameplay state.";
      };
      this.Publish(); return;
    };
    if command == 6 {
      this.Event("survey", SDPTLData.Snapshot(player)); this.Publish(); return;
    };
    if command == 1 { this.Prepare(player, request.scenario); return; };
    if command == 4 { this.Prepare(player, this.m_scenario); return; };
    if command == 7 { this.Spawn(); return; };
    if command == 2 { this.Start(); return; };
    if command == 8 {
      if !this.Gameplay(player) || this.ArenaBusy() { this.m_status = "Observation refused: normal on-foot gameplay required."; return; };
      this.Cleanup(); this.m_owner = player; this.m_observation = true; this.m_run += 1;
      ArrayClear(this.m_samples); this.m_dropped = 0; this.m_baseline = SDPTLData.Snapshot(player);
      this.m_state = 4; this.m_startedAt = SDPTLData.Now(); this.m_lastSample = this.m_startedAt;
      this.m_status = "Observing the current site. No NPCs, cameras, network links or quest state are created/changed.";
      this.Capture("observation_start"); this.PollLater(); return;
    };
  }

  private func OnSDPTLPoll(request: ref<SDPTLPoll>) -> Void {
    if request.generation != this.m_generation || this.m_state < 1 || this.m_state > 4 { return; };
    let player = GetPlayer(GetGameInstance());
    if !IsDefined(player) || player != this.m_owner { this.Fail("Player/session changed."); return; };
    if this.ArenaBusy() { this.Fail("Combat Arena survival/menu opened. Test cancelled to avoid contamination."); return; };
    if player.IsDead() { this.Capture("player_dead"); this.Fail("Player died. Normal death/reload; no test respawn or healing."); return; };
    let now = SDPTLData.Now();
    let entities = GameInstance.GetDynamicEntitySystem();
    if !IsDefined(entities) || !entities.IsReady() { this.Fail("Dynamic entity service unavailable."); return; };
    if this.m_state == 2 || this.m_state == 3 {
      let allReady = true;
      let i = 0;
      while i < ArraySize(this.m_ids) {
        let npc = entities.GetEntity(this.m_ids[i]) as NPCPuppet;
        if !IsDefined(npc) || !npc.IsAttached() { allReady = false; }
        else {
          if !this.m_bound[i] {
            let attitude = npc.GetAttitudeAgent();
            if !IsDefined(attitude) { allReady = false; }
            else {
              attitude.SetAttitudeGroup(n"neutral");
              attitude.SetAttitudeTowards(player.GetAttitudeAgent(), EAIAttitude.AIA_Neutral);
              this.m_bound[i] = true; this.m_hp[i] = SDPTLData.Health(npc);
              this.Event("actor_attached", SDPTLData.Snapshot(npc));
            };
          };
          if npc.IsDead() || ScriptedPuppet.IsDefeated(npc) || NPCPuppet.IsInCombat(npc)
            || (this.m_bound[i] && AbsF(SDPTLData.Health(npc) - this.m_hp[i]) > 0.1) {
            this.Fail("Preparation invalidated: actor combat, defeat or health drift. Reload/prepare again."); return;
          };
        };
        i += 1;
      };
      if AbsF(SDPTLData.Health(player) - this.m_playerBaseline) > 0.1 || player.IsInCombat() {
        this.Fail("Preparation invalidated: player health/combat changed."); return;
      };
      if allReady {
        if this.m_readyAt <= 0.0 { this.m_readyAt = now; };
        if this.m_state == 2 && now - this.m_readyAt >= 1.0 {
          this.m_state = 3; this.m_status = "Actors attached. Inspect equipment/armor/routes, then Start after closing CET. Attachment does not qualify AI or network behavior.";
          this.Capture("ready");
        };
      } else {
        this.m_readyAt = 0.0;
        if now - this.m_requestedAt > 20.0 { this.Fail("Actor attachment timed out; owned actors cleaned up."); return; };
      };
    };
    if this.m_state == 4 {
      let alive = 0;
      let i = 0;
      while i < ArraySize(this.m_ids) {
        let npc = entities.GetEntity(this.m_ids[i]) as NPCPuppet;
        if !IsDefined(npc) { this.Fail("Registered actor disappeared; result invalid, not a kill."); return; };
        let finished = npc.IsDead() || ScriptedPuppet.IsDefeated(npc) || ScriptedPuppet.IsUnconscious(npc);
        if !finished { alive += 1; }
        else {
          if !this.m_finished[i] { this.m_finished[i] = true; this.Event("neutralized_sample", SDPTLData.Snapshot(npc)); };
        };
        i += 1;
      };
      if now - this.m_lastSample >= 1.0 { this.m_lastSample = now; this.Capture("sample"); };
      if !this.m_observation && alive == 0 {
        this.m_state = 5; this.m_status = "Encounter neutralized. Export report; corpses remain until cleanup. Reload baseline for comparable trials.";
        this.Capture("complete"); return;
      };
      if now - this.m_startedAt >= 300.0 {
        this.m_state = 5; this.m_status = "Five-minute capture finished; owned actors cleaned up.";
        this.Capture("time_limit"); this.Cleanup(); return;
      };
    };
    this.PollLater();
  }
}

@addMethod(PlayerPuppet)
public final func SDPTL_Command(command: Int32, scenario: Int32) -> Void {
  let request = new SDPTLCommand(); request.command = command; request.scenario = scenario; request.owner = this;
  let system = SDPTLSystem.Get(); if IsDefined(system) { system.QueueRequest(request); };
}
@addMethod(PlayerPuppet)
public final func SDPTL_State() -> Int32 { return SDPTLSystem.Get().State(); }
@addMethod(PlayerPuppet)
public final func SDPTL_Status() -> String { return SDPTLSystem.Get().Status(); }
@addMethod(PlayerPuppet)
public final func SDPTL_Report() -> String { return SDPTLSystem.Get().Report(); }
@addMethod(PlayerPuppet)
public final func SDPTL_Ready() -> Bool { return SDPTLSystem.Get().State() == 3; }
@addMethod(PlayerPuppet)
public final func SDPTL_ScenarioCount() -> Int32 { return SDPTLScenario.Count(); }
@addMethod(PlayerPuppet)
public final func SDPTL_ScenarioName(index: Int32) -> String { return SDPTLScenario.Name(index); }
@addMethod(PlayerPuppet)
public final func SDPTL_ScenarioSummary(index: Int32) -> String { return SDPTLScenario.Notes(index); }
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  wrappedMethod(); this.SDPTL_Command(9, 0);
}
