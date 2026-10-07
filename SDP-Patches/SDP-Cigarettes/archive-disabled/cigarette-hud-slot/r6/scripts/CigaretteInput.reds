module SkillDrivenProgression

// Controller shortcut: hold Square, press D-pad left.
// Same scheme as Custom Quickslots: r6/input/SkillDrivenProgression.xml (loaded
// by Input Loader) adds SDP_CigaretteSquare, a Square action that only counts
// after a 0.1 s hold, so a quick tap still just reloads. The cigarette is used
// when D-pad left is released while that hold is active.
@addField(PlayerPuppet)
private let m_sdpCigaretteInput: ref<SDPCigaretteInputListener>;

@addField(PlayerPuppet)
private let m_sdpCigaretteInventory: ref<SDPCigaretteInventoryCallback>;

@addField(PlayerPuppet)
private let m_sdpCigaretteInventoryListener: ref<InventoryScriptListener>;

@addMethod(PlayerPuppet)
public final func SDP_CigaretteSquareHeld() -> Bool {
  return IsDefined(this.m_sdpCigaretteInput) && this.m_sdpCigaretteInput.IsSquareHeld();
}

// True while D-pad left belongs to the cigarette shortcut, so the pocket radio
// and notifications ignore it (as Custom Quickslots does).
@addMethod(PlayerPuppet)
public final func SDP_CigaretteOwnsDpadLeft() -> Bool {
  return IsDefined(this.m_sdpCigaretteInput) && this.m_sdpCigaretteInput.OwnsDpadLeft();
}

public class SDPCigaretteInputListener {
  private let m_player: wref<PlayerPuppet>;
  private let m_squareHeld: Bool;
  private let m_lastKBM: Bool;
  private let m_lastCombat: Bool;
  // A D-pad left press that started during the Square hold stays ours until
  // the next press, even if Square is let go before D-pad left.
  private let m_dpadClaimed: Bool;

  public func Init(player: wref<PlayerPuppet>) -> Void {
    this.m_player = player;
    this.m_lastKBM = player.PlayerLastUsedKBM();
    this.m_lastCombat = player.IsInCombat();
  }

  public func IsSquareHeld() -> Bool {
    return this.m_squareHeld;
  }

  public func OwnsDpadLeft() -> Bool {
    return this.m_squareHeld || this.m_dpadClaimed;
  }

  public func SetSquareHeld(held: Bool) -> Void {
    if NotEquals(held, this.m_squareHeld) {
      this.m_squareHeld = held;
      SDP_CigaretteSlotNotify(this.m_player, 0);
    };
  }

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if !IsDefined(this.m_player) { return false; };
    let refresh: Bool = false;
    let kbm: Bool = this.m_player.PlayerLastUsedKBM();
    if NotEquals(kbm, this.m_lastKBM) {
      this.m_lastKBM = kbm;
      this.m_squareHeld = false;
      refresh = true;
    };
    let combat: Bool = this.m_player.IsInCombat();
    if NotEquals(combat, this.m_lastCombat) {
      this.m_lastCombat = combat;
      refresh = true;
    };

    let name: CName = ListenerAction.GetName(action);
    let kind: gameinputActionType = ListenerAction.GetType(action);
    if !kbm && Equals(name, n"SDP_CigaretteSquare") {
      if Equals(kind, gameinputActionType.BUTTON_HOLD_COMPLETE) {
        if !this.m_squareHeld { this.m_squareHeld = true; refresh = true; };
      } else {
        if Equals(kind, gameinputActionType.BUTTON_RELEASED) && this.m_squareHeld {
          this.m_squareHeld = false;
          refresh = true;
        };
      };
    };
    if refresh {
      SDP_CigaretteSlotNotify(this.m_player, 0);
    };

    // Exactly as Custom Quickslots: act on the dpad_left release while the
    // Square hold is active, and never consume the event. Consuming the press
    // swallowed the release, which is why a normal tap did nothing.
    if Equals(name, n"dpad_left") && Equals(kind, gameinputActionType.BUTTON_PRESSED) {
      this.m_dpadClaimed = !kbm && this.m_squareHeld;
    };
    if !kbm && this.m_squareHeld && Equals(name, n"dpad_left")
      && Equals(kind, gameinputActionType.BUTTON_RELEASED) {
      let development: ref<PlayerDevelopmentSystem> = PlayerDevelopmentSystem.GetInstance(this.m_player);
      if IsDefined(development) {
        let data: ref<PlayerDevelopmentData> = development.GetDevelopmentData(this.m_player);
        if IsDefined(data) { data.SDP_UseCigarette(); };
      };
    };
    return false;
  }
}

// Refreshes the HUD slot whenever the cigarette count changes.
public class SDPCigaretteInventoryCallback extends InventoryScriptCallback {
  private let m_player: wref<PlayerPuppet>;

  public func Bind(player: wref<PlayerPuppet>) -> Void {
    this.m_player = player;
  }

  private func Check(item: ItemID) -> Void {
    if SDP_IsCigarette(ItemID.GetTDBID(item)) {
      SDP_CigaretteSlotNotify(this.m_player, 0);
    };
  }

  public func OnItemAdded(item: ItemID, itemData: wref<gameItemData>, flaggedAsSilent: Bool) -> Void {
    this.Check(item);
  }

  public func OnItemRemoved(item: ItemID, difference: Int32, currentQuantity: Int32) -> Void {
    this.Check(item);
  }

  public func OnItemQuantityChanged(item: ItemID, diff: Int32, total: Uint32, flaggedAsSilent: Bool) -> Void {
    this.Check(item);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  this.m_sdpCigaretteInput = new SDPCigaretteInputListener();
  this.m_sdpCigaretteInput.Init(this);
  this.RegisterInputListener(this.m_sdpCigaretteInput);
  let development: ref<PlayerDevelopmentSystem> = PlayerDevelopmentSystem.GetInstance(this);
  if IsDefined(development) {
    let data: ref<PlayerDevelopmentData> = development.GetDevelopmentData(this);
    if IsDefined(data) { data.SDP_GrantStarterCigarettes(); };
  };
  this.SDP_SteadyAimLoop();
  this.m_sdpCigaretteInventory = new SDPCigaretteInventoryCallback();
  this.m_sdpCigaretteInventory.Bind(this);
  this.m_sdpCigaretteInventoryListener = GameInstance.GetTransactionSystem(this.GetGame())
    .RegisterInventoryListener(this, this.m_sdpCigaretteInventory);
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  if IsDefined(this.m_sdpCigaretteInput) {
    this.UnregisterInputListener(this.m_sdpCigaretteInput);
    this.m_sdpCigaretteInput = null;
  };
  if IsDefined(this.m_sdpCigaretteInventoryListener) {
    GameInstance.GetTransactionSystem(this.GetGame())
      .UnregisterInventoryListener(this, this.m_sdpCigaretteInventoryListener);
    this.m_sdpCigaretteInventoryListener = null;
  };
  this.m_sdpCigaretteInventory = null;
  this.SDP_ClearSteadyAim();
  this.SDP_ClearMilestones();
  return wrappedMethod();
}


// Keep D-pad left from toggling or changing the pocket radio, or opening a
// notification, while it is used for the cigarette shortcut.
@wrapMethod(PocketRadio)
public final func HandleInputAction(action: ListenerAction) -> Void {
  if IsDefined(this.m_player) && this.m_player.SDP_CigaretteOwnsDpadLeft() { return; };
  wrappedMethod(action);
}

@wrapMethod(PocketRadioWheelDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && player.SDP_CigaretteOwnsDpadLeft() { return false; };
  return wrappedMethod(stateContext, scriptInterface);
}

@wrapMethod(GenericNotificationController)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  let player: ref<PlayerPuppet> = this.m_player as PlayerPuppet;
  if IsDefined(player) && player.SDP_CigaretteOwnsDpadLeft() { return false; };
  return wrappedMethod(action, consumer);
}
