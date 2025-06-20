# einstein.chezmoi

My dotfiles for Arch Linux managed by `chezmoi`.

I am currently on gnome with the following extensions:
```

gnome-shell-extension-blur-my-shell
gnome-shell-extension-caffeine
gnome-shell-extension-clipboard-indicator
gnome-shell-extension-just-perfection-desktop
gnome-shell-extension-unite

```

## Packages
`paru` as AUR helper.
`determinate-nix` for dev environments.

### Main
```

zsh ghostty keyguard steam neovim neovide git chezmoi inksape ttf-fantasque-nerd webtorrent-cli

```

### Neovim
```

texlive-full sioyek imagemagick tinymist typst qt5-wayland harper

```

### zsh
```

starship zoxide fzf fd bat ripgrep tree dust git-delta lazygit
zsh-completions zsh-history-substring-search zsh-you-should-use zsh-autosuggestions
zsh-fast-syntax-highlighting thefuck direnv fastfetch

```

### applications
```

refine newsflash foliate valent signal-desktop-beta-bin

```


### bash
```

gum bc

```

### qutebrowser
```

qutebrowser pdfjs python-adblock qt6-wayland

```

### fonts
```

ttf-devanagarifonts lohit-fonts ttf-indic-otf noto-fonts-cjk ttf-roboto ttf-ms-win11-auto ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common noto-fonts noto-fonts-emoji

```

## Niri
```

niri clipse swayosd mako brightnessctl wofi swww-git way-edges bemoji swaylock-effects swayidle xwayland-satellite-git

```

### systemd
Reload systemd and enable the `swayidle` service:
```zsh

systemctl --user daemon-reload
systemctl --user add-wants niri.service swayidle.service

```

### Local Bin Path
```zsh

mkdir -p ~/.config/environment.d
echo 'PATH=${HOME}/.local/bin:${PATH}' > ~/.config/environment.d/01-local-bin.conf

```
