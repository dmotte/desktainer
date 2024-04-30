#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

sed -Ei 's/^#?UMASK.*$/UMASK 077/' /etc/login.defs
sed -Ei 's/^#?DIR_MODE=.*$/DIR_MODE=0700/' /etc/adduser.conf

chmod 700 /var/log/supervisor /home/*
