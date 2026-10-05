// The hub menu's CHARACTER entry opens straight onto Skill Progression.
// Attributes are derived from skills and perk points are never granted, so
// the vanilla category screen (attribute tiles + perk trees) has nothing to do.
// Uses the same path vanilla's "Open Skills" notification uses
// (OpenSkillsScreen), just unconditionally. Back on the skills screen closes
// the menu instead of dropping to the category screen.
// Left vanilla: vendor/ripperdoc contexts, and anything that explicitly asks
// for a perk tree (e.g. the Relic tree notification).
module SkillDrivenProgression

@addMethod(NewPerksCategoriesGameController)
private final func SDP_ShouldForceSkills() -> Bool {
  if IsDefined(this.m_vendorUserData) {
    return false;
  };
  if IsDefined(this.m_perkUserData) && NotEquals(this.m_perkUserData.statType, gamedataStatType.Invalid) {
    return false;
  };
  return true;
}

@wrapMethod(NewPerksCategoriesGameController)
protected cb func OnSkillsScreenSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
  let result: Bool = wrappedMethod(widget, userData);
  if this.SDP_ShouldForceSkills() && NotEquals(this.m_currentScreen, NewPeksActiveScreen.Skills) {
    this.OpenSkillsScreen();
  };
  return result;
}

@wrapMethod(NewPerksCategoriesGameController)
protected cb func OnBack(userData: ref<IScriptable>) -> Bool {
  if Equals(this.m_currentScreen, NewPeksActiveScreen.Skills) && this.SDP_ShouldForceSkills() {
    this.m_menuEventDispatcher.SpawnEvent(n"OnCloseHubMenu");
    return true;
  };
  return wrappedMethod(userData);
}

// Rename the hub's CHARACTER entry to SKILLS. Every HubMenuItems overload of
// MenuDataBuilder.Add funnels through this private overload, so one hook
// covers both the full hub menu and the radial hub.
@wrapMethod(MenuDataBuilder)
private final func Add(data: MenuData, identifier: HubMenuItems, parentIdentifier: HubMenuItems, fullscreenName: CName, icon: CName, opt userData: ref<IScriptable>, opt disabled: Bool) -> ref<MenuDataBuilder> {
  if Equals(identifier, HubMenuItems.Character) && Equals(fullscreenName, n"new_perks") {
    data.label = "SKILLS";
  };
  return wrappedMethod(data, identifier, parentIdentifier, fullscreenName, icon, userData, disabled);
}
