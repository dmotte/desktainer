#!/bin/bash

set -e

# TODO move everything from this script to the new one

############################# mainuser: screenrec ##############################

# cat << 'EOF' > /etc/supervisor/conf.d/screenrec.conf
# [program:screenrec]
# command=/bin/bash /opt/screenrec.sh
# priority=30
# user=mainuser
# EOF

install -omainuser -gmainuser -m700 /dev/stdin /opt/screenrec.sh << 'EOF'
#!/bin/bash

set -e

DATA_DIR=/data/mainuser/screenrec

mkdir -p "$DATA_DIR"

sleep 10

while :; do
    ffmpeg -framerate 3 -f x11grab -i :0.0 \
        -c:v libx265 -crf 40 -preset slow \
        -vf 'scale=iw*2/3:ih*2/3' -t 60 \
        "$DATA_DIR/$(date -u +%Y-%m-%d-%H%M%S).mp4"
done
EOF

################################# USER: alice ##################################

useradd -Ums/bin/bash alice

cat << 'EOF' > /etc/ssh/sshd_config.d/alice.conf
Match User alice
    AllowAgentForwarding no
    AllowTcpForwarding yes
    GatewayPorts no
    X11Forwarding no
    PermitTunnel no
    PermitListen 8001 8002 8003 8004 8005
    PermitOpen any
    PermitTTY no
    ForceCommand echo "This account can only be used for port forwarding"
EOF
install -d -oalice -galice -m700 ~alice/.ssh
appownmod ~alice/.ssh/authorized_keys alice:alice 600 << 'EOF'
(put-public-ssh-key-here)
EOF

################################# USER: bob ##################################

useradd -Ums/bin/bash bob

cat << 'EOF' > /etc/ssh/sshd_config.d/bob.conf
Match User bob
    AllowAgentForwarding no
    AllowTcpForwarding local
    GatewayPorts no
    X11Forwarding no
    PermitTunnel no
    PermitListen none
    PermitOpen 127.0.0.1:8001 127.0.0.1:8002
    PermitTTY no
    ForceCommand echo "This account can only be used for port forwarding"
EOF
install -d -obob -gbob -m700 ~bob/.ssh
appownmod ~bob/.ssh/authorized_keys bob:bob 600 << 'EOF'
(put-public-ssh-key-here)
EOF
