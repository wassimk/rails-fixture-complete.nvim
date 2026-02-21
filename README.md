# rails-fixture-complete.nvim

Autocompletion for Rails test fixtures. Completes fixture type names (`users`, `posts`) and individual fixture names (`:bob`, `:alice`) with YAML documentation previews.

Works natively with both [blink.cmp](https://github.com/Saghen/blink.cmp) and [nvim-cmp](https://github.com/hrsh7th/nvim-cmp).

## 📋 Requirements

- **Neovim 0.10+**
- [blink.cmp](https://github.com/Saghen/blink.cmp) or [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- Fixture files in `test/fixtures/` or `spec/fixtures/` (standard Rails locations)
- Ruby test files in `test/` or `spec/` directories

## 🛠️ Installation

### blink.cmp

```lua
-- lazy.nvim
{
  'saghen/blink.cmp',
  dependencies = {
    'wassimk/rails-fixture-complete.nvim',
  },
  opts = {
    sources = {
      default = { 'rails_fixture_complete' },
      providers = {
        rails_fixture_complete = {
          name = 'rails_fixture_complete',
          module = 'rails-fixture-complete.blink',
        },
      },
    },
  },
}
```

### nvim-cmp

The source auto-registers when nvim-cmp is detected. Just add it to your sources:

```lua
-- lazy.nvim
{
  'hrsh7th/nvim-cmp',
  dependencies = {
    'wassimk/rails-fixture-complete.nvim',
  },
  opts = {
    sources = {
      { name = 'rails_fixture_complete' },
    },
  },
}
```

## 💻 How It Works

The plugin provides a single unified completion source that adapts based on cursor context:

- **Type completions** appear when typing normally in a test file, suggesting fixture type names derived from `.yml`/`.yaml` filenames in `test/fixtures` or `spec/fixtures`. Selecting a type inserts `type_name(`.
- **Name completions** appear after typing `fixture_type(:`, suggesting individual fixture names defined in the corresponding YAML file. Each suggestion includes a documentation preview of the fixture's attributes.

## 🔧 Configuration

Both sources are enabled by default. Call `setup()` to customize, or pass options through the blink.cmp provider config:

```lua
-- Direct setup (optional, only needed to change defaults)
require('rails-fixture-complete').setup({
  sources = {
    types = true,   -- complete fixture type names (users, posts, etc.)
    names = true,   -- complete fixture names (:bob, :alice, etc.)
  },
})

-- Or via blink.cmp provider opts
providers = {
  rails_fixture_complete = {
    name = 'rails_fixture_complete',
    module = 'rails-fixture-complete.blink',
    opts = {
      sources = { types = false },  -- names only
    },
  },
}
```

## 🔨 Development

Run tests and lint:

```shell
make test
make lint
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```

This activates a pre-commit hook that auto-generates `doc/rails-fixture-complete.nvim.txt` from `README.md` whenever the README is staged. Requires [pandoc](https://pandoc.org/installing.html).
