// The new-game character creator has its own attribute point controls.
module SkillDrivenProgression

@wrapMethod(CharacterCreationStatsMenu)
protected cb func OnInitialize() -> Bool {
  wrappedMethod();
  inkWidgetRef.SetVisible(this.m_pointsLabel, false);
  this.m_attributePointsAvailable = 0;
  inkTextRef.SetText(this.m_skillPointLabel, s"0");
}

@wrapMethod(CharacterCreationStatsMenu)
private final func ResetAllBtnBackToBaseline() -> Void {
  wrappedMethod();
  this.m_attributePointsAvailable = 0;
  inkTextRef.SetText(this.m_skillPointLabel, s"0");
}

@replaceMethod(CharacterCreationStatsMenu)
private final func CanBeIncremented(currValue: Int32) -> Bool {
  return false;
}

@replaceMethod(CharacterCreationStatsMenu)
private final func CanBeDecremented(currValue: Int32) -> Bool {
  return false;
}

@replaceMethod(CharacterCreationStatsMenu)
private final func Add(targetWidget: wref<inkWidget>) -> Void {}

@replaceMethod(CharacterCreationStatsMenu)
private final func Subtract(targetWidget: wref<inkWidget>) -> Void {}

@wrapMethod(PlayerDevelopmentData)
public final func RefreshDevelopmentSystemOnNewGameStarted() -> Void {
  wrappedMethod();
  this.SDP_ClearAttributePoints();
  this.SDP_RecalculateAllAttributes();
  this.SDP_RecalculateSkillDrivenLevel();
}
