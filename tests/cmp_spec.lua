local helpers = require('helpers')

describe('cmp source', function()
  before_each(function()
    helpers.setup_mocks()
    require('rails-fixture-complete').setup()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  it('get_trigger_characters returns :', function()
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()
    assert.same({ ':' }, source:get_trigger_characters())
  end)

  it('is_available returns true for ruby test files', function()
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()
    assert.is_true(source:is_available())
  end)

  it('is_available returns false for non-ruby files', function()
    vim.bo.filetype = 'javascript'
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()
    assert.is_false(source:is_available())
  end)

  it('complete calls callback with type items', function()
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()

    local result
    source:complete({
      context = {
        cursor_before_line = '    use',
        cursor_after_line = '',
        cursor = { row = 4, col = 8 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_not_nil(result.items)
    assert.equals(2, #result.items)
    assert.is_true(result.isIncomplete)
  end)

  it('complete calls callback with name items on trigger', function()
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()

    local result
    source:complete({
      context = {
        cursor_before_line = '    users(:',
        cursor_after_line = ')',
        cursor = { row = 4, col = 12 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_not_nil(result.items)
    assert.equals(2, #result.items)
    assert.equals(':bob', result.items[1].label)
  end)

  it('complete calls callback with isIncomplete on no match', function()
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()

    helpers.fixture_files = {}
    require('rails-fixture-complete.fixtures')._reset_cache()

    local result
    source:complete({
      context = {
        cursor_before_line = '    ',
        cursor_after_line = '',
        cursor = { row = 1, col = 5 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_nil(result.items)
    assert.is_true(result.isIncomplete)
  end)

  it('maps cmp row/col (both 1-indexed) to 0-indexed', function()
    local cmp_source = require('rails-fixture-complete.cmp')
    local source = cmp_source.new()

    local result
    source:complete({
      context = {
        cursor_before_line = '    users(:',
        cursor_after_line = ')',
        cursor = { row = 10, col = 12 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.equals(2, #result.items)
    local item = result.items[1]
    assert.equals(9, item.textEdit.range.start.line)
  end)
end)
