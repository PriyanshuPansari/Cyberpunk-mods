// The processor's ordinary inventory modification screen owns these actions.
// Upgrades use components directly; opening a ripperdoc is unnecessary.
module SkillDrivenProgression

@wrapMethod(InventoryItemModeLogicController)
private final func SetInventoryItemButtonHintsHoverOver(const displayingData: script_ref<InventoryItemData>, opt display: ref<InventoryItemDisplayController>) -> Void {
  wrappedMethod(displayingData, display);
  this.m_buttonHintsController.RemoveButtonHint(n"upgrade_cyberware");
  if !IsDefined(display) || !IsDefined(this.itemChooser)
    || NotEquals(ItemID.GetTDBID(this.itemChooser.GetModifiedItemID()), t"SkillDrivenProgression.NeuralProcessor") {
    return;
  };
  let itemID: TweakDBID = ItemID.GetTDBID(InventoryItemData.GetID(displayingData));
  let family: Int32 = SDP_FamilyItemFamily(itemID);
  if family > 0 {
    let grade: Int32 = SDP_FamilyItemGrade(itemID);
    let familyData: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this.m_player);
    if IsDefined(familyData) {
      if Equals(display.GetDisplayContext(), ItemDisplayContext.Attachment) {
        if familyData.SDP_FamilyTrainingGrade(family) == grade
          && familyData.SDP_FamilyXP(family, grade) >= SDP_FamilyThreshold(family, grade) {
          this.m_buttonHintsController.AddButtonHint(
            n"upgrade_cyberware", "Record " + SDP_FamilyName(family) + " " + SDP_FamilyGradeLabel(grade)
          );
        };
      } else {
        let nextGrade: Int32 = grade + 1;
        if SDP_FamilyMaxGrade(family) > 1 && grade == familyData.SDP_FamilyMasteredGrade(family)
          && SDP_FamilyThreshold(family, nextGrade) > 0 {
          this.m_buttonHintsController.AddButtonHint(
            n"upgrade_cyberware", "Upgrade " + SDP_FamilyName(family) + " to "
              + SDP_FamilyGradeLabel(nextGrade) + " ("
              + IntToString(SDP_OrderDeadeyeUpgradeCost(nextGrade)) + " "
              + SDP_OrderDeadeyeMaterialLabel(nextGrade) + ")"
          );
        };
      };
    };
    return;
  };
  let orderGrade: Int32 = SDP_OrderDeadeyeItemGrade(itemID);
  if orderGrade > 0 {
    let orderData: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this.m_player);
    if IsDefined(orderData) {
      if Equals(display.GetDisplayContext(), ItemDisplayContext.Attachment) {
        if orderData.SDP_OrderDeadeyeTrainingGrade() == orderGrade
          && orderData.SDP_OrderDeadeyeXP(orderGrade) >= SDP_OrderDeadeyeThreshold(orderGrade) {
          this.m_buttonHintsController.AddButtonHint(
            n"upgrade_cyberware", "Record Deadeye " + SDP_OrderDeadeyeGradeLabel(orderGrade)
          );
        };
      } else {
        let nextGrade: Int32 = orderGrade + 1;
        if orderGrade == orderData.m_sdpOrderDeadeyeMasteredGrade
          && SDP_OrderDeadeyeUpgradeCost(nextGrade) > 0 {
          this.m_buttonHintsController.AddButtonHint(
            n"upgrade_cyberware",
            "Upgrade to " + SDP_OrderDeadeyeGradeLabel(nextGrade) + " ("
              + IntToString(SDP_OrderDeadeyeUpgradeCost(nextGrade)) + " "
              + SDP_OrderDeadeyeMaterialLabel(nextGrade) + ")"
          );
        };
      };
    };
    return;
  };
  return;
}

@wrapMethod(InventoryItemModeLogicController)
protected cb func OnItemDisplayClick(evt: ref<ItemDisplayClickEvent>) -> Bool {
  if IsDefined(evt) && evt.actionName.IsAction(n"upgrade_cyberware")
    && IsDefined(evt.display) && IsDefined(this.itemChooser)
    && Equals(ItemID.GetTDBID(this.itemChooser.GetModifiedItemID()), t"SkillDrivenProgression.NeuralProcessor") {
    let itemID: TweakDBID = ItemID.GetTDBID(InventoryItemData.GetID(evt.itemData));
    let family: Int32 = SDP_FamilyItemFamily(itemID);
    if family > 0 {
      let grade: Int32 = SDP_FamilyItemGrade(itemID);
      let familyData: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this.m_player);
      let success: Bool = false;
      if IsDefined(familyData) {
        if Equals(evt.display.GetDisplayContext(), ItemDisplayContext.Attachment) {
          success = familyData.SDP_FamilyRecord(family);
        } else {
          success = familyData.SDP_FamilyUpgrade(family, grade + 1);
        };
      };
      if success {
        this.itemChooser.RefreshItems();
        this.RefreshAvailableItems();
        if NotEquals(evt.display.GetDisplayContext(), ItemDisplayContext.Attachment) {
          this.PlaySound(n"Item", n"OnBuy");
        };
      } else {
        this.ShowNotification(this.m_player.GetGame(), UIMenuNotificationType.InventoryActionBlocked);
      };
      return true;
    };
    let orderGrade: Int32 = SDP_OrderDeadeyeItemGrade(itemID);
    if orderGrade > 0 {
      let orderData: ref<PlayerDevelopmentData> = PlayerDevelopmentSystem.GetData(this.m_player);
      let orderSuccess: Bool = false;
      if IsDefined(orderData) {
        if Equals(evt.display.GetDisplayContext(), ItemDisplayContext.Attachment) {
          orderSuccess = orderData.SDP_OrderRecordDeadeye();
        } else {
          orderSuccess = orderData.SDP_OrderUpgradeDeadeye(orderGrade + 1);
        };
      };
      if orderSuccess {
        this.itemChooser.RefreshItems();
        this.RefreshAvailableItems();
        if NotEquals(evt.display.GetDisplayContext(), ItemDisplayContext.Attachment) {
          this.PlaySound(n"Item", n"OnBuy");
        };
      } else {
        this.ShowNotification(this.m_player.GetGame(), UIMenuNotificationType.InventoryActionBlocked);
      };
      return true;
    };
    return wrappedMethod(evt);
  };
  return wrappedMethod(evt);
}
