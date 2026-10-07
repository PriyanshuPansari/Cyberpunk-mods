-- CET Quickhack Designer window: edits the design library stored in the save
-- (the same library as Crafting > Quickhack Designer), program chip slots, and
-- the lab (prototype.lua), and the native quickhack references with the
-- comparison meter (NativeReferences.reds, ComparisonMeter.reds).
-- quickhack-designs.json is only an export/import file for moving designs
-- between saves.
local designs = require("quickhack_designs")
local M = {}

local libraryFile = "quickhack-designs.json"
local legacyFile = "prototype-recipe.json"
local dumpFile = "native-quickhacks-dump.txt"

local proto
local library = {}
local selected = 1
local revision = nil
local message = "Load a save. Designs are stored in your save and shared with Crafting > Quickhack Designer."
local dirty, dirtyAge = false, 0
local freeMode = false
local slotStatus, slotSignature, slotName = {}, {}, {}
local components, recordCheck = "", "Run the check after loading a save."
local refresh = 0
local fileDesigns = nil
-- Native references: read from the backend on first view and on request.
local refs = nil
local refSelected = 1
local refSummary = ""
local meterReport = "Nothing measured yet."
-- A running dump: written a few programs per frame so the game does not stall.
local dumpState = nil

local triggerNames = {"Opponent starts reloading", "Your ranged hit", "Your ranged headshot", "On upload", "After 3 seconds"}
local payloadNames = {"Blindness", "Thermal pulses", "Electrical pulses", "Stun", "Movement restriction", "Chemical pulses", "Physical pulses",
  "Immobilize", "Weapon jam", "Deafen + comms jam", "Cyberware malfunction"}
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

-- Designs in the export file (or the Build 9 single blueprint), for import.
local function scanFile()
  fileDesigns = nil
  for _, name in ipairs({libraryFile, legacyFile}) do
    local contents = readFile(name)
    if contents then
      local ok, value = pcall(json.decode, contents)
      local list = ok and designs.decode(value)
      if list and #list > 0 then fileDesigns = {name = name, list = list}; return end
    end
  end
end

local function backend()
  local player = Game.GetPlayer()
  if not player then return nil end
  local ok, version = pcall(function() return player:SDP_PrototypeVersion() end)
  if not ok or version ~= proto.build then return nil end
  return player
end

-- Rebuild the Lua mirror of the save's library (layout in DesignLibrary.reds).
local function pull(player)
  local list = {}
  for i = 0, player:SDPQH_DesignCount() - 1 do
    local f = function(k) return player:SDPQH_DesignField(i, k) end
    list[#list + 1] = {
      index = i,
      name = player:SDPQH_DesignName(i),
      lifetime = designs.lifetimes[f(1)] or 30,
      spread = f(2),
      first = {f(3), f(4), f(5), f(6), f(7), f(8)},
      second = {f(9), f(10), f(11), f(12), f(13), f(14)},
    }
  end
  library = list
  selected = math.max(1, math.min(selected, #library))
  revision = player:SDPQH_LibraryRevision()
end

local function push(player, design)
  local a, b = design.first, design.second
  return player:SDPQH_SaveDesign(design.index, design.name, a[1], a[2], a[3], a[4], a[5], a[6],
    b[1], b[2], b[3], b[4], b[5], b[6], design.lifetime, design.spread)
end

-- Send a pending edit now (before compiling or changing the library).
local function flush()
  if not dirty then return end
  local player = backend()
  local design = library[selected]
  if player and design and designs.wellFormed(design) then push(player, design) end
  dirty = false
end

local function markDirty() dirty, dirtyAge = true, 0 end

local function current() return library[selected] end

-- Runs a library action, then re-reads the library and selects the result.
local function libraryAction(action)
  flush()
  local player = backend()
  if not player then message = "Load a save (and matching scripts) to edit designs."; return end
  local index = action(player)
  pull(player)
  if type(index) == "number" and index >= 0 then selected = index + 1 end
end

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
  flush()
  message = proto.call(function(player) return player:SDPQH_CompileDesign(slot, design.index, freeMode) end)
end

local function exportFile()
  flush()
  local file = io.open(libraryFile, "w")
  if not file then message = "Could not write " .. libraryFile .. "."; return end
  file:write(json.encode(designs.encode(library)))
  file:close()
  message = "Exported " .. #library .. " designs to " .. libraryFile .. ". Import them in another save."
  scanFile()
end

local function importFile()
  if not fileDesigns then message = "No designs found in " .. libraryFile .. "."; return end
  local added = 0
  libraryAction(function(player)
    local last = -1
    for _, design in ipairs(fileDesigns.list) do
      design.index = -1
      local index = push(player, design)
      if index >= 0 then added, last = added + 1, index end
    end
    return last
  end)
  message = "Imported " .. added .. " designs from " .. fileDesigns.name .. "."
end

local function drawLibrary()
  for i, design in ipairs(library) do
    local label = design.name
    if not designs.validate(design) then label = label .. " (invalid)" end
    if ImGui.Selectable(label .. "##design" .. i, i == selected) then flush(); selected = i end
  end
  ImGui.Separator()
  if ImGui.Button("New") then libraryAction(function(player) return player:SDPQH_NewDesign() end) end
  ImGui.SameLine()
  if ImGui.Button("Duplicate") and current() then
    local index = current().index
    libraryAction(function(player) return player:SDPQH_DuplicateDesign(index) end)
  end
  ImGui.SameLine()
  if ImGui.Button("Delete") and current() then
    local index = current().index
    libraryAction(function(player) player:SDPQH_DeleteDesign(index); return index - 1 end)
  end
  if ImGui.Button("Add starter designs") then
    libraryAction(function(player)
      message = "Added " .. player:SDPQH_AddStarters() .. " starter designs."
      return -1
    end)
  end
  ImGui.Separator()
  if ImGui.Button("Export to file") then exportFile() end
  if fileDesigns then
    ImGui.SameLine()
    if ImGui.Button("Import " .. #fileDesigns.list .. " from file") then importFile() end
  end
end

local function drawEditor()
  local design = current()
  if not design then ImGui.TextWrapped("Load a save to edit its designs."); return end
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
  ImGui.Text("Compile into program slot:")
  for slot = 1, designs.slotCount do
    if slot > 1 then ImGui.SameLine() end
    if ImGui.Button(designs.slotLetters[slot] .. "##compile") then compile(slot) end
  end
  if ImGui.Button("Test in Lab sandbox") then
    if valid then proto.setRecipe(design); message = "Copied to the Lab sandbox recipe." else message = reason end
  end
end

local function loadRefs(player, remeasure)
  if remeasure then player:SDPQH_RefRefresh() end
  local list = {}
  for i = 0, player:SDPQH_RefCount() - 1 do
    list[#list + 1] = {title = player:SDPQH_RefTitle(i), coverage = player:SDPQH_RefCoverage(i)}
  end
  refs = list
  refSelected = math.max(1, math.min(refSelected, #refs))
  refSummary = #refs > 0 and player:SDPQH_RefSummary(refSelected - 1)
    or "No native quickhack programs were found. The catalog needs TweakXL."
end

local function startDump(player)
  local file = io.open(dumpFile, "w")
  if not file then message = "Could not write " .. dumpFile .. "."; return end
  local ok, header = pcall(function() return player:SDPQH_DumpHeader() end)
  if not ok then file:close(); message = "Dump failed: " .. tostring(header); return end
  file:write(header)
  dumpState = {file = file, index = 0, count = player:SDPQH_RefCount()}
  message = "Dumping " .. dumpState.count .. " native quickhacks..."
end

local function stepDump()
  if not dumpState then return end
  local player = backend()
  if not player then
    dumpState.file:close()
    dumpState = nil
    message = "Dump stopped: the save was unloaded."
    return
  end
  local ok, err = pcall(function()
    for _ = 1, 4 do
      if dumpState.index >= dumpState.count then break end
      dumpState.file:write(player:SDPQH_RefDump(dumpState.index), "\n")
      dumpState.index = dumpState.index + 1
    end
  end)
  if ok and dumpState.index < dumpState.count then
    message = "Dumping native quickhacks: " .. dumpState.index .. "/" .. dumpState.count
    return
  end
  dumpState.file:close()
  message = ok and ("Wrote " .. dumpState.count .. " native quickhacks to " .. dumpFile .. " in the CET mod folder.")
    or ("Dump failed: " .. tostring(err))
  dumpState = nil
end

local function freeModeBox()
  local value, pressed = ImGui.Checkbox("Free mode (testing: no component costs)", freeMode)
  if pressed then freeMode = value end
end

local function drawReferences()
  ImGui.TextWrapped("Every native quickhack program at every tier, read from the game's records and rebuilt from our "
    .. "primitives with the native numbers. Compile one into a slot, upload it next to the native program on a "
    .. "similar enemy, then compare the two in the meter below.")
  local player = backend()
  if not player then ImGui.Text("Load a save (and matching scripts) to read native quickhacks."); return end
  if not refs then
    local ok, err = pcall(loadRefs, player, false)
    if not ok then refs, message = {}, "Could not read native quickhacks: " .. tostring(err) end
  end
  if ImGui.Button("Re-read with current stats") then
    local ok = pcall(loadRefs, player, true)
    message = ok and ("Re-read " .. #refs .. " native quickhacks.") or "Could not read native quickhacks."
  end
  ImGui.SameLine()
  if dumpState then
    ImGui.Text("Dumping " .. dumpState.index .. "/" .. dumpState.count .. "...")
  elseif ImGui.Button("Dump all to file") then
    startDump(player)
  end
  ImGui.SameLine()
  freeModeBox()
  ImGui.BeginChild("SDPReferenceList", 260, 330, true)
  for i, entry in ipairs(refs) do
    local mark = entry.coverage == "recreated" and "" or (entry.coverage == "native only" and " (native only)" or " (partial)")
    if ImGui.Selectable(entry.title .. mark .. "##ref" .. i, i == refSelected) then
      refSelected = i
      refSummary = player:SDPQH_RefSummary(i - 1)
    end
  end
  ImGui.EndChild()
  ImGui.SameLine()
  ImGui.BeginChild("SDPReferenceDetail", 0, 330, false)
  ImGui.TextWrapped(refSummary)
  if #refs > 0 then
    ImGui.Separator()
    ImGui.Text("Compile the recreation into program slot:")
    for slot = 1, designs.slotCount do
      if slot > 1 then ImGui.SameLine() end
      if ImGui.Button(designs.slotLetters[slot] .. "##reference") then
        local index = refSelected - 1
        message = proto.call(function(p) return p:SDPQH_CompileReference(slot, index) end)
      end
    end
    if ImGui.Button("Add craftable version to designs") then
      local index = refSelected - 1
      libraryAction(function(p) return p:SDPQH_RefToLibrary(index) end)
      message = "Added the nearest craftable design (2/4/8 s, 10/25/50 damage) to the Designer tab."
    end
    ImGui.SameLine()
    if ImGui.Button("Get native program (free mode)") then
      if freeMode then
        local index = refSelected - 1
        message = proto.call(function(p) return p:SDPQH_RefGiveNative(index) end)
      else
        message = "Turn on free mode to get native programs for testing."
      end
    end
  end
  ImGui.EndChild()
  ImGui.Separator()
  ImGui.Text("Comparison meter")
  ImGui.TextWrapped(meterReport)
  if ImGui.Button("Clear meter") then
    message = proto.call(function(p) return p:SDPQH_MeterClear() end)
    meterReport = "Nothing measured yet."
  end
end

local function drawSlots()
  ImGui.TextWrapped("Each slot is a program chip for your cyberdeck. Fabricate a chip, install it in the cyberdeck screen, "
    .. "then compile designs into its slot at any time; the chip runs whatever is compiled. Slots are stored in your save.")
  if components ~= "" then ImGui.Text("You have " .. components .. ".") end
  freeModeBox()
  for slot = 1, designs.slotCount do
    ImGui.Separator()
    local letter = designs.slotLetters[slot]
    ImGui.Text("Program " .. letter .. ": " .. (slotName[slot] or "-"))
    ImGui.TextWrapped(slotStatus[slot] or "Load a save to read this slot.")
    if ImGui.Button("Fabricate chip (" .. (freeMode and "free" or designs.chipCost .. " uncommon") .. ")##" .. letter) then
      message = proto.call(function(player) return player:SDPQH_FabricateChip(slot, freeMode) end)
    end
    ImGui.SameLine()
    if ImGui.Button("Clear slot##" .. letter) then
      message = proto.call(function(player) return player:SDPQH_ClearSlot(slot) end)
    end
    local design = slotSignature[slot] and slotSignature[slot] ~= "" and designs.findBySignature(library, slotSignature[slot])
    if design then
      ImGui.SameLine()
      if ImGui.Button("Edit design##" .. letter) then
        for i, entry in ipairs(library) do if entry == design then flush(); selected = i end end
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
  scanFile()
  registerHotkey("SDPDesignerMenu", "Quickhack designer: open in-game menu", function()
    message = proto.call(function(player) return player:SDPQH_OpenDesignerMenu() end)
  end)
end

-- Keeps the mirror in step with the save: pushes this window's edits after a
-- short pause and re-reads the library when anything else changed it.
function M.update(delta)
  stepDump()
  if dirty then
    dirtyAge = dirtyAge + delta
    if dirtyAge >= 0.5 then flush() end
  end
  refresh = refresh + delta
  if refresh < 1 then return end
  refresh = 0
  local player = backend()
  if not player then
    library, revision, slotStatus, slotSignature, slotName, components = {}, nil, {}, {}, {}, ""
    refs = nil
    return
  end
  local ok = pcall(function()
    player:SDPQH_EnsureApplied()
    if revision == nil then scanFile() end
    if not dirty and player:SDPQH_LibraryRevision() ~= revision then pull(player) end
    components = player:SDPQH_Components()
    meterReport = player:SDPQH_MeterReport()
    for slot = 1, designs.slotCount do
      slotStatus[slot] = player:SDPQH_SlotStatus(slot)
      slotSignature[slot] = player:SDPQH_SlotSignature(slot)
      slotName[slot] = player:SDPQH_SlotName(slot)
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
    if ImGui.Button("Open in-game designer menu") then
      message = proto.call(function(player) return player:SDPQH_OpenDesignerMenu() end)
    end
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
      if ImGui.BeginTabItem("Native quickhacks") then
        drawReferences()
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
  pcall(flush)
  if dumpState then dumpState.file:close(); dumpState = nil end
end

return M
