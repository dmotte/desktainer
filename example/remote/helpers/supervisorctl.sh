#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

readonly supervisord_conf=/etc/supervisor/supervisord.conf

[ -e "$supervisord_conf" ] ||
    { echo "File $supervisord_conf not found" >&2; exit 1; }

if ! grep -Fx '[unix_http_server]' "$supervisord_conf" >/dev/null; then
    echo "Adding supervisorctl config to $supervisord_conf"

    cat << 'EOF' >> "$supervisord_conf"

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
