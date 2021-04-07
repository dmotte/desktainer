FROM dmotte/desktainer

# Expose the SSH and Shellinabox ports
EXPOSE 22 4200

# Install additional packages
RUN apt-get update \
    && apt-get install -y git htop nano tmux tree wget zip curl socat procps \
        openssh-server shellinabox \
        firefox-esr dirmngr lynx speedometer evince mtpaint gedit

# Copy the additional supervisor configuration files
COPY supervisor-confd/* /etc/supervisor/conf.d/

# sshd: Remove the generated SSH host keys! We want to generate them outside the
# container and then mount them inside, for security reasons
RUN rm /etc/ssh/ssh_host_*_key && rm /etc/ssh/ssh_host_*_key.pub

# sshd: create the privilege separation directory
RUN mkdir -p /var/run/sshd

# Create custom user named "debian"
RUN useradd \
    --create-home \
    --shell /bin/bash \
    --user-group \
    --groups adm,sudo \
    debian

# LXDE: set desktop background color
RUN mkdir -p "/home/debian/.config/pcmanfm/LXDE" \
    && echo '[*]\nwallpaper_mode=color\ndesktop_bg=#3a6ea5' \
        > "/home/debian/.config/pcmanfm/LXDE/desktop-items-0.conf" \
    && chown -R debian:debian "/home/debian/.config"
