# This has been moved my owndedicated fork of harpoon: [here](https://github.com/13janderson/harpoon2) 

The 

# Motivation

In general, I agree with the premise of harpoon in that you are often only editing the same 4-5 files at once but I find temporarily memorizing where each file is in the list
almost impossible to achieve.

Thus, I created a basic floating window into the harpoon list which is automatically updated by hooking into Harpoon's own events. These events were only a recent feature of harpoon 2 
and thus this extension is only compatible with Harpoon2 and above.

The floating window is not intended to be a **replacement** for the harpoon quick_menu, it is intended to complement it by displaying it's state while it does not appear.
You thus still edit harpoon entries via the quick menu like before but have these constantly shown to you in a floating window.

To make this distinction clear, the floating window is hidden once the harpoon menu is opened and then re-opened once the harpoon menu is closed.

# Functionality
- The floating window is loaded on neovim startup, **AFTER** harpoon is loaded. 
- Floating window is anchored to the current window and is resized when that window is resized.
- Updates to harpoon list are reflected in floating window by hooking into harpoon events.
- Floating window is **NEVER** open at the same time as harpoon's menu window.
- Floating window will not appear **EVER** again for the current session after the user forcefully closes it.
- Floating window will not appear if there are no entries in the harpoon list, as to not waste screen space.


# Installation

To install my own fork of harpoon with this feature better integrated (With a nice configuration):

## Lazy

```lua
{
    "13janderson/harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require('harpoon')
      harpoon:setup {
        settings = {
          save_on_toggle = true,
          save_on_ui_close = true,
          tmux_autoclose_windows = false,
        },
      }
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
      -- Pseudo arrow keys for config
      vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-b>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-m>", function() harpoon:list():select(4) end)
},
```

To install this plugin directly for use with the original harpoon:

## Lazy

```lua
{
    "13janderson/harpoon-float.nvim",
    dependencies = {
      "ThePrimeagen/harpoon",
      branch = "harpoon2"
    },
},
```



