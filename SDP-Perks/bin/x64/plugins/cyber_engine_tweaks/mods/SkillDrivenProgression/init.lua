local settingsFile = "settings.json"
local familyNames = {
  "Deadeye", "Adrenaline", "Obliteration", "Quake", "Air Dash",
  "Sharpshooter", "Blade Runner", "Chrome", "Pyromania", "Bolt",
  "Overclock", "Hack Queue", "Smart Lock", "Ninjutsu", "Juggler", "Vehicle",
  "OS Expansion", "Frontal Cortex Expansion", "Cardiovascular Expansion", "Nervous System Expansion",
  "Integumentary Expansion", "Arms Expansion", "Hands Expansion", "Legs Expansion"
}
-- Skill passives, Cyberware Capacity and scanner dilation moved to the SDPSkills and
-- SDPScannerDilation CET mods with the SDP split; their old keys in settings.json are ignored.
local config = { shardXP = {}, showXP = false, showTree = false }
for slot = 0, 15 do config.shardXP[slot + 1] = 100 end

local function loadSettings()
  local file = io.open(settingsFile, "r")
  if not file then return end
  local ok, saved = pcall(json.decode, file:read("*a"))
  file:close()
  if not ok or type(saved) ~= "table" then return end
  for key, value in pairs(saved) do
    if key == "showXP" or key == "showTree" then config[key] = value end
  end
  if type(saved.shardXP) == "table" then
    for i = 1, 16 do
      local value = tonumber(saved.shardXP[i])
      if value then config.shardXP[i] = math.max(0, math.min(500, value)) end
    end
  end
  config.showXP = config.showXP == true
  config.showTree = config.showTree == true
end

local function saveSettings()
  local file = io.open(settingsFile, "w")
  if not file then print("SDP: cannot save tuning settings") return end
  file:write(json.encode(config))
  file:close()
end

local function developmentData()
  local player = Game.GetPlayer()
  if not player then return nil end
  local system = PlayerDevelopmentSystem.GetInstance(player)
  return system and system:GetDevelopmentData(player) or nil
end

local function applySettings(data)
  if not data then return end
  for slot = 0, 15 do data:SDP_TuningSetXPScale(slot, config.shardXP[slot + 1] / 100) end
end

local function ensureTab(ui, root)
  local ok, exists = pcall(function() return ui.pathExists(root) end)
  if not (ok and exists) then pcall(function() ui.addTab(root, "Skill Driven Progression") end) end
end

local function addNativeSettings()
  local ui = GetMod("nativeSettings")
  if not ui then print("SDP: Native Settings UI unavailable") return end
  local root = "/SkillDrivenProgression"
  ensureTab(ui, root)
  ui.addSubcategory(root .. "/shards", "Shard training XP")
  for slot = 0, 15 do
    local i = slot + 1
    ui.addRangeInt(root .. "/shards", familyNames[i],
      "XP from qualifying shard actions. 100% uses the catalog award; 50% trains at half speed.",
      0, 500, 5, config.shardXP[i], 100, function(value)
        config.shardXP[i] = value
        saveSettings()
        pcall(function() local data = developmentData(); if data then data:SDP_TuningSetXPScale(slot, value / 100) end end)
      end)
  end
  ui.addSubcategory(root .. "/overlay", "XP tracker")
  ui.addSwitch(root .. "/overlay", "Show XP overlay",
    "Shows skill and shard XP gained in the current (or last) combat encounter, plus recent shard awards. You can also bind the CET hotkey.",
    config.showXP, false, function(value)
      config.showXP = value
      saveSettings()
    end)
end

registerHotkey("SDPShardXP", "Toggle XP overlay", function()
  config.showXP = not config.showXP
  saveSettings()
end)

registerHotkey("SDPShardTree", "Toggle shard tree", function()
  config.showTree = not config.showTree
  saveSettings()
end)

-- Shard tree: every family's grades, grouped by skill, like the perk tree.
-- Recorded grades are green, the slotted (training) grade is amber with its
-- XP, later grades are grey. Hover a grade for what it grants (needs the CET
-- overlay open for the mouse; the window also shows while it's closed).
local treeGroups = { "Solo", "Shinobi", "Engineer", "Netrunner", "Headhunter", "General" }
local treeStatic, treeState, treeElapsed, overlayOpen = nil, nil, 1, false
local treeErrors = {}
local function treeError(where, err)
  local message = where .. ": " .. tostring(err)
  if not treeErrors[message] then treeErrors[message] = true print("SDP " .. message) end
end

registerForEvent("onOverlayOpen", function()
  overlayOpen = true
end)
registerForEvent("onOverlayClose", function()
  overlayOpen = false
end)

local function buildTreeStatic(data)
  local families = {}
  for f = 0, 23 do
    local family = { id = f, name = data:SDP_TreeFamilyName(f), group = data:SDP_TreeFamilyGroup(f),
      max = data:SDP_TreeMaxGrade(f), grades = {} }
    for g = 1, family.max do
      family.grades[g] = { label = data:SDP_TreeGradeLabel(g), title = data:SDP_TreeGradeTitle(f, g),
        desc = data:SDP_TreeGradeDescription(f, g), threshold = data:SDP_TreeGradeThreshold(f, g) }
    end
    families[#families + 1] = family
  end
  return families
end

local function refreshTree(delta)
  if not config.showTree then return end
  treeElapsed = treeElapsed + delta
  if treeElapsed < 0.5 then return end
  treeElapsed = 0
  local ok, err = pcall(function()
    local data = developmentData()
    if not data then treeState = nil return end
    if not treeStatic then treeStatic = buildTreeStatic(data) end
    local state = { levels = {}, families = {} }
    for i = 0, 5 do state.levels[i] = data:SDP_TreeSkillLevel(i) end
    for _, family in ipairs(treeStatic) do
      local recorded = data:SDP_RecordedGrade(family.id)
      local slotted = data:SDP_TreeSlottedGrade(family.id)
      local xp = 0
      if slotted == recorded + 1 then xp = data:SDP_TreeGradeXP(family.id, slotted) end
      state.families[family.id] = { recorded = recorded, slotted = slotted, xp = xp }
    end
    treeState = state
  end)
  if not ok then treeError("shard tree", err) end
end

local function drawTreeFamily(family, s)
  ImGui.Text(string.format("%-26s", family.name))
  for g = 1, family.max do
    local grade = family.grades[g]
    local color, status
    if g <= s.recorded then
      color, status = { 0.20, 0.55, 0.30, 1 }, "Recorded"
    elseif g == s.slotted and g == s.recorded + 1 then
      color, status = { 0.75, 0.55, 0.10, 1 }, string.format("Training: %d / %d XP", s.xp, grade.threshold)
    elseif g == s.recorded + 1 then
      color, status = { 0.25, 0.32, 0.42, 1 }, "Next: slot this grade to train it"
    else
      color, status = { 0.16, 0.16, 0.18, 1 }, "Locked"
    end
    ImGui.SameLine()
    ImGui.PushStyleColor(ImGuiCol.Button, color[1], color[2], color[3], color[4])
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, color[1] + 0.1, color[2] + 0.1, color[3] + 0.1, 1)
    ImGui.SmallButton(grade.label .. "##" .. family.id .. "_" .. g)
    ImGui.PopStyleColor(2)
    if ImGui.IsItemHovered() then
      ImGui.BeginTooltip()
      ImGui.PushTextWrapPos(420)
      ImGui.Text(family.name .. " " .. grade.label .. ": " .. grade.title)
      ImGui.Text(grade.desc)
      ImGui.Separator()
      ImGui.Text(status)
      ImGui.PopTextWrapPos()
      ImGui.EndTooltip()
    end
  end
  if s.slotted == s.recorded + 1 and s.slotted > 0 then
    ImGui.SameLine()
    ImGui.Text(string.format("  %d/%d", s.xp, family.grades[s.slotted].threshold))
  end
end

local function drawTree()
  if not config.showTree or not treeStatic or not treeState then return end
  ImGui.SetNextWindowPos(400, 120, ImGuiCond.FirstUseEver)
  ImGui.SetNextWindowSize(760, 520, ImGuiCond.FirstUseEver)
  local flags = ImGuiWindowFlags.NoCollapse
  if not overlayOpen then flags = flags + ImGuiWindowFlags.NoMouseInputs + ImGuiWindowFlags.NoNavInputs end
  if ImGui.Begin("Shard tree", flags) then
    if ImGui.BeginTabBar("SDPShardTreeTabs") then
      for groupIndex, groupName in ipairs(treeGroups) do
        local label = groupName
        if groupIndex <= 5 then label = string.format("%s %d", groupName, treeState.levels[groupIndex - 1]) end
        if ImGui.BeginTabItem(label .. "##tree" .. groupIndex) then
          for _, family in ipairs(treeStatic) do
            if family.group == groupIndex - 1 then
              drawTreeFamily(family, treeState.families[family.id])
            end
          end
          ImGui.EndTabItem()
        end
      end
      ImGui.EndTabBar()
    end
  end
  ImGui.End()
end

-- Cigarettes are used from a Custom Quickslots slot (compat/CustomQuickslots);
-- this mod adds no key binding of its own.

local lastData, lastSequence = nil, 0
local recentAwards = {}
local encounterLines = {}

-- Encounter log: every closed combat encounter is appended to
-- encounters.log (readable) and encounters.csv (one row per encounter) in
-- this mod's CET folder, for later analysis.
local skillNames = { "Solo", "Shinobi", "Engineer", "Netrunner", "Headhunter" }
local rarityNames = { "Boss", "Elite", "MaxTac", "Normal", "Officer", "Rare", "Trash", "Weak" }
local logFile, csvFile, killsFile = "encounters.log", "encounters.csv", "kills.csv"
local neutNames = { "killed", "defeated", "unconscious", "rarity_changed", "by_gun", "by_melee",
  "by_cyberarm", "by_quickhack", "by_thrown", "by_explosive", "by_status", "by_takedown", "by_unattributed" }
local killsHeader = "ended_at,encounter_started_at,encounter_outcome,result,method,rarity,base_rarity,"
  .. "faction,npc_type,archetype,power_level,awards_xp,name"
local lastClosed = nil
local encounterAwards = {}
local encounterStartedAt = nil

local function fileExists(path)
  local file = io.open(path, "r")
  if file then file:close() return true end
  return false
end

-- v2 channel columns (shard, channel id, label), read from the game once.
local function channelColumns(data)
  local list = {}
  for slot = 0, #familyNames - 1 do
    for channel = 11, 15 do
      local label = data:SDP_EncounterChannelLabel(slot, channel)
      if label and label ~= "" then list[#list + 1] = { slot, channel, familyNames[slot + 1] .. "_" .. label } end
    end
  end
  return list
end

local function csvHeader(data)
  local columns = { "ended_at", "started_at", "combat_seconds", "outcome" }
  for index = 0, 10 do columns[#columns + 1] = data:SDP_EncounterLevelName(index) end
  for _, name in ipairs(skillNames) do columns[#columns + 1] = "skill_" .. name end
  for _, name in ipairs(familyNames) do columns[#columns + 1] = "shard_" .. name:gsub(" ", "_") end
  for _, name in ipairs(skillNames) do columns[#columns + 1] = "skillev_" .. name end
  for _, name in ipairs(familyNames) do columns[#columns + 1] = "trig_" .. name:gsub(" ", "_") end
  for _, c in ipairs(channelColumns(data)) do
    columns[#columns + 1] = "ch_" .. c[3]:gsub("[^%w]+", "_")
  end
  for _, r in ipairs(rarityNames) do columns[#columns + 1] = "kills_" .. r end
  for _, n in ipairs(neutNames) do columns[#columns + 1] = "down_" .. n end
  return table.concat(columns, ",")
end

local function logEncounter(data)
  local ended = os.date("%Y-%m-%d %H:%M:%S")
  local started = encounterStartedAt or ""
  local seconds = math.floor(data:SDP_EncounterLastSeconds())
  local outcome = data:SDP_EncounterLastDied() and "died" or "survived"
  local levels, levelText = {}, {}
  for index = 0, 10 do
    local value = data:SDP_EncounterLastLevel(index)
    levels[#levels + 1] = tostring(value)
    levelText[#levelText + 1] = data:SDP_EncounterLevelName(index) .. " " .. value
  end
  local skills, shards, skillText, shardText = {}, {}, {}, {}
  local skillEvents, triggers, eventText = {}, {}, {}
  for index = 0, #skillNames - 1 do
    local xp = data:SDP_EncounterLastSkillXP(index)
    skills[#skills + 1] = tostring(xp)
    if xp > 0 then skillText[#skillText + 1] = skillNames[index + 1] .. " +" .. xp end
    local events = data:SDP_EncounterLastSkillEvents(index)
    skillEvents[#skillEvents + 1] = tostring(events)
    if events > 0 then eventText[#eventText + 1] = skillNames[index + 1] .. " x" .. events end
  end
  for slot = 0, #familyNames - 1 do
    local xp = data:SDP_EncounterLastShardXP(slot)
    shards[#shards + 1] = tostring(xp)
    if xp > 0 then shardText[#shardText + 1] = familyNames[slot + 1] .. " +" .. xp end
    triggers[#triggers + 1] = tostring(data:SDP_EncounterLastTriggers(slot))
  end

  local file, openError = io.open(logFile, "a")
  if not file then print("SDP: cannot open " .. logFile .. ": " .. tostring(openError)) end
  if file then
    file:write(string.format("=== Encounter %s -> %s  (combat %d:%02d)%s\n",
      started, ended, math.floor(seconds / 60), seconds % 60, outcome == "died" and "  FAILED: player died" or ""))
    file:write("Character: " .. table.concat(levelText, "  ") .. "\n")
    file:write("Skills: " .. (#skillText > 0 and table.concat(skillText, "   ") or "none") .. "\n")
    file:write("Shards (by channel): " .. data:SDP_EncounterLastShardText() .. "\n")
    file:write("Kills by rarity: " .. data:SDP_EncounterLastKillText() .. "\n")
    file:write("Neutralized: " .. data:SDP_EncounterLastNeutText() .. "\n")
    for index = 0, data:SDP_EncounterLastNeutRowCount() - 1 do
      file:write("  - " .. data:SDP_EncounterLastNeutRow(index):gsub(",", " | ") .. "\n")
    end
    file:write("Skill XP events: " .. (#eventText > 0 and table.concat(eventText, "   ") or "none") .. "\n")
    file:write("Channel triggers (all shards, trained or not): "
      .. data:SDP_EncounterLastChannelTriggerText() .. "\n")
    file:write("v1 source triggers (comparison only): " .. data:SDP_EncounterLastV1TriggerText() .. "\n")
    for _, line in ipairs(encounterAwards) do file:write("  " .. line .. "\n") end
    file:write("\n")
    file:close()
  end

  -- A header from an older build starts a new file; the old one is kept.
  local header = csvHeader(data)
  local existing = io.open(csvFile, "r")
  local newCsv = not existing
  if existing then
    local first = existing:read("*l")
    local second = existing:read("*l")
    existing:close()
    if first ~= header then
      if second then pcall(os.rename, csvFile, "encounters_" .. os.date("%Y%m%d_%H%M%S") .. ".csv") end
      -- header only (or rename refused): overwritten below
      newCsv = true
    end
  end
  local chans = {}
  for _, c in ipairs(channelColumns(data)) do chans[#chans + 1] = tostring(data:SDP_EncounterLastChannelXP(c[1], c[2])) end
  for index = 0, #rarityNames - 1 do chans[#chans + 1] = tostring(data:SDP_EncounterLastKills(index)) end
  for index = 0, #neutNames - 1 do chans[#chans + 1] = tostring(data:SDP_EncounterLastNeutCount(index)) end
  file = io.open(csvFile, newCsv and "w" or "a")
  if file then
    if newCsv then file:write(header .. "\n") end
    file:write(table.concat({ ended, started, tostring(seconds), outcome }, ",") .. ","
      .. table.concat(levels, ",") .. ","
      .. table.concat(skills, ",") .. "," .. table.concat(shards, ",") .. ","
      .. table.concat(skillEvents, ",") .. "," .. table.concat(triggers, ",") .. ","
      .. table.concat(chans, ",") .. "\n")
    file:close()
  end

  -- kills.csv: one row per neutralized enemy.
  local rows = data:SDP_EncounterLastNeutRowCount()
  if rows > 0 then
    local killsExisting = io.open(killsFile, "r")
    local killsNew = not killsExisting
    if killsExisting then
      if killsExisting:read("*l") ~= killsHeader then
        killsExisting:close()
        pcall(os.rename, killsFile, "kills_" .. os.date("%Y%m%d_%H%M%S") .. ".csv")
        killsNew = true
      else
        killsExisting:close()
      end
    end
    local killsOut = io.open(killsFile, killsNew and "w" or "a")
    if killsOut then
      if killsNew then killsOut:write(killsHeader .. "\n") end
      for index = 0, rows - 1 do
        killsOut:write(table.concat({ ended, started, outcome }, ",") .. ","
          .. data:SDP_EncounterLastNeutRow(index) .. "\n")
      end
      killsOut:close()
    end
  end
end
-- One-off calibration dump: the game's native skill XP curves, written to
-- native_curves.csv the first time a save is loaded in a game session.
local curvesDumped = false
local function curveName(value)
  if type(value) == "string" then return value end
  if value and value.value then return value.value end
  return tostring(value)
end
local function dumpNativeCurves()
  curvesDumped = true
  local stats = Game.GetStatsDataSystem()
  local function curve(set, x, column)
    local ok, v = pcall(function() return stats:GetValueFromCurve(CName.new(set), x, CName.new(column)) end)
    if ok and v then return v end
    return ""
  end
  local skills = { "StrengthSkill", "ReflexesSkill", "TechnicalAbilitySkill", "IntelligenceSkill", "CoolSkill" }
  local sets = {}
  for _, id in ipairs(skills) do
    local record = TweakDB:GetRecord("Proficiencies." .. id)
    sets[#sets + 1] = { id, curveName(record:CurveSetName()), curveName(record:CurveName()) }
  end
  local file = io.open("native_curves.csv", "w")
  if not file then return end
  local header = { "level" }
  for _, s in ipairs(sets) do header[#header + 1] = s[1] .. "_xp_to_reach(" .. s[2] .. "/" .. s[3] .. ")" end
  header[#header + 1] = "damage_to_skill_xp(power_level)"
  header[#header + 1] = "player_level_to_xp_mult"
  local rarities = { "trash", "weak", "normal", "rare", "officer", "elite", "boss" }
  for _, r in ipairs(rarities) do header[#header + 1] = "dmg_xp_mult_" .. r end
  file:write(table.concat(header, ",") .. "\n")
  for level = 1, 60 do
    local row = { tostring(level) }
    for _, s in ipairs(sets) do row[#row + 1] = tostring(curve(s[2], level, s[3])) end
    row[#row + 1] = tostring(curve("activity_to_proficiency_xp", level, "damage_to_skill_xp"))
    row[#row + 1] = tostring(curve("player_level_to_xp_multiplier", level, "player_level_to_xp_mult"))
    for _, r in ipairs(rarities) do
      row[#row + 1] = tostring(curve("puppet_preset_" .. r .. "_mods", level, "power_level_to_dmg_xp_mult"))
    end
    file:write(table.concat(row, ",") .. "\n")
  end
  file:close()
  print("SDP: native_curves.csv written")
end

local overlayElapsed = 0
local reportedErrors = {}
local function reportError(where, err)
  local message = where .. ": " .. tostring(err)
  if not reportedErrors[message] then
    reportedErrors[message] = true
    print("SDP overlay error " .. message)
  end
end
local function updateOverlay(delta)
  overlayElapsed = overlayElapsed + delta
  if overlayElapsed < 0.15 then return end
  overlayElapsed = 0
  xpcall(function()
    local data = developmentData()
    if not data then lastData = nil return end
    local session = data:SDP_SessionId()
    if session ~= lastData then
      lastData, lastSequence, recentAwards = session, 0, {}
      lastClosed, encounterStartedAt, encounterAwards = nil, nil, {}
      applySettings(data)
    end
    -- Also advance encounter tracking from here, so it never depends on the
    -- redscript player loop alone.
    local player = Game.GetPlayer()
    if player then data:SDP_EncounterTick(player:IsInCombat()) end
    if player and not curvesDumped then
      local ok, err = pcall(dumpNativeCurves)
      if not ok then reportError("curve dump", err) end
    end
    encounterLines = {
      data:SDP_EncounterHeader(),
      data:SDP_EncounterSkillLine(),
      data:SDP_EncounterShardLine(),
      data:SDP_EncounterTriggerLine(),
      data:SDP_EncounterKillLine(),
      data:SDP_EncounterNeutLine()
    }
    local open = data:SDP_EncounterIsOpen()
    if open and not encounterStartedAt then
      encounterStartedAt, encounterAwards = os.date("%Y-%m-%d %H:%M:%S"), {}
    end
    local closed = data:SDP_EncounterClosedCount()
    if lastClosed == nil then lastClosed = closed end
    if closed > lastClosed then
      lastClosed = closed
      local ok, err = pcall(logEncounter, data)
      if ok then print("SDP: encounter logged") else reportError("encounter log", err) end
      encounterStartedAt, encounterAwards = nil, {}
      if open then encounterStartedAt = os.date("%Y-%m-%d %H:%M:%S") end
    end
    local sequence = data:SDP_TuningAwardSequence()
    if sequence == lastSequence then return end
    local count = data:SDP_TuningAwardCount()
    local unseen = math.min(count, math.max(0, sequence - lastSequence))
    for index = count - unseen, count - 1 do
      local line = data:SDP_TuningAwardLine(index)
      recentAwards[#recentAwards + 1] = line
      if #recentAwards > 8 then table.remove(recentAwards, 1) end
      if encounterStartedAt then
        encounterAwards[#encounterAwards + 1] = os.date("%H:%M:%S") .. "  " .. line
      end
    end
    lastSequence = sequence
  end, function(err) reportError("update", err) end)
end

registerForEvent("onDraw", function()
  local okTree, errTree = pcall(drawTree)
  if not okTree then reportError("shard tree draw", errTree) end
  if not config.showXP then return end
  ImGui.SetNextWindowPos(20, 120, ImGuiCond.FirstUseEver)
  ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.04, 0.08, 0.12, 0.72)
  local flags = ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.AlwaysAutoResize
    + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.NoMouseInputs
    + ImGuiWindowFlags.NoNavInputs + ImGuiWindowFlags.NoNavFocus
  -- Wrap text to ~28% of the screen width and cap the height at 60%.
  local screenW, screenH = GetDisplayResolution()
  local wrapWidth = math.max(320, math.min(560, screenW * 0.28))
  ImGui.SetNextWindowSizeConstraints(0, 0, wrapWidth + 24, screenH * 0.6)
  if ImGui.Begin("SDP shard XP tracker", flags) then
    ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + wrapWidth)
    for _, line in ipairs(encounterLines) do ImGui.Text(line) end
    ImGui.Separator()
    ImGui.Text("Recent shard XP awards")
    if #recentAwards == 0 then ImGui.Text("No shard XP awarded yet") end
    for _, line in ipairs(recentAwards) do ImGui.Text(line) end
    ImGui.PopTextWrapPos()
  end
  ImGui.End()
  ImGui.PopStyleColor(1)
end)

-- TweakXL creates the record; CET appends it before equipment is initialized.
registerForEvent("onInit", function()
  loadSettings()
  addNativeSettings()
  local key = "EquipmentArea.EyesCW.equipSlots"
  local slot = "SkillDrivenProgression.ProcessorEquipSlot"
  local slots = TweakDB:GetFlat(key)
  if type(slots) ~= "table" then
    print("SDP: cannot add neural processor socket")
    return
  end
  for _, current in ipairs(slots) do
    if TDBID.ToStringDEBUG(current) == slot then return end
  end
  table.insert(slots, slot)
  TweakDB:SetFlat(key, slots)
  print("SDP: neural processor socket added")
end)

-- The equipment area may finish restoring after development data. Retry
-- provisioning quietly; the redscript method is idempotent per character.
local elapsed = 0
local function retryProvisioning(delta)
  elapsed = elapsed + delta
  if elapsed < 3 then return end
  elapsed = 0
  pcall(function()
    local player = Game.GetPlayer()
    if not player then return end
    local system = PlayerDevelopmentSystem.GetInstance(player)
    if not system then return end
    local data = system:GetDevelopmentData(player)
    if data then
      data:SDP_EnsureStarterProcessor()
      applySettings(data)
    end
  end)
end

-- CET keeps only one handler per event and mod: a second
-- registerForEvent("onUpdate") silently replaces the first, so every
-- per-frame task goes through this single handler.
registerForEvent("onUpdate", function(delta)
  updateOverlay(delta)
  retryProvisioning(delta)
  refreshTree(delta)
end)
