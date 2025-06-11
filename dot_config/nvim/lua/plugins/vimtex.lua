return {
    "lervag/vimtex",
    lazy = false,
    ft = { "tex", "latex" },
    init = function()
        vim.g.vimtex_view_method = "sioyek"
        vim.g.vimtex_quickfix_enabled = 1
        vim.g.vimtex_quickfix_open_on_warning = 0
        vim.g.vimtex_quickfix_ignore_filters = {
            "Underfull",
            "Overfull", 
            "specifier changed to",
            "Token not allowed in a PDF string",
        }
        
        vim.g.vimtex_compiler_progname = "nvr"
    end,
    config = function()
        -- Create autocommands after plugin loads
        local augroup = vim.api.nvim_create_augroup("VimTexConfig", { clear = true })
        
        -- Set filetype 
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
            group = augroup,
            pattern = "*.tex",
            callback = function()
                vim.bo.filetype = "tex"
            end,
        })
        
        -- Auto-compile on VimTeX initialization
        vim.api.nvim_create_autocmd("User", {
            group = augroup,
            pattern = "VimtexEventInitPost",
            callback = function()
                vim.fn["vimtex#compiler#compile"]()
            end,
        })
        
        -- Clean up on quit
        vim.api.nvim_create_autocmd("User", {
            group = augroup,
            pattern = "VimtexEventQuit",
            callback = function()
                vim.fn["vimtex#compiler#clean"](0)
            end,
        })
    end,
    keys = {
        { "<leader>xx", "<cmd>VimtexCompile<cr>", desc = "Start/stop compilation", ft = "tex" },
        { "<leader>xv", "<cmd>VimtexView<cr>", desc = "View PDF", ft = "tex" },
        { "<leader>xt", "<cmd>VimtexTocToggle<cr>", desc = "Toggle TOC", ft = "tex" },
        { "<leader>xc", "<cmd>VimtexClean<cr>", desc = "Clean auxiliary files", ft = "tex" },
        { "<leader>xe", "<cmd>VimtexErrors<cr>", desc = "Show errors", ft = "tex" },
        { "<leader>xg", "<cmd>VimtexStatus<cr>", desc = "Show status", ft = "tex" },
    },
}
