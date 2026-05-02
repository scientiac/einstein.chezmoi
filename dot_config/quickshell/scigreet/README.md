# SciGreet

Minimal `greetd` greeter using `quickshell` + `niri`. Lockscreen-style ring indicator UI with blurred wallpaper.

## Preview (Development)

Test the UI without `greetd`:

```bash
cd ~/.config/quickshell/scigreet
qs -p test.qml
```

Hover over the top right corner to find the force quit option.

## Setup on Arch Linux

### 1. Install Dependencies

```bash
sudo pacman -S greetd niri quickshell
```

Make sure `niri` and `quickshell` (or `qs`) are in PATH.

### 2. Create Greeter User

Skip if `greetd` already created one:

```bash
sudo groupadd -r greeter 2>/dev/null || true
sudo useradd -r -g greeter -d /var/lib/greeter -s /bin/bash -c "Greeter" greeter 2>/dev/null || true
sudo mkdir -p /var/lib/greeter
sudo chown greeter:greeter /var/lib/greeter
```

### 3. Deploy `scigreet`

```bash
sudo mkdir -p /etc/xdg/quickshell/scigreet
cd ~/.config/quickshell/
sudo cp -r scigreet/* /etc/xdg/quickshell/scigreet/
sudo chown -R greeter:greeter /etc/xdg/quickshell/scigreet
```

### 4. Create Greeter Launch Scripts

We separate the QML runner from the Niri launcher to avoid parsing errors with console escape codes in the Niri config.

```bash
# 2. The Niri Launch Script
sudo tee /usr/local/bin/scigreet <<'EOF'
#!/bin/bash
set -e

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=gbm
export RUST_LOG=error
export NIRI_LOG=error

# Suppress kernel messages on greeter console
dmesg -n 1 2>/dev/null || true

TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" <<NIRI_EOF
hotkey-overlay {
    skip-at-startup
}

debug {
    keep-max-bpc-unchanged
}

gestures {
    hot-corners {
        off
    }
}

input {
    touchpad {
        tap
    }
}

layout {
    background-color "#000000"
}

spawn-at-startup "sh" "-c" "qs -p /etc/xdg/quickshell/scigreet/shell.qml; niri msg action quit --skip-confirmation"
NIRI_EOF

exec niri -c "$TEMP_CONFIG"
EOF

sudo chmod +x /usr/local/bin/scigreet-session /usr/local/bin/scigreet
```

### 5. Configure greetd

```bash
sudo tee /etc/greetd/config.toml <<'EOF'
[terminal]
vt = "next"

[default_session]
user = "greeter"
command = "/usr/local/bin/scigreet"
EOF
```


### 6. Disable GDM and Enable greetd

```bash
# Disable GDM
sudo systemctl disable gdm

# Enable greetd
sudo systemctl enable greetd
```

### 7. Verify Before Rebooting

```bash
# Check greetd config
cat /etc/greetd/config.toml

# Check scigreet files exist
ls -la /etc/xdg/quickshell/scigreet/

# Check launch script
cat /usr/local/bin/scigreet

# Check niri and quickshell are available
which niri qs
```

### 8. Reboot

```bash
sudo reboot
```

## Upgrading

After modifying scigreet source files, re-deploy:

```bash
cd ~/.config/quickshell/
sudo cp -r scigreet/* /etc/xdg/quickshell/scigreet/
sudo chown -R greeter:greeter /etc/xdg/quickshell/scigreet
```

then `reboot`.

## Options

Hover around the bottom corners to see options for login.
