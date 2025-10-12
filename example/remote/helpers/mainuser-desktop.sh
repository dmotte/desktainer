#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

options=$(getopt -o + -l mimeapps-file: -l dconf-file: \
    -l xrandr-fb: -l wallpaper: -- "$@")
eval "set -- $options"

mimeapps_file=''
dconf_file=''
xrandr_fb='1920x900'
wallpaper='#3a6ea5'

while :; do
    case $1 in
        --mimeapps-file) shift; mimeapps_file=$1;;
        --dconf-file) shift; dconf_file=$1;;
        --xrandr-fb) shift; xrandr_fb=$1;;
        --wallpaper) shift; wallpaper=$1;;
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

dpkg -s dconf-cli >/dev/null 2>&1 ||
    { apt_update_if_old; apt-get install -y dconf-cli; }

install -d -omainuser -gmainuser ~mainuser/.config{,/autostart,/pcmanfm{,/LXDE}}

if [ -n "$mimeapps_file" ]; then
    if [ -e ~mainuser/.config/mimeapps.list ]; then
        # We can skip this, it's not so important
        echo 'Mimeapps file already exists. Skipping'
    else
        echo "Installing mimeapps file $mimeapps_file"
        install -omainuser -gmainuser -Tm600 "$mimeapps_file" \
            ~mainuser/.config/mimeapps.list
    fi
fi

if [ -n "$dconf_file" ]; then
    echo "Installing dconf file $dconf_file and autostart launcher"

    install -omainuser -gmainuser -Tm644 "$dconf_file" \
        ~mainuser/.config/initial.dconf

    install -omainuser -gmainuser -Tm644 /dev/stdin \
        ~mainuser/.config/autostart/dconf-load.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=dconf-load
Exec=/bin/sh -ec '/usr/bin/dconf load / < ~/.config/initial.dconf'
NoDisplay=true
EOF
fi

echo "Installing autostart launcher to set resolution to $xrandr_fb at startup"

install -omainuser -gmainuser -Tm644 /dev/stdin \
    ~mainuser/.config/autostart/xrandr-fb.desktop << EOF
[Desktop Entry]
Type=Application
Name=xrandr-fb
Exec=/usr/bin/xrandr --fb $xrandr_fb
NoDisplay=true
EOF

if [ -e ~mainuser/.config/pcmanfm/LXDE/pcmanfm.conf ]; then
    # We can skip this, it's not so important
    echo 'The pcmanfm.conf file already exists. Skipping'
else
    echo 'Installing pcmanfm.conf file'
    install -omainuser -gmainuser -Tm644 <(echo -e '[ui]\nshow_hidden=1') \
        ~mainuser/.config/pcmanfm/LXDE/pcmanfm.conf
fi

if [[ "$wallpaper" = \#* ]]
    then readonly wallpaper_mode=color wallpaper_key=desktop_bg
    else readonly wallpaper_mode=crop wallpaper_key=wallpaper
fi

echo "Setting wallpaper_mode=$wallpaper_mode, $wallpaper_key=$wallpaper"

sed -Ei ~mainuser/.config/pcmanfm/LXDE/desktop-items-0.conf \
    -e "s/^wallpaper_mode=.*$/wallpaper_mode=$wallpaper_mode/" \
    -e "s|^$wallpaper_key=.*$|$wallpaper_key=$wallpaper|"

install -dv -omainuser -gmainuser ~mainuser/Desktop

if [ ! -e ~mainuser/Desktop/persistent ]; then
    ln -Tsv /data/mainuser ~mainuser/Desktop/persistent
    chown -h mainuser:mainuser ~mainuser/Desktop/persistent
fi
