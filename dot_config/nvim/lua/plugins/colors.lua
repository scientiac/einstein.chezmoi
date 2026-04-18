vim.pack.add({
  { src = "https://github.com/rebelot/kanagawa.nvim" }
})

local ok, kanagawa = pcall(require, "kanagawa")
if not ok then return end

kanagawa.setup({
  compile = false,
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
})

vim.cmd.colorscheme("kanagawa")
