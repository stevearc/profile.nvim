local M = {}

local MAX_ARG_LEN = 200
local tbl_islist = vim.tbl_islist

M.split = function(string, pattern)
  local ret = {}
  for token in string.gmatch(string, "[^" .. pattern .. "]+") do
    table.insert(ret, token)
  end
  return ret
end

M.pack = function(...)
  return { n = select("#", ...), ... }
end

M.path_glob_to_regex = function(glob)
  local pattern = string.gsub(glob, "%.", "[%./]")
  pattern = string.gsub(pattern, "*", ".*")
  return "^" .. pattern .. "$"
end

M.normalize_module_name = function(name)
  return string.gsub(name, "/", ".")
end

M.startswith = function(haystack, prefix)
  return string.find(haystack, prefix) == 1
end

M.split_path = function(path)
  local pieces = M.split(path, "\\.")
  if #pieces == 1 then
    return "_G", path
  end
  local mod = table.concat(M.pack(unpack(pieces, 1, #pieces - 1)), ".")
  return mod, pieces[#pieces]
end

local function sanitize(table)
  local clean = {}
  local iterfn
  if tbl_islist(table) then
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

M.format_args = function(...)
  local args = M.pack(...)
  if args.n == 0 then
    return nil
  elseif args.n == 1 and type(args[1]) == "table" then
    return sanitize(args[1])
  else
    return sanitize(args)
  end
end

return M
