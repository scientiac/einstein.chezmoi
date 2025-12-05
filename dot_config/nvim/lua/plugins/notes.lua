return {
  "zk-org/zk-nvim",
  ft = "markdown",
  config = function()
    require("zk").setup({
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

    -- Markdown-specific keybindings in zk notebooks
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        -- Check if we're in a zk notebook
        if require("zk.util").notebook_root(vim.fn.expand('%:p')) ~= nil then
          local function map(mode, lhs, rhs, map_opts)
            map_opts = map_opts or {}
            map_opts.noremap = true
            map_opts.silent = false
            map_opts.buffer = true
            vim.keymap.set(mode, lhs, rhs, map_opts)
          end
          
          -- Open link under cursor (go to definition)
          map("n", "<CR>", vim.lsp.buf.definition, { desc = "Open link under cursor" })
          
          -- Create a new note in the same directory as current buffer
          map("n", "<leader>zn", function()
            vim.cmd("ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }")
          end, { desc = "New note in current directory" })
          
          -- Show backlinks (notes linking to current buffer)
          map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", { desc = "Show backlinks" })
          
          -- Show outbound links (notes linked by current buffer)
          map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", { desc = "Show links" })
          
          -- Insert link at cursor
          map("n", "<leader>zk", "<Cmd>ZkInsertLink<CR>", { desc = "Add Link" })
          
          -- Search for notes (excluding journals)
          map("n", "<leader>zs", "<Cmd>ZkNotes { sort = { 'modified' }, excludeHrefs = { 'journal' } }<CR>", { desc = "Search notes" })
          
          -- Search for journals only
          map("n", "<leader>zj", "<Cmd>ZkNotes { hrefs = { 'journal' }, sort = { 'modified' } }<CR>", { desc = "Search journals" })

          -- Create note from visual selection (title)
          map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", { desc = "New note from title selection" })
          
          -- Create note from visual selection (content)
          map("v", "<leader>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", { desc = "New note from content selection" })
          
          -- Insert link around visual selection
          map("v", "<leader>zk", ":'<,'>ZkInsertLinkAtSelection<CR>", { desc = "Link at selection" })
          
          -- Code actions for visual selection
          map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.code_action()<CR>", { desc = "Code actions" })
        end
      end,
    })
  end,
}
