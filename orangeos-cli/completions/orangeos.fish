set -l seen '__fish_seen_subcommand_from'
set -l has_opt '__fish_contains_opt'

set -l commands shell toggle scheme screenshot record clipboard emoji wallpaper resizer install update
set -l not_seen "not $seen $commands"

# Disable file completions
complete -c orangeos -f

# Add help for any command
complete -c orangeos -s 'h' -l 'help' -d 'Show help'

# Subcommands
complete -c orangeos -n $not_seen -a 'shell' -d 'Start the shell or message it'
complete -c orangeos -n $not_seen -a 'toggle' -d 'Toggle a special workspace'
complete -c orangeos -n $not_seen -a 'scheme' -d 'Manage the colour scheme'
complete -c orangeos -n $not_seen -a 'screenshot' -d 'Take a screenshot'
complete -c orangeos -n $not_seen -a 'record' -d 'Start a screen recording'
complete -c orangeos -n $not_seen -a 'clipboard' -d 'Open clipboard history'
complete -c orangeos -n $not_seen -a 'emoji' -d 'Emoji/glyph utilities'
complete -c orangeos -n $not_seen -a 'wallpaper' -d 'Manage the wallpaper'
complete -c orangeos -n $not_seen -a 'resizer' -d 'Window resizer'
complete -c orangeos -n $not_seen -a 'install' -d 'Install the Orange OS dotfiles'
complete -c orangeos -n $not_seen -a 'update' -d 'Update the Orange OS dotfiles'

# Shell
set -l commands mpris drawers wallpaper notifs
set -l not_seen "$seen shell && not $seen $commands"
complete -c orangeos -n $not_seen -s 'd' -l 'daemon' -d 'Start the shell detached'
complete -c orangeos -n $not_seen -s 'r' -l 'restart' -d 'Kill and restart the shell'
complete -c orangeos -n $not_seen -s 's' -l 'show' -d 'Print all IPC commands'
complete -c orangeos -n $not_seen -s 'l' -l 'log' -d 'Print the shell log'
complete -c orangeos -n $not_seen -l 'log-rules' -d 'Log rules to apply'
complete -c orangeos -n $not_seen -a 'mpris' -d 'Mpris control'
complete -c orangeos -n $not_seen -a 'drawers' -d 'Toggle drawers'
complete -c orangeos -n $not_seen -a 'wallpaper' -d 'Wallpaper control (for internal use)'
complete -c orangeos -n $not_seen -a 'notifs' -d 'Notification control'

set -l commands getActive play pause playPause stop next previous list
set -l not_seen "$seen shell && $seen mpris && not $seen $commands"
complete -c orangeos -n $not_seen -a 'play' -d 'Play media'
complete -c orangeos -n $not_seen -a 'pause' -d 'Pause media'
complete -c orangeos -n $not_seen -a 'playPause' -d 'Play/pause media'
complete -c orangeos -n $not_seen -a 'next' -d 'Skip to next song'
complete -c orangeos -n $not_seen -a 'previous' -d 'Go to previous song'
complete -c orangeos -n $not_seen -a 'stop' -d 'Stop media'
complete -c orangeos -n $not_seen -a 'list' -d 'List media players'
complete -c orangeos -n $not_seen -a 'getActive' -d 'Get a property from the active MPRIS player'

set -l commands trackTitle trackArtist trackAlbum position length identity
set -l not_seen "$seen shell && $seen mpris && $seen getActive && not $seen $commands"
complete -c orangeos -n $not_seen -a 'trackTitle' -d 'Track title'
complete -c orangeos -n $not_seen -a 'trackArtist' -d 'Track artist'
complete -c orangeos -n $not_seen -a 'trackAlbum' -d 'Track album'
complete -c orangeos -n $not_seen -a 'position' -d 'Track position'
complete -c orangeos -n $not_seen -a 'length' -d 'Track length'
complete -c orangeos -n $not_seen -a 'identity' -d 'Player identity'

set -l commands list toggle
set -l not_seen "$seen shell && $seen drawers && not $seen $commands"
complete -c orangeos -n $not_seen -a 'list' -d 'List togglable drawers'
complete -c orangeos -n $not_seen -a 'toggle' -d 'Toggle a drawer'

set -l commands (orangeos shell drawers list 2> /dev/null)
complete -c orangeos -n "$seen shell && $seen drawers && $seen toggle && not $seen $commands" -a "$commands" -d 'drawer'

set -l commands list get set
set -l not_seen "$seen shell && $seen wallpaper && not $seen $commands"
complete -c orangeos -n $not_seen -a 'list' -d 'List wallpapers'
complete -c orangeos -n $not_seen -a 'get' -d 'Get current wallpaper path'
complete -c orangeos -n $not_seen -a 'set' -d 'Change wallpaper'
complete -c orangeos -n "$seen shell && $seen wallpaper && $seen set" -F

complete -c orangeos -n "$seen shell && $seen notifs && not $seen clear" -a 'clear' -d 'Clear popup notifications'

# Toggles
set -l commands communication music specialws sysmon todo
complete -c orangeos -n "$seen toggle && not $seen drawers && not $seen $commands" -a "$commands" -d 'toggle'

# Scheme
set -l commands list get set
set -l not_seen "$seen scheme && not $seen $commands"
complete -c orangeos -n $not_seen -a 'list' -d 'List available schemes'
complete -c orangeos -n $not_seen -a 'get' -d 'Get scheme properties'
complete -c orangeos -n $not_seen -a 'set' -d 'Set the current scheme'

complete -c orangeos -n "$seen scheme && $seen list" -s 'n' -l 'names' -d 'List scheme names'
complete -c orangeos -n "$seen scheme && $seen list" -s 'f' -l 'flavours' -d 'List scheme flavours'
complete -c orangeos -n "$seen scheme && $seen list" -s 'm' -l 'modes' -d 'List scheme modes'
complete -c orangeos -n "$seen scheme && $seen list" -s 'v' -l 'variants' -d 'List scheme variants'

complete -c orangeos -n "$seen scheme && $seen get" -s 'n' -l 'name' -d 'Get scheme name'
complete -c orangeos -n "$seen scheme && $seen get" -s 'f' -l 'flavour' -d 'Get scheme flavour'
complete -c orangeos -n "$seen scheme && $seen get" -s 'm' -l 'mode' -d 'Get scheme mode'
complete -c orangeos -n "$seen scheme && $seen get" -s 'v' -l 'variant' -d 'Get scheme variant'

complete -c orangeos -n "$seen scheme && $seen set" -l 'notify' -d 'Send a notification on error'
complete -c orangeos -n "$seen scheme && $seen set" -s 'r' -l 'random' -d 'Switch to a random scheme'
complete -c orangeos -n "$seen scheme && $seen set" -s 'n' -l 'name' -d 'Set scheme name' -a "$(caelestia scheme list -n)" -r
complete -c orangeos -n "$seen scheme && $seen set" -s 'f' -l 'flavour' -d 'Set scheme flavour' -a "$(caelestia scheme list -f)" -r
complete -c orangeos -n "$seen scheme && $seen set" -s 'm' -l 'mode' -d 'Set scheme mode' -a "$(caelestia scheme list -m)" -r
complete -c orangeos -n "$seen scheme && $seen set" -s 'v' -l 'variant' -d 'Set scheme variant' -a "$(caelestia scheme list -v)" -r

# Screenshot
complete -c orangeos -n "$seen screenshot" -s 'r' -l 'region' -d 'Capture region'
complete -c orangeos -n "$seen screenshot" -s 'f' -l 'freeze' -d 'Freeze while selecting region'

# Record
complete -c orangeos -n "$seen record" -s 'r' -l 'region' -d 'Capture region'
complete -c orangeos -n "$seen record" -s 's' -l 'sound' -d 'Capture sound'
complete -c orangeos -n "$seen record" -s 'c' -l 'clipboard' -d 'Copy recording path to clipboard'

# Clipboard
complete -c orangeos -n "$seen clipboard" -s 'd' -l 'delete' -d 'Delete from cliboard history'

# Wallpaper
complete -c orangeos -n "$seen wallpaper" -s 'p' -l 'print' -d 'Print the scheme for a wallpaper' -rF
complete -c orangeos -n "$seen wallpaper" -s 'r' -l 'random' -d 'Switch to a random wallpaper' -rF
complete -c orangeos -n "$seen wallpaper" -s 'f' -l 'file' -d 'The file to switch to' -rF
complete -c orangeos -n "$seen wallpaper" -s 'n' -l 'no-filter' -d 'Do not filter by size'
complete -c orangeos -n "$seen wallpaper" -s 't' -l 'threshold' -d 'The threshold to filter by' -r
complete -c orangeos -n "$seen wallpaper" -s 'N' -l 'no-smart' -d 'Disable smart mode switching'

# Emoji
complete -c orangeos -n "$seen emoji" -s 'p' -l 'picker' -d 'Open emoji/glyph picker'
complete -c orangeos -n "$seen emoji" -s 'f' -l 'fetch' -d 'Fetch emoji/glyph data from remote'

# Resizer
complete -c orangeos -n "$seen resizer" -s 'd' -l 'daemon' -d 'Start in daemon mode'
complete -c orangeos -n "$seen resizer" -a 'pip' -d 'Quick pip mode'
complete -c orangeos -n "$seen resizer" -a 'active' -d 'Select the active window'

# Install (component flags come from the manifest, so are not completed statically)
complete -c orangeos -n "$seen install" -l 'aur-helper' -d 'The AUR helper to use' -a 'yay paru' -r
complete -c orangeos -n "$seen install" -l 'enable-components' -d 'List of components to enable' -r
complete -c orangeos -n "$seen install" -l 'disable-components' -d 'List of components to disable' -r
complete -c orangeos -n "$seen install" -l 'noconfirm' -d 'Use defaults for all prompts'

# Update
complete -c orangeos -n "$seen update" -l 'aur-helper' -d 'The AUR helper to use' -a 'yay paru' -r
complete -c orangeos -n "$seen update" -l 'noconfirm' -d 'Use defaults for all prompts'
