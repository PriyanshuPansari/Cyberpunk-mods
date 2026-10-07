// SDPCombat: armour integrity bars (section 12c armour model).
//   V:       a thin bar under the HUD health bar, the integrity of her subdermal armour (hidden if she has none)
//   enemies: a thin bar under the nameplate health bar, the integrity of the piece covering the torso
//            (hidden when the enemy wears nothing, or is not handled by the combat model)
// Colour: steel blue while intact, fading to amber as integrity falls below 40%.
module SDPCombat

public abstract class SDPArmorBar {
  public static func Color(integrity: Float) -> HDRColor {
    let c: HDRColor;
    let t = ClampF((integrity - 0.1) / 0.3, 0.0, 1.0);   // 0 at <=10%, 1 at >=40%
    c.Red = 1.0 * (1.0 - t) + 0.45 * t;
    c.Green = 0.62 * (1.0 - t) + 0.75 * t;
    c.Blue = 0.15 * (1.0 - t) + 1.0 * t;
    c.Alpha = 1.0;
    return c;
  }

  public static func Build(parent: ref<inkCompoundWidget>, width: Float, height: Float, top: Float,
                           out root: wref<inkCanvas>, out fill: wref<inkRectangle>) -> Void {
    let r = new inkCanvas();
    r.SetName(n"sdpArmorBar");
    r.SetSize(width, height);
    r.SetMargin(0.0, top, 0.0, 0.0);
    let bg = new inkRectangle();
    bg.SetName(n"sdpArmorBg");
    bg.SetSize(width, height);
    let dark: HDRColor;
    dark.Red = 0.05; dark.Green = 0.07; dark.Blue = 0.1; dark.Alpha = 1.0;
    bg.SetTintColor(dark);
    bg.SetOpacity(0.55);
    bg.Reparent(r);
    let f = new inkRectangle();
    f.SetName(n"sdpArmorFill");
    f.SetSize(width, height);
    f.SetTintColor(SDPArmorBar.Color(1.0));
    f.Reparent(r);
    r.Reparent(parent);
    root = r;
    fill = f;
  }

  public static func Describe(w: wref<inkWidget>) -> String {
    if !IsDefined(w) { return "none"; };
    let m = w.GetMargin();
    let c = w as inkCompoundWidget;
    let kids = IsDefined(c) ? c.GetNumChildren() : -1;
    return s"\(NameToString(w.GetName())) [\(NameToString(w.GetClassName()))] size=\(w.GetWidth())x\(w.GetHeight()) visible=\(w.IsVisible()) opacity=\(w.GetOpacity()) margin=\(m.left),\(m.top),\(m.right),\(m.bottom) children=\(kids)";
  }

  public static func Set(root: wref<inkCanvas>, fill: wref<inkRectangle>, width: Float, integrity: Float, show: Bool) -> Void {
    if !IsDefined(root) || !IsDefined(fill) { return; };
    root.SetVisible(show);
    if !show { return; };
    let i = ClampF(integrity, 0.0, 1.0);
    fill.SetWidth(MaxF(0.0, width * i));
    fill.SetTintColor(SDPArmorBar.Color(i));
  }
}

// ---- V ------------------------------------------------------------------------------------------

@addField(healthbarWidgetGameController) public let m_sdpArmorRoot: wref<inkCanvas>;
@addField(healthbarWidgetGameController) public let m_sdpArmorFill: wref<inkRectangle>;
@addField(healthbarWidgetGameController) public let m_sdpArmorWidth: Float;

@wrapMethod(healthbarWidgetGameController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  this.SDP_BuildArmorBar();
  return result;
}

@addField(healthbarWidgetGameController) public let m_sdpArmorMode: Int32;
@addField(healthbarWidgetGameController) public let m_sdpArmorWidthOverride: Float;
@addField(healthbarWidgetGameController) public let m_sdpArmorX: Float;
@addField(healthbarWidgetGameController) public let m_sdpArmorY: Float;

// mode 0: inside the HUD bar layout under the health bar
// mode 1: inside the health bar widget, anchored to its bottom edge
// mode 2: on the HUD root at an explicit offset (SDPC:ArmorBarAt(x, y))
@addMethod(healthbarWidgetGameController)
public final func SDP_BuildArmorBar() -> Void {
  if IsDefined(this.m_sdpArmorRoot) { this.m_sdpArmorRoot.Reparent(null); };
  let hb = inkWidgetRef.Get(this.m_healthBar);
  let layout = inkWidgetRef.Get(this.m_barsLayoutPath);
  // auto width: the wider of the health bar and its layout row; SDPC:ArmorBarWidth(w) overrides it live
  let w = IsDefined(hb) ? hb.GetWidth() : 0.0;
  if IsDefined(layout) { w = MaxF(w, layout.GetWidth()); };
  if w <= 1.0 { w = 600.0; };
  if this.m_sdpArmorWidthOverride > 1.0 { w = this.m_sdpArmorWidthOverride; };
  this.m_sdpArmorWidth = w;
  let parent: ref<inkCompoundWidget>;
  if this.m_sdpArmorMode == 0 { parent = inkWidgetRef.Get(this.m_barsLayoutPath) as inkCompoundWidget; };
  if this.m_sdpArmorMode == 1 { parent = hb as inkCompoundWidget; };
  if this.m_sdpArmorMode == 2 || !IsDefined(parent) { parent = this.GetRootWidget() as inkCompoundWidget; };
  if !IsDefined(parent) { return; };
  let root: wref<inkCanvas>;
  let fill: wref<inkRectangle>;
  SDPArmorBar.Build(parent, w, 6.0, 3.0, root, fill);
  if this.m_sdpArmorMode == 1 {
    root.SetAnchor(inkEAnchor.BottomLeft);
    root.SetMargin(0.0, 0.0, 0.0, -8.0);
  };
  if this.m_sdpArmorMode == 2 || (this.m_sdpArmorMode == 0 && !IsDefined(inkWidgetRef.Get(this.m_barsLayoutPath))) {
    root.SetAnchor(inkEAnchor.TopLeft);
    root.SetMargin(this.m_sdpArmorX, this.m_sdpArmorY, 0.0, 0.0);
  };
  this.m_sdpArmorRoot = root;
  this.m_sdpArmorFill = fill;
  let owner = this.GetOwnerEntity() as GameObject;
  if IsDefined(owner) {
    let system = SDPCombatSystem.Get(owner.GetGame());
    if IsDefined(system) { system.RegisterVArmorBar(this); };
  };
}

@addMethod(healthbarWidgetGameController)
public final func SDP_SetArmorBarMode(mode: Int32, x: Float, y: Float) -> Void {
  this.m_sdpArmorMode = mode;
  this.m_sdpArmorX = x;
  this.m_sdpArmorY = y;
  this.SDP_BuildArmorBar();
}

@addMethod(healthbarWidgetGameController)
public final func SDP_ArmorBarDebug() -> String {
  let s = s"[SDPCombat] armour bar mode=\(this.m_sdpArmorMode)\n";
  s += "  HUD root: " + SDPArmorBar.Describe(this.GetRootWidget()) + "\n";
  s += "  bar layout: " + SDPArmorBar.Describe(inkWidgetRef.Get(this.m_barsLayoutPath)) + "\n";
  s += "  health bar: " + SDPArmorBar.Describe(inkWidgetRef.Get(this.m_healthBar)) + "\n";
  s += "  armour bar: " + SDPArmorBar.Describe(this.m_sdpArmorRoot) + "\n";
  s += "  armour fill: " + SDPArmorBar.Describe(this.m_sdpArmorFill) + "\n";
  return s;
}

@addMethod(healthbarWidgetGameController)
public final func SDP_SetArmorBar(integrity: Float, rating: Float) -> Void {
  SDPArmorBar.Set(this.m_sdpArmorRoot, this.m_sdpArmorFill, this.m_sdpArmorWidth, integrity, rating > 0.05);
}

// ---- enemies ------------------------------------------------------------------------------------

@addField(NameplateVisualsLogicController) public let m_sdpArmorRoot: wref<inkCanvas>;
@addField(NameplateVisualsLogicController) public let m_sdpArmorFill: wref<inkRectangle>;
@addField(NameplateVisualsLogicController) public let m_sdpArmorWidth: Float;

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  wrappedMethod(puppet, incomingData, isNewNpc);
  this.SDP_UpdateArmorBar(puppet);
}

@addMethod(NameplateVisualsLogicController)
public final func SDP_UpdateArmorBar(puppet: ref<GameObject>) -> Void {
  let npc = puppet as NPCPuppet;
  let show = false;
  let integrity = 0.0;
  if IsDefined(npc) {
    let system = SDPCombatSystem.Get(npc.GetGame());
    if IsDefined(system) && system.DurabilityEnabled() && SDPHitModel.Handles(system, npc) {
      let kit = SDPArmor.ForNPC(npc);
      kit.Update(SDPHitModel.Now(npc.GetGame()));
      let piece = kit.Covering(2);
      if !IsDefined(piece) && ArraySize(kit.pieces) > 0 { piece = kit.pieces[0]; };
      if IsDefined(piece) || kit.HasPieceFor(2) {
        show = true;
        // a broken torso piece shows an empty bar rather than disappearing
        integrity = IsDefined(piece) ? piece.integrity : 0.0;
      };
    };
  };
  if show && !IsDefined(this.m_sdpArmorRoot) {
    let hb = inkWidgetRef.Get(this.m_healthbarWidget);
    let parent = hb as inkCompoundWidget;
    let system = SDPCombatSystem.Get(npc.GetGame());
    if IsDefined(system) { system.NoteEnemyBar("health bar widget " + SDPArmorBar.Describe(hb) + (IsDefined(parent) ? " -> building" : " -> not a container, no bar")); };
    if IsDefined(parent) {
      let w = hb.GetWidth();
      if w <= 1.0 { w = 120.0; };
      this.m_sdpArmorWidth = w;
      let root: wref<inkCanvas>;
      let fill: wref<inkRectangle>;
      SDPArmorBar.Build(parent, w, 3.0, 0.0, root, fill);
      root.SetAnchor(inkEAnchor.BottomLeft);
      root.SetAnchorPoint(0.0, 0.0);
      root.SetMargin(0.0, 2.0, 0.0, 0.0);
      this.m_sdpArmorRoot = root;
      this.m_sdpArmorFill = fill;
    };
  };
  SDPArmorBar.Set(this.m_sdpArmorRoot, this.m_sdpArmorFill, this.m_sdpArmorWidth, integrity, show);
}
