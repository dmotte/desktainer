FROM dmotte/desktainer

# Expose the SSH and Shellinabox ports
EXPOSE 22 4200

# Install additional packages
RUN apt-get update \
    && apt-get install -y git htop nano tmux tree wget zip curl socat procps \
        openssh-server shellinabox \
        firefox-esr dirmngr lynx speedometer evince mtpaint gedit
#TODO install sshd without generating host keys, or remove them

# Copy the additional supervisor configuration files
COPY supervisor-confd/* /etc/supervisor/conf.d/

# sshd: create the privilege separation directory
RUN mkdir -p /var/run/sshd

#TODO create debian user

#TODO desktop bg color: copy .config/pcmanfm/LXDE/desktop-items-0.conf test only interested row
