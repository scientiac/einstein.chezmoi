return {
  "saghen/blink.cmp",
  version = '*',
  event = { "LspAttach" },
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = {
      preset = 'none',
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide' },
      ['<C-d>'] = { 'scroll_documentation_up' },
      ['<C-f>'] = { 'scroll_documentation_down' },
      ['<CR>'] = { 'accept', 'fallback' },
      ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
    },
    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        cmdline = {
          min_keyword_length = 2,
        },
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
      },
    },
    completion = {
      menu = {
        border = vim.g.border_style,
        scrolloff = 1,
        scrollbar = false,
      },
      documentation = {
        auto_show_delay_ms = 0,
        auto_show = true,
        window = {
          border = vim.g.border_style,
        },
      },
    },
  },
}
