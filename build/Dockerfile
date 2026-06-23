# syntax=docker/dockerfile:1

FROM docker.io/library/debian:13

# We install the "lxqt-session" package instead of "lxqt-wayland-session"
# because, even though the latter would be much better to run a Wayland
# desktop, it's only available from Debian 14 (forky) onwards
RUN <<'EOF' /bin/bash -e
    apt-get update
    apt-get install -y tini gosu supervisor sudo labwc lxqt-session wayvnc novnc
    apt-get install -y --no-install-recommends lxqt
    rm -rf /var/lib/apt/lists/*
EOF

EXPOSE 6900

ADD --chown=root:root --chmod=755 \
    --checksum=sha256:b350a393494f8de7d51b3309d8f7f40274392826938ef73a5da9cd9631541b62 \
    https://raw.githubusercontent.com/dmotte/misc/refs/heads/main/scripts/userngo/userngo-debian.sh \
    /opt/userngo/main.sh

COPY --chown=root:root --chmod=755 *.sh /opt/desktainer/

# TODO test everything in this file

# To avoid warnings about non-UTF-8 locale
ENV LC_ALL=C.UTF-8

# TODO test Tight* encodings on ARM, and restore the workaround if not working properly
# TODO make sure x-terminal-emulator is set

RUN <<'EOF' /bin/bash -e
    mv -Tv /usr/share/novnc/vnc.html /usr/share/novnc/index.html

    sed -Ei "s/^(\s*UI\.initSetting\('autoconnect', )false/\1true/" \
        /usr/share/novnc/app/ui.js

    # See https://github.com/novnc/noVNC/pull/2057
    sed -Ei 's/^(\s*inputFocus = inputFocus === "none" )(\? "noVNC_username_input" : inputFocus;)$/\1\&\& document.getElementById("noVNC_username_input").value === "" \2/' \
        /usr/share/novnc/app/ui.js

    # Needed to prevent the "menu-cached 100% CPU usage" bug
    mv -Tv /usr/lib/menu-cache/menu-cached{,.old}
    ln -Tsv /usr/bin/true /usr/lib/menu-cache/menu-cached
EOF

ENTRYPOINT ["/usr/bin/tini", "--", "/bin/bash", "/opt/userngo/main.sh", \
    "/bin/bash", "/opt/desktainer/entrypoint.sh"]
