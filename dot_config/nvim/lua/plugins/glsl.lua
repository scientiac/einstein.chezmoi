return {
  "timtro/glslView-nvim",
  ft = "glsl",
  config = function()
    require("glslView").setup({
      viewer_path = "glslViewer",  -- install `glslViewer` first
      args = { "-l" },
    })

    -- Auto-start glslViewer when a GLSL file is opened
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "glsl",
      callback = function()
        vim.defer_fn(function()
          vim.cmd("GlslView")
        end, 10)
      end,
    })

    -- Auto-close glslViewer when Neovim exits
    vim.api.nvim_create_autocmd({ "VimLeave", "VimLeavePre" }, {
      callback = function()
        -- Kill all glslViewer processes
        vim.fn.system("pkill -f glslViewer")
      end,
    })
  end,
}
