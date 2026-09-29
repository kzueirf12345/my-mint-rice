# 🎀 Urodish Linux Mint Rice

Portable backup and documentation of my Linux Mint Cinnamon setup.

The goal of this repository is to reproduce the desktop on a fresh Linux Mint installation without backing up personal sessions, passwords, browser cookies, authentication tokens, or other credentials.

---

## System

- **OS:** Linux Mint 22.3 Zena
- **Desktop:** Cinnamon 6.6
- **Session:** X11
- **Shell:** Zsh
- **Terminal:** Kitty
- **Prompt:** Starship
- **Display setup:** Dual-monitor HiDPI

Current monitor layout:

| Output | Resolution | Role |
|---|---:|---|
| `HDMI-A-0` | 5120×2880 | Primary external display |
| `eDP` | 3408×2130 | Internal display |

> Display geometry, LightDM scaling and monitor names are machine-specific and should not be blindly restored on another machine.

---

# 🎨 Visual Style

The overall aesthetic is:

- Catppuccin Mocha
- Pink accent
- Dark navy / bluish-purple backgrounds
- Rounded UI
- Hello Kitty / kawaii elements
- Minimal desktop
- No heavy blur effects

Main palette:

| Element | Color |
|---|---|
| Background | `#1e1e2e` |
| Surface | `#313244` |
| Text | `#cdd6f4` |
| Pink | `#f5c2e7` |

---

# 🖥️ GTK / Cinnamon

## GTK Theme

Theme:

```text
Catppuccin-Pink-Dark-B
```

Source:

```text
Fausto-Korpsvart/Catppuccin-GTK-Theme
```

Original installation:

```bash
cd ~/Downloads/Catppuccin-GTK-Theme/themes

./install.sh \
  -a pink \
  -m dark \
  --tweaks border
```

Configuration:

- Accent: Pink
- Mode: Dark
- Border tweak: enabled
- Radius tweak: disabled

The radius tweak was intentionally avoided because it caused graphical corner artifacts on maximized/fullscreen windows in the dual-monitor setup.

Portable copy:

```text
themes/gtk/Catppuccin-Pink-Dark-B/
```

---

## Cinnamon Panel

A thin Cinnamon panel is placed at the top.

Main application menu:

```text
Cinnamenu@json
```

A custom pink line was added to:

```text
~/.themes/Catppuccin-Pink-Dark-B/cinnamon/cinnamon.css
```

CSS:

```css
.panel-top {
  box-shadow:
    inset 0 -2px 0 #f5c2e7,
    0 0 5px rgba(0, 0, 0, 0.5),
    0 0 16px rgba(0, 0, 0, 0.24);
}
```

A backup of the original CSS was also created.

Cinnamon configuration snapshot:

```text
configs/cinnamon/cinnamon.dconf
```

Enabled applets are documented in:

```text
configs/cinnamon/enabled-applets.txt
```

Current user applets include:

- `Cinnamenu@json`
- `CommandRunner@appdevsw`

Applet files:

```text
configs/cinnamon/applets/
```

---

# 🗂️ Icons

Main icon theme:

```text
Tela-circle-pink
```

Source:

```text
vinceliuice/Tela-circle-icon-theme
```

Portable copy:

```text
themes/icons/Tela-circle-pink/
```

---

# 🖱️ Cursor

Cursor theme:

```text
catppuccin-mocha-pink-cursors
```

Portable copy:

```text
themes/cursors/catppuccin-mocha-pink-cursors/
```

Current Cinnamon setting:

```bash
gsettings set org.cinnamon.desktop.interface \
  cursor-theme 'catppuccin-mocha-pink-cursors'
```

---

# 🌸 Wallpapers

Main desktop/login wallpaper:

```text
wallpapers/wallpaper-5k.png
```

Resolution:

```text
5120×2880
```

Telegram wallpaper:

```text
wallpapers/telegram-wallpaper.png
```

Wallpaper style:

- deep navy / bluish-purple background
- pastel pink details
- Hello Kitty-inspired character
- minimal composition
- kawaii aesthetic

---

# 🚀 Plank Reloaded

Plank Reloaded is used as the bottom dock.

Configuration:

- Position: bottom
- Alignment: center
- Icon size: approximately 48 px
- Zoom: approximately 130%
- Hide mode: disabled

Theme:

```text
Catppuccin-mocha
```

Custom pink border:

```ini
LineWidth=2
OuterStrokeColor=245;;194;;231;;255
```

Portable theme:

```text
configs/plank/Catppuccin-mocha/
```

Plank settings:

```text
configs/plank/plank.dconf
```

---

# 💻 Kitty

Terminal emulator:

```text
kitty
```

Configuration:

```text
configs/kitty/kitty.conf
```

Theme:

```text
Catppuccin Mocha
```

Theme file:

```text
configs/kitty/current-theme.conf
```

Important visual settings include:

```conf
window_padding_width 12
background_opacity 0.94

cursor #f5c2e7
cursor_text_color #1e1e2e

selection_background #f5c2e7
selection_foreground #1e1e2e
```

Clipboard shortcuts:

```conf
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
```

---

# 🔤 Font

Main terminal/editor font:

```text
JetBrainsMono Nerd Font
```

Kitty uses:

```text
JetBrainsMono Nerd Font Mono
```

Font size:

```text
11.5
```

The font was installed under the user's local font directory.

Installed font information is stored in:

```text
system/fonts/
```

The actual font files do not need to be stored in this repository.

When restoring the setup, install the current JetBrainsMono Nerd Font release from Nerd Fonts.

---

# 🐚 Zsh

Default shell:

```text
/usr/bin/zsh
```

Version used when this rice was created:

```text
Zsh 5.9
```

Configuration:

```text
configs/zsh/zshrc
```

Features:

- persistent history
- shared history
- duplicate history filtering
- case-insensitive completion
- Emacs-style keybindings
- Ctrl+Left / Ctrl+Right word navigation
- Home / End support
- history prefix search
- zsh-autosuggestions
- zsh-syntax-highlighting
- Starship prompt
- colored GNU utilities

Main plugins/packages:

```text
zsh-autosuggestions
zsh-syntax-highlighting
```

Colored CLI output is enabled for utilities such as:

```text
ls
grep
egrep
fgrep
diff
```

---

# ⭐ Starship

Starship is used as the shell prompt.

Configuration:

```text
configs/starship/starship.toml
```

Base preset:

```text
catppuccin-powerline
```

The prompt uses Nerd Font glyphs and a two-line layout.

Desired behavior:

```text
╭─ user  ~/full/path/to/current/directory  git ...
╰─ ❯ command
```

Directory paths should not be aggressively truncated.

The configuration was adjusted so long paths such as:

```text
~/Downloads/Catppuccin-GTK-Theme
```

are shown instead of:

```text
…/Catppuccin-GTK-Theme
```

---

# 📊 btop

System monitor:

```text
btop
```

Configuration:

```text
configs/btop/btop.conf
```

Theme:

```text
catppuccin_mocha
```

Theme file:

```text
configs/btop/themes/catppuccin_mocha.theme
```

---

# 🦊 Firefox

Firefox uses **FlexFox** for UI customization.

Source:

```text
yuuqilin/FlexFox
```

Portable customization:

```text
configs/firefox/chrome/
```

This contains:

```text
userChrome.css
userContent.css
```

Current layout:

- horizontal tabs
- normal top tab bar
- rounded UI
- Catppuccin styling
- rounded web content

Sidebery was tested and intentionally removed.

Tab management is done with:

```text
Simple Tab Groups
```

Firefox color theme:

```text
Catppuccin Mocha Pink
```

Private Firefox profile data is intentionally **not** backed up.

Do not commit:

```text
cookies
passwords
sessions
key4.db
storage
authentication tokens
browser history databases
```

---

# 📝 VS Code

VS Code is installed using the official Microsoft APT repository.

Configuration:

```text
configs/vscode/settings.json
configs/vscode/keybindings.json
configs/vscode/extensions.txt
```

Visual target:

- Catppuccin Mocha
- Pink accents
- Catppuccin icons
- JetBrainsMono Nerd Font

Editor font:

```text
JetBrainsMono Nerd Font Mono
```

Extensions can be restored with:

```bash
while read -r extension; do
    code --install-extension "$extension"
done < configs/vscode/extensions.txt
```

---

# 🎵 Spotify

Spotify is installed as the native APT package.

Customization stack:

```text
Spotify
↓
Spicetify CLI
↓
Spicetify Marketplace
↓
Catppuccin styling
```

Spicetify configuration:

```text
configs/spicetify/config-xpui.ini
```

Spicetify installation directory:

```text
~/.spicetify
```

Zsh PATH:

```bash
export PATH="$HOME/.spicetify:$PATH"
```

Spicetify initially could not modify:

```text
/usr/share/spotify/Apps/xpui.spa
```

Required permissions:

```bash
sudo chmod a+wr /usr/share/spotify
sudo chmod a+wr -R /usr/share/spotify/Apps
```

Then:

```bash
spicetify backup apply
```

Marketplace is enabled.

Desired Spotify palette:

```text
Background: #1e1e2e
Surface:    #313244
Text:       #cdd6f4
Pink:       #f5c2e7
```

---

# ✈️ Telegram

Telegram Desktop is installed through Flatpak.

Application ID:

```text
org.telegram.desktop
```

A Catppuccin Telegram theme is applied inside Telegram.

Telegram originally showed the wrong/tiny black cursor because the Flatpak sandbox could not see the user cursor theme.

Fix:

```bash
flatpak override --user \
  --filesystem="$HOME/.icons/catppuccin-mocha-pink-cursors:ro" \
  --env=XCURSOR_THEME=catppuccin-mocha-pink-cursors \
  org.telegram.desktop
```

Restart:

```bash
flatpak kill org.telegram.desktop
flatpak run org.telegram.desktop
```

Telegram sessions and `tdata` are intentionally **not** backed up.

---

# 🔐 LightDM / Slick Greeter

Display manager:

```text
LightDM
```

Greeter:

```text
Slick Greeter
```

Configuration backup:

```text
configs/lightdm/slick-greeter.conf
```

Current configuration:

```ini
[Greeter]
only-on-monitor=eDP
enable-hidpi=off
background=/usr/share/backgrounds/urodish/login-wallpaper.png
theme-name=Catppuccin-Pink-Dark-B
icon-theme-name=Tela-circle-pink
cursor-theme-name=catppuccin-mocha-pink-cursors
cursor-theme-size=24
draw-user-backgrounds=false
draw-grid=false
```

## HiDPI issue

This machine uses two high-resolution displays with different physical pixel densities.

Slick Greeter automatically detected HiDPI and enabled:

```text
2x scale ratio
```

This produced incorrect scaling on one of the monitors.

The following settings were therefore tested:

```ini
enable-hidpi=off
only-on-monitor=eDP
```

These settings are **machine-specific**.

Do not blindly restore them on another machine.

Monitor names such as:

```text
eDP
HDMI-A-0
```

can also differ between computers.

## Login wallpaper

The wallpaper must be readable before the user logs in.

System location:

```text
/usr/share/backgrounds/urodish/login-wallpaper.png
```

Installation:

```bash
sudo mkdir -p /usr/share/backgrounds/urodish

sudo cp wallpapers/wallpaper-5k.png \
  /usr/share/backgrounds/urodish/login-wallpaper.png

sudo chmod 644 \
  /usr/share/backgrounds/urodish/login-wallpaper.png
```

Themes used by LightDM also need to be available system-wide.

---

# 📦 Packages

Manually installed APT packages:

```text
system/apt/manual-packages.txt
```

Full package snapshot:

```text
system/apt/all-packages.txt
```

APT sources:

```text
system/apt/sources.txt
```

Flatpak applications:

```text
system/flatpak/apps.txt
```

Installed software versions:

```text
system/versions.txt
```

`all-packages.txt` is primarily documentation.

Do **not** blindly reinstall every package from it on another distribution/version.

---

# 🔑 APT Repository Fixes

## Spotify

Spotify repository originally failed with:

```text
NO_PUBKEY 5384CE82BA52C83A
```

The signing key was installed using:

```bash
curl -sS \
  https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
  | sudo gpg --dearmor --yes \
  -o /etc/apt/trusted.gpg.d/spotify.gpg
```

---

## Amnezia

The Amnezia repository originally used the legacy `trusted.gpg` keyring.

The key fingerprint was:

```text
75C9 DD72 C799 870E 3105 42E2 4166 F2C2 5729 0828
```

It was migrated to:

```text
/etc/apt/keyrings/amnezia.gpg
```

Repository configuration:

```text
/etc/apt/sources.list.d/amneziawg.list
```

with `signed-by=` pointing to the dedicated keyring.

APT repository configuration should always be reviewed before restoring it on a new system.

---

# ⚡ Performance

The rice was tested at idle.

Observed CPU usage:

```text
98–99.5% idle
```

Typical temperatures:

```text
39–43°C
```

RAM usage shortly after boot was approximately:

```text
1.9 GiB used / 27 GiB
```

The customization stack did not produce meaningful idle load.

## Blur warning

A Cinnamon blur extension was tested.

It caused severe desktop lag and was removed.

For this reason heavy compositor/blur effects are intentionally avoided.

---

# 💾 Backup

To refresh the repository from the current system:

```bash
cd ~/my-mint-rice

./scripts/backup.sh
```

Inspect changes:

```bash
git status
git diff
```

Then commit:

```bash
git add .
git commit -m "Update rice snapshot"
```

---

# ♻️ Restore

Clone the repository:

```bash
git clone <repository> ~/my-mint-rice

cd ~/my-mint-rice
```

Install the required applications first.

Then restore user-level configuration:

```bash
./scripts/restore.sh
```

The restore script handles things such as:

- Zsh
- Starship
- Kitty
- btop
- VS Code settings
- VS Code extensions
- GTK theme
- icons
- cursor
- Cinnamon applets
- Cinnamon settings
- Plank
- Spicetify configuration
- FlexFox
- wallpapers

System-level configuration should be reviewed manually.

This includes:

- APT repositories
- LightDM
- system-wide themes
- fonts
- Spotify permissions
- monitor configuration

---

# 🔒 Security

This repository stores configuration, **not personal sessions**.

Never commit:

```text
passwords
browser cookies
authentication tokens
Telegram sessions
SSH private keys
GPG private keys
.env secrets
API keys
private certificates
```

Before publishing:

```bash
git status
```

and inspect all files being committed.

---

# 📁 Repository Structure

```text
my-mint-rice/
├── README.md
├── system-inventory.txt
│
├── configs/
│   ├── btop/
│   ├── cinnamon/
│   ├── firefox/
│   ├── kitty/
│   ├── lightdm/
│   ├── plank/
│   ├── spicetify/
│   ├── starship/
│   ├── vscode/
│   └── zsh/
│
├── themes/
│   ├── cursors/
│   ├── gtk/
│   └── icons/
│
├── wallpapers/
│   ├── wallpaper-5k.png
│   └── telegram-wallpaper.png
│
├── system/
│   ├── apt/
│   ├── flatpak/
│   ├── fonts/
│   └── gsettings/
│
├── scripts/
│   ├── backup.sh
│   └── restore.sh
│
└── docs/
```

---

# 🎯 Repository Philosophy

Prefer **reproducible configuration** over copying complete application profiles.

The repository should contain enough information to rebuild the environment while keeping personal data and authentication state outside Git.

The intended workflow is:

```text
fresh Linux Mint
       ↓
install required software
       ↓
clone my-mint-rice
       ↓
restore configs/themes
       ↓
apply machine-specific system settings
       ↓
done
```