#!/bin/bash

set -e

readonly port_vnc=${DESKTAINER_PORT_VNC:-5900}
readonly port_novnc=${DESKTAINER_PORT_NOVNC:-6900}

################################################################################

# rm -rf /tmp/* /tmp/.* # TODO good?

USER=$(id -un); export USER
export HOME=~

# Needed to have the correct shell inside the terminal emulator
SHELL=$(getent passwd "$USER" | cut -d: -f7); export SHELL

export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
install -dvm700 "$XDG_RUNTIME_DIR"

# TODO XDG_CONFIG_HOME env var needed? Other XDG_ env vars?

cd

install -dvm700 ~/.config{,/autostart}

install -Tvm644 /dev/stdin ~/.config/autostart/wayvncctl-attach.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=wayvncctl-attach
Exec=/bin/sh -ec '/usr/bin/wayvncctl -w attach "$WAYLAND_DISPLAY"'
NoDisplay=true
EOF

install -dvm700 ~/.config/wayvnc
# WARNING: when running as root, "enable_pam=true" makes wayvnc accept any
# existing user as a valid login!
[ -e ~/.config/wayvnc/config ] ||
    printf '%s\n' enable_auth=true relax_encryption=true enable_pam=true |
        install -Tvm644 /dev/stdin ~/.config/wayvnc/config

# xdg-user-dirs-update # TODO needed? Not completely sure, because the page https://manpages.debian.org/trixie/xdg-user-dirs/xdg-user-dirs-update.1.en.html says that it's "run automatically at the start of a user session"

install -dvm700 ~/.supervisor{,/conf.d}

[ -e ~/.supervisor/supervisord.conf ] ||
    install -Tvm644 /dev/stdin ~/.supervisor/supervisord.conf << EOF
[supervisord]
nodaemon=true
logfile=%(here)s/supervisord.log ; TODO test, and consider subdir "log" like in svcbox-rootless (does it get automatically created?)
pidfile=%(here)s/supervisord.pid ; TODO test
childlogdir=%(here)s ; TODO test, and consider subdir "log" like in svcbox-rootless (does it get automatically created?)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[group:main]
programs=desktop,wayvnc,novnc

[program:desktop]
; Known issue: the Task Manager panel doesn't show any window. But LXQt's
; Wayland support is still experimental in Debian 13 (trixie), and
; it will be more robust in Debian 14 (forky). For now, we
; can use Alt+Tab to cycle through open windows
command=/usr/bin/dbus-run-session -- /usr/bin/labwc -S/usr/bin/startlxqt
environment=WLR_BACKENDS="headless",WLR_RENDERER="pixman",QT_QPA_PLATFORM="wayland"
; TODO Support env var DESKTAINER_LABWC_VERBOSE to add the "-V" (verbose) flag to labwc

[program:wayvnc]
; Note: wayvnc creates the Unix Domain Socket "$XDG_RUNTIME_DIR/wayvncctl" to
; make the wayvncctl CLI tool work
command=/usr/bin/wayvnc -D 0.0.0.0
; TODO support DESKTAINER_PORT_VNC=unix to run it like "wayvnc -u"
; TODO support custom port number

[program:novnc]
; TODO support VNC as socket file
; TODO support custom port numbers, and maybe also "none" to disable it
command=/usr/bin/websockify --web=/usr/share/novnc 6900 127.0.0.1:5900

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[include]
files=%(here)s/conf.d/*.conf ; TODO test
EOF

# TODO is leaving the already existing /etc/supervisor/supervisord.conf there an issue? Is the socket for supervisorctl created? Moreover, read it so you compare yours with the official one

bash; exit # TODO

exec /usr/bin/supervisord -nc ~/.supervisor/supervisord.conf
