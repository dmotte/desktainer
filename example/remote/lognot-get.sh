#!/bin/bash

set -e

withprefix() { while read -r i; do echo "$1$i"; done }

trap 'kill $(jobs -p)' EXIT

tail -f /var/log/supervisor/noVNC-stdout-* | withprefix 'noVNC.O: ' &
tail -f /var/log/supervisor/noVNC-stderr-* | withprefix 'noVNC.E: ' &

tail -f /var/log/supervisor/sshd-stdout-* | withprefix 'sshd.O: ' &
tail -f /var/log/supervisor/sshd-stderr-* | withprefix 'sshd.E: ' &

tail -f /var/log/supervisor/portmap-ssh-stdout-* |
    grep --line-buffered client_request_forwarded_tcpip |
    withprefix 'portmap-ssh.O: ' &
tail -f /var/log/supervisor/portmap-ssh-stderr-* |
    grep --line-buffered client_request_forwarded_tcpip |
    withprefix 'portmap-ssh.E: ' &

rm -f /tmp/lognot-misc.sock
socat UNIX-LISTEN:/tmp/lognot-misc.sock,mode=666,fork STDOUT |
    withprefix 'misc: ' &

wait # until all jobs finish
trap - EXIT
