local has_cmp, cmp = pcall(require, 'cmp')
if has_cmp then
  local rfc = require('rails-fixture-complete')
  if not rfc._setup_called then
    rfc.setup()
  end

  cmp.register_source('rails_fixture_complete', require('rails-fixture-complete.cmp').new())
end
