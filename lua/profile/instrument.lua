local clock = require("profile.clock")
local util = require("profile.util")
local M = {}

local rawrequire = require
local events = {}
local ignore_list = {
  "^_G$",
  "^bit$",
  "^coroutine$",
  "^debug$",
  "^ffi$",
  "^io$",
  "^jit.*$",
  "^luv$",
  "^math$",
  "^os$",
  "^package$",
  "^string$",
  "^table$",
  "^vim%.inspect$",
  "^profile.*$",
  "^lspconfig%.util%.script_path$",
  "^plenary%.async_lib.*$",
}

local instrument_list = {}
local wrapped_modules = {}
local wrapped_functions = {}
M.recording = false
local exposed_globals = {
  ["vim"] = vim,
  ["vim.fn"] = vim.fn,
  ["vim.api"] = vim.api,
}

local function all_modules()
  return vim.tbl_extend("keep", package.loaded, exposed_globals)
end

local function should_instrument(name)
  -- Don't double-wrap
  if wrapped_functions[name] then
    return false
  elseif wrapped_modules[name] then
    return false
  else
    for _, pattern in ipairs(ignore_list) do
      if string.match(name, pattern) then
        return false
      end
    end
    return true
  end
end

local function wrap_function(name, fn)
  return function(...)
    local arg_string = util.format_args(...)
    local start = clock()
    local function handle_result(...)
      local delta = clock() - start
      M.add_event({
        name = name,
        args = arg_string,
        cat = "function",
        ph = "X",
        ts = start,
        dur = delta,
      })
      return ...
    end
    return handle_result(fn(...))
  end
end

local function patch_function(modname, mod, name)
  local fn = mod[name]
  if type(fn) == "function" then
    local fnname = string.format("%s.%s", modname, name)
    if should_instrument(fnname) then
      wrapped_functions[fnname] = fn
      mod[name] = wrap_function(fnname, fn)
    end
  end
end

local function maybe_wrap_function(name)
  local parent_mod_name, fn = util.split_path(name)
  local mod = M.get_module(parent_mod_name)
  if mod then
    patch_function(parent_mod_name, mod, fn)
  end
end

local function wrap_module(name, mod)
  name = util.normalize_module_name(name)
  if type(mod) ~= "table" or not should_instrument(name) then
    return
  end
  wrapped_modules[name] = true
  for k in pairs(mod) do
    -- Do not wrap module functions that start with '_'
    -- Those have to be explicitly passed to instrument()
    if type(k) == "string" and not util.startswith(k, "_") then
      patch_function(name, mod, k)
    end
  end
end

local function should_profile_module(name)
  for _, pattern in ipairs(instrument_list) do
    if string.match(name, pattern) then
      return true
    end
  end
  return false
end

M.hook_require = function(module_name)
  if rawrequire ~= require then
    return
  end
  local wrapped_require = wrap_function("require", rawrequire)
  _G.require = function(name)
    -- Don't time the require if the file is already loaded
    if package.loaded[name] or not should_profile_module(name) then
      return rawrequire(name)
    end
    local mod = wrapped_require(name)
    wrap_module(name, mod)
    return mod
  end
end

M.clear_events = function()
  events = {}
end

M.add_event = function(event)
  if M.recording then
    table.insert(events, event)
  end
end

M.get_module = function(name)
  local ok, mod = pcall(require, name)
  if ok then
    if type(mod) == "table" then
      return mod
    else
      return nil
    end
  else
    mod = _G
    local paths = util.split(name, "\\.")
    for _, token in ipairs(paths) do
      mod = mod[token]
      if not mod then
        break
      end
    end
    return type(mod) == "table" and mod or nil
  end
end

M.get_events = function()
  return events
end

M.ignore = function(name)
  table.insert(ignore_list, util.path_glob_to_regex(name))
end

M.print_modules = function()
  for module, _ in pairs(wrapped_modules) do
    print(module)
  end
end

local function instrument(_, name)
  local pattern = util.path_glob_to_regex(name)
  if not vim.tbl_contains(instrument_list, pattern) then
    table.insert(instrument_list, pattern)
  end
  M.hook_require(name)
  for modname, mod in pairs(all_modules()) do
    if string.match(modname, pattern) then
      wrap_module(modname, mod)
    end
  end
  maybe_wrap_function(name)
end

return setmetatable(M, {
  __call = instrument,
})
