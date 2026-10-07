// Native Quickhack Designer menu. Built from Codeware UI widgets and shown as a
// third tab of the game's Crafting menu (Crafting / Upgrading / Quickhack
// Designer), or as an in-game popup (SDPQH_OpenDesignerMenu). Everything here
// compiles only when Codeware is installed; without it the CET window remains.
// The design library and slots it edits live in the save (DesignLibrary.reds).
module SkillDrivenProgression

@if(ModuleExists("Codeware.UI"))
import Codeware.UI.*

public enum SDPQHUIKind {
  Select = 0,
  PagePrev = 1,
  PageNext = 2,
  New = 3,
  Duplicate = 4,
  Delete = 5,
  Starters = 6,
  Prev = 7,
  Next = 8,
  Compile = 9,
  Fabricate = 10,
  Clear = 11,
  Free = 12,
  Close = 13,
  Mode = 14,
  Approximate = 15,
  GiveNative = 16,
  MeterClear = 17,
  RefRefresh = 18,
}

// Value lists for the selector rows, cheap -> expensive like quickhack_designs.lua.
public abstract class SDPQHChoices {
  public static func Values(selector: Int32) -> array<Float> {
    let list: array<Float>;
    let field: Int32 = SDPQHChoices.Field(selector);
    if selector == 13 { ArrayPush(list, 1.00); ArrayPush(list, 2.00); ArrayPush(list, 3.00); return list; };
    if selector == 14 { ArrayPush(list, 0.00); ArrayPush(list, 1.00); ArrayPush(list, 2.00); ArrayPush(list, 3.00); return list; };
    switch field {
      case 0: ArrayPush(list, 1.00); ArrayPush(list, 2.00); ArrayPush(list, 3.00); ArrayPush(list, 4.00); ArrayPush(list, 5.00); break;
      case 1:
        ArrayPush(list, 1.00); ArrayPush(list, 2.00); ArrayPush(list, 3.00); ArrayPush(list, 4.00); ArrayPush(list, 6.00); ArrayPush(list, 7.00);
        ArrayPush(list, 8.00); ArrayPush(list, 9.00); ArrayPush(list, 10.00); ArrayPush(list, 11.00); ArrayPush(list, 12.00);
        break;
      case 2: ArrayPush(list, 0.00); ArrayPush(list, 1.00); ArrayPush(list, 2.00); break;
      case 3: ArrayPush(list, 2.00); ArrayPush(list, 4.00); ArrayPush(list, 8.00); break;
      case 4: ArrayPush(list, 10.00); ArrayPush(list, 25.00); ArrayPush(list, 50.00); break;
      case 5: ArrayPush(list, 2.00); ArrayPush(list, 1.00); ArrayPush(list, 0.50); break;
    };
    return list;
  }

  // Selectors 0-5: primary trigger..pulse, 6: second rule on/off,
  // 7-12: secondary trigger..pulse, 13: lifetime, 14: spread.
  public static func Field(selector: Int32) -> Int32 {
    if selector >= 0 && selector <= 5 { return selector; };
    if selector >= 7 && selector <= 12 { return selector - 7; };
    return -1;
  }

  public static func Index(selector: Int32) -> Int32 {
    if selector >= 0 && selector <= 5 { return 3 + selector; };
    if selector >= 7 && selector <= 12 { return 9 + selector - 7; };
    if selector == 13 { return 1; };
    if selector == 14 { return 2; };
    return -1;
  }

  public static func Step(selector: Int32, current: Float, direction: Int32) -> Float {
    let list: array<Float> = SDPQHChoices.Values(selector);
    let size: Int32 = ArraySize(list);
    if size == 0 { return current; };
    let at: Int32 = 0;
    let i: Int32 = 0;
    while i < size {
      if list[i] == current { at = i; };
      i += 1;
    };
    return list[(at + direction + size) % size];
  }

  public static func Label(selector: Int32, spec: ref<SDPQHSpec>) -> String {
    if selector == 6 { return spec.I(9) == 0 ? "Off" : "On"; };
    if selector == 13 { return IntToString(spec.LifetimeSeconds()) + " seconds"; };
    if selector == 14 {
      let spread: Int32 = spec.Spread();
      return spread == 0 ? "No spread" : IntToString(spread) + (spread == 1 ? " nearby enemy" : " nearby enemies");
    };
    let value: Float = spec.F(SDPQHChoices.Index(selector));
    switch SDPQHChoices.Field(selector) {
      case 0:
        switch Cast<Int32>(value) {
          case 1: return "Opponent starts reloading";
          case 2: return "Your ranged hit";
          case 3: return "Your ranged headshot";
          case 4: return "On upload";
          case 5: return "3 seconds after upload";
        };
        return "-";
      case 1:
        switch Cast<Int32>(value) {
          case 1: return "Blindness";
          case 2: return "Thermal pulses";
          case 3: return "Electrical pulses";
          case 4: return "Stun";
          case 6: return "Movement restriction";
          case 7: return "Chemical pulses";
          case 8: return "Physical pulses";
          case 9: return "Immobilize";
          case 10: return "Weapon jam";
          case 11: return "Deafen and comms jam";
          case 12: return "Cyberware malfunction";
        };
        return "-";
      case 2:
        if value == 1.00 { return "Only if already blinded"; };
        if value == 2.00 { return "Only if already burning"; };
        return "Always";
      case 3: return SDPQHDesign.DurationText(value);
      case 4: return SDPQHDesign.AmountText(value) + " base damage";
      case 5: return "Every " + SDPQHDesign.IntervalText(value);
    };
    return "-";
  }

  public static func Title(selector: Int32) -> String {
    if selector == 6 { return "Second rule"; };
    if selector == 13 { return "Lifetime"; };
    if selector == 14 { return "Spread on upload"; };
    switch SDPQHChoices.Field(selector) {
      case 0: return "Trigger";
      case 1: return "Effect";
      case 2: return "Condition";
      case 3: return "Duration";
      case 4: return "Damage";
      case 5: return "Pulse";
    };
    return "";
  }
}

@if(ModuleExists("Codeware.UI"))
public class SDPQHButton extends SimpleButton {
  public static func Make(text: String, width: Float, height: Float, fontSize: Int32) -> ref<SDPQHButton> {
    let self: ref<SDPQHButton> = new SDPQHButton();
    self.CreateInstance();
    self.m_root.SetSize(width, height);
    self.m_root.SetAnchorPoint(0.00, 0.00);
    self.m_label.SetFontSize(fontSize);
    self.SetText(text);
    self.ToggleSounds(true);
    return self;
  }
}

@if(ModuleExists("Codeware.UI"))
public class SDPQHDesignerPanel extends inkCustomController {
  protected let m_player: wref<PlayerPuppet>;
  protected let m_canvas: wref<inkCanvas>;
  protected let m_selected: Int32;
  protected let m_page: Int32;
  protected let m_free: Bool;
  protected let m_message: String;
  protected let m_controllers: array<ref<inkCustomController>>;
  protected let m_list: array<ref<SDPQHButton>>;
  protected let m_rows: array<wref<inkWidget>>;
  protected let m_values: array<wref<inkText>>;
  protected let m_steppers: array<ref<SDPQHButton>>;
  protected let m_name: ref<HubTextInput>;
  protected let m_pageText: wref<inkText>;
  protected let m_complexityText: wref<inkText>;
  protected let m_complexityFill: wref<inkRectangle>;
  protected let m_statsText: wref<inkText>;
  protected let m_costText: wref<inkText>;
  protected let m_haveText: wref<inkText>;
  protected let m_summaryText: wref<inkText>;
  protected let m_slotNames: array<wref<inkText>>;
  protected let m_slotStatus: array<wref<inkText>>;
  protected let m_freeButton: ref<SDPQHButton>;
  protected let m_messageText: wref<inkText>;
  protected let m_closeButton: ref<SDPQHButton>;
  // 0: the save's designs, 1: native quickhack references (NativeReferences.reds).
  protected let m_mode: Int32;
  protected let m_refSelected: Int32;
  protected let m_refPage: Int32;
  protected let m_modeButtons: array<ref<SDPQHButton>>;
  protected let m_designTools: wref<inkCanvas>;
  protected let m_refTools: wref<inkCanvas>;
  protected let m_editor: wref<inkCanvas>;
  protected let m_refView: wref<inkCanvas>;
  protected let m_refText: wref<inkText>;
  protected let m_meterText: wref<inkText>;

  public static func PageSize() -> Int32 { return 10; }
  public static func Width() -> Float { return 3400.00; }
  public static func Height() -> Float { return 1560.00; }

  public static func Create(player: ref<PlayerPuppet>, closable: Bool) -> ref<SDPQHDesignerPanel> {
    let self: ref<SDPQHDesignerPanel> = new SDPQHDesignerPanel();
    self.m_player = player;
    self.m_message = "Pick a design, edit it, then compile it into a program slot.";
    self.CreateInstance();
    if closable { self.AddCloseButton(); };
    return self;
  }

  protected cb func OnCreate() {
    let root: ref<inkCanvas> = new inkCanvas();
    root.SetName(n"SDPQHDesigner");
    root.SetSize(SDPQHDesignerPanel.Width(), SDPQHDesignerPanel.Height());
    root.SetAnchor(inkEAnchor.TopCenter);
    root.SetAnchorPoint(0.50, 0.00);
    root.SetMargin(0.00, 300.00, 0.00, 0.00);
    root.SetInteractive(true);
    this.m_canvas = root;
    this.SetRootWidget(root);
    this.BuildLibrary(root);
    this.BuildEditor(root);
    this.BuildReferenceView(root);
    this.BuildReadout(root);
  }

  protected cb func OnInitialize() {
    this.Refresh();
  }

  // ---- Widget helpers ------------------------------------------------------

  protected func Text(parent: ref<inkCompoundWidget>, text: String, x: Float, y: Float, size: Int32, color: HDRColor) -> ref<inkText> {
    let label: ref<inkText> = new inkText();
    label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    label.SetFontStyle(n"Medium");
    label.SetFontSize(size);
    label.SetTintColor(color);
    label.SetAnchor(inkEAnchor.TopLeft);
    label.SetMargin(x, y, 0.00, 0.00);
    label.SetFitToContent(true);
    label.SetText(text);
    label.Reparent(parent);
    return label;
  }

  protected func Header(parent: ref<inkCompoundWidget>, text: String, x: Float, y: Float) -> ref<inkText> {
    let label: ref<inkText> = this.Text(parent, text, x, y, 44, ThemeColors.Bittersweet());
    label.SetLetterCase(textLetterCase.UpperCase);
    return label;
  }

  protected func Rect(parent: ref<inkCompoundWidget>, x: Float, y: Float, width: Float, height: Float, color: HDRColor, opacity: Float) -> ref<inkRectangle> {
    let rect: ref<inkRectangle> = new inkRectangle();
    rect.SetAnchor(inkEAnchor.TopLeft);
    rect.SetMargin(x, y, 0.00, 0.00);
    rect.SetSize(width, height);
    rect.SetTintColor(color);
    rect.SetOpacity(opacity);
    rect.Reparent(parent);
    return rect;
  }

  protected func Canvas(parent: ref<inkCompoundWidget>, x: Float, y: Float, width: Float, height: Float) -> ref<inkCanvas> {
    let canvas: ref<inkCanvas> = new inkCanvas();
    canvas.SetAnchor(inkEAnchor.TopLeft);
    canvas.SetMargin(x, y, 0.00, 0.00);
    canvas.SetSize(width, height);
    canvas.Reparent(parent);
    return canvas;
  }

  protected func Block(parent: ref<inkCompoundWidget>, x: Float, y: Float, width: Float, height: Float, size: Int32, color: HDRColor) -> ref<inkText> {
    let text: ref<inkText> = this.Text(parent, "", x, y, size, color);
    text.SetFitToContent(false);
    text.SetSize(width, height);
    text.SetWrappingAtPosition(width);
    return text;
  }

  // Buttons report clicks to this panel; the widget name carries kind and argument.
  protected func Button(parent: ref<inkCompoundWidget>, text: String, x: Float, y: Float, width: Float, height: Float,
      kind: SDPQHUIKind, arg: Int32) -> ref<SDPQHButton> {
    let button: ref<SDPQHButton> = SDPQHButton.Make(text, width, height, height >= 80.00 ? 38 : 32);
    button.SetName(StringToName("SDPQH_" + IntToString(EnumInt(kind)) + "_" + IntToString(arg)));
    button.SetPosition(x, y);
    button.RegisterToCallback(n"OnBtnClick", this, n"OnButtonClick");
    button.Reparent(parent);
    ArrayPush(this.m_controllers, button);
    return button;
  }

  protected func AddRow(parent: ref<inkCompoundWidget>, selector: Int32, x: Float, y: Float) -> Void {
    let row: ref<inkCanvas> = new inkCanvas();
    row.SetAnchor(inkEAnchor.TopLeft);
    row.SetMargin(x, y, 0.00, 0.00);
    row.SetSize(1300.00, 70.00);
    row.Reparent(parent);
    this.Text(row, SDPQHChoices.Title(selector), 0.00, 12.00, 34, ThemeColors.Bittersweet());
    ArrayPush(this.m_steppers, this.Button(row, "<", 400.00, 3.00, 90.00, 64.00, SDPQHUIKind.Prev, selector));
    let value: ref<inkText> = this.Text(row, "", 520.00, 12.00, 34, ThemeColors.ElectricBlue());
    ArrayPush(this.m_steppers, this.Button(row, ">", 1210.00, 3.00, 90.00, 64.00, SDPQHUIKind.Next, selector));
    ArrayPush(this.m_rows, row);
    ArrayPush(this.m_values, value);
  }

  // ---- Layout --------------------------------------------------------------

  protected func BuildLibrary(root: ref<inkCanvas>) -> Void {
    ArrayPush(this.m_modeButtons, this.Button(root, "Designs", 0.00, 0.00, 390.00, 60.00, SDPQHUIKind.Mode, 0));
    ArrayPush(this.m_modeButtons, this.Button(root, "Native quickhacks", 410.00, 0.00, 390.00, 60.00, SDPQHUIKind.Mode, 1));
    let i: Int32 = 0;
    while i < SDPQHDesignerPanel.PageSize() {
      ArrayPush(this.m_list, this.Button(root, "", 0.00, 70.00 + Cast<Float>(i) * 84.00, 800.00, 72.00, SDPQHUIKind.Select, i));
      i += 1;
    };
    this.Button(root, "<", 0.00, 925.00, 100.00, 64.00, SDPQHUIKind.PagePrev, 0);
    this.m_pageText = this.Text(root, "", 130.00, 935.00, 32, ThemeColors.ElectricBlue());
    this.Button(root, ">", 700.00, 925.00, 100.00, 64.00, SDPQHUIKind.PageNext, 0);
    let tools: ref<inkCanvas> = this.Canvas(root, 0.00, 1010.00, 800.00, 170.00);
    this.Button(tools, "New", 0.00, 0.00, 250.00, 72.00, SDPQHUIKind.New, 0);
    this.Button(tools, "Copy", 270.00, 0.00, 250.00, 72.00, SDPQHUIKind.Duplicate, 0);
    this.Button(tools, "Delete", 540.00, 0.00, 260.00, 72.00, SDPQHUIKind.Delete, 0);
    this.Button(tools, "Add starter designs", 0.00, 90.00, 800.00, 72.00, SDPQHUIKind.Starters, 0);
    this.m_designTools = tools;
    let refTools: ref<inkCanvas> = this.Canvas(root, 0.00, 1010.00, 800.00, 170.00);
    this.Button(refTools, "Re-read with current stats", 0.00, 0.00, 800.00, 72.00, SDPQHUIKind.RefRefresh, 0);
    this.Text(refTools, "Every native quickhack program at every tier,\nread from the game's records.", 0.00, 90.00, 26, ThemeColors.Bittersweet());
    refTools.SetVisible(false);
    this.m_refTools = refTools;
  }

  protected func BuildEditor(parent: ref<inkCanvas>) -> Void {
    let root: ref<inkCanvas> = this.Canvas(parent, 880.00, 0.00, 1300.00, 1560.00);
    this.m_editor = root;
    let x: Float = 0.00;
    this.Header(root, "Design", x, 0.00);
    this.m_name = HubTextInput.Create();
    this.m_name.SetMaxLength(SDPQHDesign.MaxName());
    this.m_name.SetWidth(1300.00);
    this.m_name.GetRootWidget().SetMargin(x, 70.00, 0.00, 0.00);
    this.m_name.RegisterToCallback(n"OnInput", this, n"OnNameInput");
    this.m_name.Reparent(root);
    ArrayPush(this.m_controllers, this.m_name);
    this.Header(root, "Primary rule", x, 180.00);
    let i: Int32 = 0;
    while i <= 5 {
      this.AddRow(root, i, x, 240.00 + Cast<Float>(i) * 78.00);
      i += 1;
    };
    this.Header(root, "Secondary rule", x, 730.00);
    this.AddRow(root, 6, x, 790.00);
    i = 7;
    while i <= 12 {
      this.AddRow(root, i, x, 868.00 + Cast<Float>(i - 7) * 78.00);
      i += 1;
    };
    this.Header(root, "Program", x, 1350.00);
    this.AddRow(root, 13, x, 1410.00);
    this.AddRow(root, 14, x, 1488.00);
  }

  protected func BuildReferenceView(parent: ref<inkCanvas>) -> Void {
    let root: ref<inkCanvas> = this.Canvas(parent, 880.00, 0.00, 1300.00, 1560.00);
    this.Header(root, "Native quickhack", 0.00, 0.00);
    this.m_refText = this.Block(root, 0.00, 70.00, 1300.00, 640.00, 30, ThemeColors.PureWhite());
    this.Button(root, "Add craftable version to designs", 0.00, 730.00, 640.00, 68.00, SDPQHUIKind.Approximate, 0);
    this.Button(root, "Get native program (free mode)", 660.00, 730.00, 640.00, 68.00, SDPQHUIKind.GiveNative, 0);
    this.Header(root, "Comparison meter", 0.00, 830.00);
    this.m_meterText = this.Block(root, 0.00, 890.00, 1300.00, 560.00, 26, ThemeColors.ElectricBlue());
    this.Button(root, "Clear meter", 0.00, 1470.00, 400.00, 68.00, SDPQHUIKind.MeterClear, 0);
    root.SetVisible(false);
    this.m_refView = root;
  }

  protected func BuildReadout(root: ref<inkCanvas>) -> Void {
    let x: Float = 2260.00;
    this.Header(root, "Readout", x, 0.00);
    this.m_complexityText = this.Text(root, "", x, 70.00, 34, ThemeColors.ElectricBlue());
    this.Rect(root, x, 122.00, 1100.00, 14.00, ThemeColors.RedOxide(), 0.80);
    this.m_complexityFill = this.Rect(root, x, 122.00, 0.00, 14.00, ThemeColors.ElectricBlue(), 1.00);
    this.m_statsText = this.Text(root, "", x, 150.00, 34, ThemeColors.ElectricBlue());
    this.m_costText = this.Text(root, "", x, 205.00, 30, ThemeColors.Dandelion());
    this.m_haveText = this.Text(root, "", x, 250.00, 28, ThemeColors.Bittersweet());
    this.m_summaryText = this.Text(root, "", x, 310.00, 30, ThemeColors.PureWhite());
    this.m_summaryText.SetFitToContent(false);
    this.m_summaryText.SetSize(1120.00, 260.00);
    this.m_summaryText.SetWrappingAtPosition(1120.00);
    this.Header(root, "Program slots", x, 600.00);
    let slot: Int32 = 1;
    while slot <= SDPQHDesign.SlotCount() {
      let y: Float = 660.00 + Cast<Float>(slot - 1) * 190.00;
      ArrayPush(this.m_slotNames, this.Text(root, "", x, y, 34, ThemeColors.ElectricBlue()));
      ArrayPush(this.m_slotStatus, this.Text(root, "", x, y + 45.00, 26, ThemeColors.Bittersweet()));
      this.Button(root, "Compile", x, y + 92.00, 330.00, 68.00, SDPQHUIKind.Compile, slot);
      this.Button(root, "Make chip", x + 350.00, y + 92.00, 330.00, 68.00, SDPQHUIKind.Fabricate, slot);
      this.Button(root, "Clear", x + 700.00, y + 92.00, 300.00, 68.00, SDPQHUIKind.Clear, slot);
      slot += 1;
    };
    this.m_freeButton = this.Button(root, "", x, 1425.00, 620.00, 68.00, SDPQHUIKind.Free, 0);
    this.m_messageText = this.Text(root, "", x, 1505.00, 28, ThemeColors.Dandelion());
  }

  protected func AddCloseButton() -> Void {
    this.m_closeButton = this.Button(this.m_canvas, "Close", 2700.00, -90.00, 400.00, 72.00, SDPQHUIKind.Close, 0);
  }

  // ---- State ---------------------------------------------------------------

  protected func Library() -> ref<PlayerDevelopmentData> {
    return IsDefined(this.m_player) ? this.m_player.SDPQH_Library() : null;
  }

  protected func Current() -> ref<SDPQHSpec> {
    let data: ref<PlayerDevelopmentData> = this.Library();
    if !IsDefined(data) { return null; };
    let count: Int32 = data.SDPQH_DesignCount();
    if count == 0 { return null; };
    this.m_selected = Max(0, Min(this.m_selected, count - 1));
    return data.SDPQH_Design(this.m_selected);
  }

  protected func Store(spec: ref<SDPQHSpec>) -> Void {
    let data: ref<PlayerDevelopmentData> = this.Library();
    if IsDefined(data) && IsDefined(spec) { data.SDPQH_StoreDesign(this.m_selected, spec); };
  }

  public func SetPlayer(player: ref<PlayerPuppet>) -> Void {
    this.m_player = player;
  }

  public func Refresh() -> Void {
    if !IsDefined(this.m_player) { return; };
    let references: Bool = this.m_mode == 1;
    this.m_editor.SetVisible(!references);
    this.m_refView.SetVisible(references);
    this.m_designTools.SetVisible(!references);
    this.m_refTools.SetVisible(references);
    this.m_modeButtons[0].SetText(references ? "Designs" : "> Designs");
    this.m_modeButtons[1].SetText(references ? "> Native quickhacks" : "Native quickhacks");
    if references { this.RefreshReferences(); } else { this.RefreshDesigns(); };
    let slot: Int32 = 1;
    while slot <= SDPQHDesign.SlotCount() {
      this.m_slotNames[slot - 1].SetText("Program " + SDPQHDesign.Letter(slot) + ": " + this.m_player.SDPQH_SlotName(slot));
      this.m_slotStatus[slot - 1].SetText(this.m_player.SDPQH_SlotStatus(slot));
      slot += 1;
    };
    this.m_freeButton.SetText(this.m_free ? "Free mode: on" : "Free mode: off");
    this.m_messageText.SetText(this.m_message);
  }

  protected func ShowList(count: Int32, page: Int32, selected: Int32, titles: array<String>) -> Int32 {
    let pages: Int32 = Max(1, (count + SDPQHDesignerPanel.PageSize() - 1) / SDPQHDesignerPanel.PageSize());
    page = Max(0, Min(page, pages - 1));
    let i: Int32 = 0;
    while i < ArraySize(this.m_list) {
      let index: Int32 = page * SDPQHDesignerPanel.PageSize() + i;
      let visible: Bool = index < count && i < ArraySize(titles);
      this.m_list[i].GetRootWidget().SetVisible(visible);
      if visible { this.m_list[i].SetText((index == selected ? "> " : "") + titles[i]); };
      i += 1;
    };
    this.m_pageText.SetText("Page " + IntToString(page + 1) + " / " + IntToString(pages));
    return page;
  }

  protected func RefreshDesigns() -> Void {
    let data: ref<PlayerDevelopmentData> = this.Library();
    let spec: ref<SDPQHSpec> = this.Current();
    let count: Int32 = IsDefined(data) ? data.SDPQH_DesignCount() : 0;
    let pages: Int32 = Max(1, (count + SDPQHDesignerPanel.PageSize() - 1) / SDPQHDesignerPanel.PageSize());
    this.m_page = Max(0, Min(this.m_page, pages - 1));
    let titles: array<String>;
    let i: Int32 = 0;
    while i < SDPQHDesignerPanel.PageSize() && this.m_page * SDPQHDesignerPanel.PageSize() + i < count {
      ArrayPush(titles, data.SDPQH_Design(this.m_page * SDPQHDesignerPanel.PageSize() + i).name);
      i += 1;
    };
    this.m_page = this.ShowList(count, this.m_page, this.m_selected, titles);
    if !IsDefined(spec) {
      this.m_statsText.SetText("");
      this.m_costText.SetText("");
      this.m_summaryText.SetText("Load a save to design quickhacks.");
      return;
    };
    if !this.m_name.IsFocused() { this.m_name.SetText(spec.name); };
    let damaging1: Bool = SDPQHDesign.Damaging(spec.I(4));
    let second: Bool = spec.I(9) != 0;
    let damaging2: Bool = second && SDPQHDesign.Damaging(spec.I(10));
    i = 0;
    while i < ArraySize(this.m_values) {
      let shown: Bool = true;
      if i == 4 || i == 5 { shown = damaging1; };
      if i >= 7 && i <= 12 { shown = second; };
      if i == 11 || i == 12 { shown = damaging2; };
      this.m_rows[i].SetVisible(shown);
      this.m_values[i].SetText(SDPQHChoices.Label(i, spec));
      i += 1;
    };
    let complexity: Int32 = spec.Complexity();
    this.m_complexityText.SetText("Complexity " + IntToString(complexity) + " / 12");
    this.m_complexityFill.SetWidth(1100.00 * MinF(1.00, Cast<Float>(complexity) / 12.00));
    this.m_complexityFill.SetTintColor(complexity > 12 ? ThemeColors.Bittersweet() : ThemeColors.ElectricBlue());
    let problem: String = spec.Problem();
    let points: Int32 = spec.Points();
    if StrLen(problem) == 0 {
      this.m_statsText.SetText(IntToString(SDPQHDesign.Ram(points)) + " RAM   |   Upload " + SDPQHDesign.UploadText(points)
        + "   |   Cooldown " + IntToString(SDPQHDesign.Cooldown(points)) + "s");
      let rare: Int32 = SDPQHDesign.Rare(points);
      this.m_costText.SetText("Compile cost: " + IntToString(SDPQHDesign.Uncommon(points)) + " uncommon"
        + (rare > 0 ? " + " + IntToString(rare) + " rare" : "") + " components" + (this.m_free ? " (free mode)" : ""));
      this.m_summaryText.SetTintColor(ThemeColors.PureWhite());
      this.m_summaryText.SetText(spec.Description());
    } else {
      this.m_statsText.SetText("Cannot compile");
      this.m_costText.SetText("");
      this.m_summaryText.SetTintColor(ThemeColors.Bittersweet());
      this.m_summaryText.SetText(problem);
    };
    this.m_haveText.SetText("You have " + this.m_player.SDPQH_Components());
  }

  protected func RefreshReferences() -> Void {
    let catalog: ref<SDPQHRefCatalog> = this.m_player.SDPQH_RefCatalog();
    let count: Int32 = ArraySize(catalog.entries);
    this.m_refSelected = Max(0, Min(this.m_refSelected, count - 1));
    let pages: Int32 = Max(1, (count + SDPQHDesignerPanel.PageSize() - 1) / SDPQHDesignerPanel.PageSize());
    this.m_refPage = Max(0, Min(this.m_refPage, pages - 1));
    let titles: array<String>;
    let i: Int32 = 0;
    while i < SDPQHDesignerPanel.PageSize() && this.m_refPage * SDPQHDesignerPanel.PageSize() + i < count {
      let entry: ref<SDPQHNativeRef> = catalog.entries[this.m_refPage * SDPQHDesignerPanel.PageSize() + i];
      ArrayPush(titles, entry.Title() + (entry.Complete() ? "" : (entry.Supported() ? " (partial)" : " (native only)")));
      i += 1;
    };
    this.m_refPage = this.ShowList(count, this.m_refPage, this.m_refSelected, titles);
    this.m_meterText.SetText(this.m_player.SDPQH_MeterReport());
    this.m_complexityFill.SetWidth(0.00);
    this.m_haveText.SetText("You have " + this.m_player.SDPQH_Components());
    if count == 0 {
      this.m_refText.SetText("No native quickhack programs were found. The catalog needs TweakXL.");
      this.m_complexityText.SetText("");
      this.m_statsText.SetText("");
      this.m_costText.SetText("");
      this.m_summaryText.SetText("");
      return;
    };
    let reference: ref<SDPQHNativeRef> = catalog.entries[this.m_refSelected];
    this.m_refText.SetText(reference.Summary());
    this.m_complexityText.SetText("Native reference: " + reference.Coverage());
    this.m_statsText.SetText(IntToString(reference.ram) + " RAM   |   Upload " + SDPQHDesign.Num(reference.upload)
      + "s   |   Cooldown " + SDPQHDesign.Num(reference.cooldown) + "s");
    this.m_costText.SetText("Compiling a reference is free; chips cost " + IntToString(SDPQHDesign.ChipCost()) + " uncommon components"
      + (this.m_free ? " (free mode)" : ""));
    this.m_summaryText.SetTintColor(reference.Supported() ? ThemeColors.PureWhite() : ThemeColors.Bittersweet());
    this.m_summaryText.SetText(reference.Supported() ? reference.Spec().Description()
      : "None of this quickhack's effects has a primitive yet, so it stays native only.");
  }

  // ---- Input ---------------------------------------------------------------

  protected cb func OnButtonClick(widget: wref<inkWidget>) -> Bool {
    if !IsDefined(widget) { return false; };
    let name: String = NameToString(widget.GetName());
    if !StrBeginsWith(name, "SDPQH_") { return false; };
    let kind: String;
    let arg: String;
    if !StrSplitFirst(StrMid(name, 6), "_", kind, arg) { return false; };
    this.Handle(StringToInt(kind), StringToInt(arg));
    return true;
  }

  protected cb func OnNameInput(widget: wref<inkWidget>) -> Bool {
    let spec: ref<SDPQHSpec> = this.Current();
    if IsDefined(spec) && NotEquals(spec.name, this.m_name.GetText()) {
      spec.name = this.m_name.GetText();
      this.Store(spec);
      this.Refresh();
    };
    return true;
  }

  // True while the name field has keyboard focus.
  public func IsTyping() -> Bool {
    return this.m_mode == 0 && IsDefined(this.m_name) && this.m_name.IsFocused();
  }

  public func Handle(kind: Int32, arg: Int32) -> Void {
    let data: ref<PlayerDevelopmentData> = this.Library();
    if !IsDefined(data) || !IsDefined(this.m_player) { return; };
    let spec: ref<SDPQHSpec> = this.Current();
    let index: Int32;
    let references: Bool = this.m_mode == 1;
    switch IntEnum<SDPQHUIKind>(kind) {
      case SDPQHUIKind.Select:
        if references {
          this.m_refSelected = this.m_refPage * SDPQHDesignerPanel.PageSize() + arg;
        } else {
          this.m_selected = this.m_page * SDPQHDesignerPanel.PageSize() + arg;
          this.m_name.SetText(this.m_player.SDPQH_DesignName(this.m_selected));
        };
        break;
      case SDPQHUIKind.PagePrev:
        if references { this.m_refPage -= 1; } else { this.m_page -= 1; };
        break;
      case SDPQHUIKind.PageNext:
        if references { this.m_refPage += 1; } else { this.m_page += 1; };
        break;
      case SDPQHUIKind.Mode:
        this.m_mode = arg;
        if arg == 1 {
          this.m_player.SDPQH_RefRefresh();
          this.m_message = "Compile a native quickhack into a slot, upload it next to the native program, then read the meter.";
        } else {
          this.m_message = "Pick a design, edit it, then compile it into a program slot.";
        };
        break;
      case SDPQHUIKind.Approximate:
        index = this.m_player.SDPQH_RefToLibrary(this.m_refSelected);
        this.m_message = index >= 0 ? "Added the nearest craftable design to Designs." : "Nothing to approximate, or the library is full.";
        break;
      case SDPQHUIKind.GiveNative:
        this.m_message = this.m_free ? this.m_player.SDPQH_RefGiveNative(this.m_refSelected)
          : "Turn on free mode to get native programs for testing.";
        break;
      case SDPQHUIKind.MeterClear:
        this.m_message = this.m_player.SDPQH_MeterClear();
        break;
      case SDPQHUIKind.RefRefresh:
        this.m_message = "Re-read " + IntToString(this.m_player.SDPQH_RefRefresh()) + " native quickhacks with your current stats.";
        break;
      case SDPQHUIKind.New:
        index = this.m_player.SDPQH_NewDesign();
        this.m_message = index >= 0 ? "New design added." : "The library is full (" + IntToString(SDPQHDesign.MaxDesigns()) + " designs).";
        this.SelectIndex(index);
        break;
      case SDPQHUIKind.Duplicate:
        index = this.m_player.SDPQH_DuplicateDesign(this.m_selected);
        this.m_message = index >= 0 ? "Design copied." : "The library is full.";
        this.SelectIndex(index);
        break;
      case SDPQHUIKind.Delete:
        this.m_message = this.m_player.SDPQH_DeleteDesign(this.m_selected) ? "Design deleted." : "Keep at least one design.";
        this.SelectIndex(this.m_selected - 1);
        break;
      case SDPQHUIKind.Starters:
        this.m_message = "Added " + IntToString(this.m_player.SDPQH_AddStarters()) + " starter designs.";
        break;
      case SDPQHUIKind.Prev:
        this.StepSelector(spec, arg, -1);
        break;
      case SDPQHUIKind.Next:
        this.StepSelector(spec, arg, 1);
        break;
      case SDPQHUIKind.Compile:
        this.m_message = references ? this.m_player.SDPQH_CompileReference(arg, this.m_refSelected)
          : this.m_player.SDPQH_CompileDesign(arg, this.m_selected, this.m_free);
        break;
      case SDPQHUIKind.Fabricate:
        this.m_message = this.m_player.SDPQH_FabricateChip(arg, this.m_free);
        break;
      case SDPQHUIKind.Clear:
        this.m_message = this.m_player.SDPQH_ClearSlot(arg);
        break;
      case SDPQHUIKind.Free:
        this.m_free = !this.m_free;
        this.m_message = this.m_free ? "Free mode: compiling and chips cost nothing (testing)." : "Free mode off.";
        break;
      case SDPQHUIKind.Close:
        this.CallCustomCallback(n"OnDesignerClose");
        return;
    };
    this.Refresh();
  }

  protected func SelectIndex(index: Int32) -> Void {
    if index < 0 { index = 0; };
    this.m_selected = index;
    this.m_page = index / SDPQHDesignerPanel.PageSize();
    this.m_name.SetText(this.m_player.SDPQH_DesignName(index));
  }

  protected func StepSelector(spec: ref<SDPQHSpec>, selector: Int32, direction: Int32) -> Void {
    if !IsDefined(spec) { return; };
    if selector == 6 {
      // Matches the CET designer: a new second rule starts as headshot -> thermal.
      let on: Bool = spec.I(9) == 0;
      spec.Set(9, on ? 3.00 : 0.00);
      spec.Set(10, on ? 2.00 : 0.00);
      spec.Set(11, 0.00);
    } else {
      let at: Int32 = SDPQHChoices.Index(selector);
      spec.Set(at, SDPQHChoices.Step(selector, spec.F(at), direction));
    };
    this.Store(spec);
  }
}

// In-game host: the same panel in a modal popup, scaled to the popup container.
@if(ModuleExists("Codeware.UI"))
public class SDPQHDesignerPopup extends InGamePopup {
  protected let m_panel: ref<SDPQHDesignerPanel>;
  protected let m_owner: wref<PlayerPuppet>;

  public static func Make(player: ref<PlayerPuppet>) -> ref<SDPQHDesignerPopup> {
    let self: ref<SDPQHDesignerPopup> = new SDPQHDesignerPopup();
    self.m_owner = player;
    return self;
  }

  protected cb func OnCreate() {
    super.OnCreate();
    let header: ref<InGamePopupHeader> = InGamePopupHeader.Create();
    header.SetTitle("Quickhack Designer");
    header.Reparent(this);
    this.m_panel = SDPQHDesignerPanel.Create(this.m_owner, true);
    let widget: wref<inkWidget> = this.m_panel.GetRootWidget();
    widget.SetMargin(0.00, 150.00, 0.00, 0.00);
    // Scale the 4K-sized panel around its top edge to fit the popup container.
    let pivot: Vector2;
    pivot.X = 0.50;
    pivot.Y = 0.00;
    widget.SetRenderTransformPivot(pivot);
    let scale: Vector2;
    scale.X = 0.43;
    scale.Y = 0.43;
    widget.SetScale(scale);
    this.m_panel.RegisterToCallback(n"OnDesignerClose", this, n"OnDesignerClose");
    this.m_panel.Reparent(this);
  }

  protected cb func OnDesignerClose(widget: wref<inkWidget>) -> Bool {
    this.Close();
    return true;
  }

  public func UseCursor() -> Bool {
    return true;
  }
}

@if(ModuleExists("Codeware.UI"))
@addMethod(PlayerPuppet)
public final func SDPQH_OpenDesignerMenu() -> String {
  GameInstance.GetUISystem(this.GetGame()).QueueEvent(ShowCustomPopupEvent.Create(SDPQHDesignerPopup.Make(this)));
  return "Opening the Quickhack Designer. It is also a tab in the Crafting menu.";
}

@if(!ModuleExists("Codeware.UI"))
@addMethod(PlayerPuppet)
public final func SDPQH_OpenDesignerMenu() -> String {
  return "The native designer menu needs Codeware. Install Codeware, or use the CET Designer tab.";
}

// ---- Crafting menu tab -------------------------------------------------------

@if(ModuleExists("Codeware.UI"))
@addField(CraftingMainGameController)
private let m_sdpqhPanel: ref<SDPQHDesignerPanel>;

@if(ModuleExists("Codeware.UI"))
@wrapMethod(CraftingMainGameController)
protected final func RegisterTabButtons() -> Void {
  wrappedMethod();
  let labels: array<String>;
  ArrayPush(labels, "UI-ResourceExports-Crafting");
  ArrayPush(labels, "UI-PanelNames-UPGRADING");
  ArrayPush(labels, "Quickhack Designer");
  this.m_tabRoot.SetData(ArraySize(labels), null, labels);
}

@if(ModuleExists("Codeware.UI"))
@wrapMethod(CraftingMainGameController)
private final func SelectTab(selectedIndex: Int32) -> Void {
  if selectedIndex == 2 {
    this.m_craftingLogicController.ClosePanel();
    this.m_upgradingLogicController.ClosePanel();
    this.SDPQH_ShowDesigner(true);
    this.PlaySound(n"TabButton", n"OnPress");
    return;
  };
  this.SDPQH_ShowDesigner(false);
  wrappedMethod(selectedIndex);
}

// Letters typed into the design name must not switch Crafting tabs.
@if(ModuleExists("Codeware.UI"))
@wrapMethod(CraftingMainGameController)
protected cb func OnSubMenuRelease(evt: ref<inkPointerEvent>) -> Bool {
  if IsDefined(this.m_sdpqhPanel) && this.m_sdpqhPanel.IsTyping() { return false; };
  return wrappedMethod(evt);
}

@if(ModuleExists("Codeware.UI"))
@addMethod(CraftingMainGameController)
private final func SDPQH_ShowDesigner(show: Bool) -> Void {
  if !show {
    if IsDefined(this.m_sdpqhPanel) { this.m_sdpqhPanel.GetRootWidget().SetVisible(false); };
    return;
  };
  if !IsDefined(this.m_sdpqhPanel) {
    this.m_sdpqhPanel = SDPQHDesignerPanel.Create(this.m_player, false);
    this.m_sdpqhPanel.Reparent(this.GetRootCompoundWidget(), this);
  };
  this.m_sdpqhPanel.SetPlayer(this.m_player);
  this.m_sdpqhPanel.GetRootWidget().SetVisible(true);
  this.m_sdpqhPanel.Refresh();
}
