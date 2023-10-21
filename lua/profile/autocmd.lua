local M = {}

local autocmds = {
  "BufAdd",
  "BufDelete",
  "BufEnter",
  "BufFilePost",
  "BufFilePre",
  "BufHidden",
  "BufLeave",
  "BufModifiedSet",
  "BufNew",
  "BufNewFile",
  "BufRead",
  -- "BufReadCmd",
  "BufReadPre",
  "BufUnload",
  "BufWinEnter",
  "BufWinLeave",
  "BufWipeout",
  "BufWrite",
  -- "BufWriteCmd",
  "BufWritePost",
  "ChanInfo",
  "ChanOpen",
  "CmdUndefined",
  "CmdlineChanged",
  "CmdlineEnter",
  "CmdlineLeave",
  "CmdwinEnter",
  "CmdwinLeave",
  "ColorScheme",
  "ColorSchemePre",
  "CompleteChanged",
  "CompleteDonePre",
  "CompleteDone",
  "CursorHold",
  "CursorHoldI",
  "CursorMoved",
  "CursorMovedI",
  "DiffUpdated",
  "DirChanged",
  -- "FileAppendCmd",
  "FileAppendPost",
  "FileAppendPre",
  "FileChangedRO",
  "ExitPre",
  "FileChangedShell",
  "FileChangedShellPost",
  -- "FileReadCmd",
  "FileReadPost",
  "FileReadPre",
  "FileType",
  -- "FileWriteCmd",
  "FileWritePost",
  "FileWritePre",
  "FilterReadPost",
  "FilterReadPre",
  "FilterWritePost",
  "FilterWritePre",
  "FocusGained",
  "FocusLost",
  "FuncUndefined",
  "UIEnter",
  "UILeave",
  "InsertChange",
  "InsertCharPre",
  "TextYankPost",
  "InsertEnter",
  "InsertLeavePre",
  "InsertLeave",
  "LspAttach",
  "LspDetach",
  "LspTokenUpdate",
  "MenuPopup",
  "OptionSet",
  "QuickFixCmdPre",
  "QuickFixCmdPost",
  "QuitPre",
  "RemoteReply",
  "SessionLoadPost",
  "ShellCmdPost",
  "Signal",
  "ShellFilterPost",
  "SourcePre",
  "SourcePost",
  -- "SourceCmd",
  "SpellFileMissing",
  "StdinReadPost",
  "StdinReadPre",
  "SwapExists",
  "Syntax",
  "TabEnter",
  "TabLeave",
  "TabNew",
  "TabNewEntered",
  "TabClosed",
  "TermOpen",
  "TermEnter",
  "TermLeave",
  "TermClose",
  "TermResponse",
  "TextChanged",
  "TextChangedI",
  "TextChangedP",
  "User",
  "VimEnter",
  "VimLeave",
  "VimLeavePre",
  "VimResized",
  "VimResume",
  "VimSuspend",
  "WinClosed",
  "WinEnter",
  "WinLeave",
  "WinNew",
  "WinScrolled",
}

local function create(groupname, fn)
  local aug = vim.api.nvim_create_augroup(groupname, {})
  for _, autocmd in ipairs(autocmds) do
    vim.api.nvim_create_autocmd(autocmd, {
      desc = "profile.nvim " .. fn,
      pattern = "*",
      group = aug,
      callback = function(args)
        require("profile")[fn](autocmd, { match = args.match })
      end,
    })
  end
end

M.instrument_start = function()
  create("lua_profile_start", "log_start")
end

M.instrument_auto = function()
  if vim.fn.exists("#lua_profile_start") ~= 0 then
    create("lua_profile_end", "log_end")
  else
    create("lua_profile", "log_instant")
  end
end

M.clear = function()
  vim.api.nvim_create_augroup("lua_profile", {})
  vim.api.nvim_create_augroup("lua_profile_start", {})
  vim.api.nvim_create_augroup("lua_profile_end", {})
end

return M
