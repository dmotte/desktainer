#!/bin/bash

set -ex

appownmod() { touch "$1"; cat >> "$1"; chown "$2" "$1"; chmod "$3" "$1"; }

################################### Generic ####################################

apt-get update
apt-get install -y git nano tmux tree wget zip curl socat procps jq yq \
    iputils-ping iproute2 openssh-server \
    shellinabox ffmpeg firefox-esr dirmngr dconf-cli
rm -rf /var/lib/apt/lists/*

sed -Ei 's/^#?UMASK.*$/UMASK 077/' /etc/login.defs
sed -Ei 's/^#?DIR_MODE=.*$/DIR_MODE=0700/' /etc/adduser.conf

cat << 'EOF' >> /etc/supervisor/supervisord.conf
[unix_http_server]
file=/run/supervisor.sock
chown=root:root
chmod=0700

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///run/supervisor.sock
EOF

chmod 700 /var/log/supervisor
chmod 700 /opt/startup-{early,late}

#################################### lognot ####################################

# cat << 'EOF' > /etc/supervisor/conf.d/lognot.conf
# [program:lognot]
# command=/bin/bash -c 'bash /opt/lognot/get.sh |
#     while read -r i; do echo "$HOSTNAME: $i"; done |
#     /opt/lognot/msgbuf -i10 -m2048 -- /bin/bash /opt/lognot/tg.sh'
# priority=50
# EOF

install -dm700 /opt/lognot
install -m700 /{setup,opt}/lognot/get.sh
curl -Lo /opt/lognot/msgbuf \
    "https://github.com/dmotte/msgbuf/releases/latest/download/msgbuf-$(uname -m)-unknown-linux-gnu"
echo '3fcec4e61ef0fdbc9e4a703ba3c5b3075b20336d57b963e05676ccdab3ad5ca4' \
    /opt/lognot/msgbuf | sha256sum -c # Checksum for v1.0.2
chmod +x /opt/lognot/msgbuf
install -m700 /{setup,opt}/lognot/tg.sh
cat << 'EOF' > /opt/startup-late/50-lognot-secrets.sh
sed -i /opt/lognot/tg.sh \
    -e "s/{{ lognot_bot_token }}/$LOGNOT_BOT_TOKEN/" \
    -e "s/{{ lognot_chat_id }}/$LOGNOT_CHAT_ID/"
unset LOGNOT_{BOT_TOKEN,CHAT_ID}
EOF

################################ OpenSSH server ################################

cat << 'EOF' > /etc/supervisor/conf.d/sshd.conf
[program:sshd]
command=/usr/sbin/sshd -De
priority=10
EOF

mkdir -p /var/run/sshd

sed -Ei /etc/ssh/sshd_config \
    -e 's/^#?AddressFamily.*$/AddressFamily inet/' \
    -e 's/^#?PermitRootLogin.*$/PermitRootLogin no/' \
    -e 's/^#?HostbasedAuthentication.*$/HostbasedAuthentication no/' \
    -e 's/^#?PermitEmptyPasswords.*$/PermitEmptyPasswords no/' \
    -e 's/^#?PasswordAuthentication.*$/PasswordAuthentication no/'

rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
mkdir /etc/ssh/host-keys
cat << 'EOF' > /opt/startup-late/50-ssh-host-keys.sh
# Get host keys from the volume
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
install -m600 -t/etc/ssh /etc/ssh/host-keys/ssh_host_*_key 2>/dev/null || :
install -m644 -t/etc/ssh /etc/ssh/host-keys/ssh_host_*_key.pub 2>/dev/null || :

# Generate the missing host keys
ssh-keygen -A

# Copy the (previously missing) generated host keys to the volume
cp -n /etc/ssh/ssh_host_*_key /etc/ssh/host-keys/ 2>/dev/null || :
cp -n /etc/ssh/ssh_host_*_key.pub /etc/ssh/host-keys/ 2>/dev/null || :
EOF

################################ Shell In A Box ################################

cat << 'EOF' > /etc/supervisor/conf.d/shellinabox.conf
[program:shellinabox]
command=/usr/bin/shellinaboxd -q -p 4200 -u shellinabox -g shellinabox
    --user-css "White on Black:+/etc/shellinabox/options-enabled/00_White On Black.css;Color Terminal:+/etc/shellinabox/options-enabled/01+Color Terminal.css"
    --disable-ssl --service "/:AUTH:HOME:tmux new-session -As0"
priority=10
EOF

################################ USER: mainuser ################################

useradd -UGsudo -ms/bin/bash mainuser

echo 'mainuser ALL=(ALL) NOPASSWD: ALL' | \
    install -m440 /dev/stdin /etc/sudoers.d/mainuser-nopassword

install -d -omainuser -gmainuser -m700 ~mainuser/.ssh
appownmod ~mainuser/.ssh/authorized_keys mainuser:mainuser 600 << 'EOF'
(put-public-ssh-key-here)
EOF

echo 'install -d -omainuser -gmainuser -m700 /data/mainuser' \
    > /opt/startup-late/50-data-mainuser.sh

############################ mainuser: portmap-ssh #############################

# cat << 'EOF' > /etc/supervisor/conf.d/portmap-ssh.conf
# [program:portmap-ssh]
# command=/bin/bash -c 'ssh -i /home/mainuser/.ssh/portmap-ssh.pem \
#     -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes \
#     myuser@myserver.example.com -Nv -R 12345:127.0.0.1:22 \
#     || result="$?"; sleep 30; exit "${result:-0}"'
# startsecs=0
# priority=10
# user=mainuser
# EOF

appownmod ~mainuser/.ssh/known_hosts mainuser:mainuser 600 << 'EOF'
(put-public-ssh-host-key-here)
EOF

cat << 'EOF' > /opt/startup-late/50-portmap-ssh-client-key.sh
if [ ! -f ~mainuser/.ssh/portmap-ssh.pem ]; then
    install -omainuser -gmainuser -m600 \
        <(echo "$PORTMAP_SSH_CLIENT_KEY") ~mainuser/.ssh/portmap-ssh.pem
fi
unset PORTMAP_SSH_CLIENT_KEY
EOF

############################## mainuser: desktop ###############################

install -d -omainuser -gmainuser ~mainuser/.config

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/mimeapps.list << 'EOF'
[Added Associations]
text/plain=org.xfce.mousepad.desktop
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/initial.dconf << 'EOF'
[org/xfce/mousepad/preferences/view]
show-line-numbers=true

show-right-margin=true
right-margin-position=80

highlight-current-line=true
match-braces=true
word-wrap=true

color-scheme='oblivion'

tab-width=4
insert-spaces=true

auto-indent=true

[org/xfce/mousepad/preferences/window]
statusbar-visible=true
toolbar-visible=true
EOF

install -d -omainuser -gmainuser ~mainuser/.config/autostart

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/autostart/dconf-load.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=dconf-load
Exec=/bin/sh -c "/usr/bin/dconf load / < ~/.config/initial.dconf"
NoDisplay=true
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/autostart/xrandr-fb.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=xrandr-fb
Exec=/usr/bin/xrandr --fb 1920x900
NoDisplay=true
EOF

install -d -omainuser -gmainuser ~mainuser/.config/pcmanfm{,/LXDE}
install -omainuser -gmainuser -m644 /dev/stdin \
    ~mainuser/.config/pcmanfm/LXDE/pcmanfm.conf << 'EOF'
[ui]
show_hidden=1
EOF

install -omainuser -gmainuser -m644 /dev/stdin \
     ~mainuser/.config/pcmanfm/LXDE/desktop-items-0.conf << 'EOF'
[*]
wallpaper_mode=color
desktop_bg=#3a6ea5
EOF

install -d -omainuser -gmainuser ~mainuser/Desktop

ln -s /data/mainuser ~mainuser/Desktop/persistent
chown -h mainuser:mainuser ~mainuser/Desktop/persistent

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
        "$DATA_DIR/$(date +%Y-%m-%d-%H%M%S).mp4"
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
