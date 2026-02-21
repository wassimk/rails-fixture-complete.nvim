--- @class rails-fixture-complete.BlinkSource : blink.cmp.Source
local source = {}

--- @param opts table
--- @param _config blink.cmp.SourceProviderConfig
function source.new(opts, _config)
  local self = setmetatable({}, { __index = source })

  local rfc = require('rails-fixture-complete')
  rfc.setup(opts)

  return self
end

function source:enabled()
  return require('rails-fixture-complete').is_available()
end

function source:get_trigger_characters()
  return { ':' }
end

function source:get_completions(context, callback)
  local result = require('rails-fixture-complete.items').build_items({
    line_text = context.line,
    line_number = context.cursor[1] - 1,
    cursor_col = context.cursor[2],
  })

  if result then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = result.items })
  else
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end

  return function() end
end

return source
