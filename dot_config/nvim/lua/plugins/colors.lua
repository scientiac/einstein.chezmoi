vim.pack.add({
  { src = "https://github.com/rebelot/kanagawa.nvim" }
})

local ok, kanagawa = pcall(require, "kanagawa")
if not ok then return end

kanagawa.setup({
  compile = true,
  undercurl = true,
  commentStyle = { italic = true },
  keywordStyle = { italic = true },
  statementStyle = { bold = true },
  transparent = false,
  dimInactive = false,
  terminalColors = true,
  theme = "wave",
  background = {
    dark = "dragon",
    light = "lotus",
  },
  colors = {
    theme = {
      all = {
        ui = {
          bg_gutter = "none"
        }
      }
    }
  },
  overrides = function(colors)
    local theme = colors.theme
    return {
      NormalFloat = { bg = "none" },
      FloatBorder = { bg = "none" },
      FloatTitle = { bg = "none" },
      Cmdline = { bg = "none" },
      CmdlinePrompt = { bg = "none" },
      StatusLine = { bg = "none" },
      StatusLineNC = { bg = "none" },
      MsgArea = { bg = "none" },
      WinBar = { bg = "none" },
      WinBarNC = { bg = "none" },
      Pmenu = { bg = "none" },

      NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

      LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
      MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

      PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
      PmenuSbar = { bg = theme.ui.bg_m1 },
      PmenuThumb = { bg = theme.ui.bg_p2 },

      BlinkCmpMenuBorder = { fg = "none", bg = "none" },
      BlinkCmpDocBorder = { fg = "none", bg = "none" },
    }
  end,
})

vim.cmd.colorscheme("kanagawa")
