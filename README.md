# Motivation

In general, I agree with the premise of harpoon in that you are often only editing the same 4-5 files at once but I find temporarily memorizing where each file is in the list
almost impossible to achieve.

Thus, I created a basic floating window into the harpoon list which is automatically updated by hooking into Harpoon's own events. These events were only a recent feature of harpoon 2 
and thus this extension is only compatible with Harpoon2 and above.

The floating window is not intended to be a **replacement** for the harpoon quick_menu, it is intended to complement it by displaying it's state while it does not appear.
You thus still edit harpoon entries via the quick menu like before but have these constantly shown to you in a floating window.

Features:
- The floating window is loaded on neovim startup, AFTER harpoon is loaded. 
- Floating window is anchored to the current window and is resized when that window is resized.
- Updates to harpoon list are reflected in floating window by hooking into harpoon events.


# Installation

# Lazy

```lua
{
    "13janderson/harpoon-float.nvim",
    dependencies = {
      "ThePrimeagen/harpoon",
      branch = "harpoon2"
    },
},
```



