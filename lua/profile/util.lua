local M = {}

local MAX_ARG_LEN = 200
local tbl_isarray = vim.isarray or vim.tbl_isarray or vim.tbl_islist
local pack_len = vim.F.pack_len
local split = vim.split

M.DEFAULT_PROCESS_ID = 1
M.DEFAULT_THREAD_ID = 1

if jit and jit.version then
  local ffi = require("ffi")

  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    ffi.cdef([[
      typedef unsigned long DWORD;
      DWORD GetCurrentThreadId();
    ]])

    ---@return number The current thread's ID number (1-or-more value).
    function M.get_thread_id()
      return ffi.C.GetCurrentThreadId()
    end

    -- Mac doesn't have gettid easily available
  elseif vim.fn.has("mac") == 1 then
    ---@return number The current thread's ID number (1-or-more value).
    function M.get_thread_id()
      return M.DEFAULT_THREAD_ID
    end
  else
    ffi.cdef([[
      typedef int pid_t;
      pid_t gettid();
    ]])

    ---@return number The current thread's ID number (1-or-more value).
    function M.get_thread_id()
      return ffi.C.gettid()
    end
  end
else
  ---@return number The current thread's ID number (1-or-more value).
  function M.get_thread_id()
    return M.DEFAULT_THREAD_ID
  end
end

---@return number # The current process's ID number (1-or-more value).
function M.get_process_id()
  return vim.uv.os_getpid()
end

---@param glob string
---@return string
M.path_glob_to_regex = function(glob)
  local pattern = string.gsub(glob, "%.", "[%./]")
  pattern = string.gsub(pattern, "*", ".*")
  return "^" .. pattern .. "$"
end

---@param name string
---@return string
M.normalize_module_name = function(name)
  local ret = string.gsub(name, "/", ".")
  return ret
end

---@param haystack string
---@param prefix string
---@return boolean
M.startswith = function(haystack, prefix)
  return string.find(haystack, prefix) == 1
end

---@param path string
---@return string module
---@return string tail
M.split_path = function(path)
  local pieces = split(path, ".", { plain = true })
  if #pieces == 1 then
    return "_G", path
  end
  local mod = table.concat(pack_len(unpack(pieces, 1, #pieces - 1)), ".")
  return mod, pieces[#pieces]
end

local function sanitize(table)
  local clean = {}
  local iterfn
  if tbl_isarray(table) then
    iterfn = ipairs
  else
    iterfn = pairs
  end
  for i, v in iterfn(table) do
    local t = type(v)
    if t == "string" then
      if string.len(v) > MAX_ARG_LEN then
        clean[tostring(i)] = string.sub(v, 1, MAX_ARG_LEN - 3) .. "..."
      else
        clean[tostring(i)] = v
      end
    elseif t == "nil" or t == "boolean" or t == "number" then
      clean[tostring(i)] = v
    end
  end
  -- If no args, then return nil
  if next(clean) == nil then
    return nil
  else
    return clean
  end
end

---@param ... any[]
---@return any
M.format_args = function(...)
  local args = pack_len(...)
  if args.n == 0 then
    return nil
  elseif args.n == 1 and type(args[1]) == "table" then
    return sanitize(args[1])
  else
    return sanitize(args)
  end
end

return M
