local helpers = require('helpers')
local items = require('rails-fixture-complete.items')
local rfc = require('rails-fixture-complete')

describe('items', function()
  before_each(function()
    helpers.setup_mocks()
    rfc.setup()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  describe('type completions', function()
    it('returns type items when not in name context', function()
      local result = items.build_items({
        line_text = '    use',
        line_number = 5,
        cursor_col = 7,
      })

      assert.is_not_nil(result)
      assert.is_false(result.is_name_completion)
      assert.equals(2, #result.items)
    end)

    it('includes ( in insertText for type items', function()
      local result = items.build_items({
        line_text = '    use',
        line_number = 0,
        cursor_col = 7,
      })

      local found = false
      for _, item in ipairs(result.items) do
        if item.label == 'users' then
          assert.equals('users(', item.insertText)
          found = true
        end
      end
      assert.is_true(found)
    end)

    it('returns nil when types disabled and not in name context', function()
      rfc.setup({ sources = { types = false } })

      local result = items.build_items({
        line_text = '    use',
        line_number = 0,
        cursor_col = 7,
      })

      assert.is_nil(result)
    end)

    it('returns nil when no fixture files exist', function()
      helpers.fixture_files = {}
      require('rails-fixture-complete.fixtures')._reset_cache()

      local result = items.build_items({
        line_text = '    use',
        line_number = 0,
        cursor_col = 7,
      })

      assert.is_nil(result)
    end)
  end)

  describe('name completions', function()
    it('returns name items when cursor is after type(:', function()
      local result = items.build_items({
        line_text = '    users(:',
        line_number = 3,
        cursor_col = 11,
      })

      assert.is_not_nil(result)
      assert.is_true(result.is_name_completion)
      assert.equals(2, #result.items)
    end)

    it('returns name items with partial input', function()
      local result = items.build_items({
        line_text = '    users(:bo',
        line_number = 3,
        cursor_col = 13,
      })

      assert.is_not_nil(result)
      assert.is_true(result.is_name_completion)
    end)

    it('has correct textEdit range for name items', function()
      local result = items.build_items({
        line_text = '    users(:bo',
        line_number = 5,
        cursor_col = 13,
      })

      local item = result.items[1]
      assert.equals(5, item.textEdit.range.start.line)
      assert.equals(10, item.textEdit.range.start.character)
      assert.equals(5, item.textEdit.range['end'].line)
      assert.equals(13, item.textEdit.range['end'].character)
    end)

    it('has correct textEdit range at colon with no partial input', function()
      local result = items.build_items({
        line_text = '    users(:',
        line_number = 2,
        cursor_col = 11,
      })

      local item = result.items[1]
      assert.equals(2, item.textEdit.range.start.line)
      assert.equals(10, item.textEdit.range.start.character)
      assert.equals(2, item.textEdit.range['end'].line)
      assert.equals(11, item.textEdit.range['end'].character)
    end)

    it('includes documentation for name items', function()
      local result = items.build_items({
        line_text = '    users(:',
        line_number = 0,
        cursor_col = 11,
      })

      local found_bob = false
      for _, item in ipairs(result.items) do
        if item.label == ':bob' then
          assert.truthy(item.documentation:find('name: Bob Smith'))
          found_bob = true
        end
      end
      assert.is_true(found_bob)
    end)

    it('falls through to type completions for invalid fixture type', function()
      local result = items.build_items({
        line_text = '    nonexistent(:',
        line_number = 0,
        cursor_col = 17,
      })

      assert.is_not_nil(result)
      assert.is_false(result.is_name_completion)
    end)

    it('returns nil inside valid fixture type call when names disabled', function()
      rfc.setup({ sources = { names = false } })

      local result = items.build_items({
        line_text = '    users(:',
        line_number = 0,
        cursor_col = 11,
      })

      assert.is_nil(result)
    end)

    it('suppresses type completions inside fixture type parens without colon', function()
      local result = items.build_items({
        line_text = '    users(',
        line_number = 0,
        cursor_col = 10,
      })

      assert.is_nil(result)
    end)

    it('does not suppress type completions inside non-fixture function call', function()
      local result = items.build_items({
        line_text = '    assert_equal(use',
        line_number = 0,
        cursor_col = 20,
      })

      assert.is_not_nil(result)
      assert.is_false(result.is_name_completion)
    end)

    it('returns nil when both sources disabled', function()
      rfc.setup({ sources = { types = false, names = false } })

      local result = items.build_items({
        line_text = '    users(:',
        line_number = 0,
        cursor_col = 11,
      })

      assert.is_nil(result)
    end)
  end)
end)
