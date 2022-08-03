local hrtime = vim.loop.hrtime

local start = hrtime()

return setmetatable({
  reset = function()
    start = hrtime()
  end,
}, {
  __call = function()
    -- Microseconds
    return (hrtime() - start) / 1e3
  end,
})
