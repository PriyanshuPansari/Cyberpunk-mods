// New shard order. Keep grade assignment in this catalog so moving an effect
// changes one entry, not the character-owned XP, item, or burn-in mechanics.
module SkillDrivenProgression

public func SDP_OrderDeadeyeItemGrade(itemID: TweakDBID) -> Int32 {
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier1Shard") { return 1; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier1PlusShard") { return 2; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier2Shard") { return 3; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier2PlusShard") { return 4; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier3Shard") { return 5; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier3PlusShard") { return 6; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier4Shard") { return 7; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier4PlusShard") { return 8; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier5Shard") { return 9; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier5PlusShard") { return 10; };
  if Equals(itemID, t"SkillDrivenProgression.DeadeyeFocusTier5PlusPlusShard") { return 11; };
  return 0;
}

public func SDP_OrderDeadeyeItemID(grade: Int32) -> TweakDBID {
  if grade == 1 { return t"SkillDrivenProgression.DeadeyeFocusTier1Shard"; };
  if grade == 2 { return t"SkillDrivenProgression.DeadeyeFocusTier1PlusShard"; };
  if grade == 3 { return t"SkillDrivenProgression.DeadeyeFocusTier2Shard"; };
  if grade == 4 { return t"SkillDrivenProgression.DeadeyeFocusTier2PlusShard"; };
  if grade == 5 { return t"SkillDrivenProgression.DeadeyeFocusTier3Shard"; };
  if grade == 6 { return t"SkillDrivenProgression.DeadeyeFocusTier3PlusShard"; };
  if grade == 7 { return t"SkillDrivenProgression.DeadeyeFocusTier4Shard"; };
  if grade == 8 { return t"SkillDrivenProgression.DeadeyeFocusTier4PlusShard"; };
  if grade == 9 { return t"SkillDrivenProgression.DeadeyeFocusTier5Shard"; };
  if grade == 10 { return t"SkillDrivenProgression.DeadeyeFocusTier5PlusShard"; };
  if grade == 11 { return t"SkillDrivenProgression.DeadeyeFocusTier5PlusPlusShard"; };
  return t"None";
}

public func SDP_OrderDeadeyeEffectGrade(effectID: TweakDBID) -> Int32 {
  if Equals(effectID, t"SkillDrivenProgression.FocusMode") { return 1; };
  if Equals(effectID, t"SkillDrivenProgression.FocusPrecision") { return 2; };
  if Equals(effectID, t"SkillDrivenProgression.RinseAndReload") { return 2; };
  if Equals(effectID, t"SkillDrivenProgression.DeepBreath") { return 3; };
  if Equals(effectID, t"SkillDrivenProgression.NoSweat") { return 3; };
  if Equals(effectID, t"SkillDrivenProgression.HeadToHead") { return 4; };
  if Equals(effectID, t"SkillDrivenProgression.Pull") { return 4; };
  if Equals(effectID, t"SkillDrivenProgression.DeadeyeMode") { return 5; };
  if Equals(effectID, t"SkillDrivenProgression.DeadeyePrecision") { return 6; };
  if Equals(effectID, t"SkillDrivenProgression.LongShot") { return 6; };
  if Equals(effectID, t"SkillDrivenProgression.QuickDraw") { return 7; };
  if Equals(effectID, t"SkillDrivenProgression.CaliforniaReaper") { return 7; };
  if Equals(effectID, t"SkillDrivenProgression.HighNoon") { return 8; };
  if Equals(effectID, t"SkillDrivenProgression.DeadeyeEfficiency") { return 9; };
  if Equals(effectID, t"SkillDrivenProgression.RunNGun") { return 10; };
  if Equals(effectID, t"SkillDrivenProgression.NervesOfTungstenSteel") { return 11; };
  return 0;
}

public func SDP_OrderDeadeyeThreshold(grade: Int32) -> Int32 {
  return SDP_ChannelThreshold(0, grade);  // training v2 (ShardChannels.reds)
}

public func SDP_OrderDeadeyeEffectPackage(effectID: TweakDBID) -> TweakDBID {
  if Equals(effectID, t"SkillDrivenProgression.FocusPrecision") {
    return t"SkillDrivenProgression.DeadeyeFocusPrecision";
  };
  if Equals(effectID, t"SkillDrivenProgression.RinseAndReload") {
    return t"SkillDrivenProgression.DeadeyeRinseAndReload";
  };
  if Equals(effectID, t"SkillDrivenProgression.NoSweat") {
    return t"SkillDrivenProgression.DeadeyeNoSweat";
  };
  if Equals(effectID, t"SkillDrivenProgression.HeadToHead") { return t"SkillDrivenProgression.DeadeyeHeadToHead"; };
  if Equals(effectID, t"SkillDrivenProgression.Pull") { return t"SkillDrivenProgression.DeadeyePull"; };
  if Equals(effectID, t"SkillDrivenProgression.DeadeyeMode") { return t"SkillDrivenProgression.DeadeyeMode"; };
  if Equals(effectID, t"SkillDrivenProgression.DeadeyePrecision") { return t"SkillDrivenProgression.DeadeyePrecision"; };
  if Equals(effectID, t"SkillDrivenProgression.LongShot") { return t"SkillDrivenProgression.DeadeyeLongShot"; };
  if Equals(effectID, t"SkillDrivenProgression.QuickDraw") { return t"SkillDrivenProgression.DeadeyeQuickDraw"; };
  if Equals(effectID, t"SkillDrivenProgression.CaliforniaReaper") { return t"SkillDrivenProgression.DeadeyeCaliforniaReaper"; };
  if Equals(effectID, t"SkillDrivenProgression.HighNoon") { return t"SkillDrivenProgression.DeadeyeHighNoon"; };
  if Equals(effectID, t"SkillDrivenProgression.DeadeyeEfficiency") { return t"SkillDrivenProgression.DeadeyeEfficiency"; };
  if Equals(effectID, t"SkillDrivenProgression.RunNGun") { return t"SkillDrivenProgression.DeadeyeRunNGun"; };
  if Equals(effectID, t"SkillDrivenProgression.NervesOfTungstenSteel") { return t"SkillDrivenProgression.DeadeyeNervesOfTungstenSteel"; };
  return t"None";
}

public func SDP_OrderDeadeyeUpgradeCost(grade: Int32) -> Int32 {
  if grade == 2 { return 20; };
  if grade == 3 { return 30; };
  if grade >= 4 && grade <= 11 { return grade * 10; };
  return 0;
}

public func SDP_OrderDeadeyeUpgradeMaterial(grade: Int32) -> TweakDBID {
  if grade == 2 { return t"Items.CommonMaterial1"; };
  if grade == 3 { return t"Items.UncommonMaterial1"; };
  if grade == 4 { return t"Items.UncommonMaterial1"; };
  if grade == 5 || grade == 6 { return t"Items.RareMaterial1"; };
  if grade == 7 || grade == 8 { return t"Items.EpicMaterial1"; };
  if grade >= 9 && grade <= 11 { return t"Items.LegendaryMaterial1"; };
  return t"None";
}

public func SDP_OrderDeadeyeMaterialLabel(grade: Int32) -> String {
  if grade == 2 { return "Tier 1 components"; };
  if grade == 3 || grade == 4 { return "Tier 2 components"; };
  if grade == 5 || grade == 6 { return "Tier 3 components"; };
  if grade == 7 || grade == 8 { return "Tier 4 components"; };
  if grade >= 9 && grade <= 11 { return "Tier 5 components"; };
  return "components";
}

public func SDP_OrderDeadeyeGradeQuality(grade: Int32) -> gamedataQuality {
  if grade == 1 { return gamedataQuality.Common; };
  if grade == 2 { return gamedataQuality.CommonPlus; };
  if grade == 3 { return gamedataQuality.Uncommon; };
  if grade == 4 { return gamedataQuality.UncommonPlus; };
  if grade == 5 { return gamedataQuality.Rare; };
  if grade == 6 { return gamedataQuality.RarePlus; };
  if grade == 7 { return gamedataQuality.Epic; };
  if grade == 8 { return gamedataQuality.EpicPlus; };
  if grade == 9 { return gamedataQuality.Legendary; };
  if grade == 10 { return gamedataQuality.LegendaryPlus; };
  return gamedataQuality.LegendaryPlusPlus;
}

public func SDP_OrderDeadeyeGradeLabel(grade: Int32) -> String {
  if grade == 1 { return "Tier 1: Focus"; };
  if grade == 2 { return "Tier 1+: Focus Precision"; };
  if grade == 3 { return "Tier 2: Deep Breath"; };
  if grade == 4 { return "Tier 2+: Head to Head"; };
  if grade == 5 { return "Tier 3: Deadeye"; };
  if grade == 6 { return "Tier 3+: Long Shot"; };
  if grade == 7 { return "Tier 4: Quick Draw"; };
  if grade == 8 { return "Tier 4+: High Noon"; };
  if grade == 9 { return "Tier 5: Deadeye Efficiency"; };
  if grade == 10 { return "Tier 5+: Run 'N' Gun"; };
  if grade == 11 { return "Tier 5++: Nerves of Tungsten-Steel"; };
  return "Unknown grade";
}

// Use awards belong to the character and the currently training shard grade.
// Later grades can move or retune these entries in the training catalog.
public func SDP_OrderDeadeyeUseAward(eventID: TweakDBID, grade: Int32) -> Int32 {
  return SDP_TrainingDeadeyeAward(SDP_OrderDeadeyeUseSource(eventID), grade);
}

public func SDP_OrderPreferDeadeyeUseEvent(best: TweakDBID, candidate: TweakDBID, grade: Int32) -> TweakDBID {
  let candidateGrade: Int32 = SDP_TrainingDeadeyeSourceGrade(SDP_OrderDeadeyeUseSource(candidate));
  if candidateGrade == 0 || candidateGrade > grade { return best; };
  let bestGrade: Int32 = SDP_TrainingDeadeyeSourceGrade(SDP_OrderDeadeyeUseSource(best));
  if candidateGrade > bestGrade { return candidate; };
  return best;
}

// Stable source slots; keep their order when adding future XP sources so
// previously saved per-grade counters retain their meaning.
public func SDP_OrderDeadeyeUseSource(eventID: TweakDBID) -> Int32 {
  if Equals(eventID, t"SkillDrivenProgression.FocusDamagingHit") { return 1; };
  if Equals(eventID, t"SkillDrivenProgression.DeadeyeHeadshotHit") { return 2; };
  if Equals(eventID, t"SkillDrivenProgression.DeadeyeWeakspotHit") { return 3; };
  if Equals(eventID, t"SkillDrivenProgression.RinseReloadCompleted") { return 4; };
  if Equals(eventID, t"SkillDrivenProgression.FocusNeutralization") { return 5; };
  if Equals(eventID, t"SkillDrivenProgression.HeadToHeadNeutralization") { return 6; };
  if Equals(eventID, t"SkillDrivenProgression.PullAirborneGrenade") { return 7; };
  if Equals(eventID, t"SkillDrivenProgression.DeadeyeDamagingHit") { return 8; };
  if Equals(eventID, t"SkillDrivenProgression.LongShotHit") { return 9; };
  if Equals(eventID, t"SkillDrivenProgression.QuickDrawSwap") { return 10; };
  if Equals(eventID, t"SkillDrivenProgression.CaliforniaReaperNeutralization") { return 11; };
  if Equals(eventID, t"SkillDrivenProgression.HighNoonReload") { return 12; };
  if Equals(eventID, t"SkillDrivenProgression.DeadeyeEfficiencyHit") { return 13; };
  if Equals(eventID, t"SkillDrivenProgression.RunNGunHipFireHit") { return 14; };
  if Equals(eventID, t"SkillDrivenProgression.TungstenSteelCriticalHit") { return 15; };
  return 0;
}

public func SDP_OrderDeadeyeUseSourceName(source: Int32) -> String {
  if source == 1 { return "Focus hit"; };
  if source == 2 { return "headshot"; };
  if source == 3 { return "weakspot"; };
  if source == 4 { return "post-neutralization reload"; };
  if source == 5 { return "Focus neutralization"; };
  if source == 6 { return "Head to Head neutralization"; };
  if source == 7 { return "Pull! airborne grenade"; };
  if source == 8 { return "Deadeye hit"; };
  if source == 9 { return "Long Shot hit"; };
  if source == 10 { return "Quick Draw swap"; };
  if source == 11 { return "California Reaper neutralization"; };
  if source == 12 { return "High Noon reload"; };
  if source == 13 { return "Deadeye efficiency hit"; };
  if source == 14 { return "Run 'N' Gun hip-fire"; };
  if source == 15 { return "Tungsten-Steel critical hit"; };
  return "unknown";
}

public func SDP_OrderDeadeyeSourceIsSignature(grade: Int32, source: Int32) -> Bool {
  if grade == 4 { return source == 6 || source == 7; };
  if grade == 5 { return source == 8; };
  if grade == 6 { return source == 9; };
  if grade == 7 { return source == 10 || source == 11; };
  if grade == 8 { return source == 12; };
  if grade == 9 { return source == 13; };
  if grade == 10 { return source == 14; };
  if grade == 11 { return source == 15; };
  return false;
}

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderDeadeyeMasteredGrade: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderDeadeyeXP: array<Int32>;

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderDeadeyeHitXP: array<Int32>;

// Tier 1+ use XP by trigger. Older use XP stays in the aggregate as past XP.
@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderFocusUseXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderHeadshotUseXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderWeakspotUseXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderReloadUseXP: Int32;

@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderTier2NeutralizationXP: Int32;

// Use awards attached to the newly unlocked action at each later grade.
@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderDeadeyeSignatureXP: array<Int32>;

// Reserve 32 source slots per grade so later sources do not shift saved data.
@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderDeadeyeUseSourceXP: array<Int32>;

// Retained for compatibility with saves made before use-only attunement.
@addField(PlayerDevelopmentData)
public persistent let m_sdpHeadhunterXPShareCursor: Int32;

// Save compatibility with the earlier fractional-award scheme.
@addField(PlayerDevelopmentData)
public persistent let m_sdpOrderPriorXPHalfCarry: array<Int32>;

// A completed reload of the same gun can claim one recent aimed neutralization.
@addField(PlayerDevelopmentData)
public let m_sdpOrderRinseReloadReadyUntil: Float;

@addField(PlayerDevelopmentData)
public let m_sdpOrderRinseReloadWeapon: ItemID;

@addField(PlayerDevelopmentData)
public let m_sdpOrderHighNoonReloadReady: Bool;

@addField(PlayerDevelopmentData)
public let m_sdpOrderLastEquippedWeapon: ItemID;

@addField(PlayerDevelopmentData)
public let m_sdpOrderQuickDrawNextAwardTime: Float;

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderEnsureDeadeyeXP() -> Void {
  while ArraySize(this.m_sdpOrderDeadeyeXP) < 11 {
    ArrayPush(this.m_sdpOrderDeadeyeXP, 0);
  };
  while ArraySize(this.m_sdpOrderDeadeyeHitXP) < 11 {
    ArrayPush(this.m_sdpOrderDeadeyeHitXP, 0);
  };
  while ArraySize(this.m_sdpOrderDeadeyeSignatureXP) < 11 {
    ArrayPush(this.m_sdpOrderDeadeyeSignatureXP, 0);
  };
  while ArraySize(this.m_sdpOrderDeadeyeUseSourceXP) < 352 {
    ArrayPush(this.m_sdpOrderDeadeyeUseSourceXP, 0);
  };
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeXP(grade: Int32) -> Int32 {
  if grade < 1 || grade > ArraySize(this.m_sdpOrderDeadeyeXP) { return 0; };
  return this.m_sdpOrderDeadeyeXP[grade - 1];
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeHitXP(grade: Int32) -> Int32 {
  if grade < 1 || grade > ArraySize(this.m_sdpOrderDeadeyeHitXP) { return 0; };
  return this.m_sdpOrderDeadeyeHitXP[grade - 1];
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeSlottedGrade() -> Int32 {
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return 0; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let itemData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) { return 0; };
  let highest: Int32 = 0;
  let slot: Int32 = 0;
  while slot < 3 {
    let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
    if itemData.HasPartInSlot(slotID) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slotID);
      let grade: Int32 = SDP_OrderDeadeyeItemGrade(ItemID.GetTDBID(InnerItemData.GetItemID(part)));
      if grade > highest { highest = grade; };
    };
    slot += 1;
  };
  return highest;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeActiveGrade() -> Int32 {
  let slotted: Int32 = this.SDP_OrderDeadeyeSlottedGrade();
  if slotted == this.m_sdpOrderDeadeyeMasteredGrade + 1 {
    return slotted;
  };
  return this.m_sdpOrderDeadeyeMasteredGrade;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeHasEffect(effectID: TweakDBID) -> Bool {
  let minimum: Int32 = SDP_OrderDeadeyeEffectGrade(effectID);
  return minimum > 0 && this.SDP_OrderDeadeyeActiveGrade() >= minimum;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeTrainingGrade() -> Int32 {
  let grade: Int32 = this.SDP_OrderDeadeyeSlottedGrade();
  if grade != this.m_sdpOrderDeadeyeMasteredGrade + 1
    || SDP_OrderDeadeyeThreshold(grade) <= 0 {
    return 0;
  };
  return grade;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderAddDeadeyeXP(amount: Int32, useXP: Bool) -> Int32 {
  let grade: Int32 = this.SDP_OrderDeadeyeTrainingGrade();
  if grade <= 0 || amount <= 0 { return 0; };
  this.SDP_OrderEnsureDeadeyeXP();
  let index: Int32 = grade - 1;
  let before: Int32 = this.m_sdpOrderDeadeyeXP[index];
  let maximum: Int32 = SDP_OrderDeadeyeThreshold(grade);
  if before >= maximum { return 0; };
  this.m_sdpOrderDeadeyeXP[index] = Min(
    maximum, before + amount
  );
  let awarded: Int32 = this.m_sdpOrderDeadeyeXP[index] - before;
  if useXP { this.m_sdpOrderDeadeyeHitXP[index] += awarded; };
  return awarded;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderAwardDeadeyeUseEvent(eventID: TweakDBID, grade: Int32) -> Int32 {
  if SDP_ChannelFamily(0) { return 0; };  // v2 channels pay Deadeye instead
  if grade <= 0 || grade != this.SDP_OrderDeadeyeTrainingGrade() { return 0; };
  let source: Int32 = SDP_OrderDeadeyeUseSource(eventID);
  let baseXP: Int32 = SDP_OrderDeadeyeUseAward(eventID, grade);
  if baseXP <= 0 || this.SDP_OrderDeadeyeXP(grade) >= SDP_OrderDeadeyeThreshold(grade) { return 0; };
  let awarded: Int32 = this.SDP_OrderAddDeadeyeXP(this.SDP_TuningScaledXP(0, baseXP), true);
  this.SDP_TuningLogAward(0, grade, source, baseXP, awarded,
    this.SDP_OrderDeadeyeXP(grade), SDP_OrderDeadeyeThreshold(grade));
  if awarded > 0 {
    if source > 0 {
      this.SDP_OrderEnsureDeadeyeXP();
      this.m_sdpOrderDeadeyeUseSourceXP[(grade - 1) * 32 + source - 1] += awarded;
    };
  };
  if grade == 2 && awarded > 0 {
    if Equals(eventID, t"SkillDrivenProgression.FocusDamagingHit") {
      this.m_sdpOrderFocusUseXP += awarded;
    } else {
      if Equals(eventID, t"SkillDrivenProgression.DeadeyeHeadshotHit") {
        this.m_sdpOrderHeadshotUseXP += awarded;
      } else {
        if Equals(eventID, t"SkillDrivenProgression.DeadeyeWeakspotHit") {
          this.m_sdpOrderWeakspotUseXP += awarded;
        } else {
          if Equals(eventID, t"SkillDrivenProgression.RinseReloadCompleted") {
            this.m_sdpOrderReloadUseXP += awarded;
          };
        };
      };
    };
  };
  if grade == 3 && awarded > 0
    && Equals(eventID, t"SkillDrivenProgression.FocusNeutralization") {
    this.m_sdpOrderTier2NeutralizationXP += awarded;
  };
  if awarded > 0 && grade >= 4 {
    let signature: Int32 = 0;
    if Equals(eventID, t"SkillDrivenProgression.HeadToHeadNeutralization") { signature = 4; };
    if Equals(eventID, t"SkillDrivenProgression.PullAirborneGrenade") { signature = 4; };
    if Equals(eventID, t"SkillDrivenProgression.DeadeyeDamagingHit") { signature = 5; };
    if Equals(eventID, t"SkillDrivenProgression.LongShotHit") { signature = 6; };
    if Equals(eventID, t"SkillDrivenProgression.QuickDrawSwap")
      || Equals(eventID, t"SkillDrivenProgression.CaliforniaReaperNeutralization") { signature = 7; };
    if Equals(eventID, t"SkillDrivenProgression.HighNoonReload") { signature = 8; };
    if Equals(eventID, t"SkillDrivenProgression.DeadeyeEfficiencyHit") { signature = 9; };
    if Equals(eventID, t"SkillDrivenProgression.RunNGunHipFireHit") { signature = 10; };
    if Equals(eventID, t"SkillDrivenProgression.TungstenSteelCriticalHit") { signature = 11; };
    if signature == grade {
      this.SDP_OrderEnsureDeadeyeXP();
      this.m_sdpOrderDeadeyeSignatureXP[signature - 1] += awarded;
    };
  };
  return awarded;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderGrantDeadeyeTier1Shard() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  return GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GiveItemByTDBID(
    this.m_owner, t"SkillDrivenProgression.DeadeyeFocusTier1Shard", 1
  );
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderGrantDeadeyeTier1PlusShard() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  return GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GiveItemByTDBID(
    this.m_owner, t"SkillDrivenProgression.DeadeyeFocusTier1PlusShard", 1
  );
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderGrantDeadeyeTier2Shard() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  return GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GiveItemByTDBID(
    this.m_owner, t"SkillDrivenProgression.DeadeyeFocusTier2Shard", 1
  );
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderGrantDeadeyeShard(grade: Int32) -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  let itemID: TweakDBID = SDP_OrderDeadeyeItemID(grade);
  if Equals(itemID, t"None") { return false; };
  return GameInstance.GetTransactionSystem(this.m_owner.GetGame()).GiveItemByTDBID(
    this.m_owner, itemID, 1
  );
}

// Upgrade an inventory copy after its lower grade has been recorded.
@addMethod(PlayerDevelopmentData)
public final func SDP_OrderUpgradeDeadeye(grade: Int32) -> Bool {
  if !IsDefined(this.m_owner)
    || grade != this.m_sdpOrderDeadeyeMasteredGrade + 1
    || SDP_OrderDeadeyeUpgradeCost(grade) <= 0 { return false; };
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  if IsDefined(player) && player.IsInCombat() { return false; };
  let oldItem: TweakDBID = SDP_OrderDeadeyeItemID(grade - 1);
  let newItem: TweakDBID = SDP_OrderDeadeyeItemID(grade);
  if Equals(oldItem, t"None") || Equals(newItem, t"None") { return false; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let material: TweakDBID = SDP_OrderDeadeyeUpgradeMaterial(grade);
  let cost: Int32 = SDP_OrderDeadeyeUpgradeCost(grade);
  if ts.GetItemQuantityWithDuplicates(this.m_owner, ItemID.CreateQuery(material)) < cost {
    return false;
  };
  let items: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, items);
  let baseShard: ItemID = ItemID.None();
  let i: Int32 = 0;
  while i < ArraySize(items) {
    if IsDefined(items[i]) && Equals(ItemID.GetTDBID(items[i].GetID()), oldItem) {
      baseShard = items[i].GetID();
      break;
    };
    i += 1;
  };
  if !ItemID.IsValid(baseShard) || !ts.RemoveItem(this.m_owner, baseShard, 1) {
    return false;
  };
  if !ts.RemoveItemByTDBID(this.m_owner, material, cost, true) {
    ts.GiveItemByTDBID(this.m_owner, oldItem, 1);
    return false;
  };
  if !ts.GiveItemByTDBID(this.m_owner, newItem, 1) {
    ts.GiveItemByTDBID(this.m_owner, oldItem, 1);
    ts.GiveItemByTDBID(this.m_owner, material, cost);
    return false;
  };
  return true;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderReconcileDeadeyePackages() -> Void {
  if !IsDefined(this.m_owner) || !this.m_owner.IsPlayerControlled() { return; };
  let effects: array<TweakDBID>;
  ArrayPush(effects, t"SkillDrivenProgression.FocusPrecision");
  ArrayPush(effects, t"SkillDrivenProgression.RinseAndReload");
  ArrayPush(effects, t"SkillDrivenProgression.NoSweat");
  ArrayPush(effects, t"SkillDrivenProgression.HeadToHead");
  ArrayPush(effects, t"SkillDrivenProgression.Pull");
  ArrayPush(effects, t"SkillDrivenProgression.DeadeyeMode");
  ArrayPush(effects, t"SkillDrivenProgression.DeadeyePrecision");
  ArrayPush(effects, t"SkillDrivenProgression.LongShot");
  ArrayPush(effects, t"SkillDrivenProgression.QuickDraw");
  ArrayPush(effects, t"SkillDrivenProgression.CaliforniaReaper");
  ArrayPush(effects, t"SkillDrivenProgression.HighNoon");
  ArrayPush(effects, t"SkillDrivenProgression.DeadeyeEfficiency");
  ArrayPush(effects, t"SkillDrivenProgression.RunNGun");
  ArrayPush(effects, t"SkillDrivenProgression.NervesOfTungstenSteel");
  let packages: ref<GameplayLogicPackageSystem> = GameInstance.GetGameplayLogicPackageSystem(this.m_owner.GetGame());
  let i: Int32 = 0;
  while i < ArraySize(effects) {
    let packageID: TweakDBID = SDP_OrderDeadeyeEffectPackage(effects[i]);
    let applied: Bool = this.SDP_DeadeyePackageApplied(packageID);
    let desired: Bool = this.SDP_OrderDeadeyeHasEffect(effects[i])
      && !this.SDP_DeadeyePackageApplied(SDP_ShardPackageSource(packageID));
    if desired && !applied {
      packages.ApplyPackage(this.m_owner, this.m_owner, packageID);
    } else {
      if !desired && applied {
        packages.RemovePackage(this.m_owner, packageID);
      };
    };
    i += 1;
  };
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderNoteAimedNeutralization(evt: ref<gameTargetDamageEvent>) -> Void {
  if this.SDP_OrderDeadeyeTrainingGrade() < 2
    || !evt.attackData.HasFlag(hitFlag.WasKillingBlow)
      && !evt.attackData.HasFlag(hitFlag.Defeated) { return; };
  let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_owner.GetGame());
  if stats.GetStatValue(Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatType.IsAimingWithWeapon) < 0.50 {
    return;
  };
  this.m_sdpOrderRinseReloadWeapon = evt.attackData.GetWeapon().GetItemID();
  this.m_sdpOrderRinseReloadReadyUntil = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_owner.GetGame())) + 5.00;
  this.m_sdpOrderHighNoonReloadReady = this.SDP_OrderDeadeyeTrainingGrade() >= 8
    && StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"DeadeyeSE")
    && (evt.attackData.HasFlag(hitFlag.Headshot) || evt.attackData.HasFlag(hitFlag.WeakspotHit));
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderOnReloadCompleted(weaponID: ItemID) -> Void {
  let grade: Int32 = this.SDP_OrderDeadeyeTrainingGrade();
  if grade < 2 || !ItemID.IsValid(weaponID) {
    return;
  };
  let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_owner.GetGame()));
  if this.m_sdpOrderRinseReloadReadyUntil >= now
    && this.m_sdpOrderRinseReloadWeapon == weaponID {
    if this.m_sdpOrderHighNoonReloadReady {
      this.SDP_EncounterAddTrigger(0, 12);
      this.SDP_OrderAwardDeadeyeUseEvent(t"SkillDrivenProgression.HighNoonReload", grade);
    } else {
      this.SDP_EncounterAddTrigger(0, 4);
      this.SDP_OrderAwardDeadeyeUseEvent(t"SkillDrivenProgression.RinseReloadCompleted", grade);
    };
  };
  this.m_sdpOrderRinseReloadReadyUntil = 0.00;
  this.m_sdpOrderRinseReloadWeapon = ItemID.None();
  this.m_sdpOrderHighNoonReloadReady = false;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderOnWeaponEquipped(weaponID: ItemID) -> Void {
  if !ItemID.IsValid(weaponID) { return; };
  let previous: ItemID = this.m_sdpOrderLastEquippedWeapon;
  this.m_sdpOrderLastEquippedWeapon = weaponID;
  let grade: Int32 = this.SDP_OrderDeadeyeTrainingGrade();
  let player: ref<PlayerPuppet> = this.m_owner as PlayerPuppet;
  let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.m_owner.GetGame()));
  if ItemID.IsValid(previous) && previous != weaponID && IsDefined(player) && player.IsInCombat() {
    this.SDP_EncounterAddTrigger(0, 10);
    if now >= this.m_sdpOrderQuickDrawNextAwardTime {
      this.SDP_ChannelEvent(0, 12, 7, 0.50);   // v2: Quick Draw swap
      this.m_sdpOrderQuickDrawNextAwardTime = now + 5.00;
    };
  };
  if grade >= 7 && ItemID.IsValid(previous) && previous != weaponID
    && IsDefined(player) && player.IsInCombat()
    && now >= this.m_sdpOrderQuickDrawNextAwardTime {
    this.SDP_OrderAwardDeadeyeUseEvent(t"SkillDrivenProgression.QuickDrawSwap", grade);
    this.m_sdpOrderQuickDrawNextAwardTime = now + 5.00;
  };
}

// CET helpers for this first physical slice. The processor menu can also
// install and remove the shard normally.
@addMethod(PlayerDevelopmentData)
public final func SDP_OrderSlotDeadeye(grade: Int32, slot: Int32) -> Bool {
  if !IsDefined(this.m_owner) || slot < 0 || slot >= 3
    || grade != this.m_sdpOrderDeadeyeMasteredGrade + 1
    || this.SDP_OrderDeadeyeSlottedGrade() > 0 { return false; };
  let itemID: TweakDBID = SDP_OrderDeadeyeItemID(grade);
  if Equals(itemID, t"None") { return false; };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return false; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let processorData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
  if !IsDefined(processorData) || processorData.HasPartInSlot(slotID) { return false; };
  let items: array<wref<gameItemData>>;
  ts.GetItemList(this.m_owner, items);
  let i: Int32 = 0;
  while i < ArraySize(items) {
    if IsDefined(items[i]) && Equals(ItemID.GetTDBID(items[i].GetID()), itemID) {
      if !ts.AddPart(this.m_owner, processor, items[i].GetID(), slotID) { return false; };
      this.SDP_OrderReconcileDeadeyePackages();
      return true;
    };
    i += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderUnslotDeadeye() -> Bool {
  if !IsDefined(this.m_owner) { return false; };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  if !ItemID.IsValid(processor) { return false; };
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let itemData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) { return false; };
  let slot: Int32 = 0;
  while slot < 3 {
    let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
    if itemData.HasPartInSlot(slotID) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slotID);
      if SDP_OrderDeadeyeItemGrade(ItemID.GetTDBID(InnerItemData.GetItemID(part))) > 0 {
        let removed: ItemID = ts.RemovePart(this.m_owner, processor, slotID);
        if !ItemID.IsValid(removed) { return false; };
        if !ts.GiveItem(this.m_owner, removed, 1) {
          ts.AddPart(this.m_owner, processor, removed, slotID);
          return false;
        };
        this.SDP_OrderReconcileDeadeyePackages();
        return true;
      };
    };
    slot += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final func SDP_OrderRecordDeadeye() -> Bool {
  let grade: Int32 = this.SDP_OrderDeadeyeTrainingGrade();
  if grade <= 0 || this.SDP_OrderDeadeyeXP(grade) < SDP_OrderDeadeyeThreshold(grade) {
    return false;
  };
  let processor: ItemID = this.SDP_PrototypePhysicalProcessorID();
  let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  let itemData: wref<gameItemData> = ts.GetItemData(this.m_owner, processor);
  if !IsDefined(itemData) { return false; };
  let slot: Int32 = 0;
  while slot < 3 {
    let slotID: TweakDBID = this.SDP_PrototypeShardSlotID(slot);
    if itemData.HasPartInSlot(slotID) {
      let part: InnerItemData;
      itemData.GetItemPart(part, slotID);
      if SDP_OrderDeadeyeItemGrade(ItemID.GetTDBID(InnerItemData.GetItemID(part))) == grade {
        let removed: ItemID = ts.RemovePart(this.m_owner, processor, slotID);
        if !ItemID.IsValid(removed) { return false; };
        if !ts.GiveItem(this.m_owner, removed, 1) {
          ts.AddPart(this.m_owner, processor, removed, slotID);
          return false;
        };
        this.m_sdpOrderDeadeyeMasteredGrade = grade;
        this.SDP_OrderReconcileDeadeyePackages();
        return true;
      };
    };
    slot += 1;
  };
  return false;
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeStatus() -> String {
  return "grade=" + IntToString(this.m_sdpOrderDeadeyeMasteredGrade)
    + " slotted=" + IntToString(this.SDP_OrderDeadeyeSlottedGrade())
    + " FocusXP=" + IntToString(this.SDP_OrderDeadeyeXP(1))
    + "/" + IntToString(SDP_OrderDeadeyeThreshold(1))
    + " hitXP=" + IntToString(this.SDP_OrderDeadeyeHitXP(1))
    + " active=" + ToString(this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.FocusMode"))
    + " Tier1PlusXP=" + IntToString(this.SDP_OrderDeadeyeXP(2))
    + "/" + IntToString(SDP_OrderDeadeyeThreshold(2))
    + " plusUseXP=" + IntToString(this.SDP_OrderDeadeyeHitXP(2))
    + " precision=" + ToString(this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.FocusPrecision"))
    + " rinse=" + ToString(this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.RinseAndReload"))
    + " precisionPackage=" + ToString(this.SDP_DeadeyePackageApplied(t"SkillDrivenProgression.DeadeyeFocusPrecision"))
    + " rinsePackage=" + ToString(this.SDP_DeadeyePackageApplied(t"SkillDrivenProgression.DeadeyeRinseAndReload"))
    + " Tier2XP=" + IntToString(this.SDP_OrderDeadeyeXP(3))
    + "/" + IntToString(SDP_OrderDeadeyeThreshold(3))
    + " Tier2UseXP=" + IntToString(this.SDP_OrderDeadeyeHitXP(3))
    + " deepBreath=" + ToString(this.SDP_OrderDeadeyeHasEffect(t"SkillDrivenProgression.DeepBreath"))
    + " noSweatPackage=" + ToString(this.SDP_DeadeyePackageApplied(t"SkillDrivenProgression.DeadeyeNoSweat"));
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeUseBreakdown() -> String {
  let categorized: Int32 = this.m_sdpOrderFocusUseXP + this.m_sdpOrderHeadshotUseXP
    + this.m_sdpOrderWeakspotUseXP + this.m_sdpOrderReloadUseXP;
  return "Tier1+ use XP: Focus=" + IntToString(this.m_sdpOrderFocusUseXP)
    + " headshot=" + IntToString(this.m_sdpOrderHeadshotUseXP)
    + " weakspot=" + IntToString(this.m_sdpOrderWeakspotUseXP)
    + " reload=" + IntToString(this.m_sdpOrderReloadUseXP)
    + " earlier=" + IntToString(Max(0, this.SDP_OrderDeadeyeHitXP(2) - categorized));
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeTier2UseBreakdown() -> String {
  return "Tier2 use XP: total=" + IntToString(this.SDP_OrderDeadeyeHitXP(3))
    + " Focus neutralization=" + IntToString(this.m_sdpOrderTier2NeutralizationXP);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeGradeStatus(grade: Int32) -> String {
  if grade < 1 || grade > 11 { return "Invalid Deadeye grade"; };
  let signatureXP: Int32 = grade <= ArraySize(this.m_sdpOrderDeadeyeSignatureXP)
    ? this.m_sdpOrderDeadeyeSignatureXP[grade - 1] : 0;
  return SDP_OrderDeadeyeGradeLabel(grade)
    + " XP=" + IntToString(this.SDP_OrderDeadeyeXP(grade))
    + "/" + IntToString(SDP_OrderDeadeyeThreshold(grade))
    + " useXP=" + IntToString(this.SDP_OrderDeadeyeHitXP(grade))
    + " signatureXP=" + IntToString(signatureXP)
    + " recorded=" + ToString(this.m_sdpOrderDeadeyeMasteredGrade >= grade)
    + " slotted=" + ToString(this.SDP_OrderDeadeyeSlottedGrade() == grade);
}

@addMethod(PlayerDevelopmentData)
public final const func SDP_OrderDeadeyeDetailedXP(grade: Int32) -> String {
  if grade < 1 || grade > 11 { return "Invalid Deadeye grade"; };
  let total: Int32 = this.SDP_OrderDeadeyeXP(grade);
  let useTotal: Int32 = this.SDP_OrderDeadeyeHitXP(grade);
  let result: String = SDP_OrderDeadeyeGradeLabel(grade)
    + " XP=" + IntToString(total) + "/" + IntToString(SDP_OrderDeadeyeThreshold(grade))
    + " non-use=" + IntToString(Max(0, total - useTotal))
    + " use=" + IntToString(useTotal);
  let counted: Int32 = 0;
  let signatureCounted: Int32 = 0;
  let source: Int32 = 1;
  while source <= 15 {
    let index: Int32 = (grade - 1) * 32 + source - 1;
    if index < ArraySize(this.m_sdpOrderDeadeyeUseSourceXP) {
      let amount: Int32 = this.m_sdpOrderDeadeyeUseSourceXP[index];
      if amount > 0 {
        result += " | " + SDP_OrderDeadeyeUseSourceName(source) + "=" + IntToString(amount);
        counted += amount;
        if SDP_OrderDeadeyeSourceIsSignature(grade, source) {
          signatureCounted += amount;
        };
      };
    };
    source += 1;
  };
  let previousUse: Int32 = Max(0, useTotal - counted);
  let signatureTotal: Int32 = grade <= ArraySize(this.m_sdpOrderDeadeyeSignatureXP)
    ? this.m_sdpOrderDeadeyeSignatureXP[grade - 1] : 0;
  let previousSignature: Int32 = Min(previousUse, Max(0, signatureTotal - signatureCounted));
  result += " | earlier signature=" + IntToString(previousSignature)
    + " inherited=" + IntToString(previousUse - previousSignature);
  return result;
}

// Encounter measurement for Deadeye hits: counts every Deadeye hit condition
// that is met, whether or not Deadeye is being trained. Mirrors the checks in
// SDP_PrototypeOnDamagingHit without the training gates.
@addField(PlayerDevelopmentData) private let m_sdpMeasureDeadeyeAttack: ref<AttackData>;
@addField(PlayerDevelopmentData) private let m_sdpMeasureDeadeyeTarget: EntityID;
@addField(PlayerDevelopmentData) private let m_sdpMeasureDeadeyeTime: Float;

@addMethod(PlayerDevelopmentData)
public final func SDP_MeasureDeadeyeHit(evt: ref<gameTargetDamageEvent>) -> Void {
  if !IsDefined(this.m_owner) || !IsDefined(evt) || evt.damage <= 0.00
    || !IsDefined(evt.target) || !IsDefined(evt.attackData)
    || !IsDefined(evt.attackData.GetWeapon()) || !evt.attackData.GetWeapon().IsRanged()
    || evt.attackData.HasFlag(hitFlag.DamageOverTime) { return; };
  let targetPuppet: ref<ScriptedPuppet> = evt.target as ScriptedPuppet;
  if !IsDefined(targetPuppet) || !targetPuppet.AwardsExperience() { return; };
  let headshot: Bool = evt.attackData.HasFlag(hitFlag.Headshot);
  let weakspot: Bool = evt.attackData.HasFlag(hitFlag.WeakspotHit);
  let focusHit: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"FocusedCoolPerkSE");
  let deadeyeHit: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.m_owner, n"DeadeyeSE");
  let neutralization: Bool = evt.attackData.HasFlag(hitFlag.WasKillingBlow)
    || evt.attackData.HasFlag(hitFlag.Defeated);
  if !headshot && !weakspot && !focusHit && !deadeyeHit && !neutralization { return; };
  let targetID: EntityID = evt.target.GetEntityID();
  let attackTime: Float = evt.attackData.GetAttackTime();
  if this.m_sdpMeasureDeadeyeAttack == evt.attackData
    && this.m_sdpMeasureDeadeyeTarget == targetID
    && this.m_sdpMeasureDeadeyeTime == attackTime { return; };
  this.m_sdpMeasureDeadeyeAttack = evt.attackData;
  this.m_sdpMeasureDeadeyeTarget = targetID;
  this.m_sdpMeasureDeadeyeTime = attackTime;
  let weaponType: gamedataItemType = WeaponObject.GetWeaponType(evt.attackData.GetWeapon().GetItemID());
  let precisionWeapon: Bool = Equals(weaponType, gamedataItemType.Wea_Handgun)
    || Equals(weaponType, gamedataItemType.Wea_Revolver)
    || Equals(weaponType, gamedataItemType.Wea_SniperRifle)
    || Equals(weaponType, gamedataItemType.Wea_PrecisionRifle);
  if focusHit { this.SDP_EncounterAddTrigger(0, 1); };
  if headshot { this.SDP_EncounterAddTrigger(0, 2); };
  if weakspot { this.SDP_EncounterAddTrigger(0, 3); };
  if focusHit && neutralization {
    this.SDP_EncounterAddTrigger(0, 5);
    this.SDP_EncounterAddTrigger(0, 6);
  };
  if deadeyeHit && precisionWeapon {
    this.SDP_EncounterAddTrigger(0, 8);
    this.SDP_EncounterAddTrigger(0, 13);
    if Vector4.Distance(this.m_owner.GetWorldPosition(), evt.target.GetWorldPosition()) >= 25.00 {
      this.SDP_EncounterAddTrigger(0, 9);
    };
    if neutralization && (headshot || weakspot) { this.SDP_EncounterAddTrigger(0, 11); };
    if (headshot || weakspot) && evt.attackData.HasFlag(hitFlag.CriticalHit) {
      this.SDP_EncounterAddTrigger(0, 15);
    };
  };
  if !focusHit {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(this.m_owner.GetGame());
    if stats.GetStatValue(Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatType.IsAimingWithWeapon) < 0.50 {
      this.SDP_EncounterAddTrigger(0, 14);
    };
  };
}
