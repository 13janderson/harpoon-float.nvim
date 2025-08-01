local HarpoonFloat = {}

local harpoon = require("harpoon")
local list = harpoon:list()

function HarpoonFloat:new()
  self.__index = self

  local instance = setmetatable({}, self)
  instance.anchor_winnr = vim.api.nvim_get_current_win()
  instance.is_hidden = false
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
    desc = 'Redraw harpoon float on resize',
    group = vim.api.nvim_create_augroup('HarpoonFloatRedrawOnResize', { clear = true }),
    callback = function(e)
      if tonumber(e.match) == self.anchor_winnr then
        self:draw()
      end
    end,
  })

  -- Hide floating window upon another window being opened
  vim.api.nvim_create_autocmd('WinNew', {
    desc = 'Hide harpoon float on another window being opened',
    group = vim.api.nvim_create_augroup('HarpoonFloatHideWithNewWindow', { clear = true }),
    callback = function(e)
      if tonumber(e.match) ~= self.winnr then
        self:hide()
      end
    end,
  })

  -- Mark floating window as hidden if it is ever manually closed by the user
  -- This enforces the window to NEVER be opened again in this neovim instance
  vim.api.nvim_create_autocmd('WinClosed', {
    desc = "Detect manual closing of our own window",
    group = vim.api.nvim_create_augroup('HarpoonFloatClose', { clear = true }),
    callback = function(e)
      vim.schedule(function()
        if tonumber(e.match) == self.winnr then
          -- Lucky for us this is only triggered when the user closes our window not when we hide it ourself
          self.is_hidden = true
        else
          -- If a window is closed which is not our window, then we should try to draw again
          self:draw()
        end
      end)
    end,
  })
end

function HarpoonFloat:create_buffer_if_not_exists()
  if self.bufnr == nil or not vim.api.nvim_buf_is_valid(self.bufnr) then
    self.bufnr = vim.api.nvim_create_buf(false, true)
  end
end

-- Returns whether the harpoon list has any entries or not
---@return boolean
function HarpoonFloat:harpoon_has_entries()
  local entries = list:display()
  if #entries == 0 or (#entries == 1 and entries[1] == "") then
    return false
  end
  return true
end

-- Sets the buffer lines, creating the buffer if needed first.
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
  if (not vim.api.nvim_win_is_valid(self.anchor_winnr)) then
    self.anchor_winnr = vim.api.nvim_get_current_win()
  end

  local win_width = vim.api.nvim_win_get_width(self.anchor_winnr)

  local config = {
    title = "HarpoonFloat",
    title_pos = "left",
    win = self.anchor_winnr,
    relative = "win",
    width = 35,
    height = math.max(1, #self.harpoon_lines),
    row = 0,
    col = win_width * 0.6,
    style = "minimal",
    border = "rounded",
  }
  return config
end

-- Sets the window config, creating the window if needed first.
function HarpoonFloat:create_window_if_not_exists()
  local config = self:get_window_config()
  if self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_set_config(self.winnr, config)
  end

  self.winnr = vim.api.nvim_open_win(self.bufnr, false, config)
  vim.wo[self.winnr].number = true
  vim.wo[self.winnr].relativenumber = false
end

function HarpoonFloat:draw()
  -- Only draw ourselves if we are not hidden by user forcefully
  if self.is_hidden then
    return
  end

  vim.schedule(function()
    -- Only draw if there is a single non-floating window open.
    -- Exlcuding our own window as a precaution
    local open_wins = vim.tbl_filter(function(v)
      -- Filter gives us the elements where this predicate is true
      return v ~= self.winnr and vim.api.nvim_win_get_config(v).relative == ''
    end, vim.api.nvim_list_wins())

    if #open_wins == 1 then
      if self:harpoon_has_entries() then
        self:set_buffer_lines()
        self:create_window_if_not_exists()
      end
    end
  end)
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

function HarpoonFloat:hide()
  if self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr) then
    vim.api.nvim_win_hide(self.winnr)
  end
end

function HarpoonFloat:setup()
  vim.schedule(function()
    -- Draw on being loaded
    local float = self:new()
    float:draw()
  end)
end

return HarpoonFloat
