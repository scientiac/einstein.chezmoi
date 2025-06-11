return {
    "3rd/image.nvim",
    build = false,
    event = "VeryLazy",
    enabled = not vim.g.neovide,
    opts = {
        backend = "kitty",
        processor = "magick_cli",
        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = true,
                download_remote_images = true,
                only_render_image_at_cursor = true,
                only_render_image_at_cursor_mode = "popup",
                floating_windows = true,
                filetypes = { "markdown", "vimwiki" },
            }
        },
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
    keys = {
        {
            "<leader>ti",
            function()
                local image = require("image")
                if image.is_enabled() then
                    image.disable()
                    vim.notify("Image rendering disabled", vim.log.levels.INFO)
                else
                    image.enable()
                    vim.notify("Image rendering enabled", vim.log.levels.INFO)
                end
            end,
            desc = "Toggle image rendering",
        },
    },
}
