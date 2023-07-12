#!/bin/bash

set -ex

fileownmod() { cat > "$1" && chown "$2" "$1" && chmod "$3" "$1"; }
appownmod() { touch "$1" && cat >> "$1" && chown "$2" "$1" && chmod "$3" "$1"; }
dirownmod() { mkdir "$1" && chown "$2" "$1" && chmod "$3" "$1"; }
dirpownmod() { mkdir -p "$1" && chown "$2" "$1" && chmod "$3" "$1"; }

################################### Generic ####################################

apt-get update
apt-get install -y git nano tmux tree wget zip curl socat procps jq yq \
    iputils-ping iproute2 openssh-server python3-pip python3-venv \
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

cat << 'EOF' > /etc/supervisor/conf.d/lognot.conf
[program:lognot]
command=/bin/bash -c 'bash /opt/lognot/get.sh |
    while read -r i; do echo "$HOSTNAME: $i"; done |
    /opt/lognot/venv/bin/python3 -um msgbuf \
        -l INFO -i 10 -m 2048 -f /opt/lognot/buffer.txt \
        /opt/lognot/venv/bin/python3 /opt/lognot/tg.py'
priority=50
EOF

dirownmod /opt/lognot root:root 700
fileownmod /opt/lognot/get.sh root:root 700 < /setup/lognot/get.sh
python3 -m venv /opt/lognot/venv
/opt/lognot/venv/bin/pip3 install requests==2.* msgbuf==1.*
fileownmod /opt/lognot/tg.py root:root 600 < /setup/lognot/tg.py
cat << 'EOF' > /opt/startup-late/50-lognot-secrets.sh
sed -i /opt/lognot/tg.py \
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
cp /etc/ssh/host-keys/ssh_host_*_key /etc/ssh/ 2>/dev/null || true
cp /etc/ssh/host-keys/ssh_host_*_key.pub /etc/ssh/ 2>/dev/null || true

# Generate the missing host keys
ssh-keygen -A

# Set correct permissions on host keys
chown root:root /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# Copy the (previously missing) generated host keys to the volume
cp -n /etc/ssh/ssh_host_*_key /etc/ssh/host-keys/ 2>/dev/null || true
cp -n /etc/ssh/ssh_host_*_key.pub /etc/ssh/host-keys/ 2>/dev/null || true
EOF

################################ Shell In A Box ################################

cat << 'EOF' > /etc/supervisor/conf.d/shellinabox.conf
[program:shellinabox]
command=/usr/bin/shellinaboxd -q -p 4200 -u shellinabox -g shellinabox
    --user-css "White on Black:+/etc/shellinabox/options-enabled/00_White On Black.css;Color Terminal:+/etc/shellinabox/options-enabled/01+Color Terminal.css"
    --disable-ssl --service "/:AUTH:HOME:tmux new-session -As main"
priority=10
EOF

################################ USER: mainuser ################################

useradd -UGsudo -ms/bin/bash mainuser

echo 'mainuser ALL=(ALL) NOPASSWD: ALL' | \
    fileownmod /etc/sudoers.d/mainuser-nopassword root:root 440

dirownmod ~mainuser/.ssh mainuser:mainuser 700
appownmod ~mainuser/.ssh/authorized_keys mainuser:mainuser 600 << 'EOF'
(put-public-ssh-key-here)
EOF

cat << 'EOF' > /opt/startup-late/50-data-mainuser.sh
mkdir -p /data/mainuser
chown mainuser:mainuser /data/mainuser
chmod 700 /data/mainuser
EOF

############################ mainuser: portmap-ssh #############################

cat << 'EOF' > /etc/supervisor/conf.d/portmap-ssh.conf
[program:portmap-ssh]
command=/usr/bin/ssh -i /home/mainuser/.ssh/portmap-ssh.pem
    -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes
    myuser@myserver.example.com -Nv -R 12345:127.0.0.1:22
priority=10
user=mainuser
EOF

appownmod ~mainuser/.ssh/known_hosts mainuser:mainuser 600 << 'EOF'
(put-public-ssh-host-key-here)
EOF

cat << 'EOF' > /opt/startup-late/50-portmap-ssh-client-key.sh
echo "$PORTMAP_SSH_CLIENT_KEY" > ~mainuser/.ssh/portmap-ssh.pem
chown mainuser:mainuser ~mainuser/.ssh/portmap-ssh.pem
chmod 600 ~mainuser/.ssh/portmap-ssh.pem
unset PORTMAP_SSH_CLIENT_KEY
EOF

############################## mainuser: desktop ###############################

dirpownmod ~mainuser/.config mainuser:mainuser 755

fileownmod ~mainuser/.config/mimeapps.list mainuser:mainuser 644 << 'EOF'
[Added Associations]
text/plain=org.xfce.mousepad.desktop
EOF

fileownmod ~mainuser/.config/initial.dconf mainuser:mainuser 644 << 'EOF'
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

dirpownmod ~mainuser/.config/autostart mainuser:mainuser 755

fileownmod ~mainuser/.config/autostart/dconf-load.desktop \
    mainuser:mainuser 644 << 'EOF'
[Desktop Entry]
Type=Application
Name=dconf-load
Exec=/bin/sh -c "/usr/bin/dconf load / < ~/.config/initial.dconf"
NoDisplay=true
EOF

fileownmod ~mainuser/.config/autostart/xrandr-fb.desktop \
    mainuser:mainuser 644 << 'EOF'
[Desktop Entry]
Type=Application
Name=xrandr-fb
Exec=/usr/bin/xrandr --fb 1920x900
NoDisplay=true
EOF

dirpownmod ~mainuser/.config/pcmanfm/LXDE mainuser:mainuser 755
fileownmod ~mainuser/.config/pcmanfm/LXDE/pcmanfm.conf \
    mainuser:mainuser 644 << 'EOF'
[ui]
show_hidden=1
EOF

fileownmod ~mainuser/.config/pcmanfm/LXDE/desktop-items-0.conf \
    mainuser:mainuser 644 << 'EOF'
[*]
wallpaper_mode=color
desktop_bg=#3a6ea5
EOF

dirpownmod ~mainuser/Desktop mainuser:mainuser 755

ln -s /data/mainuser ~mainuser/Desktop/persistent
chown -h mainuser:mainuser ~mainuser/Desktop/persistent

############################# mainuser: screenrec ##############################

cat << 'EOF' > /etc/supervisor/conf.d/screenrec.conf
[program:screenrec]
command=/bin/bash /opt/screenrec.sh
priority=30
user=mainuser
EOF

fileownmod /opt/screenrec.sh mainuser:mainuser 700 << 'EOF'
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
dirownmod ~alice/.ssh alice:alice 700
appownmod ~alice/.ssh/authorized_keys alice:alice 600 << 'EOF'
(put-public-ssh-key-here)
EOF
