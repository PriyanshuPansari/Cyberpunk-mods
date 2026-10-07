-- SDP Quickhack Crafting: the Quickhack Designer window (designer.lua) with the
-- design model in quickhack_designs.lua and the lab/sandbox in prototype.lua.
local prototypeWorkbench = require("prototype")
local designer = require("designer")
prototypeWorkbench.init()
designer.init(prototypeWorkbench)

local reported = {}
local function reportError(where, err)
  local message = where .. ": " .. tostring(err)
  if not reported[message] then reported[message] = true print("SDP crafting error " .. message) end
end

registerForEvent("onOverlayOpen", function() prototypeWorkbench.setOverlay(true) end)
registerForEvent("onOverlayClose", function() prototypeWorkbench.setOverlay(false) end)

registerForEvent("onDraw", function()
  local ok, err = pcall(designer.draw)
  if not ok then reportError("designer draw", err) end
end)

registerForEvent("onUpdate", function(delta)
  local ok, err = pcall(prototypeWorkbench.update, delta)
  if not ok then reportError("prototype workbench update", err) end
  ok, err = pcall(designer.update, delta)
  if not ok then reportError("designer update", err) end
end)

registerForEvent("onShutdown", function()
  local ok, err = pcall(designer.shutdown)
  if not ok then reportError("designer shutdown", err) end
end)
