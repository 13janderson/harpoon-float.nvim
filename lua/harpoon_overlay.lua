-- Want to have a view into harpoon at all times
-- In general, I agree with the premise of harpoon in that you are often only editing
-- the same 4-5 files at once but I find temporarily memorizing where each file is in the list
-- almost impossible to achieve.

local HarpoonFloat = require "harpoon_float"
local M = {}

M.setup = function()
  local float = HarpoonFloat:new()
  float:update_buffer_lines()
  float:create_window_if_not_exists()
end

return M
