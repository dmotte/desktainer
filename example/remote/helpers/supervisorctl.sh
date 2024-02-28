#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

if ! grep -Fx '[unix_http_server]' \
    /etc/supervisor/supervisord.conf >/dev/null 2>&1; then
    echo 'Adding supervisorctl config to supervisord.conf'

    cat << 'EOF' >> /etc/supervisor/supervisord.conf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[unix_http_server]
file=/run/supervisor.sock
chown=root:root
chmod=0700

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///run/supervisor.sock
EOF
fi
