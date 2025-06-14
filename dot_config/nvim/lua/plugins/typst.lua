return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = '1.*',
  opts = {
    formatterMode = "typstyle",
    invert_colors = '{"rest": "auto","image": "never"}',
    port = 31415,
    open_cmd = 'qutebrowser %s'
  },
  config = function(_, opts)
    require('typst-preview').setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "typst",
      callback = function()
        vim.defer_fn(function()
          vim.cmd("TypstPreview")
        end, 10)
      end,
    })
  end,
}
