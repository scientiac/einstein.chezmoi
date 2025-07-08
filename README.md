# einstein.chezmoi

My dotfiles for Arch Linux managed by [chezmoi](https://www.chezmoi.io/).

I am currently on gnome with the following extensions:
```

gnome-shell-extension-blur-my-shell
gnome-shell-extension-caffeine
gnome-shell-extension-clipboard-indicator
gnome-shell-extension-just-perfection-desktop
gnome-shell-extension-unite
gnome-shell-extension-appindicator

```

## Packages
`paru` as AUR helper.
`nix` for dev environments.

### Main
```

  zsh eza less mpv ghostty neovim git chezmoi ttf-fantasque-nerd webtorrent-cli tuned morewaita-icon-theme-git udisks2-btrfs wl-clipboard bluez bluez-utils adw-gtk-theme rustup

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

refine newsflash foliate valent signal-desktop keyguard steam inkscape

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

niri-git clipse swayosd mako brightnessctl rofi-wayland swww-git way-edges-git bemoji swaylock-effects-git swayidle xwayland-satellite-git

```

### swayidle
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


### services to Enable
```zsh

sudo systemctl enable --now bluetooth.service

```

### Removed
```zsh

gnome-tweaks gnome-music totem gnome-connections simple-scan gnome-tour

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
