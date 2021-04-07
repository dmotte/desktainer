FROM debian

# Expose the VNC and HTTP ports
EXPOSE 5901 6901

# Install required packages
RUN apt-get update \
    && apt-get install -y sudo dbus-x11 supervisor novnc xvfb x11vnc \
    && apt-get install -y --no-install-recommends lxde

#TODO
RUN apt-get install -y at-spi2-core

# Copy the startup script
COPY startup.sh /
RUN chmod +x /startup.sh

# Copy the supervisord configuration file
COPY supervisord.conf /etc/supervisor/supervisord.conf

# noVNC: if on ARM architecture, disable the Tight* encodings
# See https://github.com/fcwu/docker-ubuntu-vnc-desktop/issues/98 for further
# information
RUN ARCH="$(uname -m)"; \
    if [ "$ARCH" != "${ARCH#arm}" ]; then \
        sed -i 's/\(encs\.push[(]encodings\.encodingTight\)/\/\/ \1/' \
        /usr/share/novnc/core/rfb.js; \
    fi

# noVNC: make the vnc.html page the default one
RUN mv /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# noVNC: set default autoconnect=true
RUN sed -i "s/\(WebUtil\.getConfigVar[(]'autoconnect', \)false/\1true/" \
    /usr/share/novnc/app/ui.js

#TODO set default terminal to LXTerminal
RUN update-alternatives --set x-terminal-emulator /usr/bin/lxterminal

#TODO disable light-locker because it creates $HOME/core (core dump file)
RUN rm /etc/xdg/autostart/light-locker.desktop

#TODO disable polkit because of message "No session for pid X"
#RUN rm /etc/xdg/autostart/lxpolkit.desktop && \
#    mv /usr/bin/lxpolkit /usr/bin/lxpolkit.bak

ENTRYPOINT ["/startup.sh"]
