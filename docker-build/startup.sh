#!/bin/bash

set -e

################################# CUSTOM USER ##################################

USER=${USER:-debian}
PASSWORD=${PASSWORD:-debian}

# If the main user should be root
if [ "$USER" = "root" ]; then
    echo "The main user is root"
    HOME="/root"
else
    echo "Enabling custom user: $USER"
    HOME="/home/$USER"

    # If user already exists
    if id "$USER" &> /dev/null; then
        # If the home directory doesn't exist
        if [ ! -d "$HOME" ]; then
            # Create it and set the owner
            mkdir -p "$HOME"
            chown -R $USER:$USER "$HOME"
        fi
    else
        # Create the user (and also his home directory, if it doesn't exist)
        useradd \
            --create-home \
            --shell /bin/bash \
            --user-group \
            --groups adm,sudo \
            $USER
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
RESOLUTION=${RESOLUTION:-1280x720}
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
    mkdir -p "$HOME/.vnc"
    chown -R $USER:$USER "$HOME/.vnc"

    x11vnc -storepasswd "$VNC_PASSWORD" "$HOME/.vnc/passwd"
    chown -R $USER:$USER "$HOME/.vnc/passwd"
    chmod 400 "$HOME/.vnc/passwd"

    unset VNC_PASSWORD

    sed -i "s/%VNCPWOPTION%/-usepw/" /etc/supervisor/supervisord.conf
    echo "VNC password set"

    #TODO check psw file not readable and encrypted
    #TODO check no bash history vnc password
else
    sed -i "s/%VNCPWOPTION%/-nopw/" /etc/supervisor/supervisord.conf
    echo "VNC password disabled"

    #TODO check .vnc dir does not exist
    #TODO check no warning nopw in vnc log
fi

############################## START SUPERVISORD ###############################

#TODO test disable polkit from cfg
#sed -i "s/^\(polkit\/command.*\)$/#\1/" $HOME/.config/lxsession/LXDE/desktop.conf

#TODO check HOME and USER vars in programs
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
