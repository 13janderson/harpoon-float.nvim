local HarpoonFloat = {}

local harpoon = require("harpoon")
local list = harpoon:list()

function HarpoonFloat:new()
  self.__index = self

  local instance = setmetatable({}, self)
  instance:create_buffer_if_not_exists()
  instance.anchor_winnr = vim.api.nvim_get_current_win()
  instance:register_autocmds()

  harpoon:extend({
    LIST_CHANGE = function()
      instance:draw()
    end,
    ADD = function()
      instance:draw()
    end
  })
  return instance
end

function HarpoonFloat:register_autocmds()
  -- Resize the floating window on the anchoring window being resized
  vim.api.nvim_create_autocmd('WinResized', {
    desc = 'Redraw harpoon overlay on resize',
    group = vim.api.nvim_create_augroup('HarpoonFloatRedraw', { clear = true }),
    callback = function(e)
      if tonumber(e.match) == self.anchor_winnr then
        self:draw()
      end
    end,
  })

  -- Close the window and delete the buffer on the anchoring window being closed
  vim.api.nvim_create_autocmd('WinClosed', {
    desc = 'Close harpoon overlay on anchoring window being closed',
    group = vim.api.nvim_create_augroup('HarpoonFloatRedraw', { clear = true }),
    callback = function(e)
      if tonumber(e.match) == self.anchor_winnr then
        self:close()
      end
    end,
  })


  -- Close the window and delete the buffer on the anchoring window being closed
  vim.api.nvim_create_autocmd('WinClosed', {
    desc = 'Close harpoon overlay on anchoring window being closed',
    group = vim.api.nvim_create_augroup('HarpoonFloatCloseWithAnchoringWindow', { clear = true }),
    callback = function(e)
      if tonumber(e.match) == self.anchor_winnr then
        self:close()
      end
    end,
  })

  -- Close the window and delete the buffer on leaving vim
  vim.api.nvim_create_autocmd('VimLeave', {
    desc = 'Close harpoon overlay on leaving vim',
    group = vim.api.nvim_create_augroup('HarpoonFloatCloseWithVim', { clear = true }),
    callback = function(e)
      if tonumber(e.match) == self.anchor_winnr then
        self:close()
      end
    end,
  })
end

function HarpoonFloat:create_buffer_if_not_exists()
  if self.bufnr == nil then
    self.bufnr = vim.api.nvim_create_buf(true, false)
  end

  -- Event loop I guess?
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(self.bufnr) then
      ---@diagnostic disable-next-line
      vim.api.nvim_buf_set_option(self.bufnr, "relativenumber", false)
      ---@diagnostic disable-next-line
      vim.api.nvim_buf_set_option(self.bufnr, "number", true)
    end
  end)
end

function HarpoonFloat:set_buffer_lines()
  self:create_buffer_if_not_exists()

  local display = list:display()

  self.harpoon_lines = vim.tbl_deep_extend("force", {}, display)

  for i, harpoon_entry in pairs(display) do
    -- Simplify paths to be the last directory and the filename only
    local harpoon_entry_filename = vim.fn.fnamemodify(harpoon_entry, ":t")
    local harpoon_entry_dirname = vim.fn.fnamemodify(harpoon_entry, ":h:t")
    local harpoon_entry_simplified = harpoon_entry_dirname .. "/" .. harpoon_entry_filename
    self.harpoon_lines[i] = harpoon_entry_simplified

    local len = harpoon_entry_simplified:len()
    local max_len = -1
    if len > max_len then
      self.max_harpoon_entry_len = len
    end
  end
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, self.harpoon_lines)
end

---@return vim.api.keyset.win_config config
function HarpoonFloat:get_window_config()
  local win_width = vim.api.nvim_win_get_width(self.anchor_winnr)
  local win_height = vim.api.nvim_win_get_height(self.anchor_winnr)
  return {
    title = "HarpoonFloat",
    title_pos = "left",
    win = self.anchor_winnr,
    relative = "win",
    width = 40,
    height = #self.harpoon_lines,
    row = 0.4 * win_height,
    col = win_width * 0.7,
    style = "minimal",
    border = "rounded",
  }
end

function HarpoonFloat:create_window_if_not_exists()
  if self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr) then
    return
  end

  self.winnr = vim.api.nvim_open_win(self.bufnr, false, self:get_window_config())
end

function HarpoonFloat:draw()
  vim.schedule(function()
    self:set_buffer_lines()
    self:set_window_config()
  end)
end

function HarpoonFloat:set_window_config()
  self:create_window_if_not_exists()
  vim.api.nvim_win_set_config(self.winnr, self:get_window_config())
end

-- Closes the window and deletes the associated buffer
function HarpoonFloat:close()
  if vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_close(self.winnr, true)
  end
  if vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
end

-- Draw on being loaded
vim.schedule(function()
  local float = HarpoonFloat:new()
  float:draw()
end)

return HarpoonFloat
