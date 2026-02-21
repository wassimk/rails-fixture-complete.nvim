local M = {}

local _cache = {
  fixture_dirs = nil,
  files = nil,
  types = nil,
  type_to_file = nil,
  names = {},
}

function M._reset_cache()
  _cache = {
    fixture_dirs = nil,
    files = nil,
    types = nil,
    type_to_file = nil,
    names = {},
  }
end

function M.fixture_dirs()
  if _cache.fixture_dirs then
    return _cache.fixture_dirs
  end

  local buf_dir = vim.fn.expand('%:p:h')
  local found = vim.fs.find({ 'test', 'spec' }, {
    path = buf_dir,
    upward = true,
    type = 'directory',
  })

  local dirs = {}
  for _, dir in ipairs(found) do
    local fixture_dir = dir .. '/fixtures'
    if vim.fn.isdirectory(fixture_dir) == 1 then
      table.insert(dirs, fixture_dir)
    end
  end

  _cache.fixture_dirs = dirs
  return dirs
end

function M.scan_files()
  if _cache.files then
    return _cache.files
  end

  local files = {}
  for _, dir in ipairs(M.fixture_dirs()) do
    for _, ext in ipairs({ 'yml', 'yaml' }) do
      local pattern = dir .. '/**/*.' .. ext
      local found = vim.fn.glob(pattern, false, true)
      for _, file in ipairs(found) do
        table.insert(files, { path = file, dir = dir })
      end
    end
  end

  _cache.files = files
  return files
end

function M.get_types()
  if _cache.types then
    return _cache.types
  end

  local types = {}
  local type_to_file = {}

  for _, entry in ipairs(M.scan_files()) do
    local relative = entry.path:sub(#entry.dir + 2)
    local type_name = relative:match('(.+)%.ya?ml$')
    if type_name then
      type_name = type_name:gsub('/', '_')
      if not type_to_file[type_name] then
        table.insert(types, type_name)
        type_to_file[type_name] = entry.path
      end
    end
  end

  _cache.types = types
  _cache.type_to_file = type_to_file
  return types
end

function M.valid_type(type_name)
  if type_name == nil or type_name == '' then
    return false
  end

  if not _cache.type_to_file then
    M.get_types()
  end

  return _cache.type_to_file[type_name] ~= nil
end

function M.get_names(type_name)
  if _cache.names[type_name] then
    return _cache.names[type_name]
  end

  if not _cache.type_to_file then
    M.get_types()
  end

  local filename = _cache.type_to_file[type_name]
  if not filename then
    return {}
  end

  local names = {}
  local ok, _ = pcall(function()
    local file = io.open(filename, 'r')
    if not file then
      return
    end

    for line in file:lines() do
      local name = line:match('^([%w_]+):')
      if name then
        table.insert(names, name)
      end
    end

    file:close()
  end)

  if not ok then
    return {}
  end

  _cache.names[type_name] = names
  return names
end

function M.get_documentation(type_name, name)
  if not _cache.type_to_file then
    M.get_types()
  end

  local filename = _cache.type_to_file[type_name]
  if not filename then
    return ''
  end

  local documentation = ''
  local ok, _ = pcall(function()
    local file = io.open(filename, 'r')
    if not file then
      return
    end

    local matched = false
    local indent_level = nil

    for line in file:lines() do
      if not matched then
        if line:match('^' .. name .. ':') then
          matched = true
          documentation = name .. ':\n'
          indent_level = nil
        end
      else
        if line == '' or line == '--' then
          matched = false
        elseif indent_level == nil then
          indent_level = line:match('^(%s+)')
          if indent_level and #indent_level > 0 then
            documentation = documentation .. line .. '\n'
          else
            matched = false
          end
        else
          local current_indent = line:match('^(%s+)')
          if current_indent and #current_indent >= #indent_level then
            documentation = documentation .. line .. '\n'
          else
            matched = false
          end
        end
      end
    end

    file:close()
  end)

  if not ok then
    return ''
  end

  return documentation
end

return M
