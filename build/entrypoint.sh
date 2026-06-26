#!/bin/bash

set -e

readonly port_vnc=${DESKTAINER_PORT_VNC:-5900}
readonly port_novnc=${DESKTAINER_PORT_NOVNC:-6900}

readonly labwc_verbose=${DESKTAINER_LABWC_VERBOSE:-false}

readonly disable_minimize=${DESKTAINER_DISABLE_MINIMIZE:-false}

################################################################################

args_labwc=(-S/usr/bin/startlxqt)
if [ "$labwc_verbose" = true ]; then args_labwc+=(-V); fi

args_wayvnc=(-D 0.0.0.0 "$port_vnc")

args_websockify=(--web=/usr/share/novnc "0.0.0.0:$port_novnc" "127.0.0.1:$port_vnc")

# TODO support DESKTAINER_PORT_VNC=unix: -Du ${XDG_RUNTIME_DIR@Q}/desktainer-vnc.sock
# TODO support --web=/usr/share/novnc --unix-target=${XDG_RUNTIME_DIR@Q}/desktainer-vnc.sock 0.0.0.0:$port_novnc
# TODO support maybe noVNC port "none" to disable it

################################################################################

find /tmp -mindepth 1 -delete

USER=$(id -un); export USER
export HOME=~

# Needed to have the correct shell inside the terminal emulator
SHELL=$(getent passwd "$USER" | cut -d: -f7); export SHELL

export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
install -dvm700 "$XDG_RUNTIME_DIR"

cd

install -dvm700 ~/.config{,/autostart}

install -dvm700 ~/.config/labwc
if [ "$disable_minimize" = true ]; then
    # This is a workaround for the fact that the Task Manager panel doesn't
    # show any window
    [ -e ~/.config/labwc/rc.xml ] ||
        install -Tvm644 /dev/stdin ~/.config/labwc/rc.xml << 'EOF'
<?xml version="1.0"?>
<labwc_config>
  <mouse>
    <default />

    <context name="Iconify">
      <mousebind button="Left" action="Click">
        <action name="None" />
      </mousebind>
    </context>
  </mouse>
</labwc_config>
EOF
fi

[ -e ~/.config/autostart/wayvncctl-attach.desktop ] ||
    install -Tvm644 /dev/stdin \
        ~/.config/autostart/wayvncctl-attach.desktop << 'EOF'
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

# Not strictly required, because the LXQt session should create the
# directories anyway if they don't exist, but we do it in advance, just in case
xdg-user-dirs-update

install -dvm700 ~/.supervisor{,/conf.d,/log}

[ -e ~/.supervisor/supervisord.conf ] ||
    install -Tvm644 /dev/stdin ~/.supervisor/supervisord.conf << EOF
[supervisord]
nodaemon=true
logfile=%(here)s/log/supervisord.log
pidfile=%(here)s/supervisord.pid
childlogdir=%(here)s/log

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[group:main]
programs=desktop,wayvnc,novnc

[program:desktop]
; Known issue: the Task Manager panel doesn't show any window. But LXQt's
; Wayland support is still experimental in Debian 13 (trixie), and
; it will be more robust in Debian 14 (forky). For now, we
; can use Alt+Tab to cycle through open windows
command=/usr/bin/dbus-run-session -- /usr/bin/labwc ${args_labwc[*]@Q}
environment=WLR_BACKENDS="headless",WLR_RENDERER="pixman",
    QT_QPA_PLATFORM="wayland"

[program:wayvnc]
; Note: wayvnc creates the Unix Domain Socket ${XDG_RUNTIME_DIR@Q}/wayvncctl to
; make the wayvncctl CLI tool work
command=/usr/bin/wayvnc ${args_wayvnc[*]@Q}

[program:novnc]
command=/usr/bin/websockify ${args_websockify[*]@Q}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[include]
files=%(here)s/conf.d/*.conf
EOF

exec /usr/bin/supervisord -nc ~/.supervisor/supervisord.conf
