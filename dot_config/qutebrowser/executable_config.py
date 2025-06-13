# load config done via GUI
config.load_autoconfig(False)
config.source('themes/black.py')

# store and accept all cookies
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)

# toggle bars
config.bind(' t', 'config-cycle tabs.show always never')
config.bind(' s', 'config-cycle statusbar.show always in-mode')
config.bind(' mo', 'spawn --detach mpv --ytdl-raw-options=cookies=~/.config/qutebrowser/cookies.txt --force-window=immediate --ytdl-format="bestvideo[height<=720]+bestaudio/best[height<=720]" {url}')
config.bind(' mm', 'hint links spawn --detach mpv --ytdl-raw-options=cookies=~/.config/qutebrowser/cookies.txt --force-window=immediate --ytdl-format="bestvideo[height<=720]+bestaudio/best[height<=720]" {hint-url}')

# notificaitons
c.content.notifications.enabled = False

# clipboard
c.content.javascript.clipboard = 'access'

# darkmode
c.colors.webpage.preferred_color_scheme = "dark"

# faster vim like quitting
c.aliases = {'q': 'quit', 'w': 'session-save', 'wq': 'quit --save'}

# Show tabs and statusbar only when changing.
c.tabs.show_switching_delay = 1000
c.tabs.position = 'left'
c.tabs.width = '20%'

# UI elements
c.scrolling.bar = 'never'
c.statusbar.show = 'never'
c.tabs.show = 'never'

# padding to make UI less congested
c.statusbar.padding = {'top': 8, 'bottom': 8, 'left': 4, 'right': 4}
c.tabs.padding = {'top': 8, 'bottom': 8, 'left': 4, 'right': 4}

# font configuration
c.fonts.default_family = ['FantasqueSansM Nerd Font']
c.fonts.default_size = '11pt'
c.fonts.web.family.fixed = 'FantasqueSansM Nerd Font'
c.fonts.web.family.sans_serif = 'FantasqueSansM Nerd Font'
c.fonts.web.family.serif = 'FantasqueSansM Nerd Font'
c.fonts.web.family.standard = 'FantasqueSansM Nerd Font'

# insert mode 
c.input.insert_mode.auto_leave = True
c.input.insert_mode.auto_load = True

# ublock adblock
c.content.blocking.method = 'adblock'
c.content.blocking.enabled = True

c.content.blocking.adblock.lists = [
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2025.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-general.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-mobile.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/lan-block.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/ubo-link-shorteners.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/ubol-filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
]

