module SkillDrivenProgression

@if(ModuleExists("SDPCombat.BlindAim"))
import SDPCombat.BlindAim.SDPBlindAimMemory

// Optional bridge: neither standalone mod requires the other. The feature's
// module is checked, rather than assuming every SDPCombat version has it.
public abstract class SDPCombatBlindTrace {
  @if(ModuleExists("SDPCombat.BlindAim"))
  public static func Describe(npc: ref<NPCPuppet>) -> String {
    let memory = npc.m_sdpcBlindAim;
    if IsDefined(memory) && memory.frozen {
      return " combatAim=frozen point=" + ToString(memory.frozenPoint)
        + " pointSource=" + (memory.fromSight ? "last_sighted_shot" : "initial_facing");
    };
    return " combatAim=not_frozen";
  }

  @if(!ModuleExists("SDPCombat.BlindAim"))
  public static func Describe(npc: ref<NPCPuppet>) -> String {
    return " combatAim=module_unavailable";
  }
}
