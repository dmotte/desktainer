#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

options=$(getopt -o + -l user: -l authorized-keys-file: \
    -l allow-tcp-forwarding: -l permit-listen: -l permit-open: -- "$@")
eval "set -- $options"

# See https://man.openbsd.org/sshd_config#AllowTcpForwarding for more info on
# sshd config options

user=''
authorized_keys_file=''
allow_tcp_forwarding='no' # Available options: yes, no, local, remote
permit_listen='none'
permit_open='none'

while :; do
    case $1 in
        --user) shift; user=$1;;
        --authorized-keys-file) shift; authorized_keys_file=$1;;
        --allow-tcp-forwarding) shift; allow_tcp_forwarding=$1;;
        --permit-listen) shift; permit_listen=$1;;
        --permit-open) shift; permit_open=$1;;
        --) shift; break;;
    esac
    shift
done

[ -n "$user" ] || { echo 'User cannot be empty' >&2; exit 1; }

################################################################################

if ! id "$user" >/dev/null 2>&1; then
    echo "Creating user $user"
    useradd -Ums/bin/bash "$user"
fi

echo "Creating sshd config file $user.conf"

cat << EOF > "/etc/ssh/sshd_config.d/user-$user.conf"
Match User $user
    AllowAgentForwarding no
    AllowTcpForwarding $allow_tcp_forwarding
    GatewayPorts no
    X11Forwarding no
    PermitTunnel no
    PermitListen $permit_listen
    PermitOpen $permit_open
    PermitTTY no
    ClientAliveInterval 30
    ForceCommand echo "This account can only be used for port forwarding"
EOF

user_home=$(eval "echo ~$user")

install -d -o"$user" -g"$user" -m700 "$user_home/.ssh"

if [ -n "$authorized_keys_file" ]; then
    echo "Creating authorized_keys file for $user"

    install -o"$user" -g"$user" -m600 "$authorized_keys_file" \
        "$user_home/.ssh/authorized_keys"
fi
