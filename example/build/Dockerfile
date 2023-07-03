# Tested with docker.io/dmotte/desktainer:2023.06.27.0437
FROM docker.io/dmotte/desktainer:latest

# Expose the SSH and Shellinabox ports
EXPOSE 22 4200

# Declare the persistent directory as volume
VOLUME /data

# Install additional packages
RUN apt-get update && \
    apt-get install -y git htop nano tmux tree wget zip curl socat procps \
        iputils-ping iproute2 \
        openssh-server shellinabox ffmpeg \
        firefox-esr dirmngr lynx dconf-cli && \
    rm -rf /var/lib/apt/lists/*

# Copy the additional supervisor configuration files
COPY --chown=root:root --chmod=644 supervisor-confd/* /etc/supervisor/conf.d/

# sshd: Remove the generated SSH host keys! For obvious security reasons
RUN rm /etc/ssh/ssh_host_*_key && rm /etc/ssh/ssh_host_*_key.pub

# sshd: Create the privilege separation directory
RUN mkdir -p /var/run/sshd

# sshd: Always use IPv4
# This makes SSH X11 forwarding work. Usually, Docker containers do not have an
# IPv6 address and, by default, SSH X11 forwarding listens on [::1]:6010 on the
# server, but we want it to listen on 127.0.0.1 instead
RUN sed -Ei 's/^#?AddressFamily.*$/AddressFamily inet/' /etc/ssh/sshd_config

# sshd: Hardening
RUN sed -Ei 's/^#?PermitRootLogin.*$/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -Ei 's/^#?HostbasedAuthentication.*$/HostbasedAuthentication no/' /etc/ssh/sshd_config && \
    sed -Ei 's/^#?PermitEmptyPasswords.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# sshd: startup script for missing host keys generation
RUN mkdir /etc/ssh/host-keys
COPY --chown=root:root --chmod=700 50-ssh-host-keys.sh /opt/startup-late/

# Create custom user named "mainuser"
RUN useradd \
    --create-home \
    --shell /bin/bash \
    --user-group \
    --groups sudo \
    mainuser

# Copy the screenrec.sh script
COPY --chown=root:root --chmod=755 screenrec.sh /opt/

# Startup script for persistent directory initialization
RUN echo 'mkdir -p /data/mainuser && chown mainuser:mainuser /data/mainuser' \
    > "/opt/startup-late/50-data-mainuser.sh"

# Perform some stuff as mainuser
USER mainuser
WORKDIR /home/mainuser

# Create some needed directories
RUN mkdir -p ".config/autostart" ".config/pcmanfm/LXDE" "Desktop"

# Copy the mimeapps.list file (for file types associations)
COPY --chown=mainuser:mainuser --chmod=644 mimeapps.list .config/

# Copy the initial dconf settings file
COPY --chown=mainuser:mainuser --chmod=644 initial.dconf .config/

# LXDE launcher: load initial dconf settings
RUN echo '[Desktop Entry]\nType=Application\nName=dconf-load\nExec=/bin/sh -c "/usr/bin/dconf load / < ~/.config/initial.dconf"\nNoDisplay=true' \
    > ".config/autostart/dconf-load.desktop"

# LXDE launcher: set resolution with xrandr
RUN echo '[Desktop Entry]\nType=Application\nName=xrandr-fb\nExec=/usr/bin/xrandr --fb 1920x900\nNoDisplay=true' \
    > ".config/autostart/xrandr-fb.desktop"

# LXDE: set desktop background color
RUN echo '[*]\nwallpaper_mode=color\ndesktop_bg=#3a6ea5' \
    > ".config/pcmanfm/LXDE/desktop-items-0.conf"

# Create a symbolic link to the persistent directory on Desktop
RUN ln -s /data/mainuser Desktop/persistent

# Become the root user again
USER root
WORKDIR /
