#!/bin/bash

set -e

withprefix() { while IFS= read -r i; do echo "$1$i"; done }

trap 'jobs -p | xargs -rd\\n kill; wait' EXIT

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

socat UNIX-LISTEN:/tmp/lognot-misc.sock,mode=666,fork,unlink-early - |
    withprefix 'misc: ' &

wait # until all jobs finish
trap - EXIT
