#!/bin/bash

set -e

if [ -n "$VNC_PASSWORD" ]; then
    sed -i "s/###VNC_PASSWORD###/$VNC_PASSWORD/" /etc/supervisor/supervisord.conf
    unset VNC_PASSWORD
    echo "VNC password set in supervisord.conf"
else
    sed -i "s/-passwd \"###VNC_PASSWORD###\"//" /etc/supervisor/supervisord.conf
    echo "VNC password option removed from supervisord.conf"
fi

if [ -n "$RESOLUTION" ]; then
    sed -i "s/1280x720x24/${RESOLUTION}x24/" /etc/supervisor/supervisord.conf
    echo "Resolution set to $RESOLUTION"
fi

# Start all the services
/usr/bin/supervisord
