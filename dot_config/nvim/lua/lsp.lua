local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

capabilities.textDocument.formatting = {
  dynamicRegistration = false,
}

capabilities.textDocument.semanticTokens.augmentsSyntaxTokens = false

capabilities.textDocument.completion.completionItem = {
  contextSupport = true,
  snippetSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
  labelDetailsSupport = true,
  documentationFormat = { "markdown", "plaintext" },
}

-- send actions with hover request
capabilities.experimental = {
  hoverActions = true,
  hoverRange = true,
  serverStatusNotification = true,
  -- snippetTextEdit = true, -- not supported yet
  codeActionGroup = true,
  ssr = true,
  commands = {
    "rust-analyzer.runSingle",
    "rust-analyzer.debugSingle",
    "rust-analyzer.showReferences",
    "rust-analyzer.gotoLocation",
    "editor.action.triggerParameterHints",
  },
}

require('mappings').lsp()

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.vsplit(vim.lsp.log.get_filename())
end, {
  desc = "Get all the lsp logs",
})-- Remove ltex-ls-plus and add harper_ls
vim.lsp.config["harper_ls"] = {
    cmd = { "harper-ls", "--stdio" },
    filetypes = { "typst", "tex", "markdown", "text" },
    settings = {
        ["harper-ls"] = {
            userDictPath = "",
            fileDictPath = "",
            linters = {
                SpellCheck = true,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = true,
                UnclosedQuotes = true,
                WrongQuotes = true,     -- Enable for proper British quotes
                LongSentences = true,
                RepeatedWords = true,
                Spaces = true,
                Matcher = true,
                CorrectNumberSuffix = true
            },
            codeActions = {
                ForceStable = false
            },
            markdown = {
                IgnoreLinkTitle = false
            },
            diagnosticSeverity = "information",  -- More visible than "hint"
            isolateEnglish = false,
            dialect = "British",                 -- Set to British English
            maxFileLength = 120000
        }
    }
}

-- Enable LSP servers (replaced ltex-ls-plus with harper_ls)
vim.lsp.enable({ 'lua_ls', 'nixd', 'nil_ls', 'tinymist', 'harper_ls' })

vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd("silent checkhealth vim.lsp")
end, {
  desc = "Get all the information about all LSP attached",
})

vim.lsp.config.lua_ls = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".git", vim.uv.cwd() },
  settings = {
    Lua = {
      telemetry = {
        enable = false,
      },
    },
  },
}

vim.lsp.config.nixd = {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
}

vim.lsp.config.nil_ls = {
  cmd = { 'nil' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
}

vim.lsp.config["tinymist"] = {
    cmd = { "tinymist" },
    filetypes = { "typst" },
    settings = {
        formatterMode = "typstyle"
    },
    on_attach = function(client, bufnr)
        -- Pin current file as main
        vim.keymap.set("n", "<leader>tp", function()
            client:request("workspace/executeCommand", {
                command = "tinymist.pinMain",
                arguments = { vim.api.nvim_buf_get_name(0) },
            })
        end, { desc = "Tinymist pin main", buffer = bufnr, noremap = true })
        -- Unpin current main file
        vim.keymap.set("n", "<leader>tu", function()
            client:request("workspace/executeCommand", {
                command = "tinymist.pinMain",
                arguments = { vim.NIL },
            })
        end, { desc = "Tinymist unpin main", buffer = bufnr, noremap = true })
    end
}

vim.lsp.config["harper_ls"] = {
    cmd = { "harper-ls", "--stdio" },
    filetypes = { "typst", "tex", "markdown", "text" },
    settings = {
        ["harper-ls"] = {
            linters = {
                SpellCheck = true,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = true,
                UnclosedQuotes = true,
                WrongQuotes = true,
                LongSentences = true,
                RepeatedWords = true,
                Spaces = false,
                Matcher = true,
                CorrectNumberSuffix = true
            },
            codeActions = {
                ForceStable = false
            },
            markdown = {
                IgnoreLinkTitle = false
            },
            diagnosticSeverity = "information",
            isolateEnglish = false,
            dialect = "British",
            maxFileLength = 120000
        }
    }
}

vim.lsp.config.clangd = {
  cmd = { 
    "clangd", 
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
    "--query-driver=/home/scientiac/.espressif/tools/riscv32-esp-elf/**"
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  root_markers = { 
    ".clangd", 
    ".clang-tidy", 
    ".clang-format", 
    "compile_commands.json", 
    "compile_flags.txt", 
    "configure.ac", 
    ".git" 
  },
  settings = {
    clangd = {
      InlayHints = {
        Designators = true,
        Enabled = true,
        ParameterNames = true,
        DeducedTypes = true,
      },
      fallbackFlags = { "-std=c++17" },
    },
  },
}

vim.lsp.enable({ 'lua_ls', 'nixd', 'nil_ls', 'tinymist', 'harper_ls', 'clangd' })
