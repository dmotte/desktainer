#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

apt_update_if_old() {
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
        apt-get update
    fi
}

################################################################################

dpkg -s shellinabox >/dev/null 2>&1 ||
    { apt_update_if_old; apt-get install -y shellinabox; }

echo 'Creating shellinabox service files'

cat << 'EOF' > /etc/supervisor/conf.d/shellinabox.conf
[program:shellinabox]
command=/usr/bin/shellinaboxd -tp4200 -ushellinabox -gshellinabox
    --user-css='White on Black:+/etc/shellinabox/options-enabled/00_White On Black.css;Color Terminal:+/etc/shellinabox/options-enabled/01+Color Terminal.css'
    -s'/:AUTH:HOME:tmux new-session -As0'
priority=10
EOF
