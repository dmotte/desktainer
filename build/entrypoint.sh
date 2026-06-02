#!/bin/bash

set -e

cd "$(dirname "$0")"

# TODO test this script thoroughly

# TODO read env var DESKTAINER_PASSWORD and unset. Then you can use it with "chpasswd" if [ "$EUID" = 0 ]

{ [ "$EUID" = 0 ] && [ -n "$DESKTAINER_USER" ]; } ||
    { echo 'Running start.sh'; exec bash start.sh "$@"; }

IFS=: read -ar parts <<< "$DESKTAINER_USER"
new_uid=${parts[0]:-1000}
new_user=${parts[1]:-user}
new_gid=${parts[2]:-$new_uid}
new_group=${parts[3]:-$new_user}

# TODO env var DESKTAINER_SUDOER
# TODO env var DESKTAINER_NOPASSWD

if ! getent group "$new_gid" >/dev/null &&
        ! getent group "$new_group" >/dev/null; then
    echo "Creating group $new_group ($new_gid)"
    # TODO something like this: groupadd -g "$new_gid" "$new_group"
    # but please write it properly, by reading the command's manual
fi

if ! getent passwd "$new_uid" >/dev/null &&
        ! getent passwd "$new_user" >/dev/null; then
    echo "Creating user $new_user ($new_uid)"
    # TODO something like this: useradd -m -s /bin/bash -u "$new_uid" -g "$new_gid" "$new_user"
    # but please write it properly, by reading the command's manual
fi

# TODO compare the user+group creation code with the "old" one, currently in start.sh

echo "Running start.sh as $new_uid:$new_gid"
exec gosu "$new_uid:$new_gid" bash start.sh "$@"
