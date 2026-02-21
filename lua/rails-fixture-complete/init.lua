local M = {}

M._config = {
  sources = {
    types = true,
    names = true,
  },
}

M._setup_called = false

function M.setup(opts)
  M._config = vim.tbl_deep_extend('force', M._config, opts or {})
  M._setup_called = true

  require('rails-fixture-complete.fixtures')._reset_cache()
end

function M.is_available()
  if vim.bo.filetype ~= 'ruby' then
    return false
  end

  local path = vim.fn.expand('%:p')
  return path:find('/test/') ~= nil or path:find('/spec/') ~= nil
end

return M
