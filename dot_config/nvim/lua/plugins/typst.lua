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
}
