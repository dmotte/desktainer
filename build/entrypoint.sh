#!/bin/bash

set -e

USER=$(id -un); export USER
export HOME=~

cd

readonly port_vnc=${DESKTAINER_PORT_VNC:-5900}
readonly port_novnc=${DESKTAINER_PORT_NOVNC:-6900}

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
