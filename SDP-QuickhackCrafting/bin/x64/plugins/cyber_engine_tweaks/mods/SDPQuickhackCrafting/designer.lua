-- Quickhack Designer window: design library and editor, program chip slots, and
-- the lab (prototype.lua). Designs live in quickhack-designs.json (shared by all
-- saves); compiled slots live in the save through the redscript backend.
local designs = require("quickhack_designs")
local M = {}

local libraryFile = "quickhack-designs.json"
local legacyFile = "prototype-recipe.json"

local proto
local library = {}
local selected = 1
local message = "Pick a design on the left, edit it, then compile it into a program slot."
local dirty, dirtyAge = false, 0
local freeMode = false
local slotStatus, slotSignature, lastLabelSignature = {}, {}, {}
local components, recordCheck = "", "Run the check after loading a save."
local refresh = 0

local triggerNames = {"Opponent starts reloading", "Your ranged hit", "Your ranged headshot", "On upload", "After 3 seconds"}
local payloadNames = {"Blindness", "Thermal pulses", "Electrical pulses", "Stun", "Movement restriction", "Chemical pulses", "Physical pulses"}
local conditionNames = {"Always", "Target already blinded", "Target already burning"}
local durationNames = {"2 seconds", "4 seconds", "8 seconds"}
local amountNames = {"10 base damage", "25 base damage", "50 base damage"}
local intervalNames = {"every 2s", "every 1s", "every 0.5s"}
local lifetimeNames = {"15 seconds", "30 seconds", "60 seconds"}
local spreadNames = {"No spread", "1 nearby enemy", "2 nearby enemies", "3 nearby enemies"}

local function readFile(name)
  local file = io.open(name, "r")
  if not file then return nil end
  local contents = file:read("*a")
  file:close()
  return contents
end

local function save()
  local file = io.open(libraryFile, "w")
  if not file then message = "Could not write " .. libraryFile .. "."; return false end
  file:write(json.encode(designs.encode(library)))
  file:close()
  dirty = false
  return true
end

local function markDirty()
  dirty, dirtyAge = true, 0
  lastLabelSignature = {}
end

-- First run seeds the starter designs and imports the old single blueprint.
local function load()
  local contents = readFile(libraryFile)
  if contents then
    local ok, value = pcall(json.decode, contents)
    local list, skipped = nil, nil
    if ok then list, skipped = designs.decode(value) end
    if list then
      library = list
      if skipped and skipped > 0 then message = "Skipped " .. skipped .. " unreadable designs in " .. libraryFile .. "." end
    else
      library = designs.starters()
      message = libraryFile .. " is unreadable; started from the starter designs. The old file is kept until you save."
      return
    end
  else
    library = designs.starters()
    local legacy = readFile(legacyFile)
    if legacy then
      local ok, value = pcall(json.decode, legacy)
      local imported = ok and designs.decode(value)
      if imported and imported[1] then
        imported[1].name = designs.uniqueName(library, imported[1].name .. " (imported)")
        table.insert(library, 1, imported[1])
      end
    end
    save()
  end
  if #library == 0 then library = {designs.new("New design")} end
  selected = 1
end

local function current() return library[selected] end

local function combo(label, index, names)
  local value, changed = ImGui.Combo(label, index - 1, names, #names)
  return changed and value + 1 or index
end

local function ruleEditor(label, rule, primary)
  ImGui.Separator()
  ImGui.Text(label)
  local on = rule[1] ~= 0
  if not primary then
    local value, pressed = ImGui.Checkbox("Use a second rule##" .. label, on)
    if pressed and value ~= on then
      if value then rule[1], rule[2], rule[3] = 3, 2, 0 else rule[1], rule[2], rule[3] = 0, 0, 0 end
      markDirty()
    end
    if not value then return end
  end
  local trigger = combo("Trigger##" .. label, rule[1], triggerNames)
  local payloadIndex = combo("Effect##" .. label, designs.indexOf(designs.programPayloads, rule[2]) or 1, payloadNames)
  local condition = combo("Condition##" .. label, rule[3] + 1, conditionNames) - 1
  local duration = combo("Duration##" .. label, designs.indexOf(designs.durations, rule[4]) or 2, durationNames)
  local payload = designs.programPayloads[payloadIndex]
  local changed = trigger ~= rule[1] or payload ~= rule[2] or condition ~= rule[3] or designs.durations[duration] ~= rule[4]
  rule[1], rule[2], rule[3], rule[4] = trigger, payload, condition, designs.durations[duration]
  if designs.damaging(payload) then
    local amount = combo("Damage##" .. label, designs.indexOf(designs.amounts, rule[5]) or 2, amountNames)
    local interval = combo("Pulse##" .. label, designs.indexOf(designs.intervals, rule[6]) or 2, intervalNames)
    changed = changed or designs.amounts[amount] ~= rule[5] or designs.intervals[interval] ~= rule[6]
    rule[5], rule[6] = designs.amounts[amount], designs.intervals[interval]
  end
  if changed then markDirty() end
end

local function compile(slot)
  local design = current()
  local ok, reason = designs.validate(design)
  if not ok then message = reason; return end
  if dirty then save() end
  local a, b = design.first, design.second
  message = proto.call(function(player)
    return player:SDPQH_CompileSlot(slot, a[1], a[2], a[3], a[4], a[5], a[6], b[1], b[2], b[3], b[4], b[5], b[6],
      design.lifetime, design.spread, design.name, freeMode)
  end)
  lastLabelSignature[slot] = nil
end

local function drawLibrary()
  for i, design in ipairs(library) do
    local label = design.name
    if not designs.validate(design) then label = label .. " (invalid)" end
    if ImGui.Selectable(label .. "##design" .. i, i == selected) then selected = i end
  end
  ImGui.Separator()
  if ImGui.Button("New") and #library < designs.maxDesigns then
    library[#library + 1] = designs.new(designs.uniqueName(library, "New design"))
    selected = #library
    markDirty()
  end
  ImGui.SameLine()
  if ImGui.Button("Duplicate") and current() and #library < designs.maxDesigns then
    local copy = designs.copy(current())
    copy.name = designs.uniqueName(library, current().name .. " copy")
    table.insert(library, selected + 1, copy)
    selected = selected + 1
    markDirty()
  end
  ImGui.SameLine()
  if ImGui.Button("Delete") and #library > 1 then
    table.remove(library, selected)
    selected = math.min(selected, #library)
    markDirty()
  end
  if ImGui.Button("Add starter designs") then
    for _, design in ipairs(designs.starters()) do
      if #library < designs.maxDesigns and not designs.findBySignature(library, designs.signature(design)) then
        library[#library + 1] = design
        markDirty()
      end
    end
  end
end

local function drawEditor()
  local design = current()
  if not design then ImGui.Text("No design selected."); return end
  local name, changed = ImGui.InputText("Name", design.name, designs.maxName + 1)
  if changed and name ~= design.name then design.name = name; markDirty() end
  ruleEditor("Primary rule", design.first, true)
  ruleEditor("Secondary rule", design.second, false)
  ImGui.Separator()
  ImGui.Text("Program")
  local lifetime = combo("Lifetime", designs.indexOf(designs.lifetimes, design.lifetime) or 2, lifetimeNames)
  local spread = combo("Spread on upload", design.spread + 1, spreadNames) - 1
  if designs.lifetimes[lifetime] ~= design.lifetime or spread ~= design.spread then
    design.lifetime, design.spread = designs.lifetimes[lifetime], spread
    markDirty()
  end
  ImGui.Separator()
  local valid, reason = designs.validate(design)
  if valid then
    local stats = designs.stats(design)
    ImGui.ProgressBar(math.min(1, stats.complexity / 12), -1, 0, "Complexity " .. stats.complexity .. "/12")
    ImGui.Text(stats.ram .. " RAM  |  upload " .. designs.uploadText(stats) .. "  |  cooldown " .. stats.cooldown .. "s")
    ImGui.Text("Compile cost: " .. stats.uncommon .. " uncommon" .. (stats.rare > 0 and (" + " .. stats.rare .. " rare") or "")
      .. " quickhack components" .. (freeMode and " (free mode)" or ""))
    ImGui.TextWrapped(designs.describe(design))
  else
    ImGui.TextColored(1, 0.45, 0.35, 1, reason)
  end
  ImGui.Separator()
  if dirty then ImGui.Text("Unsaved changes (saved automatically).") end
  ImGui.Text("Compile into program slot:")
  for slot = 1, designs.slotCount do
    if slot > 1 then ImGui.SameLine() end
    if ImGui.Button(designs.slotLetters[slot] .. "##compile") then compile(slot) end
  end
  if ImGui.Button("Test in Lab sandbox") then
    if valid then proto.setRecipe(design); message = "Copied to the Lab sandbox recipe." else message = reason end
  end
end

local function drawSlots()
  ImGui.TextWrapped("Each slot is a program chip for your cyberdeck. Fabricate a chip, install it in the cyberdeck screen, "
    .. "then compile designs into its slot at any time; the chip runs whatever is compiled. Slots are stored in your save.")
  if components ~= "" then ImGui.Text("You have " .. components .. ".") end
  local value, pressed = ImGui.Checkbox("Free mode (testing: no component costs)", freeMode)
  if pressed then freeMode = value end
  for slot = 1, designs.slotCount do
    ImGui.Separator()
    local letter = designs.slotLetters[slot]
    local design = slotSignature[slot] and slotSignature[slot] ~= "" and designs.findBySignature(library, slotSignature[slot])
    local title = slotSignature[slot] == "" and "Blank" or (design and design.name or "Compiled design (not in your library)")
    ImGui.Text("Program " .. letter .. ": " .. title)
    ImGui.TextWrapped(slotStatus[slot] or "Load a save to read this slot.")
    if ImGui.Button("Fabricate chip (" .. (freeMode and "free" or designs.chipCost .. " uncommon") .. ")##" .. letter) then
      message = proto.call(function(player) return player:SDPQH_FabricateChip(slot, freeMode) end)
    end
    ImGui.SameLine()
    if ImGui.Button("Clear slot##" .. letter) then
      message = proto.call(function(player) return player:SDPQH_ClearSlot(slot) end)
      lastLabelSignature[slot] = nil
    end
    if design then
      ImGui.SameLine()
      if ImGui.Button("Edit design##" .. letter) then
        for i, entry in ipairs(library) do if entry == design then selected = i end end
      end
    end
  end
  ImGui.Separator()
  if ImGui.Button("Check program records") then
    recordCheck = proto.call(function(player) return player:SDPQH_RecordCheck() end)
  end
  ImGui.TextWrapped(recordCheck)
end

function M.init(prototype)
  proto = prototype
  load()
end

-- Slot readouts once a second. Signatures let the save's compiled numbers find
-- their design name in this machine's library.
function M.update(delta)
  if dirty then
    dirtyAge = dirtyAge + delta
    if dirtyAge >= 1.5 then save() end
  end
  refresh = refresh + delta
  if refresh < 1 then return end
  refresh = 0
  local player = Game.GetPlayer()
  if not player then slotStatus, slotSignature, lastLabelSignature, components = {}, {}, {}, ""; return end
  local ok = pcall(function()
    if player:SDP_PrototypeVersion() ~= proto.build then error("version") end
    player:SDPQH_EnsureApplied()
    components = player:SDPQH_Components()
    for slot = 1, designs.slotCount do
      slotStatus[slot] = player:SDPQH_SlotStatus(slot)
      local signature = player:SDPQH_SlotSignature(slot)
      slotSignature[slot] = signature
      if lastLabelSignature[slot] ~= signature then
        local design = signature ~= "" and designs.findBySignature(library, signature)
        player:SDPQH_SetSlotLabel(slot, design and design.name or "")
        lastLabelSignature[slot] = signature
      end
    end
  end)
  if not ok then slotStatus, components = {}, "" end
end

function M.draw()
  if not proto.isVisible() then return end
  ImGui.SetNextWindowSize(760, 640, ImGuiCond.FirstUseEver)
  local flags = proto.overlay() and 0 or (ImGuiWindowFlags.NoMouseInputs + ImGuiWindowFlags.NoNavInputs + ImGuiWindowFlags.NoNavFocus)
  if ImGui.Begin("SDP Quickhack Designer", flags) then
    ImGui.Text("Quickhack Designer - build " .. proto.build)
    ImGui.TextWrapped(message)
    if ImGui.BeginTabBar("SDPDesignerTabs") then
      if ImGui.BeginTabItem("Designer") then
        ImGui.BeginChild("SDPDesignLibrary", 220, 0, true)
        drawLibrary()
        ImGui.EndChild()
        ImGui.SameLine()
        ImGui.BeginChild("SDPDesignEditor", 0, 0, false)
        drawEditor()
        ImGui.EndChild()
        ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Program slots") then
        drawSlots()
        ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Lab") then
        proto.drawLab()
        ImGui.EndTabItem()
      end
      ImGui.EndTabBar()
    end
  end
  ImGui.End()
end

function M.shutdown()
  if dirty then save() end
end

return M
