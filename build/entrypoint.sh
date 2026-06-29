#!/bin/bash

set -e

readonly port_vnc=${DESKTAINER_PORT_VNC:-5900}
readonly port_novnc=${DESKTAINER_PORT_NOVNC:-6900}

readonly labwc_verbose=${DESKTAINER_LABWC_VERBOSE:-false}

readonly disable_minimize=${DESKTAINER_DISABLE_MINIMIZE:-false}

################################################################################

find /tmp -mindepth 1 -delete

USER=$(id -un); export USER
export HOME=~

# Needed to have the correct shell inside the terminal emulator
SHELL=$(getent passwd "$USER" | cut -d: -f7); export SHELL

export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
install -dvm700 "$XDG_RUNTIME_DIR"

cd

# Not strictly required, because the LXQt session should create the
# directories anyway if they don't exist, but we do it in advance, just in case
xdg-user-dirs-update

################################################################################

install -dvm700 ~/.config{,/autostart}

install -dvm700 ~/.config/labwc
if [ "$disable_minimize" = true ]; then
    # This is a workaround for the fact that the LXQt Task Manager panel doesn't
    # show any window when using Wayland. Hopefully this bug will be fixed in
    # Debian 14 (forky)
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

install -dvm700 ~/.config/wayvnc
# WARNING: when running as root, "enable_pam=true" makes wayvnc accept any
# existing user as a valid login!
[ -e ~/.config/wayvnc/config ] ||
    printf '%s\n' enable_auth=true relax_encryption=true enable_pam=true |
        install -Tvm644 /dev/stdin ~/.config/wayvnc/config

[ -e ~/.config/autostart/wayvncctl-attach.desktop ] ||
    install -Tvm644 /dev/stdin \
        ~/.config/autostart/wayvncctl-attach.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=wayvncctl-attach
Exec=/bin/sh -ec '/usr/bin/wayvncctl -w attach "$WAYLAND_DISPLAY"'
NoDisplay=true
EOF

################################################################################

install -dvm700 ~/.supervisor{,/conf.d,/log}

if [ ! -e ~/.supervisor/supervisord.conf ]; then
    programs=(desktop wayvnc)

    cfg_programs=''

    ############################################################################

    args_labwc=(-S/usr/bin/startlxqt)
    if [ "$labwc_verbose" = true ]; then args_labwc+=(-V); fi

    envs_labwc=('WLR_BACKENDS="headless"' 'WLR_RENDERER="pixman"'
        'QT_QPA_PLATFORM="wayland"')

    cfg_programs+=$'[program:desktop]\n'
    cfg_programs+='command=/usr/bin/dbus-run-session -- /usr/bin/labwc '
    cfg_programs+="${args_labwc[*]@Q}"$'\n'
    cfg_programs+="environment=$(IFS=,; echo "${envs_labwc[*]}")"$'\n'

    ############################################################################

    args_wayvnc=(-D)
    if [ "$port_vnc" = unix ]
        then args_wayvnc+=(-u "$XDG_RUNTIME_DIR/desktainer-vnc.sock")
        else args_wayvnc+=(0.0.0.0 "$port_vnc")
    fi

    # Note: wayvnc creates the Unix Domain Socket "$XDG_RUNTIME_DIR/wayvncctl"
    # to make the wayvncctl CLI tool work

    cfg_programs+=$'[program:wayvnc]\n'
    cfg_programs+="command=/usr/bin/wayvnc ${args_wayvnc[*]@Q}"$'\n'

    ############################################################################

    if [ "$port_novnc" != none ]; then
        args_websockify=(--web=/usr/share/novnc)
        if [ "$port_vnc" = unix ]
            then args_websockify+=(
                --unix-target="$XDG_RUNTIME_DIR/desktainer-vnc.sock"
                "0.0.0.0:$port_novnc")
            else args_websockify+=("0.0.0.0:$port_novnc" "127.0.0.1:$port_vnc")
        fi

        programs+=(novnc)

        cfg_programs+=$'[program:novnc]\n'
        cfg_programs+="command=/usr/bin/websockify ${args_websockify[*]@Q}"$'\n'
    fi

    ############################################################################

    install -Tvm644 /dev/stdin ~/.supervisor/supervisord.conf << EOF
[supervisord]
nodaemon=true
logfile=%(here)s/log/supervisord.log
pidfile=%(here)s/supervisord.pid
childlogdir=%(here)s/log

[group:main]
programs=$(IFS=,; echo "${programs[*]}")

$cfg_programs

[include]
files=%(here)s/conf.d/*.conf
EOF
fi

################################################################################

exec /usr/bin/supervisord -nc ~/.supervisor/supervisord.conf
