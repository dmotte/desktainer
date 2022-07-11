FROM debian

# Expose the VNC and noVNC ports
EXPOSE 5901 6901

# Install required packages
# Note: dbus-x11 is needed for LXDE apps to work properly (see
# https://ubuntuforums.org/showthread.php?t=2360777)
# Note: at-spi2-core is needed for LXDE apps to work properly (see
# https://www.raspberrypi.org/forums/viewtopic.php?t=196070)
RUN apt-get update \
    && apt-get install -y sudo supervisor novnc xvfb x11vnc \
        dbus-x11 at-spi2-core \
    && apt-get install -y --no-install-recommends lxde \
    && rm -rf /var/lib/apt/lists/*

# Copy the startup script
COPY startup.sh /
RUN chmod +x /startup.sh

# Create the /opt/startup-early and /opt/startup-late directories
RUN mkdir -p /opt/startup-early /opt/startup-late

# Copy the supervisord configuration file
COPY supervisord.conf /etc/supervisor/supervisord.conf

# locale: set UTF-8 locale as environment variable
ENV LC_ALL C.UTF-8

# locale: set UTF-8 locale in /etc/profile.d/
RUN echo '#!/bin/bash\n\nexport LC_ALL=C.UTF-8' \
    > /etc/profile.d/set-c-utf8-locale.sh

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

# LXDE: set default terminal to LXTerminal
RUN update-alternatives --set x-terminal-emulator /usr/bin/lxterminal

# LXDE: disable light-locker because it cannot run inside a container (it would
# fail at startup and silently create a $HOME/core core dump file)
RUN rm /etc/xdg/autostart/light-locker.desktop

# LXDE: disable polkit because of the "No session for pid ..." message box (see
# https://github.com/WhitewaterFoundry/Pengwin/issues/429)
RUN rm /etc/xdg/autostart/lxpolkit.desktop && \
    mv /usr/bin/lxpolkit /usr/bin/lxpolkit.bak

ENTRYPOINT ["/startup.sh"]
