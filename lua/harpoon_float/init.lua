local HarpoonFloat = {}

local harpoon = require("harpoon")
local list = harpoon:list()

function HarpoonFloat:new()
  self.__index = self

  local instance = setmetatable({}, self)
  instance.anchor_winnr = vim.api.nvim_get_current_win()
  instance:register_autocmds()

  harpoon:extend({
    LIST_CHANGE = function()
      instance:draw()
    end,
    ADD = function()
      instance:draw()
    end,
    UI_CREATE = function()
      instance:hide()
      vim.api.nvim_create_autocmd('WinClosed', {
        desc = "Redraw harpoon overlay on harpoon's own window being closed",
        group = vim.api.nvim_create_augroup('HarpoonFloatRedrawWithHarpoonWinClose', { clear = true }),
        callback = function(e)
          vim.schedule(function()
            if tonumber(e.match) == harpoon.ui.win_id then
              print "redrawing due to harpoon"
              self:draw()
            end
          end)
        end,
        once = true
      })
    end
  })

  return instance
end

function HarpoonFloat:register_autocmds()
  -- Resize the floating window on the anchoring window being resized
  vim.api.nvim_create_autocmd('WinResized', {
    desc = 'Redraw harpoon overlay on resize',
    group = vim.api.nvim_create_augroup('HarpoonFloatRedrawOnResize', { clear = true }),
    callback = function(e)
      if tonumber(e.match) == self.anchor_winnr then
        self:draw()
      end
    end,
  })
end

function HarpoonFloat:create_buffer_if_not_exists()
  if self.bufnr == nil then
    self.bufnr = vim.api.nvim_create_buf(false, true)
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
  print("anchor_winnr", self.anchor_winnr)
  local win_width = vim.api.nvim_win_get_width(self.anchor_winnr)
  local win_height = vim.api.nvim_win_get_height(self.anchor_winnr)

  return {
    title = "HarpoonFloat",
    title_pos = "left",
    win = self.anchor_winnr,
    relative = "win",
    width = 40,
    height = math.max(1, #self.harpoon_lines),
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
    -- Only draw if there is a single non-floating window open.
    -- Exlcuding our own window as a precaution
    local open_wins = vim.tbl_filter(function(v)
      return v == self.winnr or vim.api.nvim_win_get_config(v).relative == ''
    end, vim.api.nvim_list_wins())
    if #open_wins == 1 then
      self:set_buffer_lines()
      self:create_window_if_not_exists()
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
  if vim.api.nvim_win_is_valid(self.winnr) then
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

HarpoonFloat:setup()

return HarpoonFloat
