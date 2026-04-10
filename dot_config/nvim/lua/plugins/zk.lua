vim.pack.add({ { src = "https://github.com/zk-org/zk-nvim" } })
local ok, zk = pcall(require, "zk")
if not ok then return end

zk.setup({
  picker = "select",
  lsp = {
    config = {
      name = "zk",
      cmd = { "zk", "lsp" },
      filetypes = { "markdown" },
    },
    auto_attach = {
      enabled = true,
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    local is_notebook = require("zk.util").notebook_root(vim.fn.expand('%:p')) ~= nil
    if not is_notebook then return end

    local map = require("mappings").map

    -- Open link under cursor
    map("n", "<CR>", vim.lsp.buf.definition, "Open link under cursor", { buffer = true })

    -- Create a new note
    map("n", "<leader>zn", function()
      vim.cmd("ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }")
    end, "New note", { buffer = true })

    -- Links & Backlinks
    map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", "Show backlinks", { buffer = true })
    map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", "Show links", { buffer = true })
    map("n", "<leader>zk", "<Cmd>ZkInsertLink<CR>", "Add Link", { buffer = true })
    map("n", "<leader>zs", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", "Search notes", { buffer = true })

    -- Visual Mode mappings
    map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", "New note from title", { buffer = true })
    map("v", "<leader>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", "New note from content", { buffer = true })
    map("v", "<leader>zk", ":'<,'>ZkInsertLinkAtSelection<CR>", "Link at selection", { buffer = true })
    map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.code_action()<CR>", "Code actions", { buffer = true })
  end,
})
