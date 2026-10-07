module SDPCE

// What CE is allowed to DO to an NPC, as opposed to what it is allowed to BE. (｡◕‿◕｡)

public static func GBPIsSacredBody(npc: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) { return true; }
  return ScriptedPuppet.IsDefeated(npc)
    || ScriptedPuppet.IsUnconscious(npc)
    || StatusEffectSystem.ObjectHasStatusEffect(npc, t"BaseStatusEffect.InvulnerableAfterDefeated");
}

public static func GBPIsCorpse(npc: ref<ScriptedPuppet>) -> Bool {
  return !IsDefined(npc) || npc.IsDead() || npc.IsDeadNoStatPool();
}

public static func GBPIsDownedNPC(npc: ref<ScriptedPuppet>) -> Bool {
  return !IsDefined(npc) || npc.IsDead() || npc.IsDeadNoStatPool() || GBPIsSacredBody(npc);
}

public static func GBPUnderAuthoredControl(npc: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) { return true; }
  if StatusEffectSystem.ObjectHasStatusEffectWithTag(npc, n"LoreAnim") { return true; }
  if StatusEffectSystem.ObjectHasStatusEffect(npc, t"BaseStatusEffect.Grappled") { return true; }

  let preset: gamedataReactionPresetType = npc.GetPuppetReactionPresetType();
  if Equals(preset, gamedataReactionPresetType.NoReaction) || Equals(preset, gamedataReactionPresetType.Follower) { return true; }

  let moves: ref<MovePoliciesComponent> = npc.GetMovePolicesComponent();
  if IsDefined(moves) && moves.IsOnOffMeshLink() { return true; }

  let bb: ref<IBlackboard> = npc.GetPuppetStateBlackboard();
  if IsDefined(bb) && bb.GetBool(GetAllBlackboardDefs().PuppetState.WorkspotAnimationInProgress) { return true; }

  let gi: GameInstance = npc.GetGame();
  let workspots: ref<WorkspotGameSystem> = GameInstance.GetWorkspotSystem(gi);
  if IsDefined(workspots) && workspots.IsActorInWorkspot(npc) { return true; }
  if AIActionHelper.HasWorkspotAICommand(npc) { return true; }

  let scene: ref<SceneSystemInterface> = GameInstance.GetSceneSystem(gi).GetScriptInterface();
  if IsDefined(scene) && (scene.IsEntityInDialogue(npc.GetEntityID()) || scene.IsEntityInScene(npc.GetEntityID())) { return true; }

  return false;
}

public static func GBPMayCommand(npc: ref<ScriptedPuppet>) -> Bool {
  return IsDefined(npc) && !GBPIsDownedNPC(npc) && !GBPUnderAuthoredControl(npc);
}

public static func GBPMayPullIntoFight(npc: ref<ScriptedPuppet>) -> Bool {
  return GBPMayCommand(npc) && !npc.IsQuest();
}

public static func GBPNeverFears(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) { return false; }
  if npc.IsMechanical() { return true; }
  let t: gamedataNPCType = npc.GetNPCType();
  if Equals(t, gamedataNPCType.Android) || Equals(t, gamedataNPCType.Drone) || Equals(t, gamedataNPCType.Mech)
    || Equals(t, gamedataNPCType.Spiderbot) || Equals(t, gamedataNPCType.Cerberus) || Equals(t, gamedataNPCType.Chimera)
    || Equals(t, gamedataNPCType.Device) { return true; }
  let reactions: ref<ReactionManagerComponent> = npc.GetStimReactionComponent();
  if !IsDefined(reactions) { return false; }
  let preset: wref<ReactionPreset_Record> = reactions.GetReactionPreset();
  return IsDefined(preset) && Equals(preset.Type(), gamedataReactionPresetType.NoReaction);
}
