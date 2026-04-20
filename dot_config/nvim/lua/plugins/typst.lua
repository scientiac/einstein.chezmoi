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


-- Smarana
vim.pack.add({ { src = "https://codeberg.org/scientiac/smarana.git" } })

local ok_sma, smarana = pcall(require, "smarana")
if ok_sma then
  smarana.setup({
    preview = true,
    default_type = "ask", -- "ask" | "fleeting" | "capture" | "atomic"
  })

  -- Normal mode maps
  map("n", "<leader>sn", ":SmaNew<cr>", "New smarana note")
  map("n", "<leader>ss", ":SmaNotes<cr>", "Search smarana notes")
  map("n", "<leader>sk", ":SmaInsertLink<cr>", "Insert smarana link")
  map("n", "<leader>sb", ":SmaBacklinks<cr>", "View backlinks")
  map("n", "<leader>sl", ":SmaForwardLinks<cr>", "View links")

  -- Direct type shortcuts (skip the type picker)
  map("n", "<leader>sf", ":SmaNewFleeting<cr>", "New fleeting note")
  map("n", "<leader>sc", ":SmaNewCapture<cr>", "New capture note")
  map("n", "<leader>sa", ":SmaNewAtomic<cr>", "New atomic note")

  -- Visual mode maps
  map("v", "<leader>st", smarana.new_from_title, "New note from title")
  map("v", "<leader>sc", smarana.new_from_content, "New note from content")
  map("v", "<leader>si", smarana.insert_link_at_selection, "Insert Link at selection")

end
