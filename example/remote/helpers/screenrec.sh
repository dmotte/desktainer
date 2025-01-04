#!/bin/bash

set -e

[ "$EUID" = 0 ] || { echo 'This script must be run as root' >&2; exit 1; }

readonly data_dir=${1:?}

apt_update_if_old() {
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -60)" ]; then
        apt-get update
    fi
}

################################################################################

dpkg -s ffmpeg >/dev/null 2>&1 ||
    { apt_update_if_old; apt-get install -y ffmpeg; }

echo 'Creating screenrec service files'

cat << 'EOF' > /etc/supervisor/conf.d/screenrec.conf
[program:screenrec]
command=/bin/bash /opt/screenrec.sh
priority=30
user=mainuser
EOF

install -omainuser -gmainuser -m700 /dev/stdin /opt/screenrec.sh << EOF
#!/bin/bash

set -e

readonly data_dir=${data_dir@Q}

mkdir -p "\$data_dir"

sleep 10

while :; do
    ffmpeg -framerate 3 -f x11grab -i :0.0 \
        -c:v libx265 -crf 40 -preset slow \
        -vf 'scale=iw*2/3:ih*2/3' -t 60 \
        "\$data_dir/\$(date -u +%Y-%m-%d-%H%M%S).mp4"
done
EOF
