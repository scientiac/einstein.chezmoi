vim.pack.add({ { src = "https://github.com/chomosuke/typst-preview.nvim" } })

local ok, typst_preview = pcall(require, "typst-preview")
if not ok then return end

typst_preview.setup({
  formatterMode = "typstyle",
  open_cmd = 'previewfox %s'
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = function(args)
    if vim.fn.expand("%:t") == "main.typ" then
      vim.schedule(function()
        vim.cmd("TypstPreview")
      end)
    end
  end,
})

local map = require("mappings").map
map("n", "<leader>tp", "<cmd>TypstPreviewToggle<cr>", "Toggle Typst Preview")
