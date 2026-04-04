# einstein.niri.chezmoi

My dotfiles for Arch Linux managed by [chezmoi](https://www.chezmoi.io/).

## Packages
`paru` as AUR helper.
`nix` for dev environments.

### Main
```

  zsh eza less mpv ghostty kitty neovim git chezmoi webtorrent-cli tuned morewaita-icon-theme-git wl-clipboard adw-gtk-theme

```

### Neovim
```

typst harper jq

```

### mpv
```

mpv-modernz-git  mpv-thumbfast-git

```

### zsh
```

zoxide fzf fd bat ripgrep tree dust git-delta lazygit zsh-completions zsh-history-substring-search zsh-you-should-use zsh-autosuggestions zsh-fast-syntax-highlighting direnv fastfetch zsh-pure-prompt

```

### applications
```

newsflash readest signal-desktop

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

noto-fonts-cjk ttf-roboto ttf-nerd-fonts-symbols ttf-fantasque-nerd ttf-nerd-fonts-symbols-common noto-fonts noto-fonts-emoji ttf-times-new-roman

```

## Niri
```

swayosd brightnessctl

```

## Nix
### Install packages
```

nix zsh-nix-shell nix-zsh-completions

```

### Add user to Nix Group
```

sudo groupadd nixbld
sudo usermod -a -G nixbld scientiac
sudo groupadd nix-users
sudo usermod -a -G nix-users scientiac

```

### Start the Nix Daemon
```

sudo systemctl enable --now nix-daemon

```

## Launcher
```
walker elephant-archlinuxpkgs-bin elephant-bluetooth-bin elephant-calc-bin elephant-clipboard-bin elephant-desktopapplications-bin elephant-files-bin elephant-menus-bin elephant-providerlist-bin elephant-runner-bin elephant-symbols-bin elephant-unicode-bin elephant-websearch-bin
```
