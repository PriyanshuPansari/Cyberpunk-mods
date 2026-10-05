// Takedown rules with ENC (Enemies of Night City): ENC sends Elite/Boss
// rarity straight to the grapple struggle; that rule is dropped here, so only
// enemies that can break a hold (CanGuardBreak, ENC's "break hold") struggle
// at once. The base game's rules are kept: skull-level enemies (power level
// far above the player) and MiniBoss/MaxTac enemies still break free, and
// ENC's Body/Cool requirements in GrappleBreakFreeDecisions still apply.
module SkillDrivenProgression

public func SDP_TargetCanBreakHold(target: wref<GameObject>) -> Bool {
  if !IsDefined(target) { return false; };
  return GameInstance.GetStatsSystem(target.GetGame())
    .GetStatValue(Cast<StatsObjectID>(target.GetEntityID()), gamedataStatType.CanGuardBreak) > 0.00;
}

// Replaces ENC's version: vanilla's timer and swimming checks plus ENC's
// break-hold check, without ENC's rarity check.
@wrapMethod(GrappleStandDecisions)
protected const final func ToGrappleStruggle(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if this.GetInStateTime() >= stateContext.GetFloatParameter(n"grappleTime", true) {
    return this.IsBreakingFreeAllowed(stateContext, scriptInterface);
  };
  if this.IsDeepEnoughToSwim(scriptInterface) { return true; };
  return SDP_TargetCanBreakHold(this.stateMachineInitData.target);
}
