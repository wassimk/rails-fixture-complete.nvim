local M = {}

--- Build LSP-format completion items for Rails fixture completions.
--- Contextually returns either fixture name items (when inside `type(:`) or fixture type items.
---@param cursor_info { line_text: string, line_number: number, cursor_col: number }
---  line_number and cursor_col are 0-indexed
---@return { items: lsp.CompletionItem[], is_name_completion: boolean }|nil
function M.build_items(cursor_info)
  local config = require('rails-fixture-complete')._config
  local fixtures = require('rails-fixture-complete.fixtures')

  local line = cursor_info.line_text
  local col = cursor_info.cursor_col
  local before = line:sub(1, col)

  -- Check for name completion: type_name(:partial_name
  if config.sources.names then
    local type_name, partial = before:match('([%w_]+)%(:([%w_]*)$')
    if type_name and fixtures.valid_type(type_name) then
      local names = fixtures.get_names(type_name)
      if #names > 0 then
        local colon_char = #before - #partial - 1

        local items = {}
        for _, name in ipairs(names) do
          table.insert(items, {
            filterText = ':' .. name,
            label = ':' .. name,
            documentation = fixtures.get_documentation(type_name, name),
            textEdit = {
              newText = ':' .. name,
              range = {
                start = {
                  line = cursor_info.line_number,
                  character = colon_char,
                },
                ['end'] = {
                  line = cursor_info.line_number,
                  character = col,
                },
              },
            },
          })
        end

        return { items = items, is_name_completion = true }
      end
    end
  end

  -- Don't return type completions when inside a valid fixture type call (e.g., `users(` or `users(:bob`)
  -- This prevents stale type items from appearing alongside name items in the completion menu
  local enclosing_type = before:match('([%w_]+)%([^)]*$')
  if enclosing_type and fixtures.valid_type(enclosing_type) then
    return nil
  end

  -- Type completions
  if config.sources.types then
    local types = fixtures.get_types()
    if #types > 0 then
      local items = {}
      for _, type_name in ipairs(types) do
        table.insert(items, {
          label = type_name,
          insertText = type_name .. '(',
        })
      end

      return { items = items, is_name_completion = false }
    end
  end

  return nil
end

return M
