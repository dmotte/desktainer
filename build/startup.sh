#!/bin/bash

set -e

############################ ENVIRONMENT VARIABLES #############################

: "${USER:=mainuser}"
: "${PASSWORD:=mainuser}"

################### INCLUDE SCRIPTS FROM /opt/startup-early ####################

for i in /opt/startup-early/*.sh; do
    [ -f "$i" ] || continue
    # shellcheck source=/dev/null
    . "$i"
done

################################# CUSTOM USER ##################################

if [ "$USER" = "root" ]; then
    echo "The main user is root"
    HOME="/root"
else
    echo "Enabling custom user: $USER"
    HOME="/home/$USER"

    # If user already exists
    if id "$USER" &> /dev/null; then
        echo "The custom user $USER already exists"

        if [ ! -d "$HOME" ]; then
            echo "Creating home directory for custom user $USER"
            install -d -o"$USER" -g"$USER" "$HOME"
        fi
    else
        echo "Creating custom user $USER"
        useradd -UGsudo -ms/bin/bash "$USER"
    fi

    echo "Setting custom user's password"
    echo "$USER:$PASSWORD" | chpasswd
fi

unset PASSWORD

##################### SUPERVISORD CONFIG MAIN REPLACEMENTS #####################

: "${VNC_PORT:=5901}"
sed -i "s/%VNC_PORT%/$VNC_PORT/g" /etc/supervisor/supervisord.conf
echo "VNC port set to $VNC_PORT"

: "${NOVNC_PORT:=6901}"
sed -i "s/%NOVNC_PORT%/$NOVNC_PORT/g" /etc/supervisor/supervisord.conf
echo "noVNC port set to $NOVNC_PORT"

: "${RESOLUTION:=1920x1080}"
sed -i "s/%RESOLUTION%/$RESOLUTION/g" /etc/supervisor/supervisord.conf
echo "Resolution set to $RESOLUTION"

# Note: we use the pipe character as delimiter in the expression #2 because the
# $HOME variable contains slashes
sed -i "s/%USER%/$USER/g;s|%HOME%|$HOME|g" /etc/supervisor/supervisord.conf

############################# VNC SERVER PASSWORD ##############################

if [ -n "$VNC_PASSWORD" ]; then
    if [ ! -f "$HOME/.vnc/passwd" ]; then
        echo "Storing the VNC password into $HOME/.vnc/passwd"

        install -d -o"$USER" -g"$USER" "$HOME/.vnc"

        # Store the password encrypted and with 400 permissions
        x11vnc -storepasswd "$VNC_PASSWORD" "$HOME/.vnc/passwd"
        chown "$USER:$USER" "$HOME/.vnc/passwd"
        chmod 400 "$HOME/.vnc/passwd"
    fi

    unset VNC_PASSWORD

    sed -i "s/%VNCPWOPTION%/-usepw/" /etc/supervisor/supervisord.conf
    echo "VNC password set"
else
    sed -i "s/%VNCPWOPTION%/-nopw/" /etc/supervisor/supervisord.conf
    echo "VNC password disabled"
fi

############################# CLEAR Xvfb LOCK FILE #############################

rm -f /tmp/.X0-lock

#################### INCLUDE SCRIPTS FROM /opt/startup-late ####################

for i in /opt/startup-late/*.sh; do
    [ -f "$i" ] || continue
    # shellcheck source=/dev/null
    . "$i"
done

############################## START SUPERVISORD ###############################

# Start supervisord with "exec" to let it become the PID 1 process. This ensures
# it receives all the stop signals correctly and reaps all the zombie processes
# inside the container
echo "Starting supervisord"
exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
