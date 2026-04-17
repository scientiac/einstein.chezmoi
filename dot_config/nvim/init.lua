if vim.loader then
  vim.loader.enable()
end

require("opts").initial()

require("plugins.lazydev")
require("plugins.mini")
require("plugins.blink")
require("plugins.snacks")
require("plugins.misc")
require("plugins.typst")

require("opts").final()
require("mappings").general()
require("mappings").misc()
require("lsp")
