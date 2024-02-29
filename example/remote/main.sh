#!/bin/bash

set -e

cd "$(dirname "$0")"

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

apt_update_if_old() {
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
        apt-get update
    fi
}

################################################################################

# TODOEND: remember that everything must be idempotent

# TODO remove appownmod from everywhere!
# TODO always check with grep before using ">>"

dpkg -s curl >/dev/null 2>&1 || {
    apt_update_if_old; apt-get install -y \
        git nano tmux tree wget zip curl socat procps jq yq \
        iputils-ping iproute2 firefox-esr dirmngr
}

# TODO closer to their config (using "command -v" to be faster): shellinabox ffmpeg dconf-cli

################################################################################

fetch_and_check() { # Src: https://github.com/dmotte/misc
    local c s; c=$(curl -fsSL "$1"; echo x) && \
    s=$(echo -n "${c%x}" | sha256sum | cut -d' ' -f1) && \
    if [ "$s" = "$2" ]; then echo -n "${c%x}"
    else echo "Checksum verification failed for $1: got $s, expected $2" >&2
    return 1; fi
}

script_lognot=$(fetch_and_check \
    'https://raw.githubusercontent.com/dmotte/misc/main/scripts/provisioning/lognot.sh' \
    'f84b6c3ecf726c2d7605164770ccef7c725731ea3897aad2d6d70d7ae6cfb31f')
setup_lognot() { bash <(echo "$script_lognot") "$@"; }
script_portmap=$(fetch_and_check \
    'https://raw.githubusercontent.com/dmotte/misc/main/scripts/provisioning/portmap.sh' \
    'fd5b05aae3a11bc2898970424b316afb373f2c93480098428f8d3cec1b8963f4')
setup_portmap() { bash <(echo "$script_portmap") "$@"; }

################################################################################

bash helpers/hardening.sh
bash helpers/supervisorctl.sh

# shellcheck disable=SC2016
setup_lognot -b'(put-bot-token-here)' -c'(put-chat-id-here)' \
    'bash /opt/lognot/get.sh | while read -r i; do echo "$HOSTNAME: $i"; done'
install -m700 lognot-get.sh /opt/lognot/get.sh

bash helpers/sshd.sh

################################################################################

if [ "$SUPERVISOR_RELOAD" = 'true' ]; then
    echo 'Sending SIGHUP to supervisord (pid 1)'
    kill -sHUP 1
fi

if [ "$SUPERVISOR_UPDATE" = 'true' ]; then
    echo 'Running supervisorctl update'
    supervisorctl update
fi
