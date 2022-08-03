# profile.nvim

A lua profiler for neovim

**WARNING:** this is a gigantic hack that works by monkey patching all your lua functions. I made this for my own personal use to optimize my own plugins, and make no guarantees about stability, utility, or that it won't crash your neovim.

## Quick Start

Here is a default config that you can copy/paste into the start of your init.lua:

```lua
local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
  require("profile").instrument_autocmds()
  if should_profile:lower():match("^start") then
    require("profile").start("*")
  else
    require("profile").instrument("*")
  end
end

local function toggle_profile()
  local prof = require("profile")
  if prof.is_recording() then
    prof.stop()
    vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
      if filename then
        prof.export(filename)
        vim.notify(string.format("Wrote %s", filename))
      end
    end)
  else
    prof.start("*")
  end
end
vim.keymap.set("", "<f1>", toggle_profile)
```

**How do I use it?** \
When you want to run Neovim and profile something, start it with `NVIM_PROFILE=1 nvim`. Then you can tap `<F1>` to start a profile, and `<F1>` again to complete the profile and save it to a file. If you instead want to profile the _startup_ of neovim, do `NVIM_PROFILE=start nvim` and then hit `<F1>` as soon as neovim loads.

**Warning: traces can be very large!** \
The trace files can grow extremely large very quickly, and they are stored in memory until exported. This means that it will balloon the memory usage of neovim, might take a long time to write out to disk, could possibly crash neovim, or might crash the trace viewer you use. To avoid this I'd recommend taking _relatively short_ profiles, and wherever possible target the specific module(s) you care about. For example, instead of `start("*")`, it would be much better if I could use `start("aerial*")` to profile just my aerial.nvim plugin.

You can view the traces in `chrome://tracing` or at https://ui.perfetto.dev/

For more details on the API, look at the docstrings in [profile.lua](lua/profile.lua)
