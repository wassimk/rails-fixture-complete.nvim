local helpers = require('helpers')
local fixtures = require('rails-fixture-complete.fixtures')
local rfc = require('rails-fixture-complete')

describe('fixtures', function()
  before_each(function()
    helpers.setup_mocks()
    rfc.setup()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  describe('fixture_dirs', function()
    it('finds fixture directories by searching upward', function()
      local dirs = fixtures.fixture_dirs()
      assert.equals(1, #dirs)
      assert.equals('/project/test/fixtures', dirs[1])
    end)

    it('returns empty when no fixture dirs exist', function()
      helpers.directories = {}
      fixtures._reset_cache()

      local dirs = fixtures.fixture_dirs()
      assert.equals(0, #dirs)
    end)

    it('finds spec/fixtures when in a spec project', function()
      helpers.fs_find_result = { '/project/spec' }
      helpers.directories = { ['/project/spec/fixtures'] = true }
      fixtures._reset_cache()

      local dirs = fixtures.fixture_dirs()
      assert.equals(1, #dirs)
      assert.equals('/project/spec/fixtures', dirs[1])
    end)
  end)

  describe('get_types', function()
    it('extracts type names from fixture files', function()
      local types = fixtures.get_types()
      assert.is_true(vim.tbl_contains(types, 'users'))
      assert.is_true(vim.tbl_contains(types, 'posts'))
    end)

    it('converts nested paths to underscore names', function()
      helpers.fixture_files = {
        '/project/test/fixtures/admin/users.yml',
      }
      fixtures._reset_cache()

      local types = fixtures.get_types()
      assert.is_true(vim.tbl_contains(types, 'admin_users'))
    end)
  end)

  describe('valid_type', function()
    it('returns true for existing types', function()
      assert.is_true(fixtures.valid_type('users'))
    end)

    it('returns false for non-existing types', function()
      assert.is_false(fixtures.valid_type('comments'))
    end)

    it('returns false for nil', function()
      assert.is_false(fixtures.valid_type(nil))
    end)

    it('returns false for empty string', function()
      assert.is_false(fixtures.valid_type(''))
    end)
  end)

  describe('get_names', function()
    it('extracts fixture names from YAML file', function()
      local names = fixtures.get_names('users')
      assert.same({ 'bob', 'alice' }, names)
    end)

    it('returns empty table for invalid type', function()
      local names = fixtures.get_names('nonexistent')
      assert.same({}, names)
    end)

    it('matches names with numbers', function()
      helpers.file_contents = {
        ['/project/test/fixtures/users.yml'] = 'user_1:\n  name: User One\n\nuser_2:\n  name: User Two\n',
      }
      fixtures._reset_cache()

      local names = fixtures.get_names('users')
      assert.same({ 'user_1', 'user_2' }, names)
    end)
  end)

  describe('get_documentation', function()
    it('extracts YAML block for a fixture name', function()
      local doc = fixtures.get_documentation('users', 'bob')
      assert.truthy(doc:find('bob:'))
      assert.truthy(doc:find('name: Bob Smith'))
      assert.truthy(doc:find('email: bob@example.com'))
    end)

    it('does not include other fixtures in documentation', function()
      local doc = fixtures.get_documentation('users', 'bob')
      assert.falsy(doc:find('alice'))
    end)

    it('returns empty string for non-existing name', function()
      local doc = fixtures.get_documentation('users', 'charlie')
      assert.equals('', doc)
    end)

    it('returns empty string for non-existing type', function()
      local doc = fixtures.get_documentation('nonexistent', 'bob')
      assert.equals('', doc)
    end)

    it('detects indentation level from first attribute line', function()
      helpers.file_contents = {
        ['/project/test/fixtures/users.yml'] = 'bob:\n    name: Bob Smith\n    email: bob@test.com\nalice:\n    name: Alice\n',
      }
      fixtures._reset_cache()

      local doc = fixtures.get_documentation('users', 'bob')
      assert.truthy(doc:find('name: Bob Smith'))
      assert.truthy(doc:find('email: bob@test.com'))
      assert.falsy(doc:find('alice'))
    end)
  end)

  describe('yaml extension', function()
    it('supports .yaml extension', function()
      helpers.glob_results = {
        ['/project/test/fixtures/**/*.yml'] = {},
        ['/project/test/fixtures/**/*.yaml'] = {
          '/project/test/fixtures/tags.yaml',
        },
      }
      fixtures._reset_cache()

      local types = fixtures.get_types()
      assert.is_true(vim.tbl_contains(types, 'tags'))
    end)
  end)

  describe('caching', function()
    it('caches types after first call', function()
      local types1 = fixtures.get_types()
      helpers.fixture_files = {}
      local types2 = fixtures.get_types()
      assert.same(types1, types2)
    end)

    it('resets cache on _reset_cache()', function()
      fixtures.get_types()
      helpers.fixture_files = {}
      fixtures._reset_cache()
      local types = fixtures.get_types()
      assert.same({}, types)
    end)
  end)
end)
