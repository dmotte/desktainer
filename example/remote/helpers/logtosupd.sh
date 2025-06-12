#!/bin/bash

set -e

# This script can be used to set up a supervisord service that runs a custom
# command and forwards its outputs to supervisord's stdout and stderr

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

options=$(getopt -o +n:u: -l name:,user: -- "$@")
eval "set -- $options"

name=logtosupd # Warning: some characters are forbidden. See the code below
user=mainuser

while :; do
    case $1 in
        -n|--name) shift; name=$1;;
        -u|--user) shift; user=$1;;
        --) shift; break;;
    esac
    shift
done

command=$* # Warning: some characters are forbidden. See the code below

[[ "$name" =~ ^[0-9A-Za-z-]+$ ]] || { echo "Invalid name: $name" >&2; exit 1; }

[ -n "$command" ] || { echo 'Command cannot be empty' >&2; exit 1; }
[[ "$command" != *$'\n'* ]] ||
    { echo 'Command contains invalid characters' >&2; exit 1; }

################################################################################

echo "Creating $name service file"

cat << EOF > "/etc/supervisor/conf.d/$name.conf"
[program:$name]
command=$command
priority=10
user=$user
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF
