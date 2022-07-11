#!/bin/bash

set -e

################################# CUSTOM USER ##################################

USER=${USER:-mainuser}
PASSWORD=${PASSWORD:-mainuser}

# If the main user should be root
if [ "$USER" = "root" ]; then
    echo "The main user is root"
    HOME="/root"
else
    echo "Enabling custom user: $USER"
    HOME="/home/$USER"

    # If user already exists
    if id "$USER" &> /dev/null; then
        echo "The custom user $USER already exists"

        # If the home directory doesn't exist
        if [ ! -d "$HOME" ]; then
            echo "Creating home directory for custom user $USER"

            # Create it and set the owner
            mkdir -p "$HOME"
            chown -R "$USER:$USER" "$HOME"
        fi
    else
        echo "Creating custom user $USER"

        # Create the user (and also his home directory, if it doesn't exist)
        useradd \
            --create-home \
            --shell /bin/bash \
            --user-group \
            --groups adm,sudo \
            "$USER"
    fi

    echo "Setting custom user's password"
    echo "$USER:$PASSWORD" | chpasswd
fi

unset PASSWORD

##################### SUPERVISORD CONFIG MAIN REPLACEMENTS #####################

# Set VNC port
VNC_PORT=${VNC_PORT:-5901}
sed -i "s/%VNC_PORT%/$VNC_PORT/g" /etc/supervisor/supervisord.conf
echo "VNC port set to $VNC_PORT"

# Set noVNC port
NOVNC_PORT=${NOVNC_PORT:-6901}
sed -i "s/%NOVNC_PORT%/$NOVNC_PORT/g" /etc/supervisor/supervisord.conf
echo "noVNC port set to $NOVNC_PORT"

# Set resolution
RESOLUTION=${RESOLUTION:-1920x1080}
sed -i "s/%RESOLUTION%/$RESOLUTION/g" /etc/supervisor/supervisord.conf
echo "Resolution set to $RESOLUTION"

# Replace %USER% and %HOME% variables in supervisord.conf
# Note: we use the pipe character as delimiter in the expression #2 because the
# $HOME variable contains slashes
sed -i -e "s/%USER%/$USER/g" -e "s|%HOME%|$HOME|g" \
    /etc/supervisor/supervisord.conf

############################# VNC SERVER PASSWORD ##############################

# If the VNC password should be set
if [ -n "$VNC_PASSWORD" ]; then
    # If the .vnc/passwd file doesn't exist
    if [ ! -f "$HOME/.vnc/passwd" ]; then
        echo "Storing the VNC password into $HOME/.vnc/passwd"

        mkdir -p "$HOME/.vnc"
        chown -R "$USER:$USER" "$HOME/.vnc"

        # Store the password (encrypted and with 400 permissions)
        x11vnc -storepasswd "$VNC_PASSWORD" "$HOME/.vnc/passwd"
        chown -R "$USER:$USER" "$HOME/.vnc/passwd"
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

# Remove the X11 lock file if present
rm -f /tmp/.X0-lock

############################## START SUPERVISORD ###############################

# Start supervisord with "exec" to let it become the PID 1 process. This ensures
# it receives all the stop signals and reaps all the zombie processes inside the
# container
echo "Starting supervisord"
exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
