local M = {}

local _originals = {}

M.users_yml = [[bob:
  name: Bob Smith
  email: bob@example.com

alice:
  name: Alice Jones
  email: alice@example.com
]]

M.posts_yml = [[hello_world:
  title: Hello World
  body: This is a post
  user: bob
]]

function M.setup_mocks()
  _originals = {
    expand = rawget(vim.fn, 'expand'),
    isdirectory = rawget(vim.fn, 'isdirectory'),
    glob = rawget(vim.fn, 'glob'),
    fs_find = vim.fs.find,
    io_open = io.open,
    filetype = vim.bo.filetype,
  }

  vim.bo.filetype = 'ruby'

  M.buf_dir = nil
  M.buf_path = nil
  M.fs_find_result = nil
  M.directories = nil
  M.glob_results = nil
  M.file_contents = nil
  M.fixture_files = {
    '/project/test/fixtures/users.yml',
    '/project/test/fixtures/posts.yml',
  }

  vim.fn.expand = function(expr)
    if expr == '%:p:h' then
      return M.buf_dir or '/project/test'
    elseif expr == '%:p' then
      return M.buf_path or '/project/test/models/user_test.rb'
    end
    return expr
  end

  vim.fs.find = function(names, _)
    if M.fs_find_result then
      return M.fs_find_result
    end
    local result = {}
    for _, name in ipairs(names) do
      if name == 'test' then
        table.insert(result, '/project/test')
      end
    end
    return result
  end

  vim.fn.isdirectory = function(dir)
    if M.directories then
      return M.directories[dir] and 1 or 0
    end
    if dir == '/project/test/fixtures' then
      return 1
    end
    return 0
  end

  vim.fn.glob = function(pattern, _, _)
    if M.glob_results and M.glob_results[pattern] then
      return M.glob_results[pattern]
    end
    if pattern:match('%.yml$') then
      return M.fixture_files or {}
    end
    if pattern:match('%.yaml$') then
      return {}
    end
    return {}
  end

  io.open = function(filename, _)
    local content = nil

    if M.file_contents and M.file_contents[filename] then
      content = M.file_contents[filename]
    elseif filename:match('users%.ya?ml$') then
      content = M.users_yml
    elseif filename:match('posts%.ya?ml$') then
      content = M.posts_yml
    end

    if not content then
      return nil, 'No such file'
    end

    local line_list = vim.split(content, '\n', { plain = true })
    if #line_list > 0 and line_list[#line_list] == '' then
      table.remove(line_list)
    end

    local mock_file = {}

    function mock_file:lines()
      local i = 0
      return function()
        i = i + 1
        return line_list[i]
      end
    end

    function mock_file:close() end

    return mock_file
  end
end

function M.teardown_mocks()
  if _originals.expand then
    rawset(vim.fn, 'expand', _originals.expand)
  else
    rawset(vim.fn, 'expand', nil)
  end

  if _originals.isdirectory then
    rawset(vim.fn, 'isdirectory', _originals.isdirectory)
  else
    rawset(vim.fn, 'isdirectory', nil)
  end

  if _originals.glob then
    rawset(vim.fn, 'glob', _originals.glob)
  else
    rawset(vim.fn, 'glob', nil)
  end

  vim.fs.find = _originals.fs_find
  io.open = _originals.io_open

  pcall(function()
    vim.bo.filetype = _originals.filetype or ''
  end)

  _originals = {}

  require('rails-fixture-complete.fixtures')._reset_cache()
  require('rails-fixture-complete')._setup_called = false
  require('rails-fixture-complete')._config = {
    sources = {
      types = true,
      names = true,
    },
  }
end

return M
