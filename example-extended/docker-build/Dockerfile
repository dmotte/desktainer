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

#TODO create debian user

#TODO desktop bg color: copy .config/pcmanfm/LXDE/desktop-items-0.conf test only interested row
