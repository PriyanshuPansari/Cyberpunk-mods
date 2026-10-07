-- Quickhack designs: pure data model shared by the designer window and tests.
-- No game APIs. The cost model and signature format are mirrored by
-- CustomPrograms.reds (SDPQHDesign); change both together.
local recipes = require("prototype_recipes")
local M = {}

M.version = 1
M.slotCount = 4
M.slotLetters = {"A", "B", "C", "D"}
M.maxDesigns = 48
M.maxName = 48

-- Index order matches the rule encoding {trigger, payload, condition, duration, amount, interval}.
M.durations = {2, 4, 8}
M.amounts = {10, 25, 50}
M.intervals = {2, 1, 0.5}
M.lifetimes = {15, 30, 60}
M.maxSpread = 3

-- Triggers and payloads a compiled program may use. The native reference payload
-- (5) stays a lab-only comparison tool: designed programs use our own primitives.
M.programTriggers = {1, 2, 3, 4, 5}
M.programPayloads = {1, 2, 3, 4, 6, 7, 8}

M.triggerText = {
  [1] = "When the target starts reloading",
  [2] = "When you hit the target with a ranged weapon",
  [3] = "When you headshot the target",
  [4] = "On upload",
  [5] = "3 seconds after upload",
}
M.payloadText = {
  [1] = "blindness",
  [2] = "thermal damage pulses",
  [3] = "electrical damage pulses",
  [4] = "stun",
  [6] = "movement restriction (speed x0.2)",
  [7] = "chemical damage pulses",
  [8] = "physical damage pulses",
}
M.conditionText = {[0] = "", [1] = " (only if already blinded)", [2] = " (only if already burning)"}

-- Component costs. Items.QuickHackUncommonMaterial1 / QuickHackRareMaterial1.
M.chipCost = 10

local function indexOf(list, value)
  for i, v in ipairs(list) do if v == value then return i end end
  return nil
end
M.indexOf = indexOf

function M.damaging(payload)
  return payload == 2 or payload == 3 or payload == 7 or payload == 8
end

-- Points for strength/timing parameters. Lists are ordered cheap -> expensive.
function M.paramPoints(rule)
  if rule[1] == 0 then return 0 end
  local points = indexOf(M.durations, rule[4] or 4) - 1
  if M.damaging(rule[2]) then
    points = points + (indexOf(M.amounts, rule[5] or 25) - 1) + (indexOf(M.intervals, rule[6] or 1) - 1)
  end
  return points
end

function M.copy(design)
  local copy = recipes.copy(design)
  copy.id = design.id
  copy.lifetime = design.lifetime or 30
  copy.spread = design.spread or 0
  copy.nativeFirst, copy.nativeSecond = nil, nil
  return copy
end

local function validRule(rule)
  if type(rule) ~= "table" then return false end
  if rule[1] == 0 then return true end
  return indexOf(M.programTriggers, rule[1]) ~= nil and indexOf(M.programPayloads, rule[2]) ~= nil
end

local function wellFormedRule(rule, primary)
  if type(rule) ~= "table" then return false end
  if not indexOf(M.durations, rule[4]) or not indexOf(M.amounts, rule[5]) or not indexOf(M.intervals, rule[6]) then return false end
  if rule[1] == 0 then return not primary and rule[2] == 0 and rule[3] == 0 end
  return indexOf(M.programTriggers, rule[1]) ~= nil and indexOf(M.programPayloads, rule[2]) ~= nil
    and (rule[3] == 0 or rule[3] == 1 or rule[3] == 2)
end

-- Editable in the designer: every field holds a known choice. A well-formed
-- design may still be over budget or duplicate its rules; validate() decides
-- whether it can be compiled. The library keeps well-formed drafts.
function M.wellFormed(design)
  return type(design) == "table" and type(design.name) == "string"
    and wellFormedRule(design.first, true) and wellFormedRule(design.second, false)
    and indexOf(M.lifetimes, design.lifetime) ~= nil
    and (design.spread == 0 or design.spread == 1 or design.spread == 2 or design.spread == 3)
end

function M.validate(design)
  if type(design) ~= "table" then return false, "Missing design." end
  if type(design.name) ~= "string" or design.name:match("^%s*$") then return false, "Name the design." end
  if #design.name > M.maxName then return false, "Names are limited to " .. M.maxName .. " characters." end
  local ok, reason = recipes.validate(design, false)
  if not ok then return false, reason end
  if not validRule(design.first) or not validRule(design.second) then
    return false, "Programs use designed primitives only; native reference statuses stay in the Lab."
  end
  if not indexOf(M.lifetimes, design.lifetime) then return false, "Choose a program lifetime of 15, 30 or 60 seconds." end
  if type(design.spread) ~= "number" or design.spread ~= math.floor(design.spread)
      or design.spread < 0 or design.spread > M.maxSpread then
    return false, "Spread must be 0 to " .. M.maxSpread .. " targets."
  end
  return true, reason
end

-- All derived numbers come from integer points so Lua and redscript agree exactly.
-- Mirrors SDPQHDesign.Ram/UploadTenths/Cooldown/Uncommon/Rare.
function M.derive(points)
  return {
    points = points,
    ram = 1 + math.floor((points + 1) / 2),
    uploadTenths = 3 + points,
    cooldown = 4 + 2 * points,
    uncommon = points,
    rare = points > 14 and math.floor((points - 13) / 2) or 0,
  }
end

function M.stats(design)
  local complexity = recipes.ruleCost(design.first) + recipes.ruleCost(design.second)
  local stats = M.derive(complexity + M.paramPoints(design.first) + M.paramPoints(design.second)
    + 2 * design.spread + (indexOf(M.lifetimes, design.lifetime) - 1))
  stats.complexity = complexity
  return stats
end

function M.uploadText(stats)
  return string.format("%d.%ds", math.floor(stats.uploadTenths / 10), stats.uploadTenths % 10)
end

local function ruleSignature(rule)
  if rule[1] == 0 then return "0" end
  return table.concat({rule[1], rule[2], rule[3], indexOf(M.durations, rule[4] or 4),
    indexOf(M.amounts, rule[5] or 25), indexOf(M.intervals, rule[6] or 1)}, ".")
end

-- Must match SDPQHDesign.Signature() in CustomPrograms.reds.
function M.signature(design)
  return ruleSignature(design.first) .. "|" .. ruleSignature(design.second) .. "|"
    .. indexOf(M.lifetimes, design.lifetime) .. "|" .. design.spread
end

local function ruleSentence(rule)
  local text = M.triggerText[rule[1]] .. M.conditionText[rule[3]] .. ": " .. M.payloadText[rule[2]]
  if M.damaging(rule[2]) then
    text = text .. ", " .. (rule[5] or 25) .. " base damage every " .. (rule[6] or 1) .. "s"
  end
  return text .. " for " .. (rule[4] or 4) .. "s."
end

function M.describe(design)
  local lines = {ruleSentence(design.first)}
  if design.second[1] ~= 0 then lines[#lines + 1] = ruleSentence(design.second) end
  local tail = "Program runs " .. design.lifetime .. "s with 3 charges per rule."
  if design.spread > 0 then
    tail = tail .. " On upload it spreads to " .. design.spread .. " nearby "
      .. (design.spread == 1 and "enemy" or "enemies") .. " within 8m."
  end
  lines[#lines + 1] = tail
  return table.concat(lines, "\n")
end

function M.new(name)
  return {name = name or "New design", first = {4, 1, 0, 4, 25, 1}, second = {0, 0, 0, 4, 25, 1},
    lifetime = 30, spread = 0}
end

-- Seed designs from the lab presets that use only designed primitives.
function M.starters()
  local list = {}
  for _, preset in ipairs(recipes.presets) do
    local design = M.copy(preset)
    if M.validate(design) then list[#list + 1] = design end
  end
  return list
end

-- Reassign ids and drop anything invalid. Returns the clean list and a skip count.
function M.sanitize(list)
  local clean, skipped = {}, 0
  if type(list) ~= "table" then return clean, 0 end
  for _, value in ipairs(list) do
    if #clean >= M.maxDesigns then skipped = skipped + 1
    elseif type(value) == "table" and type(value.first) == "table" and type(value.second) == "table" then
      local ok, design = pcall(M.copy, value)
      if ok and type(value.name) == "string" then
        design.name = value.name:sub(1, M.maxName)
        if M.wellFormed(design) then clean[#clean + 1] = design else skipped = skipped + 1 end
      else skipped = skipped + 1 end
    else skipped = skipped + 1 end
  end
  for i, design in ipairs(clean) do design.id = i end
  return clean, skipped
end

function M.encode(list)
  local out = {}
  for i, design in ipairs(list) do
    out[i] = {name = design.name, first = design.first, second = design.second,
      lifetime = design.lifetime, spread = design.spread}
  end
  return {version = M.version, designs = out}
end

-- Accepts the library format or the older single-recipe blueprint (versions 1-2).
function M.decode(value)
  if type(value) ~= "table" then return nil, "Library file is not a table." end
  if value.version == M.version and type(value.designs) == "table" then
    return M.sanitize(value.designs)
  end
  if (value.version == 1 or value.version == 2) and type(value.recipe) == "table" then
    return M.sanitize({value.recipe})
  end
  return nil, "Unsupported library version."
end

function M.findBySignature(list, signature)
  for _, design in ipairs(list) do
    if M.validate(design) and M.signature(design) == signature then return design end
  end
  return nil
end

function M.uniqueName(list, base)
  local taken = {}
  for _, design in ipairs(list) do taken[design.name] = true end
  if not taken[base] then return base end
  local n = 2
  while taken[base .. " " .. n] do n = n + 1 end
  return base .. " " .. n
end

return M
