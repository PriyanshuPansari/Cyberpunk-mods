-- SDP Quickhack Crafting: the prototype workbench window (prototype.lua, recipes in prototype_recipes.lua).
local prototypeWorkbench = require("prototype")
prototypeWorkbench.init()

local reported = {}
local function reportError(where, err)
  local message = where .. ": " .. tostring(err)
  if not reported[message] then reported[message] = true print("SDP crafting error " .. message) end
end

registerForEvent("onOverlayOpen", function() prototypeWorkbench.setOverlay(true) end)
registerForEvent("onOverlayClose", function() prototypeWorkbench.setOverlay(false) end)

registerForEvent("onDraw", function()
  local ok, err = pcall(prototypeWorkbench.draw)
  if not ok then reportError("prototype workbench draw", err) end
end)

registerForEvent("onUpdate", function(delta)
  local ok, err = pcall(prototypeWorkbench.update, delta)
  if not ok then reportError("prototype workbench update", err) end
end)
