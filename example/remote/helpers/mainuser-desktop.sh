#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

options=$(getopt -o '' -l mimeapps-file: -l dconf-file: \
    -l xrandr-fb: -l wallpaper: -- "$@")
eval "set -- $options"

mimeapps_file=''
dconf_file=''
xrandr_fb='1920x900'
wallpaper='#3a6ea5'

while :; do
    case "$1" in
        --mimeapps-file) shift; mimeapps_file="$1";;
        --dconf-file) shift; dconf_file="$1";;
        --xrandr-fb) shift; xrandr_fb="$1";;
        --wallpaper) shift; wallpaper="$1";;
        --) shift; break;;
    esac
    shift
done

apt_update_if_old() {
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
        apt-get update
    fi
}

################################################################################

echo 'Configuring mainuser desktop'

dpkg -s dconf-cli >/dev/null 2>&1 || \
    { apt_update_if_old; apt-get install -y dconf-cli; }

install -d -omainuser -gmainuser ~mainuser/.config{,/autostart,/pcmanfm{,/LXDE}}

if [ -n "$mimeapps_file" ]; then
    echo "Installing mimeapps file $mimeapps_file"

    install -omainuser -gmainuser -m644 "$mimeapps_file" \
        ~mainuser/.config/mimeapps.list
fi

if [ -n "$dconf_file" ]; then
    echo "Installing dconf file $dconf_file and autostart launcher"

    install -omainuser -gmainuser -m644 "$dconf_file" \
        ~mainuser/.config/initial.dconf

    install -omainuser -gmainuser -m644 /dev/stdin \
        ~mainuser/.config/autostart/dconf-load.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=dconf-load
Exec=/bin/sh -ec '/usr/bin/dconf load / < ~/.config/initial.dconf'
NoDisplay=true
EOF
fi

echo "Installing autostart launcher to set resolution to $xrandr_fb at startup"

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/autostart/xrandr-fb.desktop << EOF
[Desktop Entry]
Type=Application
Name=xrandr-fb
Exec=/usr/bin/xrandr --fb $xrandr_fb
NoDisplay=true
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/pcmanfm/LXDE/pcmanfm.conf << 'EOF'
[ui]
show_hidden=1
EOF

if [[ "$wallpaper" = \#* ]]; then
    wallpaper_mode=color; wallpaper_spec="desktop_bg=$wallpaper"
else
    wallpaper_mode=crop; wallpaper_spec="wallpaper=$wallpaper"
fi

echo "Setting wallpaper_mode=$wallpaper_mode, $wallpaper_spec"

install -omainuser -gmainuser -m644 /dev/stdin \
     ~mainuser/.config/pcmanfm/LXDE/desktop-items-0.conf << EOF
[*]
wallpaper_mode=$wallpaper_mode
$wallpaper_spec
EOF

install -d -omainuser -gmainuser ~mainuser/Desktop

if [ ! -e ~mainuser/Desktop/persistent ]; then
    ln -s /data/mainuser ~mainuser/Desktop/persistent
    chown -h mainuser:mainuser ~mainuser/Desktop/persistent
fi
