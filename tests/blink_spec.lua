local helpers = require('helpers')

describe('blink source', function()
  before_each(function()
    helpers.setup_mocks()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  it('get_trigger_characters returns :', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})
    assert.same({ ':' }, source:get_trigger_characters())
  end)

  it('new() initializes config from opts', function()
    local blink = require('rails-fixture-complete.blink')
    blink.new({ sources = { types = false } }, {})

    local config = require('rails-fixture-complete')._config
    assert.is_false(config.sources.types)
    assert.is_true(config.sources.names)
  end)

  it('enabled returns true for ruby test files', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})
    assert.is_true(source:enabled())
  end)

  it('enabled returns false for non-test files', function()
    helpers.buf_path = '/project/app/models/user.rb'
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})
    assert.is_false(source:enabled())
  end)

  it('get_completions calls callback with type items', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})

    local result
    source:get_completions({
      line = '    use',
      cursor = { 4, 7 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_not_nil(result.items)
    assert.equals(2, #result.items)
  end)

  it('get_completions calls callback with name items on trigger', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})

    local result
    source:get_completions({
      line = '    users(:)',
      cursor = { 4, 11 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.equals(2, #result.items)
    assert.equals(':bob', result.items[1].label)
  end)

  it('get_completions calls callback with empty items on no match', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})

    helpers.fixture_files = {}
    require('rails-fixture-complete.fixtures')._reset_cache()

    local result
    source:get_completions({
      line = '    ',
      cursor = { 1, 4 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.same({}, result.items)
  end)

  it('maps blink row (1-indexed) to 0-indexed line_number', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})

    local result
    source:get_completions({
      line = '    users(:)',
      cursor = { 10, 11 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.equals(2, #result.items)
    local item = result.items[1]
    assert.equals(9, item.textEdit.range.start.line)
  end)

  it('returns a cancel function', function()
    local blink = require('rails-fixture-complete.blink')
    local source = blink.new({}, {})

    local cancel = source:get_completions({
      line = '    use',
      cursor = { 1, 7 },
    }, function() end)

    assert.equals('function', type(cancel))
  end)
end)
