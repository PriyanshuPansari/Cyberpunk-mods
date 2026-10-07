module SkillDrivenProgression

// Preserve the real purchase ledger. After a vanilla rank changes, its source
// package takes precedence over a shard clone; refunds restore the clone only
// if the character still owns or has installed that shard effect.
@wrapMethod(PlayerDevelopmentData)
private final const func ActivateNewPerk(perkType: gamedataNewPerkType, perkLevel: Int32) -> Void {
  wrappedMethod(perkType, perkLevel);
  this.SDP_PrototypeReconcileDeadeye();
}

@wrapMethod(PlayerDevelopmentData)
private final const func DeactivateNewPerk(perkType: gamedataNewPerkType, perkLevel: Int32) -> Void {
  wrappedMethod(perkType, perkLevel);
  this.SDP_PrototypeReconcileDeadeye();
}
