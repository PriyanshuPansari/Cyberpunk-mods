-- Pure component catalog/validation; no game APIs, inventory writes or callbacks.
local M = {}
M.triggers = {"Off", "Opponent starts reloading", "Your ranged hit", "Your ranged headshot", "On upload", "After 3 seconds"}
M.payloads = {"Blindness", "Thermal pulses", "Electrical pulses", "Stun", "Native reference status", "Movement restriction", "Chemical pulses", "Physical pulses"}
M.conditions = {"Always", "Target already blinded", "Target already burning"}
M.budget = 12
M.presets = {
  {name = "Empty Chamber", first = {1, 1, 0}, second = {3, 2, 1}},
  {name = "Blackout Gun", first = {3, 1, 0}, second = {3, 2, 1}},
  {name = "Heat Response", first = {2, 2, 0}, second = {3, 1, 2}},
  {name = "Reload Blackout", first = {1, 1, 0}, second = {0, 0, 0}},
  {name = "Optics core", first = {4, 1, 0}, second = {0, 0, 0}},
  {name = "Thermal core", first = {4, 2, 0}, second = {0, 0, 0}},
  {name = "Shock core", first = {4, 3, 0}, second = {0, 0, 0}},
  {name = "Delayed Flash", first = {5, 1, 0}, second = {5, 4, 0}},
  {name = "Burning Trap", first = {4, 2, 0}, second = {3, 4, 2}},
  {name = "Cripple core", first = {4, 6, 0, 4, 25, 1}, second = {0, 0, 0}},
  {name = "Caustic blackout", first = {4, 1, 0, 8, 25, 1}, second = {4, 7, 0, 8, 10, 1}},
  {name = "Headshot furnace", first = {4, 6, 0, 8, 25, 1}, second = {3, 2, 0, 4, 50, 0.5}},
  {name = "Reload Shock", first = {1, 3, 0}, second = {3, 1, 0}},
}

local function integer(value, low, high)
  return type(value) == "number" and value == math.floor(value) and value >= low and value <= high
end

function M.ruleCost(rule)
  if type(rule) ~= "table" then return nil end
  local trigger, payload, condition = rule[1], rule[2], rule[3]
  local d, a, t = rule[4] or 4, rule[5] or 25, rule[6] or 1
  if (d ~= 2 and d ~= 4 and d ~= 8) or (a ~= 10 and a ~= 25 and a ~= 50)
      or (t ~= 0.5 and t ~= 1 and t ~= 2) then return nil end
  if trigger == 0 and payload == 0 and condition == 0 then return 0 end
  if not integer(trigger, 1, 5) or not integer(payload, 1, 8) or not integer(condition, 0, 2) then return nil end
  return ({2, 3, 1, 1, 1})[trigger] + ({2, 3, 3, 2, 3, 3, 3, 3})[payload] + (condition == 0 and 0 or 1)
end

function M.validate(recipe, weapon)
  if type(recipe) ~= "table" then return false, "Missing recipe." end
  local a, b = M.ruleCost(recipe.first), M.ruleCost(recipe.second)
  if not a or not b or a == 0 then return false, "Choose valid components and a primary rule." end
  if recipe.first[1] == recipe.second[1] and recipe.first[2] == recipe.second[2]
      and recipe.first[3] == recipe.second[3]
      and (recipe.first[2] ~= 5 or recipe.nativeFirst == recipe.nativeSecond) then return false, "Duplicate rules are not supported." end
  if recipe.first[2] == 5 and (type(recipe.nativeFirst) ~= "string" or recipe.nativeFirst == "") then return false, "Learn a native status for the primary rule." end
  if recipe.second[2] == 5 and (type(recipe.nativeSecond) ~= "string" or recipe.nativeSecond == "") then return false, "Learn a native status for the secondary rule." end
  if a + b > M.budget then return false, "Complexity exceeds 12. Use a headshot trigger or remove a rule." end
  if weapon and (recipe.first[1] == 1 or recipe.second[1] == 1 or recipe.first[1] > 3 or recipe.second[1] > 3) then
    return false, "Weapons require hit/headshot rules. Upload, timer and opponent-reload triggers require a program."
  end
  return true, "Complexity " .. (a + b) .. "/" .. M.budget
end

function M.copy(recipe)
  return {name = recipe.name, nativeFirst = recipe.nativeFirst, nativeSecond = recipe.nativeSecond,
    first = {recipe.first[1], recipe.first[2], recipe.first[3], recipe.first[4] or 4, recipe.first[5] or 25, recipe.first[6] or 1},
    second = {recipe.second[1], recipe.second[2], recipe.second[3], recipe.second[4] or 4, recipe.second[5] or 25, recipe.second[6] or 1}}
end

function M.describe(rule)
  if rule[1] == 0 then return "Off" end
  return M.triggers[rule[1] + 1] .. " -> " .. M.payloads[rule[2]] .. " | " .. M.conditions[rule[3] + 1]
    .. (rule[2] == 5 and " | native timing" or (" | " .. (rule[4] or 4) .. "s"))
    .. ((rule[2] == 2 or rule[2] == 3 or rule[2] == 7 or rule[2] == 8)
      and (" | " .. (rule[5] or 25) .. " base damage / " .. (rule[6] or 1) .. "s") or "")
end

return M
