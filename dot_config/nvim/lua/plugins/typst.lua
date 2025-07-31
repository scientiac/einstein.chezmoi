return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = '1.*',
  opts = {
    formatterMode = "typstyle",
    invert_colors = '{"rest": "auto","image": "never"}',
    open_cmd = 'qutebrowser %s'
  },
  config = function(_, opts)
    require('typst-preview').setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "typst",
      callback = function()
        local filename = vim.fn.expand("%:t")
        if filename == "main.typ" then
          vim.defer_fn(function()
            vim.cmd("TypstPreview")
            
            -- Auto-pin this main.typ
            local function try_pin_main()
              local clients = vim.lsp.get_clients({ name = "tinymist" })
              if #clients > 0 then
                local client = clients[1]
                if client.server_capabilities then
                  client:request("workspace/executeCommand", {
                    command = "tinymist.pinMain",
                    arguments = { vim.api.nvim_buf_get_name(0) },
                  })
                  print("Auto-pinned main.typ")
                  return true
                end
              end
              return false
            end
            
            -- Try immediately, then retry with delays if needed
            if not try_pin_main() then
              vim.defer_fn(function()
                if not try_pin_main() then
                  vim.defer_fn(try_pin_main, 1000) -- Try again after 1 second
                end
              end, 500) -- Try again after 500ms
            end
          end, 10)
        end
      end,
    })
  end,
}
