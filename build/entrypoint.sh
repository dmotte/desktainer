#!/bin/bash

set -e

# rm -rf /tmp/* /tmp/.* # TODO good?

USER=$(id -un); export USER
export HOME=~

# Set the SHELL env var with 'getent passwd "$USER" | cut -d: -f7'? Maybe only if it's NOT set in the LXQt terminal? But I guess I added it because, when running as root, the /bin/sh shell is used for some reason. But check this pls!

export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
# shellcheck disable=SC2174
mkdir -pvm700 "$XDG_RUNTIME_DIR"

# TODO XDG_CONFIG_HOME env var needed? Other XDG_ env vars?

cd

# xdg-user-dirs-update # TODO needed? Not completely sure, because the page https://manpages.debian.org/trixie/xdg-user-dirs/xdg-user-dirs-update.1.en.html says that it's "run automatically at the start of a user session"

readonly port_vnc=${DESKTAINER_PORT_VNC:-5900}
readonly port_novnc=${DESKTAINER_PORT_NOVNC:-6900}

# TODO create supervisord dir, conf.d dir, and cfg file

bash; exit # TODO

echo "Setting VNC port to $vnc_port"
sed -i "s/%vnc_port%/$vnc_port/g" ~/.desktainer/supervisor/supervisord.conf

echo "Setting noVNC port to $novnc_port"
sed -i "s/%novnc_port%/$novnc_port/g" ~/.desktainer/supervisor/supervisord.conf

# Note: we use the pipe character as delimiter in the expression #2 because the
# $mainuser_home variable contains slashes
sed -i "s/%mainuser_name%/$mainuser_name/g;s|%mainuser_home%|$mainuser_home|g" \
    ~/.desktainer/supervisor/supervisord.conf

exec /usr/bin/supervisord -nc ~/.desktainer/supervisor/supervisord.conf
