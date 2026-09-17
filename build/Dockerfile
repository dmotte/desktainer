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

    # Force UTF-8 to avoid encoding warnings from some tools (e.g. Perl)
    printf '%s\n' '# shellcheck shell=sh' 'export LC_ALL=C.UTF-8' |
        install -Tvm644 /dev/stdin /etc/profile.d/50-c-utf8.sh

    install -dvm755 /opt/{userngo,desktainer}
EOF

EXPOSE 6900

ADD --chown=root:root --chmod=755 \
    --checksum=sha256:3e290185e3b6a7b4fd985c87bf1f45b9f82a474b7c87b2d0357b42aff9f9a7d1 \
    https://raw.githubusercontent.com/dmotte/misc/refs/heads/main/scripts/userngo/userngo-debian.sh \
    /opt/userngo/main.sh

COPY --chown=root:root --chmod=755 *.sh /opt/desktainer/

# Force UTF-8 to avoid encoding warnings from some tools (e.g. Perl)
ENV LC_ALL=C.UTF-8

RUN <<'EOF' /bin/bash -e
    ln -Tsv vnc.html /usr/share/novnc/index.html

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
