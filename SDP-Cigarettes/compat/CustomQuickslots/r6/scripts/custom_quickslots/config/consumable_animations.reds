module CustomQuickslots

// Patched by SkillDrivenProgression (compat/CustomQuickslots): the
// "Consumable Animations: Cigarettes" slot type also accepts
// SkillDrivenProgression's own Yeheyuan and Morley cigarettes. Custom
// Quickslots has a fixed list of slot types, so the cigarettes ride on this
// one. Without Consumable Animations, the vanilla junk cigarettes (which then
// cannot be smoked) are left out so the slot never picks them. Otherwise
// unchanged from Custom Quickslots 5.7.0.

@if(ModuleExists("ConsumableAnimations.Main"))
public func CustomQuickslotsAddDefinitions_ConsumableAnimations(config: ref<CustomQuickslotConfig>) -> Void {
  config.AddDefinition(
    CustomQuickslotItemTypeDefinition.Create(
      CustomQuickslotItemType.ConsumableAnimations_Cigarettes,
      CustomQuickslotCategory.ConsumableAnimations,
      CustomQuickslotSlotFunctionalType.Consumable,
      n"",
      CustomQuickslotConsumableActionType.Consume,
      [
        t"SkillDrivenProgression.CigaretteYeheyuan",
        t"SkillDrivenProgression.CigaretteMorley",
        t"Items.GenericJunkItem23",
        t"Items.GenericJunkItem24"
      ]
    )
  );
}

@if(!ModuleExists("ConsumableAnimations.Main"))
public func CustomQuickslotsAddDefinitions_ConsumableAnimations(config: ref<CustomQuickslotConfig>) -> Void {
  config.AddDefinition(
    CustomQuickslotItemTypeDefinition.Create(
      CustomQuickslotItemType.ConsumableAnimations_Cigarettes,
      CustomQuickslotCategory.ConsumableAnimations,
      CustomQuickslotSlotFunctionalType.Consumable,
      n"",
      CustomQuickslotConsumableActionType.Consume,
      [
        t"SkillDrivenProgression.CigaretteYeheyuan",
        t"SkillDrivenProgression.CigaretteMorley"
      ]
    )
  );
}
