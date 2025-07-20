
local HarpoonFloat = require "harpoon_float"
local M = {}

M.setup = function()
  local float = HarpoonFloat:new()
  float:draw()
end

return M
