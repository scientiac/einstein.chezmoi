return {
  "ellisonleao/gruvbox.nvim",
  lazy = true,
  priority = 1000,
  name = "gruvbox",
  init = function()
    vim.cmd.colorscheme "gruvbox"
  end,
  opts = {
    terminal_colors = true,
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = true,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true,
    contrast = "", -- can be "hard", "soft" or empty string
    palette_overrides = {},
    overrides = {
      StatusLine = { bg = "NONE" },
      WinBar = { bg = "NONE" },
      WinBarNC = { bg = "NONE" },
    },
    dim_inactive = false,
    transparent_mode = not vim.g.neovide,
  },
}
