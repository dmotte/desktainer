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

apt_update_if_old
apt-get install -y git nano tmux tree wget zip curl socat procps jq yq \
    iputils-ping iproute2 openssh-server \
    shellinabox ffmpeg firefox-esr dirmngr dconf-cli # TODO move things like shellinabox, openssh-server, etc. closer to their config! And you can use "command -v" to be faster there

bash helpers/hardening.sh
bash helpers/supervisorctl.sh
