# Tested with docker.io/dmotte/desktainer:2023.06.27.0437
FROM docker.io/dmotte/desktainer:latest

VOLUME /data

COPY --chown=root:root --chmod=755 setup/ /setup
RUN bash /setup/main.sh && rm -rf /setup
