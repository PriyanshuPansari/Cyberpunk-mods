// Attributes come from skills and cannot be bought or sold manually.
// Primary perk points are also disabled for now; Relic points remain available.
module SkillDrivenProgression

@wrapMethod(PlayerDevelopmentData)
private final const func GetDevPointsForLevel(level: Int32, profType: gamedataProficiencyType, devPtsType: gamedataDevelopmentPointType) -> Int32 {
  if Equals(devPtsType, gamedataDevelopmentPointType.Attribute) || Equals(devPtsType, gamedataDevelopmentPointType.Primary) {
    return -1;
  };
  return wrappedMethod(level, profType, devPtsType);
}

@wrapMethod(PlayerDevelopmentData)
public final const func AddDevelopmentPoints(amount: Int32, type: gamedataDevelopmentPointType) -> Void {
  if Equals(type, gamedataDevelopmentPointType.Attribute) || Equals(type, gamedataDevelopmentPointType.Primary) {
    return;
  };
  wrappedMethod(amount, type);
}

@addMethod(PlayerDevelopmentData)
public final func SDP_ClearAttributePoints() -> Void {
  let index: Int32 = this.GetDevPointsIndex(gamedataDevelopmentPointType.Attribute);
  if index >= 0 {
    this.m_devPoints[index].unspent = 0;
  };
}

@replaceMethod(PlayerDevelopmentData)
public final const func CanAttributeBeBought(type: gamedataStatType) -> Bool {
  return false;
}

@replaceMethod(PlayerDevelopmentData)
public final const func SellAttribute(type: gamedataStatType) -> Bool {
  return false;
}

@wrapMethod(PlayerDevelopmentData)
public final const func ResetAttributes() -> Void {
  wrappedMethod();
  this.SDP_ClearAttributePoints();
  this.SDP_RecalculateAllAttributes();
}
