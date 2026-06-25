#!/bin/bash

set -e

readonly port_vnc=${DESKTAINER_PORT_VNC:-5900}
readonly port_novnc=${DESKTAINER_PORT_NOVNC:-6900}

################################################################################

# rm -rf /tmp/* /tmp/.* # TODO good?

USER=$(id -un); export USER
export HOME=~

# Set the SHELL env var with 'getent passwd "$USER" | cut -d: -f7'? Maybe only if it's NOT set in the LXQt terminal? But I guess I added it because, when running as root, the /bin/sh shell is used for some reason. But check this pls!

export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
install -dvm700 "$XDG_RUNTIME_DIR"

# TODO XDG_CONFIG_HOME env var needed? Other XDG_ env vars?

cd

install -dvm700 ~/.config

install -dvm700 ~/.config/wayvnc
# WARNING: when running as root, "enable_pam=true" makes wayvnc accept any
# existing user as a valid login!
[ -e ~/.config/wayvnc/config ] ||
    printf '%s\n' enable_auth=true relax_encryption=true enable_pam=true |
        install -Tvm644 /dev/stdin ~/.config/wayvnc/config

# xdg-user-dirs-update # TODO needed? Not completely sure, because the page https://manpages.debian.org/trixie/xdg-user-dirs/xdg-user-dirs-update.1.en.html says that it's "run automatically at the start of a user session"

install -dvm700 ~/.supervisor{,/conf.d}

# TODO test this config!
[ -e ~/.supervisor/supervisord.conf ] ||
    install -Tvm644 /dev/stdin ~/.supervisor/supervisord.conf << EOF
[supervisord]
nodaemon=true
logfile=%(here)s/supervisord.log ; TODO test, and consider subdir "log" like in svcbox-rootless (does it get automatically created?)
pidfile=%(here)s/supervisord.pid ; TODO test
childlogdir=%(here)s ; TODO test, and consider subdir "log" like in svcbox-rootless (does it get automatically created?)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[group:main]
programs=desktop,wayvnc

[program:desktop]
command=/usr/bin/dbus-run-session -- /usr/bin/labwc -S/usr/bin/startlxqt
environment=WLR_BACKENDS="headless",WLR_RENDERER="pixman",QT_QPA_PLATFORM="wayland"

[program:wayvnc]
command=/usr/bin/sleep infinity ; TODO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[include]
files=%(here)s/conf.d/*.conf ; TODO test
EOF

# TODO is leaving the already existing /etc/supervisor/supervisord.conf there an issue? Is the socket for supervisorctl created? Moreover, read it so you compare yours with the official one

bash; exit # TODO

exec /usr/bin/supervisord -nc ~/.supervisor/supervisord.conf
