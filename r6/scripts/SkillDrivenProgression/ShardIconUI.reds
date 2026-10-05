// The quest Relic chip atlas part is larger than a normal inventory icon.
// Keep its image widget inside the inventory modification tile.
module SkillDrivenProgression

public func SDP_IsProcessorShard(itemID: TweakDBID) -> Bool {
  return Equals(itemID, t"SkillDrivenProgression.DeadeyeTier1Shard")
    || Equals(itemID, t"SkillDrivenProgression.DeadeyeTier1PlusShard")
    || SDP_OrderDeadeyeItemGrade(itemID) > 0
    || SDP_FamilyItemFamily(itemID) > 0
    || Equals(itemID, t"SkillDrivenProgression.RelicModule");
}

@wrapMethod(InventoryItemDisplayController)
protected func NewUpdateIcon(itemData: ref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  if IsDefined(itemData) && SDP_IsProcessorShard(itemData.GetTweakDBID())
    && inkWidgetRef.IsValid(this.m_itemImage) {
    inkWidgetRef.SetFitToContent(this.m_itemImage, false);
    inkWidgetRef.SetSize(this.m_itemImage, 72.00, 72.00);
    inkWidgetRef.SetScale(this.m_itemImage, new Vector2(1.00, 1.00));
  };
}

@wrapMethod(InventoryItemDisplayController)
protected func UpdateIcon() -> Void {
  wrappedMethod();
  if SDP_IsProcessorShard(ItemID.GetTDBID(InventoryItemData.GetID(this.m_itemData)))
    && inkWidgetRef.IsValid(this.m_itemImage) {
    inkWidgetRef.SetFitToContent(this.m_itemImage, false);
    inkWidgetRef.SetSize(this.m_itemImage, 72.00, 72.00);
    inkWidgetRef.SetScale(this.m_itemImage, new Vector2(1.00, 1.00));
  };
}
