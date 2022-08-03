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
  local cmd = string.format("aug %s\nau!", groupname)
  for _, autocmd in ipairs(autocmds) do
    cmd = cmd
      .. "\n"
      .. string.format(
        [[autocmd %s * call luaeval("require'profile'.%s('%s', {match=_A})", expand('<amatch>'))]],
        autocmd,
        fn,
        autocmd
      )
  end
  cmd = cmd .. "\naug END"
  vim.cmd(cmd)
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
  vim.cmd([[aug lua_profile
  au!
	aug END]])
end

return M
