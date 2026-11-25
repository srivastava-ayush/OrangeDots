# orangeos-cli (vendored)

This is a vendored copy of upstream `caelestia-cli`, renamed to provide the
`orangeos` command. The Python module, config/state directories and the shell
IPC config name intentionally stay `caelestia` for compatibility with the
Orange OS shell — only the installed command and branding are renamed.

Install from the OrangeDots repo root with `pip install --user ./orangeos-cli`,
or add `orangeos-cli/bin` to `PATH` to run `bin/orangeos` directly from the
checkout. See the top-level OrangeDots `README.md` for the full setup.

The main control script for the Orange OS dotfiles.

<details><summary id="dependencies">External dependencies</summary>

- [`libnotify`](https://gitlab.gnome.org/GNOME/libnotify) - sending notifications
- [`swappy`](https://github.com/jtheoof/swappy) - screenshot editor
- [`grim`](https://gitlab.freedesktop.org/emersion/grim) - taking screenshots
- [`dart-sass`](https://github.com/sass/dart-sass) - discord theming
- [`wl-clipboard`](https://github.com/bugaevc/wl-clipboard) - copying to clipboard
- [`slurp`](https://github.com/emersion/slurp) - selecting an area
- [`gpu-screen-recorder`](https://git.dec05eba.com/gpu-screen-recorder/about) - screen recording
- `glib2` - closing notifications
- [`cliphist`](https://github.com/sentriz/cliphist) - clipboard history
- [`fuzzel`](https://codeberg.org/dnkl/fuzzel) - clipboard history/emoji picker
- [`ffmpeg`](https://ffmpeg.org) - video wallpaper detection and colour generation

</details>

## Installation

This copy is vendored inside the OrangeDots repo, so there is no separate
`caelestia-cli` package to install. From the OrangeDots repo root:

```sh
python3 -m pip install --user ./orangeos-cli
```

This installs the `orangeos` command. Alternatively, without installing,
symlink `orangeos-cli/bin/orangeos` into `~/.local/bin` — the wrapper resolves
symlinks and runs the vendored module directly.

### Nix

The Orange OS shell flake exposes the vendored CLI as a local input
(`path:../../orangeos-cli`). Its package is `orangeos-cli`, with `orangeos` as
the installed command. You can also build it standalone from this directory:

```sh
nix run .
```

### Manual installation

Install all [dependencies](#dependencies), then from the OrangeDots repo root:

```sh
python3 -m pip install --user ./orangeos-cli
```

For fish completions, copy `completions/orangeos.fish` to
`/usr/share/fish/vendor_completions.d/orangeos.fish`.

### Additional steps

#### Auto folder colour theming

For automatic Papirus folder icon colour syncing, you must have [`papirus-folders`](https://github.com/PapirusDevelopmentTeam/papirus-folders)
installed, and `papirus-folders` must to be able to run with `sudo` without a password prompt.

You can allow this by creating a sudoers file:

```sh
echo "$USER ALL=(ALL) NOPASSWD: $(which papirus-folders)" | sudo tee /etc/sudoers.d/papirus-folders
sudo chmod 440 /etc/sudoers.d/papirus-folders
```

#### Chromium-based browser theming

For live Chromium-based browser theming, the CLI must be allowed to create certain directories in `/etc`
and write to them via `sudo` without a password prompt.

You can allow this by creating a sudoers file:

```fish
# Fish shell
for dir in /etc/chromium/policies/managed /etc/brave/policies/managed /etc/opt/chrome/policies/managed
    echo "$USER ALL=(ALL) NOPASSWD: $(which mkdir) -p $dir" | sudo tee -a /etc/sudoers.d/caelestia-chromium
    echo "$USER ALL=(ALL) NOPASSWD: $(which tee) $dir/caelestia.json" | sudo tee -a /etc/sudoers.d/caelestia-chromium
end
sudo chmod 440 /etc/sudoers.d/caelestia-chromium
```

```sh
# Bash/other shells
for dir in /etc/chromium/policies/managed /etc/brave/policies/managed /etc/opt/chrome/policies/managed; do
    echo "$USER ALL=(ALL) NOPASSWD: $(which mkdir) -p $dir" | sudo tee -a /etc/sudoers.d/caelestia-chromium
    echo "$USER ALL=(ALL) NOPASSWD: $(which tee) $dir/caelestia.json" | sudo tee -a /etc/sudoers.d/caelestia-chromium
done
sudo chmod 440 /etc/sudoers.d/caelestia-chromium
```

## Usage

All subcommands/options can be explored via the help flag.

```
$ caelestia -h
usage: caelestia [-h] [-v] COMMAND ...

Main control script for the Caelestia dotfiles

options:
  -h, --help     show this help message and exit
  -v, --version  print the current version

subcommands:
  valid subcommands

  COMMAND        the subcommand to run
    shell        start or message the shell
    toggle       toggle a special workspace
    scheme       manage the colour scheme
    screenshot   take a screenshot
    record       start a screen recording
    clipboard    open clipboard history
    emoji        emoji/glyph utilities
    wallpaper    manage the wallpaper
    resizer      window resizer daemon
    install      install the Caelestia dotfiles
    update       update the Caelestia dotfiles
```

### User templates

Custom user templates can be defined in `~/.config/caelestia/templates/`.

#### Template syntax

`{{ <color>.<format> }}`

- `<color>` is a theme color role derived from the Material You color system (e.g. `primary`, `secondary`, `background`)
- `<format>` is the output format: `hex`, `rgb`, `hsl`, or a single channel (`red`, `green`, `blue`, `hue`, `saturation`, `lightness`)

#### Examples

- `{{ primary.hex }}` outputs `3f4ba2`
- `{{ primary.rgb }}` outputs `rgb(193, 132, 207)`
- `{{ primary.red }}` outputs `193`
- `{{ primary.hsl }}` outputs `hsl(268,41%,66%)`
- `{{ primary.hue }}` outputs `268`

Output files are written to `~/.local/state/caelestia/theme/`. You can symlink them to your desired locations.

## Configuring

All configuration options are in `~/.config/caelestia/cli.json`.

<details><summary>Example configuration</summary>

```json
{
    "record": {
        "extraArgs": []
    },
    "wallpaper": {
        "postHook": "echo $WALLPAPER_PATH $SCHEME_NAME $SCHEME_FLAVOUR $SCHEME_MODE $SCHEME_VARIANT $SCHEME_COLOURS"
    },
    "theme": {
        "enableTerm": true,
        "enableHypr": true,
        "enableDiscord": true,
        "enableSpicetify": true,
        "enablePandora": true,
        "enableFuzzel": true,
        "enableBtop": true,
        "enableNvtop": true,
        "enableHtop": true,
        "enableGtk": true,
        "enableQt": true,
        "enableWarp": true,
        "enableChromium": true,
        "enableZed": true,
        "enableCava": true,
        "iconTheme": "Papirus-Dark",
        "iconThemeLight": "Papirus-Light",
        "iconThemeDark": "Papirus-Dark",
        "postHook": "echo $SCHEME_NAME $SCHEME_FLAVOUR $SCHEME_MODE $SCHEME_VARIANT $SCHEME_COLOURS"
    },
    "toggles": {
        "communication": {
            "discord": {
                "enable": true,
                "match": [{ "class": "discord" }],
                "command": ["discord"],
                "move": true
            },
            "whatsapp": {
                "enable": true,
                "match": [{ "class": "whatsapp" }],
                "move": true
            }
        },
        "music": {
            "spotify": {
                "enable": true,
                "match": [{ "class": "Spotify" }, { "initialTitle": "Spotify" }, { "initialTitle": "Spotify Free" }],
                "command": ["spicetify", "watch", "-s"],
                "move": true
            },
            "feishin": {
                "enable": true,
                "match": [{ "class": "feishin" }],
                "move": true
            }
        },
        "sysmon": {
            "btop": {
                "enable": true,
                "match": [{ "class": "btop", "title": "btop", "workspace": { "name": "special:sysmon" } }],
                "command": ["foot", "-a", "btop", "-T", "btop", "fish", "-C", "exec btop"]
            }
        },
        "todo": {
            "todoist": {
                "enable": true,
                "match": [{ "class": "Todoist" }],
                "command": ["todoist"],
                "move": true
            }
        }
    },
    "dots": {
        "url": "https://github.com/caelestia-dots/caelestia.git",
        "branch": "main"
    }
}
```

</details>
